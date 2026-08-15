# Changelog

All notable changes to Tafsiri will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- **An About section at the foot of Settings**, matching the one in BluesoundPlayer: the app name with its version and build commit, the **open source licences** of everything Tafsiri is built on, a link to the **source on GitHub**, and the existing "buy me a coffee" entry gathered in with them. The version moved out of the small centred line at the very bottom into the About entry, where someone looks for it — it is the first thing to check when the app and the source disagree. Translated into all 12 UI languages.
- **Tesseract now appears on the licence page** (ADR-049). Flutter builds that list from the packages the app links, so the engine that actually does the reading — a separate program Tafsiri runs — was missing from it, while 210 other entries were there. Desktop only: on Android and iOS the reading is done by ML Kit, which was listed all along.

### Added
- **macOS has a build script** (ADR-053): `./build_macos.sh` builds a release app and installs it into `/Applications`, where Finder and Spotlight find it — `--user` puts it in `~/Applications` instead, and `--uninstall` removes it while leaving your settings and history alone. It refuses to run when Swift Package Manager is enabled, which `speech_to_text` cannot build under, rather than letting that surface as an unreadable Swift error.

### Fixed
- **Image-to-text works on macOS**, and the app finds Tesseract wherever it is installed rather than only through `PATH` (ADR-051, ADR-052). A desktop app inherits none of your shell's environment, so a Homebrew install in `/opt/homebrew/bin` was invisible; and the App Sandbox refused to launch it at all, which is why macOS now ships unsandboxed. On Windows this also removes the need to put Tesseract on `PATH` by hand.

### Changed
- **The diagnostic log is now `tafsiri.log`** and covers voice input as well as image-to-text. It records which Tesseract binary was run and from where — which is what identified a macOS failure as the sandbox refusing to launch it rather than the engine being absent — and whether speech recognition initialised, which previously reported nothing at all when it simply returned false.
- **The Windows setup instructions point at Tesseract's own releases** instead of the UB Mannheim build (ADR-050). The official project now ships `tesseract-ocr-w64-setup-*.exe` itself, and it is the newer of the two — 5.5.3 against 5.4.0. Tick the language and script data in the installer and image-to-text works. Tesseract stays a separate install on every desktop rather than being bundled: the twelve UI languages alone come to about 25 MB, against a 12 MB installer.

---

## [1.0.12] - 2026-08-14

### Added
- **Ctrl+V pastes a screenshot on Windows too** (ADR-047). It reads the clipboard through the PowerShell Windows already ships with, so there is nothing extra to install and no new dependency — the same approach as image-to-text itself. Android is the one platform left without it. As on Linux, Ctrl+V with no image on the clipboard still pastes text exactly as before.

### Fixed
- **Non-Latin text no longer comes back as gibberish on Windows** (ADR-046). `Моля те, дай ми маслото` arrived as `ÐœÐ¾Ð»Ñ Ñ‚Ðµ, Ð´Ð°Ð¹ Ð¼Ð¸ Ð¼Ð°ÑÐ»Ð¾Ñ‚Ð¾`: Tesseract writes UTF-8, and the app was decoding it with the machine's ANSI code page, so every two-byte character became two Latin ones. Nothing reported an error — the read was 96% confident and the right length. Output is read as UTF-8 everywhere now.
- **"Install the script package" is no longer said to people who already have it** (ADR-045). If the trained data was found and used and the read still scored poorly, the app claimed the data was missing. It now falls back to your configured languages and, failing that, says plainly that it could not read the image. The case that exposed it: a full-window screenshot, mostly Latin interface with a little Cyrillic in it — script detection called it Cyrillic by a hair, the app then read a Latin window using Cyrillic data only, and your own languages never got a turn.
- **Image-to-text writes a diagnostic log** (ADR-044) to `tafsiri-ocr.log` in the system temp directory: which languages were found, which script was detected, the exact command, and how much text came back at what confidence. A Flutter release build on Windows cannot print to a console at all, which left the one broken platform unable to say what it was doing.
- **Image-to-text works on Windows** (ADR-043) — install Tesseract and it is found on `PATH`, no bundling needed. It had never worked, and not for the reason the docs assumed: the app asked for its output using `tsv`, which is not a flag but the name of a config file in the installation's `tessdata/configs/`. Where that file is missing, Tesseract does not fail — it warns, exits 0 and prints plain text, so the app saw an empty result and told you to install trained data you already had. It now asks for the same output with `-c tessedit_create_tsv=1`, which depends on nothing. A second cause sat behind that one: `--list-langs` spells the entry `script\Cyrillic` on Windows and `script/Cyrillic` on Linux, and the app compared the two literally — so it skipped the recognition run and reported script data as missing while the user was looking at the folder containing it. The comparison ignores the separator now. And behind *that*, the one that actually broke everything: the TSV parser split on `\n` alone, so with Windows line endings the header's last column was read as `text\r`, the column lookup failed, and every page came back empty — every recognition on Windows had been failing this way, not just Cyrillic ones.

---

## [1.0.11] - 2026-08-14

### Added
- **Image-to-text on Linux** (ADR-037). Picking an image on the desktop no longer ends in an error: recognition runs through the external `tesseract` binary. Needs `tesseract-ocr` plus the trained data for the languages you translate (`sudo apt install tesseract-ocr tesseract-ocr-swa`); `install.sh` warns when either is missing. Windows is not done yet — the engine still has to be bundled into the installer.
- Text recognition now sits behind an `OcrService` interface with two implementations (ML Kit on Android/iOS, Tesseract on desktop), so the translator no longer knows which engine it has.
- Tesseract is told which languages to expect from the two you already configured for translation, passed together so mixed-language images work. English names, native spellings (`Deutsch`, `Kiswahili`) and two-letter codes are all understood; missing trained data falls back to English.
- **A confidence gate**: if Tesseract's mean word confidence is below 60, the image is reported as unreadable instead of being passed on. Handed garbled text, the AI does not fail — it invents fluent, plausible text that was never on the image, which looks like success and is worse than an error.
- A separate message when no recognition engine is installed at all, so the desktop tells you to install Tesseract rather than blaming the image. Translated into all 10 UI languages.
- When recognition fails **and** the configured language had no trained data installed, the message now names the package to install (`tesseract-ocr-bul`) instead of blaming the image. A missing package that still produced good text stays silent — for Latin scripts English trained data reads the letters correctly and only drops diacritics, which the AI restores anyway.
- **Two new UI languages: Italian and Bulgarian** (12 total). Bulgarian is the first non-Latin script in the app, which is precisely the case where OCR trained data stops being optional: without `tesseract-ocr-bul`, Cyrillic reads as noise — measured at 39 confidence against a threshold of 60, so it is rejected rather than passed on. Both are also offered in the speech-recognition language list and in the Windows installer.
- **The image decides which script it is, before recognition starts.** Deriving the OCR language from your *target* languages is backwards — you photograph text you cannot read, so its script may be one you never configured. The app now asks the image first (using data that ships with Tesseract, 0.09 s), and where no configured language matches that script it uses Tesseract's script-level trained data instead, or names the package to install. German + English configured and a Bulgarian sign in front of you now works with `tesseract-ocr-script-cyrl` installed, and says so when it is not — where it previously returned `Mons, Haute Mu MacnoTo` as if that were the text. It also softens the free-text language fields: a name the app cannot map now costs accuracy rather than the whole read. Needs enough characters: a two-word sign falls back to the configured languages.
- 30 new tests (125 at that point, was 95), including three that drive the real `tesseract` binary against fixture images and skip themselves where it is not installed. ADR-038 adds eight more, for **133**, among them the image that actually failed — a short Bulgarian phrase, the length the earlier Cyrillic fixtures were too long to catch.

- **The build is now identifiable.** Settings shows `1.0.11+11 · 743b1eb` — version, build number and the commit it was compiled from. An installed desktop bundle is a copy, so behaviour that contradicts the source is more often a stale binary than a bug, and this is how you tell in one glance.
- `install.sh` notices by itself when the existing bundle came from a different commit and rebuilds instead of silently reusing it. Previously `./install.sh` without `--rebuild` would happily install a bundle built from older code.

- **Ctrl+V pastes an image from the clipboard and reads it** (ADR-040). Take a screenshot, press Ctrl+V in the translator, and the recognised text is in the input field — no saving the file and picking it out of a dialog. **Ctrl+V for text is unchanged**: if the clipboard has no image, the same keystroke pastes text as before, at the cursor. The paste button in the action bar does the same thing in the same order, so it works without a keyboard. Linux for now; Android and Windows still need their own way in. No new dependency — it reads the clipboard through `wl-paste` or `xclip`, the way OCR reads through `tesseract`.
- **The two language settings now explain themselves** (ADR-039). An info button beside each field says what it decides: the primary language is the one you want to learn or are less confident in, the secondary the one you speak well and that your text is translated into. They are what the whole translation logic turns on, and their names alone did not say which was which. Available as a dialog and as a hover tooltip, translated into all 12 UI languages.

### Fixed
- **The build stamp under Settings is just the commit now** (ADR-041) — `1.0.11+11 · 7ea9cce`, no `-dirty` suffix. It used to gain one whenever the working tree differed from the commit, which sounded useful and was not: `flutter pub get` regenerates the plugin registrants on every run, so the build dirtied its own tree and a released binary would have been labelled after eight files nobody had edited. `install.sh` still refuses to reuse a bundle built from a modified tree, so the stale-binary trap that marker was for stays covered.
- **Short Cyrillic text is no longer read as Latin nonsense** (ADR-038). Photographing `Моля те, дай ми маслото.` returned `Mona Te, nal Mu MacnoTo.` — the failure ADR-037 was meant to prevent, still happening because script detection quietly gives up on short text: Tesseract's OSD answers anything under roughly fifty characters with "Too few characters", and English trained data then reads Cyrillic lookalikes at 70.6 confidence, past the gate of 60. A phrase off a menu or a sign is the app's main case, so this was the normal path, not an edge one. The page is now repeated in a 3×3 grid and OSD asked again — which invents no glyph the image did not already have, and takes the same phrase from "Too few characters" to Cyrillic at 26.7. With `tesseract-ocr-bul` installed that image now reads back exactly, at 96.4 confidence.
- **A confident read is no longer trusted when it cannot possibly be right.** If a language you configured has no trained data and nothing loaded can read its script, the result is refused with the install hint instead of returned — confidence tells you the glyphs were legible, never that they were the right alphabet. Missing *Latin* languages are exempt, since English reads those letters and only loses diacritics, which the AI restores.
- **Installing the advised script package now actually helps.** The `-l` argument was hardcoded as `script/Cyrillic`, which is how upstream `tessdata` is laid out — but Debian's `tesseract-ocr-script-cyrl` installs the same data flat as `Cyrillic.traineddata`. Tesseract then fails with "Error opening data file", which looks exactly like the package being missing, so the app kept saying "install `tesseract-ocr-script-cyrl`" to someone who just had. The name is now read from `--list-langs`, so both layouts work.
- The install hint names the language you configured (`tesseract-ocr-bul`, ~2 MB) when the detected script matches one of your languages, and the script pack (`tesseract-ocr-script-cyrl`, ~28 MB) otherwise — which is the normal case, since you photograph scripts you do not translate into.

### Changed
- **The microphone button is gone on Linux** (ADR-039), instead of sitting there greyed out. Linux is the one platform `speech_to_text` has no implementation for, so there was no setting anywhere that could have enabled it — and a disabled button says "not right now", which sends you looking. Everywhere else — including Windows and macOS — it stays and merely greys out, because there a denied permission *is* something you can change.
- **Both language lists are now in alphabetical order** (ADR-039) — app language and speech-recognition language. They were in the order the languages were added to the app over the months, which helps nobody scanning twelve entries. Sorting ignores case and accents, so `Español` sits under E rather than after `Svenska`, and `Български` groups with the other non-Latin names at the end. The names stay in their own language (`Deutsch`, not `German`) — that is the form you spot fastest. `Auto` stays pinned at the top of the speech list, being a mode rather than a language.
- The camera entry in the image source sheet is hidden on desktop, where image pickers do file selection only and it was a guaranteed dead end.
- The Windows installer is named `tafsiri-<version>-windows-x64.exe`, matching the existing `tafsiri-<version>.apk` and `tafsiri-<version>-linux-x64.tar.gz` assets.

---

## [1.0.10] - 2026-08-12

### Added — 2026-08-14, after the release
Shipped as a third asset on the existing 1.0.10 release rather than as a new version: the Dart code is byte-identical to what 1.0.10 already contains, so the APK and the Linux bundle are unchanged and were not rebuilt.

- **Windows desktop build and installer** (ADR-035). `.\build_windows.ps1` builds the release app and packages it as `build\windows\installer\tafsiri-<version>-windows-x64.exe`. The installer is per user — no admin rights, no UAC prompt — into `%LOCALAPPDATA%\Programs\Tafsiri`, with a Start-menu entry and an optional desktop icon. Uninstalling asks whether to keep your settings, API keys and history (`%APPDATA%\ke.darkman\Tafsiri`) and defaults to keeping them.
- `windows/sqlite3.cmake` — downloads the official SQLite DLL (pinned to 3.53.4, verified against sqlite.org's published SHA3-256) and ships it next to the executable. Windows has no system SQLite, so without it the history and every save would fail. The MSVC runtime is bundled the same way, so the app also starts on machines without the Visual C++ redistributable.
- Windows branch in `useSystemSqlite`: looks for `sqlite3.dll` beside the executable, then in the repo-local cache, and otherwise fails with a message naming every path it tried.
- Installer localised into 8 languages (English, German, French, Dutch, Spanish, Danish, Norwegian, Polish — Inno Setup ships no Swahili or Swedish).
- Windows app metadata: window title and `ProductName` are `Tafsiri` instead of the lower-case package name, and `app_icon.ico` is generated from the real app icon rather than the Flutter template logo.

### Added
- **Backup and restore** (ADR-034). Settings → Backup writes your settings and the complete translation history to a JSON file of your choosing, and reads it back. The file is written outside the app sandbox, so it survives an uninstall — on Android, app data is otherwise gone for good. API keys are included only when you switch it on; the switch defaults to off and warns that the file then holds them unencrypted.
- Restoring replaces the settings; for the history you choose. **Merge** (the default) adds the backup's translations to what is already there and skips ones that are already present, so importing the same file twice changes nothing — this is what you want when pulling in another device's translations. **Replace history** wipes the current history and puts the backup's in its place; it is irreversible, so it has its own warning dialog and a red confirm button, and the switch never stays on.
- A backup written without keys leaves existing keys untouched instead of blanking them.
- Doubles as the way to move a setup between Android and Linux.
- 25 new tests (95 total, was 70): the backup format and its round-trip, rejection of foreign or too-new files, tolerance of truncated ones, and the full export→import cycle against a real database in both merge and replace mode.

### Changed
- New dependencies `file_selector` (Linux save/open dialog, native GTK) and `file_picker` (Android Storage Access Framework). Split by platform because neither covers both — see ADR-034.

---

## [1.0.9] - 2026-08-12

### Added
- **Correction mode** (ADR-033). A toggle in the translator header switches the app from translating to coaching: text written predominantly in the primary language is no longer translated to the secondary language but corrected and improved, with a "Suggestions" section listing each change. Words the learner slipped in from another language because they did not know the word (e.g. *"Tafadhali nipe **Butter**."*) are replaced with the correct primary-language word (*siagi*) and explained. Input in any other language is still translated to the primary language as before. The setting persists across restarts; the action button switches to "Improve".
- `mode` and `notes` columns on `translation_entry` (schema v2, migrated in place) so corrections are kept in the history and marked with a spellcheck badge; reloading a correction restores its suggestions.
- `AiResult.parse()` — the response parser is now a named, tested unit and understands the extended `LANG:` / `MODE:` / `NOTES:` protocol.
- 26 new tests: correction prompt routing for all three providers, response parsing, controller state, DB migration, and the correction-mode UI (70 total, was 44).
- **Linux desktop build** (ADR-031). `flutter build linux --release` now produces a working bundle. sqflite is routed through `sqflite_common_ffi` on desktop via the new `lib/core/database/sqflite_desktop.dart`, with a `sqlite3` loader override that falls back from `libsqlite3.so` to `libsqlite3.so.0` so no `libsqlite3-dev` is required at runtime. `DbHelper` stores the database under `getApplicationSupportDirectory()` on desktop.
- `test/database/sqflite_desktop_test.dart` — guards the desktop FFI/loader wiring by opening a real on-disk database.
- **`install.sh`** (ADR-032) — builds the release bundle and installs it per-user into `~/.local` with icons and a desktop entry, so Tafsiri appears in the application menu. Supports `--rebuild` and `--uninstall`. Requires no root.

### Fixed
- The 8 `translation_dao_test` cases that had always failed on Linux with `Failed to load dynamic library 'libsqlite3.so'`. Suite is now 45/45 green.

### Changed
- `DbHelper.createTableSql` and `DbHelper.migrate` are public and shared with the database tests, which previously carried their own copy of the schema.
- Eight new localised strings in all 10 languages for correction mode, including the on/off state words shown on the toggle.
- `sqflite_common_ffi` promoted from dev- to regular dependency; `sqlite3` added as a direct dependency. Both are pure-Dart FFI packages — the release APK's native libraries are unchanged.

### Known limitations (Linux)
- Voice input is unavailable (`speech_to_text` has no Linux implementation); the mic button is disabled.
- OCR is unavailable (`google_mlkit_text_recognition` is Android/iOS only); picking an image works but recognition reports the localised OCR error.
- Requires `libgtk-3-dev` to build and `libsqlite3-0` at runtime.

---

## [1.0.8] - 2026-06-14

### Added
- **Image-to-text (OCR) restored.** Re-added `google_mlkit_text_recognition` + `image_picker`, the image button + camera/gallery sheet, the OCR controller logic and `ocr*`/`imageButton`/`errorOcrFailed` strings, the CAMERA/READ_MEDIA_IMAGES/READ_EXTERNAL_STORAGE permissions, and the ML Kit ProGuard rules. Reverses the 1.0.6 removal.

### Removed
- The Google Play Core exclusion in `build.gradle.kts` (was only needed for F-Droid's APK scanner).

### Changed (build)
- Android Gradle Plugin bumped 8.7.3 → 8.9.1: the current `image_picker` transitive dependencies (androidx.activity/core 1.18.x) require AGP ≥ 8.9.1. Gradle wrapper 8.12 already supports it. Verified `flutter build apk --release` succeeds (84.5 MB APK).

### Changed
- **Official F-Droid submission abandoned** (ADR-030). The `check apk` scanner rejects Flutter's bundled Play Core classes in a way that can't be reproduced/verified locally. MR #39249 closed. The app is not published to F-Droid; distribution remains Play Store / direct APK. (1.0.6 and 1.0.7 were tagged during the F-Droid attempt but never published.)

---

## [1.0.7] - 2026-06-14

### Fixed
- **F-Droid APK scanner (`check apk`):** excluded the `com.google.android.play` (Play Core) dependency in `android/app/build.gradle.kts`. With OCR gone the `fdroid build` job passed, but the scanner then flagged 6 proprietary `com.google.android.play.core.*` classes that Flutter's embedding bundles for Play Store deferred components (which this app does not use). Verified with `dexdump` that the built APK contains zero `com.google.android.play.core` class definitions (ADR-029). Supersedes the never-published 1.0.6.

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
