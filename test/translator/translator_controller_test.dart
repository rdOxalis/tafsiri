import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/ai_service_factory.dart';
import 'package:tafsiri/features/settings/settings_controller.dart';
import 'package:tafsiri/features/translator/translator_controller.dart';
import 'mock_ai_service.mocks.dart';

ProviderContainer makeContainer({
  required MockAiService mockService,
  Map<String, Object> prefs = const {},
}) {
  SharedPreferences.setMockInitialValues({
    kPrefApiKeyClaude: 'sk-test',
    kPrefActiveProvider: kProviderClaude,
    kPrefTargetLanguage: 'Swahili',
    kPrefAltLanguage: 'English',
    ...prefs,
  });

  return ProviderContainer(
    overrides: [
      aiServiceProvider.overrideWithValue(mockService),
    ],
  );
}

void main() {
  late MockAiService mockService;

  setUp(() {
    mockService = MockAiService();
  });

  group('TranslatorController', () {
    test('initial state is empty', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(translatorProvider);
      expect(state.inputText, '');
      expect(state.outputText, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('setInputText updates inputText and clears output', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(translatorProvider.notifier).setInputText('Hello');
      expect(container.read(translatorProvider).inputText, 'Hello');
    });

    test('clearInput resets state', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(translatorProvider.notifier).setInputText('Hello');
      container.read(translatorProvider.notifier).clearInput();
      final state = container.read(translatorProvider);
      expect(state.inputText, '');
      expect(state.outputText, isNull);
    });

    test('translate sets output and lastSourceLang on success', () async {
      final container = makeContainer(mockService: mockService);
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async => 'LANG:en\nHabari');

      // Wait for settings to load
      await container.read(settingsProvider.future);

      container.read(translatorProvider.notifier).setInputText('Hello');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.outputText, 'Habari');
      expect(state.lastSourceLang, 'en');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('translate strips LANG prefix from multi-line response', () async {
      final container = makeContainer(mockService: mockService);
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async => 'LANG:de\nLine one\nLine two');

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Hallo');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.outputText, 'Line one\nLine two');
      expect(state.lastSourceLang, 'de');
    });

    test('translate handles response without LANG prefix gracefully', () async {
      final container = makeContainer(mockService: mockService);
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async => 'Habari');

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Hello');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.outputText, 'Habari');
      expect(state.lastSourceLang, isNull);
    });

    test('translate sets apiError on AiApiException', () async {
      final container = makeContainer(mockService: mockService);
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenThrow(const AiApiException(401, 'unauthorized'));

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Hello');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.error, TranslatorError.apiError);
      expect(state.isLoading, isFalse);
    });

    test('translate sets networkError on SocketException', () async {
      final container = makeContainer(mockService: mockService);
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenThrow(const SocketException('no connection'));

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Hello');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.error, TranslatorError.networkError);
      expect(state.isLoading, isFalse);
    });

    test('translate sets noApiKey error when key missing', () async {
      final container = makeContainer(
        mockService: mockService,
        prefs: {
          kPrefApiKeyClaude: '',
          kPrefActiveProvider: kProviderClaude,
        },
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Hello');
      await container.read(translatorProvider.notifier).translate();

      expect(
        container.read(translatorProvider).error,
        TranslatorError.noApiKey,
      );
      verifyNever(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      ));
    });

    test('translate does nothing when input is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [aiServiceProvider.overrideWithValue(mockService)],
      );
      addTearDown(container.dispose);

      await container.read(translatorProvider.notifier).translate();

      verifyNever(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      ));
    });

    test('correction mode is passed through to the AI service', () async {
      final container = makeContainer(
        mockService: mockService,
        prefs: {kPrefCorrectionMode: true},
      );
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async => 'LANG:sw\nMODE:correct\nTafadhali nipe siagi.');

      await container.read(settingsProvider.future);
      container
          .read(translatorProvider.notifier)
          .setInputText('Tafadhali nipe Butter.');
      await container.read(translatorProvider.notifier).translate();

      verify(mockService.translate(
        text: 'Tafadhali nipe Butter.',
        targetLanguage: 'Swahili',
        altLanguage: 'English',
        apiKey: 'sk-test',
        correctionMode: true,
      )).called(1);
    });

    test('correction response splits body and notes', () async {
      final container = makeContainer(
        mockService: mockService,
        prefs: {kPrefCorrectionMode: true},
      );
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async => 'LANG:sw\n'
          'MODE:correct\n'
          'Tafadhali nipe siagi.\n'
          'NOTES:\n'
          '- Butter → siagi: German for "butter".');

      await container.read(settingsProvider.future);
      container
          .read(translatorProvider.notifier)
          .setInputText('Tafadhali nipe Butter.');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.outputText, 'Tafadhali nipe siagi.');
      expect(state.correctionNotes, '- Butter → siagi: German for "butter".');
      expect(state.isCorrectionResult, isTrue);
      expect(state.lastSourceLang, 'sw');
    });

    test('correction mode still translates foreign input', () async {
      final container = makeContainer(
        mockService: mockService,
        prefs: {kPrefCorrectionMode: true},
      );
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async => 'LANG:de\nMODE:translate\nHabari');

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Hallo');
      await container.read(translatorProvider.notifier).translate();

      final state = container.read(translatorProvider);
      expect(state.outputText, 'Habari');
      expect(state.isCorrectionResult, isFalse);
      expect(state.correctionNotes, isNull);
    });

    test('a new input clears the previous correction notes', () async {
      final container = makeContainer(
        mockService: mockService,
        prefs: {kPrefCorrectionMode: true},
      );
      addTearDown(container.dispose);

      when(mockService.translate(
        text: anyNamed('text'),
        targetLanguage: anyNamed('targetLanguage'),
        altLanguage: anyNamed('altLanguage'),
        apiKey: anyNamed('apiKey'),
        correctionMode: anyNamed('correctionMode'),
      )).thenAnswer((_) async =>
          'LANG:sw\nMODE:correct\nNipe siagi.\nNOTES:\n- Butter → siagi');

      await container.read(settingsProvider.future);
      container.read(translatorProvider.notifier).setInputText('Nipe Butter');
      await container.read(translatorProvider.notifier).translate();
      expect(container.read(translatorProvider).correctionNotes, isNotNull);

      container.read(translatorProvider.notifier).setInputText('Something else');
      final state = container.read(translatorProvider);
      expect(state.correctionNotes, isNull);
      expect(state.isCorrectionResult, isFalse);
    });
  });

  group('AiResult.parse', () {
    test('reads LANG and MODE headers', () {
      final result = AiResult.parse('LANG:sw\nMODE:correct\nNipe siagi.');
      expect(result.sourceLang, 'sw');
      expect(result.mode, kModeCorrect);
      expect(result.isCorrection, isTrue);
      expect(result.body, 'Nipe siagi.');
      expect(result.notes, isNull);
    });

    test('accepts the headers in reverse order', () {
      final result = AiResult.parse('MODE:correct\nLANG:sw\nNipe siagi.');
      expect(result.sourceLang, 'sw');
      expect(result.mode, kModeCorrect);
      expect(result.body, 'Nipe siagi.');
    });

    test('splits a NOTES section from a multi-line body', () {
      final result = AiResult.parse(
        'LANG:sw\nMODE:correct\nLine one\nLine two\nNOTES:\n- a\n- b',
      );
      expect(result.body, 'Line one\nLine two');
      expect(result.notes, '- a\n- b');
    });

    test('defaults to translate mode when no MODE header is present', () {
      final result = AiResult.parse('LANG:en\nHabari');
      expect(result.mode, kModeTranslate);
      expect(result.isCorrection, isFalse);
      expect(result.body, 'Habari');
    });

    test('handles a bare response without any header', () {
      final result = AiResult.parse('Habari');
      expect(result.sourceLang, isNull);
      expect(result.mode, kModeTranslate);
      expect(result.body, 'Habari');
    });

    test('drops an empty NOTES section', () {
      final result = AiResult.parse('LANG:sw\nMODE:correct\nNipe siagi.\nNOTES:');
      expect(result.body, 'Nipe siagi.');
      expect(result.notes, isNull);
    });
  });
}
