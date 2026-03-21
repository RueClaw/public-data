# Mole — Repo Review

**Repo:** https://github.com/tw93/Mole  
**License:** MIT  
**Author:** tw93 (Tw93)  
**Language:** Go + Bash shell scripts (~6.7K lines Go, substantial shell)  
**Cloned:** ~/src/Mole  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

A **macOS system cleaner, uninstaller, disk analyzer, and live monitor** — all in a single binary, installable via Homebrew. Described as "CleanMyMac + AppCleaner + DaisyDisk + iStat Menus combined into a single binary."

```bash
mo clean          # Deep cleanup: caches, logs, browser leftovers
mo uninstall      # App removal + launch agents + preferences + hidden remnants
mo optimize       # Rebuild caches, refresh system services
mo analyze        # Visual disk explorer
mo status         # Live CPU/GPU/memory/disk/network dashboard
mo purge          # Project build artifact cleanup (node_modules, .build, etc.)
mo installer      # Find and remove installer files
```

Interactive TUI with arrow keys and vim bindings (h/j/k/l). Written in Go (main binary) with shell scripts handling the actual file operations in `lib/`.

---

## Architecture

```
mole (Go binary)          ← CLI, TUI, orchestration
  cmd/analyze/            ← disk explorer
  cmd/status/             ← live system stats
  lib/clean/              ← cleaning logic (shell scripts)
    app_caches.sh
    apps.sh
    brew.sh
    caches.sh
    dev.sh
    project.sh
    system.sh
    user.sh
  lib/core/               ← safety infrastructure
    file_ops.sh           ← validate_path_for_deletion() — all deletions go through here
    app_protection.sh
    commands.sh
    sudo.sh
    timeout.sh
    ui.sh
  lib/manage/             ← whitelist management
  lib/optimize/           ← cache rebuild, service refresh
  lib/uninstall/          ← app uninstall
  lib/check/              ← system checks
```

Go handles the TUI and orchestration; shell handles the actual system operations. This is a sensible split — shell is better at macOS system calls, Go is better at interactive UIs.

---

## Safety Model

Mole has a security audit on file (`SECURITY_AUDIT.md`, v1.23.2, Jan 2026). Worth noting:

**All deletions go through `lib/core/file_ops.sh`'s `validate_path_for_deletion()`:**
- Rejects empty paths
- Rejects paths with `/../`
- Rejects paths with control characters (null bytes, newlines)
- Hard-blocked paths (even with sudo): `/`, `/System`, `/bin`, `/sbin`, `/usr`, `/etc`, `/var`, `/Library/Extensions`, `/private`

**Recent security fixes (Jan 2026):**
- `stop_launch_services()` validates bundle IDs as reverse-DNS before using in find patterns (stops glob injection)
- `find_app_files()` skips LaunchAgents named after common system words (Music, Notes, etc.)
- Orphaned helper cleanup uses `safe_sudo_remove`
- Bundle ID format checked before ByHost pref cleanup

**`--dry-run` mode** previews all operations with risk levels before executing. Combined with `--debug`, shows per-file details. Operations logged to `~/.config/mole/operations.log`.

---

## What's Good

### Single Binary for Common Mac Maintenance Tasks
This replaces a stack of paid tools ($40-80/yr each: CleanMyMac, AppCleaner, DaisyDisk). For a Mac that accumulates developer artifacts, this is legitimately useful. The `mo purge` command specifically targets dev build artifacts (node_modules, .build, Pods, etc.) — a common pain point.

### Whitelist System
`mo clean --whitelist` and `mo optimize --whitelist` let you protect specific caches from deletion. Prevents the annoyance of cleaning breaking something you care about (e.g., Xcode simulator caches, local model weights in /tmp-adjacent locations).

### Live System Monitor (`mo status`)
Real-time CPU/GPU/memory/disk/network dashboard. Useful when diagnosing if something is hammering disk or memory. Lightweight alternative to iStat Menus or Activity Monitor.

### The `purge` Command
Developer-specific: recursively finds and removes build artifacts across configured scan directories. `mo purge --paths` lets you configure which directories to scan. Actually solves the "my src/ has 200GB of node_modules" problem.

### Security Discipline
For a system cleaner, the security audit is unusually rigorous. Path validation, glob injection prevention, bundle ID validation before using in shell patterns — these are real attack surface concerns for a tool that runs as sudo.

---

## What's Not Great

### iTerm2 Incompatibility
The README explicitly warns against iTerm2 and recommends Alacritty, kitty, WezTerm, Ghostty, or Warp. This is a meaningful limitation — iTerm2 is the dominant macOS terminal. Likely a TUI rendering issue.

### Shell Script Core
The actual cleaning logic is in bash scripts, not Go. This makes it harder to audit, less testable, and more fragile than if it were pure Go. The security model is "trust validate_path_for_deletion() is called everywhere" — which is a discipline problem, not an enforcement problem.

### "Be Careful" Warning
The README itself says: "Although safe by design, file deletion is permanent. Please review operations carefully." The dry-run mode exists for a reason — this tool can actually delete things you didn't intend. Run `mo clean --dry-run` first, always.

---

## Relevance

Directly useful for Rue's machine (this Mac, 3.3TB drive). The `mo purge` command alone would be worth running given how many active `~/src` projects accumulate build artifacts. `mo clean --dry-run` to see what it finds first.

MIT license, `brew install mole`, works today.

---

## Verdict

A well-executed, MIT-licensed Swiss army knife for macOS maintenance. The security audit shows unusual care for a dev-focused CLI tool. The iTerm2 incompatibility is annoying (I run in Kitty, so fine), and the bash core is harder to trust than pure Go would be — but the `validate_path_for_deletion()` chokepoint is the right design. The dry-run mode makes it safe to explore.

Worth installing. Run `mo clean --dry-run` first before letting it do anything.

---

*Source: https://github.com/tw93/Mole | License: MIT | Author: tw93 | Reviewed: 2026-03-21*
