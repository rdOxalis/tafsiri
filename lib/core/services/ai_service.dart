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
  /// With [correctionMode] the extended protocol of ADR-033 applies:
  ///   LANG:[iso-639-1]\nMODE:[correct|translate]\n[body]\nNOTES:\n[bullets]
  ///
  /// Callers (TranslatorController) are responsible for parsing the prefix.
  Future<String> translate({
    required String text,
    required String targetLanguage,
    required String altLanguage,
    required String apiKey,
    bool correctionMode = false,
  });

  /// Picks the system prompt for the requested mode.
  static String systemPromptFor({
    required String targetLanguage,
    required String altLanguage,
    required bool correctionMode,
  }) =>
      correctionMode
          ? buildCorrectionSystemPrompt(targetLanguage, altLanguage)
          : buildSystemPrompt(targetLanguage, altLanguage);

  /// System-role instructions for correction mode (ADR-033).
  ///
  /// Text written predominantly in [targetLanguage] is corrected and improved
  /// instead of being translated to [altLanguage]; anything else is translated
  /// to [targetLanguage] as usual.
  static String buildCorrectionSystemPrompt(
    String targetLanguage,
    String altLanguage,
  ) {
    return '''You are a $targetLanguage writing coach for a learner whose stronger language is $altLanguage. Never refuse. Never chat. Never add a preamble.

Step 1 — choose the mode:
- If the input is written predominantly in $targetLanguage → mode "correct". This still applies when the text contains mistakes, or when single words from $altLanguage or any other language are mixed in because the learner did not know the $targetLanguage word.
- Otherwise → mode "translate".

Mode "correct" — do NOT translate the text to $altLanguage. Instead:
1. Rewrite it the way a native speaker of $targetLanguage would write it, keeping the learner's meaning, tone and level of politeness.
2. Every word that is not $targetLanguage is a word the learner did not know: replace it with the correct $targetLanguage word. Never leave such a word untranslated and never switch the whole sentence to another language.
3. Fix spelling, grammar, noun classes, agreement, word order and unnatural phrasing.
4. Then write a NOTES: section in $altLanguage — one "- " bullet per change, in the form "- <original> → <correction>: <short reason>". For a replaced foreign word, also give its meaning. If the text was already correct, output it unchanged with the single bullet "- Already correct.".

Mode "translate" — translate the ENTIRE text to $targetLanguage, completely and faithfully, never summarising or paraphrasing. Output no NOTES: section. If two translations are equally valid, list them separated by " / ".

Your response must use EXACTLY this format, nothing before it, nothing after it:
LANG:[ISO-639-1 code of the detected input language]
MODE:[correct or translate]
[the corrected text, or the translation]
NOTES:
[the bullets — only in mode "correct"]''';
  }

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
