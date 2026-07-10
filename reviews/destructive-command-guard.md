# Destructive Command Guard (Dicklesworthstone/destructive_command_guard)

**Repo:** https://github.com/Dicklesworthstone/destructive_command_guard  
**License:** MIT-style text with OpenAI/Anthropic rider. Non-standard and non-OSI; restricted parties receive no rights. Treat as summarize-only unless the rider is acceptable to your use case.  
**Reviewed:** 2026-07-10  
**Stack:** Rust CLI, agent hook integrations, rule packs, JSON/SARIF output, GitHub Actions, shell/PowerShell installers  
**What it is:** A Rust command guard for AI coding agents that intercepts shell/git/tool commands before execution and blocks known destructive operations such as hard resets, recursive deletes, database drops, cloud deletes, Kubernetes deletions, and similar high-blast-radius actions.

---

## Verdict

⚠️ **Strong idea and serious engineering, blocked by license caveat for some adopters.** The tool addresses a real agent-safety problem with a broad rule-pack system, agent-specific hook behavior, scan mode, heredoc/inline-script detection, rich denial output, and a substantial test/CI surface. The actual license is not plain MIT despite README/Cargo metadata implying MIT; it adds an OpenAI/Anthropic rider that makes reuse legally and operationally awkward for many agent stacks.

---

## What It Is

`dcg` is a pre-execution safety hook for AI coding agents. It is designed to sit between an agent and shell execution, inspect the requested command, and deny commands that are likely to destroy local work, infrastructure, cloud resources, databases, secrets, or production systems.

The no-config default focuses on catastrophic local operations: dangerous filesystem deletion, destructive Git commands, and disk-destruction commands. Broader packs can be enabled for Docker, Kubernetes, Terraform, cloud providers, databases, CI/CD systems, DNS, payment systems, secrets managers, Windows commands, and more.

The project targets multiple agent hosts: Claude Code, Codex CLI, Gemini CLI, GitHub Copilot CLI, Cursor, Hermes Agent, Grok, Antigravity, OpenCode through a plugin, Pi through a recipe, and limited support for Aider/Continue. It also supports scan/pre-commit/CI-style detection rather than only live hook denial.

## Stack

| Layer | Tech |
|-------|------|
| Core | Rust 2024 CLI binary `dcg` |
| Matching | Regex/fancy-regex, Aho-Corasick, AST-grep/tree-sitter for inline/heredoc scripts |
| Config | TOML/YAML/JSON schema |
| Output | Console denial panels, JSON hook output, SARIF/scan results |
| Integrations | Agent hook installers, GitHub Action, pre-commit/scan workflows |
| Storage/history | Local history/session/pending exception components |
| Testing | Large Rust test suite, regression corpus, fuzz targets, benchmarks, E2E scripts |
| Distribution | Shell and PowerShell installers, GitHub release automation |

## Key Features

### Rule Packs by Blast Radius

The rule surface is organized into packs: core filesystem/git, system disk, containers, databases, Kubernetes, cloud providers, infrastructure tools, DNS, CI/CD, secrets, platform CLIs, payment providers, Windows operations, and more. This lets users keep defaults narrow while enabling environment-specific risk coverage.

### Agent-Aware Hook Protocols

The README documents different behavior for different host agents. Codex, for example, needs a strict denial path using exit code 2 and stderr rather than generic JSON output. That kind of host-specific protocol handling matters for guards that need to stop execution reliably.

### Heredoc and Inline Script Scanning

The tool is not limited to obvious shell strings. It advertises scanning for destructive commands inside inline scripts and heredocs, including Python/Ruby/Node-style destructive operations.

### Scan Mode and CI Use

In addition to runtime hooks, the repo includes scan/pre-commit/CI guidance. That is useful because destructive commands often enter repos as scripts, workflows, Makefiles, Dockerfiles, or documentation before an agent ever executes them.

### Escape Hatches

The guard provides bypass and allow mechanisms: environment bypass, allow-once codes, permanent allowlist entries, and hook removal. That is necessary for an operational safety tool; a guard that cannot be overridden will eventually get uninstalled.

## Architecture

At a high level, the architecture is:

```text
agent or CI source
  -> hook/scan input
  -> command normalization/context classification
  -> default and enabled rule packs
  -> allowlist / temporary exception logic
  -> denial or allow output in host-specific format
```

The file tree indicates a mature implementation: core evaluator modules, hook and agent protocol modules, command normalization, heredoc parsing, history/session tracking, SARIF/scan output, MCP support, many generated/handwritten packs, fuzz targets, benchmarks, E2E harnesses, and installer tests.

The main architectural tradeoff is inherent to this category: pattern guards must be conservative enough to catch destructive variants, but not so broad that they block documentation, examples, or harmless command text. The repo appears to take this seriously with false-positive/false-negative issue templates, regression corpora, context classification, and explain mode.

## Comparison

| Aspect | Destructive Command Guard | Shell Allowlist | Human Approval Prompt | Static Secret/Security Scanner |
|--------|---------------------------|-----------------|-----------------------|--------------------------------|
| Timing | Pre-execution and scan mode | Pre-execution | Before/at execution | Usually pre-commit/CI |
| Strength | Broad destructive-command knowledge | Simple and strict | Human judgment | Finds different risk classes |
| Weakness | Pattern false positives/negatives, license caveat | Hard to maintain | Alert fatigue | May not stop live agent commands |
| Best fit | Agent shell/git safety layer | High-control sandboxes | Rare high-risk actions | Repo hygiene and CI |

This is closer to a specialized command firewall than a general sandbox. It should complement, not replace, backups, version control, least-privilege credentials, container isolation, and human approval for external side effects.

## Self-Hosting Notes

The README recommends installer pipes such as:

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh?$(date +%s)" | bash -s -- --easy-mode
```

For safety-conscious use, prefer pinning a release, verifying checksums/signatures, and reading the installer before running it. Windows users get a PowerShell installer with checksum verification and optional Sigstore/cosign checks when available.

Validation note: local build/tests were not run during this review because the license rider explicitly restricts OpenAI/Anthropic-related use, analysis, benchmarking, and execution. This review is therefore a static summary based on public repo metadata, README/license/package metadata, and file structure.

---

**Attribution:** Dicklesworthstone/destructive_command_guard, MIT-style license with OpenAI/Anthropic rider, https://github.com/Dicklesworthstone/destructive_command_guard
