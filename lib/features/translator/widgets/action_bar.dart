import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/ocr/ocr_service_factory.dart';
import '../../../shared/providers/selected_tab_provider.dart';
import '../../settings/settings_controller.dart';
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
    final isOcrProcessing =
        ref.watch(translatorProvider.select((s) => s.isOcrProcessing));
    final settings = ref.watch(settingsProvider).valueOrNull;
    final primaryLang = settings?.targetLanguage.isNotEmpty == true
        ? settings!.targetLanguage
        : '…';
    final secondaryLang = settings?.altLanguage.isNotEmpty == true
        ? settings!.altLanguage
        : '…';
    final correctionMode = settings?.correctionMode ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          // Translation logic info
          IconButton(
            tooltip: l10n.translationInfoTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(
              context,
              ref,
              l10n,
              primaryLang,
              secondaryLang,
              correctionMode: correctionMode,
            ),
          ),
          // Microphone
          IconButton(
            tooltip: l10n.microphoneButton,
            icon: Icon(isListening ? Icons.mic : Icons.mic_none),
            color: isListening
                ? Theme.of(context).colorScheme.error
                : null,
            onPressed: (isLoading || !isSttAvailable)
                ? null
                : () =>
                    ref.read(translatorProvider.notifier).toggleListening(),
          ),
          // Image / OCR
          IconButton(
            tooltip: l10n.imageButton,
            icon: isOcrProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image),
            onPressed: (isLoading || isOcrProcessing)
                ? null
                : () => _showImageSourceSheet(context, ref, l10n),
          ),
          // Paste from clipboard
          IconButton(
            tooltip: l10n.pasteButton,
            icon: const Icon(Icons.content_paste),
            onPressed: isLoading
                ? null
                : () async {
                    final data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text ?? '';
                    if (text.isNotEmpty) {
                      ref
                          .read(translatorProvider.notifier)
                          .setInputText(text);
                    }
                  },
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
                // Deliberately not the spellcheck icon: that one marks the
                // correction-mode toggle (a state), this button is the action.
                : Icon(correctionMode ? Icons.auto_fix_high : Icons.translate),
            label: Text(
              correctionMode ? l10n.correctionButton : l10n.translateButton,
            ),
            onPressed: isLoading
                ? null
                : () => ref.read(translatorProvider.notifier).translate(),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String primaryLang,
    String secondaryLang, {
    required bool correctionMode,
  }) {
    void goToSettings() {
      ref.read(selectedTabProvider.notifier).state = 2;
    }

    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(correctionMode ? Icons.spellcheck : Icons.translate, size: 28),
        title: Text(l10n.translationInfoTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                Text(l10n.translationInfoPart1),
                GestureDetector(
                  onTap: () { Navigator.pop(ctx); goToSettings(); },
                  child: Text(primaryLang, style: linkStyle),
                ),
                Text(l10n.translationInfoPart2),
                GestureDetector(
                  onTap: () { Navigator.pop(ctx); goToSettings(); },
                  child: Text(primaryLang, style: linkStyle),
                ),
                Text(l10n.translationInfoPart3),
                GestureDetector(
                  onTap: () { Navigator.pop(ctx); goToSettings(); },
                  child: Text(secondaryLang, style: linkStyle),
                ),
                Text(l10n.translationInfoPart4),
              ],
            ),
            if (correctionMode) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.spellcheck, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.correctionModeInfo(primaryLang))),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); goToSettings(); },
            child: Text(l10n.settingsTitle),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Desktop image pickers do file selection only, so offering the
            // camera here would be a guaranteed dead end (ADR-037).
            if (hasCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.ocrSourceCamera),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(translatorProvider.notifier).pickImageAndRecognize(
                        source: ImageSource.camera,
                      );
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.ocrSourceGallery),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(translatorProvider.notifier).pickImageAndRecognize(
                      source: ImageSource.gallery,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
