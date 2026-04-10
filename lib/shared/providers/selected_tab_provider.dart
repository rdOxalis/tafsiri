import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently selected bottom-navigation tab index.
/// 0 = Translator, 1 = History, 2 = Settings
final selectedTabProvider = StateProvider<int>((ref) => 0);
