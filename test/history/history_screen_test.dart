import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/features/history/history_controller.dart';
import 'package:tafsiri/features/history/history_screen.dart';
import 'package:tafsiri/l10n/app_localizations.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// Keeps the history in memory, so the screen can be driven without SQLite.
class _FakeHistoryController extends HistoryController {
  _FakeHistoryController(this._entries);

  final List<TranslationEntry> _entries;

  @override
  Future<List<TranslationEntry>> build() async => List.of(_entries);

  @override
  Future<TranslationEntry?> delete(int id) async {
    final deleted = _entries.where((e) => e.id == id).firstOrNull;
    if (deleted == null) return null;
    _entries.remove(deleted);
    state = AsyncData(List.of(_entries));
    return deleted;
  }

  @override
  Future<void> restore(TranslationEntry entry) async {
    _entries.add(entry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncData(List.of(_entries));
  }
}

TranslationEntry _entry(int id, String source) => TranslationEntry(
      id: id,
      sourceText: source,
      resultText: '$source (sw)',
      sourceLang: 'en',
      targetLang: 'Swahili',
      aiProvider: 'claude',
      createdAt: DateTime(2026, 10, 27, 9, id),
    );

Widget _wrap(List<TranslationEntry> entries) => ProviderScope(
      overrides: [
        historyProvider.overrideWith(() => _FakeHistoryController(entries)),
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
        home: HistoryScreen(),
      ),
    );

void main() {
  group('Deleting a history entry', () {
    testWidgets('says the entry was deleted, not "Delete"', (tester) async {
      await tester.pumpWidget(_wrap([_entry(1, 'special cat')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Translation deleted'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'Delete'), findsNothing);
    });

    testWidgets('the message goes away on its own', (tester) async {
      await tester.pumpWidget(_wrap([_entry(1, 'special cat')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      // A snackbar's default display time is 4 seconds.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Undo brings the entry back and closes the message',
        (tester) async {
      await tester.pumpWidget(_wrap([_entry(1, 'special cat')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('special cat'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('special cat'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('several deletions show one message, not a queue',
        (tester) async {
      await tester.pumpWidget(
          _wrap([_entry(2, 'special cat'), _entry(1, 'the end')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();

      // Undo restores the latest deletion and nothing else pops up after it.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('the end'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
