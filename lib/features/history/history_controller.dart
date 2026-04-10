import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/dao_provider.dart';
import '../../shared/models/translation_entry.dart';

class HistoryController extends AsyncNotifier<List<TranslationEntry>> {
  bool showFavouritesOnly = false;

  @override
  Future<List<TranslationEntry>> build() async {
    final dao = await ref.watch(translationDaoProvider.future);
    return showFavouritesOnly ? dao.getFavourites() : dao.getAll();
  }

  void toggleFilter() {
    showFavouritesOnly = !showFavouritesOnly;
    reload();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dao = await ref.read(translationDaoProvider.future);
      return showFavouritesOnly ? dao.getFavourites() : dao.getAll();
    });
  }

  Future<TranslationEntry?> delete(int id) async {
    final current = state.valueOrNull ?? [];
    final deleted = current.where((e) => e.id == id).firstOrNull;
    if (deleted == null) return null;

    final dao = await ref.read(translationDaoProvider.future);
    await dao.delete(id);
    state = AsyncData(current.where((e) => e.id != id).toList());
    return deleted;
  }

  Future<void> restore(TranslationEntry entry) async {
    final dao = await ref.read(translationDaoProvider.future);
    await dao.insert(entry);
    await reload();
  }

  Future<void> toggleFavourite(int id) async {
    final current = state.valueOrNull ?? [];
    final entry = current.where((e) => e.id == id).firstOrNull;
    if (entry == null) return;

    final dao = await ref.read(translationDaoProvider.future);
    final newValue = !entry.isFavourite;
    await dao.setFavourite(id, isFavourite: newValue);

    state = AsyncData(current
        .map((e) => e.id == id ? e.copyWith(isFavourite: newValue) : e)
        .toList());
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryController, List<TranslationEntry>>(
  HistoryController.new,
);
