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
- AI service layer: abstract `AiService` + `AiApiException`; `ClaudeService`, `OpenAiService`, `MistralService`
- Shared `buildPrompt()` with `LANG:xx` prefix protocol (ADR-013)
- `aiServiceProvider` (Riverpod) auto-selects backend from active provider setting
- API key masking in all debug output; 12 service unit tests — all passing
- `TranslationEntry` model with `toMap()`/`fromMap()`/`copyWith()`
- `TranslatorController` (`Notifier`): translate flow, LANG prefix parsing, `TranslatorError` enum
- 10 unit tests for `TranslatorController` — all passing
- Translator UI: `InputArea`, `OutputArea`, `ActionBar`, `TranslatorScreen`
- Output area: 4 states (hint/loading/error/result), copy to clipboard, error colours
- Action bar: mic stub, image stub, FilledButton translate with loading state
- Input area: external state sync via `ref.listen` for history reload (Phase 8)
- 6 widget tests for `TranslatorScreen` — all passing
- SQLite layer: `DbHelper` singleton, `TranslationDao` (insert/getAll/getFavourites/setFavourite/delete)
- `translationDaoProvider` (FutureProvider); save-after-translate wired in `TranslatorController`
- 8 DAO unit tests with in-memory SQLite (`sqflite_common_ffi`) — all passing
- PayPal donate URL set to `https://paypal.me/CarlDarkman`

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
