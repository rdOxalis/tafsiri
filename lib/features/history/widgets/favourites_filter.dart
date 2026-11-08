import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../flashcards/flashcard.dart';
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
    final overview = ref.watch(learnOverviewProvider).valueOrNull;

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
          if (overview != null)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.school_outlined, size: 18),
              label: Text(l10n.learnButton(overview.due)),
              onPressed: () => _startLearning(context, ref),
            ),
        ],
      ),
    );
  }

  /// Works out what can be learnt, lets the user pick a language pair when
  /// there is more than one (ADR-083), and opens the session.
  Future<void> _startLearning(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final offers = await prepareLearning(ref);
    if (!context.mounted) return;
    if (offers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.learnNoPairYet)),
      );
      return;
    }
    final pair = offers.length == 1
        ? offers.single.pair
        : await showDialog<LanguagePair>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text(l10n.learnChoosePair),
              children: [
                for (final o in offers)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(o.pair),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('${pairLabel(o.pair)}  (${o.due})'),
                    ),
                  ),
              ],
            ),
          );
    if (pair == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FlashcardScreen(pair: pair),
    ));
    ref.invalidate(learnOverviewProvider);
  }
}
