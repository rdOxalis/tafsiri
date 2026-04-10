import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../features/translator/translator_controller.dart';
import '../../shared/providers/selected_tab_provider.dart';
import 'history_controller.dart';
import 'widgets/favourites_filter.dart';
import 'widgets/history_list_item.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Column(
        children: [
          const FavouritesFilter(),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.historyEmpty,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      onDismissed: (_) async {
                        final deleted = await ref
                            .read(historyProvider.notifier)
                            .delete(entry.id!);
                        if (deleted == null || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.delete),
                            action: SnackBarAction(
                              label: l10n.undoDelete,
                              onPressed: () => ref
                                  .read(historyProvider.notifier)
                                  .restore(deleted),
                            ),
                          ),
                        );
                      },
                      child: HistoryListItem(
                        entry: entry,
                        onToggleFavourite: () => ref
                            .read(historyProvider.notifier)
                            .toggleFavourite(entry.id!),
                        onTap: () => _confirmReload(context, ref, l10n, entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReload(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyReloadTitle),
        content: Text(l10n.historyReloadMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.historyReloadConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(translatorProvider.notifier).setInputText(entry.sourceText);
    ref.read(selectedTabProvider.notifier).state = 0;
  }
}
