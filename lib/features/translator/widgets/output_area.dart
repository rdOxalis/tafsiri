import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/settings_controller.dart';
import '../translator_controller.dart';

class OutputArea extends ConsumerWidget {
  const OutputArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(translatorProvider);
    final correctionMode = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.correctionMode ?? false),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 48, 12),
                child: _buildBody(context, l10n, state, correctionMode),
              ),
            ),
            if (state.outputText != null && !state.isLoading)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: l10n.copyButton,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.outputText!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copyButton),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    TranslatorState state,
    bool correctionMode,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage(l10n, state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            if (state.errorDetail != null) ...[
              const SizedBox(height: 6),
              Text(
                state.errorDetail!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    if (state.outputText != null) {
      final notes = state.correctionNotes;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.outputText!,
                style: Theme.of(context).textTheme.bodyLarge),
            if (state.isCorrectionResult && notes != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.correctionNotesTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(notes, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      );
    }
    return Center(
      child: Text(
        correctionMode ? l10n.correctionOutputHint : l10n.outputHint,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  String _errorMessage(AppLocalizations l10n, TranslatorError error) =>
      switch (error) {
        TranslatorError.noApiKey => l10n.errorNoApiKey,
        TranslatorError.apiError => l10n.errorApiError,
        TranslatorError.networkError => l10n.errorNetwork,
      };
}
