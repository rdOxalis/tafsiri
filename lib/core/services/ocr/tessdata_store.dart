import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Thrown when trained data could not be fetched — no connection, a server
/// error, or a file too small to be what it claims (ADR-075).
///
/// Its own type because the remedy is its own: not "install something", which
/// is what the desktop says, but "try again with a connection".
class TessdataDownloadException implements Exception {
  const TessdataDownloadException(this.code, this.reason);

  /// ISO 639-2 code whose data could not be fetched, e.g. `swa`.
  final String code;
  final String reason;

  @override
  String toString() => 'TessdataDownloadException($code): $reason';
}

/// Tesseract's trained data on Android, fetched the first time it is needed
/// (ADR-075).
///
/// Bundling is not an option: the script models that would cover every Latin
/// language at once weigh 89 MB, and per-language models for the twelve
/// interface languages still add up to about 40 MB. A user reads in the two
/// languages they configured, so those two are fetched — 4 to 8 MB, once — and
/// kept.
class TessdataStore {
  TessdataStore({
    http.Client? client,
    Future<Directory> Function()? baseDirectory,
  })  : _client = client ?? http.Client(),
        _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  final http.Client _client;
  final Future<Directory> Function() _baseDirectory;

  /// The `tessdata_fast` release 4.1.0, pinned to its commit rather than its
  /// tag: a tag can be moved, a commit cannot, so every device gets exactly
  /// the models that were tested. The fast models, not the best ones — they
  /// are a quarter of the size, and on a phone the difference in accuracy is
  /// smaller than the difference a steady hand makes.
  static const commit = '65727574dfcd264acbb0c3e07860e4e9e9b22185';

  /// Smaller than any real model in that release (the smallest is about a
  /// megabyte). A file below it is an error page or a cut-off transfer.
  static const minimumBytes = 100 * 1024;

  static Uri urlFor(String code) => Uri.parse(
      'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/'
      '$commit/$code.traineddata');

  /// The directory Tesseract's `init` wants: the parent of `tessdata`, with a
  /// trailing slash, because that is what its documentation demands.
  Future<String> dataPath() async {
    final base = await _baseDirectory();
    return '${base.path}/tesseract/';
  }

  Future<Directory> _tessdata() async =>
      Directory('${await dataPath()}tessdata');

  /// Whether the data for [code] is already on the device.
  Future<bool> has(String code) async {
    final file = File('${(await _tessdata()).path}/$code.traineddata');
    return await file.exists() && await file.length() >= minimumBytes;
  }

  /// Makes sure the data for every one of [codes] is on the device, fetching
  /// what is missing. Already present files cost one stat each.
  Future<void> ensure(List<String> codes) async {
    final directory = await _tessdata();
    await directory.create(recursive: true);
    for (final code in codes) {
      if (await has(code)) continue;
      await _download(code, directory);
    }
  }

  /// Removes the data for [codes] — after Tesseract refused to load it, the
  /// next attempt should fetch it fresh rather than fail the same way forever.
  Future<void> discard(List<String> codes) async {
    final directory = await _tessdata();
    for (final code in codes) {
      final file = File('${directory.path}/$code.traineddata');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _download(String code, Directory directory) async {
    final target = File('${directory.path}/$code.traineddata');
    // Written beside the target and renamed into place, so a transfer cut off
    // half-way can never be mistaken for a complete model on the next run.
    final partial = File('${target.path}.part');
    try {
      final response = await _client.send(http.Request('GET', urlFor(code)));
      if (response.statusCode != 200) {
        throw TessdataDownloadException(code, 'HTTP ${response.statusCode}');
      }
      final sink = partial.openWrite();
      try {
        await response.stream.pipe(sink);
      } finally {
        await sink.close();
      }
      final size = await partial.length();
      if (size < minimumBytes) {
        throw TessdataDownloadException(code, 'only $size bytes arrived');
      }
      await partial.rename(target.path);
      debugPrint('[Tessdata] fetched $code ($size bytes)');
    } on TessdataDownloadException {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } catch (e) {
      if (await partial.exists()) await partial.delete();
      throw TessdataDownloadException(code, e.toString());
    }
  }
}
