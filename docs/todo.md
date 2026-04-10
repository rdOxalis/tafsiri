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
- [ ] [8.1] M  `HistoryController` (Riverpod `AsyncNotifier`) — load/reload, delete, toggleFavourite
- [ ] [8.2] M  `history_screen.dart` — `ListView.builder` consuming `HistoryController`
- [ ] [8.3] M  `history_list_item.dart` — source text (truncated), result (truncated), target lang, timestamp, provider badge, favourite star
- [ ] [8.4] M  Reload-to-input: confirm dialog on tap → `TranslatorController.setInputText()` → navigate to Translator tab
- [ ] [8.5] M  Swipe-to-delete: `Dismissible` → `dao.delete()` → `SnackBar` with undo (`dao.insert()`)
- [ ] [8.6] S  Empty state widget when history list is empty

### Phase 9 — Favourites
- [ ] [9.1] S  `favourites_filter.dart` — `FilterChip` toggling between All / Favourites
- [ ] [9.2] S  `showFavouritesOnly` flag in `HistoryController`; passes `isFavourite: true` to DAO query
- [ ] [9.3] M  Star icon tap in `HistoryListItem` → `controller.toggleFavourite(id)` (ADR-017: star icon over swipe to avoid gesture conflict)
- [ ] [9.4] S  End-to-end verification: mark favourite → filter → only favourites shown

### Phase 10 — Voice Input (STT)
- [ ] [10.1] M  `SpeechToText` lifecycle in `TranslatorController` — `init()`, `startListening()`, `stopListening()`, `isAvailable`
- [ ] [10.2] S  `_sttLocaleMap` const map (10 languages → BCP-47) in `constants.dart`
- [ ] [10.3] M  Microphone button in `action_bar.dart` — disabled state, recording state indicator (visual feedback)
- [ ] [10.4] S  Auto-translate on STT `finalResult == true` → call `controller.translate()`
- [ ] [10.5] S  STT locale fallback to `SpeechToText.systemLocale()` if `source_lang` unknown
- [ ] [10.6] S  `RECORD_AUDIO` runtime permission via `speech_to_text` built-in flow (no extra package)

### Phase 11 — Image Input (OCR)
- [ ] [11.1] M  `image_picker` integration — bottom sheet with Camera / Gallery options
- [ ] [11.2] M  `google_mlkit_text_recognition` OCR pipeline — pick image → extract text
- [ ] [11.3] S  Place OCR result in input field via `TranslatorController.setInputText()` — no auto-translate (ADR-015)
- [ ] [11.4] S  OCR failure: show localised error message, leave input unchanged
- [ ] [11.5] S  `CAMERA` runtime permission handling
- [ ] [11.6] S  MLKit model download indicator on first use

### Phase 12 — Polish & Release Prep
- [ ] [12.1] M  Full error-handling audit: no-API-key snackbar, 4xx/5xx in output area, network error, OCR fail, STT unavailable
- [ ] [12.2] S  `lib/core/constants.dart` — PayPal URL, provider names, `_sttLocaleMap`, all magic strings
- [ ] [12.3] S  Final `ThemeData` in `app.dart` — Material3, colour scheme, typography
- [ ] [12.4] S  Launcher icon — replace default Flutter icon (`mipmap-*` folders or `flutter_launcher_icons`)
- [ ] [12.5] M  Final l10n completeness pass — all 10 ARB files, 100% of strings present
- [ ] [12.6] S  `flutter analyze` — zero warnings/lints
- [ ] [12.7] M  Full test suite run; meaningful coverage on controller and DAO layers
- [ ] [12.8] M  `docs/architecture.md` — final Mermaid data-flow diagram, module table, DB schema
- [ ] [12.9] S  `docs/changelog.md` — v1.0.0 entry
- [ ] [12.10] S `flutter build apk --release` — verify signing config (keystore never committed, ADR-016)

---

## Done

<!-- Items moved here with completion date, e.g.:
- [x] [1.1] flutter create (2026-04-10)
-->
