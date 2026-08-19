# Tafsiri

**Tafsiri** is Swahili for *translation* — and that is exactly what this app does and more.

Tafsiri is an Android, Linux, Windows, MacOS app for AI-powered text translation. It supports voice input, image-to-text (OCR), a great correction mode for learners and a searchable translation history with favorites. The UI is available in 12 languages, the languages to translate from and into are unlimited.

---

## Download

<a href="https://github.com/rdOxalis/tafsiri/releases/latest"><img alt="Get it on GitHub" src="assets/badges/github.png" height="48"></a>

---

## How It Works

Tafsiri is built around two language slots: a **primary language** and a **secondary language**.

- **Primary language** — the language you usually translate *into* (e.g. Swahili)
- **Secondary language** — the fallback (e.g. English)

When you enter text, the app detects the source language automatically via AI. The translation logic then works like this:

> If the input is already in the primary language → translate to the secondary language.  
> Otherwise → translate to the primary language.

This means you never have to flip a toggle or select a direction. You just type or speak, and the app figures out which way to translate. If you live between two languages — say Swahili and German, or English and French — the app adapts to each input automatically.

You configure both languages freely in Settings. There are no hardcoded language pairs.

---

## Correction mode

A toggle in the translator header switches Tafsiri from translating to coaching.

When it is on, text written predominantly in your primary language is no longer translated into the secondary language — it is corrected and improved, and a **Suggestions** section explains every change. Words you substituted from another language because you did not know them are replaced with the right one:

> **Tafadhali nipe Butter.** → *Tafadhali nipe siagi.*
> — Butter → siagi: German for "butter".

Input in any other language is still translated into your primary language, exactly as before. The setting persists across restarts, and the action button changes to "Improve" while it is active.

Corrections are stored in the history with their suggestions and marked with their own badge. The database migrates in place — existing entries are kept and counted as translations.

---

## Bring Your Own API Key

Tafsiri does not have a backend. There is no subscription, no account, no server in between. The app talks directly to the AI provider of your choice using your own API key.

This means:

- **Your data goes directly to the AI provider** — not through any intermediary
- **You control the costs** — you pay only for what you use, at the provider's rates
- **You choose the provider** — switch between Mistral, Claude, and ChatGPT at any time

API keys are stored locally on your device and never transmitted anywhere other than to the provider you have selected.

---

## Supported AI Providers

| Provider | Model used | Free tier |
|---|---|---|
| **Mistral AI** | `mistral-small-latest` | Yes — generous free tier |
| **Anthropic Claude** | `claude-haiku-*` | No — pay as you go |
| **OpenAI ChatGPT** | `gpt-4o-mini` | No — pay as you go |

**Mistral is the recommended starting point** if you want to try the app for free.

---

## Getting a Free Mistral API Key

Mistral AI offers a free tier that is more than sufficient for personal translation use.

1. Go to [console.mistral.ai](https://console.mistral.ai)
2. Create an account (email or Google login)
3. Navigate to **API Keys** in the left sidebar
4. Click **"Create new key"** — give it any name, e.g. "Tafsiri"
5. Copy the key (it starts with `sk-...`) — you only see it once
6. Open Tafsiri → Settings → paste the key into the **Mistral** field
7. Select **Mistral** as the active provider

The free tier has a monthly token limit that resets each month. For typical translation use it will not run out.

---

## Features

- **Voice input (STT)** — speak in any supported language, transcription lands in the input field and translation triggers automatically. The recognition locale adapts to your last detected input language.
- **Image input (OCR)** — take a photo or pick one from your gallery; on-device text recognition extracts the text for translation
- **Translation history** — every translation is saved locally in SQLite; tap any entry to reload it
- **Favourites** — star entries to keep them accessible
- **12 UI languages** — Swahili, German, English, French, Dutch, Spanish, Danish, Norwegian, Swedish, Polish, Italian, Bulgarian
- **Correction Mode** - For learners. Switch to that mode and your message in (mostly) primary language will be improved. 

---

## Desktop (Linux, Windows and macOS)

Tafsiri also runs on the desktop. Translation, history, favourites, settings and backup all work there, and so does image-to-text once Tesseract is installed (see below). Pasting a screenshot with **Ctrl+V** works on Linux and Windows — on macOS that is not implemented yet. Voice input is the one gap on Linux: `speech_to_text` has no implementation there, so the microphone button is not shown at all; on Windows and macOS it is.

**Linux** — needs the Flutter SDK and `libgtk-3-dev`:

```bash
./install.sh          # builds and installs into ~/.local, no root required
./install.sh --uninstall
```

**Windows** — needs the Flutter SDK, Visual Studio 2022 with "Desktop development with C++", and [Inno Setup](https://jrsoftware.org/isinfo.php) 6.3+ for the installer:

```powershell
.\build_windows.ps1
```

This produces `build\windows\installer\tafsiri-<version>-windows-x64.exe`. It installs for the current user only, so Windows asks for no administrator rights. Uninstalling asks whether to keep your settings, API keys and translation history.

**macOS** — needs Xcode with its command line tools and CocoaPods (`brew install cocoapods`). One setting is required once per machine, because `speech_to_text` ships a Swift Package manifest that contradicts its own podspec and will not compile under Swift Package Manager:

```bash
flutter config --no-enable-swift-package-manager
./build_macos.sh              # builds and installs into /Applications
./build_macos.sh --user       # ~/Applications instead, no admin rights
./build_macos.sh --uninstall
```

The app then appears in Finder and Spotlight like any other. A build you made yourself starts normally; a copy someone **downloads** is quarantined by macOS and needs clearing once, under System Settings → Privacy & Security → *Open Anyway*, because the app is ad-hoc signed rather than notarized. It is **not** sandboxed: image-to-text runs Tesseract as a child process, and the App Sandbox refuses that outright.

The microphone asks for permission the first time. macOS only shows that prompt to an app in the **foreground**, so click the window first — and note that `flutter run` cannot foreground the app, which is why voice input appears broken when testing that way. If the prompt was ever refused, macOS never asks again: `tccutil reset SpeechRecognition ke.darkman.tafsiri` (and the same for `Microphone`).

---

## Text recognition on the desktop

Image-to-text runs entirely on your machine through [Tesseract](https://github.com/tesseract-ocr/tesseract), which Tafsiri does not bundle — install it once and the image button starts working.

**Which data you need.** Tafsiri loads the trained data for the two languages you set in Settings. When it detects a script none of those is written in — you photograph a Bulgarian sign while translating between Swahili and German — it reaches for that *script's* data instead. So: a **language** pack for what you translate, a **script** pack for what you photograph.

### Linux

```bash
sudo apt install tesseract-ocr                      # the engine
sudo apt install tesseract-ocr-deu tesseract-ocr-swa  # what you translate
sudo apt install tesseract-ocr-script-cyrl          # what you photograph (~28 MB)
```

Or simply everything — 123 languages and 37 scripts, about 393 MB to download:

```bash
sudo apt install tesseract-ocr-all
```

### Windows

Download `tesseract-ocr-w64-setup-*.exe` from the [Tesseract releases](https://github.com/tesseract-ocr/tesseract/releases) and run it. In the installer, expand **Additional language data (download)** and **Additional script data (download)** and tick the top-level box of each — taking everything is simplest and saves coming back when you photograph a script you did not expect.

You can also add data later by dropping `.traineddata` files from [tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast) into `C:\Program Files\Tesseract-OCR\tessdata\` (script data goes in the `script\` subfolder).

Tafsiri looks in `C:\Program Files\Tesseract-OCR` by itself, so the installer's `PATH` checkbox is optional — tick it anyway if you want to use `tesseract` from a terminal.

### macOS

```bash
brew install tesseract tesseract-lang     # the engine and every language
```

`tesseract-lang` covers all the languages and scripts, so there is nothing to choose. Tafsiri finds Homebrew in `/opt/homebrew/bin` and `/usr/local/bin` on its own — which matters, because an app launched from Finder inherits none of your shell's `PATH`.

A program inherits `PATH` from whatever started it, and Explorer reads it once at login — so **sign out and back in** before launching Tafsiri from the Start menu, or start it from a fresh terminal to test straight away.

### Checking and troubleshooting

```
tesseract --list-langs
```

Languages appear as ISO 639-2 codes (`deu`, `swa`, `bul`); script data appears as `script/Cyrillic` on Linux and `script\Cyrillic` on Windows. Both spellings are understood.

When image-to-text or voice input does something unexpected, Tafsiri writes what it did to **`tafsiri.log`** in your temp directory — `%TEMP%` on Windows, `/tmp` on Linux, and inside the app container on macOS (`~/Library/Containers/…/Data/tmp/`) if the sandbox is ever switched back on. It records which Tesseract binary was run and from where, which languages were found, which script was detected and how sure it was, the exact command, how much text came back at what confidence, and whether speech recognition initialised.

One practical tip: **a cropped photo reads far better than a full screenshot.** Script detection on a whole window of Latin interface with a little Cyrillic in it is close to a coin toss — measured at 1.76 confidence against 10.0 for the same text cropped — and the recognition follows that guess.

---

## Privacy

Camera and microphone are used entirely on-device — Google ML Kit OCR and Android STT on the phone, Tesseract on the desktop. Reading the clipboard is local too. No images or audio are uploaded anywhere. Input text is sent only to the AI provider you have configured.

Full privacy policy: [docs/privacy-policy.md](docs/privacy-policy.md)

---

## Tech Stack

Flutter (Dart) · Android · Linux · Windows · SQLite · Riverpod · Google ML Kit · speech_to_text

---

## License

MIT
