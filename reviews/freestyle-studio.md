# Freestyle Studio (mushjacob/freestyle-studio)

**Repo:** https://github.com/mushjacob/freestyle-studio
**License:** MIT for Freestyle-owned code; bundled font licenses remain separate.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** 9ea8ec59918146ac3c388b43a8f015a5fe11f1e1, main; repository-wide inventory with detailed sampling of Disabelton, shared host/bridge contracts, Modesty dependency manifest, licensing and CI. Not an exhaustive seven-view audit.
**Verification:** Static source inspection and anonymous GitHub metadata only. No installation, source execution, account login, audio/model download, device access, live studio API probe or paid call. Upstream CI success was observed, not reproduced.
**Stack:** Browser JavaScript ES modules, HTML/CSS, Python HTTP/OAuth bridge, Freestyle Studio API, WebRTC and WebSocket.
**What it is:** Seven alternative browser studio interfaces for Freestyle's hosted music projects and audio engine—not an independently self-hostable DAW backend.

---

## Verdict

⚠️ **Interesting — credible cloud-DAW interface work, not an offline studio.** The host abstraction and receipt-aware editing/export controllers are useful engineering references. Adopt only if Freestyle account, service availability, project custody and costs are acceptable; the local server does not replace the cloud engine or prove professional audio reliability.

## What It Is

The README lists Disabelton, Illogic Amateur, Illogic Amateur Classic, Street Band, Trashlab, Vegetable Studio and Modesty. Each has a local browser entry point; embedded deployment instead receives a host object from Freestyle. Familiar studio-style layouts are views over one service, not seven distinct audio engines. [README](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/README.md)

The important distinction is between serving the interface locally and processing/storing music locally. The host contract maps projects, monitoring, engine sessions, pattern previews and edits to Freestyle. Browser audio arrives through WebRTC; live state uses an interactive WebSocket and data channels. Nothing inspected supplies a deployable replacement for that hosted service. [Host contract](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/docs/HOST_CONTRACT.md)

## Stack

| Layer | Tech |
|-------|------|
| UI | Plain JavaScript ES modules and per-view HTML/CSS; no framework build required by sampled package manifests |
| Local bridge | Python standard-library ThreadingHTTPServer, OAuth and API adapters; POSIX fcntl locking |
| Backend / data | Hosted Freestyle projects, engine sessions and render/export jobs |
| Realtime | WebRTC monitor/control/meter/editor channels; ticket-authenticated WebSocket |
| Optional dependency | Modesty declares websocket-client >=1.8,<2; optional certifi TLS-store fallback in sampled bridge |
| Development | Python 3.12+, Node.js 24; Node built-in test runner |

Sources: [package manifest](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/package.json), [bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py), [Modesty requirements](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/modesty/requirements.txt), [host contract](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/docs/HOST_CONTRACT.md).

## Key Features

### One host contract, two deployment contexts

The standalone host installs only when an embedded host is absent. Capability flags explicitly disable directEngine, share and mozart in standalone; unsupported engine mappings return 501. Pattern-arm and scene-launch support varies by view. This is a good boundary: UI presence is not evidence of backend availability or equal capabilities everywhere. [Contract](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/docs/HOST_CONTRACT.md), [standalone implementation](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/freestyle-standalone-host.js)

### Recording and export distinguish acceptance from durability

The recording controller freezes the original project/lane context, caps uploads at 25 MB, requires a consistent durable clip identity and re-reads canonical project state before confirming placement. Uncertain uploads are not automatically repeated. Export tracks job identity, rejects mismatched project/job receipts, respects retry hints and distinguishes ready, pending, failed and uncertain results. These are implemented safeguards, not measured guarantees. [Recording persistence](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-recording-persistence.js), [export controller](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-export.js)

### MIDI portability, but not complete project independence

The sampled app exposes MIDI import/export, cloud project snapshots, revert/history and cloud audio bounce. MIDI tests cover timing, polyphony, sustain, percussion and malformed data. MIDI cannot preserve the entire hosted instrument/effect/audio project, and a rendered mix is not an editable project backup. [App save/menu implementation](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/app.js), [MIDI tests](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/midi.test.mjs)

## Architecture

Browser view → host API → loopback Python bridge → Freestyle REST/MCP and cloud project engine. Realtime audio/control additionally uses WebRTC; state changes arrive through ticket-backed WebSockets. The Python adapter maps legacy-shaped tool calls onto public v1 operations, while explicitly AI-only actions such as compose/refine/mix-check use MCP. This is not a bundled local model runner. [Adapter](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/studio_api_adapter.py), [interactive sessions](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-interactive-session.js)

The repository contains 1,773 tracked files at this revision. Several views duplicate bridge and UI support modules; the contract acknowledges per-app host copies. Disabelton's app.js alone is 4,695 lines, often densely formatted. Small controller modules provide useful boundaries, but duplicated security-sensitive code and a large orchestration entry point increase maintenance and cross-view regression risk. The bridge copies are not byte-identical; this review does not infer identical security behavior across all seven. [Entry point](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/app.js), [contract](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/docs/HOST_CONTRACT.md)

## Security, Privacy and Costs

- **Local trust boundary:** the sampled server binds 127.0.0.1, checks Host, rejects foreign mutation Origins/cross-site requests, constrains static paths and excludes dotfiles. The API proxy validates paths and applies additional fetch-site checks. These controls are meaningful; they are not user authentication or protection against hostile same-user processes. Do not expose this bridge as a public multi-user service. [Bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py)
- **OAuth and permissions:** PKCE/state handling and refresh-token rotation are implemented. Credentials are kept server-side in an app-local JSON store with directory 0700/file 0600, flock locking and atomic replacement. This is permission-protected plaintext, not a keychain. Requested scopes include project/DAW writes, AI use, media upload, library writes and offline access—not read-only access. A supported environment bearer is another sensitive input. [Bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py)
- **Origin configuration:** FREESTYLE_BASE permits arbitrary HTTPS origins, with HTTP allowed only for loopback. That is operator configuration, not a verified Freestyle-only allowlist; a changed origin is a credential/data trust decision. Do not copy unreviewed environment settings. [Bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py)
- **Devices and cloud data:** recording uses getUserMedia; Web MIDI is requested through browser APIs. Uploaded recordings, project edits and remote audio sessions cross into Freestyle, while browser storage includes device identifiers and UI preferences. OAuth tokens stay out of normal browser API responses, but short-lived WebSocket tickets necessarily reach the client. Browser permission is not a cloud-data consent policy. [Recorder](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-recorder.js), [MIDI input](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/web-midi-input.js), [host](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/freestyle-standalone-host.js), [WebSocket](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-interactive-session.js)
- **Diagnostics:** the bridge sanitizes common credential/error forms and suppresses callback query strings in request logs. Its client diagnostic ring accepts bounded client-supplied entries, so do not assume every diagnostic export is free of project names, user text or signed URLs. Review diagnostics before sharing. [Bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py)
- **Costs and service terms:** the launch message calls for a Pro account; AI actions and cloud exports depend on service entitlement. The repository license is not a free-service promise. No current price, quota, retention/deletion guarantee, training-use policy or subprocessor list was verified; confirm these with the provider before uploading sensitive recordings. No provider/model calls were made. [Bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py), [AI routing](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/studio_api_adapter.py)

## Persistence, Export and Recovery

The app's Save action saves a snapshot in Freestyle, not a full local project archive. Browser preferences and a local auth file are not project backups. Recording placement reads back canonical state, and pending export observation can resume by job ID within the controller. However, the inspected export controller stores its receipt in memory; this alone does not prove recovery after browser restart. Preserve independent audio/MIDI exports and verify the provider's project backup/export facilities before relying on it for irreplaceable sessions. [Save implementation](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/app.js), [recording](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-recording-persistence.js), [exports](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/cloud-export.js)

A network failure can leave a write uncertain rather than safely retryable. The code's inspect-before-repeat approach is a strength, but recovery still depends on a reachable provider and trustworthy canonical state. Snapshot retention, complete project portability, outage recovery and cross-view undo behavior were not tested.

## License and Dependencies

[MIT](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/LICENSE) covers Freestyle-owned code (copyright 2026 Freestyle); retain its copyright and permission notice on redistribution. [Third-party notices](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/THIRD_PARTY_NOTICES.md) separately identify bundled fonts. The inspected Cuprum text is SIL OFL 1.1; Open Sans and Roboto Condensed bundles carry Apache-2.0 texts. Preserve those notices and applicable font conditions. [Cuprum](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/assets/fonts/Cuprum-OFL.txt), [Open Sans](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/assets/fonts/OpenSans-LICENSE.txt), [Roboto Condensed](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/assets/fonts/RobotoCondensed-LICENSE.txt)

Sampled package manifests have no npm runtime dependency list. Modesty's Python WebSocket dependency is range-constrained rather than exactly locked; dependencies retain their own licenses and were not installed or audited. No model weights were needed for this review, and no bundled-model license grants were identified. The UI MIT grant does not confer rights to the hosted engine, commercial service, uploaded samples, third-party plug-ins, generated music or model training data. Familiar product-inspired styling also should not be mistaken for trademark permission.

## Maturity and Verification

Anonymous GitHub metadata on 2026-11-27 reported 2 stars, 1 fork, 0 open issues and last push 2026-11-27T19:06:34Z. The releases endpoint returned no releases. Sampled package version is 0.2.0; that is not a tagged release or stability guarantee. [Repository metadata](https://api.github.com/repos/mushjacob/freestyle-studio), [releases](https://github.com/mushjacob/freestyle-studio/releases)

CI pins checkout/setup actions by commit, grants read-only repository permissions and disables persisted checkout credentials. It parses Python sources, checks app.js syntax, runs each view's MIDI test file and starts a local HTTP smoke server. Anonymous Actions metadata reported success for the exact reviewed SHA in [run 46054574733](https://github.com/mushjacob/freestyle-studio/actions/runs/46054574733). That upstream result does not validate live OAuth, cloud edit correctness, latency, recording quality, seven-view parity, browser/device compatibility or billing. [Workflow](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/.github/workflows/studio-checks.yml), [check script](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/scripts/check.py)

**Tests run here:** none from the submitted source. Review artifacts were checked for provenance, link/path validity, template integrity and public-only content. This is not a penetration test, dependency vulnerability audit, performance benchmark or live audio evaluation.

## Comparison

| Aspect | Freestyle Studio UIs | Ardour | LMMS / Audacity |
|--------|----------------------|--------|-----------------|
| Best fit | Custom interfaces for an existing Freestyle account | Local multitrack recording/editing/mixing | LMMS for local sequencing; Audacity for recording/waveform editing |
| Operational dependency | Hosted Freestyle engine and account | Local audio stack and plug-ins | Local audio stack; different scopes, not equivalent cloud views |
| Customization tradeoff | Small browser host contract, but provider API coupling | Broader native DAW architecture | Less direct fit for Freestyle integration |
| Custody | Projects and audio rely on provider | Local project files | Local project files |

Alternatives: [Ardour](https://ardour.org/), [LMMS](https://lmms.io/), [Audacity](https://www.audacityteam.org/). These are category comparisons, not benchmarks. Prefer a local DAW if offline operation and independent project custody are requirements; use this repository when the Freestyle-specific interface is the point.

## Self-Hosting Notes

You can host the **UI bridge**, not the complete backend. The README specifies Python 3.12+ and per-view ports 8080–8086; Node 24 is for development checks. Modesty adds its declared WebSocket dependency. The sampled server imports POSIX fcntl, so native Windows compatibility should not be assumed. No installation was performed. [README](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/README.md), [bridge](https://github.com/mushjacob/freestyle-studio/blob/9ea8ec59918146ac3c388b43a8f015a5fe11f1e1/Disabelton/server.py)

Keep the bridge loopback-only, review the broad OAuth scopes, protect the credential directory, use disposable non-sensitive projects for an initial authorized trial, and test export/reopen and uncertain-write recovery before production work. Do not treat local static hosting as air-gapped operation.

---

**Attribution:** mushjacob/freestyle-studio; Freestyle-owned code MIT, bundled fonts under separate licenses. Analysis based on the exact public revision above.
