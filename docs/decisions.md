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
**Decision:** The ARB filename stays `app_no.arb` (consistent with spec naming convention), but the `Locale` object in `supportedLocales` is `Locale('nb')`. The mapping is documented in `SettingsController`.  
**Consequences:** Slight mismatch between filename and locale code — acceptable. Must be handled carefully in the locale dropdown (display "Norwegian", value `nb`).

---

## ADR-012: Default AI model per provider
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec does not pin specific model names. Low-cost models are appropriate for translation tasks.  
**Decision:** Default models: `claude-haiku-4-5` (Anthropic), `gpt-4o-mini` (OpenAI), `mistral-small-latest` (Mistral). Model names are constants in `lib/core/constants.dart`.  
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