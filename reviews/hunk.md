# Hunk (modem-dev/hunk)

**Repo:** https://github.com/modem-dev/hunk  
**License:** MIT. Free to study, fork, and reuse with attribution.  
**Reviewed:** 2026-06-20  
**Stack:** TypeScript, Bun, React 19, OpenTUI, Pierre diffs, Commander, Zod  
**What it is:** Hunk is a terminal diff viewer built for reviewing agent-authored changesets. It combines a review stream, file navigation, inline agent notes, Git/Jujutsu/Sapling loaders, pager support, and a local session API that lets coding agents inspect and steer a live review window.

---

## Verdict

✅ **Deploy candidate for terminal-heavy agent review workflows.** Hunk is not just a prettier `git diff`; it is a review surface designed around how coding agents change code. The strongest parts are the normalized diff model, the multi-file review stream, the local session bridge, and the unusually serious test and packaging posture for a terminal UI project.

---

## What It Is

Hunk opens working-tree diffs, commits, stashes, raw patches, two-file comparisons, and Git pager input inside an interactive terminal UI. The core experience is a top-to-bottom review stream with a sidebar, split/stack layouts, syntax highlighting, mouse support, keyboard controls, theme selection, and support for untracked files in working-tree reviews.

The agent-specific angle is the differentiator. Hunk can register a live TUI session with a loopback daemon, then expose commands such as `hunk session review`, `navigate`, `reload`, and `comment add/apply`. That lets an external coding agent inspect the current review, move the visible UI to a file or hunk, and attach inline notes beside the relevant code.

It also exports `hunkdiff/opentui`, a set of reusable OpenTUI components for embedding Hunk's diff renderer in another terminal app. That turns the project into both an end-user CLI and a library for terminal-native review surfaces.

## Stack

| Layer | Tech |
|-------|------|
| CLI/runtime | TypeScript, Bun, Node 18+ |
| Terminal UI | OpenTUI, React 19 |
| Diff parsing/rendering | `@pierre/diffs`, `diff`, custom row planning and viewport logic |
| VCS loading | Git, Jujutsu, Sapling |
| Session control | Local HTTP/WebSocket daemon on loopback, JSON command API |
| Validation/config | Commander, Zod, TOML config |
| Packaging | npm package `hunkdiff`, Homebrew tap, Nix flake, prebuilt npm packages |
| Testing | Bun tests, PTY integration tests, TTY smoke tests, package smoke tests, benchmark gates |

## Key Features

### Review-First Diff UI

Hunk treats a changeset as one continuous review stream rather than a pile of independent file panes. The sidebar is navigation, not the primary review model. That is a better fit for agent-authored changes because the reviewer wants to audit intent, risk, and flow across the whole patch.

### Agent Session Control

The `hunk session` command family is the most interesting design choice. The live TUI registers with a local broker, and another process can ask for a compact JSON review model, navigate to a hunk, reload the displayed diff, or apply inline agent comments. This is the right direction for agent tooling: keep the human-facing UI live, but give agents a structured control surface instead of forcing them to scrape terminal output.

### Local-Only Broker With Real Guardrails

The daemon defaults to `127.0.0.1`, refuses non-loopback bind hosts unless an explicit unsafe environment flag is set, validates Host and Origin headers, limits request-body size, and bounds reload file reads to the initial repository root. The security model is still "trusted local machine," but the obvious DNS-rebinding and filesystem-escape failures are handled.

### Broad VCS And Packaging Support

Hunk supports Git, Jujutsu, and Sapling, plus raw patch and pager flows. The repo also validates npm packaging, prebuilt packages, Nix output, Homebrew release updates, Windows compatibility, terminal smoke tests, and benchmark snapshots. That maturity matters for a TUI, where environment drift is usually the hard part.

## Architecture

The architecture is cleanly layered:

1. CLI/config/runtime inputs are parsed into normalized command models.
2. loaders turn Git/Jujutsu/Sapling/file/patch inputs into one `Changeset` / `DiffFile` model.
3. UI state and layout logic render a single review stream with sidebar navigation.
4. the optional session bridge mirrors selection/comment/reload state through a local daemon.
5. reusable OpenTUI exports expose the diff renderer without the full app shell.

Two patterns stand out. First, the project keeps terminal rendering logic behind focused row-planning and viewport modules rather than putting everything in one giant app component. Second, the live-session bridge treats agent access as explicit commands over structured state, not as ambient terminal control.

## Comparison

| Aspect | Hunk | Difftastic | Delta | Lumen |
|--------|------|------------|-------|-------|
| Primary purpose | Interactive review stream | Structural diffing | Pretty pager | Interactive diff viewer |
| Agent annotations | First-class inline notes | No | No | No |
| Live agent control API | Yes | No | No | No |
| Structural diffs | No | Yes | No | No |
| VCS support | Git, jj, Sapling | Git-oriented | Git-oriented | Git-oriented |
| Embeddable TUI components | Yes | No | No | No |

Hunk does not replace Difftastic for semantic language-aware diffs. It is better understood as a review cockpit: less about computing the cleverest diff, more about making a multi-file changeset inspectable by humans and agents together.

## Self-Hosting Notes

Install paths are straightforward:

```bash
npm i -g hunkdiff
brew install modem-dev/tap/hunk
```

The runtime requires Node.js 18+ and works on macOS, Linux, and Windows. Development uses Bun 1.3+. For agent workflows, keep the session broker on loopback; remote exposure requires an explicit unsafe opt-in and should be treated as a local-trust boundary escape.

---

**Attribution:** modem-dev/hunk, MIT License
