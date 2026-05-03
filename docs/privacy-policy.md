# Privacy Policy — Tafsiri

**Last updated:** 2026-05-03

## Overview

Tafsiri is an AI-powered translation app. This policy explains what data is processed and how.

---

## Data We Collect and Process

### Text you enter for translation
Text entered into the translation field is sent to the AI provider you have configured (Mistral, Anthropic Claude, or OpenAI ChatGPT) via their respective APIs. This is necessary to perform the translation. Please refer to the privacy policies of these providers for details on how they handle your data:

- Mistral AI: https://mistral.ai/privacy-policy
- Anthropic (Claude): https://www.anthropic.com/privacy
- OpenAI (ChatGPT): https://openai.com/policies/privacy-policy

### Camera
The camera permission is used exclusively for OCR (optical character recognition) to extract text from photos. Image processing is performed **on-device** using Google ML Kit. No images are uploaded to any server.

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

The only third-party network communication this app performs is sending your input text to the AI provider API you have configured. No other data leaves your device.

---

## Children's Privacy

This app is not directed at children under the age of 13.

---

## Changes to This Policy

We may update this policy. The current version is always available at this URL. Continued use of the app after changes constitutes acceptance.

---

## Contact

If you have questions about this privacy policy, contact us at:
**rduenkelmann@googlemail.com**
