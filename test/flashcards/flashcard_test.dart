import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// As the translator stores a favourite: the detected input language, the
/// learning language of the time as target_lang — whichever way it
/// translated — and, since ADR-083, the result's language.
TranslationEntry _fav(
  int id,
  String source,
  String result, {
  String sourceLang = 'de',
  String targetLang = 'Swahili',
  String? resultLang,
  String mode = kModeTranslate,
  bool favourite = true,
}) =>
    TranslationEntry(
      id: id,
      sourceText: source,
      resultText: result,
      sourceLang: sourceLang,
      targetLang: targetLang,
      resultLang: resultLang,
      aiProvider: 'claude',
      isFavourite: favourite,
      createdAt: DateTime.utc(2026, 11, id),
      mode: mode,
    );

final _swDe = LanguagePair('sw', 'de');
final _swEn = LanguagePair('en', 'sw');

void main() {
  test('a translation into the learning language makes two cards', () {
    final cards = cardsFor([_fav(1, 'das ist gesund', 'hii ni yenye afya')]);

    expect(cards, hasLength(2));
    final produce = cards.firstWhere((c) => c.direction == CardDirection.produce);
    expect(produce.prompt, 'das ist gesund');
    expect(produce.expected, 'hii ni yenye afya');
    expect(produce.answerLang, 'sw');
    final recall = cards.firstWhere((c) => c.direction == CardDirection.recall);
    expect(recall.prompt, 'hii ni yenye afya');
    expect(recall.answerLang, 'de');
    expect(produce.pair, _swDe);
  });

  test('the field report: Swahili into English, saved under Swahili', () {
    final cards = cardsFor([
      _fav(1, 'Nataka kuhadithi kuhusu mimea', 'I want to talk about the plants',
          sourceLang: 'sw', resultLang: 'en'),
    ]);

    final produce = cards.firstWhere((c) => c.direction == CardDirection.produce);
    expect(produce.prompt, 'I want to talk about the plants');
    expect(produce.answerLang, 'sw');
    final recall = cards.firstWhere((c) => c.direction == CardDirection.recall);
    expect(recall.prompt, 'Nataka kuhadithi kuhusu mimea');
    expect(recall.answerLang, 'en', reason: 'the pair is Swahili – English');
    expect(produce.pair, _swEn);
  });

  test('a pair keeps only its own cards, whichever way they were typed', () {
    final favourites = [
      _fav(1, 'das ist gesund', 'hii ni yenye afya'),
      _fav(2, 'siku njema', 'einen schönen Tag', sourceLang: 'sw', resultLang: 'de'),
      _fav(3, 'Good morning', 'Habari za asubuhi', sourceLang: 'en'),
    ];

    expect(cardsFor(favourites, pair: _swDe).map((c) => c.entryId).toSet(), {1, 2});
    expect(cardsFor(favourites, pair: _swEn).map((c) => c.entryId).toSet(), {3});
  });

  test('a favourite whose result language is unknown makes no card yet', () {
    // Swahili typed in before result_lang existed: English or German?
    final cards = cardsFor([_fav(1, 'siku njema', 'einen schönen Tag', sourceLang: 'sw')]);
    expect(cards, isEmpty);
  });

  test('more than two sentences on a side make no card', () {
    final cards = cardsFor([
      _fav(1, 'Eins. Zwei. Drei.', 'Moja. Mbili. Tatu.'),
      _fav(2, 'Eins. Zwei.', 'Moja. Mbili.'),
    ]);
    expect(cards.map((c) => c.entryId).toSet(), {2});
  });

  test('corrections and plain history entries make no cards', () {
    final cards = cardsFor([
      _fav(1, 'siku njema', 'siku njema', mode: kModeCorrect, sourceLang: 'sw'),
      _fav(2, 'Hallo', 'Habari', favourite: false),
    ]);
    expect(cards, isEmpty);
  });

  group('resultLanguageToStore', () {
    test('input not in the learning language: the result is', () {
      expect(resultLanguageToStore(_fav(1, 'Hallo', 'Habari')), 'sw');
    });

    test('input in the learning language: unknown, the AI is asked', () {
      expect(resultLanguageToStore(_fav(1, 'Habari', 'Hello', sourceLang: 'sw')), isNull);
    });

    test('a stored value wins', () {
      expect(
          resultLanguageToStore(
              _fav(1, 'Habari', 'Hello', sourceLang: 'sw', resultLang: 'en')),
          'en');
    });
  });

  test('sentences', () {
    expect(sentenceCount('hii ni yenye afya'), 1);
    expect(sentenceCount('Habari. Nzuri sana!'), 2);
    expect(sentenceCount('Eins.\nZwei\nDrei'), 3);
    expect(sentenceCount('Wie geht es? Gut. Danke…  Tschüss'), 4);
  });

  test('a pair has no direction', () {
    expect(LanguagePair('sw', 'de'), LanguagePair('de', 'sw'));
    expect(LanguagePair('sw', 'de').first, 'de');
  });

  test('language names match across spellings', () {
    expect(sameLanguage('German', 'Deutsch'), isTrue);
    expect(sameLanguage(' swahili', 'Kiswahili'), isTrue);
    expect(sameLanguage('sw', 'Swahili'), isTrue);
    expect(sameLanguage('German', 'Swahili'), isFalse);
    expect(sameLanguage('Klingon', 'klingon'), isTrue);
    expect(sameLanguage('', ''), isFalse);
  });
}
