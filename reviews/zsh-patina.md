# zsh-patina (michel-kraemer/zsh-patina)

*Review #288 | Source: https://github.com/michel-kraemer/zsh-patina | License: MIT | Author: Michel Krämer | Reviewed: 2026-03-29 | Stars: 128*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A Zsh syntax highlighter — colors your command line as you type — implemented as a **Rust daemon with shared caching across sessions**. This is a direct replacement for `zsh-syntax-highlighting` and `fast-syntax-highlighting`.

The architecture is the interesting part: instead of running a new process per keypress (the typical approach), it spawns a single background daemon per user that all Zsh sessions share. The daemon pre-loads the syntax definitions and color theme into memory and keeps them there. Cache warm, subsequent highlights are sub-millisecond.

128 stars, created 2026-03-08 (3 weeks old). MIT. Rust + syntect (Sublime Text syntax definitions). Homebrew tap available for macOS.

---

## Performance

Benchmarks against zsh-syntax-highlighting (shell script, widely used) and fast-syntax-highlighting (shell script, the "fast" option):

| Metric | zsh-patina | zsh-syntax-highlighting | fast-syntax-highlighting |
|--------|-----------|------------------------|--------------------------|
| first_prompt_lag_ms | **17.680** | 23.389 | 26.164 |
| first_command_lag_ms | **26.090** | 31.771 | 28.601 |
| command_lag_ms | **0.197** | 0.528 | 0.240 |
| input_lag_ms | **1.394** | 8.385 | 3.643 |
| exit_time_ms | **17.725** | 19.934 | 24.095 |

Measured with [zsh-bench](https://github.com/romkatv/zsh-bench) on MacBook Pro 16" 2023.

**command_lag_ms** (the most important: delay per character typed) is **0.197ms** — vs 0.528ms for the reference implementation (2.7x faster) and 0.240ms for fast-syntax-highlighting. **input_lag_ms** is 6x faster than zsh-syntax-highlighting.

---

## Architecture: Shared Daemon

```
Zsh session 1 ──┐
Zsh session 2 ──┤──▶ zsh-patina daemon ──▶ syntect (Sublime Text syntax)
Zsh session 3 ──┘         ↑
                    (one process, shared cache:
                     syntax defs + theme loaded once)
```

Every Zsh session talks to the same daemon over a socket. The daemon loads syntax definitions and the theme once, keeps them in memory. When you open a second tab, no cold-start cost. When you type a command, the daemon highlights it from cache.

This is why the first_prompt_lag (17ms) looks surprisingly close to the per-keystroke lag (0.197ms) — the daemon was already running from a previous session.

Syntax engine: [syntect](https://github.com/trishume/syntect), Sublime Text `.sublime-syntax` grammar files. This means highlighting quality is comparable to what you get in VS Code/Sublime Text for the same languages — not a hand-rolled shell script trying to regex its way through POSIX syntax.

---

## Dynamic Highlighting

Beyond static syntax coloring, zsh-patina does two things at typing time:

1. **Command validation** — checks if the first token is a valid executable (exists in PATH or is a shell builtin). Invalid commands render in red. Valid commands render in the configured command color.

2. **Path detection** — underlines file/directory arguments that exist on disk.

Both can be disabled independently in config:
```toml
[highlighting]
dynamic = { callables = true, paths = false }  # or just `true`/`false`
```

---

## Theming

Built-in themes: `patina` (default), `catppuccin-frappe/latte/macchiato/mocha`, `classic`, `lavender`, `nord`, `simple`, `solarized`, `tokyonight`.

Custom themes are TOML files mapping Sublime Text scope names to colors/styles:
```toml
"comment" = "#a0a0a0"
"string" = "green"
"constant.character.escape" = "yellow"
"variable.other" = "yellow"
```

Because the scope names are the same Sublime Text grammar scopes, any Sublime Text color scheme can be directly translated. `zsh-patina list-themes` shows all built-ins with live highlighting examples.

---

## Installation

```bash
# macOS
brew tap michel-kraemer/zsh-patina
brew install zsh-patina
echo 'eval "$($(brew --prefix)/bin/zsh-patina activate)"' >> ~/.zshrc

# Rust
cargo install --locked zsh-patina
echo 'eval "$(~/.cargo/bin/zsh-patina activate)"' >> ~/.zshrc

# Zinit
zinit ice as"program" from"gh-r" pick"zsh-patina-*/zsh-patina" atload'eval "$(zsh-patina activate)"'
zinit light michel-kraemer/zsh-patina
```

Also: AUR package, Nix flake, pre-compiled binaries for macOS + Linux.

Config: `~/.config/zsh-patina/config.toml`. Changes take effect after `zsh-patina restart`.

Diagnostics: `zsh-patina check` runs a self-check and reports errors with hints.

---

## Caveats

- Must be loaded **last** in `.zshrc` — after all other plugins and `compinit`
- 128 stars, 3 weeks old — young project, unknown long-term maintenance trajectory
- The daemon model means one more background process. On a machine with 50+ tmux panes this might matter; on a normal workstation it doesn't.
- Dynamic path checking on every keypress could theoretically cause I/O if you're typing very fast on a slow filesystem (NFS etc.). The `max_line_length` and `timeout_ms` settings mitigate this.

---

## Verdict

🔥🔥🔥🔥 — Solid engineering. The shared-daemon architecture to avoid per-keypress cold-start is the right call, and syntect gives it Sublime Text-quality grammar parsing vs the shell-script regex approach of the alternatives. Benchmarks are real (measured with zsh-bench, not synthetic). The catppuccin/nord/tokyonight themes and custom TOML theming are quality-of-life wins over the competition.

The main risk is age — 3 weeks old, 128 stars. Worth watching. If it's still maintained in 3 months, strong candidate to replace fast-syntax-highlighting.

MIT. Cloned to `~/src/zsh-patina`.
