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
}
