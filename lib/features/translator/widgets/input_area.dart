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
    _textController = TextEditingController();
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

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              minLines: 4,
              decoration: InputDecoration(
                hintText: l10n.inputHint,
                border: InputBorder.none,
              ),
              onChanged: (v) =>
                  ref.read(translatorProvider.notifier).setInputText(v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: l10n.pasteButton,
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text ?? '';
                    if (text.isNotEmpty) {
                      ref
                          .read(translatorProvider.notifier)
                          .setInputText(text);
                    }
                  },
                ),
                IconButton(
                  tooltip: l10n.clearButton,
                  icon: const Icon(Icons.clear),
                  onPressed: hasText
                      ? () {
                          _textController.clear();
                          ref.read(translatorProvider.notifier).clearInput();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
