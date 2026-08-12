@TestOn('linux || mac-os || windows')
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/database/dao_provider.dart';
import 'package:tafsiri/core/database/db_helper.dart';
import 'package:tafsiri/core/database/sqflite_desktop.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/core/services/backup_file_io.dart';
import 'package:tafsiri/core/services/backup_service.dart';
import 'package:tafsiri/features/settings/backup_controller.dart';
import 'package:tafsiri/features/settings/settings_controller.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// Stands in for the platform file dialogs: remembers what was written and
/// hands back whatever we tell it to read.
class _FakeFileIo implements BackupFileIo {
  String? written;
  String? suggestedName;
  String? toRead;
  bool cancelSave = false;
  bool cancelOpen = false;

  @override
  Future<String?> save({
    required String suggestedName,
    required String content,
  }) async {
    if (cancelSave) return null;
    this.suggestedName = suggestedName;
    written = content;
    return '/tmp/$suggestedName';
  }

  @override
  Future<String?> open() async => cancelOpen ? null : toRead;
}

Future<Database> _openDb() async {
  databaseFactory = createDesktopDatabaseFactory();
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: DbHelper.schemaVersion,
      onCreate: (db, _) => db.execute(DbHelper.createTableSql),
    ),
  );
}

TranslationEntry _entry(String source, DateTime when) => TranslationEntry(
      sourceText: source,
      resultText: 'Habari',
      sourceLang: 'en',
      targetLang: 'Swahili',
      aiProvider: kProviderMistral,
      createdAt: when,
    );

void main() {
  // PackageInfo reaches for the platform channel to stamp the app version into
  // the backup; without a binding it throws and only logs. Initialise so the
  // failure is a real one if it ever stops being handled.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late TranslationDao dao;
  late _FakeFileIo fileIo;

  setUp(() async {
    db = await _openDb();
    dao = TranslationDao(db);
    fileIo = _FakeFileIo();
  });

  tearDown(() => db.close());

  ProviderContainer makeContainer({Map<String, Object> prefs = const {}}) {
    SharedPreferences.setMockInitialValues({
      kPrefApiKeyClaude: 'sk-existing',
      kPrefActiveProvider: kProviderClaude,
      kPrefTargetLanguage: 'Swahili',
      kPrefAltLanguage: 'English',
      ...prefs,
    });
    final container = ProviderContainer(overrides: [
      backupFileIoProvider.overrideWithValue(fileIo),
      translationDaoProvider.overrideWith((_) async => dao),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('export', () {
    test('writes settings and history, and names the file by date', () async {
      await dao.insert(_entry('Hello', DateTime.utc(2026, 8, 12, 6)));
      final container = makeContainer();
      await container.read(settingsProvider.future);

      final result = await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);

      expect(result, isA<BackupExported>());
      expect((result as BackupExported).withApiKeys, isFalse);
      expect(fileIo.suggestedName, startsWith('tafsiri-backup-'));
      expect(fileIo.suggestedName, endsWith('.json'));
      expect(fileIo.written, contains('Hello'));
      expect(fileIo.written, isNot(contains('sk-existing')));
    });

    test('carries the keys when asked to', () async {
      final container = makeContainer();
      await container.read(settingsProvider.future);

      final result = await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: true);

      expect((result as BackupExported).withApiKeys, isTrue);
      expect(fileIo.written, contains('sk-existing'));
    });

    test('a cancelled dialog is not an error', () async {
      fileIo.cancelSave = true;
      final container = makeContainer();
      await container.read(settingsProvider.future);

      final result = await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);

      expect(result, isA<BackupCancelled>());
    });
  });

  group('import', () {
    test('restores settings and history into an empty install', () async {
      // Export from one "install"…
      await dao.insert(_entry('Hello', DateTime.utc(2026, 8, 12, 6)));
      final source = makeContainer(prefs: {
        kPrefTargetLanguage: 'Swahili',
        kPrefAltLanguage: 'German',
        kPrefCorrectionMode: true,
        kPrefSttLanguage: 'sw',
      });
      await source.read(settingsProvider.future);
      await source.read(backupProvider.notifier).export(includeApiKeys: false);
      final backup = fileIo.written!;

      // …into a fresh one with different settings and no history.
      await db.delete('translation_entry');
      fileIo.toRead = backup;
      final target = makeContainer(prefs: {
        kPrefTargetLanguage: 'French',
        kPrefAltLanguage: 'English',
        kPrefCorrectionMode: false,
        kPrefSttLanguage: '',
      });
      await target.read(settingsProvider.future);

      final result = await target.read(backupProvider.notifier).import();

      expect(result, isA<BackupImported>());
      expect((result as BackupImported).entriesAdded, 1);
      expect(result.apiKeysRestored, isFalse);

      final settings = target.read(settingsProvider).requireValue;
      expect(settings.targetLanguage, 'Swahili');
      expect(settings.altLanguage, 'German');
      expect(settings.correctionMode, isTrue);
      expect(settings.sttLanguage, 'sw');
      expect(await dao.getAll(), hasLength(1));
    });

    test('a keyless backup leaves existing API keys alone', () async {
      final source = makeContainer();
      await source.read(settingsProvider.future);
      await source.read(backupProvider.notifier).export(includeApiKeys: false);
      fileIo.toRead = fileIo.written;

      final target = makeContainer(prefs: {kPrefApiKeyClaude: 'sk-keep-me'});
      await target.read(settingsProvider.future);
      await target.read(backupProvider.notifier).import();

      // The blank keys in the file must not wipe a working configuration.
      expect(target.read(settingsProvider).requireValue.apiKeyClaude,
          'sk-keep-me');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefApiKeyClaude), 'sk-keep-me');
    });

    test('a backup with keys overwrites them', () async {
      final source = makeContainer(prefs: {kPrefApiKeyClaude: 'sk-from-backup'});
      await source.read(settingsProvider.future);
      await source.read(backupProvider.notifier).export(includeApiKeys: true);
      fileIo.toRead = fileIo.written;

      final target = makeContainer(prefs: {kPrefApiKeyClaude: 'sk-old'});
      await target.read(settingsProvider.future);
      final result = await target.read(backupProvider.notifier).import();

      expect((result as BackupImported).apiKeysRestored, isTrue);
      expect(target.read(settingsProvider).requireValue.apiKeyClaude,
          'sk-from-backup');
    });

    test('importing the same file twice adds nothing the second time',
        () async {
      await dao.insert(_entry('Hello', DateTime.utc(2026, 8, 12, 6)));
      await dao.insert(_entry('World', DateTime.utc(2026, 8, 12, 7)));
      final container = makeContainer();
      await container.read(settingsProvider.future);
      await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);
      fileIo.toRead = fileIo.written;

      final first = await container.read(backupProvider.notifier).import();
      expect((first as BackupImported).entriesAdded, 0);
      expect(first.entriesSkipped, 2);

      await db.delete('translation_entry');
      final second = await container.read(backupProvider.notifier).import();
      expect((second as BackupImported).entriesAdded, 2);

      final third = await container.read(backupProvider.notifier).import();
      expect((third as BackupImported).entriesAdded, 0);
      expect(await dao.getAll(), hasLength(2));
    });

    test('merges a backup into a history that already has other entries',
        () async {
      await dao.insert(_entry('Hello', DateTime.utc(2026, 8, 12, 6)));
      final container = makeContainer();
      await container.read(settingsProvider.future);
      await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);
      fileIo.toRead = fileIo.written;

      await db.delete('translation_entry');
      await dao.insert(_entry('Something else', DateTime.utc(2026, 8, 12, 9)));

      final result = await container.read(backupProvider.notifier).import();
      expect((result as BackupImported).entriesAdded, 1);
      expect(await dao.getAll(), hasLength(2));
    });

    test('replace mode wipes the existing history first', () async {
      await dao.insert(_entry('From the backup', DateTime.utc(2026, 8, 12, 6)));
      final container = makeContainer();
      await container.read(settingsProvider.future);
      await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);
      fileIo.toRead = fileIo.written;

      // Entries that exist only on this device must be gone afterwards.
      await db.delete('translation_entry');
      await dao.insert(_entry('Only on this device', DateTime.utc(2026, 8, 13)));
      await dao.insert(_entry('Also local', DateTime.utc(2026, 8, 14)));

      final result = await container
          .read(backupProvider.notifier)
          .import(replaceHistory: true);

      expect((result as BackupImported).historyReplaced, isTrue);
      expect(result.entriesAdded, 1);

      final all = await dao.getAll();
      expect(all, hasLength(1));
      expect(all.single.sourceText, 'From the backup');
    });

    test('merge mode is the default and keeps local entries', () async {
      await dao.insert(_entry('From the backup', DateTime.utc(2026, 8, 12, 6)));
      final container = makeContainer();
      await container.read(settingsProvider.future);
      await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);
      fileIo.toRead = fileIo.written;

      await db.delete('translation_entry');
      await dao.insert(_entry('Only on this device', DateTime.utc(2026, 8, 13)));

      final result = await container.read(backupProvider.notifier).import();

      expect((result as BackupImported).historyReplaced, isFalse);
      expect(await dao.getAll(), hasLength(2));
    });

    test('replacing with an empty backup clears the history', () async {
      final container = makeContainer();
      await container.read(settingsProvider.future);
      await container
          .read(backupProvider.notifier)
          .export(includeApiKeys: false);
      fileIo.toRead = fileIo.written;

      await dao.insert(_entry('Local', DateTime.utc(2026, 8, 13)));

      final result = await container
          .read(backupProvider.notifier)
          .import(replaceHistory: true);

      expect((result as BackupImported).entriesAdded, 0);
      expect(await dao.getAll(), isEmpty);
    });

    test('a foreign file is reported, not applied', () async {
      fileIo.toRead = '{"some":"other app"}';
      final container = makeContainer();
      await container.read(settingsProvider.future);

      final result = await container.read(backupProvider.notifier).import();

      expect(result, isA<BackupFailed>());
      expect((result as BackupFailed).formatError,
          BackupError.notATafsiriBackup);
      expect(container.read(settingsProvider).requireValue.targetLanguage,
          'Swahili');
    });

    test('a cancelled dialog is not an error', () async {
      fileIo.cancelOpen = true;
      final container = makeContainer();
      await container.read(settingsProvider.future);

      expect(await container.read(backupProvider.notifier).import(),
          isA<BackupCancelled>());
    });
  });
}
