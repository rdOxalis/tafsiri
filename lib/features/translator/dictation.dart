import '../../core/constants.dart';
import '../../core/languages.dart';

/// Text spoken across several recogniser sessions in one dictation window
/// (ADR-081).
///
/// Android ends a recognition session on its own after a pause, and
/// `speech_to_text` can only shorten that pause, never lengthen it. So the
/// user speaks in parts, starting each with the microphone button. Every
/// session starts from nothing; what earlier ones heard is kept here and the
/// current session's words are added to it.
class DictationBuffer {
  String _committed = '';
  String _current = '';

  /// Everything heard so far, the current session's partial words included.
  String get text => joinSpeech(_committed, _current);

  /// Records what the current session has heard. A final result closes the
  /// session's part, so the next session's words are added after it.
  void update(String words, {required bool isFinal}) {
    if (isFinal) {
      _committed = joinSpeech(_committed, words);
      _current = '';
    } else {
      _current = words;
    }
  }

  /// Called when a new session starts. If the previous one ended without a
  /// final result (an error after a pause, for instance), its partial words
  /// are kept rather than overwritten by the new session's.
  void startSession() {
    _committed = joinSpeech(_committed, _current);
    _current = '';
  }

  void reset() {
    _committed = '';
    _current = '';
  }
}

/// Joins two pieces of recognised speech with a single space.
String joinSpeech(String a, String b) {
  final left = a.trim();
  final right = b.trim();
  if (left.isEmpty) return right;
  if (right.isEmpty) return left;
  return '$left $right';
}

/// The speech-recognition language for a language name from the settings,
/// or `null` when the name is unknown or has no recognition locale.
String? sttCodeForLanguageName(String name) {
  final code = isoCodeFor(name);
  return kSttLocaleMap.containsKey(code) ? code : null;
}

/// Which language the dictation window starts in (ADR-080).
///
/// The choice made in the window wins for the rest of the session; then a
/// fixed language from the settings; then the language of the last
/// translation, the old "Auto"; and on first use the learning language,
/// since practising it is what the app is for.
String? initialSttLanguage({
  String? chosenInWindow,
  required String setting,
  String? lastSourceLang,
  required String learningLanguage,
}) {
  if (chosenInWindow != null) return chosenInWindow;
  if (setting.isNotEmpty) return setting;
  if (kSttLocaleMap.containsKey(lastSourceLang)) return lastSourceLang;
  return sttCodeForLanguageName(learningLanguage);
}
