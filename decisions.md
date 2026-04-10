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