import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../flashcards/flashcard_controller.dart';
import '../../flashcards/flashcard_screen.dart';
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
    final learnable = ref.watch(learnableCountProvider).valueOrNull;

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
          const Spacer(),
          // Flashcards from the favourite translations (ADR-082): shown as
          // soon as one exists, with how many are waiting now.
          if (learnable != null)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.school_outlined, size: 18),
              label: Text(l10n.learnButton(learnable)),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const FlashcardScreen(),
                ));
                ref.invalidate(learnableCountProvider);
              },
            ),
        ],
      ),
    );
  }
}
