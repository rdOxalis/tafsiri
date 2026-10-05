import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/ai_models.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/settings/settings_controller.dart';
import 'package:tafsiri/features/settings/settings_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

/// ADR-073 — the model is chosen per provider, stored per provider, and
/// reaches the request.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Tafsiri',
      packageName: 'ke.darkman.tafsiri',
      version: '1.0.19',
      buildNumber: '19',
      buildSignature: '',
    );
  });

  group('the controller', () {
    test('serves the default until a choice is made', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = await container.read(settingsProvider.future);

      expect(settings.modelFor(kProviderClaude), 'claude-sonnet-5-5');
      expect(settings.modelFor(kProviderMistral), 'mistral-small-latest');
      expect(settings.activeModel, settings.modelFor(settings.activeProvider));
    });

    test('stores a choice per provider and leaves the others alone', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);

      await container
          .read(settingsProvider.notifier)
          .setModel(kProviderClaude, 'claude-haiku-4-5');
      await container
          .read(settingsProvider.notifier)
          .setModel(kProviderMistral, 'mistral-medium-latest');

      final settings = container.read(settingsProvider).requireValue;
      expect(settings.modelFor(kProviderClaude), 'claude-haiku-4-5');
      expect(settings.modelFor(kProviderMistral), 'mistral-medium-latest');
      // Comparing two providers must not reset the other one's choice.
      expect(settings.modelFor(kProviderOpenAI), defaultModelFor(kProviderOpenAI));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${kPrefModelPrefix}claude'), 'claude-haiku-4-5');
    });

    test('a choice survives a restart', () async {
      SharedPreferences.setMockInitialValues({
        '${kPrefModelPrefix}claude': 'claude-haiku-4-5',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = await container.read(settingsProvider.future);
      expect(settings.modelFor(kProviderClaude), 'claude-haiku-4-5');
    });

    test('a model no longer offered falls back instead of being sent', () async {
      SharedPreferences.setMockInitialValues({
        '${kPrefModelPrefix}claude': 'claude-haiku-3',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = await container.read(settingsProvider.future);
      expect(settings.modelFor(kProviderClaude), 'claude-sonnet-5-5');
    });
  });

  group('upgrading an existing installation', () {
    // An app update never clears app data: same package, same signing key, so
    // SharedPreferences survives. What is new here is that a key the app has
    // never written is read for the first time, and that must not disturb what
    // is already stored.
    test('keeps the API key, and starts on the default model', () async {
      SharedPreferences.setMockInitialValues({
        kPrefApiKeyClaude: 'sk-set-before-the-update',
        kPrefActiveProvider: kProviderClaude,
        kPrefTargetLanguage: 'Swahili',
        kPrefAltLanguage: 'Deutsch',
        kPrefCorrectionMode: true,
        // No model_* key: this installation predates the choice.
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = await container.read(settingsProvider.future);

      expect(settings.apiKeyClaude, 'sk-set-before-the-update');
      expect(settings.activeProvider, kProviderClaude);
      expect(settings.targetLanguage, 'Swahili');
      expect(settings.altLanguage, 'Deutsch');
      expect(settings.correctionMode, isTrue);
      // And the model that fixes the defect this release is about.
      expect(settings.activeModel, 'claude-sonnet-5-5');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefApiKeyClaude), 'sk-set-before-the-update');
    });

    test('reading the models does not write anything', () async {
      SharedPreferences.setMockInitialValues({
        kPrefApiKeyMistral: 'sk-mistral',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);

      // The default is served, not stored: nothing is written until the user
      // picks, so a later change of default still reaches existing installs.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${kPrefModelPrefix}claude'), isNull);
      expect(prefs.getString(kPrefApiKeyMistral), 'sk-mistral');
    });
  });

  group('the settings screen', () {
    Widget wrap(ProviderContainer container) => UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en', 'GB')],
            locale: Locale('en', 'GB'),
            home: SettingsScreen(),
          ),
        );

    void useTallWindow(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('offers the active provider\'s models, with their tier',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);

      useTallWindow(tester);
      await tester.pumpWidget(wrap(container));
      await tester.pumpAndSettle();

      // Mistral is the default provider: free tier first, paid one offered.
      expect(find.text('Mistral Small · free tier'), findsWidgets);

      await tester.tap(find.byKey(const Key('modelPicker')));
      await tester.pumpAndSettle();
      expect(find.text('Mistral Medium · best quality'), findsWidgets);

      await tester.tap(find.text('Mistral Medium · best quality').last);
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).requireValue
          .modelFor(kProviderMistral), 'mistral-medium-latest');
    });

    testWidgets('a provider with one model shows a line, not a menu',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setActiveProvider(kProviderOpenAI);

      useTallWindow(tester);
      await tester.pumpWidget(wrap(container));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('modelPicker')), findsNothing);
      expect(find.text('GPT-5.6 Luna · best quality'), findsOneWidget);
    });
  });
}
