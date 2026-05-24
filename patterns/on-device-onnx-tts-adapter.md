# On-Device ONNX TTS Adapter

- **Source:** https://github.com/supertone-inc/supertonic
- **Author:** Supertone Inc.
- **License:** MIT sample code; model terms depend on the selected ONNX assets
- **Extracted from:** `py/`, `nodejs/`, `web/`, `rust/`, `swift/`, `README.md`
- **Reviewed:** 2026-05-23

## Pattern

Run text-to-speech as a local ONNX-backed service with a stable HTTP contract, rather than embedding a speech model separately into every agent, browser extension, or desktop app.

The useful boundary is: app sends text, language, voice style, speed, and quality controls; the local service owns model loading, text normalization, inference, WAV encoding, and asset paths.

## Why It Works

On-device TTS has three competing needs: privacy, latency, and integration simplicity. Directly embedding ONNX Runtime in every client creates duplicated model-loading code and inconsistent behavior. A local adapter gives every client the same speech surface while keeping text and generated audio on the machine.

## Recommended Shape

1. **Pinned assets:** store ONNX graphs, config, tokenizer/index data, and voice-style JSON at a known version or checksum.
2. **One model host:** load the model once in a local service process.
3. **Small request contract:** accept text, language, voice/style ID, speed, quality steps, and output format.
4. **OpenAI-compatible shim:** expose `/v1/audio/speech` when tools already understand OpenAI-style audio APIs.
5. **Native endpoint:** expose a richer `/v1/tts` endpoint for batch synthesis, voice JSON import, and runtime options.
6. **Client libraries stay thin:** browser, agent, CLI, mobile, and desktop clients call HTTP instead of owning ONNX graph details.
7. **Consent and license layer:** keep custom voice files and model-license rules explicit at the service boundary.

## Runtime Options

- **Python service:** best default for fast iteration, local HTTP, and model/package ecosystem support.
- **Browser/WebGPU:** good for demos and local-first web apps where text should not leave the browser.
- **Swift/iOS or Flutter:** good for native mobile/offline clients when app-store packaging and binary size are acceptable.
- **Rust/C++/Go:** useful for lower-level embedded or edge deployments, but expect more native library friction.

## Safety Notes

- Treat voice-style files as sensitive user assets when they represent a real person's voice.
- Keep hosted voice cloning separate from local fixed-voice inference unless consent and rights are clear.
- Do not rely on a code license alone; model licenses and voice-style licenses may impose separate obligations.
- Bind local services to loopback by default.
- Add request limits for text length, batch size, and concurrent synthesis.
- Log minimally; raw text sent to TTS can be private.

## When To Use

Use this pattern when applications need private speech output, local/offline operation, or a drop-in local replacement for hosted TTS APIs.

Avoid it when model-license terms do not fit the product, when the target device cannot hold the model assets comfortably, or when voice identity/consent cannot be managed cleanly.
