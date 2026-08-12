import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/database/dao_provider.dart';
import '../../core/services/backup_file_io.dart';
import '../../core/services/backup_service.dart';
import '../history/history_controller.dart';
import 'settings_controller.dart';

/// Outcome of an export or import, for the snackbar.
sealed class BackupResult {
  const BackupResult();
}

class BackupCancelled extends BackupResult {
  const BackupCancelled();
}

class BackupExported extends BackupResult {
  final String location;
  final bool withApiKeys;
  const BackupExported(this.location, {required this.withApiKeys});
}

class BackupImported extends BackupResult {
  final int entriesAdded;
  final int entriesSkipped;
  final bool apiKeysRestored;

  /// True when the old history was wiped rather than merged into.
  final bool historyReplaced;

  const BackupImported({
    required this.entriesAdded,
    required this.entriesSkipped,
    required this.apiKeysRestored,
    this.historyReplaced = false,
  });
}

class BackupFailed extends BackupResult {
  /// Set when the file was readable but not a usable backup.
  final BackupError? formatError;
  final String? detail;
  const BackupFailed({this.formatError, this.detail});
}

final backupFileIoProvider = Provider<BackupFileIo>((_) => const BackupFileIo());

class BackupController extends Notifier<bool> {
  /// State is "busy" — the dialogs are modal, but writing can take a moment.
  @override
  bool build() => false;

  Future<BackupResult> export({required bool includeApiKeys}) async {
    if (state) return const BackupCancelled();
    state = true;
    try {
      final settings = await ref.read(settingsProvider.future);
      final dao = await ref.read(translationDaoProvider.future);
      final history = await dao.getAll();

      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (e) {
        debugPrint('[Backup] package info unavailable: $e');
      }

      final now = DateTime.now();
      final json = BackupService.buildJson(
        settings: settings,
        history: history,
        includeApiKeys: includeApiKeys,
        appVersion: appVersion,
        createdAt: now.toUtc(),
      );

      final location = await ref.read(backupFileIoProvider).save(
            suggestedName: BackupService.fileNameFor(now),
            content: json,
          );
      if (location == null) return const BackupCancelled();

      debugPrint('[Backup] exported ${history.length} entries, '
          'keys=$includeApiKeys');
      return BackupExported(location, withApiKeys: includeApiKeys);
    } catch (e) {
      debugPrint('[Backup] export failed: $e');
      return BackupFailed(detail: _short(e));
    } finally {
      state = false;
    }
  }

  /// [replaceHistory] wipes the existing history instead of merging the backup
  /// into it — destructive, so the UI confirms it separately.
  Future<BackupResult> import({bool replaceHistory = false}) async {
    if (state) return const BackupCancelled();
    state = true;
    try {
      final raw = await ref.read(backupFileIoProvider).open();
      if (raw == null) return const BackupCancelled();

      final contents = BackupService.parse(raw);

      await ref.read(settingsProvider.notifier).restore(
            contents.settings,
            restoreApiKeys: contents.hasApiKeys,
          );

      final dao = await ref.read(translationDaoProvider.future);
      final added = replaceHistory
          ? await dao.replaceAllWith(contents.history)
          : await dao.insertMissing(contents.history);
      ref.invalidate(historyProvider);

      debugPrint('[Backup] imported $added of ${contents.history.length} '
          'entries, replace=$replaceHistory, keys=${contents.hasApiKeys}');
      return BackupImported(
        entriesAdded: added,
        entriesSkipped: contents.history.length - added,
        apiKeysRestored: contents.hasApiKeys,
        historyReplaced: replaceHistory,
      );
    } on BackupFormatException catch (e) {
      debugPrint('[Backup] import rejected: ${e.error}');
      return BackupFailed(formatError: e.error);
    } catch (e) {
      debugPrint('[Backup] import failed: $e');
      return BackupFailed(detail: _short(e));
    } finally {
      state = false;
    }
  }

  static String _short(Object e) {
    final msg = e.toString();
    return msg.length > 120 ? '${msg.substring(0, 120)}…' : msg;
  }
}

final backupProvider =
    NotifierProvider<BackupController, bool>(BackupController.new);
