import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tafsiri/l10n/app_localizations.dart';
import 'core/locale_notifier.dart';
import 'shared/widgets/main_screen.dart';

class TafsiriApp extends ConsumerWidget {
  const TafsiriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('en', 'GB');

    return MaterialApp(
      title: 'Tafsiri',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('sw'),
        Locale('de'),
        Locale('fr'),
        Locale('nl'),
        Locale('es'),
        Locale('da'),
        Locale('nb'),
        Locale('sv'),
        Locale('pl'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
