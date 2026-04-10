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
      );

      expect(result, 'LANG:en\nHabari');
    });

    test('throws AiApiException on 401', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('unauthorized', 401));

      expect(
        () => service.translate(
            text: input, targetLanguage: target, altLanguage: alt, apiKey: apiKey),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws AiApiException on 500', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('server error', 500));

      expect(
        () => service.translate(
            text: input, targetLanguage: target, altLanguage: alt, apiKey: apiKey),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
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
