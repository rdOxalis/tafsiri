import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/openai_service.dart';
import 'mock_http_client.mocks.dart';

void main() {
  late MockClient mockClient;
  late OpenAiService service;

  setUp(() {
    mockClient = MockClient();
    service = OpenAiService(client: mockClient);
  });

  group('OpenAiService', () {
    const apiKey = 'sk-test-key';
    const model = 'gpt-5.6-luna';
    const target = 'Swahili';
    const alt = 'English';
    const input = 'Hello';

    http.Response successResponse(String text) => http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': text}
              }
            ]
          }),
          200,
        );

    test('returns translated text on 200', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => successResponse('LANG:en\nHabari'));

      final result = await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
        model: model,
      );

      expect(result, 'LANG:en\nHabari');
    });

    test('throws AiApiException on 401', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('unauthorized', 401));

      expect(
        () => service.translate(
            text: input, targetLanguage: target, altLanguage: alt, apiKey: apiKey, model: model),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws AiApiException on 500', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('server error', 500));

      expect(
        () => service.translate(
            text: input, targetLanguage: target, altLanguage: alt, apiKey: apiKey, model: model),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    // ADR-071. The model swap is two changes, not one: every GPT-5 model
    // rejects 'max_tokens' outright, so shipping the new alias with the old
    // parameter name would have taken ChatGPT down for everyone.
    test('names the model by alias and sends the parameters it accepts',
        () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => successResponse('LANG:en\nHabari'));

      await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
        model: model,
      );

      final body = jsonDecode(verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.first as String) as Map<String, dynamic>;

      expect(body['model'], 'gpt-5.6-luna');
      // No dated snapshot: one gets retired and the app stops working on
      // every device that has not been updated (ADR-067).
      expect(RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(body['model'] as String),
          isFalse);
      expect(body['max_completion_tokens'], 4096);
      expect(body.containsKey('max_tokens'), isFalse);
      // Reasoning costs output tokens; the prompt does that work instead.
      expect(body['reasoning_effort'], 'none');
    });

    test('sends Bearer token in Authorization header', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => successResponse('LANG:en\nHabari'));

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

      expect(captured['Authorization'], 'Bearer $apiKey');
    });
  });
}
