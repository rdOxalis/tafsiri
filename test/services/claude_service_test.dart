import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/claude_service.dart';
import 'mock_http_client.mocks.dart';

void main() {
  late MockClient mockClient;
  late ClaudeService service;

  setUp(() {
    mockClient = MockClient();
    service = ClaudeService(client: mockClient);
  });

  group('ClaudeService', () {
    const apiKey = 'sk-test-key';
    const model = 'claude-haiku-4-5';
    const target = 'Swahili';
    const alt = 'English';
    const input = 'Hello';

    test('returns translated text on 200', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'LANG:en\nHabari'}
              ]
            }),
            200,
          ));

      final result = await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
        model: model,
      );

      expect(result, 'LANG:en\nHabari');
    });

    test('skips a leading thinking block', () async {
      // What Sonnet 5.5 returns when it decides to think: the thinking block
      // comes first and has no text field.
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'type': 'thinking', 'thinking': '', 'signature': 'sig'},
                {'type': 'text', 'text': 'LANG:de\nLila jagte '},
                {'type': 'text', 'text': 'den Gecko.'},
              ],
              'stop_reason': 'end_turn',
            }),
            200,
          ));

      final result = await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
        model: 'claude-sonnet-5-5',
      );

      expect(result, 'LANG:de\nLila jagte den Gecko.');
    });

    test('throws AiApiException on a refusal', () {
      expect(
        () => ClaudeService.extractText({
          'content': <dynamic>[],
          'stop_reason': 'refusal',
          'stop_details': {'type': 'refusal', 'category': 'cyber'},
        }),
        throwsA(isA<AiApiException>()
            .having((e) => e.body, 'body', contains('refusal'))),
      );
    });

    test('throws AiApiException when only thinking came back', () {
      expect(
        () => ClaudeService.extractText({
          'content': [
            {'type': 'thinking', 'thinking': ''},
          ],
          'stop_reason': 'max_tokens',
        }),
        throwsA(isA<AiApiException>()
            .having((e) => e.body, 'body', contains('max_tokens'))),
      );
    });

    test('throws AiApiException on 401', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"error":"unauthorized"}', 401));

      expect(
        () => service.translate(
          text: input,
          targetLanguage: target,
          altLanguage: alt,
          apiKey: apiKey,
          model: model,
        ),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws AiApiException on 500', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('internal error', 500));

      expect(
        () => service.translate(
          text: input,
          targetLanguage: target,
          altLanguage: alt,
          apiKey: apiKey,
          model: model,
        ),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('sends correct headers', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'LANG:en\nHabari'}
              ]
            }),
            200,
          ));

      await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
        model: model,
      );

      final captured = verify(mockClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      )).captured.first as Map<String, String>;

      expect(captured['x-api-key'], apiKey);
      expect(captured['anthropic-version'], isNotNull);
    });

    test('sends the model it was given, unaltered', () async {
      // The service no longer chooses: the model comes from the user's
      // settings (ADR-073), so what a measurement ran against and what ships
      // cannot drift apart. Which identifiers may be chosen, and that none of
      // them carries a date suffix (ADR-067), is pinned in
      // test/core/ai_models_test.dart instead.
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'LANG:en\nHabari'},
              ],
            }),
            200,
          ));

      await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
        model: 'claude-sonnet-5-5',
      );

      final body = verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.first as String;
      final sent = (jsonDecode(body) as Map<String, dynamic>)['model'] as String;

      expect(sent, 'claude-sonnet-5-5');
    });
  });
}
