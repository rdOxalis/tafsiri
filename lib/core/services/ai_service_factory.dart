import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../../features/settings/settings_controller.dart';
import 'ai_service.dart';
import 'claude_service.dart';
import 'mistral_service.dart';
import 'openai_service.dart';

/// Returns the [AiService] instance for the currently active provider.
/// Automatically updates when [settingsProvider] changes.
final aiServiceProvider = Provider<AiService>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final provider = settingsAsync.valueOrNull?.activeProvider ?? kDefaultProvider;

  return switch (provider) {
    kProviderClaude => ClaudeService(),
    kProviderOpenAI => OpenAiService(),
    _ => MistralService(),
  };
});
