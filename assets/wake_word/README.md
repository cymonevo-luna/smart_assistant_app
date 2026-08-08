# Wake-word models

## jarvis.onnx (DaVoice engine)

Placeholder. To make the DaVoice wake-word engine (`WAKE_WORD_ENGINE=davoice`)
actually work:

1. Email info@davoice.io requesting a free POC/non-commercial license and a
   custom wake-word model trained for the phrase "Jarvis".
2. They'll send back a license key and a `.onnx` model file.
3. Put the license key in `DAVOICE_LICENSE_KEY` (`.env` /
   `luna_jenkins/secrets/SMART_ASSISTANT_APP_ENV`).
4. Replace this file (`assets/wake_word/jarvis.onnx`) with the real model
   file they send, keeping the same filename.
5. Rebuild — `DaVoiceWakeWordEngine` (see
   `lib/features/assistant/services/davoice_wake_word_engine.dart`) loads it
   via `KeyWordFlutterPC.createInstance('jarvis.onnx', threshold, bufferCnt)`.
   The package (flutter_wake_word 0.0.44, pre-1.0) doesn't fully document how
   it resolves that filename on each platform — verify against a DaVoice
   example app if `createInstance` doesn't pick up the Flutter asset as-is.

## Porcupine engine (`WAKE_WORD_ENGINE=picovoice`)

No model file needed — "Jarvis" ships as one of Porcupine's built-in
keywords. Only `PICOVOICE_ACCESS_KEY` is required.
