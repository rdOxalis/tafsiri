import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/database/db_helper.dart';
import 'package:tafsiri/core/database/sqflite_desktop.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/core/languages.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/features/flashcards/flashcard_controller.dart';
import 'package:tafsiri/features/flashcards/result_language.dart';
import 'package:tafsiri/features/flashcards/scheduler.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';
import '../translator/mock_ai_service.mocks.dart';

void main() {
  late Database db;
  late TranslationDao dao;
  late MockAiService ai;

  setUp(() async {
    databaseFactory = createDesktopDatabaseFactory();
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbHelper.schemaVersion,
        onCreate: (db, _) => DbHelper.createSchema(db),
      ),
    );
    dao = TranslationDao(db);
    ai = MockAiService();
  });
  tearDown(() => db.close());

  Future<void> add(String source, String result, String sourceLang) =>
      dao.insert(TranslationEntry(
        sourceText: source,
        resultText: result,
        sourceLang: sourceLang,
        targetLang: 'Swahili',
        aiProvider: 'claude',
        isFavourite: true,
        createdAt: DateTime.utc(2026, 11, 1),
      ));

  void detects(String raw) => when(ai.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      )).thenAnswer((_) async => raw);

  group('fillInResultLanguages', () {
    test('derives what follows, asks the AI once for the rest', () async {
      await add('das ist gesund', 'hii ni yenye afya', 'de'); // → sw
      await add('siku njema', 'einen schönen Tag', 'sw'); // → ?
      await add('Nataka kuhadithi', 'I want to tell', 'sw'); // → ?
      detects('1: de\n2: en');

      final left = await fillInResultLanguages(dao, await dao.getFavourites(),
          service: ai, apiKey: 'sk', model: 'm');

      expect(left, 0);
      final byText = {for (final e in await dao.getAll()) e.sourceText: e.resultLang};
      expect(byText, {
        'das ist gesund': 'sw',
        'siku njema': 'de',
        'Nataka kuhadithi': 'en',
      });
      final user = verify(ai.complete(
        system: anyNamed('system'),
        user: captureAnyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      )).captured.single as String;
      expect(user, contains('1: einen schönen Tag'));
      expect(user, isNot(contains('hii ni yenye afya')));
    });

    test('without a key the unknown stay unknown, nothing is asked', () async {
      await add('siku njema', 'einen schönen Tag', 'sw');
      final left = await fillInResultLanguages(dao, await dao.getFavourites());
      expect(left, 1);
      verifyNever(ai.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      ));
    });

    test('an AI error leaves them unknown instead of failing', () async {
      await add('siku njema', 'einen schönen Tag', 'sw');
      when(ai.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      )).thenThrow(const AiApiException(500, 'boom'));

      final left = await fillInResultLanguages(dao, await dao.getFavourites(),
          service: ai, apiKey: 'sk', model: 'm');

      expect(left, 1);
      expect((await dao.getAll()).single.resultLang, isNull);
    });
  });

  test('the detection answer is read leniently', () {
    expect(parseLanguageDetection('1: en\n2) DE\n 3. sw\nnoise'),
        {1: 'en', 2: 'de', 3: 'sw'});
  });

  group('resultLanguageFor (saving a translation)', () {
    test('into the learning language', () {
      expect(
          resultLanguageFor(
              sourceLang: 'de',
              learningLanguage: 'Swahili',
              confidentLanguage: 'German',
              isCorrection: false),
          'sw');
    });

    test('out of it, into the confident language', () {
      expect(
          resultLanguageFor(
              sourceLang: 'sw',
              learningLanguage: 'Swahili',
              confidentLanguage: 'Deutsch',
              isCorrection: false),
          'de');
    });

    test('a correction stays in its language', () {
      expect(
          resultLanguageFor(
              sourceLang: 'sw',
              learningLanguage: 'Swahili',
              confidentLanguage: 'German',
              isCorrection: true),
          'sw');
    });

    test('unknown input language: unknown', () {
      expect(
          resultLanguageFor(
              sourceLang: '',
              learningLanguage: 'Swahili',
              confidentLanguage: 'German',
              isCorrection: false),
          isNull);
    });
  });

  test('offers: one per pair, most due first', () {
    TranslationEntry fav(int id, String sl, String rl) => TranslationEntry(
          id: id,
          sourceText: 's$id',
          resultText: 'r$id',
          sourceLang: sl,
          targetLang: 'Swahili',
          resultLang: rl,
          aiProvider: 'claude',
          isFavourite: true,
          createdAt: DateTime.utc(2026, 11, id),
        );
    final cards = cardsFor([fav(1, 'sw', 'en'), fav(2, 'de', 'sw'), fav(3, 'sw', 'de')]);

    final offers = offersFor(cards, const <CardKey, CardState>{}, DateTime(2026, 11, 8));

    expect(offers.map((o) => (o.pair, o.due)), [
      (LanguagePair('sw', 'de'), 4),
      (LanguagePair('sw', 'en'), 2),
    ]);
  });
}
