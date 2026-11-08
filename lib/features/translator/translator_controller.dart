import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dictation.dart';
import '../../core/constants.dart';
import '../../core/languages.dart';
import '../../core/database/dao_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ai_service_factory.dart';
import '../../core/services/clipboard/clipboard_image_service_factory.dart';
import '../../core/diagnostics_log.dart';
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
enum OcrFailure { failed, engineMissing, languageMissing, downloadFailed }

class TranslatorState {
  final String inputText;
  final String? outputText;

  /// The input the current [outputText] was produced from (ADR-055).
  ///
  /// Kept so an edit above can be told from the result below without throwing
  /// the result away — see [isOutputStale].
  final String? outputSourceText;

  /// Improvement notes returned in correction mode (ADR-033), `null` otherwise.
  final String? correctionNotes;

  /// Dictionary-style word explanations (ADR-060), `null` when the switch is
  /// off or the exchange had nothing worth explaining.
  final String? explanations;

  /// True when the last result was a correction rather than a translation.
  final bool isCorrectionResult;
  final bool isLoading;
  final TranslatorError? error;
  final String? errorDetail;
  final String? lastSourceLang;
  final bool isSttAvailable;
  /// True while the dictation window is open (ADR-081).
  final bool isDictating;

  /// The language the dictation window recognises (ADR-080); `null` before
  /// the first dictation, or for the device's own language.
  final String? sttLang;

  /// True while the recogniser is taking speech. The window opens with it
  /// off; the user starts each part, and a pause ends it.
  final bool isMicHot;

  /// What the dictation has heard so far, shown in the window only.
  final String dictationPreview;
  final bool isOcrProcessing;

  /// Set when the last recognition attempt failed; `null` otherwise.
  final OcrFailure? ocrError;

  /// What to install, for [OcrFailure.languageMissing].
  final String? ocrErrorDetail;

  /// True while the result on screen belongs to an earlier version of the input.
  ///
  /// In correction mode the notes are the whole point of the result, and the
  /// user works them into the text above — so the result has to survive the
  /// editing and only say that it no longer matches (ADR-055).
  bool get isOutputStale =>
      outputText != null &&
      inputText.trim() != (outputSourceText ?? '').trim();

  const TranslatorState({
    this.inputText = '',
    this.outputText,
    this.outputSourceText,
    this.correctionNotes,
    this.explanations,
    this.isCorrectionResult = false,
    this.isLoading = false,
    this.error,
    this.errorDetail,
    this.lastSourceLang,
    this.isSttAvailable = false,
    this.isDictating = false,
    this.sttLang,
    this.isMicHot = false,
    this.dictationPreview = '',
    this.isOcrProcessing = false,
    this.ocrError,
    this.ocrErrorDetail,
  });

  TranslatorState copyWith({
    String? inputText,
    String? outputText,
    String? outputSourceText,
    String? correctionNotes,
    String? explanations,
    bool? isCorrectionResult,
    bool clearOutput = false,
    bool? isLoading,
    TranslatorError? error,
    String? errorDetail,
    bool clearError = false,
    String? lastSourceLang,
    bool? isSttAvailable,
    bool? isDictating,
    String? sttLang,
    bool? isMicHot,
    String? dictationPreview,
    bool? isOcrProcessing,
    OcrFailure? ocrError,
    String? ocrErrorDetail,
    bool clearOcrError = false,
  }) =>
      TranslatorState(
        inputText: inputText ?? this.inputText,
        outputText: clearOutput ? null : outputText ?? this.outputText,
        outputSourceText: clearOutput
            ? null
            : outputSourceText ?? this.outputSourceText,
        correctionNotes:
            clearOutput ? null : correctionNotes ?? this.correctionNotes,
        explanations: clearOutput ? null : explanations ?? this.explanations,
        isCorrectionResult: clearOutput
            ? false
            : isCorrectionResult ?? this.isCorrectionResult,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
        lastSourceLang: lastSourceLang ?? this.lastSourceLang,
        isSttAvailable: isSttAvailable ?? this.isSttAvailable,
        isDictating: isDictating ?? this.isDictating,
        sttLang: sttLang ?? this.sttLang,
        isMicHot: isMicHot ?? this.isMicHot,
        dictationPreview: dictationPreview ?? this.dictationPreview,
        isOcrProcessing: isOcrProcessing ?? this.isOcrProcessing,
        ocrError: clearOcrError ? null : ocrError ?? this.ocrError,
        ocrErrorDetail:
            clearOcrError ? null : ocrErrorDetail ?? this.ocrErrorDetail,
      );
}

class TranslatorController extends Notifier<TranslatorState> {
  final _stt = SpeechToText();

  // Dictation (ADR-081). The window opens silent; each tap on its microphone
  // starts one recognition session, which Android ends at the next pause.
  // The text of all sessions is collected until the user takes it over.
  bool _dictating = false;
  int _dictationSession = 0;
  final _dictation = DictationBuffer();

  @override
  TranslatorState build() {
    ref.onDispose(() {
      _dictating = false;
      _stt.stop();
    });
    Future.microtask(_initStt);
    return const TranslatorState();
  }

  Future<void> _initStt() async {
    try {
      final available = await _stt.initialize(
        // Plugin-side logging (logcat tag SpeechToTextPlugin), for builds
        // made to diagnose recognition on a device.
        debugLogging:
            const bool.fromEnvironment('TAFSIRI_STT_DEBUG'),
        onError: (e) =>
            diagLog('stt: error ${e.errorMsg} (permanent: ${e.permanent})'),
        onStatus: _onSttStatus,
      );
      // Logged whichever way it goes. `initialize` reporting false without
      // throwing is the ordinary way this fails — the microphone then sits
      // there greyed out and nothing anywhere says why, which is exactly the
      // silence that cost four rounds on the OCR side (ADR-044).
      diagLog('stt: initialize -> $available');
      if (!available) {
        diagLog('stt: has permission -> ${await _stt.hasPermission}');
      }
      state = state.copyWith(isSttAvailable: available);
    } catch (e) {
      diagLog('stt: initialize threw $e');
    }
  }

  void _onSttStatus(String s) {
    diagLog('stt: status $s (session $_dictationSession)');
    if (!_dictating) return;
    state = state.copyWith(isMicHot: s == SpeechToText.listeningStatus);
  }

  /// Opens the dictation window. Nothing is recorded until [toggleSpeaking].
  void openDictation() {
    if (_dictating) return;
    final settings = ref.read(settingsProvider).valueOrNull;
    _dictating = true;
    _dictation.reset();
    state = state.copyWith(
      isDictating: true,
      isMicHot: false,
      dictationPreview: '',
      sttLang: initialSttLanguage(
        chosenInWindow: state.sttLang,
        setting: settings?.sttLanguage ?? '',
        lastSourceLang: state.lastSourceLang,
        learningLanguage: settings?.targetLanguage ?? '',
      ),
      clearError: true,
    );
  }

  /// The window's microphone: starts a part, or ends the running one early.
  Future<void> toggleSpeaking() async {
    if (!_dictating) return;
    if (state.isMicHot) {
      await _stt.stop();
      return;
    }
    final session = ++_dictationSession;
    _dictation.startSession();
    // Shown at once; the recogniser's own `listening` status follows.
    state = state.copyWith(isMicHot: true);
    try {
      await _stt.listen(
        onResult: (result) => _onDictationResult(session, result),
        localeId: kSttLocaleMap[state.sttLang],
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      diagLog('stt: listen threw $e');
      state = state.copyWith(isMicHot: false);
    }
  }

  /// Changes the recognition language. A part being spoken is ended; the
  /// next one is recognised in [code].
  Future<void> setDictationLanguage(String code) async {
    state = state.copyWith(sttLang: code);
    if (_dictating && state.isMicHot) await _stt.stop();
  }

  /// Takes the text over into the input field and closes the window. Not
  /// translated: a dictation in a language being learnt usually wants a look
  /// first, and the translate button is right there.
  Future<void> finishDictation() async {
    if (!_dictating) return;
    if (state.isMicHot) {
      await _stt.stop();
      // The final result of a stopped session arrives a moment later
      // (about 250 ms on the Galaxy S25); the partial words are kept anyway.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    _closeDictation();
    final text = _dictation.text;
    if (text.isNotEmpty) {
      state = state.copyWith(inputText: text, clearOutput: true);
    }
  }

  /// Closes the window and keeps nothing that was said.
  Future<void> cancelDictation() async {
    if (!_dictating) return;
    _closeDictation();
    _dictation.reset();
    await _stt.cancel();
  }

  void _closeDictation() {
    _dictating = false;
    _dictationSession++;
    state = state.copyWith(
      isDictating: false,
      isMicHot: false,
      dictationPreview: '',
    );
  }

  void _onDictationResult(int session, SpeechRecognitionResult result) {
    if (result.finalResult) {
      diagLog('stt: final result, session $session/$_dictationSession, '
          '${result.recognizedWords.length} chars');
    }
    // A late result from a window already closed.
    if (!_dictating || session != _dictationSession) return;
    _dictation.update(result.recognizedWords, isFinal: result.finalResult);
    state = state.copyWith(dictationPreview: _dictation.text);
  }

  Future<void> pickImageAndRecognize({required ImageSource source}) async {
    state = state.copyWith(isOcrProcessing: true);

    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source);
    } catch (e) {
      diagLog('image picker failed: $e');
      state =
          state.copyWith(isOcrProcessing: false, ocrError: OcrFailure.failed);
      return;
    }
    if (file == null) {
      state = state.copyWith(isOcrProcessing: false);
      return;
    }

    await _recogniseInto(file.path);
  }

  /// Runs recognition on an image the clipboard was holding (ADR-040).
  ///
  /// Returns false when there was no image, which is the ordinary case and has
  /// to stay silent: the caller then pastes text, exactly as it did before this
  /// existed. Only an image found *and* read counts as handled.
  Future<bool> pasteImageFromClipboard() async {
    // A keystroke can be repeated far faster than recognition finishes, and two
    // runs would race for the input field. Reported as handled, not as "no
    // image" — falling through to a text paste here would be worse than
    // ignoring the press.
    if (state.isOcrProcessing) return true;

    // Logged before anything else, because "Ctrl+V does nothing" has two very
    // different causes — the keystroke never reaching here, or the clipboard
    // holding no image — and only one of them is a bug in this code.
    diagLog('clipboard: paste requested');

    final File? file;
    try {
      file = await ref.read(clipboardImageServiceProvider).readImage();
    } catch (e) {
      diagLog('clipboard: read failed: $e');
      return false;
    }
    if (file == null) {
      diagLog('clipboard: no image — falling back to text');
      return false;
    }

    state = state.copyWith(isOcrProcessing: true);
    try {
      await _recogniseInto(file.path);
    } finally {
      // The temporary directory belongs to us and nothing reads it after
      // recognition; a failure to tidy up must not mask the result.
      try {
        await file.parent.delete(recursive: true);
      } on IOException catch (e) {
        diagLog('clipboard: could not remove the temporary file: $e');
      }
    }
    return true;
  }

  /// Recognition and its failure modes, shared by every way an image arrives.
  ///
  /// Assumes `isOcrProcessing` is already set, and always clears it.
  Future<void> _recogniseInto(String imagePath) async {
    try {
      // Tesseract needs to know which trained data to load, and the user has
      // already said so in Settings — the same two languages the translation
      // logic runs on (ADR-037). On Android these are also the two it fetches
      // on first use (ADR-075).
      final settings = ref.read(settingsProvider).valueOrNull;
      final primary = settings?.targetLanguage ?? kDefaultTargetLanguage;
      final alt = settings?.altLanguage ?? kDefaultAltLanguage;
      diagLog('settings: primary="$primary" alt="$alt"');

      final text = await ref.read(ocrServiceProvider).recogniseText(
            imagePath,
            primaryLanguage: primary,
            altLanguage: alt,
          );
      diagLog('OK: ${text.length} chars');

      state = state.copyWith(
        inputText: text,
        isOcrProcessing: false,
        clearOutput: true,
        clearError: true,
      );
    } on OcrLanguageMissingException catch (e) {
      diagLog('languageMissing: $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.languageMissing,
        ocrErrorDetail: tesseractPackageHint(e.languageCodes),
      );
    } on OcrDataDownloadException catch (e) {
      // Android fetches trained data on first use (ADR-075): the remedy is a
      // connection, not an installation, so it gets its own message.
      diagLog('trained data download failed: $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.downloadFailed,
      );
    } on OcrUnavailableException catch (e) {
      diagLog('engine unavailable: $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.engineMissing,
      );
    } catch (e) {
      diagLog('failed: $e');
      state = state.copyWith(
        isOcrProcessing: false,
        ocrError: OcrFailure.failed,
      );
    }
  }

  void clearOcrError() {
    state = state.copyWith(clearOcrError: true);
  }

  /// Edits to the input leave the result standing (ADR-055).
  ///
  /// The result is what the user is editing *from* — in correction mode the
  /// suggestions are worked into the text word by word, and wiping them on the
  /// first keystroke took the reference away. It is only marked as no longer
  /// matching ([TranslatorState.isOutputStale]) and replaced on the next run.
  void setInputText(String text) {
    state = state.copyWith(inputText: text, clearError: true);
  }

  void loadHistoryEntry(
    String sourceText,
    String resultText, {
    String mode = kModeTranslate,
    String? notes,
    String? explanations,
  }) {
    state = state.copyWith(
      inputText: sourceText,
      clearOutput: true,
      clearError: true,
    ).copyWith(
      outputText: resultText,
      outputSourceText: sourceText,
      correctionNotes: notes,
      explanations: explanations,
      isCorrectionResult: mode == kModeCorrect,
    );
  }

  void clearInput() {
    state = state.copyWith(
      inputText: '',
      clearOutput: true,
      clearError: true,
    );
  }

  Future<void> translate() async {
    // The button is disabled while loading, but speech recognition calls this
    // directly, and some devices deliver the final result twice — which saved
    // the same translation twice.
    if (state.isLoading) return;
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
        model: settings.activeModel,
        correctionMode: settings.correctionMode,
        explanations: settings.explanationsMode,
      );

      final result = AiResult.parse(raw);
      final sourceLang = result.sourceLang;
      final translation = result.body;

      debugPrint('[TranslatorController] source=$sourceLang '
          'mode=${result.mode}');

      state = state.copyWith(
        isLoading: false,
        outputText: translation,
        outputSourceText: input,
        correctionNotes: result.notes,
        explanations: result.explanations,
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
            explanations: result.explanations,
            resultLang: resultLanguageFor(
              sourceLang: sourceLang ?? '',
              learningLanguage: settings.targetLanguage,
              confidentLanguage: settings.altLanguage,
              isCorrection: result.isCorrection,
            ),
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

  /// The EXPLAIN: section (ADR-060), `null` when the model sent none.
  final String? explanations;

  const AiResult({
    this.sourceLang,
    this.mode = kModeTranslate,
    required this.body,
    this.notes,
    this.explanations,
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

    // EXPLAIN: comes last, so it is cut off first — whatever remains is then
    // split into body and NOTES: exactly as before (ADR-060).
    String? explanations;
    final explainIndex =
        lines.indexWhere((l) => l.trim().toUpperCase() == 'EXPLAIN:');
    if (explainIndex >= 0) {
      final section = lines.skip(explainIndex + 1).join('\n').trim();
      explanations = section.isEmpty ? null : section;
      lines.removeRange(explainIndex, lines.length);
    }

    final notesIndex =
        lines.indexWhere((l) => l.trim().toUpperCase() == 'NOTES:');
    if (notesIndex < 0) {
      return AiResult(
        sourceLang: sourceLang,
        mode: mode,
        body: lines.join('\n').trim(),
        explanations: explanations,
      );
    }

    final notes = lines.skip(notesIndex + 1).join('\n').trim();
    return AiResult(
      sourceLang: sourceLang,
      mode: mode,
      body: lines.take(notesIndex).join('\n').trim(),
      notes: notes.isEmpty ? null : notes,
      explanations: explanations,
    );
  }
}

final translatorProvider = NotifierProvider<TranslatorController, TranslatorState>(
  TranslatorController.new,
);
