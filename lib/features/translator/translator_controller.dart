import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants.dart';
import '../../core/database/dao_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ai_service_factory.dart';
import '../../features/settings/settings_controller.dart';
import '../../shared/models/translation_entry.dart';

enum TranslatorError { noApiKey, apiError, networkError }

class TranslatorState {
  final String inputText;
  final String? outputText;
  final bool isLoading;
  final TranslatorError? error;
  final String? lastSourceLang;
  final bool isSttAvailable;
  final bool isListening;

  const TranslatorState({
    this.inputText = '',
    this.outputText,
    this.isLoading = false,
    this.error,
    this.lastSourceLang,
    this.isSttAvailable = false,
    this.isListening = false,
  });

  TranslatorState copyWith({
    String? inputText,
    String? outputText,
    bool clearOutput = false,
    bool? isLoading,
    TranslatorError? error,
    bool clearError = false,
    String? lastSourceLang,
    bool? isSttAvailable,
    bool? isListening,
  }) =>
      TranslatorState(
        inputText: inputText ?? this.inputText,
        outputText: clearOutput ? null : outputText ?? this.outputText,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        lastSourceLang: lastSourceLang ?? this.lastSourceLang,
        isSttAvailable: isSttAvailable ?? this.isSttAvailable,
        isListening: isListening ?? this.isListening,
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

    final localeId = kSttLocaleMap[state.lastSourceLang];
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

  void setInputText(String text) {
    state = state.copyWith(inputText: text, clearOutput: true, clearError: true);
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
      );

      final sourceLang = _extractSourceLang(raw);
      final translation = _extractTranslation(raw);

      debugPrint('[TranslatorController] source=$sourceLang');

      state = state.copyWith(
        isLoading: false,
        outputText: translation,
        lastSourceLang: sourceLang ?? state.lastSourceLang,
        clearError: true,
      );

      // Save to SQLite
      final daoAsync = ref.read(translationDaoProvider);
      daoAsync.whenData((dao) => dao.insert(
            TranslationEntry(
              sourceText: input,
              resultText: translation,
              sourceLang: sourceLang ?? '',
              targetLang: settings.targetLanguage,
              aiProvider: settings.activeProvider,
              createdAt: DateTime.now().toUtc(),
            ),
          ));
    } on AiApiException catch (e) {
      debugPrint('[TranslatorController] API error ${e.statusCode}');
      state = state.copyWith(isLoading: false, error: TranslatorError.apiError);
    } on SocketException {
      debugPrint('[TranslatorController] network error');
      state = state.copyWith(isLoading: false, error: TranslatorError.networkError);
    } catch (e) {
      debugPrint('[TranslatorController] unexpected error: $e');
      state = state.copyWith(isLoading: false, error: TranslatorError.apiError);
    }
  }

  /// Parses `LANG:xx` from the first line of [raw] (ADR-013).
  static String? _extractSourceLang(String raw) {
    final first = raw.split('\n').first.trim();
    if (first.startsWith('LANG:')) return first.substring(5).trim();
    return null;
  }

  /// Returns the translation text, stripping the `LANG:xx` prefix line.
  static String _extractTranslation(String raw) {
    final lines = raw.split('\n');
    if (lines.first.trim().startsWith('LANG:')) {
      return lines.skip(1).join('\n').trim();
    }
    return raw.trim();
  }
}

final translatorProvider = NotifierProvider<TranslatorController, TranslatorState>(
  TranslatorController.new,
);
