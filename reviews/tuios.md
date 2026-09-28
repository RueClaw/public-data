# TUIOS (Gaurav-Gosain/tuios)

**Repo:** https://github.com/Gaurav-Gosain/tuios  
**License:** MIT (© 2025 Gaurav Gosain). Free reuse with attribution. Third-party portions: Charm stack (MIT), optional libghostty-vt backend (MIT, behind `-tags ghostty`), pinned Unicode UCD data files under `internal/vt/testdata/unicode/` with their own provenance note.  
**Reviewed:** 2026-09-28 (commit `eb49a3e`, one day after v0.8.0)  
**Stack:** Go 1.26.6, Bubble Tea v2 / Lipgloss v2 / Ultraviolet, Wish v2 (SSH server), cobra, xpty/creack pty, optional libghostty-vt (Zig-built), sip (WebGL web serving), WebAssembly build for the docs site  
**What it is:** A tmux-style terminal multiplexer and tiling window manager that runs inside your existing terminal. A daemon keeps sessions alive, and v0.8.0 adds a layer that tracks the coding agents running in its panes: state, a cross-session Inbox for approvals and questions, agent-to-agent mail, worktree fan-out, remote hosts, and an MCP server.

---

## Verdict

⚠️ **Interesting. It's the most complete "multiplexer that knows about agents" we've seen, and the engineering discipline around it is real. But it's a very large, very fast-moving, single-maintainer codebase that has just broken its daemon protocol. Try it as a daily driver alongside tmux, not as a replacement for infrastructure you depend on.**

What's good: the terminal core is serious work, not a Bubble Tea toy. There's a pure-Go VT emulator with a table-driven conformance corpus, grammar-based fuzzing (`vtgen`) that delta-debugs failures into readable repro scripts, a differential test against tmux, and a second emulator backend (libghostty-vt) that's differential-fuzzed against the first. The agent layer is thought through. Pane grants (`read`/`write`/`fan`/`respond`/`admin`), human-origin checks via `SO_PEERCRED`, risky-approval rules, an MCP server that's read-only and session-scoped by default, and a herdr-protocol adapter that's input-only and careful not to impersonate a real herdr. Network exposure is locked down: SSH mode refuses a non-loopback bind without authorized keys, and the web server refuses a non-loopback bind without TLS.

What gives pause: ~277k lines of non-test Go plus ~187k lines of tests, and ~2,400 commits between v0.7.0 (March) and v0.8.0 (September). That's one author at a pace that almost certainly involves heavy agent-assisted development. The surface area is huge: launcher, screensaver, confetti, spotlight, desktop-app icons, federation, web, and WASM. SECURITY.md says only the latest `main` gets fixes and "there is no stable release yet." Default pane permissions are `admin` unless you opt into strict mode. `tuios-web` has TLS but no client authentication of its own. Whatever can reach the port gets a shell.

---

## What It Is

- **Multiplexer core:** panes, 9 workspaces, BSP / master-stack / niri-style scrolling layouts, vim-modal window management (`Ctrl+B` prefix), copy mode over 10k-line scrollback, command palette, which-key popup, layout templates, tape scripting (record/replay DSL).
- **Daemon sessions:** detach/attach like tmux. Sessions are resurrected after a daemon restart or reboot (structure and working directories, not processes). Multiple clients can attach, and every client has full control.
- **Graphics:** kitty graphics passthrough with image-ID reuse (flicker-free `mpv --vo=kitty`, including shm), kitty animation frame patching, sixel passthrough (experimental), kitty keyboard protocol, mode 2026 synchronized output.
- **Agents (v0.8.0):** state per pane (working / waiting / done / errored) from 18 harness integrations (`tuios integration install`) plus process/screen detection for 23 agent CLIs. An Inbox across all sessions and hosts, one-key approvals for Claude Code, opencode, Kilo, and Qwen Code, `ask-human`, `send-agent-message`, `ask-agent`, `fan` (one prompt → N agents in N git worktrees), `start-agent` (TUI or headless over ACP / Codex app-server), and resume after daemon restart.
- **Machines:** named SSH hosts, Tailscale tailnet discovery, remote attach, hosted panes (process on another machine, pane here), global sessions spanning machines, per-host link policy.
- **Other front doors:** `tuios mcp` (MCP server), a tmux shim for tools that drive tmux (e.g. Claude Code agent teams), `tuios subscribe` event stream, a JSON verb control protocol, an SSH server, `tuios-web` (a separate binary, for isolation), and a WASM guided tour.
- **Agent skill:** `tuios --skill [topic]` prints a guide for agents running inside a pane. It's embedded in the binary, and tests resolve every command it shows against the real cobra tree.

## Stack

| Layer | Tech |
|-------|------|
| Language | Go 1.26.6 (~277k LOC non-test, ~187k LOC tests; 2,048 `.go` files) |
| TUI | Bubble Tea v2, Lipgloss v2, Ultraviolet, charmtone |
| VT emulation | Own pure-Go emulator (`internal/vt`); optional libghostty-vt via `-tags ghostty` |
| PTY | charmbracelet/x/xpty, creack/pty, ConPTY on Windows; single spawn path in `internal/ptyspawn` |
| Remote | Wish v2 SSH server, own federation link layer over ssh, Tailscale ipnstate |
| Web | `tuios-web` via sip (WebGL terminal), coder/websocket |
| Packaging | GoReleaser (Linux/macOS/Windows/FreeBSD/OpenBSD), Homebrew, AUR, Nix flake, Docker (ghcr) |
| CI | go-test, lint (golangci-lint), govulncheck, nightly fuzz, e2e-tui, ghostty-vt, learn-web (WASM), binary-size, docker |

## Key Features

### Terminal emulator testing that's actually adversarial
`internal/vt` has a conformance corpus: input bytes → expected screen on a small grid. A case with `unhandled=false` asserts the emulator *recognised* every sequence, which catches "silently ignored" bugs (the doc admits NEL and DECALN were missing under green tests). `knownBug` cases fail loudly if they start passing. `internal/fuzz/vtgen` generates input by grammar rather than by byte and reduces failures to named-sequence scripts saved as JSON repros, not raw bytes, so they survive generator changes. There's also a differential against tmux (`-tags differential`), where tmux's own divergences are listed and asserted.

### Agent Inbox and approvals
Harness hooks report state to the daemon socket. The Inbox aggregates approvals, questions, mail, errors, and finished turns across sessions and machines, and `Prefix+o` jumps to the oldest. With `[agents.approvals]`, permission prompts from supported harnesses can be answered from the Inbox without switching panes. `internal/risk` flags risky calls by shipped and configured rules. A pane with the `respond` grant may deny a risky call but not allow it unless configured, and replies typed by the human are marked verified via peer-credential checks on the socket.

### Fan-out across worktrees
`tuios fan` starts one prompt in several agents, with mixed harnesses allowed, each in its own git worktree. Selectors like `group:fan/retry needs:you` address a group. `internal/worktree` creates and removes worktrees "without losing uncommitted work", and `tuios worktree pull` brings remote-host work back.

### Compatibility shims
The tmux shim runs tmux-driving tools with their panes as tuios panes. The herdr adapter accepts herdr's pane-state JSON-RPC (so Crush reports state natively) on a tuios-owned socket. It only sets `HERDR_*` env in panes that want it and strips an outer herdr's env so agents can't report to the wrong multiplexer.

### Self-update that respects package managers
`tuios update` first works out where the binary came from (`internal/release/provenance.go`). If Homebrew, AUR, Nix, or `go install` owns it, it refuses and prints the right command rather than overwriting a managed file. Downloaded archives are checked against the release's `checksums.txt` (sha256). There are no signatures, so this protects against corruption, not a compromised release.

## Architecture

- **MVU on Bubble Tea v2:** `app.OS` (`internal/app/os.go`) is the model, `render.go` is the view, `update.go` handles updates. Input goes through `internal/input/handler.go` into modal handlers.
- **Event-driven rendering:** PTY reader goroutines signal over a buffered channel with no fixed-rate tick, so idle sessions schedule no renders. There's a style LRU cache, object pools, and viewport culling. Perf budgets are enforced as benchmarks (`docs/perf.md` keeps a "measured and not changed" ledger, which is a good habit).
- **Daemon (`internal/session`):** owns PTYs and emulators, with a binary wire protocol plus JSON verbs. Clients are viewers that receive snapshots and streams (`docs/REHYDRATION.md` defines the snapshot-vs-stream contract). Resurrection state is written atomically at 0600.
- **Federation (`internal/federation`):** daemon-to-daemon link over ssh, with reconnection, outbox, and per-host policy.
- **Separation choices:** `tuios-web` is a separate binary "for security isolation". The fuzzer UI (`cmd/tuios-fuzz`) stays out of the shipped binary. Browser-only code is behind `js` build tags.
- **Conventions enforced by code:** `internal/lint` rejects literal colours in render code, tests check that the embedded skill's commands exist, and a test checks docs links.

## Security

- **Local daemon:** Unix socket chmod `0700` in a per-user runtime dir. PID/lock/state files are `0600`. Peer credentials (`SO_PEERCRED` / `LOCAL_PEERPID`) are used to tell human-typed input from agent input.
- **SSH mode:** defaults to `localhost`. It uses public-key auth from `$XDG_CONFIG_HOME/tuios/authorized_keys` then `~/.ssh/authorized_keys`, and refuses to start on a non-loopback host with no keys. An explicitly named but missing or empty keys file is a hard error, not a silent fall-through to no-auth (`internal/server/auth.go`, tested in `ssh_auth_test.go` / `ssh_loopback_test.go`).
- **Web mode:** defaults to `localhost`. A non-loopback bind requires `--cert/--key`, `--auto-tls` (self-signed), or an explicit `--insecure`. **There is no built-in client authentication.** Docs say web clients are gated "by whatever stands in front of `tuios-web`". Anyone who reaches the port gets full control of the session. Put it behind an authenticating proxy or VPN, or use `--read-only`.
- **Multi-client:** there are no per-client permission tiers. Every attached client can type and manage windows.
- **Agent permissions:** pane grants exist, but the default is effectively `admin` unless `[agents.permissions] mode = "strict"` is set. For fleets of untrusted agents, turn strict on and give `--grants` explicitly. The MCP server is read-only and scoped to the caller's session unless `--scope all` is passed.
- **Shell execution:** hooks (`internal/hooks/hooks.go`) and dock components (`internal/app/dock_runtime.go`) run `sh -c` on strings from the user's own config. That's expected for a hook system, but a config file becomes code.
- **Secrets scan:** the only `sk-`/`AKIA`/`ghp_`-shaped match is a fixture in `internal/agentproto/render_test.go`. No real credentials were found.
- **CI:** every one of the 13 workflows declares `permissions:`. Third-party actions (goreleaser, docker, setup-zig, issue-parser) are SHA-pinned. First-party `actions/*`, `golangci-lint-action`, and `govulncheck-action` use major tags. `govulncheck` runs in CI.
- **Install script:** `curl | bash` is offered, and it verifies `checksums.txt` since v0.8.0.
- **Policy:** SECURITY.md has private email disclosure, no response SLA, and fixes on `main` only.

## Maturity

- ~3,960★, 155 forks, 21 open issues. Created 2025-09-06, last push 2026-09-28 (multiple commits per hour on review day).
- Releases: v0.6.0 (Jan 2026), v0.7.0 (Mar 2026), v0.8.0 (2026-09-27, "about 2,400 commits since v0.7.0"; the daemon protocol changed, so a running v0.7 daemon must be stopped).
- Tests: 3,396 `Test*`/`Fuzz*` functions across the tree, including an E2E module (`e2e/tui`) that drives a real binary against real daemons. The contributor guide explicitly prefers E2E tests and keeps a negative-control record proving regression tests fail without their fix.
- Docs: extensive (`docs/`, tuios.dev, WASM tour, per-topic agent skill). The prose is careful and specific.
- Risk: single maintainer, extreme churn, and pre-1.0 with "no stable release yet" per SECURITY.md.

### Validation on 2026-09-28

Linux x86_64, 4 vCPU / 2 GB RAM, Go 1.26.6 (toolchain auto-downloaded):

```
go test -p 1 -count=1 ./internal/netutil/ ./internal/risk/ ./internal/tape/ ./internal/server/
  risk ok (0.03s) · tape ok (0.02s) · server ok (15.3s) · netutil: no test files
go test -p 1 -short -count=1 ./internal/vt/ ./internal/harness/ ./internal/config/ ./internal/layout/
  vt ok (3.5s) · harness ok (0.09s) · config ok (3.8s) · layout ok (0.5s)
go build -p 1 -o tuios-bin ./cmd/tuios          → 35 MB binary, "tuios version dev [pure-Go backend]"
tuios --skill                                  → prints embedded agent guide
tuios new smoke --detach; tuios ls; tuios kill-server
  → daemon auto-started, session listed (1 window, detached), clean stop with state saved
tuios run -s smoke2 -- 'echo ...'
  → refused with a precise error: the pane shell had no OSC 133 prompt marks, suggests wait-for instead
```

All 7 test packages that were run passed, and the binary builds and runs its daemon lifecycle headless. Not run: the full `go test ./...`, the E2E suite (`TUIOS_E2E=1`, 40-minute budget), `-race`, the ghostty backend, the web client Playwright tests, and anything interactive (no TTY here). No performance claims were reproduced.

## Comparison

| | TUIOS | tmux | Zellij |
|---|---|---|---|
| Language | Go | C | Rust |
| Daemon / detach | Yes | Yes | Yes |
| Tiling modes | BSP, master-stack, scrolling, floating | Manual splits, presets | Layouts, floating, stacked |
| Agent state / Inbox | Built in (18 harness integrations, 23 detected CLIs) | No (scripts only) | No built-in |
| Graphics | Kitty graphics with ID reuse and animation; sixel experimental | Sixel (3.4+); kitty via `allow-passthrough` | Sixel |
| Remote machines | SSH hosts, hosted panes, global sessions | ssh + nested tmux | ssh |
| Web access | `tuios-web` (TLS, no built-in auth) | No | Built-in web client |
| Maturity | Pre-1.0, very fast churn | Decades | 0.x, large community |

TUIOS also accepts the pane-state protocol of herdr, another multiplexer aimed at coding agents, so harnesses that already report to herdr (e.g. Crush) work unchanged.

## Self-Hosting Notes

- Install via Homebrew/AUR/Nix or a release archive; `tuios --standalone` skips the daemon for a single run.
- Wire agents with `tuios integration install <harness>` (or `--all`), then `tuios doctor agents`.
- For multi-agent use, set `[agents.permissions] mode = "strict"` and grant explicitly. Leave `[agents.approvals]` off until you trust the risk rules.
- `tuios run` needs OSC 133 shell integration. Without it, use `send-text` plus `wait-for window-output`.
- Don't expose `tuios-web` beyond loopback without an authenticating reverse proxy or a VPN in front of it. TLS alone is not access control.
- Upgrading across minor versions may need `tuios kill-server` (the protocol changed in v0.8.0).
- Building from source on small machines works with `-p 1` (a 2 GB host was fine for the pure-Go build).

## Reusable Patterns

- **"Unhandled" assertion in conformance tests:** assert that the parser *recognised* every sequence, not just that the screen matched. Silently ignored input is otherwise indistinguishable from correct no-op handling.
- **Grammar-level fuzzing with symbolic repros:** save reduced failures as named-operation scripts rather than bytes, so the corpus survives changes to the generator.
- **Self-invalidating known-bug lists:** `knownBug` cases and `tmuxDiffers` entries fail the suite when they start passing, so stale exceptions can't accumulate.
- **Provenance-aware self-update:** detect the package manager that owns the binary and refuse to overwrite it.
- **Refuse-by-default network binds:** one shared `IsLoopbackHost` predicate gates both the SSH server (needs keys) and the web server (needs TLS), so the two can't disagree about what "on the network" means.
- **Embedded agent skill tested against the CLI tree:** the docs agents read can't drift from the commands that exist.

---

**Attribution:** Gaurav-Gosain/tuios, MIT License
