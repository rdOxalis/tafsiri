import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
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
      (_, hasError) {
        if (!hasError) return;
        ref.read(translatorProvider.notifier).clearOcrError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOcrFailed)),
        );
      },
    );

    return const Column(
      children: [
        Expanded(child: InputArea()),
        Expanded(child: OutputArea()),
        ActionBar(),
      ],
    );
  }
}
