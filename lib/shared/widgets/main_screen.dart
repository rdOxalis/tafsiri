import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/settings_screen.dart';
import '../../l10n/app_localizations.dart';

// Placeholder screens for Phase 6 and 8
class _TranslatorPlaceholder extends StatelessWidget {
  const _TranslatorPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Translator — coming in Phase 6'));
}

class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('History — coming in Phase 8'));
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  static const _screens = [
    _TranslatorPlaceholder(),
    _HistoryPlaceholder(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.translate),
            label: l10n.navTranslator,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
