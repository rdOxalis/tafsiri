import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  DbHelper._();

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'tafsiri.db');
    debugPrint('[DbHelper] opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
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
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ADR-014: add migration steps here when schema version increments
        debugPrint('[DbHelper] onUpgrade $oldVersion → $newVersion');
      },
    );
  }

  /// For testing: inject an already-open in-memory database.
  @visibleForTesting
  static void injectForTest(Database db) => _db = db;

  /// For testing: reset singleton so a fresh database is opened next time.
  @visibleForTesting
  static void resetForTest() => _db = null;
}
