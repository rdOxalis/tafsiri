# Privacy Policy — Tafsiri

**Last updated:** 2026-11-15

## Overview

Tafsiri is an AI-powered translation app. This policy explains what data is processed and how.

---

## Data We Collect and Process

### Text you enter for translation
Text entered into the translation field is sent to the AI provider you have configured (Mistral, Anthropic Claude, or OpenAI ChatGPT) via their respective APIs. This is necessary to perform the translation.

### Flashcards
When you learn with flashcards, each answer you type is sent to the same AI provider to be checked, together with the card's text and your saved translation of it. An empty answer, or your saved translation typed back exactly, is decided on your device without a request. The first time you open "Learn", the texts of older favourites whose language Tafsiri does not know yet may be sent once to the AI provider, only to identify the language they are written in. Without an API key, nothing is sent and you grade your answers yourself.

Please refer to the privacy policies of these providers for details on how they handle your data:

- Mistral AI: https://legal.mistral.ai/terms/privacy-policy
- Anthropic (Claude): https://www.anthropic.com/privacy
- OpenAI (ChatGPT): https://openai.com/policies/privacy-policy

### Camera
The camera permission is used exclusively for OCR (optical character recognition) to extract text from photos. Image processing is performed **on-device**, by Tesseract — an open-source recognition engine built into the app. No images are uploaded to any server, and no Google service is involved.

### Microphone
The microphone permission is used exclusively for speech-to-text input, and only while you have started a recording in the dictation window. Tafsiri does not record or store audio itself: it hands the recognition to the speech recognition service of your device (on most Android phones Google's) and receives only the recognised text. Whether that service processes the audio on the device or on its provider's servers depends on the service, your device and the language, not on Tafsiri; its provider's privacy policy applies (Google: https://policies.google.com/privacy).

### Translation history and learning progress
Your translation history (source text, translated text, languages, timestamp) and your flashcard progress are stored **locally on your device** in a SQLite database. They are not uploaded anywhere; the only exception is the flashcard texts sent to your AI provider as described above. A backup file is written only where you choose, and contains your API keys only if you switch that on.

### API keys
API keys you enter in Settings are stored **locally on your device** using Android's SharedPreferences. They are never transmitted to anyone other than the respective AI provider when making requests.

---

## Data We Do NOT Collect

- We do not collect analytics or usage statistics.
- We do not show advertisements.
- We do not have a backend server.
- We do not transmit your API keys to any party other than the AI provider you have selected.

---

## Third-Party Services

The app itself makes two kinds of network request, and only these two:

1. **Text, to the AI provider you configured** — Mistral, Anthropic or OpenAI: what you translate, and when learning with flashcards, the card, your saved translation and your answer, as described above. These are the only times anything you wrote leaves your device through Tafsiri.
2. **Text recognition data, from GitHub — once per language.** The first time you read text from an image, the app downloads the trained language data for your two configured languages from the public repository of the Tesseract project on GitHub (`raw.githubusercontent.com`), a few megabytes each. The request names only the language file it wants. It carries nothing about you, your images or your text, but as with any web request GitHub sees your IP address. The files are kept on your device and are not downloaded again. GitHub's privacy statement: https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement

No other data leaves your device through Tafsiri. Speech input goes through your device's speech recognition service, as described under *Microphone*.

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
