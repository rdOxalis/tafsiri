import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ai_service_factory.dart';
import '../../features/settings/settings_controller.dart';

enum TranslatorError { noApiKey, apiError, networkError }

class TranslatorState {
  final String inputText;
  final String? outputText;
  final bool isLoading;
  final TranslatorError? error;
  final String? lastSourceLang;

  const TranslatorState({
    this.inputText = '',
    this.outputText,
    this.isLoading = false,
    this.error,
    this.lastSourceLang,
  });

  TranslatorState copyWith({
    String? inputText,
    String? outputText,
    bool clearOutput = false,
    bool? isLoading,
    TranslatorError? error,
    bool clearError = false,
    String? lastSourceLang,
  }) =>
      TranslatorState(
        inputText: inputText ?? this.inputText,
        outputText: clearOutput ? null : outputText ?? this.outputText,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        lastSourceLang: lastSourceLang ?? this.lastSourceLang,
      );
}

class TranslatorController extends Notifier<TranslatorState> {
  @override
  TranslatorState build() => const TranslatorState();

  void setInputText(String text) {
    state = state.copyWith(inputText: text, clearOutput: true, clearError: true);
  }

  void clearInput() {
    state = const TranslatorState();
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

      // Phase 7: save entry to SQLite
      // TODO(phase7): await _dao.insert(TranslationEntry(...));

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
