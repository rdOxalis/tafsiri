import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/services/backup_service.dart';
import 'package:tafsiri/features/settings/settings_controller.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';

/// ADR-034 — the backup format is the contract between an old install and a
/// new one, so it is pinned here rather than only exercised through the UI.
const _settings = SettingsState(
  apiKeyMistral: 'sk-mistral',
  apiKeyClaude: 'sk-claude',
  apiKeyOpenAI: 'sk-openai',
  activeProvider: kProviderClaude,
  targetLanguage: 'Swahili',
  altLanguage: 'German',
  sttLanguage: 'sw',
  correctionMode: true,
);

final _history = [
  TranslationEntry(
    sourceText: 'Hello',
    resultText: 'Habari',
    sourceLang: 'en',
    targetLang: 'Swahili',
    aiProvider: kProviderClaude,
    isFavourite: true,
    createdAt: DateTime.utc(2026, 8, 12, 6, 30),
  ),
  TranslationEntry(
    sourceText: 'Tafadhali nipe Butter.',
    resultText: 'Tafadhali nipe siagi.',
    sourceLang: 'sw',
    targetLang: 'Swahili',
    aiProvider: kProviderMistral,
    createdAt: DateTime.utc(2026, 8, 12, 7),
    mode: kModeCorrect,
    notes: '- Butter → siagi: German for "butter".',
  ),
];

String _export({bool includeApiKeys = false}) => BackupService.buildJson(
      settings: _settings,
      history: _history,
      includeApiKeys: includeApiKeys,
      appVersion: '1.0.9+9',
      createdAt: DateTime.utc(2026, 8, 12, 8),
    );

void main() {
  group('BackupService export', () {
    test('round-trips settings and history without keys', () {
      final restored = BackupService.parse(_export());

      expect(restored.hasApiKeys, isFalse);
      expect(restored.settings.activeProvider, kProviderClaude);
      expect(restored.settings.targetLanguage, 'Swahili');
      expect(restored.settings.altLanguage, 'German');
      expect(restored.settings.sttLanguage, 'sw');
      expect(restored.settings.correctionMode, isTrue);
      expect(restored.appVersion, '1.0.9+9');

      expect(restored.history, hasLength(2));
      final correction = restored.history[1];
      expect(correction.sourceText, 'Tafadhali nipe Butter.');
      expect(correction.mode, kModeCorrect);
      expect(correction.notes, contains('siagi'));
      expect(correction.createdAt, DateTime.utc(2026, 8, 12, 7));
      expect(restored.history[0].isFavourite, isTrue);
    });

    test('omits API keys entirely unless asked for', () {
      final json = _export();

      // Not merely blanked — the secrets must not appear in the file at all.
      expect(json, isNot(contains('sk-mistral')));
      expect(json, isNot(contains('sk-claude')));
      expect(json, isNot(contains('sk-openai')));
      expect(jsonDecode(json), isNot(contains('apiKeys')));

      final restored = BackupService.parse(json);
      expect(restored.hasApiKeys, isFalse);
      expect(restored.settings.apiKeyClaude, isEmpty);
    });

    test('includes API keys when asked for', () {
      final restored = BackupService.parse(_export(includeApiKeys: true));

      expect(restored.hasApiKeys, isTrue);
      expect(restored.settings.apiKeyMistral, 'sk-mistral');
      expect(restored.settings.apiKeyClaude, 'sk-claude');
      expect(restored.settings.apiKeyOpenAI, 'sk-openai');
    });

    test('is marked as ours and versioned', () {
      final doc = jsonDecode(_export()) as Map<String, dynamic>;
      expect(doc['app'], 'tafsiri-backup');
      expect(doc['formatVersion'], 1);
      expect(doc['createdAt'], '2026-08-12T08:00:00.000Z');
    });
  });

  group('BackupService.parse rejects', () {
    test('a file that is not JSON', () {
      expect(
        () => BackupService.parse('not json at all'),
        throwsA(isA<BackupFormatException>()
            .having((e) => e.error, 'error', BackupError.notJson)),
      );
    });

    test('a JSON file that is not a Tafsiri backup', () {
      expect(
        () => BackupService.parse('{"hello":"world"}'),
        throwsA(isA<BackupFormatException>()
            .having((e) => e.error, 'error', BackupError.notATafsiriBackup)),
      );
    });

    test('a backup from a newer format version', () {
      final doc = jsonDecode(_export()) as Map<String, dynamic>;
      doc['formatVersion'] = BackupService.formatVersion + 1;
      expect(
        () => BackupService.parse(jsonEncode(doc)),
        throwsA(isA<BackupFormatException>()
            .having((e) => e.error, 'error', BackupError.unsupportedVersion)),
      );
    });
  });

  group('BackupService.parse tolerates', () {
    test('a backup with no history at all', () {
      final doc = jsonDecode(_export()) as Map<String, dynamic>;
      doc.remove('history');
      final restored = BackupService.parse(jsonEncode(doc));
      expect(restored.history, isEmpty);
      expect(restored.settings.targetLanguage, 'Swahili');
    });

    test('missing settings by falling back to defaults', () {
      final doc = jsonDecode(_export()) as Map<String, dynamic>;
      doc.remove('settings');
      final restored = BackupService.parse(jsonEncode(doc));
      const defaults = SettingsState.defaults();
      expect(restored.settings.targetLanguage, defaults.targetLanguage);
      expect(restored.settings.altLanguage, defaults.altLanguage);
      expect(restored.settings.activeProvider, defaults.activeProvider);
      expect(restored.settings.correctionMode, isFalse);
    });

    test('one unusable history row without losing the rest', () {
      final doc = jsonDecode(_export()) as Map<String, dynamic>;
      (doc['history'] as List).insert(1, {'sourceText': '', 'resultText': ''});
      (doc['history'] as List).insert(2, 'garbage');

      final restored = BackupService.parse(jsonEncode(doc));
      expect(restored.history, hasLength(2));
    });

    test('a history row with an unparsable timestamp', () {
      final doc = jsonDecode(_export()) as Map<String, dynamic>;
      (doc['history'] as List)[0]['createdAt'] = 'whenever';
      final restored = BackupService.parse(jsonEncode(doc));
      expect(restored.history[0].createdAt, isNotNull);
      expect(restored.history[0].sourceText, 'Hello');
    });
  });

  test('fileNameFor is dated and zero-padded', () {
    expect(
      BackupService.fileNameFor(DateTime(2026, 8, 3)),
      'tafsiri-backup-2026-08-03.json',
    );
    expect(
      BackupService.fileNameFor(DateTime(2026, 11, 24)),
      'tafsiri-backup-2026-11-24.json',
    );
  });
}
