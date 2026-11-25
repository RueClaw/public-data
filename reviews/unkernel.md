# Unkernel (pithings/unkernel)

**Repo:** https://github.com/pithings/unkernel
**License:** Mixed: GPL-2.0-or-later project default; MIT SDK/page; GPL-2.0-only kernel components. Published package declares `MIT AND GPL-2.0-only`; additional renderer and distribution terms apply.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** `96e4bd7ebb54b93ad5ec68feab4eda94b3073927` (main; commit dated 2026-11-25T15:37:25Z). Scope: README, licenses, build/packaging/release workflow, sampled emulator and kernel integration, SDK, host mounts/networking, browser preview/storage, init and tests.
**Release observed:** `v0.2.0-261125-cec0a49`, published 2026-11-25T14:53:22Z, resolves to `cec0a49f5d028867955dbc19769fe9e810dc9384`; this is not the newer reviewed main commit.
**Verification:** Static source review only. Anonymous GitHub API and HTTPS clone succeeded. No installs, builds, source execution, browser demo, benchmarks, network probes or tests were run.
**Stack:** Linux C/patches, Zig aarch64 emulator/JIT, WebAssembly + JSPI, TypeScript SDK, React/Vite/Nitro desktop, IndexedDB.
**What it is:** A Linux kernel compiled to WebAssembly, with emulated unmodified arm64 user programs, embedded in Node or a browser. Not a container orchestrator, conventional unikernel, or a hardened multi-tenant sandbox.

---

## Verdict

⚠️ **Interesting — compelling local Linux runtime, not a ready-made hostile-code boundary.** The split between a wasm-compiled kernel and emulated user space is substantive, and the storage/recovery code is unusually thoughtful. Evaluate it for trusted browser labs, demos and embedded development; do not treat its same-origin preview, Node network backend or host mounts as safe defaults for untrusted agents.

## What It Is

Pooya Parsa’s Unkernel runs real Linux kernel subsystems rather than reimplementing a small selection of POSIX syscalls. Its `arch/wasm` port and Zig kwemu share Linux-managed page tables. User binaries are aarch64 instructions; syscalls return into the compiled kernel. The “real MMU” is a software page-table walker with permission checks and TLBs, not hardware virtualization. That distinction explains both its compatibility ambitions and its host-security limits. [1][2][3]

The SDK exposes exec/spawn, block devices, filesystem mounts over 9p/vsock, networking, display, sound and optional graphics bridges. The desktop combines those into a local Linux environment. “No server” means guest computation happens on the device: downloads, browser TCP proxying, package mirrors and default wallpaper still involve servers. [1][4][7]

## Stack

| Layer | Implementation |
|---|---|
| Kernel | Linux 7.3.4 source pin plus local wasm/toolchain patches |
| CPU | Zig aarch64 reference interpreter, decoded operations and wasm JIT |
| Scheduling | JSPI suspending imports; optional SMP instances sharing wasm memory |
| SDK | TypeScript, Node/browser conditional exports; no declared runtime npm dependencies |
| Desktop | React, Tailwind, Vite/Nitro, terminal/Wayland integrations |
| Storage | Read-only distro image + overlayfs; ext4 data disk backed by file or IndexedDB |
| Graphics | virglrenderer/WebGL2; guest Vulkan bridge and naga SPIR-V-to-WGSL translation |

Sources: build pin, runtime imports, package manifest and frontend configuration. “Zero-dependency SDK” does not mean a dependency-free build, desktop or binary distribution. [2][4][10][11]

## Key Features

### Kernel compatibility without emulating kernel instructions
The runtime implements JSPI task switching and paravirtual devices; kwemu checks Sv48-format translations in linear memory. Source supports the architectural claim, but inspection does not demonstrate Linux-wide compatibility or interpreter/JIT equivalence. Native arm64 packages avoid recompilation to wasm, while CPU-heavy work still pays emulation/JIT costs. [2][3][4]

### Persistence with deliberate failure handling
The init script mounts the distro read-only and puts per-distro changes on ext4 when a data disk exists, otherwise tmpfs. It tests the resulting shell/init and falls back to a fresh upper layer while preserving the damaged changes. This is recovery from an unusable overlay, not detection of all corruption or malicious startup files. [8]

Browser block writes and generation metadata share an IndexedDB transaction with strict durability requested. The page uses Web Locks, with a BroadcastChannel fallback, to avoid concurrent persistent writers; a second tab or failed storage open can get an explicitly unsaved in-memory disk. Export backups remain necessary: browser eviction, quota exhaustion and storage clearing are not solved by journaling. [9]

Snapshots copy machine memory, not disks. Restore checks disk identity/generation, device compatibility and CPU count. The kernel’s commit callback can persist a snapshot before abandoning execution, and a failed commit resumes execution rather than silently losing it. These are useful recovery patterns, not independently crash-tested guarantees. CLI root changes are ephemeral without `--data`; `stop()` is not a clean guest shutdown. [1][4][9]

### Flexible host/guest integration
9p mounts, vsock streams and terminal sessions make it useful as an embedded development environment. The same integrations deliberately pierce the bare wasm boundary. Guest distro commands normally run as uid 1000 with passwordless sudo; the base shell is root. Guest uid isolation is not a separate human approval or host authorization system. [1][5]

## Architecture

`createKernel` / CLI → TypeScript host imports and workers → wasm Linux kernel → kwemu executing arm64 user programs. Device requests return to host implementations for disks, TCP/DNS, graphics and shared memory. Optional SMP starts multiple wasm instances on one shared memory, not separate security domains. Browser SMP needs cross-origin isolation; runtime support also depends on JSPI. [3][4]

The code is organized by responsibility (`src/a64`, `src/emu`, `kernel`, `guest`, `js/core`, platform adapters, `web`). ABI assertions, reference execution, explicit snapshot mismatch errors, checksum validation and focused tests are good maintainability signals. The large custom kernel/emulator/host interface remains a significant correctness and attack surface. This was a sampled static review, not an audit of every instruction decoder or kernel patch. [2][3][4][12]

## Security, Execution Authority and Privacy

### High: guest web previews share the desktop origin
`web/src/preview.ts` explicitly says trusted content only. `Preview.tsx` creates an iframe without a sandbox attribute, at the same origin, and the service worker relays guest HTTP responses into that origin. A malicious guest page can therefore run with that origin’s web authority, including access to same-origin storage and reachable parent-page objects; the desktop exposes `window.KW`. Stripping `Set-Cookie` from responses does not create an origin boundary. This is a documented trust constraint, not a demonstrated exploit or a browser escape. Avoid untrusted previews or redesign them onto an appropriately isolated origin. [6]

### High: Node networking grants host reachability
The SDK starts without guest networking unless configured. In contrast, CLI networking is enabled unless `--no-net`; its direct backend opens Node TCP sockets and resolves names through the host, with host-loopback mapping enabled. There is no destination allowlist in that backend. Guest code can reach services available to the Node process, including private services subject to host routing/firewalls. The CLI’s optional forwards bind loopback, but that does not restrict outbound guest traffic. Worker mode changes scheduling, not these capabilities. [1][7]

### Medium: host mounts are writable unless restricted, and not race-proof
CLI `--mount` uses a writable Node filesystem adapter unless `:ro` is supplied. 9p checks read-only mutation requests, rejects unsafe path components and does not walk symlinks. Node opens regular files with `O_NOFOLLOW`/`O_NONBLOCK`. However, the adapter explicitly documents a host-side directory-to-symlink race between a guest walk and a later request; final-component no-follow does not prevent intermediate-directory replacement. Use dedicated immutable or disposable mount trees, read-only exports and outer OS isolation when appropriate. No race was executed here. [5]

### Authentication and egress are deployment responsibilities
This is a local runtime, not an authenticated multi-user execution service. The inspected frontend serves assets and preview fallback pages, not remote tenant VMs. COOP/COEP enable browser isolation features; they are not user authentication or egress controls. Wisp origin acceptance is not strong client authentication: the Node Wisp adapter itself supplies a localhost Origin header. No proxy deployment was inspected or tested. [6][7][10]

Browser networking uses Wisp; HTTP package routes can use `mirror.unkernel.dev`, and README documents a default Picsum wallpaper request. A relay can observe destinations and plaintext protocols; TLS within the guest protects application plaintext subject to its normal trust model. Pin and host artifacts, choose a controlled relay, turn off guest networking and external wallpaper where needed, and do not assume `?net=0` prevents all page/download traffic. Persistent disks and snapshots may retain credentials introduced into the guest; neither is an encrypted vault. No private data was used for this review. [1][7][9]

## Claims, Maturity and Tests

- **Boot and near-native syscall/fork claims:** README supplies timing tables and dates, but its syscall comparison used the earlier riscv64 user space. Those measurements are not a benchmark of this exact arm64 revision across devices, nor proof of native application throughput. Cold downloads, JIT warm-up and workload mix matter. No timing was reproduced. [1]
- **Compatibility claims need qualification:** README’s “Vulkan 1.2” description should not be read as conformance certification; open issue [#33](https://github.com/pithings/unkernel/issues/33) concerns required timeline semaphore reporting. Other observed reports include audio starvation under GL ([#34](https://github.com/pithings/unkernel/issues/34)) and Firefox secondary-CPU JIT collection ([#29](https://github.com/pithings/unkernel/issues/29)). Reports are not independently reproduced defects.
- **Release CI is substantial, but not universal:** the sole observed workflow triggers on version tags or manual dispatch, not every PR. It builds kernels/renderers/images, checks types, runs kernel JIT/non-JIT/SMP and ABI tests, selected SDK tests, distro tests and built-package API tests. It does not invoke every manifest test script or the browser suite. The public API showed a successful [release run](https://github.com/pithings/unkernel/actions/runs/45635398171) at `cec0a49f5d028867955dbc19769fe9e810dc9384`, not the reviewed main SHA. Workflow configuration and upstream green status are not locally verified results. [11][12]
- **Metadata snapshot:** anonymous API reported 1,716 stars, 83 forks and 25 open issues/PRs combined on 2026-11-25; latest push timestamp was 2026-11-25T16:29:19Z. Popularity and rapid releases do not establish security or long-term support. Canonical-source search of the review collection, README and research index found no prior review, so this is a new entry.

## Licensing and Supply Chain

Do not describe the whole product as MIT. The actual GPLv2 license text, MIT grant, file SPDX headers, manifest and third-party notices establish component-specific terms. SDK/page reuse is MIT with notice retention; distributed kernel binaries need applicable GPL source/notice compliance. The default project code is stated as GPL-2.0-or-later, kernel patches are GPL-2.0-only, LLVM patches retain Apache-2.0 WITH LLVM-exception, and distro packages/graphics dependencies retain their own licenses. The manifest’s short package expression is not a substitute for the more detailed renderer notices. No upstream code was extracted into this review. [13]

Positive controls include exact Linux/LLVM source commits, checksum-pinned downloads, pnpm/Cargo lockfiles, full-SHA GitHub Action pins, checkout credential non-persistence, frozen npm dependency installation, release main-ancestry checks and OIDC npm publishing with provenance requested. Distro downloads verify size and SHA-256 against the release index and atomically rename verified downloads. [2][11][14]

Remaining trust includes the release account and its checksum manifest (hashes from the same release are not an independent signature), npm/toolchains, distro repositories, frontend dependencies and non-fully-frozen host build packages. Reproducibility is asserted by build comments but was not independently rebuilt; artifact attestations and all third-party sources were not audited. The web build can choose the newest release unless explicitly pinned, so reproduce the frontend and kernel versions together. [10][11][14]

## Comparison

| Alternative | Prefer it when | Tradeoff versus Unkernel |
|---|---|---|
| [v86](https://github.com/copy/v86) | You need a browser x86 machine and PC compatibility | Emulates the machine/kernel too; different architecture and performance profile |
| [iSH](https://github.com/ish-app/ish) | You want its established iOS Linux-userland experience | User-mode emulation with syscall translation rather than a compiled full Linux kernel |
| [Wasmer WASIX](https://wasmer.io/wasix) | You can rebuild workloads for wasm | Avoids native-ISA emulation, but different POSIX/ABI compatibility constraints |
| [Firecracker](https://github.com/firecracker-microvm/firecracker) | You need server-side hardware-backed microVM isolation | Requires Linux/KVM and an operational control plane; not a browser runtime |

These are architectural fit comparisons, not benchmarks or fresh security audits of the alternatives. Unkernel’s differentiator is keeping Linux kernel semantics with unmodified arm64 programs inside a wasm host.

## Self-Hosting Notes

Use a dedicated origin and browser profile for experiments, keep previews trusted, pin the kernel/distro/page revision, and serve correct wasm MIME types, byte-range distro responses and COOP/COEP over a secure context. The page’s development server binds all interfaces; do not expose development tooling as a production control plane. A self-hosted page needs a suitable Wisp relay for TCP networking; the default proxy is not a general hosting guarantee. [1][10]

For Node, start with no network, no host mounts and disposable data; add only capabilities the workload needs. For hostile workloads, place the entire Node process behind an independently administered OS/container/microVM boundary with resource limits and network policy. Back up disk exports and test restore on the same kernel/device/CPU configuration before relying on snapshots. No deployment was performed.

## Evidence

All source links below are pinned to the reviewed commit. Public release/issue/metadata observations are dated above and can change.

[1]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/README.md
[2]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/kernel/build.sh
[3]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/src/emu/kwemu.zig
[4]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/core/kernel.ts
[5]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/node/nodefs.ts
[6]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/src/preview.ts
[7]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/node/net.ts
[8]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/guest/base/initramfs/init
[9]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/core/snapshot.ts
[10]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/vite.config.ts
[11]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/.github/workflows/release.yml
[12]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/package.json
[13]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/THIRD-PARTY.md
[14]: https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/node/distro-fetch.ts

Additional implementation evidence: [CLI defaults](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/cli.ts#L442-L452), [9p checks](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/core/9p.ts), [unsandboxed iframe](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/src/components/Preview.tsx#L165-L168), [preview relay](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/public/vm-sw.js), [desktop authority](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/src/kw.ts), [disk transactions](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/js/web/disk.ts), [single-writer page logic](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/src/data.ts), [page networking defaults](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/web/src/config.ts), [snapshot tests](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/test/distro.test.ts), [MIT grant](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/LICENSE-MIT), [GPL text](https://github.com/pithings/unkernel/blob/96e4bd7ebb54b93ad5ec68feab4eda94b3073927/LICENSE), [release](https://github.com/pithings/unkernel/releases/tag/v0.2.0-261125-cec0a49).

**Attribution:** pithings/unkernel, Pooya Parsa and contributors. Component licenses as described above. This review is independent analysis, not upstream endorsement.
