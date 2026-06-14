# Architecture Decision Records

## ADR-001: Flutter Android-first
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App needed for Android devices. Cross-platform capability (iOS) is desirable later but not required for v1.  
**Decision:** Flutter with Android as primary target. iOS support deferred to v2.  
**Consequences:** Single codebase ready for future iOS extension with minimal rework.

---

## ADR-002: Riverpod for state management
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App has multiple independent state domains: active translation, history list, settings, loading/error states.  
**Decision:** Use `riverpod` / `flutter_riverpod`. Provides compile-safe providers, clean separation of controllers and UI, and good testability.  
**Consequences:** Slightly higher initial setup cost vs. `setState`, but pays off for this complexity level.

---

## ADR-003: Language detection via AI prompt, not local library
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The primary target language is Swahili. Local language detection libraries (e.g. `langdetect`) have poor coverage for Swahili and similar languages.  
**Decision:** Language detection is performed by the selected AI provider as part of the translation prompt. The prompt asks the model to detect and conditionally translate in one call.  
**Consequences:** One fewer dependency. Slightly higher latency vs. local detection, but saves a second API round-trip. Result quality depends on the AI provider.

---

## ADR-004: sqflite for local history storage
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Translation history and favourites need to persist across app restarts. Needs to be queryable (filter by favourite, sort by date).  
**Decision:** `sqflite` with a single `translation_entry` table. Simple schema, well-supported on Android.  
**Consequences:** No external server required. Data stays on device. No built-in sync (out of scope for v1).

---

## ADR-005: google_mlkit_text_recognition for OCR
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Image input requires OCR to extract text. Options: cloud OCR (extra API cost/latency) vs. on-device.  
**Decision:** `google_mlkit_text_recognition` runs on-device, no additional API key or network call needed.  
**Consequences:** Works offline for the OCR step. Model download may be required on first use on some devices.

---

## ADR-006: ARB-based localisation for 10 languages
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App must support Swahili, German, British English, French, Dutch, Spanish, Danish, Norwegian, Swedish, Polish.  
**Decision:** Flutter's standard `intl`/ARB pipeline. All user-facing strings go through `AppLocalizations`. No hardcoded strings in widgets.  
**Consequences:** Extra upfront work to populate all 10 ARB files. Required for each new string. Enables future language additions with minimal friction.

---

## ADR-007: Package name ke.darkman.tafsiri
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Standard reverse-domain Android package naming. Owner uses `ke.darkman` prefix.  
**Decision:** `ke.darkman.tafsiri`  
**Consequences:** Fixed from project creation — changing later requires a full package rename.

---

## ADR-008: STT locale derived from detected source language
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Voice input should recognise what the user actually speaks, not the app UI language. A user with UI in German might be dictating Swahili.  
**Decision:** After each translation the detected `source_lang` is stored in controller state and mapped to a BCP-47 locale used for the next STT session. A static map covers all 10 supported languages. Falls back to device locale on first launch or unknown language.  
**Consequences:** STT quality improves significantly for multilingual users. Requires maintaining the `_sttLocaleMap`. If the device doesn't have the locale installed, `speech_to_text` falls back gracefully.

---

## ADR-009: PayPal donate button via url_launcher
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App should offer a "Buy me a coffee" donation option consistent with the BluesoundPlayer app, using the same PayPal donate link.  
**Decision:** Add `url_launcher` dependency. Place a donate button at the bottom of the Settings screen. Opens the PayPal URL in the external browser. Button label goes through ARB localisation.  
**Consequences:** Minimal extra dependency (`url_launcher` is standard in Flutter ecosystem). No in-app payment flow, no store fees.

---

## ADR-010: App name "Tafsiri"
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App needed a memorable, internationally distinctive name reflecting its core purpose and Swahili focus.  
**Decision:** "Tafsiri" — Swahili for "translation" (also used as a verb: "to translate"). Derived from Arabic *tafsīr*. Fully established in everyday Swahili (Kenya, Tanzania). Package name: `ke.darkman.tafsiri`.  
**Consequences:** Strong identity, directly descriptive, fits the `ke.darkman` namespace naturally.

---

## ADR-011: Norwegian locale code — `nb` not `no`
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Flutter's `supportedLocales` uses IETF BCP-47 tags. Norwegian Bokmål is `nb`, not `no`. Using `no` causes Flutter to fail to match the locale.  
**Decision:** The ARB file is named `app_nb.arb` and the `Locale` object in `supportedLocales` is `Locale('nb')`. Display name in the locale dropdown is "Norsk", stored value is `nb`.  
**Consequences:** Consistent filename and locale code. Must be handled carefully in the locale dropdown (display "Norsk", value `nb`).

---

## ADR-012: Default AI model per provider
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec does not pin specific model names. Low-cost models are appropriate for translation tasks.  
**Decision:** Default models: `claude-haiku-4-5-20251001` (Anthropic), `gpt-4o-mini` (OpenAI), `mistral-small-latest` (Mistral). Model names are hard-coded in the respective service files.  
**Consequences:** Easy to update. Low cost per translation. Quality is sufficient for the target use case.

---

## ADR-013: Source language extraction from AI response via `LANG:xx` prefix
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The translation prompt returns only the translated text. The controller needs the detected source language to update `lastSourceLang` for STT locale mapping. A separate detection API call would violate ADR-003 (no second round-trip). Returning JSON risks the AI adding preamble.  
**Decision:** The prompt instructs the AI to respond with exactly: `LANG:[ISO-639-1 code]\n[translated text]`. The controller strips the first line, stores the code as `lastSourceLang`, and displays only the translated text.  
**Consequences:** Fragile if the AI ignores the format — mitigated by explicit prompt wording ("EXACTLY this format and nothing else"). Fallback: if the prefix is missing, `lastSourceLang` is left unchanged and STT uses the previous locale.

---

## ADR-014: SQLite migration stub from v1
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec defines a v1 schema. Adding columns later without an `onUpgrade` handler causes crashes on existing installs.  
**Decision:** `db_helper.dart` includes an `onUpgrade` stub (empty body with a comment) at schema version 1. Version is incremented for each future migration.  
**Consequences:** No immediate cost. Prevents data loss bugs in future updates.

---

## ADR-015: OCR does not auto-translate
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Voice input (STT) auto-translates on final result because the user's intent is unambiguous — they spoke to translate. OCR text from an image may contain multiple blocks, noise, or unwanted content. The user should review before translating.  
**Decision:** OCR result is placed in the input field only. The user taps Translate manually.  
**Consequences:** One extra tap for OCR users. Reduces risk of wasted API calls on poor OCR output.

---

## ADR-016: Release keystore not committed to git
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Android release signing requires a keystore file. Committing it to a public repo is a security risk.  
**Decision:** The release keystore is generated locally and referenced via environment variables or a `key.properties` file that is listed in `.gitignore`. The `android/app/build.gradle` signing config reads from `key.properties`.  
**Consequences:** Each developer/CI environment must provision the keystore separately. Must be documented in `docs/architecture.md` or a `CONTRIBUTING.md` when CI is set up.

---

## ADR-017: Star icon tap as primary favourite interaction (not swipe)
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec allows "swipe-to-favourite or star icon". Each history list item already uses swipe-to-delete (`Dismissible`). Having two swipe gestures on the same item creates an ambiguous UX.  
**Decision:** Star icon tap on the list item is the primary way to mark/unmark a favourite in v1. Swipe gesture is reserved exclusively for delete.  
**Consequences:** Cleaner gesture model. Slightly less discoverable than swipe, but the star icon is a universal convention.

---

## ADR-018: SVG-designed launcher icon with flutter_launcher_icons
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The app needed a distinctive launcher icon. No external designer was available; the icon had to be created programmatically and integrate cleanly with Android adaptive icon requirements.  
**Decision:** Icon designed as SVG (`assets/icon/icon.svg`): two speech bubbles (solid + outline) with a directional arrow, teal `#00897B` background, rounded-square shape. Exported to 1024×1024 PNG via `inkscape`. All Android mipmap densities (mdpi → xxxhdpi) and the adaptive icon (`mipmap-anydpi-v26`) generated by `flutter_launcher_icons` dev dependency.  
**Consequences:** SVG source file is version-controlled — icon can be refined without re-exporting manually. The `flutter_launcher_icons` config lives in `pubspec.yaml`. iOS support deferred to v2.

---

## ADR-019: System dark/light theme with ThemeMode.system
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Android users expect apps to respect the system dark/light mode preference. Hardcoding light-only would feel dated on Android 10+.  
**Decision:** `TafsiriApp` provides both `theme` and `darkTheme` via a shared `_buildTheme(Brightness)` factory, and sets `themeMode: ThemeMode.system`. Seed colour is Material teal `Colors.teal` for both modes.  
**Consequences:** No user-facing toggle needed — the system preference controls it. Both modes share the same teal identity and are visually consistent.

---

## ADR-021: AI prompt split into system role and user message
**Date:** 2026-04-11  
**Status:** Accepted  
**Context:** All three providers were receiving instructions and text in a single `user` message. ChatGPT in particular ignored the translation rules (wrong target language, reformulation instead of translation, no output for longer texts). System-role messages carry higher instruction weight with all providers.  
**Decision:** Split `buildPrompt()` into `buildSystemPrompt(targetLanguage, altLanguage)` and `buildUserMessage(text)`. Claude sends the system prompt as a top-level `"system"` field (Anthropic API standard). OpenAI and Mistral send it as `{"role": "system", ...}` as the first message. The user message contains only the raw text. `max_tokens` raised to 4096 for all providers.  
**Consequences:** Better instruction compliance across all providers. Longer OCR texts no longer truncated. `buildPrompt()` removed — any future prompt change must update `buildSystemPrompt()`.

---

## ADR-022: STT input language setting
**Date:** 2026-04-11  
**Status:** Accepted  
**Context:** STT locale was derived solely from the detected source language of the last translation (ADR-008). If the last translation detected French, the microphone would listen in French even if the user wanted to speak German. This caused mis-recognition when switching input languages.  
**Decision:** Add a `stt_language` SharedPreferences key (ISO-639-1 code, empty = auto). A dropdown in Settings lists Auto + all 10 supported languages. `TranslatorController.toggleListening()` prefers the explicit setting over the auto-detected `lastSourceLang`.  
**Consequences:** User has full control over the STT recognition locale. Auto mode (default) preserves the existing adaptive behaviour from ADR-008.

---

## ADR-023: Translation philosophy info button in ActionBar
**Date:** 2026-04-29
**Status:** Accepted
**Context:** Users were not always aware of the bidirectional translation logic (primary ↔ secondary language toggle based on detected language). A discoverable explanation directly on the translator screen was needed without cluttering the UI permanently.
**Decision:** Add a small ⓘ `IconButton` as the leftmost item in the ActionBar (between the two text areas). Tapping it opens an `AlertDialog` that explains the logic using the current primary and secondary language names as tappable links that navigate to the Settings tab. Language names are read via `ref.watch(settingsProvider)` in `build()` so they are always available immediately, even on first launch.
**Consequences:** Users can understand the translation logic on demand. Language names in the dialog always reflect current configuration. No permanent screen real estate consumed.

---

## ADR-024: Await SQLite insert before invalidating history provider
**Date:** 2026-04-29
**Status:** Accepted
**Context:** The history provider was not showing the first translation after app start. The root cause was that `dao.insert()` was called fire-and-forget via `whenData`, which returned immediately without waiting for the insert to complete. `ref.invalidate(historyProvider)` was then called before the row existed in SQLite. On subsequent translations the history provider was already alive, masking the race.
**Decision:** Replace the `whenData` fire-and-forget with a sequential `await ref.read(translationDaoProvider.future)` + `await dao.insert(...)` + `ref.invalidate(historyProvider)` block inside `translate()`. The insert is guaranteed complete before the provider is invalidated.
**Consequences:** History is consistent after every translation including the very first. Slight increase in time-to-history-refresh (one extra `await`) — negligible in practice since SQLite inserts are fast.

---

## ADR-029: Exclude Google Play Core to pass F-Droid's APK scanner
**Date:** 2026-06-14  
**Status:** Accepted  
**Context:** After removing ML Kit (ADR-028), the `fdroid build` job finally succeeded — but the pipeline's `check apk` job (which only runs once a build exists, hence never seen before) failed: the scanner found 6 proprietary classes in the APK — `com.google.android.play.core.splitcompat.SplitCompatApplication`, `…splitinstall.SplitInstallManager`/`SplitInstallSessionState`/`SplitInstallStateUpdatedListener`, `…tasks.OnSuccessListener`/`OnFailureListener`. These come from Google Play Core, which Flutter's embedding pulls in for Play Store "deferred components" / dynamic feature delivery. Tafsiri does not use deferred components. (Note: these are the same classes the `-dontwarn` rules reference — they are referenced by Flutter's `PlayStoreDeferredComponentManager` but the app never instantiates it.)  
**Decision:** Add `configurations.all { exclude(group = "com.google.android.play") }` to `android/app/build.gradle.kts`. The `-dontwarn com.google.android.play.core.**` ProGuard rules remain so R8 does not fail on the now-absent classes. Released as 1.0.7 (versionCode 7); F-Droid recipe pinned to tag `v1.0.7` (1.0.6 was tagged but never published — its APK failed `check apk`).  
**Consequences:** The APK no longer contains any `com.google.android.play.core` classes — verified locally with `dexdump` (0 class definitions) under the reproduced F-Droid AGP 9 toolchain. Deferred components remain unavailable (unused anyway). This exclusion is harmless for any other distribution channel.

---

## ADR-028: Remove image-to-text (OCR) for F-Droid compatibility
**Date:** 2026-06-14  
**Status:** Accepted  
**Context:** Even after fixing the AGP 9 / built-in-Kotlin opt-out (ADR-027), the F-Droid build kept failing while configuring `:google_mlkit_commons`. The F-Droid job log revealed the real cause: F-Droid's scanner logs `Removing usual suspect 'com.google.mlkit'` and **strips every `com.google.mlkit:*` dependency** from the ML Kit plugins' `build.gradle` (ML Kit is proprietary Google software pulled from Google's Maven; it is on F-Droid's `suss.json` non-free signature list). Proven locally: replicating the strip produces 23 compile errors (`package com.google.mlkit.* does not exist`). No Gradle flag or plugin-version bump can fix this — it is a licensing/policy incompatibility. ML Kit was the **only** non-free dependency flagged; everything else (speech_to_text via the system SpeechRecognizer, the AI HTTP calls, sqflite, etc.) is F-Droid-clean. Options considered: ship via IzzyOnDroid (keeps ML Kit, builds from GitHub release APKs); replace ML Kit with FOSS Tesseract (heavy — the Flutter plugins pull a prebuilt tesseract4android AAR that F-Droid also rejects, plus photo-OCR quality regression); or remove the OCR feature.  
**Decision:** Remove the image-to-text/OCR feature for the official F-Droid distribution: drop `google_mlkit_text_recognition` and `image_picker`, the image button + camera/gallery sheet, the OCR controller code/state, the OCR ARB strings, the CAMERA/READ_MEDIA_IMAGES/READ_EXTERNAL_STORAGE permissions, and the ML Kit ProGuard rules. The Google Play Core `-dontwarn` rules are kept — they belong to Flutter's `PlayStoreDeferredComponentManager`, not ML Kit. Released as 1.0.6 (versionCode 6), F-Droid recipe pinned to tag `v1.0.6`.  
**Consequences:** The app loses photo→text translation; voice, paste, typing, AI translation, history, favourites and 10-language UI remain. APK ~84 MB → ~53 MB. Verified buildable under the reproduced F-Droid AGP 9 toolchain. If OCR is wanted back later, the cleanest path is a separate IzzyOnDroid distribution that keeps ML Kit (no source build, no stripping). The opt-out Gradle flags from ADR-027 are still required (the kotlin-android conflict is a project-level AGP 9 issue, independent of ML Kit).

---

## ADR-027: F-Droid build fix — opt out of both AGP 9 new DSL and built-in Kotlin
**Date:** 2026-06-14  
**Status:** Accepted  
**Context:** The F-Droid `fdroid build` job for MR #39249 kept failing with a `NullPointerException` while configuring `:google_mlkit_commons` ("Failed to notify project evaluation listener") plus a Flutter Fix hint "Starting AGP 9+, only the new DSL interface will be read". Three prior commits (ee2b338, 28eed06, d2afa69) only varied *how* `android.newDsl=false` was applied and never fixed it. Root cause was established by reproducing the build locally: the project pins AGP 8.7.3 + Gradle 8.12 and builds fine under that toolchain (Java 17 *and* full JDK 21), but F-Droid's buildserver pulls `fdroidserver` from `master` and builds with a **bleeding-edge AGP 9 / Gradle 9** toolchain that activates the new Gradle DSL and built-in Kotlin. Under AGP 9, `android.newDsl=false` alone is insufficient — it leaves a `kotlin-android` "Cannot add extension with name 'kotlin'" failure. The old `google_mlkit_commons` 0.8.1 (legacy embedded `buildscript { classpath 'com.android.tools.build:gradle:7.4.2' }`) is the component that NPEs first on F-Droid's exact version mix.  
**Decision:** Set BOTH `android.newDsl=false` and `android.builtInKotlin=false` in `android/gradle.properties`, and append both in the F-Droid recipe prebuild (the recipe builds the v1.0.5 tag, whose committed file predates these flags). Verified locally: AGP 9.0.1 + Gradle 9.1.0 + JDK 21 + the unchanged old plugin builds a clean ~84 MB APK with both flags, and fails with only `newDsl=false`. The flags are no-ops under AGP 8.7.3, so they are safe regardless of which toolchain F-Droid uses on a given day.  
**Consequences:** No retag needed — only the prebuild changed, so updating the fdroiddata MR YAML is enough to re-trigger CI. A proper migration to the AGP 9 / new-DSL world (and newer MLKit plugins) is deferred; the opt-out flags will stop working at AGP 10 (mid-2026), tracked in todo. The misleading note in `docs/FDROID.md` claiming `fdroid build` "fails for Flutter apps (expected)" was corrected — it must pass.

---

## ADR-026: F-Droid submission
**Date:** 2026-05-28  
**Status:** Accepted  
**Context:** Tafsiri should be available via F-Droid, the open-source Android app store, to reach users who prefer FOSS distribution over Google Play.  
**Decision:** Prepare the app for F-Droid's source-based build model. Changes required: `dependenciesInfo { includeInApk = false; includeInBundle = false }` in `build.gradle.kts` (mandatory for F-Droid); Java compatibility raised to VERSION_17 (F-Droid builds with Java 21); fastlane store metadata in en-US, de-DE, sw; F-Droid build recipe at `fdroid/metadata/com.njerahouse.tafsiri.yml`; GitHub Actions release workflow with pinned Flutter version. Anti-feature `NonFreeNet` declared because the app connects to third-party AI APIs. MR submitted to `fdroid/fdroiddata`: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249  
**Consequences:** F-Droid builds the APK from source using its own signing keys — no pre-built APK is submitted. Auto-updates work via git tags (`v1.x.y`). The `NonFreeNet` anti-feature is displayed in the F-Droid store listing but does not block inclusion. The `google_mlkit_text_recognition` dependency uses the unbundled ML Kit (Apache 2.0) which does not require Google Play Services.

---

## ADR-025: API key console links and Mistral free-tier hint in Settings
**Date:** 2026-05-28  
**Status:** Accepted  
**Context:** The "bring your own API key" model requires users to obtain keys from each provider's console. New users had no guidance on where to get a key or that a free option exists.  
**Decision:** Add a "Get API key →" `TextButton` below the active provider's API key field. Each provider maps to its canonical key console URL (Mistral: `console.mistral.ai/api-keys`, Claude: `console.anthropic.com/settings/keys`, OpenAI: `platform.openai.com/api-keys`). For Mistral specifically, a hint text notes the free tier with no credit card required — Mistral is the default provider and the only one with a free offering. All text goes through ARB localisation (11 locales).  
**Consequences:** Friction for new users is reduced significantly. URL constants centralised in `constants.dart`. If provider console URLs change they must be updated there.

---

## ADR-020: ProGuard keep rules for google_mlkit_text_recognition release build
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** `flutter build apk --release` failed with R8 errors: the `google_mlkit_text_recognition` plugin references optional script-recognizer classes (Chinese, Devanagari, Japanese, Korean) and Google Play Core split-install classes that are not bundled in the base Latin-script SDK. R8 treats missing references as fatal errors.  
**Decision:** Add `-dontwarn` rules for all missing classes to `android/app/proguard-rules.pro`. Enable `isMinifyEnabled = true` with `proguardFiles` reference in the release build type. The optional script models are not shipped — the app only uses Latin-script OCR.  
**Consequences:** Release build succeeds. Optional script recognizers remain unsupported in v1 (out of scope). If Chinese/Japanese/Korean OCR is added in v2, the corresponding SDK dependency must be added and the `-dontwarn` rule removed.
