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

  /// Builds the shared prompt used by all providers.
  static String buildPrompt(
    String text,
    String targetLanguage,
    String altLanguage,
  ) {
    return '''You are a translation assistant.
Detect the language of the following text.
If it is already $targetLanguage, translate it to $altLanguage.
Otherwise translate it to $targetLanguage.
Respond with EXACTLY this format and nothing else:
LANG:[ISO-639-1 code of the detected source language]
[translated text]

Text: $text''';
  }

  /// Default HTTP client factory — allows injection in tests.
  static http.Client defaultClient() => http.Client();
}
