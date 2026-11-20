# Umami Flavors (OldJobobo/umami)

**Repo:** https://github.com/OldJobobo/umami
**License:** MIT, copyright 2026 OldJobobo; preserve the notice when redistributing code. Omarchy, plugins, packages and themes retain their own terms.
**Reviewed:** 2026-11-20 (UTC)
**Revision:** `825b0a8c8a6b6d6743f6d5728a0563990b5c9418`, whole repository; source commit dated 2026-11-19.
**Verification:** Static implementation review plus 103 upstream unit tests passed in a network-isolated, secret-free Bubblewrap sandbox on Python 3.14. No installation, package build, desktop interaction or live upgrade was performed.
**Stack:** Python 3.11+ standard library, TOML, Bash, Git, GNU coreutils, pacman/ALPM, Omarchy's Lua Hyprland configuration and shell IPC.
**What it is:** An unofficial, prototype Omarchy customization compositor: reapply a recipe to a fresh copy of stock Omarchy rather than maintain a fork. This is **not umami-software/umami web analytics**, and has no analytics dashboard, event database or tracking script.

## Verdict

⚠️ **Interesting — a well-focused customization layer, not yet a dependable desktop recovery system.** The useful idea is separating maintained intent from generated desktop files, with readable per-change outcomes and consent-aware plugin ownership. The implementation is unusually inspectable, and its 103 tests pass, but its declarative/code boundary has a concrete generated-comment injection gap, tree activation is not a crash-safe transaction, and real release-to-release compatibility remains unproved. Use a disposable VM for evaluation; prefer ordinary user overrides for small personal tweaks.

## What It Is

Umami copies the installed Omarchy tree, applies TOML transforms, emits generated Lua, records a report, and redirects Omarchy to the composed copy. Its five example flavors cover quiet keyboard-first layout, Shibumi shell, macOS-style switching, a command palette, and employer-style defaults/locks. These are Omarchy-specific recipes, not complete machine images.

The README's claim that changes survive updates has a real mechanism: an ALPM PostTransaction hook recomposes on installs/upgrades of omarchy, omarchy-dev and their settings packages. It does not establish that every upstream change remains compatible. The design document explicitly marks YAML sketches, stacking and the CI package tier as unbuilt; the machine-rebuild/lockfile document is exploratory, not shipped functionality. [S1, S2, S7]

## Stack and Architecture

| Layer | Implementation and boundary |
|---|---|
| Entry point | Bash launcher resolves its own path and invokes Python with isolated import mode (-I). |
| Recipe | recipe.py parses TOML, classifies transforms, validates plugin pins and suite/package fields, resolves source paths within the recipe. |
| Composition | compose.py copies real files with GNU cp/reflinks, dispatches transforms, emits default/over-theme/locked Lua modules, applies built-in Omarchy compatibility patches. |
| Activation | system.py runs as root, stages the recipe, builds tree.new, renames trees, writes Omarchy/sudo configuration and coordinates user-session refresh. |
| User layer | user.py applies defaults once, locks at login, asks about new plugins/suites, pins clones and tracks ownership in JSON. |
| Inspection | plan supports file lists/diffs/JSON; status distinguishes this session from the next boot. |

There is no service backend, HTTP listener, database server, account system or AI provider integration. Local Unix ownership and sudo are the administrative boundary. GUI behavior is delegated to Omarchy and Hyprland, not implemented as a standalone cross-platform UI. [S2–S5]

## Key Features and Evidence

### Intent-oriented transforms, with qualified drift detection

An anchored patch requires exactly one match; a diff is checked before Git applies it, with ordered fallback diffs. Literal key chords can be replaced/removed; file/command replacement can record an upstream hash. Optional stale/failed changes do not block the rest; required stale/failed transforms fail composition. Hash mismatch is **drift, still applied**, including for required transforms. A successful exit alone is therefore not an acceptance test.

These are syntactic and structural checks, not semantic compatibility proofs. Binding discovery is regex-based and misses dynamically constructed chords. IPC comparison counts target/function names, not argument types or behavior. lua.set only warns if its leaf name is absent; real validation happens when Hyprland loads it. Built-in compatibility patches can be stale while the overall report remains ok, because overall status considers recipe transforms, not the built-in patch results. [S2, S6]

The public open issue #1 reports whole PR diffs failing because packaged Omarchy omits existing test/docs files touched by those diffs. This is consistent with the all-or-nothing Git apply path, but the reported real installation was not reproduced here. Review a runtime-only patch deliberately rather than assuming a GitHub PR diff is package-ready. [S8]

### Defaults and locks are different tools

Theme/bar defaults are recorded per flavor and changed entry; later personal choices normally survive. Locks reapply at login or load after user configuration. Missing theme/toggles anchors weaken precedence and produce warnings. Locks are desktop policy, **not a security boundary** or endpoint-management system: they do not remove the user's underlying OS authority or prevent alternate programs. [S1–S4]

### Plugin ownership is handled thoughtfully, but execution remains trusted

New plugins/suites normally require per-user consent; declines/removals and independently installed plugins are respected. Plugin fetch checks the URL through Omarchy, checks out an exact 40-character SHA, verifies HEAD and manifest ID, then calls Omarchy's validator. A changed pin updates a previously managed plugin without a fresh approval; --yes explicitly bypasses the initial prompt. An exact commit identifies bytes, not a signature or proof of marketplace review: no marketplace approval lookup is implemented here.

Packages are restricted to names present in configured pacman repositories; suites verify command package ownership on installation/update and run as the user. Signature enforcement ultimately depends on pacman's configured policy, not an independent Umami signature verifier. Package installation occurs before composition and is not rolled back if later composition fails. [S3–S5]

## Security, Execution and Privacy

**The declarative label needs hardening.** recipe.py accepts a nonempty transform ID and flavor name without excluding newlines. compose.py interpolates both directly into generated Lua line comments/header text. Thus newline-bearing metadata can introduce executable Lua even when code = true was not declared. This is a static data-flow finding, not a live exploit test; it undermines the promise that arbitrary declarative recipe input is data only. Reject control characters or safely render metadata before treating untrusted recipes as declarative. The admin still explicitly installs the recipe, and this observation does not establish unauthenticated remote access. [S2, S5]

Code-tier recipes intentionally have package-like authority: they can replace executable Omarchy commands, and the composed bin directory is placed in sudo secure_path. code = true is a declaration, **not** a sandbox or signature check. Local recipe selection can shadow bundled names, and recipe staging dereferences symlinks while copying the entire directory; do not place secrets or unrelated files beside a recipe. The source/tree path checks are valuable for ordinary transforms but should not be treated as universal confinement: first-party plugin-add constructs its destination from a manifest ID without the ordinary inside() check. Such transforms already require trusted code-tier input. [S2, S3, S5]

Third-party user plugins execute arbitrary unsandboxed code in a long-lived shell; plugin.hypr additionally loads plugin Lua in Hyprland. Limited shell host capabilities are not filesystem/process isolation. The generated plugin.hypr loader checks file presence, not a fresh consent record; an already-present user plugin can supply that file. Package suites likewise inherit user authority. Trust each plugin/package and its updates separately.

No dedicated telemetry uploader, credential store or paid API flow was found. Network activity comes from Git plugin clones and package operations, and whatever installed plugins/suites do. Git inherits the user environment/configuration; disabling terminal prompts does not disable configured credential helpers or SSH identities. Reports, recipe copies and Git metadata are plaintext, with no dedicated encryption/redaction layer. Treat recipe contents and embedded URLs as potentially retained or shared through diagnostics. No cloud fee is intrinsic; costs are disk copies, network downloads and maintenance time. [S3, S4]

## Persistence, Recovery, Export and Removal

- **System state:** /etc/umami retains the active recipe directory; /var/lib/umami/tree holds generated files and a .flavor recipe/report; report.json holds the latest composition. The synthetic .git has no upstream and is a compatibility shim, not versioned rollback history.
- **User state:** XDG state holds umami/plugins.json and defaults.json; plugins live in the Omarchy user plugin directory; cache staging uses the XDG cache directory. JSON ownership/decline records matter to future behavior. No retention expiry or comprehensive export/delete command is provided.
- **Activation is not fully atomic:** recompose renames tree to tree.old, then tree.new to tree, then deletes old. There is a gap with no active tree path, no visible process lock/fsync/journal, and the next run deletes leftover old/new trees before rebuilding. A power loss or concurrent invocation is not equivalent to a tested rollback.
- **Fallback is narrower than the wording suggests:** a reported required-transform failure preserves the running tree and points next boot to stock; unexpected exceptions outside that report path are not a universal fallback handler. Hook mode returns zero for a handled failed composition, so automation must inspect reports. Disabling does not undo already-applied user settings, installed packages or plugin effects.
- **Config preservation:** point_at writes /etc/omarchy.conf wholesale and replaces/removes the shared omarchy-dev-path sudoers drop-in. visudo validation is good, but there is no merge or backup of pre-existing unrelated content in these files.
- **User recovery edge:** plugin state is saved before first enable succeeds. On the next sync, matching commit takes the already-ok branch rather than retrying enable; manual enable may be necessary. Plugin update deletes its old copy before post-update rescan verification. defaults.json is written directly; plugins.json uses rename but no visible lock/fsync.
- **Uninstall:** package hooks point back to stock and remove the Git safe-directory exception; tree/recipe remain until after reboot. Per-user state, plugins, packages and theme/bar changes are not comprehensively restored or deleted. The older shell uninstaller deletes the recipe immediately but also retains the active tree for reboot.

Back up the recipe **and assets**, original affected system config, personal Omarchy settings and per-user ownership state separately. Preserve required plugin/package artifacts if offline replay matters; a SHA without an available repository is not a backup. JSON reports and plan diffs are useful exports, not a complete restore format. Exact-input lockfiles and whole-machine recovery are expressly future ideas. [S2–S4, S7]

## Platform, Build, Updates and License

This targets Arch-based Omarchy with its current Lua Hyprland APIs, shell command suite, pacman hooks, runuser/systemd user environment and GNU cp. Python stdlib-only does not imply portability to ordinary Linux desktops, macOS or Windows. README reports author VM verification on Omarchy 4.5.0 stable and a stable-to-edge switch, explicitly **not a stable release bump**; these are author claims, not reproduced acceptance evidence.

The local package is version 0.1.0 and declares omarchy, python and git, without a compatibility version pin. packaging/build archives checkout HEAD, not uncommitted edits, then uses makepkg --nodeps. PKGBUILD marks the locally generated tarball checksum SKIP; that makes provenance depend on the trusted checkout/build process. No signing pipeline, release assets or repository-hosted CI workflow was found at this revision; the build script does not run the tests. Do not confuse the design's signed CI respin with a delivered update channel.

MIT permits reuse with notice preservation. The root license is present, but the package() function does not install LICENSE into the usual license directory; distributors should include it. Bundled example recipes refer to external themes/plugins/packages, not a blanket MIT license over those assets. No code/assets were extracted for this review. [S1, S5, S7, S9]

## Verification and Maturity

GitHub public metadata at retrieval showed a public non-fork repository created 2026-11-19, pushed 2026-11-19, 13 stars, 0 forks, one open issue and no releases. These are a dated activity snapshot, not quality evidence.

The 103 upstream unittest cases passed in 0.422 seconds in a secret-free, no-network sandbox: source read-only, synthetic writable home/tmp, no host home/config/device/session mounts. Tests use temporary source trees, local Git fixtures and fake Omarchy commands. Some subprocess ResourceWarnings were emitted; negative-fixture FAILED lines were expected test output, not suite failures. This verifies compositor and user-layer logic under fixtures, not actual pacman transactions, desktop accessibility/rendering, permissions on a live system, plugin safety, abrupt-power-loss recovery or cross-release upgrades. No extra packages, accounts, models or datasets were acquired.

## Comparison

| Option | Best fit | Tradeoff versus Umami |
|---|---|---|
| Stock Omarchy user overrides | A few settings or key bindings | Smaller privileged footprint; no general upstream-patch composition. |
| chezmoi or GNU Stow | Versioned personal dotfiles | Better ownership of personal files; does not automatically regenerate Omarchy's packaged runtime tree. |
| Maintained Omarchy fork/package patches | Deep code changes | Explicit diff/rebase ownership; more maintenance, but less temptation to equate a successful transform with semantic compatibility. |
| Nix/Home Manager or image-based systems | Broader declarative/reproducible environments | Larger ecosystem/workflow change; Umami is a smaller Omarchy-specific layer, not equivalent generation rollback or whole-system reconstruction. |

**Practical call:** study and VM-test the intent/composition split and consent-aware ownership model. Before using it on an important desktop, fix metadata code-generation handling, add crash/concurrency-safe activation and backups, verify uninstall/user-state recovery, and exercise actual supported stable upgrades. Ordinary overrides remain the simpler choice when they solve the problem.

## Source Evidence

All source links below are revision-pinned unless noted.

[S1]: https://github.com/OldJobobo/umami/blob/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/README.md
[S2]: https://github.com/OldJobobo/umami/blob/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/umami/compose.py
[S3]: https://github.com/OldJobobo/umami/blob/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/umami/system.py
[S4]: https://github.com/OldJobobo/umami/blob/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/umami/user.py
[S5]: https://github.com/OldJobobo/umami/tree/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/umami
[S6]: https://github.com/OldJobobo/umami/tree/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/tests
[S7]: https://github.com/OldJobobo/umami/tree/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/docs
[S8]: https://github.com/OldJobobo/umami/issues/1
[S9]: https://github.com/OldJobobo/umami/tree/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/packaging

- [README and stated validation][S1]
- [Composer, generated Lua and transform outcomes][S2]
- [System activation/config/recovery][S3]
- [Consent, plugin fetch and user persistence][S4]
- [Recipe validation, tier rules, Lua/IPC helpers and CLI][S5]
- [Tests][S6] · [Design and future scope][S7] · [Open compatibility report][S8] · [Packaging][S9]
- [License](https://github.com/OldJobobo/umami/blob/825b0a8c8a6b6d6743f6d5728a0563990b5c9418/LICENSE)
- [Public metadata](https://api.github.com/repos/OldJobobo/umami) · [Releases](https://github.com/OldJobobo/umami/releases), retrieved 2026-11-20 UTC.

**Attribution:** OldJobobo/umami, MIT. Independent review; no affiliation with the author or Omarchy.
