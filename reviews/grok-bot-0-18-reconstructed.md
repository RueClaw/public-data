# grok-bot-0.18-reconstructed (b-nnett/grok-bot-0.18-reconstructed)

**Repo:** https://github.com/b-nnett/grok-bot-0.18-reconstructed  
**License:** No source license asserted; repository explicitly warns that no upstream source-code license is implied. Treat as research/reference only.  
**Reviewed:** 2026-08-23  
**Stack:** TypeScript, Electron 42, Vite/React 19, Node 26, ConnectRPC/Protobuf, AI SDK, Claude Agent SDK, OpenTelemetry, Docker integration  
**What it is:** An unofficial source-oriented reconstruction and extension of the public Grok Bot 0.18.0 macOS app, with readable Electron/host/coordinator/local-exec boundaries plus an inference router for Cursor, Claude Code, Codex, and OpenRouter.

---

## Verdict

📚 **Study it; do not deploy it as a normal app.** The reconstruction discipline is unusually careful: checksum-pinned upstream artifacts, clean-history publication checks, separate bundle identity, updater/telemetry guards, and explicit provenance warnings. But the repo has no usable source license, depends on reverse-engineered application behavior, keeps large original installers in Git LFS, has a red upstream CI run, and `npm audit --omit=dev` reports 27 production advisories including 3 high-severity issues.

---

## What It Is

This project reconstructs the public Grok Bot 0.18.0 desktop application into readable TypeScript. It is clear about its status: it is not Anysphere's original monorepo, not an official release, and not a claim that the reconstructed material is safe to redistribute.

The repo keeps two source roots. `source/` holds reconstructed Electron main, preload, host, coordinator, local execution, shared protocol, and agent runtime code. `frontend/` is a readable partial renderer reconstruction, but packaged builds retain the checksum-pinned shipped renderer and apply a narrow Router settings patch rather than claiming to have recovered the original frontend source.

The experimental extension is an inference router: new turns can be routed through Cursor, Claude Code, Codex, or OpenRouter while preserving Grok Bot-style tools, streaming, reactions, rich mentions, and local usage counters. It also adds an optional loopback-bound local Docker sandbox instead of the upstream remote box.

## Stack

| Layer | Tech |
|-------|------|
| Desktop | Electron 42.1.0, macOS Apple Silicon target |
| Runtime | Node.js 26.5.x, TypeScript 7 |
| Frontend workspace | React 19, Vite 8, TipTap |
| Protocol | ConnectRPC, Protobuf-generated agent services |
| Model/provider integrations | Cursor session, Claude Agent SDK, Codex Responses transport, OpenRouter, Vercel AI SDK |
| Local execution | Loopback HTTP ConnectRPC daemon, `/bin/sh -lc`, Docker sandbox option |
| Observability/deps | OpenTelemetry, Statsig package retained, Sentry/telemetry disabled by reconstructed package guard |
| Build/package | ASAR assembly, renderer hash manifests, ad-hoc signing, publication-tree verification |

## Key Features

### Evidence-gated reconstruction

The strongest part of the project is its provenance model. `PROVENANCE.md` pins the upstream macOS DMG and `app.asar` SHA-256, states that no upstream source license is implied, and requires UI-facing recovery to be backed by artifact anchors such as emitted code, strings, DOM signatures, IPC/RPC contracts, or repeatable runtime observation.

That is the right posture for this kind of work. It does not make redistribution risk disappear, but it avoids pretending that a binary reconstruction is ordinary open-source application code.

### Runtime/renderer split

The repo does not try to rewrite the whole polished UI. It compiles readable runtime/control-plane code, keeps the shipped renderer as the baseline, and applies a narrow hash-recorded Router settings transform. This reduces the amount of speculative UI behavior and keeps the reconstruction centered on inspectable boundaries.

### Provider router

The Router settings surface can choose Cursor, Claude Code, Codex, or OpenRouter. The coordinator keeps a local transcript tail for routed providers, bridges Grok Bot MCP tools into direct providers, streams assistant deltas back into the existing transcript UI, and records local usage totals when providers return usage.

### Local execution daemon

`source/box-exec-daemon/server.ts` implements a loopback ConnectRPC execution daemon with a bearer token, workspace-root path resolution, symlink rejection on file reads, background shell transcripts, foreground streaming shell execution, and timeout/abort handling. The default token is only `"local"`, so the loopback binding and sandbox boundary are doing most of the safety work.

### Packaging safeguards

Reconstructed packages use a distinct bundle identifier, ad-hoc signing, and a packaging guard that defaults official updates, Sentry, and upstream telemetry off. Tests assert that the guard is applied in both fallback and clean packaging paths.

## Architecture

The project has three unusual architecture boundaries:

- **Pinned binary artifact as spec:** the upstream app is a checksum-pinned input, not a vague inspiration source.
- **Readable runtime overlay:** reconstructed TypeScript replaces or overlays host/coordinator/main-process behavior.
- **Shipped renderer baseline:** the minified production renderer is retained, with only a narrow auditable settings patch.

The checked-in source tree is large: 1,722 TypeScript files under `source/` and 8 Node test files. The codebase includes host extensions, agent runner composition, MCP routing, local shell execution, transcript persistence, provider selection, update guards, packaging verification, and frontend reconstruction manifests.

## Security and Maturity

The repo is one day old at review time, with 47 stars and 14 forks. It has a GitHub Actions workflow for `npm ci`, typechecks, tests, frontend build, and publication-tree verification, but the latest upstream run was failing.

Local validation:

- `npm ci --no-audit --no-fund` completed on Node 26.5.0.
- `npm run typecheck` passed.
- `npm run source:typecheck` passed.
- `npm test` passed 17/18 tests; the one failure was expected in this clone because Git LFS payloads were not pulled, so the preserved installer size/hash test saw the LFS pointer file instead of the 155 MB DMG.
- `npm run frontend:build` passed with chunk-size and ineffective dynamic-import warnings.
- `npm audit --omit=dev --json` reported 27 production advisories: 4 low, 20 moderate, 3 high. High-severity direct issues included `piscina`, `undici`, and `ws`.

The repository's own `SECURITY.md` is candid: this is a small-club reconstruction, not a supported production distribution; do not reuse real credentials or sensitive accounts while experimenting with it.

## Comparison

| Aspect | grok-bot-0.18-reconstructed | grok-cli | Official desktop apps |
|--------|------------------------------|----------|-----------------------|
| Purpose | Reconstruct and extend a shipped desktop app | Native Grok-oriented terminal agent | Supported vendor UX |
| License posture | No source license; research only | MIT intent | Vendor terms |
| Interface | Electron desktop app | CLI/TUI/headless | Desktop app |
| Provider routing | Cursor, Claude Code, Codex, OpenRouter | Grok/xAI-centered | Vendor-specific |
| Tooling focus | Grok Bot tools, MCP bridge, local sandbox | CLI tools, skills, Telegram bridge | Product workflows |
| Deployability | Not recommended | Depends on current API health | Vendor-supported |

Compared with ordinary agent clients, this repo is more valuable as a reconstruction methodology and artifact-boundary case study than as a tool to install.

## Self-Hosting Notes

This is not a self-hosted service. To build it as documented, you need macOS Apple Silicon, Node 26.5.x, Xcode Command Line Tools, Git LFS, and optionally Docker Desktop. Bootstrap pulls or uses the pinned Grok Bot 0.18.0 DMG, verifies hashes, hydrates ignored build inputs, then packages a distinct ad-hoc signed app.

Practical cautions:

- Do not use sensitive accounts or credentials in this build.
- Pulling Git LFS artifacts is required for full archive tests.
- Treat the local execution daemon as high authority even with loopback binding.
- Review dependency advisories before running against untrusted content.
- Do not redistribute reconstructed code or packaged builds without a rights review.

---

**Attribution:** b-nnett/grok-bot-0.18-reconstructed. No source license asserted; repository derived from publicly distributed Grok Bot 0.18.0 binaries and includes its own provenance/notice warnings.
