import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/translation_entry.dart';

final _dateFmt = DateFormat('d MMM yyyy HH:mm');

class HistoryListItem extends StatelessWidget {
  final TranslationEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;

  const HistoryListItem({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.sourceText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                entry.resultText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ProviderBadge(provider: entry.aiProvider),
                  const SizedBox(width: 8),
                  Text(
                    entry.targetLang,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    _dateFmt.format(entry.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  IconButton(
                    icon: Icon(
                      entry.isFavourite ? Icons.star : Icons.star_border,
                      size: 20,
                    ),
                    color: entry.isFavourite
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: entry.isFavourite
                        ? 'Remove from favourites'
                        : 'Add to favourites',
                    onPressed: onToggleFavourite,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  final String provider;
  const _ProviderBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    final label = switch (provider) {
      'claude' => 'C',
      'openai' => 'G',
      _ => 'M',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
