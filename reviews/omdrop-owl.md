# omdrop-owl (t4t5/omdrop-owl)

**Repo:** https://github.com/t4t5/omdrop-owl
**License:** Declared mixed GPL-3.0-or-later / GPL-2.0-only / ISC; incomplete top-level licensing documentation (details below).
**Reviewed:** 2026-10-12 (UTC)
**Revision:** `ee6a57d971c207c933a424c0d705044a02985b0a`, main; commit dated 2026-10-11T17:57:58Z.
**Scope:** README, packaging, pins, shell helper/profiles, seven OWL patches, build/staging scripts and exclusive-mode regression tests; selected upstream license/header checks, not a full transitive-source audit.
**Verification:** Static source review only. No installation, source execution, tests, radio operations, transfers or benchmarks run.
**Stack:** Bash · patched C OWL · Python tools · NetworkManager · nl80211/libnl · libpcap · libev · BlueZ · polkit
**What it is:** A Linux radio backend that lets omdrop use native Apple AirDrop over userspace AWDL on selected non-Apple Wi-Fi hardware. It is not a complete standalone file-transfer application.

---

## Verdict

⚠️ **Interesting — a hardware-specific pilot, not a general AirDrop replacement.** The backend contract and driver profiles are useful engineering, and the patches address concrete interoperability failures. But Intel operation takes Wi-Fi offline, the driver-level “tested” gate is broader than tested hardware, and a current Intel 7265 report describes firmware crashes. Try only on an explicitly matched card/kernel with local recovery access; prefer a conventional LAN transfer tool when both endpoints can install an app.

## What It Is

omdrop-owl supplies the AWDL link beneath omdrop's receiver/sender, replacing the Broadcom-specific backend. A privileged shell helper creates monitor/ad-hoc interfaces, launches patched OWL, advertises the service and restores normal Wi-Fi afterward. Portable AirDrop/advertisement helpers are fetched from omdrop-awdl at a fixed revision, rather than reimplemented here.

The README's statement that omdrop's backend-support PR is not merged is stale: [omdrop-plugin PR #25](https://github.com/brentkearney/omdrop-plugin/pull/25) was merged on 2026-10-11 at 19:37:12 UTC (merge commit `97c16bb8adc22362323a853c3542bc0b11044310`). This confirms integration landed, not that any particular installed plugin version or hardware works.

## Stack

| Layer | Technology |
|---|---|
| Radio lifecycle | Bash, iw/ip, NetworkManager, flock, process supervision |
| AWDL | OWL C daemon; seven local patches; libev/libpcap/libnl |
| Discovery/transfer helpers | Pinned Python/shell tools from omdrop-awdl, BlueZ and mDNS |
| Privilege | Root helper via fixed-path polkit action |
| Packaging | Arch PKGBUILD; Debian package builder; CMake/GCC |
| Persistence | Transient runtime state and administrator-owned hardware configuration; no database |

## Key Features

### Two explicit radio modes

Shared mode is documented working on MT7925 and requires the AP on channel 6, 44 or 149. Intel uses exclusive mode: disconnect the station, create an IBSS interface or convert the station in place, then restore it. The helper records the prior connection UUID and IPv6 setting for the conversion path, and retries reconnecting. This is meaningful recovery logic, not simply a launcher. [README](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/README.md#L17-L49), [exclusive lifecycle](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L158-L221).

### Narrow, explainable interoperability patches

The patch set adds transmit-rate/address controls, fixed-channel scheduling, metric-first master election, no-ACK unicast, fixed-channel pinning and Intel retry/peer-liveness fixes. In particular, queue-full handling retains a unicast frame and retries from the event loop rather than silently dropping it; no-ACK mode trades firmware retries for TCP retransmission. These are targeted workarounds, not proof of protocol completeness or good performance on arbitrary cards. [fixed-radio patch](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/patches/owl-03-fixed-radio.patch), [no-ACK patch](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/patches/owl-05-fixed-radio-noack.patch), [reliability patch](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/patches/owl-07-intel-reliability.patch).

### Machine-readable diagnosis, with an important limit

The helper supports probe/status JSON, peer listing, finite discoverability windows and an explicit receive-proven flag. However, visible checks process identities and a usable awdl0 address, not the continued health of the underlying radio or an actual transfer. Receive-proven is a historical “add peer” log match for the window, not authenticated peer identity or transfer success. [status and peers](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L223-L305).

## Architecture and Dependencies

The helper selects a managed station and loads a driver profile. Shared mode checks a default IPv4 gateway with ping, then shares the AP channel; thus an IPv6-only or ICMP-blocking network can fail the start gate despite usable connectivity. Exclusive mode selects permissible AWDL channels from iw output and temporarily hands control away from NetworkManager. OWL creates awdl0; the supervisor repeatedly advertises port 8771 and stops on timeout or OWL exit. The application-level receiver and acceptance/TLS policy live outside this repository. [start/supervisor](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L353-L515).

[pins](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/pins) fixes OWL to `832d70f815c3d4a06a02117bf0fc5e868daa1ff0` and omdrop-awdl to `534f91a525337951ca19c311e53d333bd6d55100`. Arch prepare checks duplicated pins agree; OWL submodules are checked out at recorded gitlinks despite initial source clones tracking repositories. Pinning helps repeatability but is not signature/provenance verification, and distro dependencies are not fully locked. The build intentionally compiles only OWL, saying bundled googletest fails under current GCC. [PKGBUILD](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/PKGBUILD), [build](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/tools/build-owl.sh), [staging](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/tools/stage.sh).

## Security and Operational Findings

1. **The hardware safety gate is too coarse to mean card-tested.** Profiles mark the entire iwlwifi driver tested, enabling untested Intel models without opt-in. [Issue #16](https://github.com/t4t5/omdrop-owl/issues/16), opened 2026-10-12, reports repeated Intel 7265 firmware assertions at this same revision and a false-visible state after reprobe. This is a public reporter's evidence, not independently reproduced. README also records MT7921 exclusive failure and an MT7925 post-teardown receive wedge mitigated by reconnecting. Match PCI ID, firmware, kernel and mode, not merely the driver name. [profiles](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/owl-profiles#L20-L23), [gate](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L398-L410).

2. **Local active users can perform disruptive privileged radio operations without an admin prompt.** The polkit action binds a fixed installed helper path and requires admin authentication for remote/inactive callers, but allow_active is yes. That is an intentional desktop convenience/security tradeoff: start 0 permits indefinite discoverability and exclusive mode disconnects Wi-Fi. The helper also changes interface state, sysctls and potentially mounts debugfs. Root ownership of the helper, adjacent Python/OWL files and configuration is essential. No privilege-escalation exploit was demonstrated. [policy](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/packaging/omdrop-owl.policy), [root/config](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L33-L78).

3. **Cleanup is thoughtful but not transactional.** flock serializes lifecycle calls and daemon children explicitly close the lock descriptor; failed station restoration preserves recovery state. Yet fixed names mon0/awdlibss0 are deleted without proving this run created them, debugfs mounting is not undone, and restoration errors can be logged while stop returns success. Avoid machines using those names for other radio workflows; verify connectivity after teardown. [cleanup](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L310-L348), [startup side effects](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L437-L479).

4. **Privilege and network attack surface exceed this small repository.** OWL is launched from the root helper without a privilege-drop wrapper in the inspected launch path, and processes nearby wireless input. An exhaustive parser, imported sender/receiver, TLS/identity or archive-handling audit was not performed. There is no web API/CORS layer here; those application concerns cannot be inferred safe from a radio-helper review. Diagnostic reports include network identifiers; README specifically warns that files beyond summary.txt contain the router MAC. Review logs before sharing. [launch](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/userspace/omdrop-discoverable#L466-L513), [report guidance](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/README.md#L66-L75).

## Maturity and Verification

Public [GitHub metadata](https://api.github.com/repos/t4t5/omdrop-owl) retrieved 2026-10-12: created 2026-10-08; last push 2026-10-11T17:58:08Z; 2,183 stars, 154 forks, eight open items including PRs; not archived. [Releases API](https://api.github.com/repos/t4t5/omdrop-owl/releases) returned none. Package version is 0.1.0. A few days of public history and popularity do not establish reliability.

The tracked tree has no CI workflow. One Python unittest file contains ten command-double tests for exclusive-mode restoration/retry/failure behavior. Useful coverage, but it extracts functions and does not exercise the whole helper, real firmware, full transfer path, polkit or packaging. PKGBUILD's check is an option-recognition smoke check, not a transfer or upstream regression suite. The manual card harness performs transfers and a default five-minute post-stop connectivity watch; these tests were inspected, not run. [tests](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/tests/test_exclusive.py), [card harness](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/tools/test-card.sh).

README throughput figures (MT7925 about 490 kB/s send and 1.3 MB/s receive; an AX201 2.4 MB photo taking 10.5–17 seconds) are upstream observations, not independently verified benchmarks. No safe secret-free execution environment or matching hardware test was established, so all source execution was withheld.

## License and Reuse

No top-level LICENSE/COPYING is tracked and GitHub reports license null. That does **not** mean every component is unlicensed: [Debian packaging's copyright text](https://github.com/t4t5/omdrop-owl/blob/ee6a57d971c207c933a424c0d705044a02985b0a/tools/build-deb.sh#L44-L54) explicitly declares omdrop-discoverable, owl-profiles and OWL patches GPL-3.0-or-later, OWL GPL-3.0-or-later, radiotap ISC, and separately shipped omdrop-awdl tools GPL-2.0-only. PKGBUILD repeats the mixed licenses and installs upstream license documents.

The pinned OWL [source header](https://github.com/jedbillyb/owl/blob/832d70f815c3d4a06a02117bf0fc5e868daa1ff0/daemon/owl.c#L1-L19) confirms GPL-3.0-or-later and its COPYING supplies GPLv3. The pinned omdrop-awdl [LICENSE](https://github.com/brentkearney/omdrop-awdl/blob/534f91a525337951ca19c311e53d333bd6d55100/LICENSE) says GPL-2.0-only but describes kernel-derived patches, while this package imports userspace programs. That scope and the lack of a clear grant for all original build/test files merit clarification before redistributing a derivative. Radiotap's ISC classification was checked in packaging, not independently against its resolved gitlink license.

Preserve notices and satisfy applicable GPL corresponding-source obligations when distributing binaries/modifications. Shipping separate GPLv2-only and GPLv3 programs is not a blanket permission to combine their code into a single derivative. No source extraction was made; this is a licensing assessment, not legal advice.

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| omdrop-owl | Native AirDrop interoperability on specifically validated non-Broadcom Linux hardware | Radio privilege, narrow hardware support, possible Wi-Fi interruption |
| [omdrop-awdl](https://github.com/brentkearney/omdrop-awdl) | Supported Broadcom hardware in the same omdrop ecosystem | Different hardware/driver constraints; not a universal replacement |
| [LocalSend](https://github.com/localsend/localsend) | Ordinary cross-platform LAN file transfers | Requires an app on both endpoints; not native AirDrop |
| [PairDrop](https://github.com/schlagmichinetz/PairDrop) | Browser-based cross-platform sharing | Browser/signaling/network requirements; not native AirDrop |

These are workflow comparisons, not fresh security audits or benchmarks of the alternatives.

## Self-Hosting Notes

This is a desktop system package, not a server/container deployment. Build on a disposable machine first; install only after reviewing privileged files and confirming the exact card/mode. Requires NetworkManager and compatible omdrop; conflicts with the Broadcom backend. Keep console or independent network access for recovery, choose finite discoverability windows, and validate bidirectional transfers plus post-stop Wi-Fi. A VM can check builds/mocks but cannot establish physical-radio compatibility without suitable passthrough.

## Limitations

Static, sampled review at the exact SHA above. No install, runtime, exploit, transfer, performance, dependency-vulnerability or reproducible-build verification. External metadata and issue status are retrieval-time snapshots; upstream reports are attributed rather than treated as independently verified. No claim that authentication, contacts-only behavior, receiver acceptance or transferred-file safety was audited.

---

**Attribution:** [t4t5/omdrop-owl](https://github.com/t4t5/omdrop-owl), with upstream OWL and omdrop-awdl attribution and mixed-license qualifications above.
