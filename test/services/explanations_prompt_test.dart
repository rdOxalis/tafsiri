import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/claude_service.dart';
import 'package:tafsiri/core/services/mistral_service.dart';
import 'package:tafsiri/core/services/openai_service.dart';
import 'mock_http_client.mocks.dart';

/// ADR-060 — the explanations switch adds a section to whichever prompt is in
/// force, and must be absent from every request when the switch is off.
void main() {
  const target = 'Swahili';
  const alt = 'English';

  group('AiService.systemPromptFor with explanations', () {
    test('adds nothing at all when the switch is off', () {
      expect(
        AiService.systemPromptFor(
          targetLanguage: target,
          altLanguage: alt,
          correctionMode: false,
          explanations: false,
        ),
        AiService.buildSystemPrompt(target, alt),
      );
      expect(
        AiService.systemPromptFor(
          targetLanguage: target,
          altLanguage: alt,
          correctionMode: true,
          explanations: false,
        ),
        AiService.buildCorrectionSystemPrompt(target, alt),
      );
    });

    test('appends the section to the plain translation prompt', () {
      final prompt = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: alt,
        correctionMode: false,
        explanations: true,
      );

      // The base prompt survives verbatim — the section is added, not woven in.
      expect(prompt, startsWith(AiService.buildSystemPrompt(target, alt)));
      expect(prompt, contains('EXPLAIN:'));
    });

    test('appends the section to the correction prompt too', () {
      final prompt = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: alt,
        correctionMode: true,
        explanations: true,
      );

      expect(
        prompt,
        startsWith(AiService.buildCorrectionSystemPrompt(target, alt)),
      );
      // …but there the NOTES already do the explaining.
      expect(prompt, contains('NEVER in mode "correct"'));
    });

    test('the section says what a learner needs and what to leave out', () {
      final section = AiService.buildExplanationsSection(target, alt);

      // The rule that covers both directions: it is the learning-language
      // words that get explained, whichever side of the exchange they are on.
      expect(section, contains('whichever side they are on'));
      // Written in the language the learner is confident in.
      expect(section, contains('written in $alt'));
      // Spelled out rather than dictionary abbreviations — the whole point of
      // not copying TUKI's kt / nm / tde / tdw notation.
      expect(section, contains('never abbreviations'));
      // The noun class is still demanded; only the app does not supply it.
      expect(section, contains('noun, class 9/10'));
      // A cap, so the section cannot bury the translation.
      expect(section, contains('At most 5 entries'));
      // It must be droppable when there is nothing worth saying.
      expect(section, contains('Omit the whole section'));
      // It has to override "never explain" from the base prompt.
      expect(section, contains('ONE EXCEPTION'));
    });

    // ADR-070 — ChatGPT wrote the whole section in English with Swahili and
    // German configured, and Claude wrote the grammatical terms in English
    // while getting the meanings right. Two causes, both of them ADR-063's:
    // the leading language rule was missing from this path, and every example
    // in the section was an English literal offered up to be copied.
    test('the translation prompt gains the language rule with the section', () {
      final withSection = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: 'German',
        correctionMode: false,
        explanations: true,
      );
      final without = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: 'German',
        correctionMode: false,
        explanations: false,
      );

      expect(withSection, contains(AiService.outputLanguageRule('German')));
      // …and only because the section is there. With the switch off the
      // prompt stays byte-for-byte what it always was (ADR-060).
      expect(without, isNot(contains('THE LANGUAGE YOU WRITE IN')));
    });

    test('the correction prompt does not get a second copy of that rule', () {
      final prompt = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: 'German',
        correctionMode: true,
        explanations: true,
      );

      expect('THE LANGUAGE YOU WRITE IN'.allMatches(prompt).length, 1);
    });

    test('the examples are labelled as shapes, not as wording to copy', () {
      final section = AiService.buildExplanationsSection(target, 'German');

      // The specific failure: "noun"/"verb"/"adjective" came back verbatim.
      expect(section, contains('not these English ones'));
      expect(
        section,
        contains('Every example above is written in English'),
      );
      expect(section, contains('They show you the shape, never the wording'));
    });
  });

  group('providers send the flag', () {
    late MockClient client;

    setUp(() => client = MockClient());

    void answerWith(String body) {
      when(client.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(body, 200));
    }

    String sentSystemPrompt() {
      final captured = verify(client.post(any,
              headers: anyNamed('headers'), body: captureAnyNamed('body')))
          .captured
          .single as String;
      final json = jsonDecode(captured) as Map<String, dynamic>;
      if (json.containsKey('system')) return json['system'] as String;
      final messages = json['messages'] as List;
      return (messages.first as Map)['content'] as String;
    }

    test('Claude', () async {
      answerWith(jsonEncode({
        'content': [
          {'text': 'LANG:en\nHabari'}
        ]
      }));
      await ClaudeService(client: client).translate(
        text: 'Hello',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
        explanations: true,
      );
      expect(sentSystemPrompt(), contains('EXPLAIN:'));
    });

    test('Mistral', () async {
      answerWith(jsonEncode({
        'choices': [
          {
            'message': {'content': 'LANG:en\nHabari'}
          }
        ]
      }));
      await MistralService(client: client).translate(
        text: 'Hello',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
        explanations: true,
      );
      expect(sentSystemPrompt(), contains('EXPLAIN:'));
    });

    test('OpenAI', () async {
      answerWith(jsonEncode({
        'choices': [
          {
            'message': {'content': 'LANG:en\nHabari'}
          }
        ]
      }));
      await OpenAiService(client: client).translate(
        text: 'Hello',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
        explanations: true,
      );
      expect(sentSystemPrompt(), contains('EXPLAIN:'));
    });

    test('and leave it out when the switch is off', () async {
      answerWith(jsonEncode({
        'content': [
          {'text': 'LANG:en\nHabari'}
        ]
      }));
      await ClaudeService(client: client).translate(
        text: 'Hello',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
      );
      expect(sentSystemPrompt(), isNot(contains('EXPLAIN:')));
    });
  });
}
