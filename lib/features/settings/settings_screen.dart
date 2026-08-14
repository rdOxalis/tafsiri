import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/build_info.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/locale_notifier.dart';
import '../../core/services/backup_service.dart';
import '../../l10n/app_localizations.dart';
import 'backup_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _mistralController = TextEditingController();
  final _claudeController = TextEditingController();
  final _openAiController = TextEditingController();
  final _targetLangController = TextEditingController();
  final _altLangController = TextEditingController();

  bool _mistralVisible = false;
  bool _claudeVisible = false;
  bool _openAiVisible = false;
  bool _initialized = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _appVersion = buildLabel(
              version: info.version,
              buildNumber: info.buildNumber,
            ));
      }
    });
  }

  @override
  void dispose() {
    _mistralController.dispose();
    _claudeController.dispose();
    _openAiController.dispose();
    _targetLangController.dispose();
    _altLangController.dispose();
    super.dispose();
  }

  void _syncControllers(SettingsState s) {
    if (_initialized) return;
    _mistralController.text = s.apiKeyMistral;
    _claudeController.text = s.apiKeyClaude;
    _openAiController.text = s.apiKeyOpenAI;
    _targetLangController.text = s.targetLanguage;
    _altLangController.text = s.altLanguage;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (settings) {
          _syncControllers(settings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Warning banner ---
              if (!settings.hasApiKeyForActiveProvider) ...[
                _WarningBanner(message: l10n.warningNoApiKey),
                const SizedBox(height: 8),
              ],

              // --- Translation Languages ---
              _SectionHeader(l10n.translationLanguagesSection),
              const SizedBox(height: 8),
              TextField(
                controller: _targetLangController,
                decoration:
                    InputDecoration(labelText: l10n.targetLanguageLabel),
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setTargetLanguage(v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _altLangController,
                decoration:
                    InputDecoration(labelText: l10n.altLanguageLabel),
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setAltLanguage(v),
              ),

              const Divider(height: 32),

              // --- Speech Recognition ---
              _SectionHeader(l10n.sttLanguageLabel),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: kSttLanguageOptions.any(
                        (e) => e.$1 == settings.sttLanguage)
                    ? settings.sttLanguage
                    : '',
                items: kSttLanguageOptions
                    .map((e) => DropdownMenuItem(
                          value: e.$1,
                          child: Text(e.$1.isEmpty
                              ? l10n.sttLanguageAuto
                              : e.$2),
                        ))
                    .toList(),
                onChanged: (code) {
                  if (code != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setSttLanguage(code);
                  }
                },
              ),

              const Divider(height: 32),

              // --- App Language ---
              _SectionHeader(l10n.appLanguageLabel),
              const SizedBox(height: 8),
              _LocaleDropdown(),

              const Divider(height: 32),

              // --- AI Provider ---
              _SectionHeader(l10n.providerLabel),
              Text(
                l10n.providerSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 4),
              RadioListTile<String>(
                value: kProviderMistral,
                groupValue: settings.activeProvider,
                title: Text(l10n.providerMistral),
                onChanged: (p) => ref
                    .read(settingsProvider.notifier)
                    .setActiveProvider(p!),
              ),
              RadioListTile<String>(
                value: kProviderClaude,
                groupValue: settings.activeProvider,
                title: Text(l10n.providerClaude),
                onChanged: (p) => ref
                    .read(settingsProvider.notifier)
                    .setActiveProvider(p!),
              ),
              RadioListTile<String>(
                value: kProviderOpenAI,
                groupValue: settings.activeProvider,
                title: Text(l10n.providerOpenAI),
                onChanged: (p) => ref
                    .read(settingsProvider.notifier)
                    .setActiveProvider(p!),
              ),
              const SizedBox(height: 8),
              // --- API Key for active provider only ---
              if (settings.activeProvider == kProviderMistral) ...[
                _ApiKeyField(
                  label: l10n.apiKeyMistral,
                  controller: _mistralController,
                  visible: _mistralVisible,
                  onToggleVisibility: () =>
                      setState(() => _mistralVisible = !_mistralVisible),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setApiKey(kProviderMistral, v),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.mistralFreeHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                _GetApiKeyButton(url: kMistralApiKeyUrl, label: l10n.getApiKeyButton),
              ],
              if (settings.activeProvider == kProviderClaude) ...[
                _ApiKeyField(
                  label: l10n.apiKeyClaude,
                  controller: _claudeController,
                  visible: _claudeVisible,
                  onToggleVisibility: () =>
                      setState(() => _claudeVisible = !_claudeVisible),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setApiKey(kProviderClaude, v),
                ),
                _GetApiKeyButton(url: kClaudeApiKeyUrl, label: l10n.getApiKeyButton),
              ],
              if (settings.activeProvider == kProviderOpenAI) ...[
                _ApiKeyField(
                  label: l10n.apiKeyOpenAI,
                  controller: _openAiController,
                  visible: _openAiVisible,
                  onToggleVisibility: () =>
                      setState(() => _openAiVisible = !_openAiVisible),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setApiKey(kProviderOpenAI, v),
                ),
                _GetApiKeyButton(url: kOpenAiApiKeyUrl, label: l10n.getApiKeyButton),
              ],

              const Divider(height: 32),

              // --- Backup (ADR-034) ---
              _SectionHeader(l10n.backupSection),
              const _BackupPanel(),

              const Divider(height: 32),

              // --- Donate ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.coffee_outlined),
                title: Text(l10n.donateButton),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDonateDialog(context, l10n),
              ),
              const SizedBox(height: 16),

              // --- Version ---
              if (_appVersion.isNotEmpty)
                Center(
                  child: Text(
                    'v$_appVersion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  void _showDonateDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.coffee_outlined, size: 32),
        title: Text(l10n.donateButton),
        content: const Text('PayPal · paypal.me/CarlDarkman'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.donateButton),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(kPayPalDonateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onChanged;

  const _ApiKeyField({
    required this.label,
    required this.controller,
    required this.visible,
    required this.onToggleVisibility,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _GetApiKeyButton extends StatelessWidget {
  final String url;
  final String label;
  const _GetApiKeyButton({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        icon: const Icon(Icons.open_in_new, size: 14),
        label: Text(label),
        style: TextButton.styleFrom(
          textStyle: Theme.of(context).textTheme.bodySmall,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () => launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ),
      ),
    );
  }
}

class _LocaleDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.valueOrNull;
    final currentCode = currentLocale == null
        ? 'en_GB'
        : currentLocale.countryCode != null
            ? '${currentLocale.languageCode}_${currentLocale.countryCode}'
            : currentLocale.languageCode;

    return DropdownButtonFormField<String>(
      value: supportedAppLocales.any((e) => e.$1 == currentCode)
          ? currentCode
          : 'en_GB',
      items: supportedAppLocales
          .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
          .toList(),
      onChanged: (code) {
        if (code != null) {
          ref.read(localeProvider.notifier).setLocale(code);
        }
      },
    );
  }
}

/// Backup export/import (ADR-034).
///
/// Lives in Settings but writes outside the app sandbox — data inside the
/// sandbox is deleted on uninstall, which is exactly what this guards against.
class _BackupPanel extends ConsumerStatefulWidget {
  const _BackupPanel();

  @override
  ConsumerState<_BackupPanel> createState() => _BackupPanelState();
}

class _BackupPanelState extends ConsumerState<_BackupPanel> {
  /// Both default to off and are deliberately not persisted: each is the
  /// riskier choice of its pair, so it has to be asked for every time rather
  /// than happening because a switch remembered.
  bool _includeApiKeys = false;
  bool _replaceHistory = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = ref.watch(backupProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.backupExplain,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _includeApiKeys,
          title: Text(l10n.backupIncludeKeys),
          subtitle: _includeApiKeys
              ? Text(
                  l10n.backupIncludeKeysWarning,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                )
              : null,
          onChanged: busy ? null : (v) => setState(() => _includeApiKeys = v),
          secondary: Icon(
            Icons.save_alt,
            size: 18,
            color: theme.colorScheme.outline,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _replaceHistory,
          title: Text(l10n.backupReplaceHistory),
          subtitle: _replaceHistory
              ? Text(
                  l10n.backupReplaceHistoryWarning,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                )
              : null,
          onChanged: busy ? null : (v) => setState(() => _replaceHistory = v),
          secondary: Icon(
            Icons.settings_backup_restore,
            size: 18,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(l10n.backupExportButton),
                onPressed: busy ? null : _export,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.settings_backup_restore),
                label: Text(l10n.backupImportButton),
                onPressed: busy ? null : _import,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _export() async {
    final result = await ref
        .read(backupProvider.notifier)
        .export(includeApiKeys: _includeApiKeys);
    if (!mounted) return;
    _report(result);
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Replacing is destructive and irreversible, so it gets its own wording
    // and a red confirm button rather than the neutral merge dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          _replaceHistory
              ? Icons.warning_amber_rounded
              : Icons.settings_backup_restore,
          size: 28,
          color: _replaceHistory ? theme.colorScheme.error : null,
        ),
        title: Text(l10n.backupImportConfirmTitle),
        content: Text(_replaceHistory
            ? l10n.backupImportConfirmMessageReplace
            : l10n.backupImportConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: _replaceHistory
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.backupImportConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(backupProvider.notifier)
        .import(replaceHistory: _replaceHistory);
    if (!mounted) return;
    _report(result);
  }

  void _report(BackupResult result) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (String message, bool isError) = switch (result) {
      BackupCancelled() => ('', false),
      BackupExported(withApiKeys: final withKeys) => (
          withKeys ? l10n.backupExportedWithKeys : l10n.backupExported,
          false,
        ),
      BackupImported(
        entriesAdded: final added,
        entriesSkipped: final skipped,
        apiKeysRestored: final keys,
        historyReplaced: final replaced,
      ) =>
        (
          [
            if (replaced)
              l10n.backupImportedReplaced(added)
            else
              l10n.backupImported(added, skipped),
            if (keys) l10n.backupImportedKeys,
          ].join(' · '),
          false,
        ),
      BackupFailed(formatError: final error, detail: final detail) => (
          switch (error) {
            BackupError.notATafsiriBackup => l10n.backupErrorNotBackup,
            BackupError.notJson => l10n.backupErrorUnreadable,
            BackupError.unsupportedVersion => l10n.backupErrorTooNew,
            null => detail == null
                ? l10n.backupErrorFailed
                : '${l10n.backupErrorFailed} $detail',
          },
          true,
        ),
    };

    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: isError ? theme.colorScheme.errorContainer : null,
      ),
    );
  }
}
