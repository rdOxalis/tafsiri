import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/features/settings/settings_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

/// The About section at the foot of Settings: the version someone is asked for
/// when reporting a bug, the licence list the dependencies oblige us to show,
/// and the way back to the source.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Tafsiri',
      packageName: 'ke.darkman.tafsiri',
      version: '1.0.12',
      buildNumber: '12',
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

  /// A viewport tall enough for the whole settings page, so nothing has to be
  /// scrolled into view — the screen holds several scrollables and asking for
  /// "the" one is ambiguous.
  void useTallWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('lists the version, the licences and the source', (tester) async {
    useTallWindow(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version 1.0.12+12'), findsOneWidget);
    expect(find.text('Open Source Licences'), findsOneWidget);
    expect(find.text('Source code on GitHub'), findsOneWidget);
    // The donate entry moved into this section rather than being replaced.
    expect(find.text('Buy me a coffee'), findsOneWidget);
  });

  testWidgets('the licence entry opens the licence page', (tester) async {
    // Flutter's own page, so what is worth pinning is that it opens at all and
    // arrives carrying the app's name rather than the default "flutter".
    useTallWindow(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Source Licences'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('Tafsiri'), findsWidgets);
  });
}
