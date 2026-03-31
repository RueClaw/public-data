# vphone-aio (34306/vphone-aio)

*Review #294 | Source: https://github.com/34306/vphone-aio | License: none stated | Author: 34306 | Reviewed: 2026-03-30 | Stars: 1,360*
*Upstream: [Lakr233/vphone-cli](https://github.com/Lakr233/vphone-cli) (4,854 stars, MIT) | Writeup: [wh1te4ever/super-tart-vphone-writeup](https://github.com/wh1te4ever/super-tart-vphone-writeup) (975 stars)*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A one-script launcher for **vphone** — a fully virtualized iPhone (iOS 26.x) running on macOS via Apple's private Virtualization.framework PCC (Private Cloud Compute) research infrastructure. Jailbroken, with SSH and VNC access, on a Mac. This is the easiest entry point to a research project that is genuinely remarkable.

`vphone-aio` is a thin wrapper. The real work is in [Lakr233/vphone-cli](https://github.com/Lakr233/vphone-cli) (Swift, MIT) and the [wh1te4ever writeup](https://github.com/wh1te4ever/super-tart-vphone-writeup). This review covers the whole stack.

---

## How It Works

Apple built `Virtualization.framework` for their Private Cloud Compute infrastructure — the ML inference backend that powers Apple Intelligence features. The framework can boot iOS images on Apple Silicon Macs. This was intended for internal research but the API is accessible if you bypass SIP/AMFI restrictions.

The vphone-cli project reverse-engineered the boot chain and firmware patching required to:
1. Download a real iPhone IPSW + PCC CloudOS image
2. Patch the boot chain (41/52/112 binary patches depending on variant)
3. Apply a custom firmware (CFW) in 10/12/14 phases
4. Boot the resulting VM via Virtualization.framework
5. Expose SSH and VNC via `iproxy` tunnels

**Three firmware variants:**

| Variant | Boot patches | CFW phases | Result |
|---------|-------------|------------|--------|
| Regular | 41 | 10 | Shell access |
| Development | 52 | 12 | + TXM entitlement/debug bypasses |
| Jailbreak | 112 | 14 | + Sileo, TrollStore, full security bypass |

The jailbreak variant runs the finalization automatically on first boot via a LaunchDaemon (`/cores/vphone_jb_setup.sh`).

Tested hardware: Mac16,12 running macOS 26.3. iOS versions: 26.1, 26.3, 26.3.1.

---

## vphone-aio Specifically

`vphone-aio` reduces the vphone-cli setup (multiple Makefile targets, two-terminal restore flow, manual iproxy) to a single script:

1. Ships the pre-built `vphone-cli.tar.zst` split across 7 parts (stored in Git LFS — ~12GB total)
2. `vphone-aio.sh` merges parts, extracts, builds, starts iproxy tunnels (SSH on 22222, VNC on 5901), and runs `boot.sh`
3. Auto-downloads missing parts if you have a partial clone

The README says to disable SIP and set `amfi_get_out_of_my_way=1`. That's the main prerequisite — plus 128GB+ free disk (recommended).

**Security note:** The repo ships pre-built binaries split across Git LFS. SHA-256 checksums are provided. For a repo with no license and an anonymous author, this warrants verification before running.

---

## vphone-cli Architecture

The full vphone-cli project (Lakr233, MIT) is more substantial:

```
sources/          — Swift source (vphone-cli binary)
scripts/          — Makefile targets: fw_prepare, fw_patch, ramdisk_build, cfw_install, boot
research/         — Binary patch documentation
vendor/           — Vendored Swift deps + toolchain sources (submodules)
skills/           — OpenClaw/Hermes skills (this is an AI-integrated project)
```

**Makefile targets (key flow):**
```bash
make setup_machine    # full automation (preferred)
# OR manual:
make setup_tools      # deps + Python venv
make build            # build + sign vphone-cli Swift binary
make vm_new           # create VM directory (CPU, MEMORY, DISK_SIZE configurable)
make fw_prepare       # download IPSW + CloudOS, extract, generate manifest
make fw_patch         # binary-patch boot chain (regular variant)
make boot_dfu         # boot VM in DFU mode (terminal 1)
make restore          # flash via idevicerestore (terminal 2)
make cfw_install      # install custom firmware
make boot             # normal boot
```

VM config stored in `vm/config.plist` (compatible with Apple's security-pcc VMBundle.Config format). VM backup/switch system for managing multiple iOS builds.

The binary patching is done via analysis, not static offsets — the README explicitly states "newer versions should work" for future iOS builds.

**Access after boot:**
- SSH (JB): `ssh -p 2222 mobile@127.0.0.1` (password: `alpine`)
- VNC: `vnc://127.0.0.1:5901`
- RPC: `rpcclient -p 5910` via [doronz88/rpc-project](https://github.com/doronz88/rpc-project)

---

## Why This Matters

This is Apple Silicon's Virtualization.framework running a full iOS instance, virtualized, on macOS — something Apple never documented or intended for public use.

**Practical uses:**

1. **iOS security research** — full shell access, jailbroken, with TrollStore and Sileo, running real iOS
2. **App testing** — install `.ipa` and `.tipa` packages, test without a physical device
3. **Automation** — RPC port exposes the iOS runtime to programmatic control
4. **PCC/Apple Intelligence research** — this is the PCC VM infrastructure; relevant for anyone studying Apple's ML privacy claims
5. **Sandboxed iOS environment** — disposable, VM-restorable, useful for malware analysis

**What makes it notable vs. iOS simulators:**
- iOS Simulator is not iOS. This is real iOS firmware, booted on virtualized ARM hardware.
- Full jailbreak means full filesystem access, no sandbox restrictions
- RPC port enables programmatic control of the running iOS instance
- VM snapshots / backup-restore for reproducible environments

---

## Requirements & Caveats

**Requirements:**
- macOS 26.3+ (Sequoia/Tahoe) on Apple Silicon
- SIP partially or fully disabled + `amfi_get_out_of_my_way=1`
- Xcode (for Swift compilation)
- ~128GB+ free disk (recommended)
- `brew install aria2 ideviceinstaller wget gnu-tar openssl@3 ldid-procursus sshpass keystone autoconf automake pkg-config libtool cmake`

**Caveats:**
- Requires disabling system security features (SIP/AMFI). Not a casual install.
- vphone-aio has no license. vphone-cli is MIT.
- Pre-built binaries in vphone-aio — verify checksums before running.
- Nested virtualization doesn't work (can't run inside a VM).
- System apps (App Store, Messages) won't work if you pick Japan/EU region during setup (regulatory checks the VM can't satisfy).
- This uses Apple's private PCC infrastructure APIs. Apple could change or block this at any time.

---

## Verdict

🔥🔥🔥🔥🔥 — One of the most technically impressive projects in the Apple Silicon ecosystem. Running a fully jailbroken virtual iPhone on macOS via the PCC Virtualization.framework is a genuine research achievement. `vphone-aio` packages the complexity into a single script at the cost of requiring trust in pre-built binaries. The full `vphone-cli` (MIT, Lakr233) is the verifiable upstream. For iOS security research, app testing in a sandboxed environment, or PCC/Apple Intelligence research, this is the tool. The SIP/AMFI requirements make it a dedicated research machine install, not something you'd put on a daily driver. Cloned to `~/src/vphone-aio`. Upstream at `~/src/vphone-cli` (recommend cloning that instead for serious use).

---

*Attribution: vphone-cli by Lakr233 (MIT). Original writeup by wh1te4ever (Hyungyu Seo). vphone-aio is a convenience wrapper with no stated license.*
