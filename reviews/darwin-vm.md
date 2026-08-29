# darwin-vm (jprx/darwin-vm)

**Repo:** https://github.com/jprx/darwin-vm
**License:** MIT for the wrapper repo; bundled `qemu-sptm` submodule is QEMU-derived GPL-2.0-family code
**Reviewed:** 2026-08-28
**Stack:** Shell, Python, QEMU fork, Apple IPSW extraction, XNU/Darwin boot tooling
**What it is:** A tiny wrapper around a custom QEMU fork for booting barebones iOS/macOS Darwin systems to a root shell for low-level kernel and userspace research.

---

## Verdict

⚠️ **Interesting lab tool for Darwin/XNU work, not a general iPhone or Mac emulator.** The project is technically sharp: it packages a patched QEMU machine, device-tree fixups, trust-cache generation, ramdisk surgery, SPTM/TXM handling, and clear debugging notes into a small reproducible workflow. The caveats are big: it is one commit old, depends on remote Apple IPSW assets and a separate QEMU fork, modifies ramdisks to launch root shells, has no project-level CI, and local QEMU configure could not be completed here because `ninja` was missing.

---

## What It Is

`darwin-vm` boots recent iOS and macOS Darwin kernels under QEMU to a console root shell. It explicitly does not emulate a full iPhone or Mac UI: no SpringBoard, GUI apps, Wi-Fi, Bluetooth, graphics stack, or normal device experience. The intended user is a kernel, reverse-engineering, emulator, or security researcher who wants an XNU playground closer to "Linux + initrd in QEMU" than to a consumer VM.

The root repo is mostly orchestration. `get_files.sh` uses `ipsw` to fetch kernelcache, SPTM/TXM firmware where needed, device tree, and ramdisk from a remote IPSW. `dt_fixup.py` rewrites Apple device-tree properties so QEMU can satisfy enough of XNU's boot expectations. `build_tc.py` builds a simple trust cache from code-signing CDHashes. `fix_perms.sh` repairs root ownership inside the ramdisk. `run.sh` invokes the custom `qemu-sptm` binary with the prepared firmware inputs.

The actual emulator work lives in the `qemu-sptm` submodule. It adds a `-M darwin` machine and XNU-specific boot inputs such as `-bootkc`, `-dtree`, `-sptm`, `-txm`, `-tc`, and `-ramdisk`, plus Apple Silicon register/device-tree support and SPTM/TXM memory-map loading logic.

## Stack

| Layer | Tech |
|-------|------|
| Runner | `run.sh`, QEMU `aarch64-softmmu`, `-M darwin` |
| Firmware acquisition | `ipsw`, `jq`, `wget`, Apple IPSW URLs |
| Ramdisk patching | `hdiutil`, launchd plist replacement, `ditto`, `codesign` |
| Device tree patching | Python Apple Device Tree parser/encoder |
| Trust cache | Python CDHash list to TrustCache v1 binary |
| Emulator core | `jprx/qemu-sptm`, QEMU-derived C/C++/Meson tree |
| Debugging | QEMU GDB stub, LLDB/GDB, development kernelcache workflow |

## Key Features

### Modern Darwin Targets

The README claims tested boots for iPhone 12 through iPhone 17 class devices and M1 through M5 class Macs, including newer SPTM/TXM/MIE-era targets. That is the main reason this repo is interesting: older iOS-in-QEMU references exist, but this project focuses on newer Apple Silicon boot machinery.

### Barebones Root Shell

The setup replaces the ramdisk launchd daemons with simple `/bin/sh` or `/bin/bash` console services, then fixes root ownership so launchd accepts them. The result is a deliberately stripped research environment: boot quickly, land in a root shell, copy in signed command-line programs, update the trust cache, and iterate.

### SPTM/TXM-Aware QEMU Fork

`qemu-sptm` is more than a wrapper. It adds Darwin machine properties, maps BootKC/TXM/SPTM segments in the order expected by Apple's boot chain, constructs boot args, updates `/chosen/memory-map`, initializes Apple-specific system registers, and patches one AppleImage4 deadlock path. The code is full of "make XNU happy" details that are hard to rediscover.

### Kernel Debugging Path

The README includes a practical LLDB/GDB workflow, kernelcache rebasing notes, and a development-kernel path through Apple's KDK and `kmutil create`. That makes the repo useful as documentation even for people who do not use the exact scripts.

## Architecture

The root project is intentionally small:

```text
darwin-vm/
  get_files.sh       # fetch IPSW pieces, patch device tree, patch ramdisk
  dt_fixup.py        # decode/modify/re-encode Apple Device Tree blobs
  build_tc.py        # build TrustCache v1 from CDHash lines
  fix_perms.sh       # mount ramdisk and chown boot-critical paths
  run.sh             # invoke qemu-sptm/build/qemu-system-aarch64
  launchdaemons/     # replacement shell launchd plists
  qemu-sptm/         # custom QEMU fork submodule
```

The cleanest boundary is between host-side preparation and emulator-side boot. Host scripts create a `firmware/` directory containing `bootkc`, `dtree`, `sptm`, `txm`, `ramdisk.dmg`, and `ramdisk.tc`; QEMU consumes those immutable-ish artifacts at launch. That makes the workflow understandable and easy to inspect.

The less clean part is provenance and repeatability. `get_files.sh` downloads a prebuilt iOS userspace tarball from another GitHub repository, relies on live Apple IPSW URLs, and does not verify checksums. For a research lab this may be acceptable; for a reproducible artifact, it needs pinned hashes and release assets.

## Comparison

| Aspect | darwin-vm | Earlier iOS-QEMU Writeups | Full macOS Virtualization.framework |
|--------|-----------|---------------------------|-------------------------------------|
| Goal | Bare Darwin root shell for research | Boot older iOS/XNU targets | Supported macOS VM experience |
| UI/device fidelity | Minimal console only | Minimal/experimental | Real macOS GUI VM |
| Modern SPTM/TXM support | Yes, core focus | Usually no | Hidden behind Apple stack |
| Host portability | QEMU path can run where QEMU runs after Mac prep | Varies | Apple Silicon macOS host |
| Debuggability | Strong LLDB/GDB notes | Often research-note quality | Good for macOS, less low-level control |
| Operational maturity | Fresh, one-commit repo | Historical references | Production Apple framework |

## Self-Hosting Notes

Use this only in a dedicated research workspace. It downloads Apple firmware inputs, rewrites ramdisks, runs custom QEMU code, and intentionally boots a root shell. The root scripts passed `bash -n`, ShellCheck, and Python bytecode compilation locally. `build_tc.py` also produced the expected 68-byte trust-cache blob for two sample hashes.

I did not complete a QEMU build. `./configure --target-list=aarch64-softmmu` began setting up QEMU's Python environment but failed because `ninja` is not installed on the review machine. No full VM boot was attempted.

Security/reproducibility checklist before serious use:

- Pin and verify the downloaded `ios-cli-tools` tarball.
- Record exact IPSW URLs, build numbers, and hashes in `firmware/info`.
- Treat patched ramdisks and extracted firmware as local research artifacts, not redistributable project assets.
- Keep the VM and QEMU fork isolated from sensitive host paths.
- Expect churn: this is a brand-new repository with no releases, tags, or CI evidence in the wrapper repo.

---

**Attribution:** jprx/darwin-vm, MIT License for wrapper repo; `jprx/qemu-sptm` derives from QEMU GPL-2.0-family code
