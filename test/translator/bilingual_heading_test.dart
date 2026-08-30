import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/translator/translator_controller.dart';
import 'package:tafsiri/features/translator/translator_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';
import 'package:tafsiri/shared/language_terms.dart';

/// ADR-065 — the notes heading is shown in the two configured languages, not
/// in the app's interface language.
class _FakeTranslatorController extends TranslatorController {
  final TranslatorState _initial;
  _FakeTranslatorController(this._initial);

  @override
  TranslatorState build() => _initial;

  @override
  Future<void> translate() async {}
}

void main() {
  group('bilingualTerm', () {
    late AppLocalizations english;

    setUp(() async {
      english = await AppLocalizations.delegate.load(const Locale('en', 'GB'));
    });

    test('learning language first, confident language second', () {
      expect(
        bilingualTerm(
          learningLanguage: 'Swahili',
          confidentLanguage: 'Deutsch',
          term: (l) => l.correctionNotesTitle,
          fallback: english,
        ),
        'Mapendekezo · Vorschläge',
      );
    });

    test('accepts the spellings the free-text field allows', () {
      for (final pair in [
        ('Kiswahili', 'German'),
        ('sw', 'de'),
        ('  swahili  ', 'DEUTSCH'),
      ]) {
        expect(
          bilingualTerm(
            learningLanguage: pair.$1,
            confidentLanguage: pair.$2,
            term: (l) => l.correctionNotesTitle,
            fallback: english,
          ),
          'Mapendekezo · Vorschläge',
          reason: 'for $pair',
        );
      }
    });

    test('a language Tafsiri has no translation of contributes nothing', () {
      // Turkish is a language someone may well be learning; the app is not
      // translated into it, and inventing a heading would be worse than
      // showing only the one we have.
      expect(
        bilingualTerm(
          learningLanguage: 'Turkish',
          confidentLanguage: 'Deutsch',
          term: (l) => l.correctionNotesTitle,
          fallback: english,
        ),
        'Vorschläge',
      );
    });

    test('falls back to the interface language when neither is known', () {
      expect(
        bilingualTerm(
          learningLanguage: 'Turkish',
          confidentLanguage: 'Portuguese',
          term: (l) => l.correctionNotesTitle,
          fallback: english,
        ),
        'Suggestions',
      );
    });

    test('identical terms are not repeated', () {
      // Danish and Norwegian share the word; "Forslag · Forslag" is noise.
      final both = bilingualTerm(
        learningLanguage: 'Danish',
        confidentLanguage: 'Norwegian',
        term: (l) => l.correctionNotesTitle,
        fallback: english,
      );
      expect(both.contains('·'), isFalse, reason: 'was: $both');
    });
  });

  testWidgets('the heading on screen carries both languages', (tester) async {
    SharedPreferences.setMockInitialValues({
      kPrefTargetLanguage: 'Swahili',
      kPrefAltLanguage: 'Deutsch',
      kPrefCorrectionMode: true,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translatorProvider.overrideWith(() => _FakeTranslatorController(
                const TranslatorState(
                  inputText: 'hata hivyo',
                  outputText: 'hata hivyo',
                  outputSourceText: 'hata hivyo',
                  correctionNotes: '- bereits korrekt',
                  isCorrectionResult: true,
                ),
              )),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', 'GB')],
          locale: Locale('en', 'GB'),
          home: Scaffold(body: TranslatorScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The app itself is in English; the heading is not.
    expect(find.text('Mapendekezo · Vorschläge'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('- bereits korrekt'), findsOneWidget);
  });
}
