import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'ai_service.dart';

/// The model alias, deliberately without a date suffix (ADR-067).
///
/// A dated snapshot pins one exact version and is eventually retired; the
/// alias follows the current version of the same model. For an app that sits
/// on people's phones for months between updates, that is the safer of the
/// two: a retired snapshot breaks translation in the field for everyone who
/// has not updated, and no release we make afterwards reaches them any faster.
/// A silently updated model translates a little differently, which is a far
/// cheaper failure. Mistral and OpenAI are already on aliases here.

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
    required String model,
    bool correctionMode = false,
    bool explanations = false,
  }) async {
    debugPrint('[ClaudeService] translate — key=${maskApiKey(apiKey)}, '
        'correction=$correctionMode');

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        // Room for thinking as well as the answer: current Claude models think
        // adaptively when the request does not say otherwise, and thinking
        // tokens count against this limit. Billed by use, not by the cap.
        'max_tokens': 16000,
        'system': AiService.systemPromptFor(
          targetLanguage: targetLanguage,
          altLanguage: altLanguage,
          correctionMode: correctionMode,
          explanations: explanations,
        ),
        'messages': [
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

    return extractText(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// The answer is the text blocks of the response, joined.
  ///
  /// Not simply the first block: current models think adaptively by default,
  /// and the response then opens with a `thinking` block that carries no
  /// `text` (its content is omitted unless asked for). Reading `first['text']`
  /// failed with "type 'Null' is not a subtype of type 'String'" whenever the
  /// model chose to think.
  @visibleForTesting
  static String extractText(Map<String, dynamic> json) {
    final stopReason = json['stop_reason'] as String?;
    if (stopReason == 'refusal') {
      throw AiApiException(200, 'refusal: ${jsonEncode(json['stop_details'])}');
    }
    final text = ((json['content'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String? ?? '')
        .join();
    if (text.trim().isEmpty) {
      throw AiApiException(200, 'no text in response (stop_reason: $stopReason)');
    }
    return text;
  }
}
