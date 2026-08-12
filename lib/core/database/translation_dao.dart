import 'package:sqflite/sqflite.dart';
import '../../shared/models/translation_entry.dart';

const _table = 'translation_entry';

class TranslationDao {
  const TranslationDao(this._db);

  final Database _db;

  Future<int> insert(TranslationEntry entry) =>
      _db.insert(_table, entry.toMap());

  Future<List<TranslationEntry>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'created_at DESC');
    return rows.map(TranslationEntry.fromMap).toList();
  }

  Future<List<TranslationEntry>> getFavourites() async {
    final rows = await _db.query(
      _table,
      where: 'is_favourite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return rows.map(TranslationEntry.fromMap).toList();
  }

  Future<void> setFavourite(int id, {required bool isFavourite}) =>
      _db.update(
        _table,
        {'is_favourite': isFavourite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> delete(int id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  /// Wipes the history and inserts [entries] in its place (ADR-034).
  ///
  /// Both steps run in one transaction: a failure half-way must not leave the
  /// user with neither their old history nor the new one.
  Future<int> replaceAllWith(List<TranslationEntry> entries) async {
    await _db.transaction((txn) async {
      await txn.delete(_table);
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert(_table, entry.toMap());
      }
      await batch.commit(noResult: true);
    });
    return entries.length;
  }

  /// Inserts backup entries, skipping ones already present (ADR-034).
  ///
  /// Identity is source text + result text + timestamp: re-importing the same
  /// file is a no-op instead of duplicating the whole history.
  Future<int> insertMissing(List<TranslationEntry> entries) async {
    if (entries.isEmpty) return 0;

    final existing = <String>{
      for (final row in await _db.query(
        _table,
        columns: ['source_text', 'result_text', 'created_at'],
      ))
        _identity(
          row['source_text'] as String,
          row['result_text'] as String,
          row['created_at'] as String,
        ),
    };

    var inserted = 0;
    final batch = _db.batch();
    for (final entry in entries) {
      final key = _identity(
        entry.sourceText,
        entry.resultText,
        entry.createdAt.toUtc().toIso8601String(),
      );
      if (!existing.add(key)) continue;
      batch.insert(_table, entry.toMap());
      inserted++;
    }
    await batch.commit(noResult: true);
    return inserted;
  }

  // Escaped NUL as separator, so no field boundary can be forged by the
  // text itself. Written as \u0000, never as a raw control byte.
  static String _identity(String source, String result, String createdAt) =>
      '$source\u0000$result\u0000$createdAt';
}
