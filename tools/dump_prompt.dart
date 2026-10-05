// Prints the exact system prompt and user message the app would send, as JSON,
// so a probe can fire them at a provider without building or running the app
// (ADR-071). Used by tools/probe_prompt.sh; harmless on its own.
//
// dart run tools/dump_prompt.dart <learning> <confident> <correct|translate> \
//     <explanations on|off> <text> [agreement on|off] [analysis on|off]
//
// The last argument exists so a probe can measure the agreement rule of
// ADR-072 against the same prompt without it, in one run.
//
// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:tafsiri/core/services/ai_service.dart';

void main(List<String> args) {
  if (args.length < 5 || args.length > 7) {
    print('usage: dump_prompt.dart <learning> <confident> '
        '<correct|translate> <on|off> <text> [agreement on|off] '
        '[analysis on|off]');
    return;
  }
  final [learning, confident, mode, explain, text] = args.take(5).toList();
  final agreement = args.length >= 6 ? args[5] : 'on';
  final analysis = args.length == 7 ? args[6] : 'off';

  print(const JsonEncoder().convert({
    'system': AiService.systemPromptFor(
      targetLanguage: learning,
      altLanguage: confident,
      correctionMode: mode == 'correct',
      explanations: explain == 'on',
      agreementRule: agreement == 'on',
      analysisFirst: analysis == 'on',
    ),
    'user': AiService.buildUserMessage(text),
  }));
}
