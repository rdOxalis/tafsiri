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
                {'text': 'LANG:en\nHabari'}
              ]
            }),
            200,
          ));

      final result = await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
      );

      expect(result, 'LANG:en\nHabari');
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
                {'text': 'LANG:en\nHabari'}
              ]
            }),
            200,
          ));

      await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
      );

      final captured = verify(mockClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      )).captured.first as Map<String, String>;

      expect(captured['x-api-key'], apiKey);
      expect(captured['anthropic-version'], isNotNull);
    });

    test('names the model without a date suffix', () async {
      // A dated snapshot pins one version and is eventually retired, which
      // would break translation on every phone that has not updated. The alias
      // follows the current version instead (ADR-067). Pinned as a test
      // because the dated form is what a model recalls from training and
      // writes back in without noticing.
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
      );

      final body = verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.first as String;
      final model = (jsonDecode(body) as Map<String, dynamic>)['model'] as String;

      expect(model, 'claude-haiku-4-5');
      expect(model, isNot(matches(RegExp(r'-\d{8}$'))),
          reason: 'a date-suffixed snapshot gets retired; the alias does not');
    });
  });
}
