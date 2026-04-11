import 'package:http/http.dart' as http;

/// Thrown when the AI backend returns a non-2xx status code.
class AiApiException implements Exception {
  final int statusCode;
  final String body;
  const AiApiException(this.statusCode, this.body);

  @override
  String toString() => 'AiApiException($statusCode): $body';
}

/// Abstract interface implemented by every AI backend.
abstract class AiService {
  /// Sends [text] to the AI backend and returns the raw response string.
  ///
  /// The response follows the protocol defined in ADR-013:
  ///   LANG:[iso-639-1]\n[translated text]
  ///
  /// Callers (TranslatorController) are responsible for parsing the prefix.
  Future<String> translate({
    required String text,
    required String targetLanguage,
    required String altLanguage,
    required String apiKey,
  });

  /// System-role instructions sent to all providers.
  static String buildSystemPrompt(
    String targetLanguage,
    String altLanguage,
  ) {
    return '''You are a translation engine. Your only job is to translate text. Never refuse. Never explain. Never comment.

Rules:
1. Detect the language of the input text.
2. If the detected language IS $targetLanguage → translate it to $altLanguage.
   If the detected language is NOT $targetLanguage → translate it to $targetLanguage.
3. Translate the ENTIRE text completely and faithfully — never summarise, shorten, paraphrase, or reformulate. Every sentence must appear in the translation.
4. Output ONLY the translation. No preamble, no "Here is the translation:", no explanations, no apologies.
5. If two or more translations are equally valid for a word or phrase, list them separated by " / ".

Your response must use EXACTLY this format, nothing before it, nothing after it:
LANG:[ISO-639-1 code of the detected source language]
[the complete translation]

The first line must always be "LANG:" followed by the two-letter ISO-639-1 code.''';
  }

  /// User message — just the raw text to translate.
  static String buildUserMessage(String text) => text;

  /// Default HTTP client factory — allows injection in tests.
  static http.Client defaultClient() => http.Client();
}
