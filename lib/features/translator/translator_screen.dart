import 'package:flutter/material.dart';
import 'widgets/action_bar.dart';
import 'widgets/input_area.dart';
import 'widgets/output_area.dart';

class TranslatorScreen extends StatelessWidget {
  const TranslatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: InputArea()),
        Expanded(child: OutputArea()),
        ActionBar(),
      ],
    );
  }
}
