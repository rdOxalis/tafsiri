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
      ));
    });
  });
}
