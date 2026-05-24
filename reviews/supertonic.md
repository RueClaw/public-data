# Supertonic Review

- **Source:** https://github.com/supertone-inc/supertonic
- **Author:** Supertone Inc.
- **License:** MIT for sample code; accompanying model is OpenRAIL-M
- **Reviewed:** 2026-05-23
- **Commit:** `dff55dc00064c398736080c78195f577527832ae`
- **Verdict:** ✅ Deploy candidate for local TTS experiments; ⚠️ license-check the model before product use

## Summary

Supertonic is an on-device multilingual text-to-speech project centered on public ONNX model assets and multi-runtime example implementations. It targets local inference across Python, Node.js, browser/WebGPU, Java, C++, C#, Go, Swift, iOS, Rust, and Flutter.

The repo is not a polished single SDK. It is better understood as a cross-language reference kit around a shared inference contract: load four ONNX graphs, load voice-style JSON, normalize text with language tags, run duration prediction, text encoding, vector estimation, and vocoder stages, then write 44.1kHz WAV output.

That shape is valuable. It makes Supertonic a strong candidate for local voice interfaces, browser demos, mobile/offline speech, and agent tools that need private TTS without a hosted API. The main caveats are model licensing, asset size, and uneven example maturity across languages.

## What It Does

- Provides Supertonic 3 sample code for fixed-voice, local multilingual TTS.
- Supports 31 language tags plus `na` for language-agnostic text handling.
- Runs through ONNX Runtime on desktop, server, browser, mobile, and edge targets.
- Uses public Hugging Face model assets stored outside this GitHub repo.
- Shows native examples for Python, Node.js, browser/WebGPU, Java, C++, C#, Go, Swift, iOS, Rust, and Flutter.
- Documents a separate Python package and local HTTP server with native `/v1/tts` and OpenAI-compatible `/v1/audio/speech` endpoints.
- Includes benchmark images and tables for WER/CER, runtime footprint, model size, and v2-to-v3 comparison.
- Points to managed Supertone Play/API and Voice Builder for hosted workflows and custom voice JSON.

## Stack

| Layer | Tech |
|-------|------|
| Model runtime | ONNX Runtime, onnxruntime-web, ort, onnxruntime_go, Java ONNX Runtime, Swift ONNX Runtime |
| Python | onnxruntime, numpy, soundfile, librosa, PyYAML |
| Web/Node | Vite, onnxruntime-web/node, WebGPU fallback to WASM |
| Native examples | CMake/C++17, Rust/ort, Go, Java/Maven, C#/.NET, SwiftPM, Flutter |
| Assets | ONNX graphs and voice-style JSON from Hugging Face Git LFS |
| Model license | OpenRAIL-M |
| Sample-code license | MIT |

## Strong Patterns

### Stable ONNX Inference Contract

Every runtime implements the same four-stage path: duration predictor, text encoder, vector estimator, vocoder. That is a good deployment boundary because applications can choose their host language without changing the model contract.

### Local HTTP Speech Adapter

The Python SDK's separate `supertonic serve` direction is the most practical integration surface. A local service with native TTS and OpenAI-compatible speech endpoints lets agents, browser extensions, Electron apps, and local automations call one TTS runtime instead of embedding ONNX into every client.

### Browser-First Local Inference

The web example uses ONNX Runtime Web with WebGPU first and WASM fallback. That makes it suitable for privacy-preserving browser TTS demos where generated speech and text do not need to leave the device.

### Voice Styles As Portable JSON

Fixed voices and Voice Builder outputs travel as JSON style files. That is a cleaner interface than requiring every app to handle reference audio or zero-shot cloning directly.

See extracted pattern: [`patterns/on-device-onnx-tts-adapter.md`](../patterns/on-device-onnx-tts-adapter.md).

## Risks

- Sample code is MIT, but the model is OpenRAIL-M. Product reuse needs a model-license review, not just a repo-license check.
- The GitHub repo does not include model assets; full inference requires a Hugging Face Git LFS asset clone or Python package auto-download.
- Examples are uneven. Some are polished enough to build; others depend on missing local toolchains or native ONNX libraries.
- Go currently fails `go test ./...` under the local toolchain because `go vet` flags redundant-newline `fmt.Println` calls.
- C++ configure fails unless ONNX Runtime and nlohmann/json are installed locally.
- Web build succeeds, but `npm audit` reports Vite/esbuild moderate dev-server advisories.
- The README benchmark story is useful but should be repeated on target hardware before latency or quality claims are treated as product guarantees.

## Verification

Local verification on 2026-05-23:

- GitHub metadata: 9,899 stars, 1,019 forks, 69 open issues, latest release v2.0.0.
- `python3 -m py_compile py/*.py` passed.
- `cd nodejs && npm install --no-fund && npm audit --audit-level moderate` passed with 0 vulnerabilities.
- `cd web && npm install --no-fund && npm run build` passed; `npm audit --audit-level moderate` reported 2 moderate Vite/esbuild advisories.
- `cd rust && cargo check` passed.
- `cd swift && swift build` passed after downloading ONNX Runtime Swift binary artifacts.
- `cd go && go test ./...` failed on `go vet` redundant-newline warnings in `fmt.Println` calls.
- `cd cpp && cmake -S . -B build` failed because ONNX Runtime was not installed locally.
- Java verification was blocked because Maven was not installed in the local environment.
- Secret-pattern scan found no obvious live secrets.

Full synthesis was not run because the repo does not include the required Hugging Face model assets and pulling the model set would be a heavier artifact download than needed for this review.

## Recommendation

Use Supertonic when the goal is local, private, multilingual TTS and the OpenRAIL-M model terms fit the deployment. The Python package/server route is the most practical default; the browser/WebGPU and Swift/Rust examples are useful for client-native deployments.

For production use, pin the model assets, repeat latency and quality tests on target hardware, wrap the runtime behind one local service, and keep voice-cloning or custom-voice workflows behind explicit consent and licensing review.

**Attribution:** [supertone-inc/supertonic](https://github.com/supertone-inc/supertonic), sample code MIT; model OpenRAIL-M.
