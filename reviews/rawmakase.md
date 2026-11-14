# RAWmakase (pch/rawmakase)

**Repo:** https://github.com/pch/rawmakase
**License:** MIT core; separate dependency, model and asset terms apply.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** 68862fe8612d27bdcfc2de8dfde67238a2336f75, main; manifest version 0.5.0. Scope: desktop/CLI, workspace crates, exports, catalog storage, extensions, remote inference, packaging and tests; not a full dependency audit.
**Verification:** Static source review only. No application build, tests, photo processing, model download, provider call, installation or device access performed.
**Stack:** Rust 2024 / Rust 1.98+, egui/eframe, wgpu, SQLite, native RAW decoders, optional ONNX Runtime.
**What it is:** A cross-platform non-destructive photo developer and catalog manager with Lightroom-style controls, catalog import and script/agent control—not an AI image generator.

---

## Verdict

⚠️ **Interesting — a serious pilot candidate, not yet an archival Lightroom replacement.** The source contains substantial rendering, catalog recovery and file-safety engineering, with unusually candid parity research. But existing edits deliberately render through the newest engine, Lightroom compatibility is approximate, and filesystem fallbacks qualify the README's “all writes are atomic” claim. Trial copied libraries, keep original catalogs and finished exports, and validate your actual camera/display/filesystem combination before entrusting primary work.

## What It Is

RAWmakase combines a Library backed by SQLite with a Develop workspace, presets/profiles, local masks and retouching, batch exports, and a headless CLI. It imports compatible Lightroom Classic catalog metadata and develop settings into its own catalog rather than editing the source catalog. Original photo content is not the normal editing target: recipes live separately. Library move, rename and Trash operations nevertheless act on the actual files, so “non-destructive” does not mean read-only filesystem access.

The implementation is already broader than parts of its README: the README says JPEG XL export and HDR editing of rendered inputs are unavailable, whereas current export code and HDR/color documentation implement JPEG XL and selected HDR paths. Treat this review as a pinned-main analysis, not proof that every feature is in a downloaded 0.5.0 artifact. [README](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/README.md), [HDR contract](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/hdr.md), [export job](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-export/src/export/job.rs).

## Stack

| Layer | Technology and boundary |
|---|---|
| Desktop | egui/eframe with patched egui and winit; wgpu GPU presentation |
| Decode/model | Native Rust RAW/TIFF/decode crates; recipes, color and storage in rawmakase-model |
| Rendering | rawmakase-engine, CPU reference/export paths and GPU previews |
| Catalog | rawmakase-catalog with rusqlite/bundled SQLite; transaction and migration boundary |
| Output | rawmakase-export; metadata policy, ICC tagging, batch/queue and HDR encoders |
| Optional inference | ONNX Runtime; selection/denoise models, optional remote selection worker |
| Automation | Versioned loopback protocol, CLI client and stdio MCP adapter |
| Extensions | Native subprocesses, framed IPC/shared buffers; full user trust, not a sandbox |

[Manifest](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/Cargo.toml), [engine modules](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-engine/src/develop/mod.rs), [architecture](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/architecture.md).

## Key Features and Fidelity

### Lightroom migration is useful, not exact round-tripping

Catalog import preserves a useful library structure—ratings, flags, labels, keywords, collections and compatible recipes—with a source snapshot, integrity checks, active WAL/journal rejection, and transactional destination creation. Profiles are a separate concern: users must import Adobe DCP/XMP profiles they are licensed to use; Adobe profiles are not bundled. These controls reduce migration damage, but do not make the render engine Adobe's or guarantee every historical process version.

The parity ledger distinguishes fitted operators, incomplete behavior and research that is explicitly not merged. An open maintainer report, [#1079](https://github.com/pch/rawmakase/issues/1079), identifies pre-2012 Lightroom records selecting the wrong tone curve when both old and PV2012 curves exist. This is an upstream report, not an independently reproduced bug. Check older catalogs particularly carefully. [Catalogs](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/catalogs.md), [parity gaps](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/records/parity-gaps.md).

### Real color engineering, with explicit boundaries

Rendered RGB/grey inputs are decoded with their embedded ICC profile (sRGB fallback when absent) into linear ProPhoto RGB; unsupported CMYK is refused. Camera RAW development uses camera matrices, white balance, demosaicing and scene-tone processing before look/profile stages. The current engine uses destination-space channel clipping rather than a promise of lossless wide-gamut preservation. SDR exports support sRGB and Adobe RGB, plus ProPhoto in 16-bit TIFF, with embedded profiles and format validation. The SDR preview is not a soft proof of wide-gamut output.

Current HDR code maintains a master and an SDR rendition, with HDR TIFF/JPEG XL export paths and constrained supported adjustments. Upstream documents actual above-white display observation on macOS XDR, but not on real Windows or Wayland HDR displays; X11 has no HDR display path. Some HEIC HDR/gain-map behavior is platform-dependent. Animation, alpha, auxiliary depth data and unsupported container/color cases are not a universal lossless-edit contract. Do not use this as a format-preserving image transcoder. [Color contract](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/color-pipeline.md), [HDR](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/hdr.md), [export implementation](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-export/src/export/mod.rs).

### Preview speed and visual parity need separate acceptance tests

The renderer has resolution pyramids, draft/refinement, cancellation and cached stages; GPU previews are not the same evidence as full-resolution CPU exports. The public synthetic color corpus and separate hardware tests are valuable regression infrastructure, but chart tolerances do not establish accuracy across all cameras or photographs. Camera/profile/catalog fixtures and some GPU checks are opt-in; private photo-reference claims were not accessed or reproduced. [Rendering quality](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/rendering-quality.md), [corpus](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/tests/corpus/README.md), [GPU workflow](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/.github/workflows/gpu-parity.yml).

## Architecture

The workspace separates low-level file identity/rename primitives, RAW decoding, domain recipes, catalog transactions, rendering, export and optional inference. This is more than a GUI wrapper around an external RAW converter. UI, CLI and automation reuse domain operations; control commands carry explicit photo/generation/revision targets to avoid applying a stale request to the wrong edit. The automation transport bounds requests to 64 KiB and concurrent clients to 16, and cancels timed-out queued work before dispatch. Extensions run as supervised processes with Unix process groups or Windows kill-on-close jobs, plus bounded lifecycle handling; process cleanup is not security isolation.

[Filesystem primitives](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-fs/src/lib.rs), [control transport](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/src/app/shell/automation/socket.rs), [extension process lifecycle](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-extensions/src/process.rs).

## Persistence, Recovery and Data-Loss Risks

- **Recipes are not frozen renderers.** Every saved edit uses the current engine. Obsolete engine selectors are dropped; recipe schema/pipeline 11 and catalog version checks prevent some old-binary misreads, but do not preserve an old finished appearance. Keep rendered masters as well as recipes and source files. This is an explicit upstream policy, not a hypothetical bug.
- **Catalog migration has real recovery support.** Before a format-raising write, a verified SQLite backup is made beside the catalog; migration and the triggering write share a transaction. Newer features can raise the catalog to versions old releases reject. Backup space is required; mixed-version concurrent use is unsafe. Back up closed catalogs and separately retain originals and application assets, not just the executable. [Upgrade implementation](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-catalog/src/catalog/format_upgrade.rs), [DB boundary](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-catalog/src/catalog/db/mod.rs).
- **File operations are deliberately journaled.** Moves, renames, Trash and cross-volume copies track file identity and recovery state; conflicts and unsupported filesystem semantics can fail closed. Finished operation records are documented as forgotten after 30 days. Trash and operation history are not a permanent backup or indefinite undo guarantee. [Catalog storage/recovery](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/catalogs.md).
- **Atomicity has a concrete exception.** Storage normally stages, syncs and persists a sibling temporary file. But when exclusive publish/hard links are unsupported, notably macOS exFAT, no-clobber persistence copies into a newly claimed destination: a crash can leave a partial file. Failed-copy cleanup explicitly acknowledges a concurrent replacement race; ntfs-3g placeholder rename also documents a replacement race between identity check and rename. These are bounded filesystem/concurrent-writer cases, not a claim that ordinary edits destroy originals. They do refute an unconditional “all writes are atomic” reading. [Storage implementation](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-model/src/storage/files.rs), [rename fallback contract](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-fs/src/lib.rs).
- **Export overwrite is deliberate but consequential.** The exporter rejects RAW targets and canonical source-path overwrites, and requires an overwrite policy for existing output. No-clobber publication is the safer default. An explicitly overwritten previous export is still replaced; atomic replacement is not version history. An open user report, [#1084](https://github.com/pch/rawmakase/issues/1084), says some macOS JPEG exports acquire a hidden flag; not reproduced here.
- **Retention is broader than the catalog.** Profiles, presets, session state, previews, models and mask assets live in data/cache storage. Thumbnail payloads have a documented 512 MiB default LRU budget; caches are rebuildable, edits are not. Removing a library entry is not equivalent to wiping all historical catalog/backups/cache copies. Export metadata policy can carry location, contact, keywords and develop settings: choose and verify a privacy-appropriate output policy. [Metadata assembly](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-export/src/export/assemble.rs).

## Security, Privacy and Costs

Core development is local and does not need a hosted account or LLM API key. Local AI features add model downloads, disk use, CPU/GPU memory, runtime-library and model-license obligations—not per-photo API billing. Model installation code verifies expected digests; this does not establish the model's quality or replace license checks. No models were downloaded. Optional external agent clients can incur their own provider charges and transmit previews/catalog information they receive; the local MCP adapter itself is not a cloud confidentiality guarantee.

The editor control socket binds loopback and writes an OS-random token in a connection file with Unix mode 0600. Any local process able to read that token can control the app; adapter identity is cooperative, not a separate principal. MCP uses stdio and reads that existing token, opening no independent network listener. Granting an agent access therefore grants actual edit/save/export authority, not just read-only inspection. [Automation](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/automation.md), [MCP](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/mcp.md).

Remote inference is optional and off by default, and sends photo pixels to the chosen worker. Its plaintext TCP protocol has **no authentication**; the worker binary refuses non-loopback binds and documentation requires an SSH tunnel for another computer. Everyone able to reach the worker is trusted, including for cached masks addressed by deterministic content keys. The server keeps at most two analyses under a 512 MiB cache ceiling. SSH and host access policy—not the content key—provide the security boundary. [Worker](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-remote/src/bin/worker.rs), [server](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/crates/rawmakase-remote/src/server.rs), [remote inference](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/remote-inference.md).

Third-party extensions are full-trust native programs running with user permissions and inherited environment, despite process supervision. They can access files/network beyond the application's command interface. Review extension provenance and do not equate IPC validation with sandboxing. Native codecs, ONNX Runtime and GPU drivers also enlarge the attack surface when opening untrusted media; bounds and fuzzing are good signals, not an assurance against malicious files.

## Installation, Updates and Licensing

This is a desktop app, not a web service to self-host. The source requires Rust 1.98+, a C toolchain and a locked Rust dependency graph. Linux packaging has a modern glibc baseline (2.39 for the documented portable builds); HEIC depends on platform codecs. macOS requires 15+; Windows minimums differ by architecture and HEIC extensions may be needed. Package and codec availability/cost are external constraints. Cargo patches pin egui/winit forks, while fastframe components are Git/tag dependencies captured in Cargo.lock: useful reproducibility, additional maintenance coupling.

Update checks contact GitHub after launch and hourly unless disabled. Apple Silicon DMG and Windows installer paths can self-update; other installation types delegate to release/package-manager flows. The wrapper configures a publisher key and no automatic HTTP redirects, delegating signed download, host restrictions and rollback to fastframe-update. That external implementation and release binaries were not audited or executed here. Upstream states macOS DMGs are signed/notarized and Windows installers are not code-signed; do not confuse download integrity with verified publisher reputation. [Updater](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/src/updates.rs), [packaging](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/packaging/RELEASING.md).

The root MIT license permits reuse with its notice. Adobe DNG SDK-derived tables, CC0 compact ICC profiles, font licenses, Lucide ISC icons, Lensfun database CC BY-SA 3.0, Rust dependencies, ONNX Runtime and downloaded model assets keep their respective terms. No Adobe camera profiles are distributed by default. This review extracts no source code, images or models. [License](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/LICENSE), [notices](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/licenses), [dependencies](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/docs/dependencies.md).

## Maturity and Verification

Public GitHub metadata retrieved 2026-11-14 reported creation on 2026-09-26, last push 2026-11-13, 1,676 stars, 63 forks and 39 open issues/PRs combined. Latest listed release was v0.5.0, published 2026-11-12. These indicate activity, not safety. The latest returned CI run was successful at a different SHA, 36109daf02a34d194a89aa3e8ded46f0880476ff; this review does not claim the exact reviewed revision passed every workflow.

The repository includes cross-platform lint/test/build CI, dependency/advisory checks, CodeQL, nightly RAW fuzzing, synthetic color fixtures and targeted GPU parity runs. That is substantially better evidence than screenshots alone. Nevertheless this was static inspection: no tests run, no dependency advisory database refreshed, no crash-recovery simulation, no image-quality benchmark, no accessibility/latency assessment and no install/update signature verification. Documentation mixes current contracts with labeled historical/research material, and some README descriptions lag implementation. [CI](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/.github/workflows/ci.yml), [fuzzing](https://github.com/pch/rawmakase/blob/68862fe8612d27bdcfc2de8dfde67238a2336f75/.github/workflows/fuzz.yml), [public metadata](https://api.github.com/repos/pch/rawmakase).

## Comparison

| Option | Prefer it when | Tradeoff versus RAWmakase |
|---|---|---|
| [darktable](https://www.darktable.org/) | You want an established open-source catalog/develop workflow | Different processing model and Lightroom migration expectations; broader operational history |
| [RawTherapee](https://rawtherapee.com/) | Detailed RAW conversion is the main task | Not the same Lightroom-like library and agent-control workflow |
| [Lightroom Classic](https://www.adobe.com/products/photoshop-lightroom-classic.html) | Adobe rendering fidelity and existing catalog behavior are requirements | Commercial subscription/proprietary ecosystem; RAWmakase offers a local open core but not exact parity |

For a pilot, use a copied catalog and duplicated test originals, compare representative camera files and wide-gamut/HDR exports in a color-managed viewer, exercise recovery on the actual filesystem, and retain versioned backups plus finished rendered masters. Keep optional extensions/remote inference off until their trust boundaries are needed. A successful pilot could justify daily use; current source evidence does not justify discarding the old library or promising archival render stability.

---

**Attribution:** pch/rawmakase and RAWmakase contributors; MIT core with the separate component terms above. Independent analysis of public source only.
