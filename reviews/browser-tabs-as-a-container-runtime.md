# Browser tabs as a container runtime

**Source:** https://fzakaria.com/2026/11/25/browser-tabs-as-a-container-runtime
**Author / publication:** Farid Zakaria / fzakaria.com
**Published / modified:** 2026-11-25T10:00:00-08:00 (both fields in page metadata)
**Reviewed:** 2026-11-26 (UTC)
**Retrieved:** 2026-11-26 (UTC); anonymous HTTPS returned 200 and the canonical URL matched the source above. SHA-256 of retrieved raw HTML response body: `285a2ea647fb2c6f3d9927c45762b1953b8dac8b2d39c3e7eae1dc802f2aa0a2`.
**Implementation snapshot:** fzakaria/tabc `865e98ffcca5effef389db2dacfcfb99f6ce22aa` (2026-11-26); newer than the article, not a claim about its exact demo revision. Its Nix packaging pins Unkernel `0.2.0-261125-cec0a49` and a tarball hash. [2][10]
**Verification:** Full article text and both performance SVGs read; static inspection of linked README/design, page worker, supervisor, filesystem, init, packaging and CI/test definitions. No source execution, installs, browser demos, device access, live service probes, runtime tests or benchmarks. Demo videos were not independently replayed/verified.
**Topic:** Browser-hosted Linux, OCI integration, WebAssembly isolation and developer tooling.

---

## Verdict

⚠️ **Interesting but verify — a credible integration experiment, not a drop-in Docker or hostile-code isolation replacement.** Worth reading for runtime authors and developers exploring lightweight interactive Linux environments on macOS. The real achievement is wrapping a wasm Linux kernel and emulated arm64 programs in familiar container workflows; the important qualifications are host bridges, ephemeral roots, incomplete engine semantics and substantial workload slowdowns.

## Summary

Zakaria proposes making the browser the execution environment for OCI containers. His `tabc` adapter launches a supervisor and a headless Chromium profile per container; the page runs Unkernel, whose Linux kernel is compiled to WebAssembly while native aarch64 user programs are emulated. This avoids a hardware-virtualized Linux guest on macOS, not all virtualization or dependence on the host OS. [1][2][3]

On Linux, Docker or Podman can call tabc as a runtime. Without a Docker daemon, standalone tabc pulls images itself; `tocker` supplies a minimal Docker-compatible daemon and invokes the real Docker client. These are distinct paths. The article's opening juxtaposition of a real Docker daemon with a Mac needing no Docker is easy to misread: ordinary Docker Engine has not simply become a browser-only macOS program. The README explicitly requires the Docker command-line client for tocker. [1][2]

The browser is also the terminal. Input and output travel over a local WebSocket, and `--open` or `--link` uses an existing browser rather than launching a dedicated hidden instance. The Compose example shows a web service communicating with Redis; it demonstrates a useful slice of orchestration rather than the entirety of Docker's API, networking or persistence model. [1][3][4]

The article includes a small startup experiment, memory overhead and a workload comparison, and candidly acknowledges emulation cost. Its creator's perspective makes it an informative primary account of intent and demonstrations, but not an independent audit. The implementation is stronger evidence of the mechanism than the article's broad claims of equivalent isolation, near-native kernel speed or unchanged Compose behavior. [1][3]

## Key Claims

| Article claim | Evidence assessment |
|---|---|
| Containers run in browser tabs without a macOS hypervisor | Supported architecturally by worker/kernel boot and Go supervisor design; not reproduced on a Mac here. A native host executable remains necessary. [2][3][4] |
| A container never touches the host kernel | Too literal. Guest Linux syscalls need not run directly on the host kernel, but Chromium, its sandbox and the supervisor depend on host OS syscalls; file and network bridges explicitly invoke them. [3][5][6] |
| Browser isolation replaces Linux container isolation | Different boundaries, not equivalence. A wasm instance, renderer sandbox, browser profile, host identity and bridge permissions each do different work. No formal threat model or audit establishes parity. [3][5][7] |
| Startup is under a second | Author reports 15 Alpine echo runs on Ryzen 7 7840U, about 0.87 s command-to-exit; useful narrow evidence, not a cold image-pull or cross-platform service-readiness benchmark. [1][12] |
| Compose networks and volumes all work unchanged | Qualified by current docs: TCP and DNS only, no UDP, no CPU throttling, no checkpointing, no image builds without Docker, aarch64 guest images only. [3] |

## Strengths

- **Substantive architecture:** Linux semantics are supplied by a compiled kernel rather than a small handwritten syscall compatibility layer. Native arm64 images do not need rebuilding as WASI applications. The page worker implements actual filesystem, terminal and TCP plumbing. [3][4]
- **Practical integration:** supervisor PID/exit status, OCI create/start, exec, terminal sizing, live mounts and service-name routing make this more than a Linux-in-a-tab screenshot. [2][3][8]
- **Useful negative evidence:** the article publishes high memory cost and double-digit slowdowns instead of only fast boot numbers. Its linked design is unusually explicit about missing features and weaker user-browser mode. [1][3][13]
- **Inspectable tests and pins:** Nix packaging fixes an Unkernel version and hash, while Linux CI specifies Go tests and real-Chromium checks. These improve inspectability; they are not tests run by this review. [10][11]

## Isolation, Host Bridges and Privacy

### A tab is a placement unit, not a complete security policy

A conventional Linux container shares the host kernel and uses mechanisms such as namespaces, cgroups and permissions. Here a separate wasm Linux instance handles guest syscalls and emulates arm64 userspace. Wasm memory containment limits module access; Chromium's renderer sandbox limits a compromised renderer; neither automatically restricts what explicitly supplied host services may do. A browser tab is also not intrinsically one dedicated OS process: site/origin and browser mode matter. [3][4][5]

The default launcher creates a private profile, disables extensions/background activity and does not add a no-sandbox flag. When the supervisor is root, it launches Chromium as uid/gid 65534. Those are meaningful controls, but the native supervisor still holds its own authority; it does not become unprivileged merely because the browser does. Extra browser flags can override defaults. The design itself says the first, custom kernel/emulator layer is unaudited. [3][5]

Existing-browser mode trades startup/profile overhead for the user's browser profile, extensions and network context. Dashboard frames likewise are not evidence of a separate browser process/profile per service. Prefer dedicated headless profiles for isolation experiments and do not present a shared interactive browser as an equivalent configuration. [3][5]

### The bridge is part of the trusted computing base

The supervisor binds its page server to loopback and requires a cryptographically random 16-byte token in the URL path. It sets COOP/COEP/CORP and no-store headers; the token routes include filesystem, configuration, network, terminal/control and volume operations. These are useful capabilities, not remote multi-user authentication. Protect page URLs, logs and local state as bearer authority; opening a link is more than viewing inert output. Cross-origin isolation enables shared memory, not a tenant authorization system. [6][8]

Host volumes are explicit live read/write bridges, with read-only support enforced by server handlers. Directory operations use Go `os.Root`, a more relevant boundary than assuming the browser cannot access files. A guest allowed a writable directory can intentionally damage or exfiltrate that directory without escaping Wasm. Export narrowly scoped disposable paths or read-only data; do not mount credentials. Static inspection does not constitute a race/path traversal audit. [4][9]

### Network access is delegated, not eliminated

Tabc supplies its own TCP/DNS backend through local HTTP/WebSockets; this is not automatically Unkernel's public Wisp relay. The supervisor opens outbound connections. Under Docker/Podman the design places that process in the engine's network namespace; standalone host networking instead gives it host routing/reachability. Its fallback dialer accepts destinations without a destination allowlist in that function. Browser same-origin rules are not an outbound guest firewall when a native bridge makes the connections. [3][4][7]

Published standalone ports default to loopback, but that does not restrict outbound traffic. Images still come from registries, DNS queries leave through the configured resolver, and guest applications may contact external services. TLS protects application traffic according to its usual trust model; it does not hide destinations from the host/network. No live egress policy was tested. Keep networking disabled where unnecessary and enforce external network policy before evaluating untrusted code. [2][6][7][8]

## Storage, Lifecycle and Recovery

The image is read-only, backed by bundle files or indexed tar layers. Init adds a tmpfs overlay: root changes are memory-backed, not a durable Docker writable layer. Live host volumes are the persistence mechanism described here; their durability and database consistency depend on the application and underlying host filesystem. This review did not test fsync, crash consistency or concurrent-writer semantics. [3][9]

The guest's life is tied to the page. The supervisor accepts one controlling page, rejects a second, and treats page disconnect/browser exit as container failure unless an exit status already arrived. Reloading or closing the tab is not detaching a terminal from an independent server. Guest/root memory disappears with it, and checkpointing is explicitly missing. Browser suspension/discard and host sleep deserve workload-specific testing; disabling background throttling in dedicated Chromium does not control every user's existing browser. [3][5][8]

The related [public Unkernel review](unkernel.md) discusses persistent disks and snapshot validation in Unkernel itself. Those capabilities must not be silently attributed to tabc: its inspected integration uses a tmpfs root and does not provide checkpoint recovery. The same caution applies to that review's desktop-preview and public-relay findings, which concern different integration paths.

## Performance, Compatibility and Reproducibility

The article's startup SVG breaks 867 ms into Chromium opening the page (503 ms), boot/mount (84 ms), echo execution/exit (256 ms), and other work (24 ms). Reusing a browser can avoid its launch component; it cannot eliminate guest initialization or application startup. The newer pinned design also reports that a second CPU changes Ryzen startup from about 0.9 s to 1.3 s and M4 startup from 0.45 s to 0.8 s. This is evolving upstream evidence, not a contradiction resolved by our own measurements. [3][12]

The workload SVG compares tabc with native runc and labels: `find /usr` 36× slower; Python sum of five million squares 31×; importing JSON/parsing 1 MB 28×; gzip of 32 MB 14×; SHA-256 of 64 MB 11×. These are the author's measurements, not independently reproduced results. They are enough to reject a casual inference that near-native kernel execution means near-native application throughput. Latency can still be acceptable for a tiny interactive task; compilers, bulk compression and sustained compute need their own measurements. [13]

The reported roughly 540 MiB idle host footprint includes browser/helper processes. The Firecracker comparison in the article is not controlled: quoted microVM overhead and boot time have different accounting, hardware requirements and workload scope. Shared-browser amortization also changes isolation and failure coupling. No density or memory-pressure test was supplied by this review. [1][3]

Compatibility is bounded by arm64 guest binaries and available kernel/browser features, not by the host binary download architecture. The page checks SDK support and falls back to one CPU without cross-origin-isolated shared memory. CPU count is not CPU-time throttling; quota-derived counts round up. This matters for resource fairness and denial-of-service protection. No OCI conformance suite, broad Compose compatibility matrix or browser/macOS test matrix was verified. [3][4]

For a reproducible follow-up, pin tabc's commit, Unkernel package/hash, image digest and platform, browser version/flags and host OS/hardware. Separate cold download, cold browser/kernel, warm run and application readiness; report distributions and peak/idle memory with a stated accounting method. Exercise UDP-dependent apps, persistent volumes, page loss, supervisor crash and recovery, and assess network policy. The article does not provide enough pinned environment/raw samples to recreate all figures exactly. Its convenient unpinned Nix/image examples should not be mistaken for immutable experiments. [1][10][12][13]

CI definitions run on pushes to main and PRs, with Nix formatting/checks. The inspected e2e file asserts output, exit codes, stdin/stderr, a writable root, architecture, CPUs and exec behavior. It runs on Ubuntu and relaxes an AppArmor user-namespace restriction to allow Chromium's sandbox. This is test configuration, not observed successful CI at this SHA, and is not evidence for complete Compose, Mac/browser coverage or adversarial isolation. [11]

## Alternatives and Operational Fit

| Need | Better starting point / tradeoff |
|---|---|
| Familiar macOS development with broad Linux-container compatibility | Docker Desktop, Colima or Podman Machine accept a Linux VM in exchange for a conventional Linux engine; compare actual workload behavior rather than VM count. |
| Browser demos with existing arm64 userland | Tabc's differentiator: OCI workflow plus compiled Linux kernel; accept emulator cost and browser lifecycle. |
| Browser execution of a different machine image | v86 or container2wasm use different emulation/compatibility strategies. The article's blanket limitations are not a fresh benchmark or audit of their current releases. |
| Applications that can be rebuilt for Wasm | WASI-oriented runtimes avoid native-ISA emulation but require a different ABI/application-portability contract. |
| Hostile multi-tenant workloads | Independently administered OS/VM isolation, resource and network policy remain necessary evaluation criteria; Firecracker is a Linux/KVM option, not a macOS browser substitute. |

These are architectural fit comparisons, not head-to-head tests. Start with disposable, trusted interactive workloads; do not replace a durable production service or hostile-code runner on the basis of the demo.

## Gaps & Limitations

The article's strongest evidence is a working-design account plus demonstrations and small author-run measurements. It lacks an independent security audit, complete compatibility contract, durable-root/recovery story and reproducible benchmark dataset. The inspected code postdates publication; changes can alter both behavior and timings. No functionality, browser escape, filesystem attack or networking claim was tested dynamically. The review searched the public collection, README and research index for the canonical URL and found no earlier review of this article; the Unkernel entry is related context, not a duplicate.

## Sources and Reuse

Article license was not established; this review summarizes and attributes rather than reproducing the article, videos or figures. Tabc's LICENSE is MIT; its packaged kernel has GPL terms, SDK and other components retain their own terms. Do not infer an all-MIT distribution from the wrapper. No upstream code or assets were extracted. [10][14]

All implementation links below are pinned to the inspected snapshot. Article and figure URLs are mutable; the recorded HTML hash covers the HTML body, not separately hosted assets.

[1]: https://fzakaria.com/2026/11/25/browser-tabs-as-a-container-runtime
[2]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/README.md
[3]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/docs/design.md
[4]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/page/guest.js
[5]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/supervisor/chrome.go
[6]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/supervisor/server.go
[7]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/supervisor/network.go
[8]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/supervisor/supervisor.go
[9]: https://github.com/fzakaria/tabc/tree/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/rootfs
[10]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/nix/unkernel.nix
[11]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/nix/e2e.nix
[12]: https://fzakaria.com/assets/figures/f755809aab918669.svg
[13]: https://fzakaria.com/assets/figures/8f0b5aff609c72f6.svg
[14]: https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/LICENSE

Additional primary evidence: [CI workflow](https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/.github/workflows/ci.yml), [guest overlay init](https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/cmd/tabc-init/main.go), [single-page session](https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/supervisor/session.go), [read-only volume enforcement](https://github.com/fzakaria/tabc/blob/865e98ffcca5effef389db2dacfcfb99f6ce22aa/internal/rootfs/write.go).

---

**Attribution:** Farid Zakaria, “Browser tabs as a container runtime,” fzakaria.com, November 25, 2026; tabc contributors; Pooya Parsa and Unkernel contributors. Independent review, not upstream endorsement.
