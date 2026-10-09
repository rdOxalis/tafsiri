import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/ocr/android_tesseract_ocr_service.dart';
import 'package:tafsiri/core/services/ocr/ocr_service.dart';
import 'package:tafsiri/core/services/ocr/tessdata_store.dart';

/// A store that never touches the network or the disk.
class _FakeStore extends TessdataStore {
  _FakeStore({this.failWith}) : super(baseDirectory: () async => Directory.systemTemp);

  final TessdataDownloadException? failWith;
  final ensured = <List<String>>[];
  final discarded = <List<String>>[];

  @override
  Future<String> dataPath() async => '/data/tesseract/';

  @override
  Future<void> ensure(List<String> codes) async {
    ensured.add(codes);
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> discard(List<String> codes) async => discarded.add(codes);
}

/// ADR-075 — Tesseract on Android, through one platform channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(AndroidTesseractOcrService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('tesseractCodesFor', () {
    test('maps the two configured languages, in order', () {
      expect(tesseractCodesFor(['Swahili', 'Deutsch']), ['swa', 'deu']);
    });

    test('accepts any spelling the free-text field allows', () {
      expect(tesseractCodesFor([' kiswahili ', 'GERMAN']), ['swa', 'deu']);
      expect(tesseractCodesFor(['sw', 'de']), ['swa', 'deu']);
    });

    test('drops duplicates and names it cannot map', () {
      expect(tesseractCodesFor(['English', 'english']), ['eng']);
      expect(tesseractCodesFor(['Klingon', 'Bulgarian']), ['bul']);
    });

    test('falls back to English rather than reading nothing', () {
      expect(tesseractCodesFor(['Klingon', 'Quenya']), ['eng']);
    });
  });

  group('recogniseText', () {
    test('sends both languages and the data path, returns the text', () async {
      answer((_) => {'text': '  Habari za asubuhi  \n', 'confidence': 88});
      final store = _FakeStore();
      final service = AndroidTesseractOcrService(store: store);

      final text = await service.recogniseText('/img.jpg',
          primaryLanguage: 'Swahili', altLanguage: 'Deutsch');

      expect(text, 'Habari za asubuhi');
      expect(store.ensured.single, ['swa', 'deu']);
      expect(calls.single.method, 'recognise');
      expect(calls.single.arguments, {
        'imagePath': '/img.jpg',
        'dataPath': '/data/tesseract/',
        'languages': 'swa+deu',
      });
    });

    test('a read below the confidence gate is refused, not passed on', () async {
      // Below the gate the text is more likely invented than seen, and the AI
      // downstream would make it fluent (ADR-037).
      answer((_) => {'text': 'Mona Te', 'confidence': 31});
      await expectLater(
        AndroidTesseractOcrService(store: _FakeStore()).recogniseText('/i.jpg',
            primaryLanguage: 'Bulgarian', altLanguage: 'German'),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('an empty read is a failure', () async {
      answer((_) => {'text': '   ', 'confidence': 95});
      await expectLater(
        AndroidTesseractOcrService(store: _FakeStore()).recogniseText('/i.jpg',
            primaryLanguage: 'Swahili', altLanguage: 'German'),
        throwsA(isA<OcrFailedException>()),
      );
    });

    test('a failed download says so, rather than "install Tesseract"', () async {
      answer((_) => fail('no recognition without data'));
      await expectLater(
        AndroidTesseractOcrService(
          store: _FakeStore(failWith: const TessdataDownloadException('swa', 'offline')),
        ).recogniseText('/i.jpg', primaryLanguage: 'Swahili', altLanguage: 'German'),
        throwsA(isA<OcrDataDownloadException>()
            .having((e) => e.languageCode, 'code', 'swa')),
      );
    });

    test('data Tesseract will not load is thrown away for a fresh fetch',
        () async {
      answer((_) => throw PlatformException(code: 'init_failed'));
      final store = _FakeStore();
      await expectLater(
        AndroidTesseractOcrService(store: store).recogniseText('/i.jpg',
            primaryLanguage: 'Swahili', altLanguage: 'German'),
        throwsA(isA<OcrDataDownloadException>()),
      );
      expect(store.discarded.single, ['swa', 'deu']);
    });

    test('an unreadable image is an ordinary failure', () async {
      answer((_) => throw PlatformException(code: 'unreadable_image'));
      await expectLater(
        AndroidTesseractOcrService(store: _FakeStore()).recogniseText('/i.heic',
            primaryLanguage: 'Swahili', altLanguage: 'German'),
        throwsA(isA<OcrFailedException>()),
      );
    });
  });
}
