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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!settings.hasApiKeyForActiveProvider)
                  _WarningBanner(message: l10n.warningNoApiKey),

                // --- Provider ---
                const SizedBox(height: 16),
                Text(l10n.providerLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _ProviderSelector(
                  selected: settings.activeProvider,
                  onChanged: (p) =>
                      ref.read(settingsProvider.notifier).setActiveProvider(p),
                ),

                // --- API Keys ---
                const SizedBox(height: 24),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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

                // --- Languages ---
                const SizedBox(height: 24),
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

                // --- App Language ---
                const SizedBox(height: 24),
                Text(l10n.appLanguageLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _LocaleDropdown(),

                // --- Donate ---
                const SizedBox(height: 40),
                _DonateButton(label: l10n.donateButton),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
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

class _ProviderSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ProviderSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: kProviderMistral, label: Text('Mistral')),
        ButtonSegment(value: kProviderClaude, label: Text('Claude')),
        ButtonSegment(value: kProviderOpenAI, label: Text('ChatGPT')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
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

class _DonateButton extends StatelessWidget {
  final String label;
  const _DonateButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.coffee),
        label: Text(label),
        onPressed: () async {
          final uri = Uri.parse(kPayPalDonateUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
