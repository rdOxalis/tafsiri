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
/// codes. Covers the app's twelve UI languages, their native spellings and the
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
  'bulgarian': 'bul', 'български': 'bul', 'bg': 'bul',
  'russian': 'rus', 'русский': 'rus', 'ru': 'rus',
  'greek': 'ell', 'ελληνικά': 'ell', 'el': 'ell',
  'arabic': 'ara', 'العربية': 'ara', 'ar': 'ara',
};

/// The script each trained-data language is written in, keyed by ISO 639-2
/// code. Lets a detected script be checked against the configured languages
/// before any recognition happens (ADR-037).
const kLanguageScripts = <String, String>{
  'swa': 'Latin', 'eng': 'Latin', 'deu': 'Latin', 'fra': 'Latin',
  'nld': 'Latin', 'spa': 'Latin', 'dan': 'Latin', 'nor': 'Latin',
  'swe': 'Latin', 'pol': 'Latin', 'ita': 'Latin', 'por': 'Latin',
  'tur': 'Latin',
  'bul': 'Cyrillic', 'rus': 'Cyrillic',
  'ell': 'Greek',
  'ara': 'Arabic',
};

/// ISO 15924 short codes behind Debian's `tesseract-ocr-script-*` packages,
/// keyed by the script name Tesseract's OSD reports. Script trained data covers
/// every language written in that script, so one package answers "I photographed
/// something Cyrillic" without knowing which Cyrillic language it was.
const kScriptPackageSuffixes = <String, String>{
  'Latin': 'latn', 'Cyrillic': 'cyrl', 'Greek': 'grek', 'Arabic': 'arab',
  'Hebrew': 'hebr', 'Armenian': 'armn', 'Georgian': 'geor',
  'Devanagari': 'deva', 'Bengali': 'beng', 'Gujarati': 'gujr',
  'Gurmukhi': 'guru', 'Kannada': 'knda', 'Malayalam': 'mlym',
  'Oriya': 'orya', 'Sinhala': 'sinh', 'Tamil': 'taml', 'Telugu': 'telu',
  'Thaana': 'thaa', 'Thai': 'thai', 'Lao': 'laoo', 'Khmer': 'khmr',
  'Myanmar': 'mymr', 'Tibetan': 'tibt', 'Ethiopic': 'ethi', 'Syriac': 'syrc',
  'Cherokee': 'cher', 'Canadian_Aboriginal': 'cans', 'Fraktur': 'frak',
  'Vietnamese': 'viet', 'HanS': 'hans', 'HanT': 'hant', 'Hangul': 'hang',
  'Japanese': 'jpan',
};

/// What to install for [script], in the form [tesseractPackageHint] expects.
String scriptPackageSuffix(String script) =>
    'script-${kScriptPackageSuffixes[script] ?? script.toLowerCase()}';

/// Pulls the script and its confidence out of `tesseract --psm 0` output.
({String script, double confidence})? parseOsd(String output) {
  String? script;
  var confidence = 0.0;

  for (final line in output.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('Script:')) {
      final value = trimmed.substring('Script:'.length).trim();
      if (value.isNotEmpty) script = value;
    } else if (trimmed.startsWith('Script confidence:')) {
      confidence =
          double.tryParse(trimmed.split(':').last.trim()) ?? confidence;
    }
  }

  if (script == null) return null;
  return (script: script, confidence: confidence);
}

/// Below this, a script detection is treated as no detection.
///
/// The scale is small and not comparable to word confidence: a clean Cyrillic
/// page measures around 4.5 and a Latin one around 25, so this is a guard
/// against noise, not a quality bar.
const kMinScriptConfidence = 1.0;

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
    final configured = selectLanguages(primaryLanguage, altLanguage, available);

    // Ask the image which script it is *before* choosing trained data. The
    // configured languages say what the user translates into, but the image
    // holds whatever they photographed — and a translation app is used on text
    // one cannot read. Doing this only after a failure is not enough: Cyrillic
    // is full of Latin lookalikes (М о н а Т е с р), so English trained data
    // reads a Cyrillic page as confident nonsense — measured at 60.5, just past
    // the gate. Confidence catches an illegible image, never a wrong alphabet.
    final script = await detectScript(imagePath);

    if (script != null && !_covers(configured, script)) {
      final byScript = await _recognise(imagePath, 'script/$script');
      if (byScript != null && _isUsable(byScript)) return byScript.text;

      // Latin is already covered by any Latin language we might load, so a
      // failure there is a bad photograph — an install hint would misdirect.
      if (script != 'Latin') {
        throw OcrLanguageMissingException([scriptPackageSuffix(script)]);
      }
    }

    final page = await _recognise(imagePath, configured.argument);
    if (page != null && _isUsable(page)) return page.text;

    if (page == null) {
      throw const OcrFailedException('tesseract could not process the image.');
    }
    if (page.text.isEmpty) {
      throw const OcrFailedException('No text found in the image.');
    }
    if (configured.missing.isNotEmpty) {
      throw OcrLanguageMissingException(configured.missing);
    }
    throw OcrFailedException(
      'Mean confidence ${page.meanConfidence.toStringAsFixed(1)} is below '
      '$kMinMeanConfidence — refusing to pass this on as text.',
    );
  }

  /// Whether the trained data about to be loaded is written in [script].
  bool _covers(TesseractLanguages languages, String script) => languages.argument
      .split('+')
      .any((code) => kLanguageScripts[code] == script);

  bool _isUsable(TesseractPage page) =>
      page.text.isNotEmpty && page.meanConfidence >= kMinMeanConfidence;

  /// One recognition run, or `null` when Tesseract could not do it — a missing
  /// trained data file for [languages] shows up as a non-zero exit.
  Future<TesseractPage?> _recognise(String imagePath, String languages) async {
    debugPrint('[OCR] tesseract -l $languages');

    final ProcessResult result;
    try {
      // `tsv` is a config file name, not a flag, so it goes last. It gives the
      // text and the per-word confidence in one run.
      result =
          await _run(executable, [imagePath, 'stdout', '-l', languages, 'tsv']);
    } on ProcessException catch (e) {
      throw OcrUnavailableException('Could not run $executable: ${e.message}');
    }

    if (result.exitCode != 0) {
      debugPrint('[OCR] exit ${result.exitCode}: ${result.stderr}');
      return null;
    }
    return parseTesseractTsv('${result.stdout}');
  }

  /// The script Tesseract sees in the image, e.g. `Cyrillic`, or `null` when it
  /// cannot tell.
  ///
  /// Uses `osd.traineddata`, which ships with the engine itself, so this needs
  /// nothing extra installed. It does need enough characters: a two-word sign
  /// is answered with "Too few characters", which is why script detection can
  /// improve the outcome but never guarantee it.
  Future<String?> detectScript(String imagePath) async {
    try {
      final result = await _run(executable, [imagePath, 'stdout', '--psm', '0']);
      if (result.exitCode != 0) return null;
      final osd = parseOsd('${result.stdout}\n${result.stderr}');
      if (osd == null || osd.confidence < kMinScriptConfidence) return null;
      debugPrint('[OCR] script ${osd.script} (${osd.confidence})');
      return osd.script;
    } on ProcessException {
      return null;
    }
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
  TesseractLanguages selectLanguages(
    String primary,
    String alt,
    Set<String> available,
  ) {
    final wanted = <String>[];
    for (final name in [primary, alt]) {
      final code = kTesseractLanguageCodes[name.trim().toLowerCase()];
      if (code != null && !wanted.contains(code)) wanted.add(code);
    }

    final installed = wanted.where(available.contains).toList();
    final missing = wanted.where((c) => !available.contains(c)).toList();

    if (installed.isNotEmpty) {
      return TesseractLanguages(
        argument: installed.join('+'),
        missing: missing,
      );
    }

    // Nothing configured is installed. English is the one language virtually
    // every Tesseract install ships, and for Latin scripts it reads the letters
    // correctly and only loses diacritics — which the AI restores downstream.
    // For a foreign script it produces noise, and the confidence gate then
    // turns `missing` into an actionable message rather than a dead end.
    if (available.contains('eng')) {
      debugPrint('[OCR] no trained data for $wanted, falling back to eng');
      return TesseractLanguages(argument: 'eng', missing: missing);
    }

    throw OcrUnavailableException(
      'Tesseract has no trained data for ${wanted.join(', ')} and no English '
      'fallback. Installed: ${available.join(', ')}',
    );
  }
}

/// The `-l` argument to use, plus the configured languages that are not there.
@immutable
class TesseractLanguages {
  const TesseractLanguages({required this.argument, required this.missing});

  final String argument;

  /// Configured languages with no trained data installed, as ISO 639-2 codes.
  final List<String> missing;
}

/// Turns missing trained data into something the user can act on.
///
/// Debian and its derivatives package it as `tesseract-ocr-<code>` for a
/// language (`bul`) and `tesseract-ocr-script-<code>` for a whole script — the
/// latter arrives here already carrying its `script-` prefix, so both forms
/// take the same route. Elsewhere the bare codes are the most honest thing we
/// can say.
String tesseractPackageHint(List<String> codes) {
  if (Platform.isLinux) {
    return codes.map((c) => 'tesseract-ocr-$c').join(' ');
  }
  return codes.join(', ');
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
