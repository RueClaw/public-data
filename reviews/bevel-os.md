# Bevel OS (andrisgauracs/bevel-os)

**Repo:** https://github.com/andrisgauracs/bevel-os
**License:** MIT for Bevel; GPL v2 for Doom components and bundled Doom.elf; dependency and game-data terms separate.
**Reviewed:** 2026-11-15 (UTC)
**Revision:** f620228140f1cb07a0647fbc23925ab8b220e09f (main; commit dated 2026-11-14). Scope: firmware, app SDK/loader, bundled-app build pipeline, serial tools, storage/network/browser, hardware documentation, tests, assets and licensing.
**Verification:** Static source review only. No firmware build, source execution, device access, flashing, network-runtime probes, dependency installation or WAD download. Upstream performance and hardware-test results were inspected, not reproduced.
**Stack:** C, Xtensa assembly, ESP-IDF 5.5.3, FreeRTOS, FAT/wear levelling, esp_lcd, Espressif ELF loader and USB HID, Python serial tooling.
**What it is:** A real embedded graphical desktop firmware for one particular ESP32-S3 configuration—not a Linux distribution, PC OS, web desktop or AI runtime.

## Verdict

📚 **Study — impressive constrained-hardware desktop engineering, not a trustworthy general-purpose workstation.** The strongest ideas are its PSRAM-conscious strip compositor, scan-out cursor, and serial-driven UI acceptance loop. Native apps share the firmware's trust domain, Wi-Fi credentials are plaintext, and automatic reformatting plus weak recovery tests prevent treating the drive as durable storage. A spare-board hobby experiment is reasonable; valuable documents, sensitive networks and untrusted ELF programs are not.

## What It Is

Andris Gauracs publishes a Windows-95-style desktop for an ESP32-S3 N16R8 board (16 MB flash, 8 MB octal PSRAM), driving 640×480 VGA in 64 colours through a resistor DAC. The repository contains implementation, source-generated assets, prebuilt ELF apps, enclosure models, screenshots and development reports. ESP-IDF/FreeRTOS supply the scheduler, boot chain, networking and filesystem: Bevel supplies the desktop/toolkit, rendering strategy and application interface. Calling it an embedded desktop OS is fair; calling it an independently implemented kernel would not be. [1–3]

Built-ins include a file manager, text editor, BMP viewer, terminal, settings, network panel and text browser. Hello, Snake, CrashTest and Doom are separately loadable programs. The intended audience is embedded graphics enthusiasts, retro-computing hobbyists and developers studying a compact end-to-end desktop—not users seeking modern web compatibility or protected multiuser computing.

The README credits an AI coding model and documents human interventions. Those are author-provided provenance claims, not an independently audited development history or a controlled model benchmark. The code is more useful evidence than the attribution headline. [1]

## Stack

| Layer | Implementation and implications |
|---|---|
| Hardware | ESP32-S3, 240 MHz, octal PSRAM at 80 MHz; fixed VGA and USB GPIO wiring |
| System | ESP-IDF 5.5.3 / FreeRTOS; factory app partition, no OTA slots in the supplied layout |
| Graphics | esp_lcd RGB output, internal bounce buffers, PSRAM framebuffer, Xtensa PIE copy/fill routines |
| Desktop | Custom C window manager, toolkit, menus, dialogs, shell; not LVGL |
| Apps | Position-independent native ELF, elf_loader 2.1.0, function-table API, up to four app tasks |
| Storage | 12 MB flash FAT partition with wear levelling, mounted at /disk; no SD card |
| Network | ESP-IDF Wi-Fi station and HTTP client, mbedTLS certificate bundle; text-only HTML renderer |
| Development | CMake/IDF, zsh helper scripts, Python/pyserial command bridge and hardware tests |

## Key Features and Architecture

### Render where memory is fast

The GUI and scan-out ISR share core 1; USB, serial and loaded apps use core 0. The display driver refills two ten-line internal-RAM bounce buffers from a roughly 300 KiB PSRAM framebuffer. The cursor is overlaid during scan-out instead of erasing/repainting framebuffer pixels. That decouples pointer movement from expensive GUI redraws. [2]

The compositor merges a bounded set of dirty rectangles, sorts damage top-to-bottom, paints strips in a 20 KiB aligned internal buffer, and writes each finished strip to PSRAM. Beam-position estimates keep writes behind scan-out. Aligned 128-bit copies help internal memory; the performance report correctly distinguishes that from PSRAM bus limits and records rejected GDMA/cross-core alternatives. These are concrete, inspectable design decisions rather than a vague “optimized renderer” claim. [2, 10]

### Small but coherent application model

Each ELF gets its own FreeRTOS task, event queue and private drawing canvas, with GUI calls marshalled back to the desktop task. Memory allocations and open files are tracked for cleanup. Import resolution provides a function table and C-library wrappers; system() is stubbed out. This is a practical extension mechanism for trusted programs, not a security sandbox. [3]

Selected Xtensa faults outside an OS API call are redirected to a landing routine, then cleaned up with an error dialog. Faults while in_api is set fall through to the unhandled exception path. Hang detection checks unread events and time since polling. More importantly, os_task_kill retries waiting for an app to leave an OS call for 200 iterations, then deletes it regardless: the “never ended holding the drive lock” comment is stronger than the implementation. Some wrappers, including formatted file output, also do not use the same in_api guard. These are static reliability concerns, not reproduced deadlocks. [3]

### Testable without manual clicking

The UART command channel supports framebuffer dumps, injected keyboard/mouse events, window/focus inspection, file reads/writes, launch, reboot and diagnostics. kbtest.py drives real UI workflows and compares focus, windows and text contents. This is a valuable agent-development/testing pattern: observe actual state and round-trip files instead of judging screenshots alone. However, the test is a device-mutating acceptance script, not an offline unit suite. [6, 10]

## Security, Permissions and Privacy

### One trusted operator, no protected app boundary

There is no login, per-app user identity, permissions dialog, application signing gate or protected process address space in the inspected loader. ELF magic/length checks and relocation reject some invalid binaries; they do not establish trust. An app can use native pointers in the same firmware address space. A private canvas limits normal drawing interactions, not arbitrary memory access. [3]

Even normal file APIs expose shared state: api_file_read/write root paths at /disk and reject “..”, but do not isolate each app's directory. The libc fix_path accepts absolute paths unchanged and maps relative names into shared /disk/System. Consequently a trusted-interface app can reach wifi.ini and other applications' files without escaping anything. Do not infer least privilege from the small API surface or the system() stub. [3, 5]

### Serial access is administrative access

The firmware's COM command channel has no authentication or confirmation step for destructive operations. A connected host can read text files, upload/overwrite files, inject input, launch apps, delete files and reset the board. The Python daemon binds only to 127.0.0.1, which is a useful exposure limit, but uses unauthenticated raw TCP; other local processes able to connect inherit its board authority. Its request accumulation has no explicit size cap or initial read deadline, making local denial of service another concern. This is not an Internet-facing web service, so CORS is not the governing boundary. Do not tunnel or publicly bind it. [6]

The daemon appends all serial replies to build/serial.log. Reading a credential file or exposing focused text through diagnostics can therefore leave a host-side copy. There is no built-in log-retention policy; the flash helper truncates this log. Physical USB access and the development host must both be trusted. [6]

### Networking is optional, not confidential by default

The radio starts on network/browser use or automatically at boot when saved credentials exist. Wi-Fi is persisted as plaintext in /disk/System/wifi.ini; the driver itself uses RAM credential storage. “Forget” unlinks the saved file, but that is not secure erasure from wear-levelled flash, and does not constitute wiping all in-memory driver state. Secure boot and flash encryption are disabled in the supplied sdkconfig. [5, 8]

HTTP GET supports bounded page bodies, cancellation, timeouts and redirects. HTTPS uses the ESP certificate bundle, a positive sign, but CONFIG_MBEDTLS_HAVE_TIME_DATE is disabled: certificate validity dates are not checked as they would be with working time validation. Bare domains start with HTTP, searches go to FrogFind over HTTP, and redirect handling has no explicit HTTPS-downgrade prohibition. Avoid secrets in queries or pages. No cloud account, AI key or model service is required to operate the desktop. [5]

The browser does not execute JavaScript or load CSS/images, substantially shrinking active-content functionality. It still parses untrusted HTML in C, follows navigation to network destinations without a private-address policy, and accepts file:// links for local files without a separate confirmation boundary. This is not proof of automatic file exfiltration—there is no script engine—but it is also not a modern browser-origin sandbox. History is held in the browser structure; no durable history database was found in the reviewed implementation. [5]

## Persistence, Export and Recovery

The filesystem auto-formats when mounting fails. Bundled apps are restored when missing, differently sized, or after a firmware-ID change; sample files have their own installation marker. This makes a broken drive look usable again but can destroy user data. An update can replace modified bundled apps, and deleting a bundled ELF is not a durable uninstall because boot restores it. The restoration code does not comprehensively check write/close success before recording the firmware stamp. [4]

Editor, settings and Wi-Fi saves use temporary files, but explicitly unlink the original before renaming. That leaves a failure window with no original at its expected path; there is no reviewed journal/recovery scan promoting surviving .tmp files. Direct app writes and serial uploads truncate destinations. FAT wear levelling is not a transactional backup system. [4, 5]

**The headline power-cut result does not establish user-data integrity.** powercut.py resets via EN during a synthetic write, then checks that the desktop responds and Documents, Welcome.txt and Snake.elf exist. The boot routine recreates all three after reformatting. The test checks neither a non-bundled sentinel nor content hashes, and can therefore pass after destructive recovery. The README appropriately distinguishes its twelve resets from a single real unplug; the test's stronger “files intact” description is not supported by those assertions. [4, 10]

Files remain ordinary FAT contents, but the supplied host CLI provides upload, screenshot and serial-command operations rather than a complete binary download/archive/restore workflow. Its cat command is text-oriented, so it is not a general binary backup mechanism. Before relying on data, add and independently test an explicit partition/file backup and restore procedure. Doom WAD data is not embedded and will not be restored by firmware; saved-game behavior was not tested upstream. [1, 6]

## Platform, Build and Lifecycle

- **Target hardware is narrow.** The supplied build targets ESP32-S3 N16R8 with octal PSRAM, fixed pins and nonstandard integer-divided VGA timing. Other ESP32 variants, smaller-memory boards and different monitors are not qualified by this review. This is not something to install as a Linux desktop package. [1, 2, 8]
- **USB needs careful wiring.** Native USB pins are used as host input; the README warns to leave the board's AUX connector unplugged. Board-specific power behavior, an externally powered input breakout and unsuitable USB-C cables are documented. Review the actual board schematic rather than generalizing the wiring. Two separate USB devices through hubs were not demonstrated working; a combined keyboard/mouse receiver is the documented working option. [1]
- **Build from pinned inputs.** dependencies.lock records IDF 5.5.3, elf_loader 2.1.0, usb_host_hid 1.2.1 and cmake_utilities 0.5.3 with registry hashes. The manifest is looser (including elf_loader “*” and an overbroad IDF minimum); keep the lock and known SDK rather than assuming a fresh resolution is equivalent. The external loader implementation was not downloaded/audited here. [8]
- **Prebuilt code is part of the default firmware.** main/CMakeLists.txt embeds existing disk/Apps/*.elf; a successful firmware build would not prove those binaries reproduce from source. Rebuild the app artifacts in a controlled toolchain before higher-trust distribution. Mac-oriented zsh helpers assume a particular SDK/Python location and BSD stat; Linux needs adaptation. Doom's helper suppresses compiler warnings, and the main component suppresses format-truncation warnings. [8, 9]
- **Flashing is destructive to the previous firmware.** The documented flow writes bootloader, partition table and factory app, not the storage partition. There are no supplied OTA slots or automatic rollback path. A changed partition layout still risks existing data, and first boot can format on mount failure. Recovery is manual reflashing with a known-good image and separately preserved data. [1, 4, 8]
- **Helper success is not enough.** flash.sh checks the build pipeline but does not similarly gate its later flash pipeline before clearing the log and restarting the daemon. Use actual flash/readback/boot evidence, not the helper's final exit alone. Explicitly select the device: auto-discovery chooses the first matching serial port. [9]
- **Removing it:** stop the serial daemon and flash replacement firmware if desired; separately clear retained storage/credentials when repurposing the board. No packaged uninstall or secure-wipe procedure was found. Erasing data must be a deliberate, backed-up action—not an implicit review step.

## License and Assets

The actual LICENSE grants MIT rights to Bevel with explicit exceptions for vendored doomgeneric, apps/doom and Doom.elf under GPL v2. Preserve MIT notices. Shipping the default firmware carries the embedded GPL program too; do not label the whole distribution MIT-only, and satisfy the applicable source/notices obligations for Doom. The third-party note identifies doomgeneric commit e257a09527062bfb986b6e5e0780839b6cbd5b71 and notes source headers permit v2 or later. Build-to-binary correspondence was not verified. [7]

The README describes fonts/icons/cursors as original and includes editable asset-generation sources; that is inspectable provenance, not a legal originality audit. Enclosure files and other first-party assets fall under the root license absent the stated exceptions. The WAD is separately licensed game data, not GPL engine code, and is not committed. Its downloader uses a third-party mirror and an MD5 identity check; mismatch merely prints a warning and does not force a failing exit. If the vendored engine is absent, the helper clones current upstream rather than the documented pinned revision. Neither path was executed. [7, 9]

## Evidence, Tests and Maturity

At retrieval on 2026-11-15, GitHub reported public visibility, creation on 2026-11-14, last push on 2026-11-14, 53 stars, 12 forks and two open issues. The releases API returned an empty list. The two issues propose other target platforms and VNC/network features; they are requests, not delivered capabilities. These are transient metadata, not reliability evidence. No .github CI workflows or portable offline regression suite were found in the inspected tree. Shallow history was not used to infer a complete commit count. [11]

| Claim | Evidence and assessment |
|---|---|
| 0.7 s boot, roughly 32 FPS Doom | Author measurements and implementation exist; not independently reproduced |
| 68 FPS drag / 76 FPS redraw | Workload-specific processing rates in PERF.md, not proof of that many unique visible frames on a roughly 60 Hz output |
| Tear-free display | Beam-racing code and scan-out counters support the approach; upstream says tearing was not checked visually, and late-fill counters do not establish all visual correctness |
| 34/34 keyboard steps | Substantive device-driven assertion script exists; upstream result only |
| 12/12 power cuts survived | Checks reboot/recreated bundled paths, not preservation of arbitrary user content |
| App fault containment | Selected exceptions recovered outside OS calls; shared memory and API faults remain system-wide risks |

Independent verification here comprised source/ref inspection, dependency/license review, static control/data-flow tracing and checking public metadata. **No upstream tests were run.** No claim is made about successful compilation, hardware electrical safety, full parser memory safety, cryptographic implementation correctness, reproducible binaries, real power-loss durability or long-term operation. The absence of a found problem in other modules is not a security audit pass.

## Comparison

| Option | Prefer it when | Tradeoff relative to Bevel |
|---|---|---|
| Bevel OS | Studying a complete tiny retro desktop on the documented S3 board | Cohesive demo; narrow hardware and shared-trust runtime |
| [FabGL](https://github.com/fdivitto/FabGL) | Exploring ESP32 VGA, retro UI, terminal/emulation and PS/2 integrations | Broader graphics/retro toolkit, not this S3 firmware; its README warns of an older Espressif-library ceiling, so verify board/SDK compatibility first |
| [LVGL](https://github.com/lvgl/lvgl) on ESP-IDF | Building a maintainable embedded product UI with reusable widgets and platform integrations | UI library, not a ready desktop/file manager/ELF OS; integration work remains |
| Linux on a suitable single-board computer | Wanting modern browsing, users/process isolation, packages and established backup tools | More memory/power/hardware, but a fundamentally better fit for general computing |

Alternative READMEs were checked for category and compatibility caveats, not benchmarked. No evidence supports claiming Bevel is faster than those alternatives on comparable hardware.

## Practical Next Steps

For study, start with comp.c/vga.c, then trace app_loader.c and the UART test protocol. For a future spare-board pilot, first reproduce a clean build and binaries, verify exact hardware/power wiring and input-device compatibility, use a disposable network credential, keep third-party ELFs out, and demonstrate backup restoration. Replace the power-loss acceptance condition with non-bundled content hashes and explicit detection of formatting; remove silent format-on-mount-failure before entrusting data. Treat app isolation and secure credentials as architectural work, not a cosmetic permission dialog.

## Source Evidence

All repository links below pin the reviewed revision.

1. [README: purpose, hardware, limits and provenance](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/README.md).
2. [main/main.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/main.c), [comp.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/comp.c), [vga.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/vga.c).
3. [app_loader.c: app_path, fix_path, app_exception, os_run_elf, os_task_kill](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/app_loader.c), [apps/bevel.h](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/apps/bevel.h).
4. [storage.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/storage.c), [app_editor.c: ed_write](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/app_editor.c), [app_misc.c: settings_save](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/app_misc.c).
5. [net.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/net.c), [app_browser.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/app_browser.c), [sdkconfig](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/sdkconfig).
6. [serial.c](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/serial.c), [tools/bv.py](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/tools/bv.py), [main.c: os_serial_command](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/main.c).
7. [LICENSE](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/LICENSE), [third_party/README.md](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/third_party/README.md), [asset sources](https://github.com/andrisgauracs/bevel-os/tree/f620228140f1cb07a0647fbc23925ab8b220e09f/tools/assets).
8. [dependencies.lock](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/dependencies.lock), [component manifest](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/idf_component.yml), [main/CMakeLists.txt](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/main/CMakeLists.txt), [partitions.csv](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/partitions.csv).
9. [build/flash/download helpers](https://github.com/andrisgauracs/bevel-os/tree/f620228140f1cb07a0647fbc23925ab8b220e09f/tools): build_apps.sh, build_doom.sh, flash.sh, fetch_doom.sh.
10. [PERF.md](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/docs/PERF.md), [powercut.py](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/tools/powercut.py), [kbtest.py](https://github.com/andrisgauracs/bevel-os/blob/f620228140f1cb07a0647fbc23925ab8b220e09f/tools/kbtest.py).
11. [Public repository metadata](https://api.github.com/repos/andrisgauracs/bevel-os), [releases](https://github.com/andrisgauracs/bevel-os/releases), [issues](https://github.com/andrisgauracs/bevel-os/issues), retrieved 2026-11-15 UTC.

---

**Attribution:** Andris Gauracs / andrisgauracs/bevel-os. MIT Bevel implementation; GPL v2 Doom exceptions and separate dependency/game-data terms. This review contains independent analysis, not redistributed application binaries or game assets.
