import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DbHelper {
  DbHelper._();

  static Database? _db;

  /// Current schema version. 2 adds `mode` and `notes` (ADR-033).
  static const schemaVersion = 2;

  /// Schema of the current version — shared with the tests so the two cannot
  /// drift apart.
  static const createTableSql = '''
          CREATE TABLE translation_entry (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            source_text  TEXT    NOT NULL,
            result_text  TEXT    NOT NULL,
            source_lang  TEXT    NOT NULL,
            target_lang  TEXT    NOT NULL,
            ai_provider  TEXT    NOT NULL,
            is_favourite INTEGER NOT NULL DEFAULT 0,
            created_at   TEXT    NOT NULL,
            mode         TEXT    NOT NULL DEFAULT 'translate',
            notes        TEXT
          )
        ''';

  /// ADR-014: add migration steps here when the schema version increments.
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('[DbHelper] onUpgrade $oldVersion → $newVersion');
    if (oldVersion < 2) {
      // ADR-033: correction mode records how the entry was produced.
      await db.execute(
        "ALTER TABLE translation_entry "
        "ADD COLUMN mode TEXT NOT NULL DEFAULT 'translate'",
      );
      await db.execute('ALTER TABLE translation_entry ADD COLUMN notes TEXT');
    }
  }

  static Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  /// On mobile sqflite knows its own databases directory. On desktop the FFI
  /// factory would fall back to a working-directory path, so use the platform
  /// application support directory instead (ADR-031).
  static Future<String> _databasesDirectory() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return (await getApplicationSupportDirectory()).path;
    }
    return getDatabasesPath();
  }

  static Future<Database> _open() async {
    final path = join(await _databasesDirectory(), 'tafsiri.db');
    debugPrint('[DbHelper] opening database at $path');
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) => db.execute(createTableSql),
      onUpgrade: migrate,
    );
  }

  /// For testing: inject an already-open in-memory database.
  @visibleForTesting
  static void injectForTest(Database db) => _db = db;

  /// For testing: reset singleton so a fresh database is opened next time.
  @visibleForTesting
  static void resetForTest() => _db = null;
}
