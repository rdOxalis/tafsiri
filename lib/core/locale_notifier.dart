import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'app_locale';

const List<(String code, String label)> supportedAppLocales = [
  ('en_GB', 'English (UK)'),
  ('sw', 'Kiswahili'),
  ('de', 'Deutsch'),
  ('fr', 'Français'),
  ('nl', 'Nederlands'),
  ('es', 'Español'),
  ('da', 'Dansk'),
  ('nb', 'Norsk'),
  ('sv', 'Svenska'),
  ('pl', 'Polski'),
];

Locale _codeToLocale(String code) {
  if (code.contains('_')) {
    final parts = code.split('_');
    return Locale(parts[0], parts[1]);
  }
  return Locale(code);
}

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) return _codeToLocale(code);
    return const Locale('en', 'GB');
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    state = AsyncData(_codeToLocale(code));
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
