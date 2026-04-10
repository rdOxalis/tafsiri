import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_helper.dart';
import 'translation_dao.dart';

final translationDaoProvider = FutureProvider<TranslationDao>((ref) async {
  final db = await DbHelper.database;
  return TranslationDao(db);
});
