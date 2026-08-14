import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Ctrl+V / Cmd+V: an image if the clipboard has one, otherwise text.
  ///
  /// Taking the shortcut over means the field's own paste no longer runs, so
  /// the text branch has to be reproduced faithfully — at the cursor, replacing
  /// the selection — rather than dropped or turned into "replace everything"
  /// (ADR-040).
  Future<void> _paste() async {
    final handled =
        await ref.read(translatorProvider.notifier).pasteImageFromClipboard();
    if (handled || !mounted) return;

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty || !mounted) return;

    final value = _textController.value;
    // A field that has never held the cursor reports an invalid selection;
    // appending is the sane reading of "paste" in that state.
    final at = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final combined = value.text.replaceRange(at.start, at.end, pasted);

    _textController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: at.start + pasted.length),
    );
    // Setting `value` directly does not fire `onChanged`, and the listener in
    // build() leaves the controller alone because the texts now agree — so the
    // cursor stays where the paste put it.
    ref.read(translatorProvider.notifier).setInputText(combined);
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
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                    _paste,
                const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                    _paste,
              },
              child: TextField(
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
