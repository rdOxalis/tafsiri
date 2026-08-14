import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'translator_controller.dart';
import 'widgets/action_bar.dart';
import 'widgets/input_area.dart';
import 'widgets/output_area.dart';

class TranslatorScreen extends ConsumerWidget {
  const TranslatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen(
      translatorProvider.select((s) => s.ocrError),
      (_, failure) {
        if (failure == null) return;
        ref.read(translatorProvider.notifier).clearOcrError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (failure) {
              OcrFailure.engineMissing => l10n.errorOcrEngineMissing,
              OcrFailure.failed => l10n.errorOcrFailed,
            }),
          ),
        );
      },
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
            child: Row(
              children: [
                Text(
                  'Tafsiri',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                const _CorrectionModeToggle(),
              ],
            ),
          ),
          const Expanded(child: InputArea()),
          const ActionBar(),
          const Expanded(child: OutputArea()),
        ],
      ),
    );
  }
}

/// Correction mode switch (ADR-033) — lives in the translator header so it can
/// be flipped per input without opening Settings, but persists like a setting.
class _CorrectionModeToggle extends ConsumerWidget {
  const _CorrectionModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    final primaryLang = settings.targetLanguage.isNotEmpty
        ? settings.targetLanguage
        : '…';

    final on = settings.correctionMode;
    final scheme = Theme.of(context).colorScheme;

    // The default selected chip colour (secondaryContainer) is barely darker
    // than the unselected one, so on/off was hard to tell apart at a glance —
    // fill the chip with the primary colour and spell the state out.
    return Tooltip(
      message: l10n.correctionModeInfo(primaryLang),
      child: FilterChip(
        selected: on,
        showCheckmark: false,
        selectedColor: scheme.primary,
        avatar: Icon(
          on ? Icons.spellcheck : Icons.edit_note,
          size: 18,
          color: on ? scheme.onPrimary : null,
        ),
        label: Text(
          '${l10n.correctionModeLabel} (${on ? l10n.stateOn : l10n.stateOff})',
        ),
        labelStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: on ? scheme.onPrimary : null),
        onSelected: (value) =>
            ref.read(settingsProvider.notifier).setCorrectionMode(value),
      ),
    );
  }
}
