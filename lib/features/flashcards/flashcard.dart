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
/// direction.
///
/// What the history stores decides how. `target_lang` is NOT the language
/// the result was written in: the translator stores the learning language
/// that was set at the time, whichever way it translated. `source_lang` is
/// the language the AI detected in the input, and that one is reliable. So:
/// - a favourite saved while another language was being learnt yields no
///   card — neither side need be in today's learning language;
/// - the side in the learning language is the input if the input was in it,
///   otherwise the result;
/// - the other side is in whatever language it was written in — perhaps a
///   confident language set back then, not today's. It is shown as it is for
///   producing; for recalling, the answer is in today's confident language
///   and the stored side only tells the AI what was meant.
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
    if (!sameLanguage(entry.targetLang, learningLanguage)) continue;

    final inputIsLearning = sameLanguage(entry.sourceLang, learningLanguage);
    final learningSide = inputIsLearning ? entry.sourceText : entry.resultText;
    final otherSide = inputIsLearning ? entry.resultText : entry.sourceText;

    cards
      ..add(Flashcard(
        entry: entry,
        direction: CardDirection.produce,
        prompt: otherSide,
        expected: learningSide,
      ))
      ..add(Flashcard(
        entry: entry,
        direction: CardDirection.recall,
        prompt: learningSide,
        expected: otherSide,
      ));
  }
  return cards;
}

/// Whether two language names or codes mean the same language, so that
/// "German", "Deutsch" and "de" agree — the settings hold names, the
/// history's `source_lang` holds the ISO code the AI detected.
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
