import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../translator_controller.dart';

class ActionBar extends ConsumerWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading =
        ref.watch(translatorProvider.select((s) => s.isLoading));
    final isSttAvailable =
        ref.watch(translatorProvider.select((s) => s.isSttAvailable));
    final isListening =
        ref.watch(translatorProvider.select((s) => s.isListening));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          // Microphone
          IconButton(
            tooltip: l10n.microphoneButton,
            icon: Icon(isListening ? Icons.mic : Icons.mic_none),
            color: isListening
                ? Theme.of(context).colorScheme.error
                : null,
            onPressed: (isLoading || !isSttAvailable)
                ? null
                : () => ref.read(translatorProvider.notifier).toggleListening(),
          ),
          // Image — stub, wired in Phase 11
          IconButton(
            tooltip: l10n.imageButton,
            icon: const Icon(Icons.image),
            onPressed: isLoading ? null : () {},
          ),
          const Spacer(),
          FilledButton.icon(
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.translate),
            label: Text(l10n.translateButton),
            onPressed: isLoading
                ? null
                : () => ref.read(translatorProvider.notifier).translate(),
          ),
        ],
      ),
    );
  }
}
