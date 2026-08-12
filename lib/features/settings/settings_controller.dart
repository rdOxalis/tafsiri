import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class SettingsState {
  final String apiKeyMistral;
  final String apiKeyClaude;
  final String apiKeyOpenAI;
  final String activeProvider;
  final String targetLanguage;
  final String altLanguage;
  final String sttLanguage; // ISO-639-1 code, empty = auto
  final bool correctionMode; // ADR-033

  const SettingsState({
    required this.apiKeyMistral,
    required this.apiKeyClaude,
    required this.apiKeyOpenAI,
    required this.activeProvider,
    required this.targetLanguage,
    required this.altLanguage,
    required this.sttLanguage,
    this.correctionMode = false,
  });

  const SettingsState.defaults()
      : apiKeyMistral = '',
        apiKeyClaude = '',
        apiKeyOpenAI = '',
        activeProvider = kDefaultProvider,
        targetLanguage = kDefaultTargetLanguage,
        altLanguage = kDefaultAltLanguage,
        sttLanguage = '',
        correctionMode = false;

  bool get hasApiKeyForActiveProvider {
    switch (activeProvider) {
      case kProviderMistral:
        return apiKeyMistral.isNotEmpty;
      case kProviderClaude:
        return apiKeyClaude.isNotEmpty;
      case kProviderOpenAI:
        return apiKeyOpenAI.isNotEmpty;
      default:
        return false;
    }
  }

  String get activeApiKey {
    switch (activeProvider) {
      case kProviderMistral:
        return apiKeyMistral;
      case kProviderClaude:
        return apiKeyClaude;
      case kProviderOpenAI:
        return apiKeyOpenAI;
      default:
        return '';
    }
  }

  SettingsState copyWith({
    String? apiKeyMistral,
    String? apiKeyClaude,
    String? apiKeyOpenAI,
    String? activeProvider,
    String? targetLanguage,
    String? altLanguage,
    String? sttLanguage,
    bool? correctionMode,
  }) {
    return SettingsState(
      apiKeyMistral: apiKeyMistral ?? this.apiKeyMistral,
      apiKeyClaude: apiKeyClaude ?? this.apiKeyClaude,
      apiKeyOpenAI: apiKeyOpenAI ?? this.apiKeyOpenAI,
      activeProvider: activeProvider ?? this.activeProvider,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      altLanguage: altLanguage ?? this.altLanguage,
      sttLanguage: sttLanguage ?? this.sttLanguage,
      correctionMode: correctionMode ?? this.correctionMode,
    );
  }
}

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      apiKeyMistral: prefs.getString(kPrefApiKeyMistral) ?? '',
      apiKeyClaude: prefs.getString(kPrefApiKeyClaude) ?? '',
      apiKeyOpenAI: prefs.getString(kPrefApiKeyOpenAI) ?? '',
      activeProvider: prefs.getString(kPrefActiveProvider) ?? kDefaultProvider,
      targetLanguage:
          prefs.getString(kPrefTargetLanguage) ?? kDefaultTargetLanguage,
      altLanguage: prefs.getString(kPrefAltLanguage) ?? kDefaultAltLanguage,
      sttLanguage: prefs.getString(kPrefSttLanguage) ?? '',
      correctionMode: prefs.getBool(kPrefCorrectionMode) ?? false,
    );
  }

  Future<void> setApiKey(String provider, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = switch (provider) {
      kProviderMistral => kPrefApiKeyMistral,
      kProviderClaude => kPrefApiKeyClaude,
      kProviderOpenAI => kPrefApiKeyOpenAI,
      _ => throw ArgumentError('Unknown provider: $provider'),
    };
    await prefs.setString(prefKey, key);
    state = AsyncData(state.requireValue.copyWith(
      apiKeyMistral: provider == kProviderMistral ? key : null,
      apiKeyClaude: provider == kProviderClaude ? key : null,
      apiKeyOpenAI: provider == kProviderOpenAI ? key : null,
    ));
  }

  Future<void> setActiveProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefActiveProvider, provider);
    state = AsyncData(state.requireValue.copyWith(activeProvider: provider));
  }

  Future<void> setTargetLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefTargetLanguage, language);
    state = AsyncData(state.requireValue.copyWith(targetLanguage: language));
  }

  Future<void> setAltLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefAltLanguage, language);
    state = AsyncData(state.requireValue.copyWith(altLanguage: language));
  }

  Future<void> setSttLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefSttLanguage, code);
    state = AsyncData(state.requireValue.copyWith(sttLanguage: code));
  }

  Future<void> setCorrectionMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefCorrectionMode, enabled);
    state = AsyncData(state.requireValue.copyWith(correctionMode: enabled));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
