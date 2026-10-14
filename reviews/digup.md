# DigUp (ARahim3/DigUp)

**Repo:** https://github.com/ARahim3/DigUp
**License:** MIT; retain the copyright and permission notice when reusing substantial code. Model and bundled dependencies have separate terms.
**Reviewed:** 2026-10-14 (UTC)
**Revision:** f9b8106ffb8308b4f48b76149d270f7c2e6b4918, main; commit dated 2026-10-12. Scope: README, license, manifests, native app boundaries, core indexing/search/runtime, tests, release scripts, and a limited inspection of the portable shell.
**Verification:** Static source review only. No source, builds, app binaries, tests, or model inference executed.
**Stack:** Swift 6.2, SwiftUI/AppKit, SQLite FTS5, llama.cpp/Metal, EmbeddingGemma 2; Rust/Tauri portable shell in development.
**What it is:** A local desktop search app that finds selected files by meaning and exact text, returning the matching PDF page, media moment, or code location.

---

## Verdict

⚠️ **Interesting — pilot on a small, non-sensitive Mac folder set, not as a security boundary.** DigUp has a coherent multimodal retrieval pipeline, useful exact-word fallback, and unusually thoughtful index-version handling. Its public release history is only days old, privacy exclusions are best-effort heuristics, and neither runtime behavior nor performance was independently tested here. Keep Spotlight or an exact-text tool alongside it.

## What It Is

DigUp targets people who remember what a file contains but not its name: an image scene, a clause in a PDF, or a passage in a recording. The documented released application requires Apple Silicon and macOS 14 or later; the README says testing was on macOS 26. Windows/Linux are advertised as forthcoming even though portable engine paths and a Tauri shell already exist in this revision. Source presence is not proof of a supported cross-platform release. [1][2]

This is retrieval, not an answer-generating chatbot. Selected folders feed format-specific extraction, a shared embedding space, and a local SQLite index. Code search is opt-in and uses a separate database. Google DeepMind's public model card confirms that EmbeddingGemma 2 is a 740M-parameter multimodal model with 768-dimensional output and Apache-2.0 metadata; its multilingual and benchmark claims are upstream claims, not results independently reproduced for this app. [1][3]

## Stack

| Layer | Technology / role |
|---|---|
| Released Mac UI | SwiftUI/AppKit, menu bar, hotkey, native previews |
| Extraction | ImageIO, PDFKit, AVFoundation, Vision OCR on macOS |
| Embeddings | Q8_0 EmbeddingGemma 2 GGUF via llama.cpp; Metal on Mac |
| Retrieval | SQLite FTS5 + in-memory float16 vector matrix; exact scan |
| Process boundary | CLI/helper workers; newline-delimited JSON over pipes |
| Updates | Sparkle 2.10.0, pinned in Swift package resolution |
| Port work | Swift portable engine; Rust/Tauri 2 shell; PDFium, stb, miniz, SQLite and ffmpeg paths |
| Optional reference runtime | Python 3.12, MLX/mlx-vlm; not the normal shipped Mac inference dependency |

## Key Features

### Multimodal results with locations

Images, page text/images, document passages, audio windows, and video frames become segments with page/time locations. Audio uses 30-second windows; video combines sampled frames and soundtrack windows rather than indexing every frame. Long PDFs/documents receive an initial pass and subsequent completion. This gives useful navigation, but does not imply exhaustive visual-event recall or transcription-quality exact audio search. [1][4]

### Meaning plus exact words, without a vector service

Searcher loads 768-dimensional float16 vectors, scans every vector, adjusts semantic scores using modality means and a shared deviation, and combines them with FTS word coverage and file-kind hints. It retains a best segment per file. Exact identifiers receive different weighting; code definitions are resolved through textual heuristics, not a full compiler index. Search uses bound SQL parameters for FTS inputs. [5]

The design is simple and easy to ship: no external vector database or hosted embedding API. It is also linear in segment count. One million vectors alone require about 1.54 GB before search buffers and metadata; large corpora need measurement, not extrapolation from the README's millisecond claims. Ranking thresholds depend on the indexed corpus, and the code comments' internal recall improvements are not independent benchmarks. [5][6]

### Resumable indexing and vector compatibility

Indexer reconciles by path, size, modification time and inode/device, preserving embeddings on detected moves, queuing changes and deleting missing/excluded records in scope. SQLite WAL and transactions hold vectors and segment metadata together. Model fingerprints and a separate vector-version identifier avoid needless rebuilding when a runtime change preserves outputs. Reference-vector tests demand cosine agreement of at least 0.999, but explicitly skip when model files are absent. [6][7][8]

## Architecture

Selected folders → crawler/rules → format readers → helper embedding runtime → SQLite files/segments/FTS → full vector scan + keyword scoring → native result navigation.

DigUpKit owns the crawler, rules, extraction, index and search logic. LlamaRuntime owns native embedding; digup is both CLI and service/helper entry point. DigUpApp coordinates the native interface and workers. The alternative shell speaks JSON over stdin/stdout to a persistent search service: the inspected service is not an HTTP listener, so web authentication/CORS is not its deployment model. These are same-user processes, not isolation from a compromised account. [2][9]

The watchdog checks memory and time once per second, terminating a runaway indexing helper so its successor can skip the offending file. Default memory allowance is half physical RAM clamped to 4–8 GB, and per-file time limit is 15 minutes. This is useful failure containment, not a parser sandbox. [10]

## Security and Privacy

- **Local inference is supported by the inspected design, not independently proven network silence.** The normal model loader uses local files; download code uses pinned Hugging Face revision URLs and SHA-256 checks before installation. Sparkle performs update checks/downloads. No telemetry/upload path was found in the inspected core paths, but there was no packet capture or full dependency audit. Network providers still see ordinary connection metadata. [11][12]
- **Treat the index as sensitive derived content.** Plain SQLite stores paths, metadata, excerpts, FTS text and vectors; no application-layer database encryption is configured in the inspected database code. Temporary media and previews also exist. OS account permissions, disk encryption and backup policy matter; local-only is not protection against another process with the user's privileges. The app entitlements do not enable App Sandbox. [6][9][13]
- **Exclusions are not secret detection.** Rules reject selected key/certificate extensions and filename prefixes; CodeExtractor additionally rejects a private-key marker. An ordinary note or source file containing a password/token can still be indexed. Even a filename such as passwords.txt is not covered by the listed secret prefixes. Hidden paths, bundles, cloud-only placeholders and code/vendor paths have additional filters, but this is not a DLP guarantee. [14]
- **Git-ignore handling fails open.** When git cannot produce the kept-file list, GitRepos treats files as not ignored; tracked files are also included even if an ignore pattern would otherwise match them. Explicitly exclude sensitive repositories/folders instead of trusting .gitignore alone. This finding follows the actual fallback branches, not an executed exploit. [15]
- **Supply-chain defenses are uneven.** The model is revision- and hash-pinned; llama.cpp's tag is checked against a fixed commit; Sparkle is exactly pinned. The portable vendor fetch script downloads pinned versions over HTTPS without digest verification, including prebuilt PDFium. The Homebrew workflow validates signatures, developer identity and notarization before updating the cask; those checks were read, not rerun on the binary. [11][16][17]
- **Do not revive stale security claims.** The current Mac entry point clears DIGUP_WORKER_DIR unless running with a development defaults suite. CLI/development worker overrides still exist. This review does not claim the previous default-app override behavior remains exploitable. [18]

## Dependencies and License

The repository LICENSE is MIT, copyright 2026 Abdur Rahim. The model card declares Apache-2.0; llama.cpp and Sparkle are acknowledged separately by the project. Keep applicable notices when distributing an app or fork, and audit the complete dependency/license set for the chosen platform rather than treating the repository's MIT label as covering all bundled binaries. No code was extracted into this review. [3][19]

The Swift dependency graph is relatively small, but native model/runtime and media parsers remain substantial attack surface. Portable builds add C libraries, PDFium binaries, ffmpeg integration and a Rust/Tauri dependency tree. The Python manifest pins an mlx-vlm Git revision and selected package versions while allowing ranges for other packages; it is a reference/development path and should not be confused with the native Mac shipping stack. [2][16][20]

## Maturity and Verification

At retrieval on 2026-10-14 UTC, unauthenticated GitHub metadata reported **2,555 stars, 184 forks and 53 open issues/PRs combined**, creation on October 8 and latest push on October 12. Popularity does not establish stability. Two public releases were returned: v0.6.0 (October 9) and v0.6.1 (October 12). [21][22]

The v0.6.1 notes describe fixes for IME composition, non-ASCII folder paths, repeated indexing restarts, orphan helpers and runaway PDF memory use. That is evidence of responsive maintenance and real early-life rough edges; it is not independent confirmation that every fix works. Open items include cloud-placeholder indexing expectations and pause/resume behavior. Issue/PR titles were sampled, not adjudicated. [22][23]

Static inspection found Swift Testing suites for rules, code, folder selection, index storage, long files, text normalization, image sizing and reference embeddings, plus synthetic/code/multilingual evaluation query sets. A text scan found 92 lines containing @Test, not 92 executed or necessarily distinct test cases. The only checked-in GitHub Actions workflow at this revision is Homebrew release distribution, not a build/test matrix. The reference-vector suite can skip without downloaded models. [8][17][24]

**Actually verified:** public API/HTTPS accessibility without repository authentication; exact cloned SHA; core algorithm and schema; exclusion fallback behavior; license file; dependency pins; test and workflow source; public release metadata; upstream model-card metadata. Review artifacts received placeholder, link-scheme, trusted-template script/style and structural HTML checks.

**Not verified:** builds, test pass/fail, release signing/notarization, actual resource use, retrieval quality, supported OS behavior, parser exploit resistance, complete dependency vulnerabilities, and runtime network traffic. No source scripts or binaries were run. The shallow clone does not establish historical commit quality or full contributor history. HTML was structurally checked, not browser-rendered.

## Comparison

| Option | Prefer it when | Tradeoff against DigUp |
|---|---|---|
| Spotlight | Native filename, metadata and ordinary text search are sufficient | Already integrated; DigUp adds an explicit multimodal embedding pipeline and page/moment retrieval |
| [Recoll](https://www.recoll.org/) | Document-oriented full-text indexing is the main need | A more conventional lexical search workflow; not a like-for-like shared image/audio/video embedding interface |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Exact code/text matches, predictable CLI behavior and no persistent semantic index matter | No semantic scene/audio retrieval, but excellent complement for inspecting exact source |

These are workflow comparisons, not a fresh benchmark or comprehensive security review of the alternatives.

## Self-Hosting Notes

This is a desktop application, not a web service to expose. For a Mac pilot, use a small, explicitly selected non-sensitive folder set, budget roughly 865 MB for model downloads plus index growth, and keep cloud-only files downloaded locally if they must be searchable. Avoid indexing whole home folders initially. Check indexing failures and recall against known files before expanding scope. [1][11]

Source builds require the documented Xcode/toolchain and native llama.cpp build step; neither was run here. Treat Linux/Windows source as port work until a supported release and your own build/runtime checks establish otherwise. Protect index/backups like the source documents, and do not mistake the worker process or watchdog for an adversarial sandbox.

## Evidence

All repository links below are pinned to the reviewed SHA unless explicitly labeled live metadata.

[1] [README and advertised platform/features](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/README.md)

[2] [Swift products, targets and dependency versions](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Package.swift)

[3] [Google DeepMind model card (live upstream)](https://huggingface.co/google/embeddinggemma-2)

[4] [Segment construction and long-file processing](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/Indexer.swift)

[5] [Search algorithm, FTS and exact scan](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/Searcher.swift)

[6] [Schema, migrations and stored content](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/IndexStore.swift)

[7] [SQLite WAL, parameter binding and transactions](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/Database.swift)

[8] [Reference agreement gate and conditional skip](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Tests/LlamaRuntimeTests/ReferenceVectorTests.swift)

[9] [Pipe-based search protocol and preview files](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/digup/SearchService.swift)

[10] [Resource limits and recovery note](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/digup/Watchdog.swift)

[11] [Model pins and expected hashes](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/ModelFiles.swift)

[12] [Download verification; see also Updates.swift and Resources/Info.plist](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpApp/ModelDownload.swift)

[13] [App entitlements](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Resources/DigUp.entitlements)

[14] [Exclusion rules; see also CodeExtractor.swift](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/Rules.swift)

[15] [Git listing and fail-open ignore behavior](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/Crawler.swift)

[16] [Portable dependency acquisition](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/scripts/fetch-vendor.sh)

[17] [Only checked-in Actions workflow and release checks](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/.github/workflows/homebrew.yml)

[18] [Development-worker override guard](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpApp/App.swift)

[19] [MIT license terms](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/LICENSE)

[20] [Optional Python runtime dependencies](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/worker/pyproject.toml)

[21] [Live public repository metadata](https://api.github.com/repos/ARahim3/DigUp)

[22] [Live release history and notes](https://github.com/ARahim3/DigUp/releases)

[23] [Live issue/PR context](https://github.com/ARahim3/DigUp/issues)

[24] [Test source tree](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Tests)

Additional implementation references: [llama.cpp commit validation](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/scripts/build-llama.sh), [native runtime](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/LlamaRuntime/LlamaEmbedder.swift), [code extraction checks](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Sources/DigUpKit/CodeExtractor.swift), [Sparkle configuration](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/Resources/Info.plist), [Tauri manifest](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/shell/src-tauri/Cargo.toml), [evaluation inputs](https://github.com/ARahim3/DigUp/blob/f9b8106ffb8308b4f48b76149d270f7c2e6b4918/evals).

---

**Attribution:** Abdur Rahim / ARahim3/DigUp, MIT. EmbeddingGemma 2: Google DeepMind, Apache-2.0 per public model card. Independent static analysis; no affiliation implied.
