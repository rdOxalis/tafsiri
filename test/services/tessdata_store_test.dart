import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tafsiri/core/services/ocr/tessdata_store.dart';

/// ADR-075 — trained data is fetched on first use, from a pinned release,
/// and never left half-written.
void main() {
  late Directory base;
  setUp(() async => base = await Directory.systemTemp.createTemp('tessdata'));
  tearDown(() async => base.delete(recursive: true));

  Uint8List model([int size = TessdataStore.minimumBytes + 10]) =>
      Uint8List(size);

  TessdataStore storeWith(http.Client client) =>
      TessdataStore(client: client, baseDirectory: () async => base);

  File fileFor(String code) =>
      File('${base.path}/tesseract/tessdata/$code.traineddata');

  test('the data path is the parent of tessdata, with a trailing slash', () async {
    // Tesseract's init documents exactly this, and without the slash it looks
    // for "…/tesseracttessdata".
    final path = await storeWith(MockClient((_) async => http.Response('', 404)))
        .dataPath();
    expect(path, endsWith('/tesseract/'));
  });

  test('the release is pinned to a commit, not a tag or a branch', () {
    final url = TessdataStore.urlFor('swa').toString();
    expect(url, contains(TessdataStore.commit));
    expect(TessdataStore.commit, matches(RegExp(r'^[0-9a-f]{40}$')));
    expect(url, isNot(contains('/main/')));
    expect(url, endsWith('/swa.traineddata'));
  });

  test('fetches what is missing and keeps it', () async {
    final requested = <String>[];
    final store = storeWith(MockClient((request) async {
      requested.add(request.url.pathSegments.last);
      return http.Response.bytes(model(), 200);
    }));

    await store.ensure(['swa', 'deu']);
    expect(requested, ['swa.traineddata', 'deu.traineddata']);
    expect(await fileFor('swa').exists(), isTrue);
    expect(await store.has('deu'), isTrue);
  });

  test('does not fetch again what is already there', () async {
    var calls = 0;
    final store = storeWith(MockClient((_) async {
      calls++;
      return http.Response.bytes(model(), 200);
    }));
    await store.ensure(['swa']);
    await store.ensure(['swa']);
    expect(calls, 1);
  });

  test('a server error leaves nothing behind', () async {
    final store = storeWith(MockClient((_) async => http.Response('nope', 503)));
    await expectLater(store.ensure(['swa']),
        throwsA(isA<TessdataDownloadException>()));
    expect(await fileFor('swa').exists(), isFalse);
    expect(await File('${fileFor('swa').path}.part').exists(), isFalse);
  });

  test('a file too small to be a model is refused', () async {
    // An error page served with 200, or a transfer cut off early.
    final store =
        storeWith(MockClient((_) async => http.Response.bytes(model(500), 200)));
    await expectLater(store.ensure(['swa']),
        throwsA(isA<TessdataDownloadException>()));
    expect(await store.has('swa'), isFalse);
  });

  test('no connection becomes a download error, not a crash', () async {
    final store = storeWith(MockClient(
        (_) async => throw const SocketException('offline')));
    await expectLater(
      store.ensure(['swa']),
      throwsA(isA<TessdataDownloadException>()
          .having((e) => e.code, 'code', 'swa')),
    );
  });

  test('discard removes the data so the next run fetches it fresh', () async {
    final store =
        storeWith(MockClient((_) async => http.Response.bytes(model(), 200)));
    await store.ensure(['swa']);
    await store.discard(['swa']);
    expect(await store.has('swa'), isFalse);
  });
}
