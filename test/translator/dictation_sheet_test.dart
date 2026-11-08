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
  Future<void> startDictation() async {
    calls.add('start');
    state = state.copyWith(isListening: true, sttLang: 'sw');
  }

  @override
  Future<void> setDictationLanguage(String code) async {
    calls.add('lang:$code');
    state = state.copyWith(sttLang: code);
  }

  @override
  Future<void> finishDictation() async {
    if (!state.isListening) return;
    calls.add('finish');
    state = state.copyWith(isListening: false, inputText: 'Lila amemfukuza');
  }

  @override
  Future<void> cancelDictation() async {
    if (!state.isListening) return;
    calls.add('cancel');
    state = state.copyWith(isListening: false);
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

  testWidgets('shows whether to speak, and what was heard', (tester) async {
    await _open(tester);
    expect(find.text('One moment…'), findsOneWidget);

    _fake.hear('Lila amemfukuza');
    await tester.pump();

    expect(find.text('Listening…'), findsOneWidget);
    expect(find.text('Lila amemfukuza'), findsOneWidget);
  });

  testWidgets('Done closes the window and keeps the text', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(DictationSheet), findsNothing);
    expect(_fake.calls, ['start', 'finish']);
    expect(_fake.state.inputText, 'Lila amemfukuza');
  });

  testWidgets('Cancel closes the window and keeps nothing', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(DictationSheet), findsNothing);
    expect(_fake.calls, ['start', 'cancel']);
    expect(_fake.state.inputText, '');
  });

  testWidgets('Back keeps what was said, like Done', (tester) async {
    await _open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(DictationSheet), findsNothing);
    expect(_fake.calls, ['start', 'finish']);
  });
}
