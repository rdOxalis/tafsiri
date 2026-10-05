import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/ai_models.dart';
import 'package:tafsiri/core/constants.dart';

/// ADR-073 — the catalogue a user picks from, and ADR-067's rule about how a
/// model may be named, which moved here when the service constants went away.
void main() {
  group('the catalogue', () {
    test('covers every provider the app offers', () {
      for (final provider in [kProviderClaude, kProviderOpenAI, kProviderMistral]) {
        expect(modelsFor(provider), isNotEmpty, reason: provider);
      }
    });

    test('names models by alias, never by dated snapshot', () {
      // A dated snapshot is retired eventually, and it is retired in the
      // field — on phones that have not been updated (ADR-067). The dated
      // form is also exactly what a language model recalls from training and
      // writes back in without noticing, which is why this is a test.
      for (final models in kModelsByProvider.values) {
        for (final model in models) {
          expect(model.id, isNot(matches(RegExp(r'-\d{8}$'))),
              reason: '${model.id} carries a date');
        }
      }
    });

    test('every provider offers exactly one strongest model', () {
      for (final entry in kModelsByProvider.entries) {
        final best = entry.value.where((m) => m.tier == ModelTier.best);
        expect(best, hasLength(1), reason: entry.key);
      }
    });

    test('ids are unique across the catalogue', () {
      final ids = [for (final l in kModelsByProvider.values) ...l.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('defaults', () {
    test('Claude and OpenAI default to their strongest', () {
      // Measured: the cheaper Claude drops a plural that is marked only on the
      // verb, three times in four (ADR-072). A default that does that is the
      // defect, so correctness wins over cost here.
      for (final provider in [kProviderClaude, kProviderOpenAI]) {
        final chosen = modelsFor(provider)
            .firstWhere((m) => m.id == defaultModelFor(provider));
        expect(chosen.tier, ModelTier.best, reason: provider);
      }
    });

    test('Mistral defaults to the one its free tier can reach', () {
      // The README sends newcomers to Mistral's free tier; a paid default
      // would meet them with an error on their first translation.
      final chosen = modelsFor(kProviderMistral)
          .firstWhere((m) => m.id == defaultModelFor(kProviderMistral));
      expect(chosen.tier, ModelTier.free);
      expect(chosen.id, 'mistral-small-latest');
    });

    test('every default is in its provider\'s own list', () {
      for (final provider in kModelsByProvider.keys) {
        expect(modelsFor(provider).map((m) => m.id),
            contains(defaultModelFor(provider)));
      }
    });
  });

  group('resolveModel', () {
    test('keeps a valid choice', () {
      expect(resolveModel(kProviderClaude, 'claude-haiku-4-5'),
          'claude-haiku-4-5');
    });

    test('falls back when the stored model is gone or unset', () {
      // A model withdrawn from the catalogue, or a preference written by a
      // newer version of the app, must not be sent to an API that rejects it.
      for (final stored in ['', 'claude-haiku-3', 'gpt-4o-mini']) {
        expect(resolveModel(kProviderClaude, stored),
            defaultModelFor(kProviderClaude), reason: stored);
      }
    });

    test('does not take a model that belongs to another provider', () {
      expect(resolveModel(kProviderClaude, 'mistral-medium-latest'),
          defaultModelFor(kProviderClaude));
    });

    test('an unknown provider still yields something sendable', () {
      expect(resolveModel('nonesuch', 'whatever'), isNotEmpty);
    });
  });
}
