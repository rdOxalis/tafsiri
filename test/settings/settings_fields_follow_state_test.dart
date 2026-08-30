import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/settings/settings_controller.dart';
import 'package:tafsiri/features/settings/settings_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

/// ADR-064 — the fields show what is stored, not what was stored when the
/// screen opened.
///
/// The case that started this: restoring a backup into an install with no API
/// key left the key field empty, so a restore that had worked looked like it
/// had not happened.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Tafsiri',
      packageName: 'ke.darkman.tafsiri',
      version: '1.0.15',
      buildNumber: '15',
      buildSignature: '',
    );
  });

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

  testWidgets('a restored key appears without reopening the screen',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    useTallWindow(tester);
    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    // An empty install: nothing in the active provider's key field.
    final keyField = find.widgetWithText(TextField, 'Mistral API Key');
    expect(tester.widget<TextField>(keyField).controller?.text, '');

    // What a restore does to the settings.
    await container.read(settingsProvider.notifier).restore(
          const SettingsState(
            apiKeyMistral: 'sk-restored',
            apiKeyClaude: '',
            apiKeyOpenAI: '',
            activeProvider: kProviderMistral,
            targetLanguage: 'Swahili',
            altLanguage: 'Deutsch',
            sttLanguage: '',
          ),
          restoreApiKeys: true,
        );
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(keyField).controller?.text,
        'sk-restored');
  });

  testWidgets('the language fields follow a restore too', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    useTallWindow(tester);
    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await container.read(settingsProvider.notifier).restore(
          const SettingsState(
            apiKeyMistral: '',
            apiKeyClaude: '',
            apiKeyOpenAI: '',
            activeProvider: kProviderMistral,
            targetLanguage: 'Swahili',
            altLanguage: 'Deutsch',
            sttLanguage: '',
          ),
          restoreApiKeys: false,
        );
    await tester.pumpAndSettle();

    expect(find.text('Swahili'), findsWidgets);
    expect(find.text('Deutsch'), findsWidgets);
  });

  testWidgets('typing is not interrupted by the sync', (tester) async {
    // The field writes the setting on every keystroke, which comes straight
    // back as a new state — the sync must not rewrite the field under the
    // cursor while that happens.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    useTallWindow(tester);
    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    final keyField = find.widgetWithText(TextField, 'Mistral API Key');
    await tester.enterText(keyField, 'sk-typed-by-hand');
    await tester.pumpAndSettle();

    final controller = tester.widget<TextField>(keyField).controller!;
    expect(controller.text, 'sk-typed-by-hand');
    expect(controller.selection.baseOffset, 'sk-typed-by-hand'.length);
  });
}
