# Tafsiri — Task Tracker

## In Progress

<!-- Move items here when actively working on them -->

- [ ] **(Android) Clipboard images for paste.** Ctrl+V / the paste button read images on Linux (ADR-040) and Windows (ADR-047); Android is the one left. Android carries images on the clipboard as `content://` URIs, which needs a small platform channel into `ClipboardManager` — the `ClipboardImageService` interface is already the seam. Worth doing: on a phone a screenshot is the most likely way an image arrives at all.

- [ ] **Close F-Droid MR #39249** (needs your GitLab login — one click): https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249 (ADR-030)

- [ ] **Finish the Windows pass.** The build itself is done and was produced by hand on Windows for the 1.0.11 release; image-to-text and the Cyrillic script path are verified end to end there (ADR-045, ADR-046), reading a full screenshot as well as a cropped phrase. Still unchecked on that machine: **the microphone**, which has a real chance of misbehaving because `speech_to_text_windows` is beta and has never been exercised (ADR-039); the history surviving a restart, which is the bundled `sqlite3.dll` working; backup save/restore opening the Windows file dialogs; and install → Start menu → uninstall including the keep-your-data prompt. (ADR-035)

---

## Backlog

- [ ] **(Windows) Bump the pinned SQLite version when it matters.** `windows/sqlite3.cmake` pins 3.53.4 with one SHA3-256 per architecture; a bump means editing four values from sqlite.org's download page. (ADR-035)
- [ ] **(Windows, optional) Code-sign the installer.** Unsigned, SmartScreen warns on first run. Needs a paid certificate. (ADR-035)
- [ ] **(Linux, optional) Distributable packaging.** `install.sh` covers per-user installation from source; a redistributable format (AppImage / Flatpak / .deb) for users without a Flutter SDK is still open. BluesoundPlayer's `flutter/package-linux.sh` is a starting point. (ADR-032)
- [ ] **(Windows) Bundle Tesseract into the installer.** Image-to-text works on Windows with a Tesseract the user installs themselves (verified end to end, ADR-045/046); bundling would remove that step. Unlike SQLite there is no tidy official zip with a published hash — the usual source (UB Mannheim) ships an installer `.exe`, so getting engine + trained data portable into our installer needs research. Ship `eng` plus the 12 UI languages in the `tessdata_fast` variant (~2–4 MB each, so roughly 30 MB); `bul` is the one that is genuinely load-bearing, since Cyrillic is unreadable without it. Consider `script/Latin` and `script/Cyrillic` for the script-detection retry as well — they are ~28 MB each, so weigh that against the installer size rather than adding them by reflex. (ADR-037)
- [ ] **(Optional) Preprocess images before recognition.** Tesseract is strong on flat scans and weak on angled, badly lit phone photos. Greyscale, contrast and deskew before handing the file over is the obvious next quality lever, and would let the confidence gate reject less often. (ADR-037)
- [ ] **(Optional) Tune the confidence threshold.** 60 is a first guess; only real-world images can tell whether it rejects too much or too little. (ADR-037)
- [ ] **(Later) Replace ML Kit with Tesseract on Android.** Would drop the proprietary blob that blocks official F-Droid (ADR-028, ADR-030) and most of the 82 MB APK. Needs the library built into the app via the NDK — a different exercise from the desktop subprocess. The `OcrService` interface is already the seam for it. (ADR-037)
- [ ] **(Linux, optional) FOSS STT alternative.** `speech_to_text` has no Linux support; voice input needs a different engine for desktop parity. (ADR-031)

- [ ] **Try the backup dialogs on both platforms by hand.** The logic is covered by tests against a fake file layer, and the plugin wiring was checked statically, but nobody has yet clicked through the actual GTK save dialog on Linux or the SAF picker on Android. (ADR-034)
- [ ] **(Optional) Encrypt backups that contain API keys.** Currently the file is plain text and the UI warns about it; a passphrase would remove the caveat. (ADR-034)

- [ ] **Correction mode with real API keys.** The prompt is only covered by unit tests (routing + parsing). The quality of the branch decision ("is this predominantly Swahili?") and of the vocabulary replacements needs a manual pass against Mistral, Claude and ChatGPT — Swahili is where the providers differ most. (ADR-033)
- [ ] **(Optional) Per-entry mode in history.** Re-running a history entry uses whatever mode is currently active, not the mode it was created with. (ADR-033)

- [ ] **(Optional) FOSS-store distribution via IzzyOnDroid.** If a FOSS-store presence is ever wanted, IzzyOnDroid builds from GitHub release APKs and allows ML Kit / NonFree deps — keeps OCR, unlike the official F-Droid repo. (ADR-030)

### Done
- [x] Clipboard paste on Windows via PowerShell, confirmed by hand on Windows against a real clipboard. (2026-08-14, ADR-047)
- [x] Image-to-text on Windows: five bugs, one message. TSV requested as a config file that need not exist, a script name compared across platform path separators, a TSV parser that could not read CRLF, an error naming a cause it never checked, and subprocess output decoded with the ANSI code page instead of UTF-8. Verified end to end on Windows with a user-installed Tesseract, on both a full screenshot and a cropped phrase. (2026-08-14, ADR-043 to ADR-046)
- [x] Build stamp: commit baked into the binary and shown under Settings; `install.sh` rebuilds a bundle that came from a different commit instead of reusing it. (2026-08-14)
- [x] Script detection as a second attempt: a rejected read asks the image which script it is, retries with script-level trained data, and names the package when that is missing. Closes the case the settings cannot cover — photographing a script you never configured. (2026-08-14, ADR-037)
- [x] Ctrl+V (and the paste button) accept a clipboard image and run OCR on it, with text pasting unchanged when there is no image. Linux via `wl-paste`/`xclip`, no new dependency. 12 new tests. (2026-08-14, ADR-040)
- [x] Settings polish: microphone hidden on Linux rather than greyed out (it stays on Windows and macOS, where `speech_to_text` does have an implementation), both language pickers sorted alphabetically (case- and accent-insensitive, non-Latin grouped last), info buttons on the primary/secondary language fields explaining what each decides. 8 new tests. (2026-08-14, ADR-039)
- [x] **Bulgarian OCR returning Latin junk — fixed.** It was the documented OSD limit, not a stale binary: the reported phrase is 21 characters, under OSD's floor, so script detection returned nothing and English trained data read the Cyrillic at 70.6 confidence — past the gate of 60, so it was returned as a successful read, and the `configured.missing` check that names the package sat on the failure branch below it. Fixed by tiling the page 3×3 before asking OSD again (Cyrillic at 26.7), plus a guard that refuses a confident read whenever a configured language's script is unreadable. A second bug surfaced behind it: `-l script/Cyrillic` is the upstream layout, but Debian installs that data flat as `Cyrillic.traineddata`, so installing the advised package changed nothing — the name now comes from `--list-langs`. Verified end to end with `tesseract-ocr-script-cyrl` installed: the image reads back exactly at 96.2 confidence. (2026-08-14, ADR-038)
- [x] Italian and Bulgarian as UI languages (12 total), including the STT language list and the Windows installer. Bulgarian is the first non-Latin script. (2026-08-14)
- [x] Actionable message when OCR fails because the configured language has no trained data installed. (2026-08-14, ADR-037)
- [x] Image-to-text on Linux via Tesseract, behind an `OcrService` interface; confidence gate against AI-invented text; languages from settings; camera hidden on desktop; 17 new tests. (2026-08-14, ADR-037)
- [x] Release workflow removed again — never asked for, never ran, and its first act would have raced the 1.0.11 release it was supposed to help with. Releases are assembled by hand. (2026-08-14, ADR-042 supersedes ADR-036)
- [x] Windows desktop build: bundled SQLite (hash-verified download) + MSVC runtime, per-user Inno Setup installer, `build_windows.ps1`, CI job, real app icon. Authored on Linux — needs the manual Windows pass above. (2026-08-14, ADR-035)
- [x] Backup/restore to a file outside the app sandbox, so settings and history survive an uninstall; API keys opt-in; 22 new tests. (2026-08-12, ADR-034)
- [x] Correction mode: header toggle, correction prompt for all three providers, `MODE:`/`NOTES:` protocol, suggestions in the output area, schema v2 (`mode`/`notes`) with history badge, strings in all 10 languages, 25 new tests. (2026-08-12, ADR-033)
- [x] `install.sh`: per-user install into `~/.local` with icons + desktop entry, named after the Wayland `app_id`. Verified end-to-end (menu launch, icon sizes, uninstall). (2026-07-29, ADR-032)
- [x] Linux desktop build: GTK toolchain, sqflite→FFI against system SQLite, fixed the 8 always-failing DAO tests. Verified the Android release APK is unaffected. (2026-07-29, ADR-031)
- [x] Abandon official F-Droid; restore image-to-text/OCR; released as 1.0.8. (2026-06-14, ADR-030)
- [x] Exclude Google Play Core so the APK passes F-Droid's `check apk` scanner; released as 1.0.7. Verified 0 play.core class definitions via dexdump. (2026-06-14, ADR-029)
- [x] Remove image-to-text/OCR (ML Kit) for official F-Droid compatibility; released as 1.0.6. Verified buildable under reproduced F-Droid AGP 9 toolchain. (2026-06-14, ADR-028)
- [x] F-Droid AGP 9 build fix: `android.newDsl=false` + `android.builtInKotlin=false`. (2026-06-14, ADR-027)
- [x] Add store screenshots (en-US 1–3) under `fastlane/.../images/phoneScreenshots/`. (2026-06-14)


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

- [x] v1.0.5 — Version display, API key links, error details, F-Droid submission (2026-05-28)
  - App version shown at bottom of Settings screen (package_info_plus)
  - "Get API key →" link button for each provider below the key field
  - Mistral free-tier hint below Mistral key field (all 11 locales)
  - Detailed error messages with HTTP status codes (401, 429, 5xx)
  - Release signing config made conditional on key.properties existing
  - build.gradle.kts: Java 17, dependenciesInfo block (F-Droid requirements)
  - F-Droid metadata: fdroid/metadata/com.njerahouse.tafsiri.yml
  - Fastlane store descriptions: en-US, de-DE, sw
  - GitHub Actions release workflow (.github/workflows/release.yml)
  - docs/FDROID.md: process documentation and lessons learned
  - MR submitted: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249
  - pubspec.yaml version bumped to 1.0.5+5

- [x] v1.0.4 — Settings UX, info dialog, history fix (2026-04-29)
  - Settings reordered: Translation Languages first, AI Provider last before Donate
  - "Target/Alternative Language" → "Primary/Secondary Language" in all 11 locales
  - "Voice Input Language" → "Speech Recognition (Microphone)" in all 11 locales
  - AI Provider section subtitle "bring your own API-Key" (de/en untranslated, 8 locales translated)
  - Translation philosophy info button (ⓘ) in ActionBar with live language names and Settings links
  - Fix: first translation now appears in History (await SQLite insert before invalidating provider)
  - Fix: info dialog language placeholders no longer empty on first launch

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
