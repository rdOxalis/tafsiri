import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/constants.dart';

/// The privacy policy the app links to, and the provider policies it links on
/// to in turn (ADR-068).
///
/// Links are the one thing in the app that can break without a single line
/// changing here — the far end moves and nothing tells us. Mistral's policy did
/// exactly that, sitting on a 404 until someone clicked it. These checks cannot
/// see the network, so they guard what they can: that the URL the app opens
/// still matches the file in the repository, and that the addresses known to
/// have died do not come back.
void main() {
  final policy = File('docs/privacy-policy.md');

  test('the linked policy is the file in this repository', () {
    expect(policy.existsSync(), isTrue,
        reason: 'kPrivacyPolicyUrl points at docs/privacy-policy.md');
    expect(kPrivacyPolicyUrl, endsWith('/docs/privacy-policy.md'));
    expect(kPrivacyPolicyUrl, startsWith(kSourceCodeUrl));
  });

  test('the policy names a live address for every provider', () {
    final text = policy.readAsStringSync();

    // Dead as of 2026-09-05; the policy moved to the legal. subdomain.
    expect(text, isNot(contains('https://mistral.ai/privacy-policy')),
        reason: 'that address returns 404');

    expect(text, contains('https://legal.mistral.ai/terms/privacy-policy'));
    expect(text, contains('https://www.anthropic.com/privacy'));
    expect(text, contains('https://openai.com/policies/privacy-policy'));
  });
}
