# BAMA (daveebbelaar/bama)

**Repo:** https://github.com/daveebbelaar/bama
**Author:** Dave Ebbelaar
**License:** MIT; retain copyright and permission notices in copies/substantial portions. Reference-app assets and Apple documentation have separate rights.
**Reviewed:** 2026-10-31 (UTC)
**Revision:** f0c2cdbf9e41d838c14d8b7596729581dd4833c0 — whole repository; implementation focus on scaffold, build/snapshot/self-test helpers and optional agent CLI/MCP templates.
**Verification:** Static review only. No source programs, installers, app builds, tests, model calls or computer-use sessions executed.
**Stack:** Markdown Agent Skills, zsh, Swift 6.2, SwiftUI/AppKit, SwiftData, Swift Package Manager; Python/Perl helper snippets.
**What it is:** A 21-skill native macOS app-building workflow and starter template, not an autonomous app factory or a shipped application.

## Verdict

⚠️ **Interesting — a strong Mac-specific development playbook, not a verified unattended builder.** The useful part is its concrete connection between stories, native UI conventions, seeded screenshots, logic tests and small commits. Adopt selectively on a disposable macOS project: build-result handling, test-store isolation and the optional local command bridge need hardening before trusting unattended work or sensitive data.

## What It Is

BAMA means **Build Any Mac App**. It guides an existing coding agent from research or reference-app screenshots through a brief and backlog into a SwiftUI application. The actual execution engine, model, browser/computer-use tools, approvals and credentials belong to the host agent. The repository supplies instructions, scripts, starter source and twelve example specifications, not twelve completed apps.

The router chooses a skill based on the project's stage. Durable planning lives in files such as STORIES.md, screenshot indexes, design rules and FIXLOG.md. The improvement loop targets one milestone, limits visual repair to three rounds per story, and records blocked work. These are useful procedural constraints, but no runtime enforces the story state machine or guarantees that an agent inspects the screenshots. See [skills/start/bama/SKILL.md](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/bama/SKILL.md) and [skills/ship/improve-loop/SKILL.md](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/ship/improve-loop/SKILL.md).

## Stack

| Layer | Implementation |
|---|---|
| Workflow/distribution | 21 SKILL.md files; Claude plugin/marketplace JSON; per-skill agent metadata |
| Application | SwiftUI and AppKit; main-actor default isolation; separate testable Kit target |
| Persistence | SwiftData local store, UserDefaults for selected settings |
| Build | SwiftPM plus zsh bundle assembly, icon tooling and codesign |
| Verification | Swift Testing, in-app self-test, light/dark window capture, layout JSON probes and regex grid lint |
| Optional automation | Same app binary as CLI and newline JSON-RPC MCP server; Unix socket into GUI model |

The scaffold's [skills/start/new-mac-app/template/Package.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/template/Package.swift) has no external Swift package dependencies. That does not mean the whole workflow is dependency-free: it requires Apple frameworks/toolchains, shell utilities and an independently installed agent. The README's generic installer uses an unpinned latest skills package; plugin version metadata is 1.0.0, not proof of a tested release.

## Key Features

### Evidence-aware UI work

The template enumerates sidebar pages and settings tabs, visits light/dark modes, exports window PNGs and layout probes, and uses representative seeded data. Snapshot capture retries and explicitly labels its lower-fidelity AppKit fallback when Screen Recording is unavailable. The build-and-verify guide correctly distinguishes screenshots from interaction tests and warns against treating a successful compile as proof of a usable UI. See [skills/ship/build-and-verify/SKILL.md](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/ship/build-and-verify/SKILL.md) and [skills/start/new-mac-app/template/Sources/__APP_NAME__/Snapshot.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/template/Sources/__APP_NAME__/Snapshot.swift).

The grid linter is a source-text heuristic, not a Swift parser or accessibility audit. Pixel comparison reports a thresholded difference and writes overlays; it is not a semantic acceptance test. There are no published controlled success-rate or quality measurements establishing the “any app” promise. Complex permissions, background services, migrations, distribution and product-specific behavior remain engineering work.

### A coherent native scaffold

The generator separates domain helpers into a Kit target, keeps UI on the main actor and supplies a small SwiftData model, sidebar, settings, theme tokens, icon source and test hooks. It preserves existing files while copying the template and merges missing ignore rules. However, it validates the app name but not the bundle identifier before interpolating it into sed replacements, scans the destination recursively for placeholders, and finishes with git add -A and a commit. Use an isolated new project, not a mixed working tree. See [skills/start/new-mac-app/scripts/new-app.sh](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/scripts/new-app.sh).

### One command registry, multiple interfaces

The optional agent-cli template derives CLI help, JSON schemas and MCP tools from AgentCommands. Requests are routed onto the GUI's main actor and mutate its live model rather than a second database implementation. Delete previews without yes, ambiguous ID prefixes are rejected, and errors have stable codes. This is a useful pattern; it is not a complete authorization layer. See [skills/code/agent-cli/template/Agent/AgentCore.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/code/agent-cli/template/Agent/AgentCore.swift) and [skills/code/agent-cli/template/Agent/AgentCommands.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/code/agent-cli/template/Agent/AgentCommands.swift).

## Architecture and Operational Findings

### 1. Build and install are coupled, with weak failure propagation

[skills/start/new-mac-app/template/build.sh](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/template/build.sh) pipes swift build through grep and ends the pipeline with “or true”. It then checks that a binary exists and whether a Sources Swift file is newer. That heuristic does not cover all build inputs: a failed package/configuration change can leave an old binary eligible for installation. Codesign failures are also suppressed before an “installed” message. These are static control-flow findings, not reproduced failures.

The script removes and reconstructs the installed app bundle, clears extended attributes, and selects an available Apple Development signing identity or ad-hoc signing. This is local developer convenience, not notarization, hardened-runtime review, atomic deployment or rollback. Preserve the previous app externally and require actual build/signature exit status before replacement.

### 2. “Test store” is an environment convention, not path isolation

Store.isOverridden checks only that APP_STORE is nonempty. Snapshot, seed and self-test code rely on that predicate while their messages say the store must be in a temporary directory. An override pointing at a real database is accepted. Seed logic can write to an empty overridden store; the self-test mutates whichever overridden store it opens. The supplied wrappers choose temporary paths, which is good, but direct callers are not confined to them. See [skills/start/new-mac-app/template/Sources/__APP_NAME__/App.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/template/Sources/__APP_NAME__/App.swift), [skills/start/new-mac-app/template/Sources/__APP_NAME__/SeedData.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/template/Sources/__APP_NAME__/SeedData.swift) and [skills/start/new-mac-app/template/Sources/__APP_NAME__/SelfTest.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/start/new-mac-app/template/Sources/__APP_NAME__/SelfTest.swift).

Snapshot/self-test wrappers remove fixed-name temporary artifacts and the app's saved window state. Parallel runs can collide; these are not fully side-effect-free tests. Prefer per-run directories, explicit disposable-store validation and separate test preferences/state.

### 3. Optional bridge trusts the local account

[skills/code/agent-cli/template/Agent/AgentSocket.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/code/agent-cli/template/Agent/AgentSocket.swift) uses a Unix-domain socket and chmod 0600 rather than a network listener. That is a materially narrower exposure than unauthenticated TCP. However, same-user processes can invoke its commands; there is no per-client token, approval receipt or separate read/write capability. A caller-provided yes is confirmation syntax, not proof of human consent, and MCP hints are descriptive.

The socket reader has receive timeouts but no total message-size limit, and the listener spawns a thread per accepted connection without an explicit cap. The router selects a known command but does not apply a common strict argument-schema validator; individual handlers do the checks. In items list, negative limit/offset integers reach prefix/dropFirst without a nonnegative guard, a Swift precondition-trap path that can terminate the GUI. No exploit was executed. Add bounds, shared validation, peer/client policy and resource caps before using this bridge with untrusted local callers. The optional add-agent-cli installer also chooses the first Sources directory rather than explicitly finding the app target, making selection fragile when both app and Kit directories exist.

### 4. Persistence and recovery remain starter-level

SwiftData stores app records locally; failure to open the store terminates with fatalError. The supplied model has defaults, but there is no versioned migration plan, backup/restore flow, crash-recovery test or transactional install rollback. Workflow recovery is file-backed backlog plus Git history, not leases, checkpoints or exactly-once effects. A story left doing after interruption requires agent/human reconciliation. “One story per commit” helps inspect code changes, but reverting code does not undo external app interactions or database migrations.

## Execution, Privacy and Credentials

- **Agent authority is inherited.** Skill text and allowed-tool declarations do not create an OS sandbox. Build scripts write outside the project, can replace an app, launch/quit it, sign using a local identity, and optional installers add user-level skill/CLI links. The linker uses ln -sfn on generic skill names; review collisions before installing.
- **Local app data does not imply local AI.** No BAMA-owned model service or credential store was found in the inspected implementation. Claude Code/Codex/other host tools handle model authentication and may send source, screenshots and outputs to their provider under their own settings. An optional MCP client receives real item titles/notes from the bridge. Audit the host's data policy, not just SwiftData storage.
- **Computer use is sensitive.** The clone skill asks for permission, suggests demo data, limits changes to explicit consent and tells agents to exclude reference PNGs from public Git. Nevertheless, its menu/popover fallback is a full-screen screencapture, potentially including unrelated windows. The build-verification skill separately forbids full-screen captures. Resolve that inconsistency by isolating the reference app and redacting captures before model use. Textual screen indexes can also retain private content even when PNGs are ignored.
- **Additional network/rights boundaries.** The HIG helper fetches Apple documentation and caches it locally. Research/browser tools fetch public sources through the host agent. No telemetry client was identified in the inspected app/bridge templates; this is not an audit of host-agent telemetry. MIT covers BAMA, not proprietary reference apps, trademarks or Apple documentation. The clone guide's personal-use reassurance is not a blanket legal permission.

Evidence: [scripts/link-skills.sh](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/scripts/link-skills.sh), [skills/plan/clone/SKILL.md](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/plan/clone/SKILL.md), [skills/design/mac-design/scripts/hig.sh](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/design/mac-design/scripts/hig.sh), [skills/code/agent-cli/template/Agent/AgentMCP.swift](https://github.com/daveebbelaar/bama/blob/f0c2cdbf9e41d838c14d8b7596729581dd4833c0/skills/code/agent-cli/template/Agent/AgentMCP.swift).

## Maturity, Tests and Verification

Public GitHub metadata retrieved on 2026-10-31 showed creation on October 24, last push October 29, 1,037 stars, 146 forks and one open issue; these are a time-sensitive popularity snapshot, not reliability evidence. The releases endpoint returned no releases. No GitHub Actions workflow was present at the reviewed revision.

The scaffold includes four parameterized title-cleaning cases, an in-app CRUD-oriented self-test and an optional CLI checker for help/schema/error behavior and MCP initialize/tool-list shape. Those are real testing assets, but neither a repository-wide regression suite nor proof that generated apps are correct. The CLI checker does not comprehensively exercise mutation, negative numeric input, permission boundaries or crash recovery.

[Open issue #7](https://github.com/daveebbelaar/bama/issues/7) reports scaffold placeholder substitution failures on certain macOS grep environments. The reviewed generator does use the reported grep pattern, but this review did not reproduce the report or establish its exact BSD/toybox diagnosis. Treat it as an unresolved compatibility report, not a confirmed universal macOS failure.

**Review verification:** anonymously acquired the public repository; inspected the exact source revision, manifest/skill count, license, generator, package/build scripts, app state/test/snapshot code, layout/image helpers, optional CLI/socket/MCP implementation and public GitHub metadata. All source execution was deliberately skipped: no macOS GUI/toolchain validation, installer run, unit/integration tests, permission prompts, runtime security probing or paid model call. Static findings should be confirmed with synthetic data on a supported Mac before adoption.

## Comparison

| Option | Choose it when | Tradeoff relative to BAMA |
|---|---|---|
| [SwiftUI Pro](https://github.com/twostraws/SwiftUI-Agent-Skill) / [SwiftUI Expert](https://github.com/AvdLee/SwiftUI-Agent-Skill) | You want focused SwiftUI coding guidance in an existing project | Less end-to-end scaffolding and screenshot/backlog choreography; BAMA itself recommends these companions |
| Xcode + Swift Testing/XCTest | You need conventional build, signing, debugging and UI-testing control | More explicit project/toolchain ownership; BAMA avoids the GUI but does not remove Xcode toolchain requirements |
| [Superpowers](https://github.com/obra/superpowers) ([public review](superpowers.md)) | You want general planning/testing/review discipline across stacks | Broader methodology; BAMA adds macOS-specific templates and capture mechanics |
| [REA](https://github.com/morluto/rea) ([public review](rea.md)) | You need deeper reverse-engineering evidence rather than a native UI rebuild workflow | Different purpose; BAMA credits REA but mainly observes screens and reconstructs behavior |

These are fit comparisons, not comparative benchmark results or fresh audits of the alternatives.

## Self-Hosting Notes

There is no BAMA server to self-host. The supported path is macOS 26+, Xcode 26+ with Swift 6.2, and a skill-capable agent. Native reference-app computer use additionally depends on the host's plan/tool availability and macOS Accessibility/Screen Recording permissions. Linux or Windows can inspect the source but cannot validate this AppKit/SwiftUI application workflow as supplied.

For an initial pilot: pin a reviewed revision, read the selected skills/scripts, use a fresh project and demo reference data, retain host-agent approval gates, make build/sign failures fatal, verify generated placeholders are gone, and run tests/captures against a uniquely created disposable store. Leave the optional CLI/MCP bridge out until needed; harden and test it before exposing sensitive application records. Distribution still needs deliberate signing, notarization and update/recovery design.

## Bottom Line

Use BAMA as a detailed scaffold and verification checklist for small native Mac utilities. Its strongest transferable ideas are seeded UI evidence, a testable domain target and one registry for machine-facing commands. Its current code and prompt-only orchestration do not justify the stronger implication that arbitrary apps can be rebuilt safely without supervision.

**Attribution:** Dave Ebbelaar / [daveebbelaar/bama](https://github.com/daveebbelaar/bama), MIT. Analysis is independent; no reference-app assets or upstream source code are redistributed here.
