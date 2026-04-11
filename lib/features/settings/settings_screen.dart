import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/locale_notifier.dart';
import '../../l10n/app_localizations.dart';
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

              // --- AI Provider ---
              _SectionHeader(l10n.providerLabel),
              const SizedBox(height: 8),
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

              const Divider(height: 32),

              // --- API Key for active provider only ---
              if (settings.activeProvider == kProviderMistral)
                _ApiKeyField(
                  label: l10n.apiKeyMistral,
                  controller: _mistralController,
                  visible: _mistralVisible,
                  onToggleVisibility: () =>
                      setState(() => _mistralVisible = !_mistralVisible),
                  onSubmitted: (v) => ref
                      .read(settingsProvider.notifier)
                      .setApiKey(kProviderMistral, v),
                ),
              if (settings.activeProvider == kProviderClaude)
                _ApiKeyField(
                  label: l10n.apiKeyClaude,
                  controller: _claudeController,
                  visible: _claudeVisible,
                  onToggleVisibility: () =>
                      setState(() => _claudeVisible = !_claudeVisible),
                  onSubmitted: (v) => ref
                      .read(settingsProvider.notifier)
                      .setApiKey(kProviderClaude, v),
                ),
              if (settings.activeProvider == kProviderOpenAI)
                _ApiKeyField(
                  label: l10n.apiKeyOpenAI,
                  controller: _openAiController,
                  visible: _openAiVisible,
                  onToggleVisibility: () =>
                      setState(() => _openAiVisible = !_openAiVisible),
                  onSubmitted: (v) => ref
                      .read(settingsProvider.notifier)
                      .setApiKey(kProviderOpenAI, v),
                ),

              const Divider(height: 32),

              // --- Translation Languages ---
              _SectionHeader(l10n.targetLanguageLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _targetLangController,
                decoration:
                    InputDecoration(labelText: l10n.targetLanguageLabel),
                onSubmitted: (v) => ref
                    .read(settingsProvider.notifier)
                    .setTargetLanguage(v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _altLangController,
                decoration:
                    InputDecoration(labelText: l10n.altLanguageLabel),
                onSubmitted: (v) =>
                    ref.read(settingsProvider.notifier).setAltLanguage(v),
              ),

              const Divider(height: 32),

              // --- App Language ---
              _SectionHeader(l10n.appLanguageLabel),
              const SizedBox(height: 8),
              _LocaleDropdown(),

              const Divider(height: 32),

              // --- Donate ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.coffee_outlined),
                title: Text(l10n.donateButton),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDonateDialog(context, l10n),
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
  final ValueChanged<String> onSubmitted;

  const _ApiKeyField({
    required this.label,
    required this.controller,
    required this.visible,
    required this.onToggleVisibility,
    required this.onSubmitted,
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
      onSubmitted: onSubmitted,
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
