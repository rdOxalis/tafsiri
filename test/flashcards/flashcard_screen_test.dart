import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/features/flashcards/answer_check.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/features/flashcards/flashcard_controller.dart';
import 'package:tafsiri/features/flashcards/flashcard_screen.dart';
import 'package:tafsiri/features/flashcards/scheduler.dart';
import 'package:tafsiri/l10n/app_localizations.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

final _card = Flashcard(
  entry: TranslationEntry(
    id: 1,
    sourceText: 'das ist gesund',
    resultText: 'hii ni yenye afya',
    sourceLang: 'de',
    targetLang: 'Swahili',
    aiProvider: 'claude',
    isFavourite: true,
    createdAt: DateTime.utc(2026, 11, 1),
  ),
  direction: CardDirection.produce,
  prompt: 'das ist gesund',
  expected: 'hii ni yenye afya',
);

class _Fixed extends LearnController {
  _Fixed(this.initial);
  final LearnState initial;
  final submitted = <String>[];
  @override
  LearnState build() => initial;
  @override
  Future<void> submit(String answer) async => submitted.add(answer);
  @override
  void setGrade(Grade grade) => state = state.copyWith(grade: grade);
}

late _Fixed _ctl;

Widget _app(LearnState s) => ProviderScope(
      overrides: [learnProvider.overrideWith(() => _ctl = _Fixed(s))],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', 'GB')],
        locale: Locale('en', 'GB'),
        home: FlashcardScreen(),
      ),
    );

void main() {
  testWidgets('asks: shows the card, the language, and sends the answer',
      (tester) async {
    await tester.pumpWidget(_app(LearnState(
      phase: LearnPhase.asking,
      card: _card,
      position: 1,
      total: 2,
      answerLanguage: 'Swahili',
    )));

    expect(find.text('das ist gesund'), findsOneWidget);
    expect(find.text('Answer in Swahili'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hii ni nzuri');
    await tester.tap(find.text('Check'));
    expect(_ctl.submitted, ['hii ni nzuri']);
  });

  testWidgets('result: verdict preselected, feedback and saved text shown',
      (tester) async {
    await tester.pumpWidget(_app(LearnState(
      phase: LearnPhase.result,
      card: _card,
      position: 1,
      total: 2,
      answer: 'hii ni yenye afia',
      verdict: const AnswerVerdict(Grade.almost, '- afia → afya: spelling'),
      grade: Grade.almost,
      answerLanguage: 'Swahili',
    )));

    expect(find.text('hii ni yenye afya'), findsOneWidget);
    expect(find.text('- afia → afya: spelling'), findsOneWidget);
    final seg = tester.widget<SegmentedButton<Grade>>(
        find.byType(SegmentedButton<Grade>));
    expect(seg.selected, {Grade.almost});

    await tester.tap(find.text('Right'));
    await tester.pump();
    expect(_ctl.state.grade, Grade.correct);
  });

  testWidgets('grading alone: Next waits until a grade is picked',
      (tester) async {
    await tester.pumpWidget(_app(LearnState(
      phase: LearnPhase.result,
      card: _card,
      answer: 'x',
      aiUnavailable: true,
      answerLanguage: 'Swahili',
    )));

    expect(find.textContaining('not available right now'), findsOneWidget);
    final next = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
    expect(next.onPressed, isNull);
  });

  testWidgets('done: the summary', (tester) async {
    await tester.pumpWidget(_app(const LearnState(
      phase: LearnPhase.done,
      counts: {Grade.correct: 3, Grade.almost: 1, Grade.wrong: 2},
    )));
    expect(find.text('3 right · 1 almost · 2 wrong'), findsOneWidget);
  });
}
