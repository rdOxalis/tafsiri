import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../history_controller.dart';

class FavouritesFilter extends ConsumerWidget {
  const FavouritesFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(historyProvider.notifier);
    // Watch to rebuild when showFavouritesOnly changes (triggered by reload).
    ref.watch(historyProvider);
    final showFavourites = controller.showFavouritesOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.allLabel),
            selected: !showFavourites,
            onSelected: (_) {
              if (showFavourites) controller.toggleFilter();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.favouritesLabel),
            selected: showFavourites,
            onSelected: (_) {
              if (!showFavourites) controller.toggleFilter();
            },
          ),
        ],
      ),
    );
  }
}
