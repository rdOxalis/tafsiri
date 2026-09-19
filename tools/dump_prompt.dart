// Prints the exact system prompt and user message the app would send, as JSON,
// so a probe can fire them at a provider without building or running the app
// (ADR-071). Used by tools/probe_prompt.sh; harmless on its own.
//
// dart run tools/dump_prompt.dart <learning> <confident> <correct|translate> \
//     <explanations on|off> <text>
//
// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:tafsiri/core/services/ai_service.dart';

void main(List<String> args) {
  if (args.length != 5) {
    print('usage: dump_prompt.dart <learning> <confident> '
        '<correct|translate> <on|off> <text>');
    return;
  }
  final [learning, confident, mode, explain, text] = args;

  print(const JsonEncoder().convert({
    'system': AiService.systemPromptFor(
      targetLanguage: learning,
      altLanguage: confident,
      correctionMode: mode == 'correct',
      explanations: explain == 'on',
    ),
    'user': AiService.buildUserMessage(text),
  }));
}
