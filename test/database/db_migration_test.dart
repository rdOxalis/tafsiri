@TestOn('linux || mac-os || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/database/db_helper.dart';
import 'package:tafsiri/core/database/sqflite_desktop.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// Schema as shipped in app versions up to 1.0.8 (before ADR-033).
const _v1Schema = '''
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
''';

void main() {
  test('v1 → v2 migration adds mode/notes and keeps existing rows', () async {
    databaseFactory = createDesktopDatabaseFactory();

    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(_v1Schema),
      ),
    );
    addTearDown(db.close);

    // A row written by the old app version.
    await db.insert('translation_entry', {
      'source_text': 'Hello',
      'result_text': 'Habari',
      'source_lang': 'en',
      'target_lang': 'Swahili',
      'ai_provider': 'mistral',
      'is_favourite': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    await DbHelper.migrate(db, 1, DbHelper.schemaVersion);

    final dao = TranslationDao(db);
    final migrated = await dao.getAll();
    expect(migrated, hasLength(1));
    expect(migrated.single.sourceText, 'Hello');
    expect(migrated.single.isFavourite, isTrue);
    // Pre-existing entries are translations.
    expect(migrated.single.mode, kModeTranslate);
    expect(migrated.single.isCorrection, isFalse);
    expect(migrated.single.notes, isNull);

    // The new columns are writable after the migration.
    await dao.insert(TranslationEntry(
      sourceText: 'Tafadhali nipe Butter.',
      resultText: 'Tafadhali nipe siagi.',
      sourceLang: 'sw',
      targetLang: 'Swahili',
      aiProvider: 'mistral',
      createdAt: DateTime.now().toUtc(),
      mode: kModeCorrect,
      notes: '- Butter → siagi: German for "butter".',
    ));

    final all = await dao.getAll();
    expect(all, hasLength(2));
    final correction = all.firstWhere((e) => e.isCorrection);
    expect(correction.resultText, 'Tafadhali nipe siagi.');
    expect(correction.notes, contains('siagi'));
  });
}
