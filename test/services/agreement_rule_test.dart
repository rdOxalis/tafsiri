import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/ai_service.dart';

/// ADR-072 — number and person may be marked away from the noun.
///
/// These tests do what a test here can do: pin that the rule is in the prompt,
/// that it can be switched off for a measurement, and that it stays
/// language-agnostic. Whether a model follows it is settled by
/// tools/probe_grammar.sh, not here.
void main() {
  const target = 'Swahili';
  const alt = 'German';

  group('the rule is in both prompts', () {
    test('translation prompt', () {
      final prompt = AiService.buildSystemPrompt(target, alt);
      expect(prompt, contains('AGREEMENT BEFORE SURFACE FORM'));
      expect(prompt, contains('the agreement decides'));
    });

    test('correction prompt', () {
      final prompt = AiService.buildCorrectionSystemPrompt(target, alt);
      expect(prompt, contains('AGREEMENT BEFORE SURFACE FORM'));
    });

    test('and reaches both through systemPromptFor, explanations or not', () {
      for (final correction in [false, true]) {
        for (final explain in [false, true]) {
          expect(
            AiService.systemPromptFor(
              targetLanguage: target,
              altLanguage: alt,
              correctionMode: correction,
              explanations: explain,
            ),
            contains('AGREEMENT BEFORE SURFACE FORM'),
            reason: 'correction=$correction explanations=$explain',
          );
        }
      }
    });
  });

  group('it can be taken out again', () {
    // The probe measures the prompt against itself minus this rule. That only
    // means anything if removing it removes nothing else.
    test('and removing it changes nothing but the rule', () {
      for (final correction in [false, true]) {
        final with_ = AiService.systemPromptFor(
          targetLanguage: target,
          altLanguage: alt,
          correctionMode: correction,
        );
        final without = AiService.systemPromptFor(
          targetLanguage: target,
          altLanguage: alt,
          correctionMode: correction,
          agreementRule: false,
        );

        expect(without, isNot(contains('AGREEMENT BEFORE SURFACE FORM')));
        expect(
          with_.replaceFirst('${AiService.agreementRule}\n\n', ''),
          without,
          reason: 'the two prompts must differ by the rule alone '
              '(correction=$correction)',
        );
      }
    });
  });

  test('the rule names no language', () {
    // The field report is Swahili, but the field is free text and the same
    // error shape exists wherever agreement outranks the noun's own form.
    // Naming one language here would teach the model to look for that one.
    for (final word in ['Swahili', 'Bantu', 'German', 'Kiswahili', 'paka']) {
      expect(AiService.agreementRule.toLowerCase(),
          isNot(contains(word.toLowerCase())));
    }
  });

  group('the analysis-first variant (ADR-072, step 2)', () {
    test('is off unless asked for', () {
      // It must stay off in every shipped build: the app's parser does not
      // know the TRANSLATION: line, so switching it on would put the model's
      // reasoning into the output area and into the saved history.
      for (final correction in [false, true]) {
        for (final explain in [false, true]) {
          expect(
            AiService.systemPromptFor(
              targetLanguage: target,
              altLanguage: alt,
              correctionMode: correction,
              explanations: explain,
            ),
            isNot(contains('TRANSLATION:')),
            reason: 'correction=$correction explanations=$explain',
          );
        }
      }
    });

    test('restates the response format it replaces', () {
      final prompt = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: alt,
        correctionMode: false,
        analysisFirst: true,
      );
      expect(prompt, contains('ANALYSIS:'));
      expect(prompt, contains('TRANSLATION:'));
      // The analysis has to come before the translation, which is the entire
      // point — in the shipped protocol the translation is written first.
      expect(prompt.indexOf('ANALYSIS:'), lessThan(prompt.indexOf('TRANSLATION:')));
      expect(prompt, contains('before you have decided anything'));
    });

    test('still leaves room for the explanations section after it', () {
      final prompt = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: alt,
        correctionMode: false,
        explanations: true,
        analysisFirst: true,
      );
      expect(prompt.indexOf('TRANSLATION:'), lessThan(prompt.indexOf('EXPLAIN:')));
    });
  });

  test('it leads the prompt rather than sitting in a numbered rule', () {
    // ADR-063's finding: a model reads the opening as the job and the numbered
    // rules as detail. This one has to be read before the first word is chosen.
    final prompt = AiService.buildSystemPrompt(target, alt);
    expect(prompt.indexOf('AGREEMENT BEFORE SURFACE FORM'),
        lessThan(prompt.indexOf('Rules:')));
  });
}
