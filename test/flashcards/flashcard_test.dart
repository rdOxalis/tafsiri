import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

TranslationEntry _fav(
  int id,
  String source,
  String result, {
  String targetLang = 'Swahili',
  String mode = kModeTranslate,
  bool favourite = true,
}) =>
    TranslationEntry(
      id: id,
      sourceText: source,
      resultText: result,
      sourceLang: 'de',
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
    // Swahili typed in, German came out: the German side is still the prompt
    // for producing Swahili.
    final cards = _cards([
      _fav(1, 'Nimeeka imekubali', 'Ich habe es gesetzt', targetLang: 'Deutsch'),
    ]);

    final produce = cards.firstWhere((c) => c.direction == CardDirection.produce);
    expect(produce.prompt, 'Ich habe es gesetzt');
    expect(produce.expected, 'Nimeeka imekubali');
  });

  test('corrections and plain history entries make no cards', () {
    final cards = _cards([
      _fav(1, 'siku njema', 'siku njema', mode: kModeCorrect),
      _fav(2, 'Hallo', 'Habari', favourite: false),
    ]);

    expect(cards, isEmpty);
  });

  test('an entry in neither configured language keeps its direction', () {
    final cards = _cards([_fav(1, 'Hello', 'Bonjour', targetLang: 'French')]);

    expect(cards, hasLength(1));
    expect(cards.single.prompt, 'Hello');
    expect(cards.single.expected, 'Bonjour');
  });

  test('language names match across spellings', () {
    expect(sameLanguage('German', 'Deutsch'), isTrue);
    expect(sameLanguage(' swahili', 'Kiswahili'), isTrue);
    expect(sameLanguage('German', 'Swahili'), isFalse);
    expect(sameLanguage('Klingon', 'klingon'), isTrue);
    expect(sameLanguage('', ''), isFalse);
  });
}
