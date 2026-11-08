import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/features/translator/translator_controller.dart';
import 'package:tafsiri/features/translator/widgets/dictation_sheet.dart';
import 'package:tafsiri/l10n/app_localizations.dart';

/// Stands in for the recogniser: records what the window asks for.
class _FakeDictation extends TranslatorController {
  final calls = <String>[];

  @override
  TranslatorState build() => const TranslatorState(isSttAvailable: true);

  @override
  void openDictation() {
    calls.add('open');
    state = state.copyWith(isDictating: true, sttLang: 'sw');
  }

  @override
  Future<void> toggleSpeaking() async {
    calls.add(state.isMicHot ? 'stop' : 'speak');
    state = state.copyWith(isMicHot: !state.isMicHot);
  }

  @override
  Future<void> setDictationLanguage(String code) async {
    calls.add('lang:$code');
    state = state.copyWith(sttLang: code);
  }

  @override
  Future<void> finishDictation() async {
    if (!state.isDictating) return;
    calls.add('finish');
    state = state.copyWith(isDictating: false, inputText: 'Lila amemfukuza');
  }

  @override
  Future<void> cancelDictation() async {
    if (!state.isDictating) return;
    calls.add('cancel');
    state = state.copyWith(isDictating: false);
  }

  void hear(String text, {bool hot = true}) =>
      state = state.copyWith(dictationPreview: text, isMicHot: hot);
}

late _FakeDictation _fake;

Widget _app() => ProviderScope(
      overrides: [translatorProvider.overrideWith(() => _fake = _FakeDictation())],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'GB')],
        locale: const Locale('en', 'GB'),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showDictationSheet(context, ref),
              child: const Text('mic'),
            ),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    kPrefTargetLanguage: 'Swahili',
    kPrefAltLanguage: 'German',
  });
  await tester.pumpWidget(_app());
  await tester.tap(find.text('mic'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers the learning and the confident language', (tester) async {
    await _open(tester);

    expect(find.widgetWithText(ChoiceChip, 'Kiswahili'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Deutsch'), findsOneWidget);
    final sw = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Kiswahili'));
    expect(sw.selected, isTrue);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Deutsch'));
    await tester.pumpAndSettle();

    expect(_fake.calls, contains('lang:de'));
    final de = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Deutsch'));
    expect(de.selected, isTrue);
  });

  testWidgets('opens without listening; the user starts each part',
      (tester) async {
    await _open(tester);
    expect(_fake.calls, ['open']);
    expect(find.textContaining('Tap the microphone'), findsOneWidget);

    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    expect(find.text('Listening…'), findsOneWidget);

    // A pause ends the part; the window stays open for the next one.
    _fake.hear('Lila amemfukuza', hot: false);
    await tester.pump();
    expect(find.byType(DictationSheet), findsOneWidget);
    expect(find.text('Lila amemfukuza'), findsOneWidget);
    expect(find.byTooltip('Speak'), findsOneWidget);
  });

  testWidgets('the microphone ends a running part early', (tester) async {
    await _open(tester);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();

    expect(_fake.calls, ['open', 'speak', 'stop']);
    expect(find.byType(DictationSheet), findsOneWidget);
  });

  testWidgets('Use text closes the window and keeps the text', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Use text'));
    await tester.pumpAndSettle();

    expect(find.byType(DictationSheet), findsNothing);
    expect(_fake.calls, ['open', 'finish']);
    expect(_fake.state.inputText, 'Lila amemfukuza');
  });

  testWidgets('Cancel closes the window and keeps nothing', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(DictationSheet), findsNothing);
    expect(_fake.calls, ['open', 'cancel']);
    expect(_fake.state.inputText, '');
  });

  testWidgets('Back keeps what was said, like Use text', (tester) async {
    await _open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(DictationSheet), findsNothing);
    expect(_fake.calls, ['open', 'finish']);
  });
}
