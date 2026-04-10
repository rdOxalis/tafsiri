import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

Future<Database> _openInMemory() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE translation_entry (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          source_text  TEXT    NOT NULL,
          result_text  TEXT    NOT NULL,
          source_lang  TEXT    NOT NULL,
          target_lang  TEXT    NOT NULL,
          ai_provider  TEXT    NOT NULL,
          is_favourite INTEGER NOT NULL DEFAULT 0,
          created_at   TEXT    NOT NULL
        )
      '''),
    ),
  );
  return db;
}

TranslationEntry _entry({
  String sourceText = 'Hello',
  String resultText = 'Habari',
  String sourceLang = 'en',
  String targetLang = 'Swahili',
  String aiProvider = 'claude',
  bool isFavourite = false,
}) =>
    TranslationEntry(
      sourceText: sourceText,
      resultText: resultText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      aiProvider: aiProvider,
      isFavourite: isFavourite,
      createdAt: DateTime.now().toUtc(),
    );

void main() {
  late Database db;
  late TranslationDao dao;

  setUp(() async {
    db = await _openInMemory();
    dao = TranslationDao(db);
  });

  tearDown(() => db.close());

  group('TranslationDao', () {
    test('insert returns a valid id', () async {
      final id = await dao.insert(_entry());
      expect(id, greaterThan(0));
    });

    test('getAll returns entries newest first', () async {
      await dao.insert(_entry(sourceText: 'First'));
      await Future.delayed(const Duration(milliseconds: 10));
      await dao.insert(_entry(sourceText: 'Second'));

      final entries = await dao.getAll();
      expect(entries.length, 2);
      expect(entries.first.sourceText, 'Second');
      expect(entries.last.sourceText, 'First');
    });

    test('getAll returns empty list when no entries', () async {
      final entries = await dao.getAll();
      expect(entries, isEmpty);
    });

    test('delete removes entry', () async {
      final id = await dao.insert(_entry());
      await dao.delete(id);
      final entries = await dao.getAll();
      expect(entries, isEmpty);
    });

    test('setFavourite marks entry as favourite', () async {
      final id = await dao.insert(_entry());
      await dao.setFavourite(id, isFavourite: true);

      final entries = await dao.getAll();
      expect(entries.first.isFavourite, isTrue);
    });

    test('setFavourite unmarks favourite', () async {
      final id = await dao.insert(_entry(isFavourite: true));
      await dao.setFavourite(id, isFavourite: false);

      final entries = await dao.getAll();
      expect(entries.first.isFavourite, isFalse);
    });

    test('getFavourites returns only favourites', () async {
      await dao.insert(_entry(sourceText: 'A'));
      final id = await dao.insert(_entry(sourceText: 'B'));
      await dao.setFavourite(id, isFavourite: true);

      final favs = await dao.getFavourites();
      expect(favs.length, 1);
      expect(favs.first.sourceText, 'B');
    });

    test('fromMap roundtrip preserves all fields', () async {
      final original = _entry(
        sourceText: 'Guten Tag',
        resultText: 'Good day',
        sourceLang: 'de',
        targetLang: 'English',
        aiProvider: 'mistral',
      );
      final id = await dao.insert(original);
      final entries = await dao.getAll();
      final loaded = entries.first;

      expect(loaded.id, id);
      expect(loaded.sourceText, original.sourceText);
      expect(loaded.resultText, original.resultText);
      expect(loaded.sourceLang, original.sourceLang);
      expect(loaded.targetLang, original.targetLang);
      expect(loaded.aiProvider, original.aiProvider);
      expect(loaded.isFavourite, original.isFavourite);
    });
  });
}
