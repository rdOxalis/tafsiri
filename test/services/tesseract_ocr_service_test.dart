import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/ocr/ocr_service.dart';
import 'package:tafsiri/core/services/ocr/tesseract_ocr_service.dart';

/// Guards the Tesseract wiring (ADR-037) without needing Tesseract installed:
/// the TSV parsing, the confidence gate that stops garble from reaching the AI,
/// and the language selection driven by the user's settings.
void main() {
  const tsvHeader = 'level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\t'
      'left\ttop\twidth\theight\tconf\ttext';

  /// Builds a word row at the given position in the layout hierarchy.
  String word(
    String text,
    double conf, {
    int block = 1,
    int par = 1,
    int line = 1,
  }) =>
      '5\t1\t$block\t$par\t$line\t1\t0\t0\t10\t10\t$conf\t$text';

  group('parseTesseractTsv', () {
    test('joins words on a line and breaks between lines', () {
      final tsv = [
        tsvHeader,
        // Non-word rows (page, block, paragraph, line) carry conf -1 and must
        // influence neither the text nor the mean.
        '1\t1\t0\t0\t0\t0\t0\t0\t800\t600\t-1\t',
        '4\t1\t1\t1\t1\t0\t0\t0\t400\t50\t-1\t',
        word('Tafadhali', 96.0),
        word('nipe', 94.0),
        word('siagi', 90.0),
        word('Asante', 92.0, line: 2),
      ].join('\n');

      final page = parseTesseractTsv(tsv);

      expect(page.text, 'Tafadhali nipe siagi\nAsante');
      expect(page.meanConfidence, closeTo(93.0, 0.001));
    });

    test('starts a new line for a new paragraph or block', () {
      final tsv = [
        tsvHeader,
        word('eins', 90.0),
        word('zwei', 90.0, par: 2),
        word('drei', 90.0, block: 2),
      ].join('\n');

      expect(parseTesseractTsv(tsv).text, 'eins\nzwei\ndrei');
    });

    test('skips empty words and words Tesseract could not score', () {
      final tsv = [
        tsvHeader,
        word('Habari', 95.0),
        word('   ', 10.0),
        word('yako', -1.0),
      ].join('\n');

      final page = parseTesseractTsv(tsv);

      expect(page.text, 'Habari yako');
      // The blank word is dropped entirely; the unscored one keeps its text but
      // must not drag the mean down.
      expect(page.meanConfidence, closeTo(95.0, 0.001));
    });

    test('survives empty and malformed output', () {
      expect(parseTesseractTsv('').text, isEmpty);
      expect(parseTesseractTsv('').meanConfidence, 0);
      expect(parseTesseractTsv('not a tsv at all').text, isEmpty);
      expect(parseTesseractTsv(tsvHeader).text, isEmpty);
    });
  });

  group('parseOsdScript', () {
    test('reads the script out of OSD output', () {
      expect(
        parseOsdScript('Page number: 0\nOrientation in degrees: 0\n'
            'Script: Cyrillic\nScript confidence: 4.58\n'),
        'Cyrillic',
      );
    });

    test('returns null when OSD had nothing to say', () {
      expect(parseOsdScript('Too few characters. Skipping this page'), isNull);
      expect(parseOsdScript(''), isNull);
    });
  });

  group('scriptPackageSuffix', () {
    test('maps a script to its Debian package suffix', () {
      expect(scriptPackageSuffix('Cyrillic'), 'script-cyrl');
      expect(scriptPackageSuffix('Greek'), 'script-grek');
    });

    test('degrades to the lower-cased script for anything unmapped', () {
      expect(scriptPackageSuffix('Klingon'), 'script-klingon');
    });
  });

  group('selectLanguages', () {
    const service = TesseractOcrService();
    const installed = {'eng', 'deu', 'swa', 'fra'};

    test('maps both configured languages and passes them together', () {
      final selection =
          service.selectLanguages('Swahili', 'English', installed);
      expect(selection.argument, 'swa+eng');
      expect(selection.missing, isEmpty);
    });

    test('accepts native spellings and two-letter codes', () {
      expect(service.selectLanguages('Deutsch', 'en', installed).argument,
          'deu+eng');
      expect(service.selectLanguages('de', 'Français', installed).argument,
          'deu+fra');
    });

    test('understands the two newest UI languages', () {
      // Italian is Latin, Bulgarian is Cyrillic — the second is the reason the
      // missing-data path has to be actionable (ADR-037).
      expect(service.selectLanguages('Italian', 'English', {'eng', 'ita'})
          .argument, 'ita+eng');
      expect(service.selectLanguages('Български', 'English', {'eng', 'bul'})
          .argument, 'bul+eng');
    });

    test('does not repeat a language configured twice', () {
      expect(service.selectLanguages('German', 'de', installed).argument,
          'deu');
    });

    test('skips languages whose trained data is not installed', () {
      final selection = service.selectLanguages('Polish', 'German', installed);
      expect(selection.argument, 'deu');
      expect(selection.missing, ['pol']);
    });

    test('falls back to English when nothing configured is installed', () {
      final selection =
          service.selectLanguages('Bulgarian', 'Russian', installed);
      expect(selection.argument, 'eng');
      expect(selection.missing, ['bul', 'rus']);
    });

    test('gives up when even English is missing', () {
      expect(
        () => service.selectLanguages('Polish', 'Swedish', {'jpn'}),
        throwsA(isA<OcrUnavailableException>()),
      );
    });

    test('falls back for a language name it does not know', () {
      expect(service.selectLanguages('Klingon', 'Elvish', installed).argument,
          'eng');
    });
  });

  group('recogniseText', () {
    /// Fakes the three invocations the service makes: `--list-langs`, script
    /// detection (`--psm 0`) and the recognition runs themselves.
    ///
    /// [tsvByLanguage] is keyed by the `-l` argument, so a test can let the
    /// configured languages fail and a script retry succeed. [script] is what
    /// OSD reports; `null` stands for "too few characters".
    TesseractOcrService serviceReturning({
      required Set<String> langs,
      required Map<String, String> tsvByLanguage,
      String? script,
      int exitCode = 0,
    }) =>
        TesseractOcrService(
          runProcess: (executable, arguments) async {
            if (arguments.contains('--list-langs')) {
              return ProcessResult(
                0,
                0,
                'List of available languages (${langs.length}):\n'
                    '${langs.join('\n')}\n',
                '',
              );
            }
            if (arguments.contains('--psm')) {
              if (script == null) {
                return ProcessResult(0, 1, '', 'Too few characters.');
              }
              return ProcessResult(
                  0, 0, 'Orientation in degrees: 0\nScript: $script\n', '');
            }
            final requested = arguments[arguments.indexOf('-l') + 1];
            final tsv = tsvByLanguage[requested];
            // Tesseract exits non-zero when the trained data is not there.
            if (tsv == null) {
              return ProcessResult(
                  0, 1, '', 'Error opening data file for $requested');
            }
            return ProcessResult(0, exitCode, tsv, exitCode == 0 ? '' : 'boom');
          },
        );

    String tsvOf(List<String> rows) => [tsvHeader, ...rows].join('\n');

    test('returns the recognised text', () async {
      final service = serviceReturning(
        langs: {'eng', 'swa'},
        tsvByLanguage: {
          'swa+eng': tsvOf([word('Habari', 95.0), word('yako', 93.0)]),
        },
      );

      expect(
        await service.recogniseText(
          '/tmp/photo.png',
          primaryLanguage: 'Swahili',
          altLanguage: 'English',
        ),
        'Habari yako',
      );
    });

    test('names the missing language pack when that is the likely cause',
        () async {
      // Bulgarian on a machine with only English trained data: Cyrillic comes
      // back as noise, and the fix is an apt install rather than a better
      // photo — so say so instead of blaming the image.
      final service = serviceReturning(
        langs: {'eng'},
        tsvByLanguage: {
          'eng': tsvOf([word('Noxkanyucta,', 39.0), word('Gavte', 41.0)]),
        },
      );

      expect(
        () => service.recogniseText(
          '/tmp/photo.png',
          primaryLanguage: 'Bulgarian',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrLanguageMissingException>()
            .having((e) => e.languageCodes, 'languageCodes', ['bul'])),
      );
    });

    test('blames the image when every configured language is installed',
        () async {
      // The gate itself: handed this, a language model would not fail — it
      // would invent fluent text that was never on the image.
      final service = serviceReturning(
        langs: {'eng', 'swa'},
        tsvByLanguage: {
          'swa+eng': tsvOf([word('Tafadhal1', 31.0), word('n|pe', 22.0)]),
        },
      );

      expect(
        () => service.recogniseText(
          '/tmp/photo.png',
          primaryLanguage: 'Swahili',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('reports an empty page as a failure, not as empty text', () async {
      final service =
          serviceReturning(langs: {'eng'}, tsvByLanguage: {'eng': tsvOf([])});

      expect(
        () => service.recogniseText(
          '/tmp/blank.png',
          primaryLanguage: 'Swahili',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('reports a non-zero exit as a failure', () async {
      final service = serviceReturning(
        langs: {'eng'},
        tsvByLanguage: {'eng': ''},
        exitCode: 1,
      );

      expect(
        () => service.recogniseText(
          '/tmp/photo.png',
          primaryLanguage: 'Swahili',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('recovers by script when the image is in one nobody configured',
        () async {
      // The case the settings cannot cover: primary and secondary are Latin,
      // and the user photographs Cyrillic — which is what a translation app is
      // for. The configured languages produce noise; the script does not come
      // from the settings but from the image.
      final service = serviceReturning(
        langs: {'eng', 'deu', 'script/Cyrillic'},
        script: 'Cyrillic',
        tsvByLanguage: {
          'deu+eng': tsvOf([word('Noxkanyucta,', 38.0), word('Gavte', 40.0)]),
          'script/Cyrillic':
              tsvOf([word('Пожалуйста,', 94.0), word('дайте', 92.0)]),
        },
      );

      expect(
        await service.recogniseText(
          '/tmp/sign.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        'Пожалуйста, дайте',
      );
    });

    test('names the script package when its trained data is missing', () async {
      final service = serviceReturning(
        langs: {'eng', 'deu'},
        script: 'Cyrillic',
        tsvByLanguage: {
          'deu+eng': tsvOf([word('Noxkanyucta,', 38.0), word('Gavte', 40.0)]),
        },
      );

      expect(
        () => service.recogniseText(
          '/tmp/sign.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrLanguageMissingException>().having(
            (e) => e.languageCodes, 'languageCodes', ['script-cyrl'])),
      );
    });

    test('does not blame missing data when the script is Latin', () async {
      // Latin is already covered by the Latin languages we loaded, so a failure
      // here is a bad photograph. Advising an install would misdirect the user.
      final service = serviceReturning(
        langs: {'eng', 'deu'},
        script: 'Latin',
        tsvByLanguage: {
          'deu+eng': tsvOf([word('Bltte', 30.0), word('gebeu', 28.0)]),
        },
      );

      expect(
        () => service.recogniseText(
          '/tmp/blurry.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('falls back to the plain message when the script cannot be told',
        () async {
      // Too few characters for OSD — the two-word sign. Nothing to add.
      final service = serviceReturning(
        langs: {'eng', 'deu'},
        script: null,
        tsvByLanguage: {
          'deu+eng': tsvOf([word('Bltte', 30.0)]),
        },
      );

      expect(
        () => service.recogniseText(
          '/tmp/sign.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('a missing binary is unavailable, not merely failed', () async {
      // The distinction drives the message: "install Tesseract" rather than
      // "could not read that image".
      final service = TesseractOcrService(
        runProcess: (executable, arguments) async =>
            throw ProcessException(executable, arguments, 'No such file', 2),
      );

      expect(
        () => service.recogniseText(
          '/tmp/photo.png',
          primaryLanguage: 'Swahili',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrUnavailableException>()),
      );
    });
  });
}
