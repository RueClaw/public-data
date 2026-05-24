# Claude-BugHunter (elementalsouls/Claude-BugHunter)

**Repo:** https://github.com/elementalsouls/Claude-BugHunter
**License:** MIT for the repository's original work, with vendored/upstream community material attributed separately as MIT.
**Reviewed:** 2026-05-24
**Stack:** Claude Code skills, Markdown slash commands, Python stdlib CLI, Bash installers, security methodology documentation
**What it is:** Claude-BugHunter is a Claude Code skill bundle for authorized bug bounty and external red-team workflows. It packages domain skills, slash commands, disclosed-report pattern libraries, validation gates, evidence hygiene, reporting templates, and a small deterministic CLI.

---

## Verdict

⚠️ **Interesting controlled-use toolkit.** Claude-BugHunter has strong structure for authorized security research: explicit scope boundaries, validation gates, reporting discipline, and evidence-redaction workflow. It is not a default-install recommendation because it is inherently dual-use, the installer mutates the user's Claude/shell environment, and the CLI can perform real network reconnaissance when used in recon mode.

---

## What It Is

Claude-BugHunter turns Claude Code into a specialized bug-hunting workspace by installing a bundle of security skills and slash commands. The repo claims 51 skills, 15 slash commands, and 574+ disclosed-report patterns across web application, API, identity, cloud, and external enterprise-surface testing. Local inspection confirmed 51 skill directories and 14 command files in this checkout; the documentation and credits both claim 15 slash commands, so one command appears absent from the shipped commands directory.

The bundle is scoped to authorized external attack-surface work: bug bounty programs, signed web application pentests, CTF/lab targets, and the operator's own infrastructure. Its documentation explicitly excludes internal Active Directory tradecraft, post-exploitation, persistence, C2, stealth/evasion, unauthorized scanning at scale, credential-stuffing, fraud, and activities outside written authorization.

The strongest part is not any individual technique. It is the workflow wrapper: scope checks, kill/downgrade/chain triage, evidence hygiene, report drafting, and explicit reminders not to over-claim findings without in-scope proof.

## Stack

| Layer | Tech |
|-------|------|
| Skill content | Claude Code skills/*/SKILL.md files |
| Commands | Markdown slash commands in commands/ |
| CLI | Python stdlib script in scripts/cbh.py |
| Install | Bash scripts that copy skills/commands into ~/.claude |
| Documentation | README, install/usage docs, architecture docs, credits, security policy |
| Pattern libraries | Markdown files under docs/disclosed-reports/ and validation docs |

## Key Features

### Scope-First Security Workflow

The security policy and README repeatedly frame the bundle around assets the operator owns or is authorized to assess. The triage flow includes explicit questions about scope, accepted impact, available attacker access, and whether a finding is already known or merely theoretical.

That framing matters because agentic security workflows can otherwise turn broad pattern libraries into overconfident or unsafe recommendations. Claude-BugHunter's answer is to make validation and scope checks part of the workflow rather than optional prose.

### Large Skill Bundle With Progressive Loading

The repo packages 51 skills covering methodology, web vulnerability classes, external identity/platform surfaces, evidence handling, and reporting. It also uses reference files and disclosed-report summaries so Claude can load domain-specific context when a topic appears, instead of requiring one huge prompt.

This is a useful pattern for any high-risk domain skill pack: split the corpus by decision point, keep the routing skill small, and load heavier references only when the task calls for them.

### Deterministic CLI Companion

scripts/cbh.py provides a secondary CLI with recon, classify, triage, and report subcommands. It is intentionally not the main interface; the docs position Claude Code slash commands as primary and the CLI as a deterministic runner for scripted use or CI-style checks.

Validation on this checkout:

- python3 -m compileall -q scripts docs/verification passed.
- Bash syntax checks passed for scripts/*.sh.
- python3 scripts/cbh.py --help worked.
- python3 scripts/cbh.py classify and triage worked on a harmless sample, with the triage gate correctly killing an unsupported candidate finding.

### Evidence Hygiene and Report Discipline

The bundle includes explicit guidance for redacting cookies, protecting other-user PII, preparing platform-specific reports, avoiding unsupported severity claims, and rotating test-account credentials after submission. This is the most reusable non-offensive portion of the repository.

## Architecture

The repository is organized as an installable Claude Code pack:

- skills/ contains domain skills and workflow skills.
- commands/ contains slash-command definitions.
- scripts/install.sh copies skills and commands to ~/.claude and appends a source ~/.claude/scripts/hunt.sh line to the detected shell rc file.
- scripts/install-community-skills.sh optionally clones upstream community material and runs its installer.
- scripts/cbh.py bridges selected workflows into a local terminal runner.
- docs/ contains architecture notes, disclosed-report pattern summaries, validation notes, and credits.

The install approach is simple and practical, but it deserves caution. It overwrites same-named local skills/commands after backing them up, writes into ~/.claude, and modifies shell startup files. Operators should inspect the bundle and install scripts before running them.

## Comparison

| Aspect | Claude-BugHunter | General security scanners | General Claude skill bundles |
|--------|------------------|---------------------------|------------------------------|
| Primary role | Human-guided security research workflow | Automated detection | Domain context and habits |
| Safety posture | Strong stated scope and evidence gates | Varies widely | Usually not security-specific |
| Operational risk | High if used outside authorization | Depends on scan type | Usually lower |
| Best use | Authorized bug bounty/pentest assistance | Repeatable scanning | Reusable agent behavior |
| Weak spot | Dual-use content and environment-mutating installer | False positives/coverage gaps | Shallow domain specificity |

## Self-Hosting Notes

This is not a service to deploy. It is a local Claude Code content bundle and optional CLI.

Before installation:

- Read SECURITY.md, INSTALL.md, and scripts/install.sh.
- Confirm that writing into ~/.claude/skills, ~/.claude/commands, and shell rc files is acceptable.
- Keep use to owned, lab, CTF, bug-bounty in-scope, or signed-engagement targets.
- Treat cbh recon as network-active behavior and apply the same written-scope discipline as any other reconnaissance tool.
- Review the vendored/upstream attribution notes because LICENSE says upstream skills are not redistributed directly, while docs/credits.md says vendored foundation skills and commands are included.

---

**Attribution:** elementalsouls/Claude-BugHunter, MIT license with upstream/community attribution notes.
