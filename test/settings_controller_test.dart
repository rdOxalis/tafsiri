import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/settings/settings_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer() => ProviderContainer();

  group('SettingsController', () {
    test('loads default values when no prefs set', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state =
          await container.read(settingsProvider.future);

      expect(state.apiKeyMistral, isEmpty);
      expect(state.apiKeyClaude, isEmpty);
      expect(state.apiKeyOpenAI, isEmpty);
      expect(state.activeProvider, kDefaultProvider);
      expect(state.targetLanguage, kDefaultTargetLanguage);
      expect(state.altLanguage, kDefaultAltLanguage);
    });

    test('loads persisted values from prefs', () async {
      SharedPreferences.setMockInitialValues({
        kPrefApiKeyMistral: 'mk-test',
        kPrefApiKeyClaude: 'ck-test',
        kPrefActiveProvider: kProviderClaude,
        kPrefTargetLanguage: 'German',
        kPrefAltLanguage: 'French',
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(settingsProvider.future);

      expect(state.apiKeyMistral, 'mk-test');
      expect(state.apiKeyClaude, 'ck-test');
      expect(state.activeProvider, kProviderClaude);
      expect(state.targetLanguage, 'German');
      expect(state.altLanguage, 'French');
    });

    test('setApiKey persists and updates state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setApiKey(kProviderMistral, 'mk-new');

      final state = container.read(settingsProvider).requireValue;
      expect(state.apiKeyMistral, 'mk-new');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefApiKeyMistral), 'mk-new');
    });

    test('setActiveProvider persists and updates state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setActiveProvider(kProviderOpenAI);

      final state = container.read(settingsProvider).requireValue;
      expect(state.activeProvider, kProviderOpenAI);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefActiveProvider), kProviderOpenAI);
    });

    test('hasApiKeyForActiveProvider returns false when key empty', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(settingsProvider.future);
      expect(state.hasApiKeyForActiveProvider, isFalse);
    });

    test('hasApiKeyForActiveProvider returns true when key set', () async {
      SharedPreferences.setMockInitialValues({
        kPrefActiveProvider: kProviderClaude,
        kPrefApiKeyClaude: 'sk-abc123',
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(settingsProvider.future);
      expect(state.hasApiKeyForActiveProvider, isTrue);
    });

    test('setTargetLanguage persists correctly', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setTargetLanguage('Swahili');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefTargetLanguage), 'Swahili');
    });

    test('setAltLanguage persists correctly', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setAltLanguage('English');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefAltLanguage), 'English');
    });
  });
}
