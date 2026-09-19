import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'ai_service.dart';

/// ADR-071. Named by alias, never by dated snapshot — the lesson of ADR-067.
const _model = 'gpt-5.6-luna';
const _endpoint = 'https://api.openai.com/v1/chat/completions';

/// This model reasons before it answers, and charges for the thinking.
/// Measured on the explanations prompt: "none" produced the same answer as
/// "low" for a third of the output tokens, because the prompt already says
/// what a good bullet looks like (ADR-071). Translation is not a task that
/// wants deliberation.
const _reasoningEffort = 'none';

class OpenAiService implements AiService {
  OpenAiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    required String altLanguage,
    required String apiKey,
    bool correctionMode = false,
    bool explanations = false,
  }) async {
    debugPrint('[OpenAiService] translate — key=${maskApiKey(apiKey)}, '
        'correction=$correctionMode');

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        // Not 'max_tokens' — every GPT-5 model rejects that name outright.
        // gpt-4o-mini accepted both, so this is the safe one either way.
        'max_completion_tokens': 4096,
        'reasoning_effort': _reasoningEffort,
        'messages': [
          {
            'role': 'system',
            'content': AiService.systemPromptFor(
              targetLanguage: targetLanguage,
              altLanguage: altLanguage,
              correctionMode: correctionMode,
              explanations: explanations,
            ),
          },
          {
            'role': 'user',
            'content': AiService.buildUserMessage(text),
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
