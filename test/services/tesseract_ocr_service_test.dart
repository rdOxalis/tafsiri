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

  group('languageArgument', () {
    const service = TesseractOcrService();
    const installed = {'eng', 'deu', 'swa', 'fra'};

    test('maps both configured languages and passes them together', () {
      expect(service.languageArgument('Swahili', 'English', installed),
          'swa+eng');
    });

    test('accepts native spellings and two-letter codes', () {
      expect(service.languageArgument('Deutsch', 'en', installed), 'deu+eng');
      expect(service.languageArgument('de', 'Français', installed), 'deu+fra');
    });

    test('does not repeat a language configured twice', () {
      expect(service.languageArgument('German', 'de', installed), 'deu');
    });

    test('skips languages whose trained data is not installed', () {
      expect(service.languageArgument('Polish', 'German', installed), 'deu');
    });

    test('falls back to English when nothing configured is installed', () {
      expect(service.languageArgument('Polish', 'Swedish', installed), 'eng');
    });

    test('gives up when even English is missing', () {
      expect(
        () => service.languageArgument('Polish', 'Swedish', {'jpn'}),
        throwsA(isA<OcrUnavailableException>()),
      );
    });

    test('falls back for a language name it does not know', () {
      expect(service.languageArgument('Klingon', 'Elvish', installed), 'eng');
    });
  });

  group('recogniseText', () {
    /// Answers `--list-langs` with [langs] and the recognition run with [tsv].
    TesseractOcrService serviceReturning({
      required Set<String> langs,
      required String tsv,
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
            return ProcessResult(0, exitCode, tsv, exitCode == 0 ? '' : 'boom');
          },
        );

    String tsvOf(List<String> rows) => [tsvHeader, ...rows].join('\n');

    test('returns the recognised text', () async {
      final service = serviceReturning(
        langs: {'eng', 'swa'},
        tsv: tsvOf([word('Habari', 95.0), word('yako', 93.0)]),
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

    test('rejects a low-confidence read instead of passing it to the AI',
        () async {
      // This is the case the gate exists for: handed this, a language model
      // would not fail — it would invent fluent text that was never on the
      // image, and the user could not tell.
      final service = serviceReturning(
        langs: {'eng'},
        tsv: tsvOf([word('Tafadhal1', 31.0), word('n|pe', 22.0)]),
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
      final service = serviceReturning(langs: {'eng'}, tsv: tsvOf([]));

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
        tsv: '',
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
