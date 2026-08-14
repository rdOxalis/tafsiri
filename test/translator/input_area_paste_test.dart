import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/services/clipboard/clipboard_image_service.dart';
import 'package:tafsiri/core/services/clipboard/clipboard_image_service_factory.dart';
import 'package:tafsiri/core/services/ocr/ocr_service.dart';
import 'package:tafsiri/core/services/ocr/ocr_service_factory.dart';
import 'package:tafsiri/features/translator/widgets/input_area.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

/// Ctrl+V had to be taken over from the text field to reach clipboard images
/// (ADR-040), which put the ordinary text paste at risk. These pin both halves.
class _FakeClipboardImages implements ClipboardImageService {
  _FakeClipboardImages(this.file);

  final File? file;

  @override
  Future<File?> readImage() async => file;
}

class _FakeOcr implements OcrService {
  _FakeOcr(this.text);

  final String text;
  String? sawPath;

  @override
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  }) async {
    sawPath = imagePath;
    return text;
  }
}

Widget _wrap({ClipboardImageService? clipboard, OcrService? ocr}) {
  return ProviderScope(
    overrides: [
      if (clipboard != null)
        clipboardImageServiceProvider.overrideWithValue(clipboard),
      if (ocr != null) ocrServiceProvider.overrideWithValue(ocr),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en', 'GB')],
      locale: Locale('en', 'GB'),
      home: Scaffold(body: InputArea()),
    ),
  );
}

Future<void> _pressCtrlV(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  // Explicit pumps rather than pumpAndSettle: the paste is asynchronous, and
  // there is no frame-quiet moment to wait for.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Ctrl+V where the handler touches the file system.
///
/// `testWidgets` bodies run in a fake-async zone, where a real I/O future never
/// completes — so the clipboard temp file the controller deletes would hang the
/// test forever rather than fail it. `runAsync` steps outside that zone.
Future<void> _pressCtrlVWithRealIo(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': 'from the clipboard'};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Ctrl+V still pastes text when the clipboard has no image',
      (tester) async {
    await tester.pumpWidget(_wrap(clipboard: _FakeClipboardImages(null)));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await _pressCtrlV(tester);

    expect(find.text('from the clipboard'), findsOneWidget);
  });

  testWidgets('the paste lands at the cursor, not over the whole field',
      (tester) async {
    // Taking the shortcut over means reproducing this by hand; the easy wrong
    // version replaces everything, which the paste *button* does deliberately
    // but a keystroke inside a text field must not.
    await tester.pumpWidget(_wrap(clipboard: _FakeClipboardImages(null)));

    await tester.enterText(find.byType(TextField), 'ab');
    final field = tester.widget<TextField>(find.byType(TextField));
    field.controller!.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();

    await _pressCtrlV(tester);

    expect(field.controller!.text, 'afrom the clipboardb');
    expect(field.controller!.selection.baseOffset, 'afrom the clipboard'.length);
  });

  testWidgets('an image on the clipboard is recognised instead of pasted',
      (tester) async {
    late final Directory directory;
    late final File image;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('tafsiri_test');
      image = File('${directory.path}/clipboard.png');
      await image.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);
    });
    final ocr = _FakeOcr('Моля те, дай ми маслото.');

    await tester.pumpWidget(
      _wrap(clipboard: _FakeClipboardImages(image), ocr: ocr),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await _pressCtrlVWithRealIo(tester);

    expect(ocr.sawPath, image.path);
    expect(find.text('Моля те, дай ми маслото.'), findsOneWidget);
    // The clipboard text must not have been appended on top of the recognition.
    expect(find.textContaining('from the clipboard'), findsNothing);
    // The temporary file is the app's to clean up.
    expect(directory.existsSync(), isFalse);
  });
}
