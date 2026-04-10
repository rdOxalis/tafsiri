import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/features/translator/translator_controller.dart';
import 'package:tafsiri/features/translator/translator_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

class _FakeTranslatorController extends TranslatorController {
  final TranslatorState _initial;
  _FakeTranslatorController([TranslatorState? initial])
      : _initial = initial ?? const TranslatorState();

  @override
  TranslatorState build() => _initial;

  @override
  Future<void> translate() async {}
}

Widget _wrap(Widget child, {TranslatorState? state}) {
  return ProviderScope(
    overrides: [
      translatorProvider.overrideWith(
          () => _FakeTranslatorController(state)),
    ],
    child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'GB')],
        locale: const Locale('en', 'GB'),
        home: Scaffold(body: child),
      ),
    );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TranslatorScreen', () {
    testWidgets('renders input hint and translate button', (tester) async {
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pump();

      expect(find.text('Enter text to translate…'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
    });

    testWidgets('renders output hint when no output', (tester) async {
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pump();

      expect(find.text('Translation will appear here'), findsOneWidget);
    });

    testWidgets('renders loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(isLoading: true),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('renders translation output', (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(outputText: 'Habari'),
      ));
      await tester.pump();

      expect(find.text('Habari'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('renders error message for noApiKey', (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(error: TranslatorError.noApiKey),
      ));
      await tester.pump();

      expect(
        find.text('No API key set. Please add your key in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('mic and image buttons are present', (tester) async {
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
    });
  });
}
