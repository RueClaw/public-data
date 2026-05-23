# Claude Ads (AgriciDaniel/claude-ads)

**Repo:** https://github.com/AgriciDaniel/claude-ads  
**License:** MIT; permissive reuse with attribution.  
**Reviewed:** 2026-05-23  
**Stack:** Agent Skills, Markdown, Python, pytest, Playwright, ReportLab, matplotlib, shell/PowerShell installers  
**What it is:** A multi-platform paid-advertising audit and creative-generation skill pack for Claude Code and other agent hosts. It packages audit playbooks, scoring logic, helper agents, report scripts, and an eval harness for Google, Meta, YouTube, LinkedIn, TikTok, Microsoft, Apple, Amazon, attribution, tracking, budget, landing pages, and creative work.

---

## Verdict

✅ **Deploy candidate for ad-audit workflows, with installer caveats.** The domain coverage is unusually deep for an agent skill: 22 sub-skills, 10 specialized agents, platform-specific references, SSRF-safe helper scripts, and a real pytest harness. The main problem is packaging polish: the public mirror's install scripts still clone the private AI-Marketing-Hub/claude-ads repo by default, and the Unix installer may fall back to pip --break-system-packages instead of creating an isolated environment.

---

## What It Is

Claude Ads turns a coding-agent skill system into a paid-media audit workbench. The main /ads skill collects business context, dispatches platform or function-specific sub-skills, and produces account health scores, prioritized findings, quick wins, campaign plans, creative briefs, image prompts, and PDF-ready reports.

The repo is not just a prompt file. It includes sub-skills for major ad platforms, functional workflows like attribution and server-side tracking, helper agents for audit and creative production, Python scripts for landing-page capture/report generation/image generation, and tests that pin routing, scoring math, check coverage, and SSRF protections.

The strongest use case is an agency or in-house marketer that can export account data, paste campaign metrics, or run browser/screenshot helpers locally. It is less useful as a fully automated ads API system today; the repo mostly provides agent procedures and local helpers, not a production SaaS backend.

## Stack

| Layer | Tech |
|-------|------|
| Skill runtime | Claude Code Agent Skills; experimental install paths for Codex CLI, Cursor, Windsurf, Gemini CLI, Goose |
| Skill content | Markdown SKILL.md files, reference checklists, industry templates |
| Agents | 6 audit agents and 4 creative agents as Markdown agent definitions |
| Scripts | Python 3, requests, Playwright, Pillow, ReportLab, matplotlib |
| Image generation | banana-claude/nanobanana MCP preferred; Gemini/OpenAI/Stability/Replicate fallback script |
| Verification | pytest, PyYAML, pip-audit, GitHub Actions |
| Install | Bash and PowerShell installers with host whitelist/path validation |

## Key Features

### Multi-Platform Audit Surface

The skill covers Google, Meta, YouTube, LinkedIn, TikTok, Microsoft, Apple, Amazon, attribution, server-side tracking, landing pages, budget, competitor intelligence, A/B tests, PPC math, campaign planning, creative review, brand DNA, image generation, and product photoshoots. The repo claims roughly 300+ total checks when inline platform thresholds are included; 212 catalog-tracked checks are pinned in the scoring reference, while Apple/Amazon/attribution/server-side checks live inline until a future catalog pass.

### Agent-Orchestrated Audit Model

/ads audit is designed to delegate parallel audit work to specialized agents: Google, Meta, creative, tracking, budget, and compliance. This is the right shape for a wide audit problem because the domain naturally decomposes by channel and function, then recombines into one score and action plan.

### Eval Harness for Skill Drift

The tests are a good pattern for serious skill packs. They check route phrases against expected sub-skills, verify bidirectional coverage between the catalog and reference files, test scoring determinism, and pin SSRF/credential-redaction behavior. Local verification passed: 59 pytest tests, plus pip-audit with no known runtime vulnerabilities.

### Local Helper Scripts With Guardrails

The Python scripts cover page fetch, screenshot capture, landing-page analysis, image generation, and PDF report generation. scripts/url_utils.py blocks private/internal IP ranges, fails closed on DNS errors, restricts schemes to HTTP/S, strips userinfo from logged URLs, and redacts common token/API-key patterns from errors.

## Architecture

The repo is organized around progressive loading:

- ads/SKILL.md is the main router and orchestrator.
- skills/ads-*/SKILL.md files hold focused platform/function playbooks.
- agents/*.md files define specialized audit and creative workers.
- ads/references/*.md stores reusable scoring, benchmarks, compliance, copy, tracking, and platform references.
- scripts/*.py implements optional local utilities.
- tests/ pins routing, scoring, check catalog coverage, and script security behavior.

That structure is much more maintainable than one enormous advertising prompt. It lets an agent load only the relevant platform or workflow while keeping shared references available.

## Comparison

| Aspect | Claude Ads | Manual PPC Audit | Commercial Audit Tool |
|--------|------------|------------------|-----------------------|
| Runtime | Local agent skill + optional scripts | Human consultant | SaaS backend |
| Coverage | Broad, cross-platform, current ad-system terminology | Depends on reviewer | Usually strongest for one or two platforms |
| Repeatability | High if inputs are consistent | Medium | High |
| Judgment | Agent-assisted, needs review | Human expert | Rule-based dashboards |
| Data residency | Local by default | Depends on workflow | Vendor-hosted |
| Weak spot | Packaging/install polish and API automation depth | Time and consistency | Lock-in and generic recommendations |

## Self-Hosting Notes

Clone the public repo, create a local Python virtual environment, install requirements.txt plus requirements-dev.txt, and run pytest tests/ before using the helper scripts.

Do not blindly run the public mirror's installer without checking the target repo URL. At review time, both install.sh and install.ps1 defaulted to https://github.com/AI-Marketing-Hub/claude-ads, which the README describes as the private community mirror. Public users may need to edit the repo URL or install from the checked-out public clone manually.

Also avoid the Unix installer's --break-system-packages fallback on managed Python environments. A venv is cleaner and safer.

---

**Attribution:** AgriciDaniel/claude-ads, MIT
