# Changelog

All notable changes to Tafsiri will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

---

## [1.0.6] - 2026-06-14

### Removed
- **Image-to-text (OCR) feature** — removed `google_mlkit_text_recognition`, `image_picker`, the image button + camera/gallery sheet, the OCR controller logic and state, and the `imageButton`/`errorOcrFailed`/`ocrSource*` strings from all ARB files. ML Kit pulls proprietary `com.google.mlkit:*` artifacts, which F-Droid's scanner strips by policy — making the app un-buildable in the official F-Droid repo. This was the real, fundamental cause behind the failing F-Droid submission (ADR-028). Voice input, AI translation, history, favourites and all other features are unaffected. APK shrank from ~84 MB to ~53 MB.
- `CAMERA`, `READ_EXTERNAL_STORAGE` and `READ_MEDIA_IMAGES` permissions (only used by image input).
- ML Kit-specific ProGuard `-dontwarn` rules. (The Google Play Core `-dontwarn` rules were **kept** — they are required by Flutter's own `PlayStoreDeferredComponentManager`, not by ML Kit; removing them broke R8.)

### Fixed
- **F-Droid build (MR #39249):** added `android.builtInKotlin=false` alongside `android.newDsl=false` in `android/gradle.properties`. F-Droid's buildserver uses a bleeding-edge AGP 9 / Gradle 9 toolchain; opting out of the new DSL alone left a `kotlin-android` "extension already registered" error. Both flags are needed (ADR-027). Verified by reproducing AGP 9.0.1 + Gradle 9.1.0 + JDK 21 locally.

### Changed
- F-Droid recipe builds tag `v1.0.6` (versionCode 6); store descriptions and screenshots added; `docs/FDROID.md` corrected and expanded.

---

## [1.0.5] - 2026-05-28

### Added
- App version number displayed at the bottom of the Settings screen (loaded via `package_info_plus`, shows `v1.0.x`)
- "Get API key →" link button below the active provider's API key field — opens the provider's API key console in the browser (ADR-025)
- Mistral free-tier hint shown below the Mistral API key field — "Mistral offers a free tier — no credit card required" in all 11 locales (ADR-025)
- `package_info_plus ^8.0.0` dependency added
- Detailed error messages in output area: HTTP status code + human-readable cause (401 invalid key, 429 rate limit, 5xx unavailable) for `apiError`; truncated exception message for unexpected errors
- F-Droid submission: `fdroid/metadata/com.njerahouse.tafsiri.yml`, `fastlane/metadata/android/` (en-US, de-DE, sw), `.github/workflows/release.yml`, `docs/FDROID.md` (ADR-026)
- Git tag `v1.0.5` pushed; F-Droid MR opened: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249

### Changed
- Release signing config in `build.gradle.kts` is now conditional on `key.properties` existing — falls back to debug keystore gracefully when the file is absent
- `build.gradle.kts`: Java compatibility raised from VERSION_11 to VERSION_17; `dependenciesInfo { includeInApk = false; includeInBundle = false }` added (required for F-Droid)
- `pubspec.yaml` version bumped to `1.0.5+5`

---

## [1.0.4] - 2026-04-29

### Added
- Translation philosophy info button (ⓘ) as leftmost item in the ActionBar — tapping opens a dialog explaining the bidirectional translation logic (primary ↔ secondary language) with the actual language names shown as tappable links that navigate to Settings (ADR-023)
- `translationLanguagesSection`, `translationInfoTitle`, `translationInfoPart1–4`, `providerSubtitle` ARB strings added to all 11 locales
- AI Provider section now shows subtitle "bring your own API-Key" (de/en) with native translations for the other 8 locales

### Changed
- Settings screen section order: Translation Languages → Speech Recognition (Microphone) → App Language → AI Provider → API Key → Donate
- "Target Language" renamed to "Primary Language" / "Primärsprache" across all 11 locales
- "Alternative Language" renamed to "Secondary Language" / "Sekundärsprache" across all 11 locales
- "Voice Input Language" renamed to "Speech Recognition (Microphone)" / "Spracherkennung (Mikrofon)" across all 11 locales
- Info dialog language names now loaded via `ref.watch` in `build()` instead of `ref.read` at tap-time — fixes empty placeholders on first launch

### Fixed
- History tab not showing first translation after app start — SQLite insert is now `await`ed directly in `translate()` before `ref.invalidate(historyProvider)`, replacing the fire-and-forget `whenData` pattern
- Info dialog showing "…" placeholders for language names on first launch (settings not yet loaded at tap-time)

---

## [1.0.3] - 2026-04-11

### Added
- STT voice input language setting in Settings screen — dropdown with Auto + 10 supported languages; overrides the auto-detected source language when set. All 11 ARB files updated.
- Swipe-right-to-favourite gesture on history list items (`Dismissible` with `confirmDismiss: false` so the card stays in place)
- Visible delete button (`delete_outline`) on each history list item alongside the star

### Changed
- History reload now loads both source text (input area) and result text (output area), not just source text
- Settings persistence: all text fields now use `onChanged` instead of `onSubmitted` — values are saved on every keystroke, not only on keyboard Done press
- Paste/clipboard button moved from input area to the action bar (between Image and Translate buttons)
- AI prompt split into system role (instructions) and user message (text only) for all three providers — Claude uses top-level `system` field, OpenAI/Mistral use `role: system` in the messages array
- `max_tokens` increased from 1024 to 4096 for all providers — prevents truncation of longer OCR texts
- System prompt strengthened: explicit rule to translate the ENTIRE text without summarising, shortening, or paraphrasing
- Input area rounded corners fixed (`clipBehavior: Clip.antiAlias` on the container)

### Fixed
- History reload was loading only source text and leaving the output area empty
- Settings API keys and language fields were not persisted when navigating away without pressing Done
- `TextEditingController` in InputArea now initialised with current state so history-reloaded text is visible immediately after tab switch

---

## [1.0.2] - 2026-04-11

### Changed
- Translator screen redesigned: "Tafsiri" heading above input area; action bar (Mic/Image/Translate) moved to the middle between input and output areas
- Input area: replaced Card with a full-height rounded container (`surfaceContainerHighest`), removed paste/clipboard button, clear button repositioned as overlay in top-right corner
- Output area: same rounded container style as input area, copy button overlay in top-right corner; consistent visual language across both panels
- Settings screen: only the API key field for the currently active provider is shown — switching provider shows the corresponding field

### Removed
- Paste/clipboard button from input area (clipboard → manual paste via long-press is the standard Android pattern)

---

## [1.0.1] - 2026-04-10

### Fixed
- Release APK build: R8 minifier failed on missing MLKit optional script-recognizer classes (Chinese, Devanagari, Japanese, Korean) and Google Play Core split-install classes — added `-dontwarn` rules to `android/app/proguard-rules.pro`
- `isMinifyEnabled = true` explicitly set in release build type with `proguardFiles` reference
- `flutter build apk --release` now succeeds: 42.7 MB signed with debug keystore

---

## [1.0.0] - 2026-04-10

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
- `HistoryController` (`AsyncNotifier`) with `delete` (returns entry for undo), `restore`, `toggleFavourite`, `reload`
- `HistoryScreen` with `ListView.builder`, `Dismissible` swipe-to-delete, undo `SnackBar`, empty-state widget
- `HistoryListItem` card: source/result text (2-line truncated), provider badge (C/G/M), target lang, timestamp, star toggle
- Reload-to-input: confirm dialog on history tap → loads `sourceText` into translator, navigates to Translator tab
- `selectedTabProvider` (`StateProvider<int>`) for cross-widget tab navigation
- `MainScreen` refactored from `ConsumerStatefulWidget` to `ConsumerWidget` backed by `selectedTabProvider`
- `FavouritesFilter` widget: All / Favourites `FilterChip` row at top of history screen
- `HistoryController.toggleFilter()` switches between `dao.getAll()` and `dao.getFavourites()`
- Star icon in `HistoryListItem` wired to `toggleFavourite(id)` with live optimistic state update
- Voice input (STT): `TranslatorController` holds `SpeechToText` instance, `toggleListening()`, `isSttAvailable`/`isListening` state fields
- STT locale derived from `lastSourceLang` via `kSttLocaleMap`; falls back to device locale when unknown
- Microphone button: idle shows `mic_none`, active shows `mic` in error colour; disabled when STT unavailable
- Auto-translate triggered on `finalResult == true`; partial words shown live in input field
- `SpeechListenOptions` used for `cancelOnError` + `partialResults` (speech_to_text v7 API)
- Image input (OCR): `ActionBar` bottom sheet (Camera / Gallery) → `pickImageAndRecognize()` in controller
- `google_mlkit_text_recognition` pipeline: pick image → `TextRecognizer.processImage` → set input field
- No auto-translate on OCR result (ADR-015); empty result or error shows localised SnackBar
- `ocrError` transient state flag; `TranslatorScreen` upgraded to `ConsumerWidget` with `ref.listen`
- `isOcrProcessing` drives spinner on image button and disables it during processing
- `ocrSourceCamera` / `ocrSourceGallery` strings added to all 11 ARB files
- Launcher icon: two speech bubbles with translation arrow on teal background (SVG source in `assets/icon/`), all Android mipmap densities generated via `flutter_launcher_icons`
- Dark theme support: `ThemeData` for both light and dark brightness, `ThemeMode.system`
- Refined `AppBarTheme` (elevation 0, `scrolledUnderElevation: 1`), `CardThemeData`, `InputDecorationTheme`, floating `SnackBarThemeData`

### Changed
- `[1.0.0]` first release — all 12 phases complete

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
