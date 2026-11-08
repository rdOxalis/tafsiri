import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/features/flashcards/scheduler.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

final _now = DateTime(2026, 11, 8, 9);

CardState _after(List<Grade> grades) {
  CardState? state;
  var now = _now;
  for (final g in grades) {
    state = schedule(state, g, now);
    now = state.dueAt;
  }
  return state!;
}

Flashcard _card(int id, CardDirection dir) => Flashcard(
      entry: TranslationEntry(
        id: id,
        sourceText: 'a$id',
        resultText: 'b$id',
        sourceLang: 'de',
        targetLang: 'Swahili',
        aiProvider: 'claude',
        isFavourite: true,
        createdAt: DateTime(2026, 10, id),
      ),
      direction: dir,
      prompt: 'a$id',
      expected: 'b$id',
      learningLang: 'sw',
      otherLang: 'de',
    );

void main() {
  group('schedule', () {
    test('correct answers space out: 1, 3, then times the ease', () {
      expect(_after([Grade.correct]).intervalDays, 1);
      expect(_after([Grade.correct, Grade.correct]).intervalDays, 3);
      expect(
          _after([Grade.correct, Grade.correct, Grade.correct]).intervalDays,
          7.5);
    });

    test('the first correct answer is due tomorrow', () {
      final s = schedule(null, Grade.correct, _now);
      expect(s.dueAt, _now.add(const Duration(days: 1)));
      expect(s.repetitions, 1);
      expect(s.firstReviewedAt, _now);
    });

    test('almost grows the interval less and makes the card harder', () {
      final almost = _after([Grade.correct, Grade.correct, Grade.almost]);
      final correct = _after([Grade.correct, Grade.correct, Grade.correct]);
      expect(almost.intervalDays, lessThan(correct.intervalDays));
      expect(almost.intervalDays, greaterThan(3));
      expect(almost.ease, lessThan(kStartEase));
    });

    test('wrong starts over and comes back in the same session', () {
      final s = _after([Grade.correct, Grade.correct, Grade.wrong]);
      expect(s.repetitions, 0);
      expect(s.intervalDays, 0);
      expect(s.lapses, 1);
      expect(s.ease, lessThan(kStartEase));
      expect(s.dueAt.difference(s.lastReviewedAt), kRelearnDelay);
    });

    test('a first answer that is wrong is not counted as forgotten', () {
      expect(schedule(null, Grade.wrong, _now).lapses, 0);
    });

    test('the ease never drops below the minimum', () {
      final s = _after(List.filled(20, Grade.wrong));
      expect(s.ease, kMinEase);
    });

    test('the first review is remembered across answers', () {
      final s = _after([Grade.correct, Grade.wrong, Grade.correct]);
      expect(s.firstReviewedAt, _now);
    });
  });

  group('isDueToday', () {
    test('a card due this evening is offered this morning', () {
      final s = schedule(null, Grade.wrong, _now)
          .withDue(DateTime(2026, 11, 8, 21));
      expect(isDueToday(s, _now), isTrue);
    });

    test('a card due tomorrow is not', () {
      expect(isDueToday(schedule(null, Grade.correct, _now), _now), isFalse);
    });
  });

  group('buildSession', () {
    test('due cards first, most overdue first, then new ones', () {
      final a = _card(1, CardDirection.produce);
      final b = _card(2, CardDirection.produce);
      final c = _card(3, CardDirection.produce);
      final states = {
        a.key: schedule(null, Grade.correct, DateTime(2026, 11, 6))
            .withFirst(DateTime(2026, 11, 6)),
        b.key: schedule(null, Grade.correct, DateTime(2026, 11, 5))
            .withFirst(DateTime(2026, 11, 5)),
      };

      final session = buildSession([a, b, c], states, _now);

      expect(session.map((c) => c.entryId), [2, 1, 3]);
    });

    test('cards not yet due are left out', () {
      final a = _card(1, CardDirection.produce);
      final states = {a.key: schedule(null, Grade.correct, _now)};
      expect(buildSession([a], states, _now), isEmpty);
    });

    test('new cards are limited per day, counting those already begun', () {
      final cards = [
        for (var i = 1; i <= 6; i++) _card(i, CardDirection.produce),
      ];
      // Two introduced earlier today, and not due again until tomorrow.
      final states = {
        cards[0].key: schedule(null, Grade.correct, _now),
        cards[1].key: schedule(null, Grade.correct, _now),
      };

      final session = buildSession(cards, states, _now, newPerDay: 3);

      expect(session.map((c) => c.entryId), [3]);
    });

    test('new cards: oldest favourite first, producing before recalling', () {
      final cards = [
        _card(2, CardDirection.recall),
        _card(2, CardDirection.produce),
        _card(1, CardDirection.recall),
      ];
      final session = buildSession(cards, const {}, _now);
      expect(
        session.map((c) => (c.entryId, c.direction)),
        [
          (1, CardDirection.recall),
          (2, CardDirection.produce),
          (2, CardDirection.recall),
        ],
      );
    });
  });
}

extension on CardState {
  CardState withDue(DateTime due) => CardState(
        dueAt: due,
        intervalDays: intervalDays,
        ease: ease,
        repetitions: repetitions,
        lapses: lapses,
        firstReviewedAt: firstReviewedAt,
        lastReviewedAt: lastReviewedAt,
      );

  CardState withFirst(DateTime first) => CardState(
        dueAt: dueAt,
        intervalDays: intervalDays,
        ease: ease,
        repetitions: repetitions,
        lapses: lapses,
        firstReviewedAt: first,
        lastReviewedAt: lastReviewedAt,
      );
}
