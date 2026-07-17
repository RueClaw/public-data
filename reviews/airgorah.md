# Airgorah (martin-olivier/airgorah)

**Repo:** https://github.com/martin-olivier/airgorah  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-07-17  
**Stack:** Rust 2024, GTK4, aircrack-ng suite, Linux wireless tools  
**What it is:** A Linux desktop GUI for authorized WiFi security auditing: scanning access points and clients, switching adapters into monitor mode, capturing WPA handshakes, running deauthentication attacks, and launching password-cracking flows through aircrack-ng.

---

## Verdict

⚠️ **Useful wrapper for authorized WiFi audits, but not a casual install.** Airgorah gives the aircrack-ng workflow a friendly GTK front end and has decent packaging/CI signals. The tradeoff is that it runs as root, shells out to privileged networking tools, can stop network-manager services, and has little automated test coverage visible in the repo.

---

## What It Is

Airgorah is a Rust/GTK4 desktop application for Linux wireless-security work. It does not replace aircrack-ng; it orchestrates `airmon-ng`, `airodump-ng`, `aireplay-ng`, `aircrack-ng`, `macchanger`, `mergecap`, and related tools behind a GUI.

The main workflow is familiar: pick a wireless interface, enter monitor mode, scan nearby access points and clients, capture traffic/handshakes, optionally launch deauthentication against selected targets, then run dictionary or bruteforce cracking in a terminal. The README is explicit that the intended use is testing networks the operator owns.

The project is mature enough to package releases for Debian, RPM, and Arch-style systems, and it has current Rust packaging metadata. It is still a sharp tool: it needs root privileges, monitor-mode-capable hardware, packet injection support, and a Linux environment where interfering wireless services can be stopped/restored.

## Stack

| Layer | Tech |
|-------|------|
| Application | Rust 2024 |
| UI | GTK4 / gtk-rs |
| Wireless tooling | aircrack-ng suite, mdk4, iw, ip, macchanger, mergecap |
| Packaging | Docker builder, fpm, deb/rpm/pacman artifacts |
| CI | GitHub Actions clippy, fmt, x86_64/aarch64 package builds |
| Config/state | `/etc/airgorah/config.toml`, temporary capture files in `/tmp` |

## Key Features

### GTK Front End For Aircrack-ng

The core value is operator ergonomics. Airgorah turns a multi-terminal aircrack-ng workflow into a desktop interface for interface selection, scan filtering, AP/client display, deauth controls, capture saving, and cracking launchers.

### Scan And Capture State Handling

The scan backend runs `airodump-ng` with CSV and capture output, parses AP/client rows into Rust structs, tracks hidden SSIDs, keeps observed clients attached to APs, and merges capture files through `mergecap` when scans stop.

### Monitor Mode And Service Management

The interface backend checks Linux wireless interfaces with `iw`, enables monitor mode through `airmon-ng`, can randomize or restore MAC addresses with `macchanger`, and optionally stops interfering services through `systemctl`. That is useful in a lab, but it is exactly why this should be run on a dedicated audit machine rather than a shared workstation.

### Packaging And Release Path

CI builds through a Docker image, runs clippy and rustfmt, and produces deb/rpm/pacman artifacts for x86_64 and aarch64. Releases exist up to `v0.7.4`, and the crate metadata declares MIT licensing.

## Architecture

The code is organized into a thin backend/frontend split:

- `src/backend/*` wraps system tools and maintains process/global state.
- `src/frontend/*` builds GTK interfaces and connects events to backend operations.
- `src/types.rs` defines AP/client/settings structures.
- `src/globals.rs` holds process handles, scan paths, caches, and mutex-protected application state.

This is pragmatic for a small desktop utility. The downside is that most state is global and process-oriented, which makes unit testing and failure recovery harder. For a root-run app that manipulates network services, more testable command construction and explicit state transitions would be worth the extra structure.

One implementation issue stands out: bruteforce cracking builds a shell string for `sh -c` so it can pipe `crunch` into `aircrack-ng`. The custom charset field is user-controlled. Even if the normal GUI path is local/operator-driven, root-run shell composition is a risk class that should be replaced with argv-based process piping or strict escaping.

## Comparison

| Aspect | Airgorah | Raw aircrack-ng | Kismet / Wireshark-style tools |
|--------|----------|-----------------|--------------------------------|
| Primary job | GUI-driven WiFi audit workflow | CLI toolkit for capture/attack/cracking | Monitoring, packet analysis, discovery |
| Operator experience | Easier for occasional operators | Flexible but terminal-heavy | Strong visibility, less focused on cracking workflow |
| Privilege model | Root desktop app | Usually root or capabilities per command | Varies by capture setup |
| Automation | Manual GUI actions | Scriptable CLI | Tool-specific pipelines |
| Best fit | Authorized lab audits with supported adapters | Repeatable expert workflows | Passive monitoring and packet analysis |

## Self-Hosting Notes

This is not a server. Treat it as a dedicated Linux audit-workstation app.

- Requires Linux, root privileges, GTK4 runtime libraries, xterm, aircrack-ng tools, and monitor-mode/packet-injection-capable hardware.
- The packaged dependency set includes `aircrack-ng`, `macchanger`, `iw`, `xterm`, `wireshark` CLI components, `mdk4`, and `crunch` depending on distro package.
- Do not run it on a production workstation or router appliance where stopping wireless/network-manager services would be disruptive.
- Local verification on macOS could not compile past missing GTK/pkg-config system libraries; the repo's CI is the meaningful build signal for Linux.

---

**Attribution:** martin-olivier/airgorah, MIT License
