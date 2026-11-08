import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/languages.dart';
import '../../core/database/dao_provider.dart';
import '../../core/diagnostics_log.dart';
import '../../core/services/ai_service_factory.dart';
import '../history/history_controller.dart';
import '../settings/settings_controller.dart';
import 'answer_check.dart';
import 'flashcard.dart';
import 'result_language.dart';
import 'scheduler.dart';

/// Where a learning session stands (ADR-082).
enum LearnPhase {
  loading,

  /// No card is due and no new one is allowed today.
  nothingDue,

  /// A card is shown and waits for the answer.
  asking,

  /// The answer is with the AI.
  checking,

  /// The verdict is shown; the user confirms or changes the grade.
  result,

  /// Every card of the session has been answered.
  done,
}

class LearnState {
  const LearnState({
    this.phase = LearnPhase.loading,
    this.card,
    this.position = 0,
    this.total = 0,
    this.answer = '',
    this.verdict,
    this.aiUnavailable = false,
    this.grade,
    this.answerLanguage = '',
    this.counts = const {},
  });

  final LearnPhase phase;
  final Flashcard? card;

  /// 1-based number of the card in the session, and the session's size;
  /// a card repeated after a wrong answer adds to both.
  final int position;
  final int total;

  final String answer;

  /// The AI's suggestion; `null` when the user grades alone.
  final AnswerVerdict? verdict;

  /// True when the check could not run (no key, no network, API error) —
  /// the user grades themselves, as in Anki.
  final bool aiUnavailable;

  /// The grade that will be saved: the verdict's, until the user picks
  /// another; `null` while self-grading and nothing is picked yet.
  final Grade? grade;

  /// The language the current card is answered in.
  final String answerLanguage;

  /// Final grades given in this session.
  final Map<Grade, int> counts;

  LearnState copyWith({
    LearnPhase? phase,
    Flashcard? card,
    int? position,
    int? total,
    String? answer,
    AnswerVerdict? verdict,
    bool clearVerdict = false,
    bool? aiUnavailable,
    Grade? grade,
    bool clearGrade = false,
    String? answerLanguage,
    Map<Grade, int>? counts,
  }) =>
      LearnState(
        phase: phase ?? this.phase,
        card: card ?? this.card,
        position: position ?? this.position,
        total: total ?? this.total,
        answer: answer ?? this.answer,
        verdict: clearVerdict ? null : verdict ?? this.verdict,
        aiUnavailable: aiUnavailable ?? this.aiUnavailable,
        grade: clearGrade ? null : grade ?? this.grade,
        answerLanguage: answerLanguage ?? this.answerLanguage,
        counts: counts ?? this.counts,
      );
}

/// The current time, injectable so the schedule can be tested.
final learnClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// One learning session for one language pair (ADR-082, ADR-083). Disposed
/// with the screen, so every visit starts from what is due at that moment.
final learnProvider = NotifierProvider.autoDispose
    .family<LearnController, LearnState, LanguagePair>(LearnController.new);

class LearnController
    extends AutoDisposeFamilyNotifier<LearnState, LanguagePair> {
  final _queue = <Flashcard>[];
  var _states = <CardKey, CardState>{};

  @override
  LearnState build(LanguagePair pair) {
    Future.microtask(_load);
    return const LearnState();
  }

  Future<void> _load() async {
    try {
      await _loadSession();
    } catch (e) {
      diagLog('learn: loading the session failed: $e');
      state = state.copyWith(phase: LearnPhase.nothingDue);
    }
  }

  Future<void> _loadSession() async {
    await ref.read(settingsProvider.future);
    final entries = await ref.read(translationDaoProvider.future);
    final reviews = await ref.read(reviewDaoProvider.future);
    _states = await reviews.getAll();
    final cards = cardsFor(await entries.getFavourites(), pair: arg);
    _queue.addAll(buildSession(cards, _states, ref.read(learnClockProvider)()));
    if (_queue.isEmpty) {
      state = state.copyWith(phase: LearnPhase.nothingDue);
      return;
    }
    state = state.copyWith(total: _queue.length);
    _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      state = state.copyWith(phase: LearnPhase.done);
      return;
    }
    final card = _queue.removeAt(0);
    state = state.copyWith(
      phase: LearnPhase.asking,
      card: card,
      position: state.position + 1,
      answer: '',
      clearVerdict: true,
      clearGrade: true,
      aiUnavailable: false,
      answerLanguage: languageDisplayName(card.answerLang),
    );
  }

  /// Checks [answer] for the shown card. An empty answer — "I don't know" —
  /// is wrong without asking anyone.
  Future<void> submit(String answer) async {
    if (state.phase != LearnPhase.asking) return;
    final card = state.card!;
    final settings = ref.read(settingsProvider).requireValue;
    state = state.copyWith(phase: LearnPhase.checking, answer: answer);

    final needsAi = answer.trim().isNotEmpty;
    if (needsAi && !settings.hasApiKeyForActiveProvider) {
      _gradeYourself();
      return;
    }
    try {
      final verdict = await checkAnswer(
        ref.read(aiServiceProvider),
        card: card,
        answer: answer,
        feedbackLanguage: settings.altLanguage,
        apiKey: settings.activeApiKey,
        model: settings.activeModel,
      );
      state = state.copyWith(
        phase: LearnPhase.result,
        verdict: verdict,
        grade: verdict.grade,
      );
    } catch (e) {
      diagLog('learn: answer check failed: $e');
      _gradeYourself();
    }
  }

  void _gradeYourself() => state = state.copyWith(
        phase: LearnPhase.result,
        aiUnavailable: true,
        clearVerdict: true,
        clearGrade: true,
      );

  /// The user's grade — agreeing with the AI, overriding it, or grading
  /// alone.
  void setGrade(Grade grade) {
    if (state.phase != LearnPhase.result) return;
    state = state.copyWith(grade: grade);
  }

  /// Saves the grade, schedules the card and shows the next one. A wrong
  /// card goes to the end of the session to be tried again.
  Future<void> next() async {
    final grade = state.grade;
    final card = state.card;
    if (state.phase != LearnPhase.result || grade == null || card == null) {
      return;
    }
    final updated = schedule(
      _states[card.key],
      grade,
      ref.read(learnClockProvider)(),
    );
    _states[card.key] = updated;
    try {
      await (await ref.read(reviewDaoProvider.future)).save(card.key, updated);
    } catch (e) {
      diagLog('learn: saving the card state failed: $e');
    }
    final counts = {...state.counts, grade: (state.counts[grade] ?? 0) + 1};
    var total = state.total;
    if (grade == Grade.wrong) {
      _queue.add(card);
      total++;
    }
    state = state.copyWith(counts: counts, total: total);
    _showNext();
  }
}

/// A language pair to learn, and how many cards a session of it holds now.
typedef PairOffer = ({LanguagePair pair, int due});

/// The language pairs the favourites form, with the cards due in each, most
/// first; `null` when no favourite can become a card at all, so the "Learn"
/// button stays hidden. Recomputed whenever the history changes. Favourites
/// whose result language is not known yet are not counted until
/// [prepareLearning] has worked it out.
///
/// [due] is what the button shows: the cards of one session across all
/// pairs, which counts the daily allowance of new cards once.
final learnOverviewProvider = FutureProvider.autoDispose<
    ({List<PairOffer> offers, int due})?>((ref) async {
  ref.watch(historyProvider);
  final entries = await ref.watch(translationDaoProvider.future);
  final reviews = await ref.watch(reviewDaoProvider.future);
  final favourites = await entries.getFavourites();
  if (!favourites.any(isCardCandidate)) return null;
  final cards = cardsFor(favourites);
  final states = await reviews.getAll();
  final now = DateTime.now();
  return (
    offers: offersFor(cards, states, now),
    due: buildSession(cards, states, now).length,
  );
});

/// One offer per pair; a pair with nothing due is still offered, at 0.
List<PairOffer> offersFor(
  List<Flashcard> cards,
  Map<CardKey, CardState> states,
  DateTime now,
) {
  final byPair = <LanguagePair, List<Flashcard>>{};
  for (final c in cards) {
    byPair.putIfAbsent(c.pair, () => []).add(c);
  }
  return [
    for (final e in byPair.entries)
      (pair: e.key, due: buildSession(e.value, states, now).length),
  ]..sort((a, b) => b.due.compareTo(a.due));
}

/// Before a session: works out the result language of older favourites
/// (ADR-083), asking the AI once if a key is set, and returns the offers.
Future<List<PairOffer>> prepareLearning(WidgetRef ref) async {
  final settings = await ref.read(settingsProvider.future);
  final entries = await ref.read(translationDaoProvider.future);
  final reviews = await ref.read(reviewDaoProvider.future);
  final hasKey = settings.hasApiKeyForActiveProvider;
  await fillInResultLanguages(
    entries,
    await entries.getFavourites(),
    service: hasKey ? ref.read(aiServiceProvider) : null,
    apiKey: settings.activeApiKey,
    model: settings.activeModel,
  );
  ref.invalidate(learnOverviewProvider);
  return offersFor(
    cardsFor(await entries.getFavourites()),
    await reviews.getAll(),
    DateTime.now(),
  );
}
