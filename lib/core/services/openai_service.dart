import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'ai_service.dart';

const _model = 'gpt-4o-mini';
const _endpoint = 'https://api.openai.com/v1/chat/completions';

class OpenAiService implements AiService {
  OpenAiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    required String altLanguage,
    required String apiKey,
  }) async {
    debugPrint('[OpenAiService] translate — key=${maskApiKey(apiKey)}');

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content':
                AiService.buildPrompt(text, targetLanguage, altLanguage),
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AiApiException(response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['choices'][0]['message']['content'] as String;
  }
}
