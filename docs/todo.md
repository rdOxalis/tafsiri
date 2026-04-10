# Tafsiri — Task Tracker

## In Progress

- [ ] [1.7] S  `flutter build apk --debug` — abgebrochen wegen schlechter Netzwerkverbindung; neu starten im neuen Netzwerk

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
- [ ] [1.7] S  `flutter build apk --debug` — **ausstehend** (Netzwerkwechsel nötig)

### Phase 2 — Localisation
- [ ] [2.1] S  Add `generate: true` to `pubspec.yaml`; create `l10n.yaml` (`arb-dir: lib/l10n`, template: `app_en_GB.arb`, output-class: `AppLocalizations`)
- [ ] [2.2] M  Create `lib/l10n/app_en_GB.arb` as canonical template with all foundation strings (buttons, labels, errors, settings, history, donate)
- [ ] [2.3] M  Create remaining 9 ARB files (`sw`, `de`, `fr`, `nl`, `es`, `da`, `no`, `sv`, `pl`) with full translations
- [ ] [2.4] S  Wire `flutter_localizations` into `MaterialApp` (`localizationsDelegates`, `supportedLocales`, `locale` from Riverpod)
- [ ] [2.5] S  Create `LocaleNotifier` (Riverpod) backed by `shared_preferences` key `app_locale`; exposes `setLocale(String code)`
- [ ] [2.6] S  Run `flutter gen-l10n`; confirm `AppLocalizations` is importable; smoke test

### Phase 3 — Settings & Persistence
- [ ] [3.1] M  Create `SettingsController` (Riverpod) that loads/saves all 7 settings keys on init
- [ ] [3.2] M  Build `settings_screen.dart`: 3× API key input (obscured + visibility toggle), provider `SegmentedButton`, target/alt lang text fields, locale dropdown, donate button
- [ ] [3.3] S  Warning banner when active provider has no API key set
- [ ] [3.4] S  Donate button with `url_launcher` + PayPal URL from `constants.dart`; localised label via ARB
- [ ] [3.5] S  Connect locale dropdown to `LocaleNotifier` — change is live immediately
- [ ] [3.6] S  Navigation to/from Settings screen (bottom nav or app bar action)
- [ ] [3.7] M  Unit tests for `SettingsController` — verify all keys persist and reload correctly

### Phase 4 — AI Services
- [ ] [4.1] S  Create `lib/core/services/ai_service.dart` — abstract `AiService` interface with `translate()` method
- [ ] [4.2] M  Implement `ClaudeService` (Anthropic Messages API, model `claude-haiku-4-5`)
- [ ] [4.3] M  Implement `OpenAiService` (OpenAI Chat Completions API, model `gpt-4o-mini`)
- [ ] [4.4] M  Implement `MistralService` (Mistral Chat API, model `mistral-small-latest`)
- [ ] [4.5] S  `AiServiceFactory` / Riverpod provider — reads `active_provider` from settings, returns correct `AiService`
- [ ] [4.6] L  Unit tests for all three services with mocked `http.Client` (happy path + 4xx/5xx)
- [ ] [4.7] S  API key masking (`sk-****`) in all service log/debug output

### Phase 5 — Translation Core
- [ ] [5.1] S  Create `TranslationEntry` model in `lib/shared/models/translation_entry.dart` with `toMap()`/`fromMap()`
- [ ] [5.2] M  Create `TranslatorController` (Riverpod `AsyncNotifier`) — input text, output text, loading, error, `lastSourceLang`
- [ ] [5.3] M  Implement `translate()`: read settings, build prompt (with `LANG:xx\n` prefix per ADR-013), call `AiService`, strip prefix, update state
- [ ] [5.4] M  Extract `lastSourceLang` from `LANG:xx\n` prefix in AI response; store in controller state
- [ ] [5.5] S  Stub `save-to-SQLite` hook in controller (callback / TODO comment) — completed in Phase 7
- [ ] [5.6] M  Unit tests for `TranslatorController` using mocked `AiService`

### Phase 6 — Translator UI
- [ ] [6.1] S  `translator_screen.dart` — Scaffold + layout skeleton
- [ ] [6.2] M  `input_area.dart` — multiline `TextField`, clear button, clipboard paste button
- [ ] [6.3] M  `output_area.dart` — read-only display, copy-to-clipboard, empty/loading/error/result states
- [ ] [6.4] S  `action_bar.dart` — microphone button (stub), image button (stub), translate button; all localised
- [ ] [6.5] M  Wire all widgets to `TranslatorController` via `ConsumerWidget` / `ref.watch`
- [ ] [6.6] S  Loading indicator (`CircularProgressIndicator`) in output area while `isLoading == true`
- [ ] [6.7] S  Error display in output area (red-tinted text / error state)
- [ ] [6.8] S  Bottom navigation bar — Translator / History / Settings tabs
- [ ] [6.9] M  Widget tests for translator screen using mocked controller

### Phase 7 — SQLite
- [ ] [7.1] M  `db_helper.dart` — SQLite init, `CREATE TABLE` DDL per spec, `onUpgrade` stub (ADR-014)
- [ ] [7.2] M  `translation_dao.dart` — `insert`, `getAll` (desc), `getByFavourite`, `setFavourite`, `delete`
- [ ] [7.3] S  Riverpod provider for `TranslationDao` (lazy singleton)
- [ ] [7.4] S  Complete save-after-translate in `TranslatorController` (Phase 5.5 stub)
- [ ] [7.5] M  Unit tests for DAO with in-memory SQLite (`openDatabase(':memory:')`); use `DateTime.now().toUtc().toIso8601String()` for `created_at`

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
