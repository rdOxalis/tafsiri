@TestOn('linux || mac-os || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/database/db_helper.dart';
import 'package:tafsiri/core/database/sqflite_desktop.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// Guards the desktop SQLite wiring (ADR-031): the FFI factory must be able to
/// resolve the system SQLite from its worker isolate and open an on-disk file.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tafsiri_db_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('desktop factory opens an on-disk database and round-trips an entry',
      () async {
    final factory = createDesktopDatabaseFactory();
    final path = join(tempDir.path, 'tafsiri.db');

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DbHelper.schemaVersion,
        onCreate: (db, _) => db.execute(DbHelper.createTableSql),
      ),
    );
    addTearDown(db.close);

    expect(File(path).existsSync(), isTrue);

    final dao = TranslationDao(db);
    await dao.insert(TranslationEntry(
      sourceText: 'Habari',
      resultText: 'Hello',
      sourceLang: 'sw',
      targetLang: 'en',
      aiProvider: 'mistral',
      createdAt: DateTime.now(),
    ));

    final all = await dao.getAll();
    expect(all, hasLength(1));
    expect(all.single.sourceText, 'Habari');
  });
}
