import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/features/settings/settings_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

/// ADR-062 — the backup panel says which choice belongs to which action.
///
/// Before, both switches sat above both buttons, and "Replace history" applies
/// to only one of them.
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

  Widget wrap() => const ProviderScope(
        child: MaterialApp(
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

  testWidgets('each action has its own heading, options and button',
      (tester) async {
    useTallWindow(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Save a backup'), findsOneWidget);
    expect(find.text('Restore from a backup'), findsOneWidget);

    // "Replace history" belongs to the restore half only, and must sit below
    // the restore heading rather than above both buttons.
    final restoreHeading = tester.getTopLeft(find.text('Restore from a backup'));
    final replaceSwitch = tester.getTopLeft(find.text('Replace history'));
    final saveButton = tester.getTopLeft(find.text('Save backup'));
    expect(replaceSwitch.dy, greaterThan(restoreHeading.dy));
    expect(replaceSwitch.dy, greaterThan(saveButton.dy),
        reason: 'the restore options must come after the save button');

    // Include-keys stays with saving.
    final includeSwitch = tester.getTopLeft(find.text('Include API keys'));
    expect(includeSwitch.dy, lessThan(saveButton.dy));
    expect(includeSwitch.dy, lessThan(restoreHeading.dy));
  });

  testWidgets('the two key switches are separate and default differently',
      (tester) async {
    useTallWindow(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    SwitchListTile tileWith(String label) => tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, label));

    // Writing keys into a file is the risky direction — off by default.
    expect(tileWith('Include API keys').value, isFalse);
    // Taking them back out is what a reinstall needs — on by default.
    expect(tileWith('Restore API keys').value, isTrue);
    // Destructive — off by default.
    expect(tileWith('Replace history').value, isFalse);
  });

  testWidgets('turning a switch on shows the consequence', (tester) async {
    useTallWindow(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // The unencrypted-keys warning only appears once the switch is on.
    expect(
      find.textContaining('stored unencrypted', findRichText: true),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Include API keys'));
    await tester.pumpAndSettle();
    expect(find.textContaining('unencrypted'), findsOneWidget);

    // Same for the destructive one.
    await tester.tap(find.widgetWithText(SwitchListTile, 'Replace history'));
    await tester.pumpAndSettle();
    expect(find.textContaining('deleted and replaced'), findsOneWidget);
  });
}
