import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    final isOcrProcessing =
        ref.watch(translatorProvider.select((s) => s.isOcrProcessing));

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
