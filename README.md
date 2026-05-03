# Tafsiri

**Tafsiri** is Swahili for *translation* — and that is exactly what this app does.

Tafsiri is an Android app for AI-powered text translation. It supports voice input, image-to-text (OCR), and a searchable translation history with favourites. The UI is available in 10 languages.

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
- **10 UI languages** — Swahili, German, English, French, Dutch, Spanish, Danish, Norwegian, Swedish, Polish

---

## Privacy

Camera and microphone are used entirely on-device (Google ML Kit OCR, Android STT). No images or audio are uploaded anywhere. Input text is sent only to the AI provider you have configured.

Full privacy policy: [docs/privacy-policy.md](docs/privacy-policy.md)

---

## Tech Stack

Flutter (Dart) · Android · SQLite · Riverpod · Google ML Kit · speech_to_text

---

## License

MIT
