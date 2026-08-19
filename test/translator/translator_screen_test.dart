import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/constants.dart';
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

    /// The platform override has to be cleared inside the test body: the test
    /// framework asserts every foundation debug variable is unset when the body
    /// returns, which is before `addTearDown` callbacks run.
    Future<void> onPlatform(
      TargetPlatform platform,
      Future<void> Function() body,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await body();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    testWidgets('mic and image buttons are present on mobile', (tester) async {
      await onPlatform(TargetPlatform.android, () async {
        await tester.pumpWidget(_wrap(const TranslatorScreen()));
        await tester.pump();

        expect(find.byIcon(Icons.mic_none), findsOneWidget);
        expect(find.byIcon(Icons.image), findsOneWidget);
      });
    });

    testWidgets('the mic is gone on Linux, the image button stays',
        (tester) async {
      // Linux is the one target `speech_to_text` has no implementation for, so
      // the button was permanently greyed out with no setting anywhere that
      // could enable it — which reads as "not right now" rather than "not here"
      // (ADR-039). OCR does work on Linux, so its button must survive.
      await onPlatform(TargetPlatform.linux, () async {
        await tester.pumpWidget(_wrap(const TranslatorScreen()));
        await tester.pump();

        expect(find.byIcon(Icons.mic_none), findsNothing);
        expect(find.byIcon(Icons.mic), findsNothing);
        expect(find.byIcon(Icons.image), findsOneWidget);
      });
    });

    testWidgets('the mic survives on Windows and macOS', (tester) async {
      // The correction that nearly shipped: hiding it on "not mobile" would
      // have taken it off Windows and macOS too, where speech_to_text does have
      // an implementation — Windows through speech_to_text_windows (ADR-039).
      for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
        await onPlatform(platform, () async {
          await tester.pumpWidget(_wrap(const TranslatorScreen()));
          await tester.pump();

          expect(find.byIcon(Icons.mic_none), findsOneWidget,
              reason: 'the microphone must stay on $platform');
        });
      }
    });
  });

  group('TranslatorScreen correction mode', () {
    testWidgets('toggle is off by default', (tester) async {
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pumpAndSettle();

      // The state is spelled out, not only signalled by the fill colour.
      expect(
        find.widgetWithText(FilterChip, 'Correction mode (off)'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).selected,
        isFalse,
      );
      expect(find.text('Translate'), findsOneWidget);
    });

    testWidgets('tapping the toggle persists the setting', (tester) async {
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
      expect(
        find.widgetWithText(FilterChip, 'Correction mode (on)'),
        findsOneWidget,
      );
      // Selected chip is filled with the primary colour, not the near-invisible
      // default container tint.
      final scheme = Theme.of(tester.element(find.byType(FilterChip)))
          .colorScheme;
      expect(chip.selectedColor, scheme.primary);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kPrefCorrectionMode), isTrue);
    });

    testWidgets('action button and output hint switch to correction wording',
        (tester) async {
      SharedPreferences.setMockInitialValues({kPrefCorrectionMode: true});
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Improve'), findsOneWidget);
      expect(find.text('Translate'), findsNothing);
      expect(
        find.text('Corrections and suggestions will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('the mode toggle and the action button use different icons',
        (tester) async {
      SharedPreferences.setMockInitialValues({kPrefCorrectionMode: true});
      await tester.pumpWidget(_wrap(const TranslatorScreen()));
      await tester.pumpAndSettle();

      // The state is marked by spellcheck, the action by the wand — sharing an
      // icon made the two read as the same control.
      expect(
        find.descendant(
          of: find.byType(FilterChip),
          matching: find.byIcon(Icons.spellcheck),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byIcon(Icons.auto_fix_high),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.spellcheck), findsOneWidget);
    });

    testWidgets('renders correction notes below the corrected text',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(
          outputText: 'Tafadhali nipe siagi.',
          correctionNotes: '- Butter → siagi: German for "butter".',
          isCorrectionResult: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tafadhali nipe siagi.'), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(
        find.text('- Butter → siagi: German for "butter".'),
        findsOneWidget,
      );
    });

    testWidgets('hides notes for a plain translation', (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(outputText: 'Habari'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Suggestions'), findsNothing);
    });

    testWidgets('an edited input keeps the result and flags it (ADR-055)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(
          inputText: 'Tafadhali nipe siagi.',
          outputText: 'Tafadhali nipe siagi.',
          outputSourceText: 'Tafadhali nipe Butter.',
          correctionNotes: '- Butter → siagi: German for "butter".',
          isCorrectionResult: true,
        ),
      ));
      await tester.pumpAndSettle();

      // The suggestions the user is working from are still there …
      expect(find.text('- Butter → siagi: German for "butter".'),
          findsOneWidget);
      // … and both the output area and the button say they are one step behind.
      expect(find.text('No longer matches the text above'), findsOneWidget);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isTrue);
    });

    testWidgets('a result matching the input carries no marker', (tester) async {
      await tester.pumpWidget(_wrap(
        const TranslatorScreen(),
        state: const TranslatorState(
          inputText: 'Hello',
          outputText: 'Habari',
          outputSourceText: 'Hello',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No longer matches the text above'), findsNothing);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isFalse);
    });
  });
}
