import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/database/db_helper.dart';
import 'package:tafsiri/core/database/review_dao.dart';
import 'package:tafsiri/core/database/sqflite_desktop.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/features/flashcards/scheduler.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

Future<Database> _openInMemory() async {
  databaseFactory = createDesktopDatabaseFactory();
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: DbHelper.schemaVersion,
      onCreate: (db, _) => DbHelper.createSchema(db),
    ),
  );
}

Future<int> _addEntry(TranslationDao dao) => dao.insert(TranslationEntry(
      sourceText: 'das ist gesund',
      resultText: 'hii ni yenye afya',
      sourceLang: 'de',
      targetLang: 'Swahili',
      aiProvider: 'claude',
      isFavourite: true,
      createdAt: DateTime.utc(2026, 11, 8),
    ));

void main() {
  late Database db;
  late TranslationDao entries;
  late ReviewDao reviews;

  setUp(() async {
    db = await _openInMemory();
    entries = TranslationDao(db);
    reviews = ReviewDao(db);
  });
  tearDown(() => db.close());

  test('stores and reads back a card state exactly', () async {
    final id = await _addEntry(entries);
    final now = DateTime.utc(2026, 11, 8, 9, 30);
    final state = schedule(
      schedule(null, Grade.correct, now),
      Grade.almost,
      now.add(const Duration(days: 1)),
    );

    await reviews.save((id, CardDirection.recall), state);
    final read = (await reviews.getAll())[(id, CardDirection.recall)]!;

    expect(read.dueAt, state.dueAt);
    expect(read.intervalDays, state.intervalDays);
    expect(read.ease, state.ease);
    expect(read.repetitions, state.repetitions);
    expect(read.lapses, state.lapses);
    expect(read.firstReviewedAt, state.firstReviewedAt);
    expect(read.lastReviewedAt, state.lastReviewedAt);
  });

  test('saving again replaces the state; directions are separate', () async {
    final id = await _addEntry(entries);
    final now = DateTime.utc(2026, 11, 8);
    await reviews.save((id, CardDirection.produce), schedule(null, Grade.correct, now));
    await reviews.save((id, CardDirection.produce), schedule(null, Grade.wrong, now));
    await reviews.save((id, CardDirection.recall), schedule(null, Grade.correct, now));

    final all = await reviews.getAll();
    expect(all, hasLength(2));
    expect(all[(id, CardDirection.produce)]!.repetitions, 0);
    expect(all[(id, CardDirection.recall)]!.repetitions, 1);
  });

  test('the state of a deleted entry is cleaned up', () async {
    final id = await _addEntry(entries);
    await reviews.save(
        (id, CardDirection.produce), schedule(null, Grade.correct, DateTime.now()));

    await entries.delete(id);

    expect(await reviews.getAll(), isEmpty);
  });

  test('an entry deleted and restored keeps its progress', () async {
    // Undo in the history re-inserts the entry with its id; the state must
    // still be there, so deleting an entry does not touch it by itself.
    final id = await _addEntry(entries);
    await reviews.save(
        (id, CardDirection.produce), schedule(null, Grade.correct, DateTime.now()));
    final entry = (await entries.getAll()).single;

    await entries.delete(id);
    await entries.insert(entry);

    expect(await reviews.getAll(), hasLength(1));
  });
}
