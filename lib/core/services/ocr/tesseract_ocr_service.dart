import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'ocr_log.dart';
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

/// The `-l` name for [script]'s trained data, or `null` when it is not there.
///
/// The layout is not a convention we can assume. Upstream `tessdata` ships the
/// file under `script/`, and Tesseract turns `-l script/Cyrillic` into that
/// path — but Debian's `tesseract-ocr-script-cyrl` installs the same data flat
/// as `Cyrillic.traineddata` at the top of `tessdata`, where that argument
/// finds nothing. The failure is "Error opening data file", indistinguishable
/// from the package being absent, so an installed script package still produced
/// "install tesseract-ocr-script-cyrl" and no way to act on it. Taking the name
/// from `--list-langs` instead makes both layouts work (ADR-038).
///
/// The separator is not a convention either: `--list-langs` reports the name
/// the way the platform spells paths, so the same data is `script/Cyrillic` on
/// Linux and `script\Cyrillic` on Windows. Comparing literally matched neither
/// on Windows, which skipped the run and reported installed data as missing.
/// Matching is therefore separator-blind, while the value handed back is the
/// spelling this installation actually used — Tesseract is given its own words
/// back rather than ours (ADR-043).
String? scriptArgument(String script, Set<String> available) {
  String normalise(String name) => name.replaceAll(r'\', '/');

  final byNormalisedName = {
    for (final name in available) normalise(name): name,
  };
  for (final candidate in ['script/$script', script]) {
    final match = byNormalisedName[normalise(candidate)];
    if (match != null) return match;
  }
  return null;
}

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

/// How often the page is repeated per axis before OSD is asked a second time.
///
/// OSD refuses to judge a page with too few characters, and the phrase off a
/// menu or a sign this app exists for is regularly under that floor. Nine
/// copies carry a twenty-character line past it — measured on the Bulgarian
/// sample, which goes from "Too few characters" to Cyrillic at 26.7 — while the
/// image stays small enough for the extra run to be unnoticeable (ADR-038).
const kOsdTileFactor = 3;

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

  ProcessRunner get _run => _runProcess ?? _utf8Run;

  /// `Process.run`, but reading the output as UTF-8 rather than as whatever the
  /// machine calls its system encoding.
  ///
  /// Tesseract always writes UTF-8. `Process.run` defaults to `systemEncoding`,
  /// which is UTF-8 on Linux — and the ANSI code page on Windows, where
  /// `Моля те` came back as `ÐœÐ¾Ð»Ñ Ñ‚Ðµ`: every two-byte character decoded as
  /// two Latin ones. Nothing failed, the confidence was 96, and the text was
  /// nonsense (ADR-046). Malformed input is tolerated rather than thrown on,
  /// because a mangled character is worth reporting and a crash is not.
  static Future<ProcessResult> _utf8Run(
    String executable,
    List<String> arguments,
  ) =>
      Process.run(
        executable,
        arguments,
        stdoutEncoding: const Utf8Codec(allowMalformed: true),
        stderrEncoding: const Utf8Codec(allowMalformed: true),
      );

  @override
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  }) async {
    final available = await _availableLanguages();
    final configured = selectLanguages(primaryLanguage, altLanguage, available);
    ocrLog('--- recognise "$imagePath"');
    ocrLog('installed: ${available.join(" | ")}');
    ocrLog('configured: -l ${configured.argument}'
        '${configured.missing.isEmpty ? "" : "  missing=${configured.missing}"}');

    // Ask the image which script it is *before* choosing trained data. The
    // configured languages say what the user translates into, but the image
    // holds whatever they photographed — and a translation app is used on text
    // one cannot read. Doing this only after a failure is not enough: Cyrillic
    // is full of Latin lookalikes (М о н а Т е с р), so English trained data
    // reads a Cyrillic page as confident nonsense — measured at 60.5, just past
    // the gate. Confidence catches an illegible image, never a wrong alphabet.
    final script = await detectScript(imagePath);

    if (script != null && !_covers(configured, script)) {
      // Whatever this installation calls that trained data — or nothing, in
      // which case there is no point spawning a run that cannot succeed.
      final argument = scriptArgument(script, available);
      ocrLog('script $script is not covered; script data resolves to '
          '${argument ?? "NOTHING INSTALLED"}');
      // Nothing installed for this script: that is the one case where naming a
      // package is the right answer. Latin is exempt — any Latin language we
      // might load already covers it, so a failure there is a bad photograph
      // and an install hint would misdirect.
      if (argument == null) {
        if (script != 'Latin') {
          throw OcrLanguageMissingException(_installHint(configured, script));
        }
      } else {
        final byScript = await _recognise(imagePath, argument);
        if (byScript != null && _isUsable(byScript)) return byScript.text;

        // The data was there and was used, and the read still came out poor.
        // Claiming it is missing would be a lie, and one the user cannot act
        // on — they are looking at the installed file. Far more likely the
        // detection was wrong: this is what a screenshot of a mostly-Latin
        // window does, where a little Cyrillic wins OSD by a nose (measured at
        // script confidence 1.76, against ~4.5 for a genuinely Cyrillic page)
        // and the configured languages would have read it better. So fall
        // through and let them try (ADR-045).
        ocrLog('script read unusable; falling back to ${configured.argument}');
      }
    }

    // Configured languages that are missing *and* written in a script nothing
    // loaded can read. A missing Latin language does not qualify: English reads
    // those letters and only drops diacritics, which the AI restores downstream.
    final unreadable = configured.missing
        .where((code) => !_covers(configured, kLanguageScripts[code] ?? 'Latin'))
        .toList();

    final page = await _recognise(imagePath, configured.argument);
    if (page != null && _isUsable(page)) {
      // Confidence cannot catch a wrong alphabet. English trained data reads
      // "Моля те, дай ми маслото." as "Mona Te, nal Mu MacnoTo." at 70.6 — well
      // past the gate — because Cyrillic is full of Latin lookalikes. So when
      // OSD could not name the script and a configured one is unreadable, a
      // confident result is not evidence that it was read correctly, and
      // returning it would hand the model fluent nonsense (ADR-038).
      if (script == null && unreadable.isNotEmpty) {
        ocrLog('script unknown and $unreadable unreadable — refusing');
        throw OcrLanguageMissingException(unreadable);
      }
      return page.text;
    }

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

  /// What to tell the user to install for [script].
  ///
  /// A configured language written in that script wins over the script pack:
  /// it is the smaller download, and language data reads its own language
  /// better than the generic script data does. Only when the detected script
  /// matches nothing the user configured is the whole script pack the honest
  /// answer — they photographed something they never mentioned.
  List<String> _installHint(TesseractLanguages languages, String script) {
    final configured = languages.missing
        .where((code) => kLanguageScripts[code] == script)
        .toList();
    return configured.isNotEmpty ? configured : [scriptPackageSuffix(script)];
  }

  bool _isUsable(TesseractPage page) =>
      page.text.isNotEmpty && page.meanConfidence >= kMinMeanConfidence;

  /// One recognition run, or `null` when Tesseract could not do it — a missing
  /// trained data file for [languages] shows up as a non-zero exit.
  Future<TesseractPage?> _recognise(String imagePath, String languages) async {
    final arguments = [
      imagePath,
      'stdout',
      '-l',
      languages,
      '-c',
      'tessedit_create_tsv=1',
    ];
    ocrLog('run: $executable ${arguments.join(" ")}');

    final ProcessResult result;
    try {
      // Text and per-word confidence in one run. Set as a parameter rather than
      // via the `tsv` config file that used to go here: that file lives in the
      // installation's `tessdata/configs/`, and where it is absent Tesseract
      // does not fail — it prints `read_params_file: Can't open tsv` to stderr,
      // exits 0, and hands back plain text. The parser then finds no rows, the
      // read counts as unusable, and the user is told to install trained data
      // that was already there. Measured on a Windows install (ADR-043).
      result = await _run(executable, arguments);
    } on ProcessException catch (e) {
      throw OcrUnavailableException('Could not run $executable: ${e.message}');
    }

    if (result.exitCode != 0) {
      ocrLog('  exit ${result.exitCode}: ${result.stderr}');
      return null;
    }
    final raw = '${result.stdout}';
    final page = parseTesseractTsv(raw);
    // The raw length against the parsed length is the tell: plenty of output
    // and nothing parsed means the TSV did not look the way we expect, which
    // is a different problem from Tesseract having read nothing.
    ocrLog('  ${raw.length} B out, text=${page.text.length} chars, '
        'confidence=${page.meanConfidence.toStringAsFixed(1)}');
    if (page.text.isEmpty && raw.isNotEmpty) {
      ocrLog('  first line back: ${raw.split(RegExp(r"\r?\n")).first}');
    }
    return page;
  }

  /// The script Tesseract sees in the image, e.g. `Cyrillic`, or `null` when it
  /// cannot tell.
  ///
  /// Uses `osd.traineddata`, which ships with the engine itself, so this needs
  /// nothing extra installed. It does need enough characters, and a short
  /// phrase is answered with "Too few characters" — so a page OSD will not
  /// judge is tiled and asked once more before giving up (ADR-038).
  Future<String?> detectScript(String imagePath) async {
    final direct = await _osd(imagePath);
    if (direct != null) return direct;

    final tiled = await _tiledCopy(imagePath);
    if (tiled == null) return null;
    try {
      return await _osd(tiled.path);
    } finally {
      await tiled.parent.delete(recursive: true);
    }
  }

  /// One `--psm 0` run, or `null` when it produced no verdict worth trusting.
  Future<String?> _osd(String imagePath) async {
    try {
      final result = await _run(executable, [imagePath, 'stdout', '--psm', '0']);
      if (result.exitCode != 0) return null;
      final osd = parseOsd('${result.stdout}\n${result.stderr}');
      if (osd == null || osd.confidence < kMinScriptConfidence) {
        ocrLog('script not detected: ${osd ?? result.stdout}');
        return null;
      }
      ocrLog('script ${osd.script} (${osd.confidence})');
      return osd.script;
    } on ProcessException {
      return null;
    }
  }

  /// The page repeated in a [kOsdTileFactor]² grid in a temporary directory,
  /// or `null` when the image cannot be read as one.
  ///
  /// Repetition invents no glyph the page did not already carry, so the verdict
  /// stays honest — it only lifts the character count over OSD's floor. The
  /// caller owns the directory and deletes it.
  Future<File?> _tiledCopy(String imagePath) async {
    try {
      final source = img.decodeImage(await File(imagePath).readAsBytes());
      if (source == null) return null;

      const n = kOsdTileFactor;
      final tiled =
          img.Image(width: source.width * n, height: source.height * n);
      // Screenshots arrive with transparency, which OSD reads as black on
      // black; white is the background every trained data expects.
      img.fill(tiled, color: img.ColorRgb8(255, 255, 255));
      for (var row = 0; row < n; row++) {
        for (var column = 0; column < n; column++) {
          img.compositeImage(
            tiled,
            source,
            dstX: column * source.width,
            dstY: row * source.height,
          );
        }
      }

      final directory = await Directory.systemTemp.createTemp('tafsiri_osd');
      final file = File(p.join(directory.path, 'tiled.png'));
      await file.writeAsBytes(img.encodePng(tiled));
      return file;
    } on IOException {
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
      ocrLog('no trained data for $wanted, falling back to eng');
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
  // `\r?\n`, not `\n`: on Windows Tesseract ends every line with CRLF, which
  // leaves the header's last field named `text\r`. `column('text')` then
  // returns -1, the guard below reports an empty page, and the caller — seeing
  // no text — blames missing trained data. Every read on Windows failed this
  // way, and the trailing `\r` on the *word* cells was invisible because those
  // are trimmed individually (ADR-043).
  final lines =
      tsv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
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
