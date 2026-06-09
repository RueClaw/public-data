# Uzu (trymirai/uzu)

**Repo:** https://github.com/trymirai/uzu
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-06-09
**Stack:** Rust 2024, Metal, CPU backend, Tokio, Rocket, PyO3, N-API, UniFFI, wasm-bindgen, Swift Package Manager
**What it is:** Uzu is a local and on-device AI inference engine aimed at shipping model download, model configuration, chat, classification, TTS, and OpenAI-compatible serving from one Rust core across Rust, Python, TypeScript, Swift, and WASM.

---

## Verdict

✅ **Deploy candidate for Apple/local inference pilots, with telemetry and platform caveats.** The repo is active, MIT licensed, well tested, and unusually serious about cross-language SDK generation from one core. The main caution is that default engine construction talks to Mirai services for registry and telemetry; use explicit configuration and review network behavior before embedding it in privacy-sensitive software.

---

## What It Is

Uzu is Mirai's inference engine for running AI models directly inside applications. The README frames the pitch as zero-latency, private, no-inference-cost deployment, with model download and runtime configuration handled by the engine.

The project is not just a wrapper around an existing local inference binary. The repository contains a native Rust engine, a Metal backend, CPU support, model/config machinery, token-stream parsing, JSON/grammar support, TTS runtime pieces, CLI tools, an OpenAI-compatible HTTP server, and generated bindings for multiple language ecosystems.

The strongest product shape is the "single core, many SDKs" approach. A developer can use the same conceptual API in Rust, Python, Swift, or TypeScript: create an engine, find a model, download it, open a session, and request a reply.

## Stack

| Layer | Tech |
|-------|------|
| Core runtime | Rust 2024 workspace |
| Local inference | `backend-uzu`, CPU backend, Metal backend |
| Model registry | Mirai remote registry, local Lalamo registry, OpenAI-compatible provider registries |
| Chat/session layer | `shoji`, `nagare`, `hanashi`, token stream parser |
| Structured output | JSON transform, JSON schema, xgrammar |
| Bindings | PyO3, N-API, UniFFI, wasm-bindgen, Swift Package Manager |
| CLI/server | Clap, Rocket, Tokio |
| App demo | SwiftUI macOS/iOS playground |
| CI | GitHub Actions on macOS, Linux, self-hosted Apple runners |

## Key Features

### Cross-language SDK generation from Rust annotations

The repo has a custom `bindings` proc-macro crate. Public Rust types and methods are annotated once with `#[bindings::export(...)]`, then companion code is emitted for Rust, N-API, PyO3, UniFFI, and WASM backends.

That is the right direction for a performance-sensitive engine: keep the runtime and API contracts in one place, then generate the bindings instead of maintaining separate SDK logic by hand.

### On-device Metal backend

The `backend-uzu` crate includes native Metal kernels for attention, matmul, sampling, RMS norm, embeddings, SSM/short-conv paths, MoE operations, audio kernels, KV-cache updates, and other runtime primitives. It also has build-time tooling for Metal compilation, generated headers, GPU types, and trait wiring.

This is more than a toy local-LLM wrapper. It is a low-level inference stack that is explicitly optimizing for Apple devices.

### Unified engine API

The top-level `uzu` crate exposes a high-level engine API that composes storage, registries, download management, local and remote backends, telemetry, and sessions. The README examples across Rust, Python, Swift, and TypeScript all follow the same flow.

That consistency matters if the engine is meant to be embedded in apps rather than used only from a CLI.

### OpenAI-compatible local server

The CLI can run a local HTTP server with `/v1/chat/completions` and `/v1/models` endpoints. Streaming is supported with server-sent events, and the server maps common OpenAI sampling parameters like `temperature`, `top_p`, `top_k`, and `max_tokens` into Uzu chat config.

The server is intentionally small, but it gives the engine an easy compatibility path for clients that already speak OpenAI-style APIs.

### Real test and release posture

The repository has unit, integration, kernel, performance, Python binding, and TypeScript binding tests. CI checks formatting, Metal formatting, clippy with warnings denied, cargo-deny, dependency lock consistency, sync generation, backend builds, tests, and binding validation. The latest observed push workflow on `main` completed successfully.

## Architecture

The workspace is split into clear crates:

- `crates/uzu` is the public engine surface.
- `crates/backend-uzu` contains the local inference backend, CPU/Metal kernels, model loading, sessions, speculators, grammar support, TTS runtime pieces, and performance tests.
- `crates/backend-remote` adapts OpenAI-compatible hosted/local services.
- `crates/download-manager` owns resumable file download state, locking, checks, and native Apple/universal download backends.
- `crates/bindings` and `crates/bindings-types` generate multi-language API surfaces.
- `crates/cli` provides CLI, benchmark, and OpenAI-compatible server modes.
- `bindings/swift`, plus generated Python/TypeScript binding infrastructure, expose SDK surfaces.

Two design choices stand out. First, backends and registries are trait-shaped, so local model execution, remote OpenAI-compatible providers, Mirai registry models, and local Lalamo exports can plug into the same engine. Second, generated binding annotations sit on the domain types rather than in per-language wrappers, keeping SDK drift under control.

## Comparison

| Aspect | Uzu | llama.cpp | MLX / MLX-LM | Ollama |
|--------|-----|-----------|--------------|--------|
| Primary shape | Embeddable multi-language inference SDK and engine | Portable C/C++ inference runtime and server ecosystem | Apple ML research/runtime stack | Local model server and app/runtime UX |
| Apple focus | High, with native Metal backend | Strong, but broader portability focus | Very high | Good as a user-facing runtime |
| SDK strategy | Generated Rust/Python/TS/Swift/WASM bindings | Many community bindings | Python-first, Apple ecosystem | HTTP/API and CLI-first |
| Best fit | Embedding local inference directly in apps | Broad local inference compatibility | Apple model experimentation and training/inference workflows | Running and managing local models as a service |
| Main caveat | Young, Mirai registry/telemetry defaults need review | API and model support can be low-level | Less productized as a cross-language app SDK | Less suited to embedding an engine in an app binary |

## Self-Hosting Notes

For local server use:

```bash
cargo run --release -p cli -- server --model trymirai/Qwen3.5-4B-M
```

By default, the server listens on `127.0.0.1:8000`. The README shows `--host 0.0.0.0 --port 8080`, but there is no obvious authentication layer in the small Rocket server. Do not expose it to a network without a reverse proxy, auth, rate limits, request limits, and clear model/resource controls.

The engine defaults to checking local Ollama and LM Studio endpoints and initializes Mirai registry and telemetry clients. That may be reasonable for a commercial SDK, but privacy-sensitive deployments should audit network paths, set explicit config, and look for or add an opt-out control before shipping.

---

**Attribution:** trymirai/uzu, MIT License.
