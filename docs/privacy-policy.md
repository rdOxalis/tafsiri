# Privacy Policy — Tafsiri

**Last updated:** 2026-10-09

## Overview

Tafsiri is an AI-powered translation app. This policy explains what data is processed and how.

---

## Data We Collect and Process

### Text you enter for translation
Text entered into the translation field is sent to the AI provider you have configured (Mistral, Anthropic Claude, or OpenAI ChatGPT) via their respective APIs. This is necessary to perform the translation. Please refer to the privacy policies of these providers for details on how they handle your data:

- Mistral AI: https://legal.mistral.ai/terms/privacy-policy
- Anthropic (Claude): https://www.anthropic.com/privacy
- OpenAI (ChatGPT): https://openai.com/policies/privacy-policy

### Camera
The camera permission is used exclusively for OCR (optical character recognition) to extract text from photos. Image processing is performed **on-device**, by Tesseract — an open-source recognition engine built into the app. No images are uploaded to any server, and no Google service is involved.

### Microphone
The microphone permission is used exclusively for speech-to-text input. Voice recognition is performed **on-device** using the Android speech recognition framework. No audio recordings are uploaded to any server.

### Translation history
Your translation history (source text, translated text, languages, timestamp) is stored **locally on your device** in a SQLite database. This data is never transmitted externally.

### API keys
API keys you enter in Settings are stored **locally on your device** using Android's SharedPreferences. They are never transmitted to anyone other than the respective AI provider when making translation requests.

---

## Data We Do NOT Collect

- We do not collect analytics or usage statistics.
- We do not show advertisements.
- We do not have a backend server.
- We do not transmit your API keys to any party other than the AI provider you have selected.

---

## Third-Party Services

The app makes two kinds of network request, and only these two:

1. **Your input text, to the AI provider you configured** — Mistral, Anthropic or OpenAI, as described above. This is the only time anything you wrote leaves your device.
2. **Text recognition data, from GitHub — once per language.** The first time you read text from an image, the app downloads the trained language data for your two configured languages from the public repository of the Tesseract project on GitHub (`raw.githubusercontent.com`), a few megabytes each. The request names only the language file it wants. It carries nothing about you, your images or your text, but as with any web request GitHub sees your IP address. The files are kept on your device and are not downloaded again. GitHub's privacy statement: https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement

No other data leaves your device.

---

## Children's Privacy

This app is not directed at children under the age of 13.

---

## Changes to This Policy

We may update this policy. The current version is always available at this URL. Continued use of the app after changes constitutes acceptance.

---

## Contact

If you have questions about this privacy policy, contact us at:
**mail@njerahouse.com**
