import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../translator_controller.dart';

class OutputArea extends ConsumerWidget {
  const OutputArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(translatorProvider);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildBody(context, l10n, state)),
            if (state.outputText != null && !state.isLoading)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.copyButton,
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: state.outputText!));
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
      BuildContext context, AppLocalizations l10n, TranslatorState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Text(
          _errorMessage(l10n, state.error!),
          style: TextStyle(
              color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state.outputText != null) {
      return SingleChildScrollView(
        child: Text(state.outputText!,
            style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    return Center(
      child: Text(
        l10n.outputHint,
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
