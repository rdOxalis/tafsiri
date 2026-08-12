import 'dart:convert';

import '../../features/settings/settings_controller.dart';
import '../../shared/models/translation_entry.dart';
import '../constants.dart';

/// Thrown when a file does not hold a Tafsiri backup we can read.
class BackupFormatException implements Exception {
  final BackupError error;
  const BackupFormatException(this.error);

  @override
  String toString() => 'BackupFormatException($error)';
}

enum BackupError {
  /// Not JSON at all, or not a JSON object.
  notJson,

  /// Valid JSON, but not a Tafsiri backup.
  notATafsiriBackup,

  /// Written by a newer app version with a format we do not understand.
  unsupportedVersion,
}

/// A parsed backup, ready to be applied.
class BackupContents {
  final SettingsState settings;

  /// True when the file carried API keys — `settings` holds them in that case,
  /// otherwise its key fields are empty and must not overwrite existing ones.
  final bool hasApiKeys;

  final List<TranslationEntry> history;
  final DateTime? createdAt;
  final String? appVersion;

  const BackupContents({
    required this.settings,
    required this.hasApiKeys,
    required this.history,
    this.createdAt,
    this.appVersion,
  });
}

/// Builds and parses the backup document (ADR-034).
///
/// Pure data transformation — no file access — so the format is covered by
/// plain unit tests. The controller owns the file dialogs around it.
class BackupService {
  const BackupService._();

  /// Marks the file as ours; a foreign JSON file is rejected on this.
  static const marker = 'tafsiri-backup';

  /// Bump only on a breaking format change. Readers accept anything ≤ this.
  static const formatVersion = 1;

  static String buildJson({
    required SettingsState settings,
    required List<TranslationEntry> history,
    required bool includeApiKeys,
    String? appVersion,
    DateTime? createdAt,
  }) {
    final doc = <String, dynamic>{
      'app': marker,
      'formatVersion': formatVersion,
      'createdAt': (createdAt ?? DateTime.now().toUtc()).toIso8601String(),
      if (appVersion != null) 'appVersion': appVersion,
      'settings': {
        kPrefActiveProvider: settings.activeProvider,
        kPrefTargetLanguage: settings.targetLanguage,
        kPrefAltLanguage: settings.altLanguage,
        kPrefSttLanguage: settings.sttLanguage,
        kPrefCorrectionMode: settings.correctionMode,
      },
      'includesApiKeys': includeApiKeys,
      if (includeApiKeys)
        'apiKeys': {
          kProviderMistral: settings.apiKeyMistral,
          kProviderClaude: settings.apiKeyClaude,
          kProviderOpenAI: settings.apiKeyOpenAI,
        },
      'history': history.map(_entryToJson).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  static BackupContents parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const BackupFormatException(BackupError.notJson);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException(BackupError.notJson);
    }
    if (decoded['app'] != marker) {
      throw const BackupFormatException(BackupError.notATafsiriBackup);
    }

    final version = decoded['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw const BackupFormatException(BackupError.unsupportedVersion);
    }

    final settingsMap = _asMap(decoded['settings']);
    final keysMap = _asMap(decoded['apiKeys']);
    final hasApiKeys = decoded['includesApiKeys'] == true && keysMap.isNotEmpty;

    // Every field falls back to its default, so a hand-trimmed backup still
    // restores instead of throwing.
    const defaults = SettingsState.defaults();
    final settings = SettingsState(
      apiKeyMistral: _str(keysMap[kProviderMistral]),
      apiKeyClaude: _str(keysMap[kProviderClaude]),
      apiKeyOpenAI: _str(keysMap[kProviderOpenAI]),
      activeProvider: _str(settingsMap[kPrefActiveProvider],
          fallback: defaults.activeProvider),
      targetLanguage: _str(settingsMap[kPrefTargetLanguage],
          fallback: defaults.targetLanguage),
      altLanguage:
          _str(settingsMap[kPrefAltLanguage], fallback: defaults.altLanguage),
      sttLanguage: _str(settingsMap[kPrefSttLanguage]),
      correctionMode: settingsMap[kPrefCorrectionMode] == true,
    );

    final rawHistory = decoded['history'];
    final history = <TranslationEntry>[];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        final entry = _entryFromJson(item);
        if (entry != null) history.add(entry);
      }
    }

    return BackupContents(
      settings: settings,
      hasApiKeys: hasApiKeys,
      history: history,
      createdAt: DateTime.tryParse(_str(decoded['createdAt'])),
      appVersion: decoded['appVersion'] is String
          ? decoded['appVersion'] as String
          : null,
    );
  }

  /// Filename of an export, e.g. `tafsiri-backup-2026-08-12.json`.
  static String fileNameFor(DateTime when) {
    final d = when.toLocal();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'tafsiri-backup-${d.year}-$month-$day.json';
  }

  static Map<String, dynamic> _entryToJson(TranslationEntry e) => {
        'sourceText': e.sourceText,
        'resultText': e.resultText,
        'sourceLang': e.sourceLang,
        'targetLang': e.targetLang,
        'aiProvider': e.aiProvider,
        'isFavourite': e.isFavourite,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'mode': e.mode,
        if (e.notes != null) 'notes': e.notes,
      };

  /// Returns `null` for an unusable row so one bad entry cannot fail a restore.
  static TranslationEntry? _entryFromJson(Object? item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    final sourceText = _str(map['sourceText']);
    final resultText = _str(map['resultText']);
    if (sourceText.isEmpty && resultText.isEmpty) return null;

    return TranslationEntry(
      sourceText: sourceText,
      resultText: resultText,
      sourceLang: _str(map['sourceLang']),
      targetLang: _str(map['targetLang']),
      aiProvider: _str(map['aiProvider']),
      isFavourite: map['isFavourite'] == true,
      createdAt:
          DateTime.tryParse(_str(map['createdAt']))?.toUtc() ?? DateTime.now().toUtc(),
      mode: map['mode'] == kModeCorrect ? kModeCorrect : kModeTranslate,
      notes: map['notes'] is String ? map['notes'] as String : null,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String _str(Object? value, {String fallback = ''}) =>
      value is String && value.isNotEmpty ? value : fallback;
}
