# usb-rea (emirmrkaljevic/usb-rea)

**Repo:** https://github.com/emirmrkaljevic/usb-rea
**License:** MIT; retain copyright and permission notices when redistributing substantial code. Capture and dependency rights remain separate.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c` — repository-wide static review, especially `src/usb_rea`, manifests, workflows, tests and documentation.
**Verification:** Anonymous public access and exact Git revision verified. Static inspection only: no installation, source execution, tests, device access, live USB capture/replay or generated-driver execution.
**Stack:** Python 3.10+, PyUSB/libusb, MCP stdio, pytest; dumpcap/tshark or USBPcap for live capture.
**What it is:** A USB protocol reverse-engineering assistant that turns labelled captures into inferred commands, evidence reports, Wireshark dissectors and standalone Python drivers. It is not a universal ready-made USB driver or a USB security firewall.

---

## Verdict

⚠️ **Interesting — strong evidence-oriented analysis, not a hardware safety boundary.** The reusable win is connecting inferred fields and generated encoders to capture frames, with explicit unknowns and non-linear lookup fallbacks. Start with offline analysis; generated drivers can immediately detach kernel drivers and replay handshakes, while replay approval is only a caller-supplied boolean. Prefer an established device-specific driver when one exists.

---

## What It Is

usb-rea targets developers investigating Windows-only gadgets such as LCD coolers, RGB controllers, mice and lamps. Record vendor-app actions at several values, provide timestamped markers or ordered labels, and inspect the inferred protocol. The implementation is deterministic Python analysis, not an embedded LLM service; MCP exposes the same pipeline to an external agent. [1][2]

The project describes itself as alpha. At retrieval, the public API reported 237 stars, 11 forks, zero open issues and last push 2026-11-26; those are activity indicators, not correctness guarantees. Latest published release was **v0.7.14**, 2026-11-12, whose tag points to `bbf6458ce2cb048c2bd9d33a6744a479a037e232`; the reviewed main commit is newer, while the manifest still says 0.7.14. [1][3]

## Stack

| Layer | Tech |
|-------|------|
| Entry points | `usb-rea` CLI and MCP stdio server |
| Parsing | Pure-Python pcap/pcapng; USB link types 189, 220 and 249 |
| Analysis | Action segmentation, field fitting, checksums, replies, handshake/state and image-stream inference |
| Outputs | Markdown/JSON, generated Python/PyUSB driver and Lua Wireshark dissector |
| Live capture | Linux usbmon via dumpcap/tshark; Windows USBPcapCMD |
| Hardware writes | PyUSB and OS USB permissions; libusb backend |
| State | Local capture files, marker JSON and capture PID file; no database |
| Authentication | Local process/OS trust; no application-level multi-user authorization boundary |

The manifest requires `pyusb>=1.2` and `mcp>=1.2,<3`; MCP is a base dependency despite also appearing as an optional extra. Dev dependencies include pytest and Pillow; some generated raw-image paths use Pillow. Hatchling builds the package. No dependency lockfile was found; the container base and CI actions are not digest/commit pinned. Resolve and audit the actual dependency set before deployment: MIT for this repository does not relicense PyUSB, MCP, libusb or capture tooling. [2][4]

## Key Features

### Evidence-linked inference rather than opaque guesses
The pipeline removes image streams and periodic background polling, groups labelled actions, then infers constants, values, counters, bitfields, lookup mappings and checksums. Replies, observed readings, handshakes and state constraints enrich the output. Linear fitting includes leave-one-out checks; unsupported mappings can fall back to observed lookup values. Crucially, displayed confidence is mostly the fraction of explained bytes, with a penalty for fewer than three samples — **not a calibrated probability that an unseen command is safe**. [5]

### Rich output, including active behavior
Generated drivers include setters, decoded queries, state changes and image transfer. Initialization may replay inferred handshakes; state-changing commands can be inserted automatically. Lua output helps inspect later captures in Wireshark. These are useful engineering drafts, not independently verified device specifications. Unknown background-query bytes can be replayed verbatim, and an unobserved handshake branch falls back to the most common observed branch. [6]

### Existing-driver lookup before reinventing one
The documented offline catalogue has 268 USB IDs linking projects such as liquidctl, rivalcfg and OpenRGB. That is a discovery table, **not 268 devices validated by usb-rea**. Reused IDs and firmware differences remain important. Optional online lookup fetches OpenDeviceDB metadata; capture content is not uploaded by that path. [7]

## Architecture

`CLI / MCP → pcap.read_transfers → pipeline.analyze → Protocol → report / scaffold / dissector`. The parser normalizes usbmon and USBPcap events into transfers. Selection defaults to the device address with most host-to-device payloads; marker-free analysis uses timing gaps. Explicit target selection and clean captures matter: address-based selection is not physical-device authentication, and aggregation across buses can make repeated device addresses ambiguous. [5][8]

### Hardware and platform scope
- **Offline:** Python analysis of Linux usbmon and Windows USBPcap files; no hardware needed. Windows analysis is documented. No macOS live-capture implementation or native Windows/macOS CI matrix was found.
- **Live capture:** Linux requires usbmon and capture permissions; Windows uses a separately installed USBPcap filter driver and administrator capture workflow. The helper treats non-Windows platforms as usbmon rather than implementing a macOS backend.
- **Evidence examples:** synthetic lamp/fan/LCD/dial devices; packets constructed from liquidctl Kraken X and Hydro Platinum protocols and rivalcfg Rival 100; one trimmed real ASUS TUF LC III LCD capture. Generic parser tests on storage and USB3 Vision captures do not establish control-driver support for those devices.
- **Hardware validation:** no live hardware was tested for this review. Upstream documentation explicitly lists real-hardware testing as a gap; a real capture is evidence of parsing/inference, not proof of successful replay on that hardware. [1][8][9]

### Privilege, device and input safety
**Positive:** replay defaults to refusal and documents exact-packet human approval; subprocess capture arguments are passed as a list rather than through a shell; analysis and scaffold generation do not themselves open devices. **Limit:** MCP `user_confirmed=true` is supplied by the tool caller, not a trusted confirmation UI or authenticated approval record. Enforce authorization outside the server. [6][10]

`replay()` selects by VID/PID without serial or physical-port disambiguation and has no device/command allowlist, firmware compatibility check or rollback. Its setup bytes are indexed without enforcing the documented eight-byte length. Generated `Device()` enumerates interfaces and detaches active kernel drivers, then may write a handshake immediately; there is no equivalent per-packet confirmation gate. Numeric encoding masks values to field width rather than enforcing device-specific safe ranges. A valid packet or checksum can still stop a fan, change a mode or damage a workflow. Never test first on safety-critical cooling, storage or a primary input device. [6][10]

Capture defaults are broad: Linux bus 0 and Windows `-A` can include unrelated devices. The PID file is a bare PID in the working directory: repeated starts overwrite it, startup success is not checked, stderr is discarded, and stop signals the recorded PID without process-identity verification. Treat stale/replaced PID files and concurrent captures as operational hazards, especially with elevated privileges. [10]

The parser reads the entire file into memory and performs several unpack operations without comprehensive malformed-block validation. Large or malformed captures can exhaust resources or raise exceptions. MCP accepts caller-selected local file paths and marker destinations without a workspace sandbox. Run offline analysis with limited memory/CPU and only task files mounted, not with privileged access to a whole home directory. This is static risk assessment, not a demonstrated exploit. [8][10]

### Authentication, secrets, privacy and network boundaries
This is a local CLI/stdio service, not an authenticated hosted web application; CORS is not the relevant boundary. No application API credential is needed for core analysis. An MCP client inherits the server process rights and may send returned reports or generated source to its own model provider. usb-rea does not establish that downstream privacy policy. Captures can contain descriptors, serials, input traffic, display images and session tokens; reports and source derived from captured bytes should remain sensitive until inspected and redacted. [6][8][10]

Online lookup is opt-in. Its implementation fetches the public index and up to five matching device records; it does not upload captures or directly put the VID:PID in a query parameter. Record fetches can nevertheless reveal the looked-up device and ordinary network metadata. Core offline analysis has no corresponding upload path in the inspected modules. Tests can download public Wireshark samples; installation and release publishing also require network access. [7][9]

### Recovery and rollback
Stop capture explicitly and verify the actual process exited before reusing its output. Keep original captures/markers and regenerate reports into new paths: several CLI outputs overwrite files rather than maintaining backups. Device writes are not transactions. Generated state restoration is conditional code after the send, not a general exception-safe rollback; no generated close/context-manager path that reattaches kernel drivers was found. Reopening replays initialization and is not an undo operation. Plan vendor-documented reset/replug/rebind recovery and retain a working vendor driver before any controlled hardware experiment; do not assume it can reverse persistent settings or damage. [6][10]

## Tests, CI and Claim Evidence

The repository contains **28 `test_*.py` modules**. Tests cover encoders, checksums, segmentation, replies, state transitions, HID, image streams and parser regression cases. The CI workflow runs pytest on Ubuntu with Python 3.10, 3.12 and 3.13; the 3.12 job installs tshark and Lua. GitHub reported the reviewed SHA’s [CI run](https://github.com/emirmrkaljevic/usb-rea/actions/runs/45783368739) successful. This review did not rerun tests or audit every job log. [4][9]

| Claim | Evidence and limit |
|---|---|
| Recovers known protocol bytes | Tests synthesize packets according to cited liquidctl/rivalcfg formats and assert encodings, including unseen values. Valuable regression evidence, not independent device behavior validation. |
| Handles real captures | Public parser fixtures plus a stored, trimmed ASUS capture with provenance and image-data redaction documented. No raw private capture was requested or examined. |
| Every CI run exercises public samples | Not guaranteed: download failures and even SHA mismatches skip those tests. A green workflow alone is insufficient proof of every optional integration test. |
| Generated dissector works | Dedicated tshark/Lua tests exist; review did not execute them. |
| End-to-end real kernel capture | A local `dummy_hcd`/configfs gadget script exists, requires root and suitable kernel modules, and is explicitly outside hosted CI. It was not run. |
| Universal gadget reversal | Unsupported. Captured actions, adequate variation, compatible transports and recoverable protocol structure constrain results. |

Publishing uses PyPI Trusted Publishing/OIDC rather than a stored PyPI token. However, the MCP registry publish job downloads a `latest` publisher archive without an explicit checksum, and action tags/dependencies float. These are supply-chain reproducibility gaps, not evidence of compromise. [4]

## Comparison

| Aspect | usb-rea | Existing alternative |
|--------|---------|----------------------|
| Inspect raw USB traffic | Adds labelled inference and driver scaffolding | [Wireshark](https://www.wireshark.org/) plus USBPcap/usbmon gives direct protocol inspection and mature filtering; manual interpretation still required |
| Control supported coolers | Produces an inferred driver draft | [liquidctl](https://github.com/liquidctl/liquidctl) is preferable when the exact device/firmware is supported |
| Configure supported mice | Can infer captured settings | [rivalcfg](https://github.com/flozz/rivalcfg) offers device-specific implementations for supported SteelSeries models |
| Supported RGB hardware | Discovery plus reverse engineering | [OpenRGB](https://gitlab.com/CalcProgrammer1/OpenRGB) is a direct control alternative; validate its hardware-specific warnings too |

These are workflow alternatives, not a fresh security audit of the other projects. The right sequence is lookup, inspect an existing implementation, then infer missing behavior only if needed.

## Self-Hosting Notes

There is no web service or database to deploy. Start in an unprivileged, isolated offline environment with read-only captures and a separate output directory. Pin a reviewed source/dependency set. The supplied Dockerfile uses a non-root application user, but the documented privileged USB passthrough example is a large boundary expansion, not a safe default; do not expose devices for analysis-only work. If enabling MCP, expose only approved tools and files through a host-enforced policy; keep capture/replay disabled until specifically authorized. No installation was performed for this review. [2][4][10]

## Evidence and Provenance

All source links below pin the reviewed commit; metadata and release links are observations as of 2026-11-27 UTC. Canonical repository identity was checked without credentials, and the existing public review/index was checked for duplicates. Source instructions were treated as data. The evidence supports static findings only, not a complete vulnerability or licensing audit.

[1]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/README.md
[2]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/pyproject.toml
[3]: https://github.com/emirmrkaljevic/usb-rea/releases/tag/v0.7.14
[4]: https://github.com/emirmrkaljevic/usb-rea/tree/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/.github/workflows
[5]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/infer.py
[6]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/scaffold.py
[7]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/lookup.py
[8]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/pcap.py
[9]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/docs/VALIDATION.md
[10]: https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/mcp_server.py

Additional directly inspected evidence: [capture lifecycle](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/capture.py), [replay gate](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/replay.py), [pipeline](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/src/usb_rea/pipeline.py), [public-fixture skip behavior](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/tests/test_public_pcaps.py), [capture provenance](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/tests/data/SOURCES.md), [Dockerfile](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/Dockerfile), [license](https://github.com/emirmrkaljevic/usb-rea/blob/49ad0ac4a73d4031229161bf4a3676d9fb3aeb2c/LICENSE), [public metadata](https://api.github.com/repos/emirmrkaljevic/usb-rea).

---

**Attribution:** Emir Mrkaljević / emirmrkaljevic/usb-rea, MIT. This review summarizes public evidence; it does not redistribute capture fixtures or vendor code.
