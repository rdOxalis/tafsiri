# Changelog

All notable changes to Tafsiri will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- Project scaffold and documentation structure (`docs/`)
- Flutter project created (`ke.darkman.tafsiri`, minSdk 21, Material3)
- All production and dev dependencies added to `pubspec.yaml`
- Android permissions configured (INTERNET, RECORD_AUDIO, CAMERA, storage)
- `lib/` directory tree per spec (core, features, shared, l10n)
- Minimal app shell: `ProviderScope` + `TafsiriApp` (ConsumerWidget, teal theme)
- `flutter pub get` resolves cleanly; `flutter build apk --debug` succeeds
- NDK upgraded to 27.0.12077973; `speech_to_text` upgraded to ^7.0.0; Flutter configured with Java 17
- Localisation scaffold: 10 ARB files (en_GB, en, sw, de, fr, nl, es, da, nb, sv, pl), 37 foundation strings
- `AppLocalizations` generated via `flutter gen-l10n`; wired into `MaterialApp`
- `LocaleNotifier` (Riverpod) for live locale switching backed by `shared_preferences`
- Settings screen: API key inputs, provider selector, language fields, locale dropdown, donate button
- `SettingsController` (AsyncNotifier) managing all 6 SharedPreferences keys
- `MainScreen` with bottom `NavigationBar` (Translator / History / Settings)
- `lib/core/constants.dart` with all prefs keys, provider names, STT locale map, PayPal URL placeholder
- 8 unit tests for `SettingsController` — all passing

---

<!-- Template for releases:

## [1.0.0] - YYYY-MM-DD

### Added
-

### Changed
-

### Fixed
-

### Removed
-

-->
