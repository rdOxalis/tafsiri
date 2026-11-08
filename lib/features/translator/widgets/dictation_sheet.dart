import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/settings_controller.dart';
import '../dictation.dart';
import '../translator_controller.dart';

/// Starts a dictation and shows the window for it (ADR-080).
///
/// The window stays open while the user speaks: it shows the recognition
/// language, which can be switched between the learning and the confident
/// language at any moment, whether the phone is listening right now, and
/// what it has heard. Done puts the text into the input field.
Future<void> showDictationSheet(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(translatorProvider.notifier);
  await notifier.startDictation();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    builder: (_) => const DictationSheet(),
  );
  // Closed with Back or by tapping outside: keep what was said, as Done
  // would. Only Cancel throws it away.
  await notifier.finishDictation();
}

class DictationSheet extends ConsumerWidget {
  const DictationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(translatorProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final notifier = ref.read(translatorProvider.notifier);

    // The dictation can end without the user: the quick mode stops at the
    // first pause, and a recogniser that cannot work gives up.
    ref.listen(translatorProvider.select((s) => s.isListening), (_, now) {
      if (!now && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });

    final current = state.sttLang;
    // The learning and the confident language: the two a learner switches
    // between, one tap each.
    final configured = <String>[];
    for (final name in [
      settings?.targetLanguage ?? '',
      settings?.altLanguage ?? '',
    ]) {
      final code = sttCodeForLanguageName(name);
      if (code != null && !configured.contains(code)) configured.add(code);
    }
    final shown = [
      ...configured,
      if (current != null && !configured.contains(current)) current,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dictationTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final code in shown)
                  ChoiceChip(
                    label: Text(sttLanguageName(code)),
                    selected: code == current,
                    onSelected: (_) => notifier.setDictationLanguage(code),
                  ),
                PopupMenuButton<String>(
                  tooltip: l10n.dictationOtherLanguage,
                  onSelected: notifier.setDictationLanguage,
                  itemBuilder: (_) => [
                    for (final (code, name) in sortedSttLanguageOptions)
                      if (code.isNotEmpty)
                        PopupMenuItem(value: code, child: Text(name)),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.language, size: 18),
                    label: Text(l10n.dictationOtherLanguage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isMicHot
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    state.isMicHot ? Icons.mic : Icons.mic_none,
                    color: state.isMicHot
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  state.isMicHot ? l10n.dictationListening : l10n.dictationWait,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 160),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  state.dictationPreview,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: notifier.cancelDictation,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: notifier.finishDictation,
                  child: Text(l10n.dictationDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The native name of a recognition language, as the settings list shows it.
String sttLanguageName(String code) {
  for (final (c, name) in kSttLanguageOptions) {
    if (c == code) return name;
  }
  return code;
}
