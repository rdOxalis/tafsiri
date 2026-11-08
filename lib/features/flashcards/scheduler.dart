import 'flashcard.dart';

/// How an answer was judged (ADR-082): by the AI, possibly overridden by the
/// user, or by the user alone when the AI is unavailable.
enum Grade { wrong, almost, correct }

/// A card's learning state, as stored in `review_card`.
class CardState {
  const CardState({
    required this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.repetitions,
    required this.lapses,
    required this.firstReviewedAt,
    required this.lastReviewedAt,
  });

  final DateTime dueAt;

  /// Days until the card is due again after its last review; 0 while it is
  /// being relearnt.
  final double intervalDays;

  /// SM-2's ease factor: how fast the interval grows. Starts at 2.5.
  final double ease;

  /// Successful reviews in a row; reset by a wrong answer.
  final int repetitions;

  /// How often the card was forgotten.
  final int lapses;

  final DateTime firstReviewedAt;
  final DateTime lastReviewedAt;
}

const kStartEase = 2.5;
const kMinEase = 1.3;

/// A wrong card comes back within the same session.
const kRelearnDelay = Duration(minutes: 10);

/// The state after answering a card with [grade] at [now] (ADR-082).
///
/// A simplified SM-2, as Anki uses it. *Correct* follows the classic steps,
/// 1 day, then 3, then the previous interval times the ease. *Almost* still
/// counts as remembered but grows the interval only a little and makes the
/// card a bit harder. *Wrong* starts it over and brings it back in the same
/// session.
CardState schedule(CardState? previous, Grade grade, DateTime now) {
  final ease = previous?.ease ?? kStartEase;
  final reps = previous?.repetitions ?? 0;
  final interval = previous?.intervalDays ?? 0;
  final lapses = previous?.lapses ?? 0;
  final first = previous?.firstReviewedAt ?? now;

  switch (grade) {
    case Grade.wrong:
      return CardState(
        dueAt: now.add(kRelearnDelay),
        intervalDays: 0,
        ease: _clampEase(ease - 0.2),
        repetitions: 0,
        lapses: previous == null ? 0 : lapses + 1,
        firstReviewedAt: first,
        lastReviewedAt: now,
      );
    case Grade.almost:
      final next = reps == 0 ? 1.0 : _max(interval + 1, interval * 1.2);
      return CardState(
        dueAt: now.add(_days(next)),
        intervalDays: next,
        ease: _clampEase(ease - 0.15),
        repetitions: reps + 1,
        lapses: lapses,
        firstReviewedAt: first,
        lastReviewedAt: now,
      );
    case Grade.correct:
      final next = switch (reps) {
        0 => 1.0,
        1 => 3.0,
        _ => _max(interval + 1, interval * ease),
      };
      return CardState(
        dueAt: now.add(_days(next)),
        intervalDays: next,
        ease: ease,
        repetitions: reps + 1,
        lapses: lapses,
        firstReviewedAt: first,
        lastReviewedAt: now,
      );
  }
}

/// Whether a card is due today: its due time has passed, or falls before the
/// end of the local day — a card due this evening is offered this morning.
bool isDueToday(CardState state, DateTime now) =>
    state.dueAt.isBefore(_endOfDay(now));

/// The cards for a session (ADR-082): every card due today, the most
/// overdue first, then new cards — never answered — up to what is left of
/// today's allowance of [newPerDay].
List<Flashcard> buildSession(
  List<Flashcard> cards,
  Map<CardKey, CardState> states,
  DateTime now, {
  int newPerDay = 10,
}) {
  final due = <Flashcard>[];
  final fresh = <Flashcard>[];
  for (final card in cards) {
    final state = states[card.key];
    if (state == null) {
      fresh.add(card);
    } else if (isDueToday(state, now)) {
      due.add(card);
    }
  }
  due.sort((a, b) => states[a.key]!.dueAt.compareTo(states[b.key]!.dueAt));

  final startOfDay = DateTime(now.year, now.month, now.day);
  final introducedToday = states.values
      .where((s) => !s.firstReviewedAt.toLocal().isBefore(startOfDay))
      .length;
  final allowance = (newPerDay - introducedToday).clamp(0, newPerDay);

  // Oldest favourites first, the producing direction before the other.
  fresh.sort((a, b) {
    final byDate = a.entry.createdAt.compareTo(b.entry.createdAt);
    return byDate != 0 ? byDate : a.direction.index - b.direction.index;
  });
  return [...due, ...fresh.take(allowance)];
}

double _clampEase(double ease) => ease < kMinEase ? kMinEase : ease;

double _max(double a, double b) => a > b ? a : b;

Duration _days(double days) =>
    Duration(minutes: (days * Duration.minutesPerDay).round());

DateTime _endOfDay(DateTime now) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + 1);
}
