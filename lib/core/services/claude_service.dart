import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'ai_service.dart';

const _model = 'claude-haiku-4-5-20251001';
const _endpoint = 'https://api.anthropic.com/v1/messages';
const _apiVersion = '2023-06-01';

class ClaudeService implements AiService {
  ClaudeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    required String altLanguage,
    required String apiKey,
  }) async {
    debugPrint('[ClaudeService] translate — key=${maskApiKey(apiKey)}');

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
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
    return (json['content'] as List).first['text'] as String;
  }
}
