import '../../core/constants.dart';
import '../../core/services/ocr/tesseract_ocr_service.dart'
    show kTesseractLanguageCodes;
import '../../shared/models/translation_entry.dart';

/// Which way a card asks (ADR-082).
enum CardDirection {
  /// Shown in the confident language, answered in the learning language:
  /// producing the language being learnt.
  produce,

  /// Shown in the learning language, answered in the confident language:
  /// understanding it.
  recall;

  /// Stored in `review_card.direction`.
  String get key => name;

  static CardDirection fromKey(String key) =>
      CardDirection.values.firstWhere((d) => d.key == key);
}

/// One side of a favourite to show, and the other to answer.
class Flashcard {
  const Flashcard({
    required this.entry,
    required this.direction,
    required this.prompt,
    required this.expected,
  });

  final TranslationEntry entry;
  final CardDirection direction;

  /// The text shown.
  final String prompt;

  /// The stored other side — one correct answer, not the only one.
  final String expected;

  int get entryId => entry.id!;

  /// Identifies the card's learning state.
  CardKey get key => (entryId, direction);
}

typedef CardKey = (int entryId, CardDirection direction);

/// The cards the favourites yield (ADR-082).
///
/// Only translations: a correction is the user's own text improved, not a
/// pair of languages to learn. A favourite becomes two cards, one per
/// direction. Which side is in which language follows from the entry's
/// target language; an entry in neither configured language (the settings
/// changed since) keeps its stored direction as a single card.
List<Flashcard> cardsFor(
  List<TranslationEntry> favourites, {
  required String learningLanguage,
  required String confidentLanguage,
}) {
  final cards = <Flashcard>[];
  for (final entry in favourites) {
    if (entry.id == null || !entry.isFavourite || entry.isCorrection) continue;
    if (entry.sourceText.trim().isEmpty || entry.resultText.trim().isEmpty) {
      continue;
    }

    final String learningSide;
    final String confidentSide;
    if (sameLanguage(entry.targetLang, learningLanguage)) {
      learningSide = entry.resultText;
      confidentSide = entry.sourceText;
    } else if (sameLanguage(entry.targetLang, confidentLanguage)) {
      learningSide = entry.sourceText;
      confidentSide = entry.resultText;
    } else {
      cards.add(Flashcard(
        entry: entry,
        direction: CardDirection.produce,
        prompt: entry.sourceText,
        expected: entry.resultText,
      ));
      continue;
    }

    cards
      ..add(Flashcard(
        entry: entry,
        direction: CardDirection.produce,
        prompt: confidentSide,
        expected: learningSide,
      ))
      ..add(Flashcard(
        entry: entry,
        direction: CardDirection.recall,
        prompt: learningSide,
        expected: confidentSide,
      ));
  }
  return cards;
}

/// Whether two free-text language names mean the same language, so that
/// "German", "Deutsch" and "de" agree.
bool sameLanguage(String a, String b) {
  final x = a.trim().toLowerCase();
  final y = b.trim().toLowerCase();
  if (x.isEmpty || y.isEmpty) return false;
  final cx = kTesseractLanguageCodes[x];
  final cy = kTesseractLanguageCodes[y];
  if (cx != null && cy != null) return cx == cy;
  return x == y;
}

/// Whether [entry] can become a card at all — for the "Learn" button.
bool isLearnable(TranslationEntry entry) =>
    entry.isFavourite && entry.mode == kModeTranslate;
