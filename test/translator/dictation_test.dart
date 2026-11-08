import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/features/translator/dictation.dart';

void main() {
  group('DictationBuffer', () {
    test('collects the words of several sessions in order', () {
      final buffer = DictationBuffer();
      // First session: partials, then the final result after a pause.
      buffer.update('Lila', isFinal: false);
      buffer.update('Lila amemfukuza', isFinal: false);
      buffer.update('Lila amemfukuza', isFinal: true);
      // Second session starts from nothing.
      buffer.update('mjusi', isFinal: false);

      expect(buffer.text, 'Lila amemfukuza mjusi');

      buffer.update('mjusi ukutani', isFinal: true);
      expect(buffer.text, 'Lila amemfukuza mjusi ukutani');
    });

    test('keeps the partial words of the session still running', () {
      // Tapping stop mid-sentence must not lose the last words.
      final buffer = DictationBuffer()
        ..update('Nimeeka', isFinal: true)
        ..update('imekubali', isFinal: false);

      expect(buffer.text, 'Nimeeka imekubali');
    });

    test('a silent session adds nothing', () {
      final buffer = DictationBuffer()
        ..update('siku njema', isFinal: true)
        ..update('', isFinal: true);

      expect(buffer.text, 'siku njema');
    });

    test('a session that ended without a final result keeps its words', () {
      // Pause → the recogniser reports an error instead of a final result.
      final buffer = DictationBuffer()
        ..startSession()
        ..update('Lila amemfukuza', isFinal: false)
        ..startSession()
        ..update('mjusi', isFinal: false);

      expect(buffer.text, 'Lila amemfukuza mjusi');
    });

    test('reset starts over', () {
      final buffer = DictationBuffer()..update('paka', isFinal: true);
      buffer.reset();
      expect(buffer.text, '');
    });
  });

  group('RestartGuard', () {
    test('restarts after ordinary pauses indefinitely', () {
      final guard = RestartGuard();
      for (var i = 0; i < 20; i++) {
        expect(guard.allowRestartAfter(const Duration(seconds: 6)), isTrue);
      }
    });

    test('gives up when sessions keep ending at once', () {
      final guard = RestartGuard();
      const instant = Duration(milliseconds: 100);
      expect(guard.allowRestartAfter(instant), isTrue);
      expect(guard.allowRestartAfter(instant), isTrue);
      expect(guard.allowRestartAfter(instant), isFalse);
    });

    test('a normal session in between clears the count', () {
      final guard = RestartGuard();
      const instant = Duration(milliseconds: 100);
      guard.allowRestartAfter(instant);
      guard.allowRestartAfter(instant);
      guard.allowRestartAfter(const Duration(seconds: 5));
      expect(guard.allowRestartAfter(instant), isTrue);
    });
  });

  group('isFatalSttError', () {
    test('a pause does not end the mode', () {
      expect(isFatalSttError('error_speech_timeout'), isFalse);
      expect(isFatalSttError('error_no_match'), isFalse);
      expect(isFatalSttError('error_busy'), isFalse);
      expect(isFatalSttError('error_client'), isFalse);
    });

    test('what a restart cannot fix does', () {
      expect(isFatalSttError('error_permission'), isTrue);
      expect(isFatalSttError('error_language_not_supported'), isTrue);
    });
  });
}
