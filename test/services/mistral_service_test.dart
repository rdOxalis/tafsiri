import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/mistral_service.dart';
import 'mock_http_client.mocks.dart';

void main() {
  late MockClient mockClient;
  late MistralService service;

  setUp(() {
    mockClient = MockClient();
    service = MistralService(client: mockClient);
  });

  group('MistralService', () {
    const apiKey = 'mk-test-key';
    const target = 'Swahili';
    const alt = 'English';
    const input = 'Guten Tag';

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
          .thenAnswer((_) async => successResponse('LANG:de\nHabari ya asubuhi'));

      final result = await service.translate(
        text: input,
        targetLanguage: target,
        altLanguage: alt,
        apiKey: apiKey,
      );

      expect(result, 'LANG:de\nHabari ya asubuhi');
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

    test('throws AiApiException on 429 (rate limit)', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('rate limit exceeded', 429));

      expect(
        () => service.translate(
            text: input, targetLanguage: target, altLanguage: alt, apiKey: apiKey),
        throwsA(isA<AiApiException>().having((e) => e.statusCode, 'statusCode', 429)),
      );
    });

    test('sends Bearer token in Authorization header', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => successResponse('LANG:de\nHabari'));

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
