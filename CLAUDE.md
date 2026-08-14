# Tafsiri — Flutter Android App

## Project Overview

Flutter Android app for AI-powered text translation. The name "Tafsiri" is Swahili for "translation" — exactly what the app does. Supports three AI backends (Mistral, Claude, ChatGPT), automatic language detection with bidirectional translation logic, voice and image input, and a SQLite-based translation history with favourites.

**Package name:** `ke.darkman.tafsiri`  
**Development language:** English (all code, comments, commit messages, documentation)

---

## App Localisation

The app UI is available in 10 languages. All user-facing strings must go through Flutter's `intl`/ARB localisation system — no hardcoded strings in widgets.

| Language | Locale code |
|---|---|
| Swahili | `sw` |
| German | `de` |
| British English | `en_GB` |
| French | `fr` |
| Dutch | `nl` |
| Spanish | `es` |
| Danish | `da` |
| Norwegian | `no` |
| Swedish | `sv` |
| Polish | `pl` |

ARB files live in `lib/l10n/`. The Flutter tool generates `AppLocalizations` from these. Always add new strings to all 10 ARB files before shipping.

---

## Tech Stack

- **Framework:** Flutter (Dart), Android-first
- **Local database:** `sqflite` + `path_provider`
- **Voice input (STT = Speech-to-Text):** `speech_to_text` — microphone button; recognition locale is derived from the detected source language of the last translation (or falls back to device locale); transcription flows into input field, translation triggers automatically
- **Donate / Buy me a coffee:** `url_launcher` — opens PayPal donate URL from Settings screen
- **Image input / OCR:** `image_picker` + a platform-specific engine behind the `OcrService` interface — `google_mlkit_text_recognition` on Android/iOS, the external `tesseract` binary on desktop. On-device either way, no extra API call. See ADR-037.
- **Language detection:** via AI prompt (more reliable for Swahili and lesser-supported languages than local libraries)
- **Settings persistence:** `shared_preferences`
- **Backup/restore file dialogs:** `file_selector` (Linux — native GTK) + `file_picker` (Android — Storage Access Framework). Split by platform: `file_selector` has no save dialog on Android, `file_picker` needs `zenity` on Linux. See ADR-034.
- **State management:** `riverpod` / `flutter_riverpod`
- **HTTP:** `http`
- **Localisation:** `flutter_localizations` + `intl` + ARB files

---

## Project Structure

```
ke.darkman.tafsiri/
├── CLAUDE.md
├── docs/
│   ├── decisions.md       # Architectural and design decisions (ADR-style)
│   ├── todo.md            # Current tasks and backlog
│   ├── changelog.md       # Version history
│   └── architecture.md   # System overview, diagrams, data flows
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp, theme, router
│   ├── l10n/                           # Localisation ARB files
│   │   ├── app_sw.arb
│   │   ├── app_de.arb
│   │   ├── app_en_GB.arb
│   │   ├── app_fr.arb
│   │   ├── app_nl.arb
│   │   ├── app_es.arb
│   │   ├── app_da.arb
│   │   ├── app_no.arb
│   │   ├── app_sv.arb
│   │   └── app_pl.arb
│   ├── core/
│   │   ├── constants.dart
│   │   ├── database/
│   │   │   ├── db_helper.dart          # SQLite init, migrations
│   │   │   └── translation_dao.dart   # CRUD for translation entries
│   │   └── services/
│   │       ├── ai_service.dart         # Abstract interface
│   │       ├── mistral_service.dart
│   │       ├── claude_service.dart
│   │       └── openai_service.dart
│   ├── features/
│   │   ├── translator/
│   │   │   ├── translator_screen.dart
│   │   │   ├── translator_controller.dart
│   │   │   └── widgets/
│   │   │       ├── input_area.dart
│   │   │       ├── output_area.dart
│   │   │       └── action_bar.dart    # Microphone, image, translate
│   │   ├── history/
│   │   │   ├── history_screen.dart
│   │   │   ├── history_controller.dart
│   │   │   └── widgets/
│   │   │       ├── history_list_item.dart
│   │   │       └── favourites_filter.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── settings_controller.dart
│   └── shared/
│       ├── models/
│       │   └── translation_entry.dart
│       └── widgets/
│           └── language_chip.dart
└── test/
```

---

## Documentation Policy

**Every significant decision, change, or planned task must be recorded in `docs/`.**  
Claude Code must update the relevant doc file(s) as part of the same work session — not as an afterthought.

### `docs/decisions.md`
ADR-style log of architectural and design decisions. Format per entry:

```
## ADR-NNN: Title
**Date:** YYYY-MM-DD
**Status:** Accepted | Superseded by ADR-XXX
**Context:** Why this decision was needed.
**Decision:** What was decided.
**Consequences:** Trade-offs, follow-up tasks.
```

### `docs/todo.md`
Prioritised task list. Sections: `## In Progress`, `## Backlog`, `## Done`. Use checkboxes.  
Move items to Done (with date) rather than deleting them — history is valuable.

### `docs/changelog.md`
Follows [Keep a Changelog](https://keepachangelog.com) format. Sections per release: `Added`, `Changed`, `Fixed`, `Removed`. Unreleased changes go under `## [Unreleased]`.

### `docs/architecture.md`
Living document. Contains: system overview, data flow diagrams (Mermaid), module responsibilities, database schema, external API integration notes. Update when architecture changes.

---

## Data Model

### SQLite table `translation_entry`

```sql
CREATE TABLE translation_entry (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  source_text  TEXT    NOT NULL,
  result_text  TEXT    NOT NULL,
  source_lang  TEXT    NOT NULL,   -- detected language (ISO 639-1 or full name)
  target_lang  TEXT    NOT NULL,   -- actually used target language
  ai_provider  TEXT    NOT NULL,   -- 'mistral' | 'claude' | 'openai'
  is_favourite INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT    NOT NULL,   -- ISO 8601
  mode         TEXT    NOT NULL DEFAULT 'translate',  -- 'translate' | 'correct'
  notes        TEXT               -- improvement notes, correction entries only
);
```

### `TranslationEntry` (Dart)

```dart
class TranslationEntry {
  final int? id;
  final String sourceText;
  final String resultText;
  final String sourceLang;
  final String targetLang;
  final String aiProvider;
  final bool isFavourite;
  final DateTime createdAt;
  final String mode;    // 'translate' | 'correct'
  final String? notes;  // improvement notes, correction entries only
}
```

---

## Settings

Stored via `shared_preferences`.

| Key | Type | Description |
|---|---|---|
| `api_key_mistral` | String | Mistral API token |
| `api_key_claude` | String | Anthropic API token |
| `api_key_openai` | String | OpenAI API token |
| `active_provider` | String | `'mistral'` \| `'claude'` \| `'openai'` |
| `target_language` | String | Primary target language, e.g. `'Swahili'` |
| `alt_language` | String | Fallback target language, e.g. `'English'` |
| `app_locale` | String | UI locale, e.g. `'sw'`, `'de'`, `'en_GB'` |
| `correction_mode` | bool | Correction mode on/off (toggle lives in the translator header) |

API keys are **never logged in plain text**. Always mask in logs: `sk-****`.

---

## Translation Logic

```
Input text
    → Language detection (via AI prompt)
    → Detected language == target_language?
        YES  → translate to alt_language
        NO   → translate to target_language
    → Result shown in output area
    → Entry saved to SQLite
```

### Correction Mode (ADR-033)

Toggled by a chip in the translator header, persisted as `correction_mode`.

```
Correction mode ON
    → Input predominantly in target_language?
        YES  → NOT translated. AI corrects and improves the text, staying in
               target_language. Words the user wrote in another language because
               they did not know them (e.g. "Tafadhali nipe Butter.") are
               replaced with the correct word ("siagi") and explained.
               Improvement notes are shown below the result, written in alt_language.
        NO   → translate to target_language (unchanged)
```

Implemented as a separate system prompt (`AiService.buildCorrectionSystemPrompt`) — one
API call, the model picks the branch. Response protocol:
`LANG:xx` / `MODE:correct|translate` / body / `NOTES:` bullets, parsed by `AiResult.parse()`.

### AI Service Interface

```dart
abstract class AiService {
  Future<String> translate({
    required String text,
    required String targetLanguage,
    required String altLanguage,
    required String apiKey,
    bool correctionMode = false,
  });
}
```

Each concrete service implements this interface. The active service is injected based on the `active_provider` setting.

### Prompt Template (all providers)

```
You are a translation assistant.
Detect the language of the following text.
If it is already [TARGET_LANG], translate it to [ALT_LANG].
Otherwise translate it to [TARGET_LANG].
Respond with ONLY the translated text, no explanations, no preamble.

Text: [INPUT]
```

---

## Features in Detail

### Input Methods

- **Typing / pasting:** Standard multiline `TextField`, expandable
- **Clipboard:** Explicit paste button
- **Voice (STT = Speech-to-Text):** Microphone button → `speech_to_text` started with a locale derived from the detected source language of the previous translation (e.g. if last input was Swahili, STT uses `sw-TZ`; if German, `de-DE`). Falls back to device locale on first launch or if no prior translation exists. Transcription lands in input field → translation triggers automatically.
- **Image / OCR:** `image_picker` (camera + gallery) → `google_mlkit_text_recognition` → recognised text placed in input field

### Translator UI

- **Input area:** Top, editable, with clear button
- **Output area:** Below, read-only, with copy button
- **Action bar:** [Microphone] [Image] [Translate ▶] — prominent, always visible
- Loading indicator during API call

### History

- List of all entries, newest first
- Each entry shows: source text (truncated), result (truncated), target language, timestamp, provider icon
- **Reload into input:** Tap entry → confirm dialog → loads `sourceText` back into translator input field
- **Mark as favourite:** Swipe-to-favourite or star icon — sets `is_favourite = 1`
- **Favourites tab:** Separate tab or filter chip showing only favourites
- **Delete:** Swipe-to-delete with undo snackbar

### Voice Input (STT) — Language Matching

The STT recognition locale adapts to the user's actual input language, not the app UI language. Logic:

1. After each successful translation the detected `source_lang` is stored in the controller state (e.g. `'sw'`, `'de'`, `'en'`).
2. When the microphone button is tapped, the controller maps `source_lang` → BCP-47 locale and passes it to `speech_to_text`:

```dart
const _sttLocaleMap = {
  'sw': 'sw-TZ',
  'de': 'de-DE',
  'en': 'en-GB',
  'fr': 'fr-FR',
  'nl': 'nl-NL',
  'es': 'es-ES',
  'da': 'da-DK',
  'no': 'nb-NO',
  'sv': 'sv-SE',
  'pl': 'pl-PL',
};
```

3. Falls back to device locale if `source_lang` is unknown or on first launch.
4. If the requested STT locale is not available on the device, `speech_to_text` falls back gracefully — no crash.

### Settings Screen

- Per provider: token input field (obscured, with visibility toggle)
- Provider selection: `SegmentedButton` or `RadioListTile`
- Target language + alternative language: free text input (e.g. "Swahili", "English")
- App language selector: dropdown with the 10 supported locales
- Validation: warning banner if active provider has no API key set
- **Backup section** (ADR-034): "Save backup" / "Restore backup". Writes settings + full history as JSON to a location the user picks — deliberately outside the app sandbox, since sandbox data is deleted on uninstall. API keys are included only when the user enables the switch (default off, warns that the file then holds them unencrypted). Restore always replaces the settings; for the history a second switch chooses between **merge** (default, adds only what is missing — no duplicates) and **replace** (wipes the current history first; destructive, so it gets its own warning dialog).
- **"Buy me a coffee" button** (PayPal donate): displayed at the bottom of the settings screen, opens the PayPal donate URL via `url_launcher`. Use the same PayPal link as in the BluesoundPlayer app. Button label is localised via ARB.

---

## Error Handling

- No API key set → Snackbar with link to Settings
- API error (4xx/5xx) → error text shown in output area, no crash
- Network error → clear localised "No connection" message
- OCR fails → message shown, no text imported
- Voice input unavailable → button disabled with tooltip

---

## Code Conventions

- **Language:** All code, comments, variable names, commit messages, and documentation in **English**
- Dart: `lowerCamelCase` for variables/methods, `UpperCamelCase` for classes
- No business logic in widgets — all logic in controllers/services
- `const` widgets wherever possible
- No `print()` in production code — use `debugPrint()` or a proper logger
- All async operations wrapped in `try/catch`, no unhandled exceptions
- API keys never committed to source control — runtime only via `shared_preferences`
- Commit messages: Conventional Commits format (`feat:`, `fix:`, `docs:`, `refactor:` etc.)
- **After every meaningful change: update the relevant file(s) in `docs/`**

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.2
  shared_preferences: ^2.2.2
  http: ^1.2.1
  speech_to_text: ^6.6.1
  image_picker: ^1.0.7
  google_mlkit_text_recognition: ^0.13.0
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  intl: ^0.19.0
  url_launcher: ^6.3.0
  file_selector: ^1.1.0
  file_picker: ^11.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.9
```

---

## Android Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

---

## Recommended Development Order

1. **Project setup:** `flutter create --org ke.darkman`, dependencies, folder structure, `docs/` scaffold with initial content in all four files
2. **Localisation scaffold:** ARB files for all 10 languages, `AppLocalizations` wired up, locale switcher in settings
3. **Settings + persistence:** SharedPreferences, settings screen, API key input, locale setting
4. **AI services:** Interface + all three implementations (start with Claude)
5. **Translation core:** Controller + detection/translation logic
6. **Translator UI:** Input/output text areas, translate button
7. **SQLite:** DB helper, DAO, save after each translation
8. **History:** List view, reload-to-input function
9. **Favourites:** Marking, filter/tab
10. **Voice input (STT):** Microphone input
11. **Image input (OCR):** Camera + gallery
12. **Polish:** Error handling, loading states, icons, theme, final l10n pass for all 10 languages

---

## Out of Scope (v1)

- iOS support (can be added in v2)
- Cloud sync / backup of history
- Offline translation
- TTS (text-to-speech / read aloud) — v2 candidate
- Side-by-side multi-provider comparison mode