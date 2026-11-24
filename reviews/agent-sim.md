# agent-sim (Developing-Gamer/agent-sim)

**Repo:** https://github.com/Developing-Gamer/agent-sim
**License:** Apache-2.0 for agent-sim; GPL-3.0-or-later for x86Sim patches; separate upstream component and Apple runtime terms.
**Reviewed:** 2026-11-24 (UTC)
**Revision:** 009ce33690de03719b954427000643bbc22dc75b on main; repository-wide static inspection, emphasizing Rust CLI/MCP/viewer, C hooks, setup/pool scripts, benchmarks and workflows.
**Release:** v0.1.0, published 2026-11-23; annotated tag resolves to fd185b3edf8e4f690ea05bbe414fe93fe1250983, not the reviewed main revision.
**Verification:** Anonymous GitHub API, HTTPS clone, source inspection and public CI metadata. No installation, compilation, source execution, simulator boot, model calls or runtime tests performed.
**Stack:** Rust 2024, Clap, Tokio/Axum, OpenH264, C/Objective-C runtime hooks, Bash/Python; x86Sim/Darling/dynarmic/metal2vulkan/Mesa.
**What it is:** An agent-facing iOS simulator control layer for x86-64 Linux, not a general multi-agent simulation framework or a scored agent-evaluation suite.

---

## Verdict

⚠️ **Interesting — pilot on a disposable, single-trust VM, not a production device farm.** The implementation meaningfully connects accessibility snapshots, input, app installation and browser streaming to a real Apple simulator runtime via x86Sim. It has unusually useful performance and failure documentation, but unsandboxed processes, incomplete parity, persistent cross-run state and an immature delivery chain prevent a deploy-candidate recommendation. Its strongest fit is exploratory agent-driven app testing where Linux availability matters more than exact native behavior.

## What It Is

The product wraps x86Sim rather than implementing iOS itself. Apple's arm64 simulator programs run through Darling's macOS interfaces and dynarmic translation; Metal drawing reaches Mesa's CPU Vulkan driver through metal2vulkan. agent-sim adds a tuned phone configuration, upstream patches, injected accessibility/permission hooks, a Rust CLI, stdio MCP, IPA retagging, a warm-phone pool and an interactive browser viewer. [1][1] [2][2] [3][3] [4][4]

This distinction matters: the repository demonstrates an automation environment, not an autonomous agent, model service, task dataset, reward function or evaluation leaderboard. A calling agent supplies the reasoning and any model subscription. The normal fast profile changes pixel density and disables visual effects; the high-fidelity profile restores 3x rendering and effects but cannot repair compatibility-layer semantics. [1][1] [5][5] [6][6]

Anonymous metadata at review time reported 91 stars, 8 forks, zero open issues, creation on 2026-11-21 and last push on 2026-11-24 at 00:08:46Z. This is a very young public project; popularity and an empty issue queue are not reliability evidence. [17][17]

## Stack

| Layer | Technology / role |
|---|---|
| CLI and commands | Rust, Clap; delegates runtime operations to x86Sim and shell helpers |
| Agent interface | Hand-written newline JSON-RPC MCP over stdin/stdout |
| Observation and input | Injected C hooks emit accessibility JSON; Unix HID socket; memory-mapped framebuffer |
| Viewer | Axum HTTP/WebSocket, Tokio, OpenH264; inline browser client using WebCodecs |
| Runtime | x86Sim 0.5.2 default, Darling, dynarmic, metal2vulkan and Mesa lavapipe |
| Lifecycle / storage | Bash, Python, user systemd services; ordinary filesystem device data, caches and pool markers |
| Model / database | No built-in LLM provider or database service in the inspected implementation |

## Key Features

### Read, act, observe — with limits

The hooks walk native accessibility elements and WebKit content. Rust merges app, SpringBoard and web results into references such as @e3. Actions can use references, text or coordinates; MCP mutation calls normally sleep 900 ms and request another snapshot. This is useful feedback, not proof that the UI settled or the intended action succeeded. Launch/open add further waits; snapshot failures become text in an otherwise successful action result. [3][3] [4][4]

References resolve against a saved per-device snapshot, not a caller-bound observation ID. Concurrent users or a changed screen can therefore act on stale coordinates. Serialize access per phone and verify postconditions. Tool output is untrusted app/web content: nothing here makes screen text safe instructions for a model. [3][3] [4][4]

### Unencrypted device-build preparation

IPA installation extracts a local archive, copies/rewrites Mach-O platform markers and Info.plist metadata, then installs through x86Sim. It rejects encrypted FairPlay binaries; this is not App Store decryption or assurance that every device build will work. Installation working copies remain on disk and same-named inputs reuse work locations. Only install apps you trust and are authorized to use. [7][7]

### Warm pools and browser control

Pool acquisition uses atomic directory creation, a simple and useful contention primitive. The viewer streams H.264 only while clients watch, with keyframe recovery for lagging viewers. Neither feature establishes tenant isolation: a viewer token grants both sight and input, and pool release restarts the phone rather than erasing its data. [8][8] [9][9]

## Architecture

CLI/MCP → command layer → x86Sim process commands / HID socket / injected hooks → Apple runtime.

Framebuffer ring → Rust video conversion and OpenH264 → token-gated WebSocket → browser.

The Rust modules separate device discovery, process/health helpers, accessibility, input, IPA preparation, encoding and serving. That is a tractable structure for a small project. However, multiple languages, injected code and compatibility patches make end-to-end behavior substantially harder to validate than the CLI alone. The workspace denies unsafe Rust by default but selected memory-map, atomic and process-signal operations explicitly allow it; the C hooks and native dependency stack remain outside that lint. [2][2] [3][3] [4][4] [10][10]

## Evidence for Simulation and Evaluation Claims

- **Real implementation, not just a README:** accessibility extraction, HID actions, native-process orchestration and H.264 serving are implemented. Static inspection supports those mechanisms, not successful execution on an arbitrary host. [3][3] [4][4] [9][9] [10][10]
- **Performance evidence is author-reported:** BENCHMARKS documents approximately 54.7 fps Settings scrolling and 13.5 ms touch-to-frame on one Zen 5 configuration, CPU-dependent boot times, KSM memory savings, and high-fidelity tradeoffs. It identifies versions, machines, medians and unmeasured cases. These are not independent measurements from this review. [5][5]
- **Reproducibility is partial:** bench/run delegates to x86Sim's tests/perf.py, records machine/environment data and rejects scroll samples without enough frames. Not every documented comparison uses the same hardware, settings or repetitions. A complete raw dataset for the tables was not found in the reviewed tree; multi-phone simultaneous-animation performance and browser end-to-end latency remain unmeasured. [5][5] [11][11]
- **Smoke is not correctness:** bench/smoke checks launch status, process existence and coarse image color/luminance. A wrong screen can pass. Its Safari screenshots are not semantic assertions, and it prints failed-app counts without making those failures a nonzero exit at the end. It is not a comprehensive CI acceptance gate. [11][11]
- **Not native parity:** the project's matrix explicitly lacks XCTest/XCUITest, debugger/Web Inspector and cloning. Known issues include Safari video failure, missing Maps tiles, Siri not opening, rare frozen Safari and whole-phone freezes after Darling exits. Therefore neither exact native rendering nor production app compatibility is established. [6][6] [12][12]

## Execution Authority, Permissions and Privacy

**The VM is the trust boundary.** SECURITY explicitly says simulator processes are not sandboxed. Setup runs privileged package installation, enables user lingering, installs Darling into a root-owned system location when available, and rebuilds/replaces translator libraries. Pool setup can enable kernel KSM globally. These are host changes, not a harmless application-local install. WebKit's Gigacage is disabled as a compatibility workaround. [8][8] [10][10] [13][13]

MCP is local stdio with host-user authority, not a separately authenticated tenant service. It exposes install/uninstall, URL/deep-link opening and UI actions without a built-in human confirmation or per-tool policy layer. Device selection accepts explicit filesystem paths; UI access can reach whatever the app/phone is signed into. The dispatch also accepts some command names not listed by tools/list, including logs and clipboard, so the advertised list is not an authorization boundary. Keep credentials, production accounts and sensitive app data out of the VM. [3][3] [10][10]

Viewer defaults are better than the README's all-interfaces example: the CLI listens on loopback and creates 128 random bits from the OS. Both page and WebSocket check the token. Nevertheless serving is plain HTTP, the bearer token is printed in the URL, and the inspected handler has no separate read-only role, WebSocket Origin check or explicit rate limiting. Treat browser history, proxy/access logs and copied URLs as secrets; use an authenticated encrypted tunnel or properly configured TLS proxy rather than public exposure. [9][9] [10][10]

The accessibility hook reads labels and values, including a fallback to native text-field contents; the inspected emitter has no explicit secure-text-entry redaction. Do not assume password fields are safely omitted. Snapshots, hook JSON, logs, screenshots, recordings and installation copies can persist. Screenshots and text returned through MCP may then reach the calling agent's provider; provider retention and cost are outside this repository. [3][3] [4][4] [7][7]

**Egress and costs:** installation contacts GitHub, OS package repositories and Apple for an approximately 8 GB runtime; rebuilding pulls further upstream sources/submodules. Running Safari/apps can contact arbitrary services or private-network destinations reachable from the VM; open_url accepts deep links too. No application-level network allowlist or model billing controls were found. No built-in paid model/API requirement was identified, but compute, disk, downloads, viewer bandwidth, optional VM snapshots and any external agent provider can cost money. No such services were used for this review. [1][1] [3][3] [8][8] [10][10]

## Persistence and Recovery

Phone data survives stopping/restarting. Pool release is not a clean test reset: installed apps, sessions and data survive, and there is no lease timeout/owner identity. The release worker removes the held marker even if its restart/wait chain fails; a worker killed before cleanup can instead leave a stale hold. State cleanliness and recovery need external supervision. [8][8]

phone.sh clears stale framebuffer/hook answers, restarts once for certain boot stalls and uses bounded waits. Health checks notice a missing Darling server, and the documented response is another up; frozen Safari may require terminate and reopen. This is pragmatic recovery, not automatic task replay, durable agent checkpoints or guaranteed rollback. The explicit erase command deletes the device directory and reruns setup. [10][10] [12][12]

Whole-VM memory snapshots are a provider feature, not per-phone checkpoint/restore implemented here. Reported roughly 19-second warm restores are specific external measurements, not a portable service guarantee. Disk-only restores still boot again and CPU placement may change. Preserve only deliberately clean caches/images and test recovery separately. [5][5]

## Licensing, Supply Chain and CI

The root contains Apache-2.0 terms; x86Sim patches explicitly carry GPL-3.0-or-later. Keep notices and evaluate redistribution obligations for the actual assembled runtime, not just the CLI. Apple's runtime is downloaded separately and is not relicensed by Apache-2.0. This review does not establish that Linux use or redistribution is permitted by Apple's applicable agreements; resolve that before organizational adoption. No upstream code was extracted into this review. [1][1] [13][13] [14][14]

Cargo.lock and --locked CI/builds help pin Rust resolution. The installer defaults to a moving latest release and only verifies its downloaded checksum if the checksum fetch succeeds: a missing sidecar is fail-open. The x86Sim AppImage download in setup has no explicit digest verification before execution/extraction. Checked-in prebuilt hook dylibs reduce the Mac prerequisite, but CI rebuilding them is not a byte-for-byte provenance check against those shipped binaries. Actions use mutable version tags and the Rust toolchain is stable rather than an exact release. No signing/attestation or vulnerability audit step appears in the inspected release/CI workflow. [2][2] [13][13] [15][15]

There are 13 literal Rust test attributes covering helper-level behavior such as retagging, CLI shape, MCP schema/base64, input and pixel handling. Public CI run 45294734560 for the exact reviewed SHA reports success for format, Clippy, cargo test, locked release build and the macOS hook-build job. That is observed upstream status, not tests run by this reviewer. The workflow does not boot an iOS runtime or run bench/smoke; simulator compatibility, permissions and recovery paths are not proven by its green checks. [15][15] [16][16]

## Comparison

| Aspect | agent-sim | x86Sim directly | Apple Simulator + Appium XCUITest |
|---|---|---|---|
| Main attraction | Tuned agent observation/actions, hooks, IPA conversion, pool and stream | Underlying Linux runtime with broader device families and its own CLI/MCP | Native Apple testing route and XCUITest-based automation |
| Host | x86-64 Linux with substantial setup | x86-64 Linux | macOS/Xcode environment for the iOS driver |
| Evaluation | Must add tasks, scoring, reset and isolation | Must add task/evaluation orchestration | Existing test automation ecosystem; still requires your assertions |
| Tradeoff | More integration convenience and extra patch/hook maintenance | Fewer agent-sim-specific moving parts | Mac requirement; avoids this Linux compatibility stack |

x86Sim itself already has MCP; agent-sim's differentiator is not simply “MCP for iOS.” Check whether upstream now covers the needed feature before taking on downstream patches. Prefer the native path for authoritative compatibility/release gates, and agent-sim for a disposable Linux experiment. Alternatives were checked via their public documentation, not benchmarked. [6][6] [18][18] [19][19]

## Self-Hosting Notes

Use a dedicated disposable Ubuntu 24.04-class x86-64 VM, not a credential-bearing workstation or shared multi-tenant host. The README recommends 8+ CPUs, 16 GB RAM and 60 GB disk; CPU generation materially changes responsiveness. GPU-free does not mean cheap or lightweight. Review Apple terms first, then pin and independently verify all downloaded artifacts before any future authorized install. [1][1] [5][5] [13][13]

For a pilot, use synthetic app data, one agent per phone, constrained egress and loopback/tunneled viewer access. Establish explicit clean-state provisioning rather than trusting pool release. Measure representative app workflows, secure-field handling, browser video needs, crash recovery and concurrent load; define action postconditions and retain scrubbed evidence. No installation command is endorsed as a verified safe deployment recipe here.

## Verification and Limitations

Canonical source identity was normalized from the submitted .git URL and checked against the existing public review index: no prior same-source review was found. Public source and release/CI metadata were reachable anonymously. Review date is UTC; dynamic repository counts may change. Static inspection covered all principal modules/scripts and documentation, not a full security audit of every transitive component. No apps, models, accounts, paid services or private data were used. HTML/template, link/provenance and task-diff validation concern the review artifacts only, not the simulator's behavior.

## Evidence

All numbered source-file citations below pin the reviewed commit unless explicitly marked live metadata or alternative documentation.

[1]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/README.md
[2]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/crates/agent-sim/Cargo.toml
[3]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/crates/agent-sim/src/mcp.rs
[4]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/crates/agent-sim/src/ax.rs
[5]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/docs/BENCHMARKS.md
[6]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/docs/PARITY.md
[7]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/crates/agent-sim/src/ipa.rs
[8]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/scripts/pool.sh
[9]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/crates/agent-sim/src/serve.rs
[10]: https://github.com/Developing-Gamer/agent-sim/tree/009ce33690de03719b954427000643bbc22dc75b
[11]: https://github.com/Developing-Gamer/agent-sim/tree/009ce33690de03719b954427000643bbc22dc75b/bench
[12]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/docs/KNOWN_ISSUES.md
[13]: https://github.com/Developing-Gamer/agent-sim/tree/009ce33690de03719b954427000643bbc22dc75b/scripts
[14]: https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/LICENSE
[15]: https://github.com/Developing-Gamer/agent-sim/tree/009ce33690de03719b954427000643bbc22dc75b/.github/workflows
[16]: https://github.com/Developing-Gamer/agent-sim/actions/runs/45294734560
[17]: https://api.github.com/repos/Developing-Gamer/agent-sim
[18]: https://github.com/x86sim/x86sim
[19]: https://appium.github.io/appium-xcuitest-driver/latest/getting-started/system-requirements/

- [README and runtime architecture][1]; [Rust dependencies][2]; [MCP authority][3]; [accessibility and saved references][4].
- [Benchmarks][5]; [parity matrix][6]; [IPA conversion][7]; [pool lifecycle][8]; [viewer authentication/transport][9].
- [Complete pinned source tree][10]; [benchmark and smoke programs][11]; [known failures][12]; [setup/lifecycle/patch scripts][13].
- [Apache terms][14]; [CI and release workflows][15]; [observed exact-SHA CI run][16]; [live repository metadata][17].
- [x86Sim alternative][18]; [Appium XCUITest requirements][19]; [v0.1.0 release](https://github.com/Developing-Gamer/agent-sim/releases/tag/v0.1.0).
- Additional exact evidence: [security warning](https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/SECURITY.md), [installer](https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/install.sh), [secure-field-sensitive hook](https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/hooks/ax.c), [CLI defaults](https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/crates/agent-sim/src/main.rs), [GPL patch notice](https://github.com/Developing-Gamer/agent-sim/blob/009ce33690de03719b954427000643bbc22dc75b/patches/x86sim/README.md).

---

**Attribution:** Developing-Gamer/agent-sim and its contributors. Apache-2.0 with GPL-3.0-or-later patches and separate component/runtime terms. This is independent analysis, not an endorsement or legal opinion.
