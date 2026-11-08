// Runs the flashcard answer check against the real providers (ADR-082).
//
// A unit test can show what the prompt says; only this shows how strict a
// model is with it. Keys come from the environment and are never printed:
//   read -rs ANTHROPIC_API_KEY && export ANTHROPIC_API_KEY
//   read -rs OPENAI_API_KEY && export OPENAI_API_KEY
//   read -rs MISTRAL_API_KEY && export MISTRAL_API_KEY
//   .flutter/bin/flutter test tools/probe_answer_check.dart
//
// Every model in the catalogue whose provider has a key is asked about every
// row of tools/answer_check_fixture.tsv. The graded answers land in
// build/probe/answer_check-<time>.tsv.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/ai_models.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/claude_service.dart';
import 'package:tafsiri/core/services/mistral_service.dart';
import 'package:tafsiri/core/services/openai_service.dart';
import 'package:tafsiri/features/flashcards/answer_check.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

const _learning = 'Swahili';
const _confident = 'German';

void main() {
  test('answer check against the real providers', () async {
    final keys = {
      kProviderClaude: Platform.environment['ANTHROPIC_API_KEY'] ?? '',
      kProviderOpenAI: Platform.environment['OPENAI_API_KEY'] ?? '',
      kProviderMistral: Platform.environment['MISTRAL_API_KEY'] ?? '',
    };
    final services = <String, AiService>{
      kProviderClaude: ClaudeService(),
      kProviderOpenAI: OpenAiService(),
      kProviderMistral: MistralService(),
    };

    final rows = File('tools/answer_check_fixture.tsv')
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
        .map((l) => l.split('\t'))
        .toList();

    final out = StringBuffer('model\tid\taccept\tgot\tok\tfeedback\n');
    final summary = <String>[];
    for (final provider in keys.keys) {
      if (keys[provider]!.isEmpty) {
        summary.add('$provider: no key, skipped');
        continue;
      }
      for (final model in modelsFor(provider)) {
        var ok = 0;
        for (final r in rows) {
          final card = _card(r);
          String got;
          String feedback;
          try {
            final v = await checkAnswer(
              services[provider]!,
              card: card,
              answer: r[4],
              learningLanguage: _learning,
              confidentLanguage: _confident,
              apiKey: keys[provider]!,
              model: model.id,
            );
            got = v.grade.name;
            feedback = v.feedback;
          } catch (e) {
            got = 'error';
            feedback = e.toString();
          }
          final accept = r[5].split(',');
          final hit = accept.contains(got);
          if (hit) ok++;
          out.writeln([
            model.id, r[0], r[5], got, hit ? 'ok' : 'MISS',
            feedback.replaceAll('\n', ' | '),
          ].join('\t'));
          if (!hit) {
            summary.add('  ${model.id} ${r[0]}: got $got, '
                'want ${r[5]} — ${feedback.replaceAll('\n', ' | ')}');
          }
        }
        summary.add('${model.id}: $ok/${rows.length}');
      }
    }

    final dir = Directory('build/probe')..createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/answer_check-$stamp.tsv')
      ..writeAsStringSync(out.toString());
    for (final r in rows) {
      final c = _card(r);
      expect((c.prompt, c.expected), (r[2], r[3]), reason: r[0]);
    }
    // ignore: avoid_print
    print('${summary.join('\n')}\n\nwritten to ${file.path}');
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Flashcard _card(List<String> r) {
  final produce = r[1] == 'produce';
  // Build the favourite the card would come from, so the check sees the
  // same languages as in the app.
  final entry = TranslationEntry(
    id: 1,
    // The favourite was a translation from the shown text to the reference;
    // its target language decides which card it is.
    sourceText: r[2],
    resultText: r[3],
    // As the translator stores it: the detected input language, and the
    // learning language of the time as target_lang.
    sourceLang: produce ? 'de' : 'sw',
    targetLang: _learning,
    aiProvider: 'probe',
    isFavourite: true,
    createdAt: DateTime.utc(2026, 11, 8),
  );
  final card = cardsFor([entry],
          learningLanguage: _learning, confidentLanguage: _confident)
      .firstWhere((c) =>
          c.direction == (produce ? CardDirection.produce : CardDirection.recall));
  // The fixture is wrong if the card does not ask what the row means.
  assert(card.prompt == r[2] && card.expected == r[3], 'fixture row ${r[0]}');
  return card;
}
