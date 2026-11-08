import '../../core/constants.dart';
import '../../core/services/ocr/tesseract_ocr_service.dart'
    show kTesseractLanguageCodes;

/// Text spoken across several recogniser sessions, for the mode in which the
/// microphone stays on until the user taps it again (ADR-079).
///
/// Android ends a recognition session on its own after a pause, and
/// `speech_to_text` can only shorten that pause, never lengthen it. Keeping
/// the microphone open therefore means starting a new session after each
/// pause. Every session starts from nothing, so what earlier sessions heard
/// is kept here and the current session's words are added to it.
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

/// Whether a recogniser error ends keep-listening mode.
///
/// `speech_to_text` marks every Android error as permanent, including the
/// silence timeout and no-match that a pause produces — exactly the moments
/// this mode must carry on through. So the decision is made here, by error:
/// only what a restart cannot fix ends the mode.
bool isFatalSttError(String errorMsg) => const {
      'error_permission',
      'error_audio_error',
      'error_language_not_supported',
      'error_language_unavailable',
    }.contains(errorMsg);

/// Joins two pieces of recognised speech with a single space.
String joinSpeech(String a, String b) {
  final left = a.trim();
  final right = b.trim();
  if (left.isEmpty) return right;
  if (right.isEmpty) return left;
  return '$left $right';
}

/// Stops restarting when the recogniser keeps ending almost at once.
///
/// A session that ends after a long silence is normal and is restarted. One
/// that ends within moments, several times in a row, means the recogniser
/// cannot work (busy, no network for an online recogniser); restarting it
/// forever would only make the phone beep in a loop.
class RestartGuard {
  RestartGuard({
    this.quickEnd = const Duration(seconds: 1),
    this.maxQuickEnds = 3,
  });

  final Duration quickEnd;
  final int maxQuickEnds;
  int _quickEnds = 0;

  /// Whether a session that lasted [duration] may be followed by another.
  bool allowRestartAfter(Duration duration) {
    _quickEnds = duration < quickEnd ? _quickEnds + 1 : 0;
    return _quickEnds < maxQuickEnds;
  }

  void reset() => _quickEnds = 0;
}

/// ISO 639-1 code for each language Tesseract knows, so the free-text
/// language names from the settings ("Swahili", "Deutsch") can be turned into
/// a recognition language through the same table OCR already uses.
const _iso1ByTesseractCode = <String, String>{
  'swa': 'sw', 'eng': 'en', 'deu': 'de', 'fra': 'fr', 'nld': 'nl',
  'spa': 'es', 'dan': 'da', 'nor': 'nb', 'swe': 'sv', 'pol': 'pl',
  'ita': 'it', 'por': 'pt', 'tur': 'tr', 'bul': 'bg', 'rus': 'ru',
  'ell': 'el', 'ara': 'ar',
};

/// The speech-recognition language for a language name from the settings,
/// or `null` when the name is unknown or has no recognition locale.
String? sttCodeForLanguageName(String name) {
  final tesseract = kTesseractLanguageCodes[name.trim().toLowerCase()];
  final code = _iso1ByTesseractCode[tesseract];
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
