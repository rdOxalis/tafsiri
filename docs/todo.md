# Tafsiri — Task Tracker

## In Progress

<!-- Move items here when actively working on them -->

---

## Backlog

### Phase 1 — Foundation
- [x] [1.1] S  `flutter create --org ke.darkman --project-name tafsiri .` — `applicationId = ke.darkman.tafsiri` ✓ (2026-04-10)
- [x] [1.2] S  Add all dependencies to `pubspec.yaml`; `intl` auf `^0.20.2` angepasst (flutter_localizations-Pin) (2026-04-10)
- [x] [1.3] S  Add Android permissions to `AndroidManifest.xml` (INTERNET, RECORD_AUDIO, CAMERA, READ_EXTERNAL_STORAGE maxSdk=32, READ_MEDIA_IMAGES) (2026-04-10)
- [x] [1.4] S  Create full `lib/` directory tree per spec (core/, features/, shared/, l10n/) (2026-04-10)
- [x] [1.5] S  Create `docs/` scaffold — `todo.md`, `changelog.md`, `architecture.md`; `decisions.md` → `docs/decisions.md` (2026-04-10)
- [x] [1.6] S  Replace default counter app — `main.dart` mit `ProviderScope`, `app.dart` mit `TafsiriApp` (ConsumerWidget, Material3, teal) (2026-04-10)
- [x] [1.2b] S  `minSdk = 21` in `android/app/build.gradle.kts` (google_mlkit_text_recognition requirement) (2026-04-10)
- [x] [1.2c] S  `flutter pub get` — 101 Dependencies aufgelöst ✓ (2026-04-10)
- [x] [1.7] S  `flutter build apk --debug` ✓ — fixes: Java 17 (flutter config --jdk-dir), NDK 27.0.12077973, speech_to_text ^7.0.0 (2026-04-10)

### Phase 2 — Localisation
- [x] [2.1] S  `generate: true` in `pubspec.yaml` ✓; `l10n.yaml` created (2026-04-10)
- [x] [2.2] M  `lib/l10n/app_en_GB.arb` — 37 foundation strings across all screens (2026-04-10)
- [x] [2.3] M  9 ARB files created: sw, de, fr, nl, es, da, nb, sv, pl — note: `app_no.arb` → `app_nb.arb` per ADR-011; `app_en.arb` added as required fallback (2026-04-10)
- [x] [2.4] S  `flutter_localizations` wired into `MaterialApp` with `localeProvider` (2026-04-10)
- [x] [2.5] S  `LocaleNotifier` (Riverpod `AsyncNotifier`) in `lib/core/locale_notifier.dart`; `supportedAppLocales` const list (2026-04-10)
- [x] [2.6] S  `flutter gen-l10n` ✓; `flutter analyze` — no issues (2026-04-10)

### Phase 3 — Settings & Persistence
- [x] [3.1] M  `SettingsController` (Riverpod `AsyncNotifier`) — 6 prefs keys, `hasApiKeyForActiveProvider`, `activeApiKey` (2026-04-10)
- [x] [3.2] M  `settings_screen.dart` — API key fields (obscured + toggle), `SegmentedButton`, target/alt lang, locale dropdown, donate (2026-04-10)
- [x] [3.3] S  Warning banner rendered when `hasApiKeyForActiveProvider == false` (2026-04-10)
- [x] [3.4] S  Donate button with `url_launcher` + `kPayPalDonateUrl` (`https://paypal.me/CarlDarkman`) (2026-04-10)
- [x] [3.5] S  Locale dropdown connected to `LocaleNotifier` — live switch (2026-04-10)
- [x] [3.6] S  `MainScreen` with `NavigationBar` (Translator / History / Settings); placeholder screens for phases 6 + 8 (2026-04-10)
- [x] [3.7] M  8 unit tests for `SettingsController` — all green ✓ (2026-04-10)

### Phase 4 — AI Services
- [x] [4.1] S  `ai_service.dart` — abstract `AiService` + `AiApiException` + shared `buildPrompt()` (ADR-013 format) (2026-04-10)
- [x] [4.2] M  `ClaudeService` — Anthropic Messages API, model `claude-haiku-4-5-20251001` (2026-04-10)
- [x] [4.3] M  `OpenAiService` — Chat Completions API, model `gpt-4o-mini` (2026-04-10)
- [x] [4.4] M  `MistralService` — Mistral Chat API, model `mistral-small-latest` (2026-04-10)
- [x] [4.5] S  `aiServiceProvider` (Riverpod `Provider`) — switches on `active_provider` from settings (2026-04-10)
- [x] [4.6] L  12 unit tests (4 per service): happy path, 401, 4xx/5xx, header verification — all green ✓ (2026-04-10)
- [x] [4.7] S  API key masking via `maskApiKey()` from `constants.dart` in all `debugPrint` calls (2026-04-10)

### Phase 5 — Translation Core
- [x] [5.1] S  `TranslationEntry` model — `toMap()`/`fromMap()`, `copyWith()`, UTC ISO-8601 for `createdAt` (2026-04-10)
- [x] [5.2] M  `TranslatorController` (`Notifier<TranslatorState>`) — inputText, outputText, isLoading, `TranslatorError` enum, lastSourceLang (2026-04-10)
- [x] [5.3] M  `translate()` — reads settings, validates API key, calls `aiServiceProvider`, updates state (2026-04-10)
- [x] [5.4] M  `_extractSourceLang()` / `_extractTranslation()` — parse `LANG:xx\n` prefix per ADR-013 (2026-04-10)
- [x] [5.5] S  SQLite save stub: `// TODO(phase7): await _dao.insert(...)` in `translate()` (2026-04-10)
- [x] [5.6] M  10 unit tests for `TranslatorController` — all green ✓ (2026-04-10)

### Phase 6 — Translator UI
- [x] [6.1] S  `translator_screen.dart` — Column layout: InputArea / OutputArea / ActionBar (2026-04-10)
- [x] [6.2] M  `input_area.dart` — multiline TextField, paste + clear buttons, external sync via `ref.listen` (2026-04-10)
- [x] [6.3] M  `output_area.dart` — 4 states: empty hint / loading / error / result + copy button (2026-04-10)
- [x] [6.4] S  `action_bar.dart` — mic stub, image stub, FilledButton translate (disabled during loading) (2026-04-10)
- [x] [6.5] M  All widgets wired to `translatorProvider` via `ConsumerWidget`/`ConsumerStatefulWidget` (2026-04-10)
- [x] [6.6] S  `CircularProgressIndicator` in output area + inline in translate button during loading (2026-04-10)
- [x] [6.7] S  Error text in `colorScheme.error` colour; `TranslatorError` → localised string via switch (2026-04-10)
- [x] [6.8] S  `MainScreen` updated: `TranslatorScreen` live, history placeholder remains for Phase 8 (2026-04-10)
- [x] [6.9] M  6 widget tests for `TranslatorScreen` — all green ✓ (2026-04-10)

### Phase 7 — SQLite
- [x] [7.1] M  `db_helper.dart` — singleton, `CREATE TABLE` DDL, `onUpgrade` stub (ADR-014), test inject/reset helpers (2026-04-10)
- [x] [7.2] M  `translation_dao.dart` — `insert`, `getAll` (desc), `getFavourites`, `setFavourite`, `delete` (2026-04-10)
- [x] [7.3] S  `translationDaoProvider` (`FutureProvider`) in `dao_provider.dart` (2026-04-10)
- [x] [7.4] S  `TranslatorController.translate()` saves entry via `daoAsync.whenData()` after success (2026-04-10)
- [x] [7.5] M  8 DAO tests with `sqflite_common_ffi` in-memory DB; UTC ISO-8601 timestamps — all green ✓ (2026-04-10)

### Phase 8 — History Screen
- [x] [8.1] M  `HistoryController` (Riverpod `AsyncNotifier`) — load/reload, delete, toggleFavourite (2026-04-10)
- [x] [8.2] M  `history_screen.dart` — `ListView.builder` consuming `HistoryController` (2026-04-10)
- [x] [8.3] M  `history_list_item.dart` — source text (truncated), result (truncated), target lang, timestamp, provider badge, favourite star (2026-04-10)
- [x] [8.4] M  Reload-to-input: confirm dialog on tap → `TranslatorController.setInputText()` → navigate to Translator tab (2026-04-10)
- [x] [8.5] M  Swipe-to-delete: `Dismissible` → `dao.delete()` → `SnackBar` with undo (`dao.insert()`) (2026-04-10)
- [x] [8.6] S  Empty state widget when history list is empty (2026-04-10)
- [x] [8.7] S  `MainScreen` refactored to `ConsumerWidget` using `selectedTabProvider`; `_HistoryPlaceholder` removed (2026-04-10)

### Phase 9 — Favourites
- [x] [9.1] S  `favourites_filter.dart` — `FilterChip` toggling between All / Favourites (2026-04-10)
- [x] [9.2] S  `showFavouritesOnly` flag in `HistoryController`; `toggleFilter()` reloads with `dao.getFavourites()` or `dao.getAll()` (2026-04-10)
- [x] [9.3] M  Star icon tap in `HistoryListItem` → `controller.toggleFavourite(id)` (ADR-017: star icon over swipe to avoid gesture conflict) (2026-04-10)
- [x] [9.4] S  `HistoryScreen` updated: filter bar above list, `Expanded` wraps the async list (2026-04-10)

### Phase 10 — Voice Input (STT)
- [x] [10.1] M  `SpeechToText` lifecycle in `TranslatorController` — `_initStt()` (lazy via microtask), `toggleListening()`, `isSttAvailable`, `isListening` in state (2026-04-10)
- [x] [10.2] S  `kSttLocaleMap` const map (10 languages → BCP-47) already in `constants.dart` (2026-04-10)
- [x] [10.3] M  Microphone button in `action_bar.dart` — `mic_none` icon idle, `mic` icon + error colour while recording, disabled when unavailable or loading (2026-04-10)
- [x] [10.4] S  Auto-translate on STT `finalResult == true` → calls `translate()` (2026-04-10)
- [x] [10.5] S  STT locale fallback: `kSttLocaleMap[lastSourceLang]` → null → `speech_to_text` uses device locale (2026-04-10)
- [x] [10.6] S  `RECORD_AUDIO` runtime permission handled by `speech_to_text` built-in flow (2026-04-10)

### Phase 11 — Image Input (OCR)
- [x] [11.1] M  `image_picker` bottom sheet with Camera / Gallery options in `ActionBar` (2026-04-10)
- [x] [11.2] M  `google_mlkit_text_recognition` OCR pipeline in `pickImageAndRecognize()` (2026-04-10)
- [x] [11.3] S  OCR result placed in input field — no auto-translate per ADR-015 (2026-04-10)
- [x] [11.4] S  OCR failure: `ocrError` state flag → `ref.listen` in `TranslatorScreen` → SnackBar (2026-04-10)
- [x] [11.5] S  `CAMERA` runtime permission handled by `image_picker` built-in flow (2026-04-10)
- [x] [11.6] S  `ocrSourceCamera` + `ocrSourceGallery` added to all 11 ARB files (2026-04-10)

### Phase 12 — Polish & Release Prep
- [x] [12.1] M  Error-handling audit: noApiKey/apiError/networkError in OutputArea; OCR SnackBar; STT button disabled when unavailable — all wired (2026-04-10)
- [x] [12.2] S  `lib/core/constants.dart` — all magic strings, PayPal URL, STT locale map complete (2026-04-10)
- [x] [12.3] S  Final `ThemeData` in `app.dart` — dark/light scheme, `ThemeMode.system`, AppBar/Card/Input/SnackBar themes (2026-04-10)
- [x] [12.4] S  Launcher icon — SVG designed (two speech bubbles + arrow, teal), exported to 1024×1024 PNG, all mipmap densities generated via `flutter_launcher_icons` (2026-04-10)
- [x] [12.5] M  l10n completeness pass — all 11 ARB files verified (43 keys each, en/en_GB 85 with @-metadata) (2026-04-10)
- [x] [12.6] S  `flutter analyze` — zero warnings/lints ✓ (2026-04-10)
- [x] [12.7] M  Full test suite — 44/44 passing (2026-04-10)
- [x] [12.8] M  `docs/architecture.md` — Mermaid diagrams, module table, DB schema, API table, prompt template (2026-04-10)
- [x] [12.9] S  `docs/changelog.md` — v1.0.0 entry complete (2026-04-10)
- [x] [12.10] S `flutter build apk --release` ✓ 42.7 MB — ProGuard rules added for MLKit + Play Core; debug keystore used (ADR-016)

---

## Done

- [x] v1.0.3 — Bug fixes, UX improvements, prompt overhaul (2026-04-11)
  - History reload loads both input and output
  - Settings persistence fixed (onChanged instead of onSubmitted)
  - STT language setting added
  - Swipe-right-to-favourite + visible delete button in history
  - AI prompt split into system/user roles; max_tokens → 4096
  - Input area rounded corners fixed; paste button moved to action bar

- [x] v1.0.2 — Post-test UI polish (2026-04-11)
  - Translator screen: "Tafsiri" heading, action bar in the middle, rounded containers for input/output
  - Settings: only active provider's API key field shown
  - Paste button removed; clear button as overlay
  - 44/44 tests grün · `flutter analyze` clean

- [x] v1.0.0 — alle 12 Phasen abgeschlossen (2026-04-10)
  - Foundation, Localisation, Settings, AI Services, Translation Core, Translator UI,
    SQLite, History, Favourites, Voice Input (STT), Image Input (OCR), Polish & Release Prep
  - 44/44 Tests grün · `flutter analyze` clean · Debug-APK gebaut · Icon generiert
