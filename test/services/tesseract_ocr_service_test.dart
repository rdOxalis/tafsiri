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

    test('reads Windows line endings', () {
      // The bug that made every Windows read fail (ADR-043): splitting on '\n'
      // alone leaves the header's last field named 'text\r', so the column
      // lookup returns -1 and the whole page comes back empty — which the
      // caller reports as missing trained data.
      final tsv = [
        tsvHeader,
        word('Моля', 96.0),
        word('те,', 95.0),
      ].join('\r\n');

      final page = parseTesseractTsv(tsv);

      expect(page.text, 'Моля те,');
      expect(page.meanConfidence, closeTo(95.5, 0.001));
    });

    test('survives empty and malformed output', () {
      expect(parseTesseractTsv('').text, isEmpty);
      expect(parseTesseractTsv('').meanConfidence, 0);
      expect(parseTesseractTsv('not a tsv at all').text, isEmpty);
      expect(parseTesseractTsv(tsvHeader).text, isEmpty);
    });
  });

  group('parseOsd', () {
    test('reads the script and its confidence out of OSD output', () {
      final osd = parseOsd('Page number: 0\nOrientation in degrees: 0\n'
          'Script: Cyrillic\nScript confidence: 4.58\n');

      expect(osd?.script, 'Cyrillic');
      expect(osd?.confidence, closeTo(4.58, 0.001));
    });

    test('returns null when OSD had nothing to say', () {
      expect(parseOsd('Too few characters. Skipping this page'), isNull);
      expect(parseOsd(''), isNull);
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
                0,
                0,
                'Orientation in degrees: 0\n'
                    'Script: $script\nScript confidence: 4.58\n',
                '',
              );
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

    test('does not hand back confident nonsense from the wrong alphabet',
        () async {
      // The regression. Cyrillic is full of Latin lookalikes (М о н а Т е с р),
      // so English trained data reads a Bulgarian page as fluent-looking junk
      // at 60.5 mean confidence — past the gate, straight to the AI, which
      // would then invent something plausible. Confidence catches an illegible
      // image; it cannot catch a wrong alphabet. Only the script can.
      final service = serviceReturning(
        langs: {'eng', 'deu'},
        script: 'Cyrillic',
        tsvByLanguage: {
          'deu+eng': tsvOf([
            word('Mons,', 61.0),
            word('Haute', 60.0),
            word('MacnoTo', 60.5),
          ]),
        },
      );

      expect(
        () => service.recogniseText(
          '/tmp/bulgarian.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrLanguageMissingException>().having(
            (e) => e.languageCodes, 'languageCodes', ['script-cyrl'])),
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

    test('finds script trained data that the distribution installed flat',
        () async {
      // Debian's tesseract-ocr-script-cyrl puts the file at the top of tessdata
      // as `Cyrillic.traineddata`, not under `script/` the way upstream ships
      // it. Asking for `-l script/Cyrillic` then fails with "Error opening data
      // file" — indistinguishable from the package being absent, so an
      // installed package still produced "install tesseract-ocr-script-cyrl"
      // and left the user with nothing to do (ADR-038).
      final service = serviceReturning(
        langs: {'eng', 'deu', 'Cyrillic'},
        script: 'Cyrillic',
        tsvByLanguage: {
          'deu+eng': tsvOf([word('Mona', 71.0)]),
          'Cyrillic': tsvOf([word('Моля', 96.0), word('те,', 95.0)]),
        },
      );

      expect(
        await service.recogniseText(
          '/tmp/sign.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        'Моля те,',
      );
    });

    test('finds script trained data that Windows spells with a backslash',
        () async {
      // `--list-langs` reports the name the way the platform spells paths, so
      // the same data reads `script/Cyrillic` on Linux and `script\Cyrillic` on
      // Windows. Comparing literally matched neither there, the run was skipped
      // and installed data was reported as missing — with the user looking at a
      // tessdata\script folder that plainly contained it (ADR-043).
      final service = serviceReturning(
        langs: {'eng', 'deu', r'script\Cyrillic'},
        script: 'Cyrillic',
        tsvByLanguage: {
          'deu+eng': tsvOf([word('Mona', 71.0)]),
          r'script\Cyrillic': tsvOf([word('Моля', 96.0), word('те,', 95.0)]),
        },
      );

      expect(
        await service.recogniseText(
          '/tmp/sign.png',
          primaryLanguage: 'German',
          altLanguage: 'English',
        ),
        'Моля те,',
      );
    });

    test('hands Tesseract back its own spelling of the name', () async {
      // Not `script/Cyrillic` normalised to our taste: whatever the
      // installation reported is what it gets asked for (ADR-043).
      late List<String> seen;
      final service = TesseractOcrService(
        runProcess: (executable, arguments) async {
          if (arguments.contains('--list-langs')) {
            return ProcessResult(0, 0, 'eng\nscript\\Cyrillic\n', '');
          }
          if (arguments.contains('--psm')) {
            return ProcessResult(
                0, 0, 'Script: Cyrillic\nScript confidence: 4.5\n', '');
          }
          seen = arguments;
          return ProcessResult(0, 0, tsvOf([word('Моля', 96.0)]), '');
        },
      );

      await service.recogniseText(
        '/tmp/sign.png',
        primaryLanguage: 'English',
        altLanguage: 'English',
      );

      expect(seen[seen.indexOf('-l') + 1], r'script\Cyrillic');
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

    test('refuses a confident read when the missing script cannot be checked',
        () async {
      // The bug this guards (ADR-038): OSD says "too few characters" on a short
      // phrase, so the Cyrillic check never runs, English trained data reads
      // "Моля те, дай ми маслото." as Latin lookalikes at 70.6 — past the
      // confidence gate — and the junk was returned as a successful read.
      // Bulgarian is configured and has no trained data, so nothing loaded here
      // could have produced a correct read, whatever the confidence says.
      final service = serviceReturning(
        langs: {'eng', 'deu'},
        script: null,
        tsvByLanguage: {
          'eng': tsvOf([
            word('Mona', 71.0),
            word('Te,', 70.0),
            word('nal', 71.0),
            word('Mu', 70.0),
            word('MacnoTo.', 71.0),
          ]),
        },
      );

      await expectLater(
        service.recogniseText(
          '/tmp/short.png',
          primaryLanguage: 'Bulgarian',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrLanguageMissingException>().having(
          (e) => e.languageCodes,
          'languageCodes',
          ['bul'],
        )),
      );
    });

    test('still returns a confident read when only Latin data is missing',
        () async {
      // The counterpart: French is not installed and OSD stayed silent, but
      // English reads Latin letters correctly and only drops diacritics, which
      // the AI restores downstream. Refusing here would be a false alarm.
      final service = serviceReturning(
        langs: {'eng'},
        script: null,
        tsvByLanguage: {
          'eng': tsvOf([word('Donnez', 92.0), word('moi', 94.0)]),
        },
      );

      expect(
        await service.recogniseText(
          '/tmp/menu.png',
          primaryLanguage: 'French',
          altLanguage: 'English',
        ),
        'Donnez moi',
      );
    });

    test('names the configured language rather than the whole script pack',
        () async {
      // Bulgarian is what the user set and what the image turned out to be, so
      // `tesseract-ocr-bul` is both smaller and better than `script-cyrl`.
      final service = serviceReturning(
        langs: {'eng'},
        script: 'Cyrillic',
        tsvByLanguage: {
          'eng': tsvOf([word('Mona', 71.0)]),
        },
      );

      await expectLater(
        service.recogniseText(
          '/tmp/photo.png',
          primaryLanguage: 'Bulgarian',
          altLanguage: 'English',
        ),
        throwsA(isA<OcrLanguageMissingException>().having(
          (e) => e.languageCodes,
          'languageCodes',
          ['bul'],
        )),
      );
    });

    test('asks for TSV by parameter, never by config file name', () async {
      // `tsv` as a bare trailing argument is a *config file* in the
      // installation's tessdata/configs/. Where that file is absent — measured
      // on a Windows install — Tesseract does not fail: it warns on stderr,
      // exits 0 and prints plain text. The parser then finds no rows, the read
      // counts as unusable, and the user is told to install trained data that
      // was sitting there all along (ADR-043).
      late List<String> seen;
      final service = TesseractOcrService(
        runProcess: (executable, arguments) async {
          if (arguments.contains('--list-langs')) {
            return ProcessResult(0, 0, 'eng\n', '');
          }
          if (arguments.contains('--psm')) return ProcessResult(0, 1, '', '');
          seen = arguments;
          return ProcessResult(0, 0, tsvOf([word('Habari', 95.0)]), '');
        },
      );

      await service.recogniseText(
        '/tmp/photo.png',
        primaryLanguage: 'English',
        altLanguage: 'English',
      );

      expect(seen, containsAllInOrder(['-c', 'tessedit_create_tsv=1']));
      expect(seen, isNot(contains('tsv')),
          reason: 'a bare "tsv" argument reintroduces the config-file dependency');
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
