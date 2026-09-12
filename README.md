# Tafsiri

**Tafsiri** is Swahili for *translation* — and that is exactly what this app does and more.

Tafsiri is an Android, Linux, Windows, MacOS app for AI-powered text translation. It supports voice input, image-to-text (OCR), a great correction mode for learners and a searchable translation history with favorites. The UI is available in 12 languages, the languages to translate from and into are unlimited.

---

## Download

<a href="https://github.com/rdOxalis/tafsiri/releases/latest"><img alt="Get it on GitHub" src="assets/badges/github.png" height="48"></a>

---

## Become a Tester

Want early access to new features before they're released? Join our closed beta on Google Play — see [TESTING.md](TESTING.md) for how to get started.

---

## How It Works

Tafsiri is built around two language slots: a **learning language** and a **confident language**.

- **Learning language** — the one you want to learn, or are less sure of; everything you enter is translated into it (e.g. Swahili)
- **Confident language** — the one you speak well; your text lands here when you write in the learning language (e.g. English)

Note which way round that is: the learning language is the *weaker* of the two, not your everyday one. It is the slot the app translates into, because that is the language you need help with.

When you enter text, the app detects the source language automatically via AI. The translation logic then works like this:

> If the input is already in the learning language → translate to the confident language.  
> Otherwise → translate to the learning language.

This means you never have to flip a toggle or select a direction. You just type or speak, and the app figures out which way to translate. If you live between two languages — say Swahili and German, or English and French — the app adapts to each input automatically.

You configure both languages freely in Settings. There are no hardcoded language pairs.

---

## Correction mode

A toggle in the translator header switches Tafsiri from translating to coaching.

When it is on, text written predominantly in your learning language is no longer translated into the confident language — it is corrected and improved, and a **Suggestions** section explains every change. Words you substituted from another language because you did not know them are replaced with the right one:

> **Tafadhali nipe Butter.** → *Tafadhali nipe siagi.*
> — Butter → siagi: German for "butter".

Input in any other language is still translated into your learning language, exactly as before. The setting persists across restarts, and the action button changes to "Improve" while it is active.

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

## What It Actually Costs

Paying per use puts people off, and usually for a reason that turns out not to apply: most of us have only ever met the subscription model, where an app charges a monthly fee whether you open it or not, and around €5 a month is normal for a translation app. So "bring your own API key" reads as *another* subscription, on top of a setup step.

It is not. An API key is metered credit. You are billed for the text you actually send and receive, priced per million tokens — roughly per million word-pieces. A translation is a few hundred of them. Nothing accrues on the days you do not use the app.

**None of it reaches us.** Tafsiri is open source and free, there is nothing to buy here and no revenue share behind any of it — no referral links, no affiliate codes, no cut of what you spend. The links below go to the providers' plain pricing pages. The contract you enter into is with the third party you name in Settings — Mistral AI, Anthropic or OpenAI — under their terms, their billing and their privacy policy. We are not a party to it and cannot see it: your key stays on your device, and we have no account through which your usage would even be visible to us. The one thing in the app that could ever send money our way is the “buy me a coffee” button in Settings, which is voluntary, unrelated to your usage, and changes nothing if you never press it.

We build it this way because we use the same bring-your-own-key method ourselves and think the pricing is fair. That is a judgement, and judgements expire. If it stops being true — rates rise sharply, a free tier disappears, terms turn unreasonable — we will say so in this section, change the approach, or both.

Here is what that works out to. Tafsiri's prompts are a fixed size and can be measured, so these are calculated from the real thing rather than guessed. The rates are Anthropic's for Claude Haiku 4.5, the model Tafsiri uses: $1 per million tokens in, $5 per million out.

| One request | sent | returned | cost |
|---|---|---|---|
| Translation | ~410 tokens | ~50 tokens | **$0.0007** |
| Correction with suggestions | ~780 tokens | ~150 tokens | **$0.0015** |
| Translation with word explanations *(coming)* | ~710 tokens | ~250 tokens | **$0.0020** |

Fractions of a cent are hard to picture, so scaled up to a month of steady use — thirty requests every single day, which is a lot of translating:

| A month at 30 requests a day | cost |
|---|---|
| All plain translations | **$0.63** |
| All corrections | **$1.35** |
| All translations with explanations *(coming)* | **$1.80** |

Under two dollars a month for the heaviest mode, run every day. Mixed real use lands nearer a dollar. ChatGPT via `gpt-4o-mini` is cheaper still, and Mistral's free tier costs nothing at all.

**What you get for it** is the part worth weighing against a subscription. Not word-for-word substitution, but a translation that reads as the language is actually spoken. Correction mode, which does not merely translate but rewrites what you wrote the way a native speaker would and explains every change. Explanations of the essential words, with their part of speech and their derived forms, coming with the next release. That is a tutor's work, and it costs about what one coffee a year costs.

**Two honest caveats.** Providers sell credit in blocks rather than by the cent — typically from $5 — so that is what you load up front, not what you spend per month; at the rates above it lasts a long time. And published rates change: [Anthropic](https://www.anthropic.com/pricing#api), [OpenAI](https://openai.com/api/pricing/) and [Mistral](https://mistral.ai/pricing) each list their current ones. Every provider's console shows what you have actually spent, and lets you set a hard spending limit — worth doing on day one.

---

## Supported AI Providers

| Provider | Model used | Free tier |
|---|---|---|
| **Mistral AI** | `mistral-small-latest` | Yes — generous free tier |
| **Anthropic Claude** | `claude-haiku-4-5` | No — pay as you go |
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
- **Correction Mode** - For learners. Switch to that mode and your message in (mostly) learning language will be improved. 

---

## Building for Android

```bash
./build_android.sh          # the APK for a release and the AAB for Play
./build_android.sh --apk    # just one of them
```

Needs `android/key.properties` with the upload key; without it Gradle signs the release with the debug key, and the script stops rather than hand you an artefact Play will reject.

---

## Desktop (Linux, Windows and macOS)

Tafsiri also runs on the desktop. Translation, history, favourites, settings and backup all work there, and so does image-to-text once Tesseract is installed (see below). Pasting a screenshot with **Ctrl+V** works on Linux and Windows — on macOS that is not implemented yet. Voice input is the one gap on Linux: `speech_to_text` has no implementation there, so the microphone button is not shown at all; on Windows and macOS it is.

**Linux** — on Debian, Ubuntu, Mint and their relatives, take the `.deb` from the [latest release](https://github.com/rdOxalis/tafsiri/releases/latest); it needs no Flutter SDK and no build:

```bash
sudo apt install ./tafsiri_<version>_amd64.deb
sudo apt remove tafsiri          # settings and history are kept
```

To build from source instead, you need the Flutter SDK and `libgtk-3-dev`:

```bash
./install.sh          # builds and installs into ~/.local, no root required
./install.sh --uninstall
./build_deb.sh        # builds the .deb and the .tar.gz into build/deb/ instead
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
./build_macos.sh --package    # a .dmg to hand to someone else
./build_macos.sh --package=both  # …or a .dmg and a .zip
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

Full privacy policy: [docs/privacy-policy.md](docs/privacy-policy.md) — also linked from inside the app, at the foot of the translator screen and in Settings under About.

---

## Tech Stack

Flutter (Dart) · Android · Linux · Windows · SQLite · Riverpod · Google ML Kit · speech_to_text

---

## License

MIT
