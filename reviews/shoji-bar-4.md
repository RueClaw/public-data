# shoji-bar-4 (bea4dev/shoji-bar-4)

**Repo:** https://github.com/bea4dev/shoji-bar-4
**License:** Manifest declares MIT OR Apache-2.0; no license text files found in this revision. Confirm notices/terms before redistribution.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** bc42d4e049da15368c2efb997a5e4ba8a1bf4631; repository-wide static inspection, with emphasis on shell startup, IPC, settings, clipboard, notifications, lock/PAM and system actions.
**Verification:** Static source/document/manifest inspection only. No build, tests, preview, desktop interaction, service calls or performance measurements were run.
**Stack:** Rust 2024, AntiWebUI + anti-webui-md3e, Wayland, Linux-PAM, Linux desktop services.
**What it is:** A complete Material 3 Expressive desktop shell for ShojiWM—not merely a status bar and not a generic replacement panel for every compositor.

## Verdict

⚠️ **Interesting — cohesive desktop-shell design, not yet a default daily-driver recommendation.** Its strongest idea is one reactive UI and color system spanning bar, dock, panels and window frames. The extremely young public repository, security-sensitive in-process locker, limited tests and unverified performance/compatibility make an isolated ShojiWM evaluation more appropriate than replacing an established desktop or trusted locker.

## What It Is

The [README](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/README.md) and [feature guide](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/docs/features.md) describe floating bar islands, animated workspaces/window titles, an auto-hiding dock, launcher, quick settings, calendar, clipboard history, media controls, notification daemon, OSD, wallpaper and lock screen. These have corresponding Rust modules; this is substantive implementation, not a mock-up README. Visual quality and real-device behavior were not independently verified.

Its audience is ShojiWM users and developers exploring a native Rust animated desktop shell. Linux Wayland, layer-shell/session-lock support and the compositor's workspace/toplevel integration matter. There is no demonstrated X11, Windows or macOS support. Hyprland/Sway compatibility is not established by using Wayland: ShojiWM theme IPC, logout command and documented startup/keybinding integration are specific. Do not substitute it into another desktop on that assumption.

## Stack

| Layer | Technology and boundary |
|---|---|
| UI | Rust reactive signals/effects, AntiWebUI, MD3E components and springs |
| Windowing | AntiWebUI Wayland shell; per-output layers; ext-session-lock |
| System | NetworkManager, BlueZ, PipeWire, UPower, power-profiles-daemon, logind |
| Helpers | cliphist, wl-clipboard, zenity; application desktop entries; shoji_wm logout |
| Auth | Handwritten Linux-PAM FFI using login / pam_authenticate |
| Persistence | JSON settings and copied avatar in XDG state; decoded clipboard images in XDG runtime |

[Cargo.toml](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/Cargo.toml) has two AntiWebUI git dependencies on main plus serde_json. [Cargo.lock](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/Cargo.lock) pins the AntiWebUI family to f2fd04c2f16006c3e8aa95047a506d9cd3db3970. A short direct dependency list does not mean a small audited dependency surface; rendering, D-Bus/service adapters and protocol behavior are largely delegated. Those dependencies and ShojiWM were not audited here.

## Key Features and Architecture

[main.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/main.rs) separates msg and preview modes from normal Shell startup. Normal startup installs IPC, theme sharing, notification popups, OSD and lock hooks, then creates bar/dock/wallpaper/panels per output. Components are organized by desktop surface rather than backend/frontend services; there is no web server or hosted account required by this repository's documented model.

- **Coordinated motion and colors:** shared settings/theme signals drive Material color schemes and spring animations. [wm.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/wm.rs) sends JSON theme.set roles to ShojiWM, reconnecting with a 500 ms to 30 s backoff and resending the latest scheme. This is a useful integration pattern, not a portable theme API.
- **Practical controls:** [qs_pages.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/qs_pages.rs) includes Wi-Fi joining/password prompts and attempts to reconnect the previous network after failure. Bluetooth, audio and power controls are actual operations, not read-only status widgets. NetworkManager/polkit/system service policy ultimately determines permissions.
- **Integrated session UI:** [power_dialog.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/power_dialog.rs) confirms logout/restart/power-off. Logout invokes shoji_wm --quit. Application launching and desktop actions in the dock use AntiWebUI app adapters; trusted desktop entries/helper PATH are execution inputs.
- **Observability:** counted animation clocks, msg status and a CPU-report script offer useful diagnostics. They are not published benchmark results.

## Security, Privacy and Failure Boundaries

### IPC: local, but relies on the runtime directory

[ipc.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/ipc.rs) binds a Unix socket under XDG_RUNTIME_DIR, falling back to a predictable temporary-directory name if unset. There is no explicit peer-credential authorization or socket permission hardening in this file. A correctly private runtime directory is consequently important; the temporary fallback should not be treated as equivalent isolation.

A single listener thread performs an unbounded blocking read_line before dispatching. A client that connects and never sends a newline can monopolize the command listener; a huge line can grow memory. The two-second timeout covers the UI reply, not socket reads. This is a static local availability finding, not a tested exploit or remote network vulnerability. Commands include quit and theme changes but no unlock command. Arbitrary shell commands are not accepted by the IPC parser.

### Locker: correct protocol intent, important assurance gaps

[lock.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/lock.rs) uses ext-session-lock through AntiWebUI, closes panels, shares password state across outputs, authenticates off the UI thread and hooks logind lock/sleep events. The [documented recovery](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/docs/features.md) says ShojiWM remains locked if the shell dies and another locker such as swaylock can take over from a TTY. This is a compositor/dependency claim, not an independently verified recovery guarantee.

[pam.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/pam.rs) calls pam_authenticate for the login service, not account/session management. Its conversation supplies the same password to all hidden prompts, so arbitrary MFA/challenge flows are not established. The username comes from USER in [user.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/user.rs), not a UID-derived account lookup. Password buffers use String/CString and ordinary overwrite loops; that is not proof of compiler-resistant zeroization, and clearing UI strings does not guarantee all copies disappear. There is no visible sleep-inhibitor/locked-ack handshake in the shell's sleep callback; whether the dependency guarantees suspend ordering remains unverified. These are review questions before relying on it as a security boundary, not a demonstrated bypass.

The fixed preview password is restricted to the separate preview path; it is not evidence of a production backdoor. Crucially, [development docs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/docs/development.md) explicitly warn that preview clicks can change real network/Bluetooth/audio services and clipboard contents. Offscreen rendering is **not** a safe sandbox. No previews were run.

### Clipboard, notifications and credentials

[clipboard.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/clipboard.rs) lists cliphist entries, keeps previews in memory and decodes image contents to runtime-directory files. Despite thumbnail-oriented wording, decode writes the clipboard image data to disk for display. There is no shell-level secret exclusion/encryption policy. The app expects an external wl-paste --watch cliphist store recorder; removing the shell does not erase that history or stop a separately configured recorder.

Copy/delete use fixed sh scripts with the entry supplied as quoted positional argument $1, not interpolated command source—a meaningful distinction from shell injection. Deleting an image removes its local cached file, but external history changes do not imply automatic cache cleanup. XDG_RUNTIME_DIR fallback again weakens assumptions about private, session-lifetime storage.

[notify.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/notify.rs) tries to own the notification service and logs failure if another daemon owns it. It shows up to three popups and exposes notification history through the service adapter; persistence/retention limits inside AntiWebUI were not verified. Notification image hints accept local absolute/file paths and image bytes, putting sender-controlled content through image decoding. No HTML/JavaScript execution sink was established in the inspected UI. Do not run it alongside an existing daemon expecting both to receive the same notifications.

Wi-Fi passwords pass from UI signals to the network adapter; their final storage and authorization belong to NetworkManager/dependencies and were not audited. No direct telemetry uploader or remote API client was identified in the inspected shell code. That is not a guarantee of zero network traffic: helpers, launched applications, media artwork loading and dependencies have their own behavior.

## Performance: evidence versus claims

The README claims no frames when nothing moves and “0% CPU when idle.” [ui.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/ui.rs) does condition ticker continuation on live/running state, and exposes an active-clock count. This supports a deliberate event-driven design, not a measured universal zero-CPU claim: clocks, service events, animations, media and reconnection can still wake work.

There are no reviewed reproducible measurements for CPU, RSS, GPU, startup, multi-monitor scaling or long-running clipboard/history size. The [diagnostic script](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/scripts/cpu-report.sh) samples process/thread counters, perf and D-Bus profile traffic and writes local reports. Its optional sudo mode refreshes credentials and also uses sudo chown on perf output, so “only perf runs under sudo” in the docs is imprecise. Reports can expose local process/bus details; review before sharing. The script was not executed.

## Installation, Updates, Preservation and Recovery

Upstream instructs cloning under ~/.config/shoji-bar-4 and cargo build --release, with ShojiWM starting the binary. These are upstream paths, not actions performed by this review. Use a pinned revision and cargo build --release --locked for a future controlled evaluation; exact native build prerequisites and clean-machine success were not established. No release binaries, package-manager lifecycle or built-in updater were found in the reviewed repository.

Before any adoption, preserve existing compositor config, notification/clipboard startup entries, locker and working binary. Merge startup/keybindings rather than replacing a config. Keep a known-good separate session and TTY recovery route; validate lock/refusal/suspend/crash takeover before enabling automatic locking. No installation or configuration changes were made here.

[settings.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/settings.rs) reads XDG_STATE_HOME/shoji-bar-4/settings.json (HOME fallback, then /tmp), defaults malformed/missing values, debounces changes by 400 ms and writes a neighboring partial file before rename. This avoids partially replaced JSON, but errors are ignored, there is no fsync guarantee, no schema version/migration/backup and unknown keys are lost on a subsequent save. Manual edits are not shown being watched/reloaded live. Invalid files may silently become defaults and later be overwritten. Multiple display instances share this state location.

[user.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/user.rs) copies avatars and removes older avatar-* files; reset removes the configured avatar path without checking it is inside the managed directory. Hand-edited avatar settings should therefore not point at a valued original file. Preserve the state directory separately from source/build updates.

Rollback means restoring the prior executable/revision **and** compatible saved state/config, not merely pulling an old commit. Uninstall has no dedicated script: remove only this shell's startup/keybindings, restore the prior notification/lock components, and then remove its source/build artifacts if desired. State, reports, runtime clipboard images and the external cliphist database have separate lifetimes; erase only deliberately. Do not terminate a locked shell assuming that will safely unlock the session.

## Maturity, Tests and Licensing

The [public repository API](https://api.github.com/repos/bea4dev/shoji-bar-4) reported creation on 2026-11-10, last push 2026-11-10T12:48:23Z, 19 stars, 0 forks and 0 open issues at retrieval on 2026-11-10. [Releases](https://api.github.com/repos/bea4dev/shoji-bar-4/releases) and [tags](https://api.github.com/repos/bea4dev/shoji-bar-4/tags) were empty. Public repository age is not proof the code was written in one day, and popularity is not quality evidence.

The package is version 0.1.0. Two unit tests in [bar.rs](https://github.com/bea4dev/shoji-bar-4/blob/bc42d4e049da15368c2efb997a5e4ba8a1bf4631/src/bar.rs) cover small title-change detection; no CI workflow, dedicated integration suite or security/locker regression suite was found in this tree. Tests were **not run**. The shallow acquisition does not support claims about full historical coverage or maintenance trajectory.

Cargo.toml declares MIT OR Apache-2.0, but no LICENSE/NOTICE text was present and the GitHub API license field was null. Treat this as an explicit manifest declaration with incomplete bundled licensing material, not “no license declared” and not a completed licensing audit. Confirm applicable texts/notices and transitive/asset licenses before distributing a fork; no code or assets were extracted.

## Comparison

| Option | Better fit / tradeoff |
|---|---|
| shoji-bar-4 | Cohesive native Rust ShojiWM shell and shared animated theme; tightly coupled and operationally young |
| [Waybar](https://github.com/Alexays/Waybar) + separate launcher/notification daemon/locker | Modular Wayland bar setup; more assembly and less unified motion, but smaller replacement scope |
| [Quickshell](https://quickshell.org/) | Qt/QML toolkit for custom desktop shells; an alternative development foundation, not a turnkey equivalent of this exact UI |
| [swaylock](https://github.com/swaywm/swaylock) | Dedicated locker to evaluate separately where supported; not a replacement for bar/panels and takeover compatibility still needs testing |

These are role comparisons, not side-by-side performance or security certifications. Start with this project for studying coordinated shell UI or an isolated ShojiWM experiment; prefer a narrower bar change if the actual need is only status display. A deployment recommendation would need reproducible builds, service/monitor compatibility tests, hardened IPC/runtime handling, verified lock/suspend/recovery behavior, and clearer license packaging.

## Verification and Limitations

Public HTTPS source acquisition succeeded; canonical identity and exact SHA were confirmed. Existing public Markdown reviews/index content were searched without finding a prior matching source. Source-level findings above are reproducible by reading the cited pinned files. No source code, tests, scripts, binaries, previews or dependency build hooks were executed; no devices, credentials, private data or live desktop services were accessed. AntiWebUI and compositor internals, actual PAM policy, dependency vulnerabilities, performance and runtime security remain outside this static review.

---

**Attribution:** bea4dev/shoji-bar-4; manifest-declared MIT OR Apache-2.0 (license texts absent in reviewed tree).
