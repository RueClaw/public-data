# Drowse (stdlogits/drowse)

**Repo:** https://github.com/stdlogits/drowse
**License:** AGPL-3.0-or-later; bundled fonts and downloaded models/data have separate terms.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** d47bf5365f7e199404dbf003894f195e14d4eaf1 — version 6.1.3; Python package, shared dashboard, artifact handling and CI. Commit dated 2026-11-12 UTC.
**Verification:** Static source review; no installation, application execution, model downloads, device access or paid calls. Upstream CI success checked separately, not locally reproduced.
**Stack:** Python 3.11+, PyTorch, Transformers, FastAPI/Uvicorn; Svelte 5, TypeScript, Vite; filesystem artifacts and browser IndexedDB.
**What it is:** A local mechanistic-interpretability workbench for inspecting and steering Hugging Face causal language models—not a sleep utility, agent memory service or cloud-model router.

---

## Verdict

⚠️ **Interesting — a serious local research workbench, not a validated truth detector or multi-user inference service.** Drowse joins branching conversations, activation interventions, concept geometry, neuron/head inspection, Jacobian lenses and sparse autoencoders in one coherent engine. Its provenance, request boundaries and artifact recovery are unusually deliberate; model-specific validity, expensive fitting, browser-owned chat retention and breaking format changes still require a bounded research pilot.

## What It Is

The canonical repository is **stdlogits/drowse**, attributed to Drowse Contributors; the README credits a9lim with Claude. The distribution is **drowse.ai**, while the CLI/import is **drowse**. Releases through 5.3.0 used **saklas**. This review concerns the Python server and bundled dashboard, not the separate **stdlogits/drowse.ai** browser/WebGPU runtime or its hosting infrastructure. Shared frontend code is not proof of backend parity. [README](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/README.md)

Researchers can generate a reply, select tokens, inspect alternative-token probabilities and internal measurements, and fork the conversation with altered steering. Six rooms organize Workbench, Units, Lens, Probes, Artifacts and Model. OpenAI- and Ollama-compatible endpoints are local serving interfaces: their names do **not** imply forwarding prompts to those companies.

## Stack

| Layer | Technology and consequence |
|---|---|
| Inference | PyTorch ≥2.13, Transformers ≥5.22, Accelerate; one loaded model per session |
| API | FastAPI/Uvicorn; native REST/WebSocket plus OpenAI/Ollama adapters |
| UI | Svelte 5/TypeScript/Vite; committed compiled bundle ships in the wheel |
| Research | Safetensors, fitted manifolds, lens families, SAE sources, neuron catalogs |
| Durable state | Configurable Drowse home directory; browser IndexedDB for saved chats |
| Optional acceleration | CUDA bitsandbytes/kernels, FlashAttention; Apple MPS and CPU paths |

[Manifest](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/pyproject.toml), [frontend manifest](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/package.json).

## Key Features and Architecture

### One intervention engine, separate measurement plane

A DrowseSession owns a GenerationEngine. SteeringComposer resolves expressions and installs per-layer SteeringManager hooks; the read plane independently plans hidden-state capture and instrument measurements. Probe-dependent gates connect them. Generation transactions and the server session lock serialize access to the mutable model. OpenAI/Ollama stateless requests do not append to the native conversation tree. This is a consistent research core, not independent implementations behind each UI surface. [Architecture](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/ARCHITECTURE.md), [engine](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/session/engine.py), [composer](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/steering/composer.py), [app](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/server/app.py).

### Geometry is more than a named prompt preset

Concepts are fitted from authored or generated corpora. A two-node flat manifold represents a bipolar direction; other fits use affine or curved geometry. Neutral-activation whitening separates write directions from read covectors. Layer selection, ablation, token/layer scopes and probe-triggered gates act inside model forwards, rather than merely prepending an instruction. Fit identity includes authored content, rendered token positions, model identity and policy version; stale results are not silently treated as current. [Fit pipeline](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/fit/pipeline.py), [geometry](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/geometry), [steering](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/steering).

### Rich readouts are hypotheses, not semantic guarantees

R-family lenses rank what a vector tends to make the model say; S-family lenses rank input-like content, with depth-dependent weighting. Units expose neuron/head writes and reads; optional neuron-lens catalogs supply generated labels and firing normalization. SAEs add sparse features. These are implemented mechanisms, but a probe named “deceptive” is not independently calibrated evidence of deception. Corpus construction, neutral baseline, model/dtype, layer choice and intervention strength can change a reading's meaning. Generated unit labels are interpretation aids, not ground truth. Reproduce paired unsteered/steered experiments and held-out behavioral effects before using a score in consequential decisions. [Lens](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/lens), [catalog](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/units/catalog.py), [methods](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/README.md#how-drowse-works).

## Permission, Execution and Authentication Boundaries

**Good defaults:** the CLI binds loopback. Without a key, API access checks the peer and Host; browser Origins must match or be explicitly allowed. Bearer comparison is constant-time. WebSockets authenticate before acceptance using a bearer header or encoded subprotocol, not URL credentials; stale token query parameters are scrubbed. Private responses are no-store. CSP, frame denial, no-referrer and device-permission restrictions are set. Request bodies default to a 64 MiB cap. Security tests cover cross-origin clearing, authentication before body consumption and response headers. [Security middleware](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/server/security.py), [tests](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/tests/server/test_http_security.py).

**Not tenant isolation:** one server owns one shared session/model with one configured API key, not per-user roles or independent stores. Native API access includes conversation and artifact operations. A trusted local process can call a keyless service; browser-origin defenses do not stop local malware. An authenticated collaborator is not a read-only viewer. Use separate processes/stores for mutually untrusted users, and TLS plus deliberate proxy handling for remote access. Body bounds are not GPU quotas or fair scheduling.

**Model code remains a major trust boundary:** repository Python defaults off; the environment toggle or explicit Python argument enables it. That grants model code the server process's privileges, not a sandbox. Config/tokenizer/weight reads are pinned to one resolved Hub revision, a consistency control but not a publisher signature. Native dependencies and optional acceleration packages still execute code during install/runtime. [Loader](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/model/load.py).

**Archive handling is substantive:** .drowse imports reject absolute/traversal/noncanonical paths, duplicate and case-colliding names, special files, and oversized/high-ratio archives. Limits include 4,096 entries, 512 MiB per file and 2 GiB expanded total. Tensor validation is separate. CRC and cache fingerprints do not prove author identity; a valid pack is not necessarily trustworthy science or authenticated provenance. [Archive codec](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/store/archive.py).

## Network, Credentials and Cost

- Local inference needs no OpenAI/Anthropic subscription or per-token provider payment. Costs are hardware memory, electricity, disk, downloads and fitting time. First default launch downloads weights and fits 17 bundled probes; lens/SAE fitting is additional work. No hardware budget was measured here.
- Hugging Face serves weights, packs, lenses/catalogs and optional datasets. Gated models may require accepted terms and Hub credentials. Drowse delegates Hub authentication to the client library; this is not an isolated credential broker.
- The dashboard API key is held in a module variable rather than written to browser storage by the HTTP-auth module. This does not protect against trusted-origin script compromise or an unencrypted remote connection. [HTTP auth](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/src/lib/runtime/http-auth.ts)
- Optional Neuronpedia detail retrieval sends model/source/feature identifiers to Neuronpedia. External catalog links leave the local origin. The contact form explicitly POSTs entered fields to drowse.ai and retains drafts in sessionStorage; server-side contact retention is outside scope. “Local” does not mean “no network anywhere.” [SAE descriptions](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/src/lib/saeDescriptions.ts), [contact](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/src/lib/stores/contact.svelte.ts)
- **Pack publishing can disclose corpora.** Push always exports the corpus, filters fitted tensors, and defaults new repositories to public unless private is requested. It removes stale root pack/artifact layout in the target Hub repository. Use a dedicated destination, inspect exports and dry-run before publication; excluding tensors does not exclude training text. [Hub publishing](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/store/hub.py)

## Persistence, Retention, Export and Recovery

The filesystem store holds authored manifolds/corpora, templates, fits, neutral statistics, lenses, SAEs and source bindings. It is not a conversation database. The live server does hold the native tree in memory: “keeps no conversations” means no automatic durable server chat storage, not that requests never enter memory. The browser saves chats between replies in IndexedDB; preferences/drafts use browser storage. No application-level encrypted-at-rest chat vault or centrally managed retention policy was established. Treat browser profiles, downloads, corpora and backups as sensitive. [Conversation library](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/src/lib/conversationLibrary.ts), [state documentation](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/README.md#state-and-distribution).

Chat backups contain a versioned record plus SHA-256, validate before import and enforce size limits; archives can carry multiple chats. Hashes detect accidental changes, not malicious rewriting by someone who can recompute them. Explicit deletion exists, but no universal time-based purge was found in reviewed chat/store paths. Browser clearing, quota errors, origin changes or an unsaved in-flight reply can affect recovery. Export before clearing data or upgrading. Python users explicitly choose a LoomTree save path. [Chat backup](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/src/lib/chatBackup.ts).

Artifact writes use same-directory staging, fsync/replace and stable cross-process locks. Fits publish only if the authoring revision still matches; incomplete tensor/sidecar pairs are cache misses. These are strong crash/concurrent-edit measures, not a substitute for backing up authored corpora. A .drowse pack transports one manifold closure and referenced template, **not** model weights, lenses, SAEs or the full home directory. GGUF control-vector export is narrower still. [Atomic IO](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/base/atomic.py), [fit publication](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/drowse/fit/publish.py).

Migration is an operational cost: README documents no general automatic old-format migration, no reading the old Saklas home, a pre-5.4 lens conversion script, incompatibility with 5.x saved conversations in 6.0, and refitting changed frames in 6.1. Current backup code recognizes some legacy names/versioned records; that is not blanket historical compatibility. Keep pre-upgrade exports and the original environment until restore is proven.

## Self-Hosting, Platform and Update Notes

Python 3.11+ is required. CUDA or Apple Silicon MPS is recommended; CPU support is not a promise of interactive large-model performance. Quantization is CUDA-specific and ignored with a warning elsewhere. FlashAttention auto-selects when installed. A model fitting in RAM does not assure that retained activations, KV cache and analysis fits fit too. UI builds require Node 24, but the packaged server already includes the built UI.

Support is feature-dependent: README lists exercised model families but says lens fits/unit reads refuse MoE and hybrid stacks, role extraction needs a suitable chat template, and published lenses/SAEs cover selected checkpoints. MPS fallbacks and text-only extraction from some multimodal checkpoints are real code, not universal compatibility. Windows is declared OS-independent and has lock handling; this review did not establish Windows GPU/packaging parity.

Python dependencies mostly use lower bounds, not a full environment lock. Frontend dependencies are pinned with a package-lock, including a tagged GitHub tarball for Ledger. Use a version-pinned isolated environment, retain dependency resolution records and qualify a small checkpoint before investing in large fits. No installer, updater or migration was run.

## Maturity, Tests, Releases and License

Public GitHub metadata on 2026-11-12 showed **15 stars, 1 fork, 1 open issue/PR aggregate**, creation on 2026-04-09 and last push on 2026-11-12. These are context, not quality measurements. **6.1.3** was released that day with wheel/sdist and attestation files; attestations were listed, not cryptographically verified.

CI defines lint, whole-project type checks, four CPU-test shards and frontend checks/build freshness. Tests cover security, archive IO, tiny-model sessions, geometry, concurrency, stream backpressure and browser persistence. **Upstream CI for this exact SHA reported success** ([run 43144334805](https://github.com/stdlogits/drowse/actions/runs/43144334805)); GPU tests are excluded from the CPU job. README real-model CUDA/MPS coverage was not reproduced. No local source tests or dependency vulnerability audit were run.

The release workflow runs independently on main pushes with no declared CI-success dependency. A released package alone is therefore not a test-pass guarantee. Mutable action tags and broad dependency ranges remain supply-chain inputs. [CI](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/.github/workflows/ci.yml), [release workflow](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/.github/workflows/release.yml), [release](https://github.com/stdlogits/drowse/releases/tag/v6.1.3).

The root license is AGPLv3 and the manifest explicitly specifies **AGPL-3.0-or-later**. Distribution and modified network-served versions carry copyleft/source obligations; this is not permissive code to silently embed in a proprietary service. Torph's included notice is MIT and Wix Madefor is OFL-1.1. Model, dataset, catalog and dependency terms remain separate. No implementation code was extracted. [License](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/LICENSE), [font notices](https://github.com/stdlogits/drowse/blob/d47bf5365f7e199404dbf003894f195e14d4eaf1/webui/public).

## Comparison

| Choice | Prefer it when | Tradeoff against Drowse |
|---|---|---|
| [repeng](https://github.com/vgel/repeng) | You want compact activation steering | Smaller conceptual surface; no equivalent integrated dashboard implied |
| [TransformerLens](https://github.com/TransformerLensOrg/TransformerLens) | Notebook-first custom interpretability experiments matter most | More experiment authoring; inspect model compatibility separately |
| [SAELens](https://github.com/jbloomAus/SAELens) | SAE training/analysis is the primary objective | Specialized ecosystem; Drowse can consume SAELens sources |
| [Ollama](https://github.com/ollama/ollama) | You mainly need convenient local chat/model serving | Not a replacement for internal readouts and intervention engine |

Functional comparisons, not head-to-head benchmarks or fresh audits of alternatives.

## Practical Recommendation

Pilot on public/synthetic prompts and one supported modest checkpoint. Keep Drowse loopback-only, leave remote model code disabled, export chats and authored packs, and record package/model SHA, dtype, corpus, probe setup and baseline with every result. Validate intervention effects independently before interpreting labeled coordinates as traits. Adopt for exploratory interpretability and reproducible experiments; do not deploy as a shared untrusted-user service or an automated honesty/safety enforcement layer based on this review.

**Limits:** static sampled implementation review, not a complete security audit, numerical reproduction, benchmark, all-model compatibility test or review of the separate hosted/browser backend. Public review artifacts were checked for provenance, links, template completion and standalone HTML structure; application rendering was not exercised.

---

**Attribution:** stdlogits/drowse, Drowse Contributors; AGPL-3.0-or-later. Public source and independent analysis only.
