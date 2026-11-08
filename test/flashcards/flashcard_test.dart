import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// As the translator stores a favourite: the detected input language, and
/// the learning language of the time as target_lang — whichever way it
/// translated.
TranslationEntry _fav(
  int id,
  String source,
  String result, {
  String sourceLang = 'de',
  String targetLang = 'Swahili',
  String mode = kModeTranslate,
  bool favourite = true,
}) =>
    TranslationEntry(
      id: id,
      sourceText: source,
      resultText: result,
      sourceLang: sourceLang,
      targetLang: targetLang,
      aiProvider: 'claude',
      isFavourite: favourite,
      createdAt: DateTime.utc(2026, 11, id),
      mode: mode,
    );

List<Flashcard> _cards(List<TranslationEntry> entries) => cardsFor(
      entries,
      learningLanguage: 'Swahili',
      confidentLanguage: 'German',
    );

void main() {
  test('a translation into the learning language makes two cards', () {
    final cards = _cards([_fav(1, 'das ist gesund', 'hii ni yenye afya')]);

    expect(cards, hasLength(2));
    final produce = cards.firstWhere((c) => c.direction == CardDirection.produce);
    expect(produce.prompt, 'das ist gesund');
    expect(produce.expected, 'hii ni yenye afya');
    final recall = cards.firstWhere((c) => c.direction == CardDirection.recall);
    expect(recall.prompt, 'hii ni yenye afya');
    expect(recall.expected, 'das ist gesund');
  });

  test('a translation out of the learning language is turned round', () {
    // Swahili typed in, German came out. target_lang still says Swahili —
    // that is how the translator stores it.
    final cards = _cards([
      _fav(1, 'Nimeeka imekubali', 'Ich habe es gesetzt', sourceLang: 'sw'),
    ]);

    final produce = cards.firstWhere((c) => c.direction == CardDirection.produce);
    expect(produce.prompt, 'Ich habe es gesetzt');
    expect(produce.expected, 'Nimeeka imekubali');
    final recall = cards.firstWhere((c) => c.direction == CardDirection.recall);
    expect(recall.prompt, 'Nimeeka imekubali');
  });

  test('the field report: Swahili into English, saved when English was the '
      'confident language', () {
    // Shown "Antworte auf Swahili" over the Swahili text, because target_lang
    // was read as the result's language.
    final cards = _cards([
      _fav(1, 'Nataka kuhadithi kuhusu mimea', 'I want to talk about the plants',
          sourceLang: 'sw'),
    ]);

    final produce = cards.firstWhere((c) => c.direction == CardDirection.produce);
    expect(produce.prompt, 'I want to talk about the plants');
    expect(produce.expected, 'Nataka kuhadithi kuhusu mimea');
    final recall = cards.firstWhere((c) => c.direction == CardDirection.recall);
    expect(recall.prompt, 'Nataka kuhadithi kuhusu mimea');
    expect(recall.expected, 'I want to talk about the plants',
        reason: 'the English side tells the AI what was meant');
  });

  test('corrections and plain history entries make no cards', () {
    final cards = _cards([
      _fav(1, 'siku njema', 'siku njema', mode: kModeCorrect),
      _fav(2, 'Hallo', 'Habari', favourite: false),
    ]);

    expect(cards, isEmpty);
  });

  test('a favourite from another learning language makes no card', () {
    final cards = _cards([
      _fav(1, 'Hello', 'Bonjour', sourceLang: 'en', targetLang: 'French'),
    ]);

    expect(cards, isEmpty);
  });

  test('language names match across spellings', () {
    expect(sameLanguage('German', 'Deutsch'), isTrue);
    expect(sameLanguage(' swahili', 'Kiswahili'), isTrue);
    expect(sameLanguage('German', 'Swahili'), isFalse);
    expect(sameLanguage('Klingon', 'klingon'), isTrue);
    expect(sameLanguage('', ''), isFalse);
    expect(sameLanguage('sw', 'Swahili'), isTrue,
        reason: 'source_lang holds the detected ISO code');
  });
}
