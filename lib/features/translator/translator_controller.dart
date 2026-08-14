import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants.dart';
import '../../core/database/dao_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ai_service_factory.dart';
import '../../core/services/ocr/ocr_service.dart';
import '../../core/services/ocr/ocr_service_factory.dart';
import '../../core/services/ocr/tesseract_ocr_service.dart';
import '../../features/history/history_controller.dart';
import '../../features/settings/settings_controller.dart';
import '../../shared/models/translation_entry.dart';

enum TranslatorError { noApiKey, apiError, networkError }

/// Why text recognition did not produce anything (ADR-037).
///
/// The last two are worth their own messages: both mean the user has to install
/// something, which no amount of retrying will fix. [languageMissing] carries
/// the package to install in `TranslatorState.ocrErrorDetail`.
enum OcrFailure { failed, engineMissing, languageMissing }

class TranslatorState {
  final String inputText;
  final String? outputText;

  /// Improvement notes returned in correction mode (ADR-033), `null` otherwise.
  final String? correctionNotes;

  /// True when the last result was a correction rather than a translation.
  final bool isCorrectionResult;
  final bool isLoading;
  final TranslatorError? error;
  final String? errorDetail;
  final String? lastSourceLang;
  final bool isSttAvailable;
  final bool isListening;
  final bool isOcrProcessing;

  /// Set when the last recognition attempt failed; `null` otherwise.
  final OcrFailure? ocrError;

  /// What to install, for [OcrFailure.languageMissing].
  final String? ocrErrorDetail;

  const TranslatorState({
    this.inputText = '',
    this.outputText,
    this.correctionNotes,
    this.isCorrectionResult = false,
    this.isLoading = false,
    this.error,
    this.errorDetail,
    this.lastSourceLang,
    this.isSttAvailable = false,
    this.isListening = false,
    this.isOcrProcessing = false,
    this.ocrError,
    this.ocrErrorDetail,
  });

  TranslatorState copyWith({
    String? inputText,
    String? outputText,
    String? correctionNotes,
    bool? isCorrectionResult,
    bool clearOutput = false,
    bool? isLoading,
    TranslatorError? error,
    String? errorDetail,
    bool clearError = false,
    String? lastSourceLang,
    bool? isSttAvailable,
    bool? isListening,
    bool? isOcrProcessing,
    OcrFailure? ocrError,
    String? ocrErrorDetail,
    bool clearOcrError = false,
  }) =>
      TranslatorState(
        inputText: inputText ?? this.inputText,
        outputText: clearOutput ? null : outputText ?? this.outputText,
        correctionNotes:
            clearOutput ? null : correctionNotes ?? this.correctionNotes,
        isCorrectionResult: clearOutput
            ? false
            : isCorrectionResult ?? this.isCorrectionResult,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
        lastSourceLang: lastSourceLang ?? this.lastSourceLang,
        isSttAvailable: isSttAvailable ?? this.isSttAvailable,
        isListening: isListening ?? this.isListening,
        isOcrProcessing: isOcrProcessing ?? this.isOcrProcessing,
        ocrError: clearOcrError ? null : ocrError ?? this.ocrError,
        ocrErrorDetail:
            clearOcrError ? null : ocrErrorDetail ?? this.ocrErrorDetail,
      );
}

class TranslatorController extends Notifier<TranslatorState> {
  final _stt = SpeechToText();

  @override
  TranslatorState build() {
    ref.onDispose(_stt.stop);
    Future.microtask(_initStt);
    return const TranslatorState();
  }

  Future<void> _initStt() async {
    try {
      final available = await _stt.initialize(
        onError: (e) => debugPrint('[STT] error: ${e.errorMsg}'),
        onStatus: (s) {
          if (s == SpeechToText.notListeningStatus) {
            state = state.copyWith(isListening: false);
          }
        },
      );
      state = state.copyWith(isSttAvailable: available);
    } catch (e) {
      debugPrint('[STT] init failed: $e');
    }
  }

  Future<void> toggleListening() async {
    if (state.isListening) {
      await _stt.stop();
      state = state.copyWith(isListening: false);
      return;
    }

    // Prefer explicit STT language from settings, fall back to auto-detected source lang.
    final sttLang = ref.read(settingsProvider).valueOrNull?.sttLanguage ?? '';
    final langCode = sttLang.isNotEmpty ? sttLang : state.lastSourceLang;
    final localeId = kSttLocaleMap[langCode];
    state = state.copyWith(isListening: true, clearOutput: true, clearError: true);

    await _stt.listen(
      onResult: _onSttResult,
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _onSttResult(SpeechRecognitionResult result) {
    state = state.copyWith(inputText: result.recognizedWords);
    if (result.finalResult) {
      state = state.copyWith(isListening: false);
      translate();
    }
  }

  Future<void> pickImageAndRecognize({required ImageSource source}) async {
    state = state.copyWith(isOcrProcessing: true);
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null) {
        state = state.copyWith(isOcrProcessing: false);
        return;
      }
      // Tesseract needs to know which trained data to load, and the user has
      // already said so in Settings — the same two languages the translation
      // logic runs on (ADR-037). ML Kit ignores them.
      final settings = ref.read(settingsProvider).valueOrNull;
      final text = await ref.read(ocrServiceProvider).recogniseText(
            file.path,
            primaryLanguage: settings?.targetLanguage ?? kDefaultTargetLanguage,
            altLanguage: settings?.altLanguage ?? kDefaultAltLanguage,
          );

      state = state.copyWith(
        inputText: text,
        isOcrProcessing: false,
        clearOutput: true,
        clearError: true,
      );
    } on OcrLanguageMissingException catch (e) {
      debugPrint('[OCR] $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.languageMissing,
        ocrErrorDetail: tesseractPackageHint(e.languageCodes),
      );
    } on OcrUnavailableException catch (e) {
      debugPrint('[OCR] engine unavailable: $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.engineMissing,
      );
    } catch (e) {
      debugPrint('[OCR] error: $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.failed,
      );
    }
  }

  void clearOcrError() {
    state = state.copyWith(clearOcrError: true);
  }

  void setInputText(String text) {
    state = state.copyWith(inputText: text, clearOutput: true, clearError: true);
  }

  void loadHistoryEntry(
    String sourceText,
    String resultText, {
    String mode = kModeTranslate,
    String? notes,
  }) {
    state = state.copyWith(
      inputText: sourceText,
      clearOutput: true,
      clearError: true,
    ).copyWith(
      outputText: resultText,
      correctionNotes: notes,
      isCorrectionResult: mode == kModeCorrect,
    );
  }

  void clearInput() {
    state = state.copyWith(
      inputText: '',
      clearOutput: true,
      clearError: true,
      isListening: false,
    );
  }

  Future<void> translate() async {
    final input = state.inputText.trim();
    if (input.isEmpty) return;

    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;

    if (!settings.hasApiKeyForActiveProvider) {
      state = state.copyWith(error: TranslatorError.noApiKey, clearError: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearOutput: true);

    try {
      final service = ref.read(aiServiceProvider);
      final raw = await service.translate(
        text: input,
        targetLanguage: settings.targetLanguage,
        altLanguage: settings.altLanguage,
        apiKey: settings.activeApiKey,
        correctionMode: settings.correctionMode,
      );

      final result = AiResult.parse(raw);
      final sourceLang = result.sourceLang;
      final translation = result.body;

      debugPrint('[TranslatorController] source=$sourceLang '
          'mode=${result.mode}');

      state = state.copyWith(
        isLoading: false,
        outputText: translation,
        correctionNotes: result.notes,
        isCorrectionResult: result.isCorrection,
        lastSourceLang: sourceLang ?? state.lastSourceLang,
        clearError: true,
      );

      // Save to SQLite and refresh history
      try {
        final dao = await ref.read(translationDaoProvider.future);
        await dao.insert(
          TranslationEntry(
            sourceText: input,
            resultText: translation,
            sourceLang: sourceLang ?? '',
            targetLang: settings.targetLanguage,
            aiProvider: settings.activeProvider,
            createdAt: DateTime.now().toUtc(),
            mode: result.mode,
            notes: result.notes,
          ),
        );
        ref.invalidate(historyProvider);
      } catch (e) {
        debugPrint('[TranslatorController] db save failed: $e');
      }
    } on AiApiException catch (e) {
      debugPrint('[TranslatorController] API error ${e.statusCode}: ${e.body}');
      state = state.copyWith(
        isLoading: false,
        error: TranslatorError.apiError,
        errorDetail: _statusDetail(e.statusCode),
      );
    } on SocketException {
      debugPrint('[TranslatorController] network error');
      state = state.copyWith(isLoading: false, error: TranslatorError.networkError);
    } catch (e) {
      debugPrint('[TranslatorController] unexpected error: $e');
      final msg = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: TranslatorError.apiError,
        errorDetail: msg.length > 120 ? '${msg.substring(0, 120)}…' : msg,
      );
    }
  }

  static String _statusDetail(int code) => switch (code) {
        401 => 'HTTP 401 · Invalid API key',
        403 => 'HTTP 403 · Access denied',
        429 => 'HTTP 429 · Rate limit exceeded — try again later',
        500 => 'HTTP 500 · Provider server error',
        502 || 503 || 504 => 'HTTP $code · Provider unavailable',
        _ => 'HTTP $code',
      };

}

/// Parsed AI response — `LANG:` / `MODE:` header lines plus an optional
/// `NOTES:` section (ADR-013, extended by ADR-033).
class AiResult {
  final String? sourceLang;
  final String mode;
  final String body;
  final String? notes;

  const AiResult({
    this.sourceLang,
    this.mode = kModeTranslate,
    required this.body,
    this.notes,
  });

  bool get isCorrection => mode == kModeCorrect;

  static AiResult parse(String raw) {
    final lines = raw.trim().split('\n');
    String? sourceLang;
    var mode = kModeTranslate;

    // Header lines may arrive in either order; both are optional.
    while (lines.isNotEmpty) {
      final first = lines.first.trim();
      if (sourceLang == null && first.startsWith('LANG:')) {
        sourceLang = first.substring(5).trim();
      } else if (first.startsWith('MODE:')) {
        final value = first.substring(5).trim().toLowerCase();
        mode = value.startsWith(kModeCorrect) ? kModeCorrect : kModeTranslate;
      } else {
        break;
      }
      lines.removeAt(0);
    }

    final notesIndex =
        lines.indexWhere((l) => l.trim().toUpperCase() == 'NOTES:');
    if (notesIndex < 0) {
      return AiResult(
        sourceLang: sourceLang,
        mode: mode,
        body: lines.join('\n').trim(),
      );
    }

    final notes = lines.skip(notesIndex + 1).join('\n').trim();
    return AiResult(
      sourceLang: sourceLang,
      mode: mode,
      body: lines.take(notesIndex).join('\n').trim(),
      notes: notes.isEmpty ? null : notes,
    );
  }
}

final translatorProvider = NotifierProvider<TranslatorController, TranslatorState>(
  TranslatorController.new,
);
