# xfetch (xfetch-cli/xfetch)

**Repo:** https://github.com/xfetch-cli/xfetch
**License:** MIT; reusable with attribution
**Reviewed:** 2026-08-23
**Stack:** Rust 2024, clap, sysinfo, crossterm, serde/jsonc, viuer, plugin/extension/effect API crates
**What it is:** Cross-platform system information fetcher for terminals, similar in category to neofetch/fastfetch but with JSONC configuration, layouts, themes, plugins, effects, and daemon/live modes.

---

## Verdict

⚠️ **Interesting terminal UX and probe-hardening reference, not a default replacement yet.** xfetch has an unusually active young codebase for a terminal fetch tool, with good attention to slow probes, platform separation, config expressiveness, and subprocess timeouts. It is still early: the repository is only 52 stars, CI is manual-only, plugin/effect installation builds arbitrary remote Rust crates, and `cargo clippy --all-targets -- -D warnings` currently fails on macOS because of cfg-related unused imports/dead code.

---

## What It Is

xfetch renders OS, kernel, CPU, GPU, memory, disk, package-manager, network, battery, uptime, terminal, user, datetime, and palette information in the terminal. It supports Linux, macOS, and Windows, and its recent changelog is heavily focused on probe correctness and performance: direct package database reads where possible, parallel system probes, bounded command execution, WSL handling, Windows parent-process shell detection, physical-network-interface preference, and battery filtering.

The project goes well beyond a static fetch clone. Users can configure module groups, labels, value templates, icons, colors, ASCII/image logos, row-level logo colors, layouts, intro effects, animated logo plugins, config-provider extensions, and a live daemon that pins a refreshing fetch panel at the top of the terminal.

The better idea here is not "use this everywhere"; it is the way the author is turning a small CLI into a composable terminal surface while hardening platform probes against slow or hostile subprocess behavior.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Rust 2024, clap |
| Terminal UI | crossterm, console, viuer |
| System probes | sysinfo plus per-platform command/db readers |
| Config | JSONC via `json_comments`, serde, deep merge |
| Plugins | External binaries using `xfetch-plugin-api` over JSON stdin/stdout |
| Extensions | Config-provider binaries using `xfetch-extension-api` |
| Effects | External effect binaries using `xfetch-effect-api` |
| Installers | Bash, PowerShell, prebuilt release installer |
| Tests | Rust unit tests; local clippy/fmt/test scripts |

## Key Features

### Probe Slimming and Parallelism

The strongest engineering work is in system probing. xfetch avoids `System::new_all()` when modules do not need it, initializes `System`, disks, and networks concurrently, caches slow values, probes public-IP hosts in parallel, and reads some Linux package databases directly instead of shelling out.

This matters because terminal fetch tools are latency-sensitive. A fetch command that hangs on `snap`, `winget`, PowerShell, or a network endpoint feels broken even when the rest of the program is fine.

### Subprocess Deadline Wrapper

The shared subprocess runner feeds optional stdin, drains stdout/stderr on bounded reader threads, and kills timed-out children. On Windows it also routes process-tree termination through `taskkill`.

That is a useful pattern for any CLI that calls optional system tools. xfetch treats external commands as unreliable dependencies, not as trusted library calls.

### Configured Presentation Layer

The JSONC config supports nested module groups, labels, value templates, layouts, themes, icon/color maps, custom ASCII/image logos, and daemon settings. Recent releases added per-module labels and formatting fields so users can reshape display values without changing probes.

### Plugin, Extension, and Effect Split

The project separates three extension types:

- info plugins add lines to the fetch output;
- config-provider extensions transform/overlay config;
- effects transform rendered lines into animation frames.

That boundary is cleaner than a single "plugin can do anything" interface.

### Live Daemon and Hot Reload

`daemon_live` pins the fetch block and refreshes a smaller module set on a platform-specific cadence. Hot reload watches the config and active theme, then reapplies modules, colors, layout, logo, and refresh cadence without restarting.

## Architecture

The source tree is straightforward:

- `src/info/` gathers data and formats module values.
- `src/info/platform/{linux,macos,windows}/` holds platform-specific probes.
- `src/ui/` prepares render trees and layouts.
- `src/plugins/`, `src/extensions/`, and `src/effects/` manage external binary discovery, installation, and execution.
- `src/subprocess.rs` centralizes bounded command execution.
- `src/config.rs` owns JSONC parsing, defaults, deep merge, and config-provider application.

The project's recent architecture direction is good: move platform conditionals down into OS-specific modules, keep the render path platform-agnostic, and make slow work conditional on requested modules.

## Comparison

| Aspect | xfetch | neofetch | fastfetch |
|--------|--------|----------|-----------|
| Language | Rust | Bash | C |
| Status | Young, active | Archived | Mature, active |
| Extension model | Plugins, config providers, effects | Shell config/scripts | Modules/config presets |
| Performance posture | Strong recent work, but young | Slow shell-heavy baseline | Very fast mature baseline |
| Best use | Study/pilot customized terminal surfaces | Legacy compatibility | Production-grade fetch replacement |

## Security and Operational Notes

The core has no obvious hardcoded secrets. It does fetch public IP only when the `public_ip` module is requested and has a documented `disable_ip_fetching` option.

The main caution is extension installation. `xfetch plugin install`, `xfetch extension install`, and `xfetch effects install` clone a repository and run `cargo build --release` on the selected crate. That is normal for developer tooling, but it should be treated as arbitrary code execution. Install only trusted plugin/effect repositories.

Release packaging includes prebuilt binaries with SHA256SUMS. The source installer still advertises `curl | bash`, which is convenient but should be pinned or replaced with the prebuilt checksum path in more cautious environments.

## Maturity

GitHub metadata at review time: 52 stars, 4 forks, 5 open issues, last pushed 2026-08-22. The changelog is unusually detailed, and the local `cargo test` run passed 132/132 tests on macOS.

The quality gap is CI posture: `.github/workflows/rust-tests.yml` is manual-only, and local `cargo clippy --all-targets -- -D warnings` failed on macOS with unused imports/dead code. That is fixable, but it contradicts several changelog claims of clippy-clean status unless those claims were Linux-only or have drifted since.

## Self-Hosting Notes

For cautious installation, prefer release assets plus checksum verification:

```bash
curl -fsSL https://raw.githubusercontent.com/xfetch-cli/xfetch/main/install-prebuilt.sh | bash
```

For source builds:

```bash
git clone https://github.com/xfetch-cli/xfetch.git
cd xfetch
cargo test
cargo build --release
```

Treat plugins, extensions, and effects as executable third-party code. Keep configs under version control if using heavy customization.

---

**Attribution:** xfetch-cli/xfetch, MIT License
