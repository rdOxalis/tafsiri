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
      translatorProvider.select((s) => (s.ocrError, s.ocrErrorDetail)),
      (_, next) {
        final (failure, detail) = next;
        if (failure == null) return;
        ref.read(translatorProvider.notifier).clearOcrError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (failure) {
              OcrFailure.engineMissing => l10n.errorOcrEngineMissing,
              OcrFailure.languageMissing =>
                l10n.errorOcrLanguageMissing(detail ?? ''),
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
                const SizedBox(width: 12),
                // Two chips do not fit beside the title on a phone, so they
                // wrap under it rather than overflowing (ADR-060).
                const Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _CorrectionModeToggle(),
                      _ExplanationsToggle(),
                    ],
                  ),
                ),
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

    final on = settings.correctionMode;
    return _ModeChip(
      on: on,
      label: l10n.correctionModeLabel,
      tooltip: l10n.correctionModeInfo(_learningLanguage(settings)),
      icon: on ? Icons.spellcheck : Icons.edit_note,
      onChanged: ref.read(settingsProvider.notifier).setCorrectionMode,
    );
  }
}

/// Word explanations switch (ADR-060) — sits beside the correction chip
/// because both turn a translation into something a learner can work with.
class _ExplanationsToggle extends ConsumerWidget {
  const _ExplanationsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    final on = settings.explanationsMode;
    return _ModeChip(
      on: on,
      label: l10n.explanationsLabel,
      tooltip: l10n.explanationsInfo(_learningLanguage(settings)),
      icon: on ? Icons.menu_book : Icons.menu_book_outlined,
      onChanged: ref.read(settingsProvider.notifier).setExplanationsMode,
    );
  }
}

String _learningLanguage(SettingsState settings) =>
    settings.targetLanguage.isNotEmpty ? settings.targetLanguage : '\u2026';

/// A header switch, shared by both modes.
///
/// The default selected chip colour (secondaryContainer) is barely darker than
/// the unselected one, so on/off was hard to tell apart at a glance — fill the
/// chip with the primary colour and spell the state out.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.on,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onChanged,
  });

  final bool on;
  final String label;
  final String tooltip;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: FilterChip(
        selected: on,
        showCheckmark: false,
        selectedColor: scheme.primary,
        avatar: Icon(icon, size: 18, color: on ? scheme.onPrimary : null),
        label: Text('$label (${on ? l10n.stateOn : l10n.stateOff})'),
        labelStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: on ? scheme.onPrimary : null),
        onSelected: onChanged,
      ),
    );
  }
}
