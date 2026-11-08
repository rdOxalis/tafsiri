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
