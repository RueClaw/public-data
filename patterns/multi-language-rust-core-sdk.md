# Multi-Language Rust Core SDK

**Source:** [trymirai/uzu](https://github.com/trymirai/uzu)
**License:** MIT
**Extracted:** 2026-06-09

## Pattern

Keep the performance-sensitive runtime in one Rust core, annotate public domain types and methods once, then generate binding surfaces for each target language from the same contract.

This avoids the usual failure mode of local-runtime SDKs: a real implementation in one language, thin wrappers in two others, and slowly drifting behavior across Python, JavaScript, Swift, and WASM.

## Shape

Uzu uses a Rust proc-macro crate named `bindings` with backend emitters for Rust, N-API, PyO3, UniFFI, and WASM. Public API types use annotations such as:

```rust
#[bindings::export(Class)]
pub struct Engine { ... }

#[bindings::export(Implementation)]
impl Engine {
    #[bindings::export(Method(Factory))]
    pub async fn create(config: EngineConfig) -> Result<Self, EngineError> {
        Self::new(config).await
    }
}
```

The binding macro dispatches to backend-specific code generators:

```rust
let rust_tokens = Rust::method_companions(...);
let napi_tokens = Napi::method_companions(...);
let pyo3_tokens = Pyo3::method_companions(...);
let uniffi_tokens = Uniffi::method_companions(...);
let wasm_tokens = Wasm::method_companions(...);
```

The important move is not the exact macro implementation. It is the ownership boundary:

- Rust owns runtime behavior.
- Rust owns API schema and method metadata.
- Binding backends own language-specific conversion, async wrappers, iterator adapters, errors, and package generation.
- Tests validate generated SDKs rather than hand-maintained parallel implementations.

## When To Use

Use this pattern when:

- the core runtime has real performance, memory, or safety constraints;
- multiple language surfaces are product requirements, not nice-to-haves;
- API drift between SDKs would create support or security risk;
- a local/native runtime needs Python, Node, Swift, and browser/WASM access.

Good fits include local inference runtimes, search/index engines, media processing libraries, encrypted local stores, browser automation runtimes, and device-control libraries.

## Design Notes

- Keep the public domain model small and explicit. Binding generators amplify messy APIs.
- Treat async streams, callbacks, and error types as first-class binding concerns.
- Generate language-specific docs/examples from the same source where possible.
- Run per-language tests in CI; generation alone is not enough.
- Separate package publishing from core runtime release checks, but make release validation prove every SDK still works.
- Avoid hiding network, telemetry, or credential behavior behind convenience constructors. Generated SDKs multiply trust boundaries.

## Tradeoffs

This pattern adds macro/codegen complexity. It is overkill for a small wrapper or a single-language tool.

It is worth it when the alternative is maintaining separate Python, TypeScript, Swift, and Rust implementations of the same stateful runtime. In that case, codegen is cheaper than drift.

---

**Attribution:** trymirai/uzu, MIT License.
