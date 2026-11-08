import '../../core/constants.dart';
import '../../core/languages.dart';
import '../../shared/models/translation_entry.dart';

/// Which way a card asks (ADR-082).
enum CardDirection {
  /// The other side shown, answered in the learning language: producing the
  /// language being learnt.
  produce,

  /// The learning-language side shown, answered in the other language:
  /// understanding it.
  recall;

  /// Stored in `review_card.direction`.
  String get key => name;

  static CardDirection fromKey(String key) =>
      CardDirection.values.firstWhere((d) => d.key == key);
}

/// Two languages learnt together, in no particular order (ADR-083): a
/// session never mixes pairs, because juggling three languages at once is
/// what the learner asked to avoid.
class LanguagePair {
  LanguagePair(String a, String b)
      : first = a.compareTo(b) <= 0 ? a : b,
        second = a.compareTo(b) <= 0 ? b : a;

  /// ISO 639-1 codes, sorted so that the pair has no direction.
  final String first;
  final String second;

  @override
  bool operator ==(Object other) =>
      other is LanguagePair && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => '$first-$second';
}

/// One side of a favourite to show, and the other to answer.
class Flashcard {
  const Flashcard({
    required this.entry,
    required this.direction,
    required this.prompt,
    required this.expected,
    required this.learningLang,
    required this.otherLang,
  });

  final TranslationEntry entry;
  final CardDirection direction;

  /// The text shown.
  final String prompt;

  /// The stored other side — one correct answer, not the only one.
  final String expected;

  /// ISO 639-1 codes of the favourite's two sides.
  final String learningLang;
  final String otherLang;

  /// The language the answer is written in.
  String get answerLang =>
      direction == CardDirection.produce ? learningLang : otherLang;

  LanguagePair get pair => LanguagePair(learningLang, otherLang);

  int get entryId => entry.id!;

  /// Identifies the card's learning state.
  CardKey get key => (entryId, direction);
}

typedef CardKey = (int entryId, CardDirection direction);

/// Longest text that still makes a card (ADR-083). A paragraph is something
/// to read, not to recall.
const kMaxCardSentences = 2;

/// The cards the favourites yield, optionally only those of [pair].
///
/// Only translations of at most [kMaxCardSentences] sentences per side: a
/// correction is the user's own text improved, not a pair of languages to
/// learn. Each becomes two cards, one per direction.
///
/// The languages come from what the history stores (ADR-082, ADR-083):
/// `target_lang` is the learning language that was set at the time — not the
/// result's language — and says which side is being learnt; `source_lang`
/// is the language the AI detected in the input; `result_lang` the language
/// of the result. A favourite whose languages are not all known yet makes no
/// card until [resultLanguageToStore] or the AI has supplied them.
List<Flashcard> cardsFor(
  List<TranslationEntry> favourites, {
  LanguagePair? pair,
}) {
  final cards = <Flashcard>[];
  for (final entry in favourites) {
    if (!isCardCandidate(entry)) continue;
    final learning = isoCodeFor(entry.targetLang);
    final input = isoCodeFor(entry.sourceLang);
    final result = entry.resultLang ?? resultLanguageToStore(entry);
    if (learning == null || input == null || result == null) continue;
    if (input == result) continue;

    final inputIsLearning = input == learning;
    final other = inputIsLearning ? result : input;
    if (pair != null && LanguagePair(learning, other) != pair) continue;
    final learningSide = inputIsLearning ? entry.sourceText : entry.resultText;
    final otherSide = inputIsLearning ? entry.resultText : entry.sourceText;

    cards
      ..add(Flashcard(
        entry: entry,
        direction: CardDirection.produce,
        prompt: otherSide,
        expected: learningSide,
        learningLang: learning,
        otherLang: other,
      ))
      ..add(Flashcard(
        entry: entry,
        direction: CardDirection.recall,
        prompt: learningSide,
        expected: otherSide,
        learningLang: learning,
        otherLang: other,
      ));
  }
  return cards;
}

/// Whether [entry] is a favourite translation short enough for a card,
/// whatever its languages.
bool isCardCandidate(TranslationEntry entry) =>
    entry.id != null &&
    entry.isFavourite &&
    entry.mode == kModeTranslate &&
    entry.sourceText.trim().isNotEmpty &&
    entry.resultText.trim().isNotEmpty &&
    sentenceCount(entry.sourceText) <= kMaxCardSentences &&
    sentenceCount(entry.resultText) <= kMaxCardSentences;

/// The result language of an entry from before `result_lang` was stored,
/// when it follows from the rest (ADR-083): input not in the learning
/// language means the translation went into the learning language. When the
/// input WAS in the learning language, the result went into the confident
/// language of the time, which nothing recorded — `null`, and the AI is
/// asked.
String? resultLanguageToStore(TranslationEntry entry) {
  if (entry.resultLang != null) return entry.resultLang;
  final learning = isoCodeFor(entry.targetLang);
  final input = isoCodeFor(entry.sourceLang);
  if (learning == null || input == null) return null;
  return input == learning ? null : learning;
}

/// Sentences in [text]: split after ".", "!", "?" or "…" followed by a
/// space, and at line breaks. Rough on purpose — "Dr. Salim" counts as two —
/// since the limit only keeps paragraphs out.
int sentenceCount(String text) => text
    .trim()
    .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
    .where((s) => s.trim().isNotEmpty)
    .length;

/// Whether two language names or codes mean the same language, so that
/// "German", "Deutsch" and "de" agree.
bool sameLanguage(String a, String b) {
  final ca = isoCodeFor(a);
  final cb = isoCodeFor(b);
  if (ca != null && cb != null) return ca == cb;
  final x = a.trim().toLowerCase();
  return x.isNotEmpty && x == b.trim().toLowerCase();
}

/// Whether [entry] can become a card at all — for the "Learn" button.
bool isLearnable(TranslationEntry entry) =>
    entry.isFavourite && entry.mode == kModeTranslate;
