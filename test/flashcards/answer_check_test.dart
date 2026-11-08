import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tafsiri/features/flashcards/answer_check.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/features/flashcards/scheduler.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';
import '../translator/mock_ai_service.mocks.dart';

final _entry = TranslationEntry(
  id: 1,
  sourceText: 'das ist gesund',
  resultText: 'hii ni yenye afya',
  sourceLang: 'de',
  targetLang: 'Swahili',
  aiProvider: 'claude',
  isFavourite: true,
  createdAt: DateTime.utc(2026, 11, 8),
);

final _produce = cardsFor([_entry],
        learningLanguage: 'Swahili', confidentLanguage: 'German')
    .firstWhere((c) => c.direction == CardDirection.produce);
final _recall = cardsFor([_entry],
        learningLanguage: 'Swahili', confidentLanguage: 'German')
    .firstWhere((c) => c.direction == CardDirection.recall);

void main() {
  group('AnswerVerdict.parse', () {
    test('reads the verdict and the feedback', () {
      final v = AnswerVerdict.parse('VERDICT:almost\nFEEDBACK:\n'
          '- yenye afia → yenye afya: Rechtschreibung');
      expect(v.grade, Grade.almost);
      expect(v.feedback, '- yenye afia → yenye afya: Rechtschreibung');
      expect(v.byAi, isTrue);
    });

    test('tolerates Markdown, case and a line before it', () {
      final v = AnswerVerdict.parse(
          'Here you go\n**VERDICT:** Correct\n**FEEDBACK:** Sehr gut.');
      expect(v.grade, Grade.correct);
      expect(v.feedback, 'Sehr gut.');
    });

    test('an empty feedback is fine', () {
      expect(AnswerVerdict.parse('VERDICT: wrong\nFEEDBACK:').feedback, '');
    });

    test('no verdict is an error, never a guessed grade', () {
      expect(() => AnswerVerdict.parse('Das ist richtig!'),
          throwsFormatException);
      expect(() => AnswerVerdict.parse('VERDICT: maybe'),
          throwsFormatException);
    });
  });

  group('the prompt', () {
    final system = answerCheckSystemPrompt(
      answerLanguage: 'Swahili',
      learningLanguage: 'Swahili',
      confidentLanguage: 'German',
    );

    test('judges meaning, not closeness to the reference', () {
      expect(system, contains('ONE correct translation, not the only one'));
      expect(system, contains('NOT by how close it is to the reference'));
    });

    test('feedback comes in the confident language', () {
      expect(system, contains('must be written in German'));
    });

    test('the user message fences all three texts', () {
      final user = answerCheckUserMessage(
          shown: 'das ist gesund', reference: 'hii ni yenye afya', answer: 'x');
      expect(user, contains('<card_shown>\ndas ist gesund\n</card_shown>'));
      expect(user, contains('<learner_answer>\nx\n</learner_answer>'));
    });
  });

  group('answerLanguageOf', () {
    test('producing is answered in the learning language', () {
      expect(
          answerLanguageOf(_produce,
              learningLanguage: 'Swahili', confidentLanguage: 'German'),
          'Swahili');
    });

    test('recalling in the confident language', () {
      expect(
          answerLanguageOf(_recall,
              learningLanguage: 'Swahili', confidentLanguage: 'German'),
          'German');
    });
  });

  group('checkAnswer', () {
    late MockAiService service;
    setUp(() => service = MockAiService());

    Future<AnswerVerdict> check(Flashcard card, String answer) => checkAnswer(
          service,
          card: card,
          answer: answer,
          learningLanguage: 'Swahili',
          confidentLanguage: 'German',
          apiKey: 'sk-test',
          model: 'claude-sonnet-5-5',
        );

    test('an empty answer is wrong without asking the AI', () async {
      final v = await check(_produce, '   ');
      expect(v.grade, Grade.wrong);
      expect(v.byAi, isFalse);
      verifyNever(service.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      ));
    });

    test('the reference typed back is correct without asking', () async {
      final v = await check(_produce, 'Hii ni yenye afya!');
      expect(v.grade, Grade.correct);
      expect(v.byAi, isFalse);
      verifyNever(service.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      ));
    });

    test('anything else is judged by the active provider', () async {
      when(service.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      )).thenAnswer((_) async => 'VERDICT:correct\nFEEDBACK:');

      final v = await check(_produce, 'hii ni afya');

      expect(v.grade, Grade.correct);
      final captured = verify(service.complete(
        system: captureAnyNamed('system'),
        user: captureAnyNamed('user'),
        apiKey: 'sk-test',
        model: 'claude-sonnet-5-5',
      )).captured;
      expect(captured[0] as String, contains('should be in Swahili'));
      expect(captured[1] as String, contains('hii ni afya'));
    });
  });
}
