# neurband (jlcjak/neurband)

**Repo:** https://github.com/jlcjak/neurband
**License:** No project-wide license found; public visibility is not permission to reuse or redistribute its code or hardware designs. Third-party assets and datasets have separate terms.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** 323cb41daeaa09287bed4ad71032d4161647558f; current Rev C firmware, host recorder, analysis, hardware/build and science documentation; older firmware/archive inspected only for context.
**Verification:** Static review only. No installs, source execution, builds, simulations, tests, device connections, or model/data downloads.
**Stack:** C/Zephyr, nRF52832, ADS1298, Python/NumPy/Bleak, KiCad, FreeCAD, ngspice.
**What it is:** A DIY eight-channel surface-electromyography wristband and offline recording/analysis toolkit—not an EEG reader, a finished gesture controller, or a drop-in Meta Neural Band replacement.

---

## Verdict

📚 **Study: substantial engineering, not yet a validated wearable platform.** The acquisition pipeline, diagnostic metadata, simulation assumptions and held-out-session evaluation are worth studying. Missing project licensing, unauthenticated BLE control, fragile recording durability and uncompleted hardware validation prevent a deployment recommendation. The next useful milestone is measured bench and on-body evidence, not another simulated accuracy number.

---

## What It Is

The public project by **jlcjak** combines custom electronics, dry-electrode flex, printed mechanics, firmware and Python analysis. Rev C uses eight bipolar channels with 20 mm proximal–distal electrode spacing, plus driven bias pads. ADS1298 acquisition runs at 4 kSPS; the default DSP path decimates to a 2 kSPS, eight-channel, 16-bit BLE stream. An LSM6DSL supplies motion measurements. The current README says boards have arrived and housing is being fit-tested, while its bench, antenna/throughput and recording milestones remain unchecked. [S1][S2]

Its audience is technically capable biopotential researchers and hardware builders willing to validate electronics, fit, radio behavior and signals themselves. It is not a medical device. The repository explicitly prohibits wearing it with charging, USB, debugger or grounded instruments attached; the charger interlock is **not electrical isolation**. Do not interpret this review as an endorsement of on-body safety. [S1][S2]

Anonymous GitHub metadata on the review date reported 131 stars, 9 forks, two open issues and last push 2026-11-26T17:29:52Z. The releases API returned an empty list. The reviewed commit is dated 2026-11-26; popularity and recent activity do not establish physical functionality. The two issue titles concern the MCU choice and first measurements, not evidence of completed validation. [S11]

## Stack

| Layer | Tech |
|-------|------|
| Acquisition hardware | Rev C custom board, ADS1298, nRF52832-QFAA, LSM6DSL |
| Embedded runtime | Zephyr C application; nRF52 DK target with custom pin/regulator overlay |
| Transport | Custom GATT service, notifications, ASCII control commands; single central |
| Host | Python asyncio/Bleak, NumPy; Linux BlueZ PHY helper |
| Analysis | NumPy features, shrinkage LDA/logistic regression, leave-one-session-out evaluation; optional HDF5/pandas readers |
| Persistence | Host NPZ recordings and JSON labels; no database/cloud service |
| Design/simulation | KiCad/Python, FreeCAD, ngspice, finite-volume forearm model; Blender rendering |

## Key Features

### A real acquisition pipeline, not just CAD

The firmware separates data-ready interrupt handling, SPI acquisition, a 64-frame ring, DSP/packetization, a 20-packet queue and BLE transmission. Sample indices and sequence counters expose losses rather than silently interpolating them. Diagnostics include raw DC, lead-off, clipping, battery, overruns and drops; the host corrects pod ordering and polarity. This is useful instrumentation for determining whether a model is learning muscle signals or recording faults. [S2][S3][S4]

### Sensible baseline evaluation—with a narrow implemented scope

The analysis package implements filters, quality gates, time-domain features, LDA/logistic regression and majority-vote trial scoring. Its CLI requires at least two input sessions and evaluates leave-one-session-out. That is a better default than randomly splitting overlapping windows. But each input file is treated as a session: users must actually separate donnings and avoid duplicate or correlated recordings. The CLI prints evaluation results; it is not a deployed online gesture decoder or pretrained general-purpose model. Offline zero-phase filtering also cannot establish causal end-to-end latency. [S5][S6]

### Transparent scientific assumptions, overstated if read as measurements

The science documents distinguish published facts, calculations and judgments, and describe bench gates. However, the README's approximately 1.2 µVrms noise and 90–98% posture / 75–90% micro-gesture expectations are design estimates or extrapolations—not measured accuracy on this band. Its 98–100% single-muscle separation is a forward-model result. The same model reports 70–74% for subtle co-activation with eight channels and substantial rotation sensitivity; it explicitly says it is not a measurement of a person or device. Analytic solver agreement validates numerical behavior under assumptions, not anatomy, dry-contact artifacts or real gesture decoding. [S1][S6][S7]

The claim of “four independent reviews” is a project description, not independently established peer review. This review did not replicate simulations or verify every cited paper. Meta hardware/data results cannot be transferred to this eight-channel device without accounting for channel geometry, polarity, front-end filtering, contact pressure and user/session shift. The project itself warns that zero-shot use of 16-channel checkpoints will likely fail. [S6][S7]

## Architecture

**Data flow:** electrodes → ADS1298 SPI → Zephyr acquisition/DSP → GATT notifications → Bleak recorder → local NPZ → quality/feature/evaluation commands. IMU data enters the same packet queue. Control writes are copied into bounded 40-byte command buffers and dispatched through an application work queue. The host parser checks packet lengths, types and zero gain for raw/diagnostic packets. These are good defensive basics, not a security boundary against an untrusted central. [S2–S5]

### Supported hardware versus verified operation

The current target is the custom Rev C nRF52832 board, not an arbitrary BLE wristband. Using the stock DK target is a build convenience: its overlay replaces pin mappings and disables the DK's DC/DC assumption because this board lacks the required inductor. The firmware documentation reports a successful Zephyr 4.4.2 / SDK 1.0.1 build with roughly 30% flash and 94% static RAM; it explicitly says the firmware has not been run on hardware and older Zephyr/NCS/SoftDevice variants are untested. Runtime stack margins remain unmeasured. [S2][S8]

A BLE 5 adapter with adequate MTU/data-length/2M negotiation is needed for the intended throughput. The suggested nRF52840 USB dongle is a Linux HCI adapter option, not firmware for the wristband. A cross-platform USB serial bridge is explicitly unimplemented. Windows/macOS behavior is discussed, not demonstrated compatibility. Raw 4 kSPS 24-bit streaming has much tighter radio requirements than the default filtered mode. Legacy ESP32 firmware exists separately and must not be confused with current Rev C support. [S1][S2]

### Security, permissions and privacy

- **BLE lacks an enforced authenticated/encrypted boundary.** GATT control and CCC writes use ordinary read/write permissions; the inspected connection path does not request security, and the configuration does not enable a pairing/bonding workflow. A nearby central able to connect can subscribe to physiological data or send start/stop/configuration/off commands. One-connection capacity is not authentication. The documented throughput budget explicitly assumes an unencrypted link. [S2][S3]
- **Device identity is weak.** Default scanning accepts the name or service UUID. An explicit address narrows selection but is not cryptographic identity. Treat the radio neighborhood as a trust boundary, especially with human recordings. [S4]
- **A local UDP marker listener is on by default.** It binds to loopback port 5006 unless changed or disabled; any local process can inject labels. An operator-selected non-loopback bind would expose unauthenticated marker injection on that network. There is no web app, HTTP authentication layer or CORS surface in this core path. [S4]
- **No cloud account/API key is required by the inspected recorder/analysis path.** Data stays in local arrays/files in that path; there is no observed automatic upload. BLE access and filesystem permissions still matter. Linux startup tries a fixed-argument btmgmt command that may require elevated adapter-management privileges; failure is tolerated, not a reason to run the whole research stack as root. [S4]
- **Local does not mean nonsensitive.** NPZ files contain EMG, IMU, wall-clock timestamps and labels; collection can record prompted keystrokes in its typing GUI. No application encryption, retention policy or participant-access controls were found. Use consent, restricted storage and deliberate deletion/backups. The NPZ loader disables pickle, but does not impose comprehensive size/shape limits for hostile input files. [S4][S5][S6]

### Persistence and recovery

The host retains the complete recording in RAM and writes NPZ at shutdown. Its finally block handles normal duration expiry, cancellation and disconnect during the main capture loop; there is no periodic checkpoint, append journal or atomic NPZ replacement. A process kill, power loss, memory exhaustion or failed save can lose the session. Setup before the main try/finally is also not comprehensively covered. Disconnect ends the run rather than automatically reconnecting and stitching a new clock epoch. [S4]

Firmware buffers absorb only short stalls; losses are visible but unrecoverable. No on-device recording/replay storage is implemented in this path. Label saves are stronger: JSON is written to a temporary file then replaced, and collection updates it incrementally. That does not make the paired signal recording durable. [S2][S4][S5]

### Concrete consistency and input-handling gaps

The firmware initializes the RLD mask to **0x0F**, but the host CLI defaults to **0x03** and sends that setting during connection; therefore the documented firmware default is not the effective default recording configuration. This changes the bias feedback sense set and should be reconciled before interpreting noise/stability comparisons. [S3][S4]

Numeric commands use permissive atoi/strtoul conversion, and a full command queue can discard writes while the GATT callback still returns the original length. Several reconfiguration operations ignore returned failures. A successful transport write therefore does not prove the intended setting took effect; retain and check status/readback rather than assuming acknowledgement equals application. These are static code findings, not demonstrated exploits or measured failures. [S3]

## Dependencies, Licensing and Maturity

No LICENSE/COPYING/NOTICE or project-wide grant was found in the tracked tree; GitHub reports no license. “Open” in the README is insufficient to authorize code, PCB or CAD reuse. Obtain explicit terms before redistribution, extraction or commercial manufacture. This review contains analysis and links, not copied implementation or design assets. [S1][S11]

The README credits Blender Studio Human Base Meshes as CC0 and KiCad stock libraries; that is not a full asset-rights audit. Vendor datasheets, libraries and toolchain components retain their own terms. NumPy/Bleak and optional analysis libraries, Zephyr/Nordic/CMSIS/SEGGER modules, CAD tools and simulation tools do not inherit a hypothetical project license. The flex generator has version pins and a Git-commit-pinned library dependency, but the host/analysis environment has no unified lockfile and firmware setup relies on an external SDK/workspace. No dependency vulnerability audit was performed. [S1][S2][S9]

Referenced model/data licenses must be checked separately. Anonymous reads of upstream LICENSE files confirmed **CC BY-NC 4.0** for generic-neuromotor-interface and **CC BY-NC-SA 4.0** for emg2pose and emg2qwerty at retrieval. Noncommercial and, where applicable, ShareAlike requirements are material; do not assume commercially reusable pretrained weights or training data. No external datasets/checkpoints were downloaded or relicensed by this review. These links are mutable upstream terms, not frozen legal advice. [S10]

Tests exist for malformed packet rejection, encoding/decoding, sequence wrap/gaps, recording/marker round-trips, filter behavior, synthetic quality faults, alignment, classifiers and HDF5 layouts. They are valuable software checks but do not validate an analog board or physiological generalization. No tracked GitHub Actions workflows were found, and no GitHub releases were published at retrieval. The reported successful firmware build/synthetic tests remain upstream claims: **tests run for this review: none**. [S2][S11][S12]

## Comparison

| Aspect | neurband | Meta GNI / emg2pose / emg2qwerty | Existing EMG acquisition platform |
|--------|----------|--------------------------------|-----------------------------------|
| Primary value | Inspectable custom wearable design and local recording | Research data, task definitions and model baselines | Reduce custom electronics/bring-up work |
| Hardware fit | Eight-channel Rev C, not yet bench-proven in reviewed evidence | Different 16-channel research hardware; typing uses both wrists | Evaluate OpenBCI or established lab EMG systems against channel/rate/isolation needs |
| Model readiness | Offline LDA/logistic baselines and experiment plan | Published task-specific models; substantial domain mismatch | Acquisition alone still does not supply calibrated gesture decoding |
| Main tradeoff | Assembly, validation, auth and licensing burden | Noncommercial data/model terms and transfer limitations | Different form factor, price and data access; not a drop-in wristband equivalent |

For software-method study, the linked Meta repositories are the closer alternative. For collecting trustworthy signals soon, evaluate established acquisition hardware first rather than assuming a DIY wristband is cheaper after validation effort. No alternative hardware was purchased or tested, and this is not a spending recommendation. [S6][S10] See also [OpenBCI documentation](https://docs.openbci.com/) for a separate platform to assess, not a validated substitute.

## Self-Hosting Notes

This is local hardware/desktop software, not a server to deploy. A sensible future pilot would first resolve licensing; freeze toolchain and dependency versions; validate the Rev C board off-body; measure noise, charger behavior, radio throughput and runtime stack margins; then establish a consented data-collection protocol. The source estimates a first-build batch at roughly $290–350, not a verified delivered unit price. [S1][S2]

Before real collection, add authenticated/encrypted BLE with explicit device identity, durable chunked recording and reconnect epochs; reconcile RLD defaults; keep markers loopback-only or disable them; and validate held-out donnings plus null-data false activations. Do not use firmware charge detection as a substitute for electrical isolation or qualified safety review. No installation or flashing was performed for this review.

## Verification and Evidence

Canonical identity was normalized from the submitted .git URL to the public repository URL. Anonymous API/source access succeeded. Existing public reviews/index were searched without finding this source, so this is a new review, not a duplicate refresh. Source inspection was static and selective: no full PCB electrical/netlist/DRC audit, mechanical strength test, antenna measurement, battery-runtime validation, safety certification, simulation rerun or scientific replication. Binary CAD/media assets were not executed. The shallow checkout does not establish full historical maturity.

All repository citations below are pinned to the reviewed commit; metadata and external licenses are retrieval-date observations.

- [S1] [README and status](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/README.md).
- [S2] [Rev C firmware, hardware, safety and throughput documentation](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/docs/firmware_c.md).
- [S3] [BLE service](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/firmware_c/src/ble.c), [application commands](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/firmware_c/src/main.c), [acquisition](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/firmware_c/src/acq.c), [configuration](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/firmware_c/prj.conf).
- [S4] [BLE recorder/parser/save path](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/host/neurband_ble.py).
- [S5] [Model/evaluation](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/analysis/model.py), [CLI](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/analysis/__main__.py), [recording and atomic label saves](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/analysis/recording.py).
- [S6] [Data/model evidence, protocols and limitations](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/docs/science/data_and_models.md).
- [S7] [Forward-model methods and caveats](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/docs/science/emg_forward_model.md).
- [S8] [Build configuration](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/firmware_c/CMakeLists.txt), [board overlay](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/firmware_c/boards/nrf52dk_nrf52832.overlay).
- [S9] [Flex dependencies](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/boards/neurband_c_flex/requirements.txt).
- [S10] Upstream license texts retrieved 2026-11-27: [GNI](https://github.com/facebookresearch/generic-neuromotor-interface/blob/main/LICENSE), [emg2pose](https://github.com/facebookresearch/emg2pose/blob/main/LICENSE), [emg2qwerty](https://github.com/facebookresearch/emg2qwerty/blob/main/LICENSE).
- [S11] [Public repository metadata](https://api.github.com/repos/jlcjak/neurband), [releases](https://api.github.com/repos/jlcjak/neurband/releases), [issues](https://github.com/jlcjak/neurband/issues), [tracked tree](https://github.com/jlcjak/neurband/tree/323cb41daeaa09287bed4ad71032d4161647558f).
- [S12] [BLE packet tests](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/host/test_ble_packet.py), [analysis tests](https://github.com/jlcjak/neurband/blob/323cb41daeaa09287bed4ad71032d4161647558f/analysis/tests/test_analysis.py).

---

**Attribution:** jlcjak/neurband; no project-wide license found. External research, tools and assets retain their respective attribution and terms.
