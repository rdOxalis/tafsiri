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

  group('sttCodeForLanguageName', () {
    test('maps the free-text names the settings hold', () {
      expect(sttCodeForLanguageName('Swahili'), 'sw');
      expect(sttCodeForLanguageName(' kiswahili '), 'sw');
      expect(sttCodeForLanguageName('Deutsch'), 'de');
      expect(sttCodeForLanguageName('English'), 'en');
      expect(sttCodeForLanguageName('Bulgarian'), 'bg');
    });

    test('is null for a name it does not know', () {
      expect(sttCodeForLanguageName('Klingon'), isNull);
      expect(sttCodeForLanguageName(''), isNull);
    });
  });

  group('initialSttLanguage', () {
    test('the language chosen in the window wins', () {
      expect(
        initialSttLanguage(
          chosenInWindow: 'de',
          setting: 'sw',
          lastSourceLang: 'en',
          learningLanguage: 'Swahili',
        ),
        'de',
      );
    });

    test('then a fixed language from the settings', () {
      expect(
        initialSttLanguage(
            setting: 'sw', lastSourceLang: 'en', learningLanguage: 'Swahili'),
        'sw',
      );
    });

    test('then the language of the last translation', () {
      expect(
        initialSttLanguage(
            setting: '', lastSourceLang: 'de', learningLanguage: 'Swahili'),
        'de',
      );
    });

    test('on first use, the learning language', () {
      expect(
        initialSttLanguage(setting: '', learningLanguage: 'Swahili'),
        'sw',
      );
    });
  });
}
