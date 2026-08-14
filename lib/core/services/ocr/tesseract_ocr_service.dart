import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ocr_service.dart';

/// Runs a process and returns its result. Injectable so the parsing and the
/// language handling can be tested without a Tesseract installation.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Mean word confidence below which a recognition counts as failed.
///
/// Tesseract reports 0–100 per word; clean text lands in the high 80s, while a
/// photo of a curved or badly lit surface drops far below. The gate exists
/// because the extracted text goes straight to a language model afterwards:
/// handed garble, the model does not fail — it writes fluent, plausible text
/// that was never on the image, and the user has no way to tell. A visible
/// "could not read that" is the honest outcome (ADR-037).
const kMinMeanConfidence = 60.0;

/// Maps the free-text language names from Settings to Tesseract's ISO 639-2
/// codes. Covers the app's ten UI languages, their native spellings and the
/// two-letter codes the AI returns, since the setting accepts any of them.
const kTesseractLanguageCodes = <String, String>{
  'swahili': 'swa', 'kiswahili': 'swa', 'sw': 'swa',
  'english': 'eng', 'en': 'eng',
  'german': 'deu', 'deutsch': 'deu', 'de': 'deu',
  'french': 'fra', 'français': 'fra', 'francais': 'fra', 'fr': 'fra',
  'dutch': 'nld', 'nederlands': 'nld', 'nl': 'nld',
  'spanish': 'spa', 'español': 'spa', 'espanol': 'spa', 'es': 'spa',
  'danish': 'dan', 'dansk': 'dan', 'da': 'dan',
  'norwegian': 'nor', 'norsk': 'nor', 'no': 'nor', 'nb': 'nor',
  'swedish': 'swe', 'svenska': 'swe', 'sv': 'swe',
  'polish': 'pol', 'polski': 'pol', 'pl': 'pol',
  'italian': 'ita', 'italiano': 'ita', 'it': 'ita',
  'portuguese': 'por', 'português': 'por', 'portugues': 'por', 'pt': 'por',
  'turkish': 'tur', 'türkçe': 'tur', 'tr': 'tur',
};

/// Recognition through the external `tesseract` binary (ADR-037).
///
/// Deliberately a subprocess rather than FFI: no native build step, no plugin,
/// and the engine can be swapped or upgraded without touching the app.
class TesseractOcrService implements OcrService {
  const TesseractOcrService({
    this.executable = 'tesseract',
    ProcessRunner? runProcess,
  }) : _runProcess = runProcess;

  /// Binary name or absolute path. On Linux this is whatever is on `PATH`.
  final String executable;

  final ProcessRunner? _runProcess;

  ProcessRunner get _run => _runProcess ?? Process.run;

  @override
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  }) async {
    final available = await _availableLanguages();
    final languages = languageArgument(
      primaryLanguage,
      altLanguage,
      available,
    );

    debugPrint('[OCR] tesseract -l $languages');

    final ProcessResult result;
    try {
      // `tsv` is a config file name, not a flag, so it goes last. It gives the
      // text and the per-word confidence in one run.
      result = await _run(executable, [imagePath, 'stdout', '-l', languages, 'tsv']);
    } on ProcessException catch (e) {
      throw OcrUnavailableException('Could not run $executable: ${e.message}');
    }

    if (result.exitCode != 0) {
      throw OcrFailedException(
        'tesseract exited with ${result.exitCode}: ${result.stderr}',
      );
    }

    final page = parseTesseractTsv('${result.stdout}');

    if (page.text.isEmpty) {
      throw const OcrFailedException('No text found in the image.');
    }
    if (page.meanConfidence < kMinMeanConfidence) {
      throw OcrFailedException(
        'Mean confidence ${page.meanConfidence.toStringAsFixed(1)} is below '
        '$kMinMeanConfidence — refusing to pass this on as text.',
      );
    }

    return page.text;
  }

  /// Trained data actually installed, as three-letter codes.
  Future<Set<String>> _availableLanguages() async {
    final ProcessResult result;
    try {
      result = await _run(executable, ['--list-langs']);
    } on ProcessException catch (e) {
      throw OcrUnavailableException(
        'Tesseract is not installed or not on PATH ($executable): ${e.message}',
      );
    }

    // Some builds print the list to stderr, others to stdout.
    final output = '${result.stdout}\n${result.stderr}';
    return output
        .split('\n')
        .map((line) => line.trim())
        // Drops the "List of available languages (n):" header and blank lines.
        .where((line) => line.isNotEmpty && !line.contains(' '))
        .toSet();
  }

  /// Builds the `-l` argument from the configured languages.
  ///
  /// Both are passed together — Tesseract handles mixed-language pages that
  /// way, which is exactly the case correction mode is built around: a
  /// primary-language text with foreign words in it (ADR-033).
  @visibleForTesting
  String languageArgument(String primary, String alt, Set<String> available) {
    final wanted = <String>[];
    for (final name in [primary, alt]) {
      final code = kTesseractLanguageCodes[name.trim().toLowerCase()];
      if (code != null && !wanted.contains(code)) wanted.add(code);
    }

    final installed = wanted.where(available.contains).toList();
    if (installed.isNotEmpty) return installed.join('+');

    // Nothing configured is installed. English is the one language virtually
    // every Tesseract install ships, and a wrong-language guess still beats
    // refusing outright — the AI cleans up the result afterwards anyway.
    if (available.contains('eng')) {
      debugPrint('[OCR] no trained data for $wanted, falling back to eng');
      return 'eng';
    }

    throw OcrUnavailableException(
      'Tesseract has no trained data for ${wanted.join(', ')} and no English '
      'fallback. Installed: ${available.join(', ')}',
    );
  }
}

/// One recognised page: its text and how sure Tesseract was on average.
@immutable
class TesseractPage {
  const TesseractPage({required this.text, required this.meanConfidence});

  final String text;
  final double meanConfidence;
}

/// Rebuilds text and mean confidence from Tesseract's TSV output.
///
/// The TSV has one row per layout element; only level 5 rows are words. Columns
/// are addressed by header name rather than index, because the column set has
/// changed between Tesseract versions.
TesseractPage parseTesseractTsv(String tsv) {
  final lines = tsv.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) {
    return const TesseractPage(text: '', meanConfidence: 0);
  }

  final header = lines.first.split('\t');
  int column(String name) => header.indexOf(name);

  final levelAt = column('level');
  final blockAt = column('block_num');
  final parAt = column('par_num');
  final lineAt = column('line_num');
  final confAt = column('conf');
  final textAt = column('text');

  if ([levelAt, blockAt, parAt, lineAt, confAt, textAt].any((i) => i < 0)) {
    return const TesseractPage(text: '', meanConfidence: 0);
  }

  final buffer = StringBuffer();
  final confidences = <double>[];
  String? currentLine;
  var firstWordOnLine = true;

  for (final row in lines.skip(1)) {
    final cells = row.split('\t');
    if (cells.length <= textAt) continue;
    if (cells[levelAt] != '5') continue;

    final word = cells[textAt].trim();
    if (word.isEmpty) continue;

    final confidence = double.tryParse(cells[confAt]) ?? -1;
    if (confidence >= 0) confidences.add(confidence);

    final lineKey = '${cells[blockAt]}/${cells[parAt]}/${cells[lineAt]}';
    if (currentLine != null && lineKey != currentLine) {
      buffer.write('\n');
      firstWordOnLine = true;
    }
    currentLine = lineKey;

    if (!firstWordOnLine) buffer.write(' ');
    buffer.write(word);
    firstWordOnLine = false;
  }

  final mean = confidences.isEmpty
      ? 0.0
      : confidences.reduce((a, b) => a + b) / confidences.length;

  return TesseractPage(text: buffer.toString().trim(), meanConfidence: mean);
}
