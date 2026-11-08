import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_helper.dart';
import 'review_dao.dart';
import 'translation_dao.dart';

final translationDaoProvider = FutureProvider<TranslationDao>((ref) async {
  final db = await DbHelper.database;
  return TranslationDao(db);
});

/// Learning state of the flashcards (ADR-082).
final reviewDaoProvider = FutureProvider<ReviewDao>((ref) async {
  final db = await DbHelper.database;
  return ReviewDao(db);
});
