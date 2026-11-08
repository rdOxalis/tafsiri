import 'package:sqflite/sqflite.dart';
import '../../features/flashcards/flashcard.dart';
import '../../features/flashcards/scheduler.dart';

const _table = 'review_card';

/// Learning state of the flashcards (ADR-082).
class ReviewDao {
  const ReviewDao(this._db);

  final Database _db;

  /// Every stored state, keyed by card. Orphans — rows whose history entry
  /// is gone — are removed first, so they never count as reviewed today.
  Future<Map<CardKey, CardState>> getAll() async {
    await deleteOrphans();
    final rows = await _db.query(_table);
    return {
      for (final row in rows)
        (
          row['entry_id'] as int,
          CardDirection.fromKey(row['direction'] as String),
        ): _fromRow(row),
    };
  }

  Future<void> save(CardKey key, CardState state) => _db.insert(
        _table,
        _toRow(key, state),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Removes the state of cards whose history entry was deleted. Kept apart
  /// from deleting the entry so that an undone delete keeps its progress.
  Future<int> deleteOrphans() => _db.rawDelete(
        'DELETE FROM $_table WHERE entry_id NOT IN '
        '(SELECT id FROM translation_entry)',
      );

  static CardState _fromRow(Map<String, Object?> row) => CardState(
        dueAt: DateTime.parse(row['due_at'] as String),
        intervalDays: (row['interval_days'] as num).toDouble(),
        ease: (row['ease'] as num).toDouble(),
        repetitions: row['repetitions'] as int,
        lapses: row['lapses'] as int,
        firstReviewedAt: DateTime.parse(row['first_reviewed_at'] as String),
        lastReviewedAt: DateTime.parse(row['last_reviewed_at'] as String),
      );

  static Map<String, Object?> _toRow(CardKey key, CardState s) => {
        'entry_id': key.$1,
        'direction': key.$2.key,
        'due_at': s.dueAt.toUtc().toIso8601String(),
        'interval_days': s.intervalDays,
        'ease': s.ease,
        'repetitions': s.repetitions,
        'lapses': s.lapses,
        'first_reviewed_at': s.firstReviewedAt.toUtc().toIso8601String(),
        'last_reviewed_at': s.lastReviewedAt.toUtc().toIso8601String(),
      };
}
