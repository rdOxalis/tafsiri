import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../translator_controller.dart';

class InputArea extends ConsumerStatefulWidget {
  const InputArea({super.key});

  @override
  ConsumerState<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends ConsumerState<InputArea> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // Read current state so history-reload (set before this widget is built) is visible.
    final initialText = ref.read(translatorProvider).inputText;
    _textController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Sync external changes (e.g. reload from history) into the text field.
    ref.listen(translatorProvider.select((s) => s.inputText), (_, next) {
      if (_textController.text != next) {
        _textController.text = next;
        _textController.selection =
            TextSelection.collapsed(offset: next.length);
      }
    });

    final hasText =
        ref.watch(translatorProvider.select((s) => s.inputText.isNotEmpty));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: l10n.inputHint,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.fromLTRB(16, 12, 48, 12),
              ),
              onChanged: (v) =>
                  ref.read(translatorProvider.notifier).setInputText(v),
            ),
            if (hasText)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: l10n.clearButton,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _textController.clear();
                    ref.read(translatorProvider.notifier).clearInput();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
