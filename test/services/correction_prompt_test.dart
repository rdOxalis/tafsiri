import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/claude_service.dart';
import 'package:tafsiri/core/services/mistral_service.dart';
import 'package:tafsiri/core/services/openai_service.dart';
import 'mock_http_client.mocks.dart';

/// ADR-033 — correction mode must reach the provider as a different system
/// prompt, and must not leak into the default translation path.
void main() {
  const target = 'Swahili';
  const alt = 'English';

  group('the language of everything that is not the translation (ADR-063)', () {
    test('the rule leads the correction prompt and names English', () {
      // A learner with Swahili and German configured got English notes: the
      // instruction was real but buried, and English is what a model falls
      // back to.
      const german = 'Deutsch';
      final prompt = AiService.buildCorrectionSystemPrompt(target, german);

      expect(prompt, contains('THE LANGUAGE YOU WRITE IN'));
      expect(prompt, contains('must be written in $german'));
      expect(prompt, contains('Not in English, unless $german is English'));
      // The prompt is itself in English, which is exactly the confusion.
      expect(prompt, contains('says nothing about the language of your answer'));
    });

    test('the already-correct bullet is no longer an English literal', () {
      final prompt = AiService.buildCorrectionSystemPrompt(target, 'Deutsch');

      // It used to prescribe the exact string "- Already correct.", which is
      // English whatever the learner configured.
      expect(prompt, isNot(contains('"- Already correct."')));
      expect(prompt, contains('do not copy these English words'));
    });

    test('the rule follows the configured language, whatever it is', () {
      for (final alt in ['Deutsch', 'Kiswahili', 'français']) {
        final prompt = AiService.buildCorrectionSystemPrompt(target, alt);
        expect(prompt, contains('must be written in $alt'));
      }
    });

    test('an English speaker is not told to avoid English', () {
      final prompt = AiService.buildCorrectionSystemPrompt(target, 'English');
      expect(prompt, contains('Not in English, unless English is English'));
    });
  });

  group('AiService.systemPromptFor', () {
    test('translation prompt is unchanged when correction mode is off', () {
      expect(
        AiService.systemPromptFor(
          targetLanguage: target,
          altLanguage: alt,
          correctionMode: false,
        ),
        AiService.buildSystemPrompt(target, alt),
      );
    });

    test('correction prompt keeps primary-language text in that language', () {
      final prompt = AiService.systemPromptFor(
        targetLanguage: target,
        altLanguage: alt,
        correctionMode: true,
      );

      expect(prompt, AiService.buildCorrectionSystemPrompt(target, alt));
      expect(prompt, contains('do NOT translate the text to $alt'));
      // Mixed-in foreign words are words the learner did not know.
      expect(prompt, contains('did not know'));
      // Non-primary input is still translated to the primary language.
      expect(prompt, contains('translate the ENTIRE text to $target'));
      // Response protocol.
      expect(prompt, contains('LANG:'));
      expect(prompt, contains('MODE:'));
      expect(prompt, contains('NOTES:'));
    });
  });

  group('providers send the correction prompt', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
    });

    void stubChatCompletion() {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'LANG:sw\nMODE:correct\nNipe siagi.'}
                }
              ]
            }),
            200,
          ));
    }

    String capturedBody() => verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured.first as String;

    test('Mistral', () async {
      stubChatCompletion();
      await MistralService(client: mockClient).translate(
        text: 'Tafadhali nipe Butter.',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
        correctionMode: true,
      );

      final json = jsonDecode(capturedBody()) as Map<String, dynamic>;
      expect(
        json['messages'][0]['content'],
        AiService.buildCorrectionSystemPrompt(target, alt),
      );
    });

    test('OpenAI', () async {
      stubChatCompletion();
      await OpenAiService(client: mockClient).translate(
        text: 'Tafadhali nipe Butter.',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
        correctionMode: true,
      );

      final json = jsonDecode(capturedBody()) as Map<String, dynamic>;
      expect(
        json['messages'][0]['content'],
        AiService.buildCorrectionSystemPrompt(target, alt),
      );
    });

    test('Claude', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'text': 'LANG:sw\nMODE:correct\nNipe siagi.'}
              ]
            }),
            200,
          ));

      await ClaudeService(client: mockClient).translate(
        text: 'Tafadhali nipe Butter.',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
        correctionMode: true,
      );

      final json = jsonDecode(capturedBody()) as Map<String, dynamic>;
      expect(
        json['system'],
        AiService.buildCorrectionSystemPrompt(target, alt),
      );
    });

    test('defaults to the translation prompt', () async {
      stubChatCompletion();
      await MistralService(client: mockClient).translate(
        text: 'Hello',
        targetLanguage: target,
        altLanguage: alt,
        apiKey: 'sk-test',
      );

      final json = jsonDecode(capturedBody()) as Map<String, dynamic>;
      expect(
        json['messages'][0]['content'],
        AiService.buildSystemPrompt(target, alt),
      );
    });
  });
}
