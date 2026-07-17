# AI Marketing Skills (ericosiu/ai-marketing-skills)

**Repo:** https://github.com/ericosiu/ai-marketing-skills
**License:** MIT. Safe to adapt with attribution.
**Reviewed:** 2026-07-17
**Stack:** Claude Code skills, Python CLIs, TypeScript eval runner, marketing automation scripts, local telemetry, PII sanitizer
**What it is:** A large marketing and sales skill pack for agent-assisted growth experiments, content ops, outbound, SEO, finance analysis, sales pipeline work, revenue intelligence, deck generation, and media repurposing.

---

## Verdict

⚠️ **Interesting marketing-ops skill library, not a plug-and-play automation stack.** The repo has a lot of useful workflow content: expert panels, growth experiment tracking, content scoring, closed-loop analytics, sales-pipeline scripts, and practical marketing rubrics. But the operational surface is uneven: the advertised safety workflow is not under `.github/workflows`, the built-in sanitizer flags the repo itself, several scripts are stubs or require live third-party credentials, and the skill preambles can prompt for telemetry on first run.

---

## What It Is

AI Marketing Skills is a collection of Claude Code-style skills and Python helper scripts for common marketing and revenue workflows. It covers growth experiments, anonymous visitor routing, cold outbound, content production, SEO opportunity briefs, finance/cost analysis, sales-call intelligence, conversion audits, podcast repurposing, YouTube competitive analysis, decks, and short-form video pipelines.

The repo is best understood as a menu of workflow kits rather than one integrated product. Each directory usually contains a `SKILL.md`, README, requirements file, and one or more scripts. Some scripts are ready local utilities; others are API integration shells that need credentials and customization.

The most reusable pieces are the instruction/rubric assets: content expert panels, AI-writing detection, scoring rubrics, closed-loop analytics readback, and experiment promotion rules. The riskiest pieces are the ones that send email, enroll leads, expose webhook listeners, write CRM/outbound records, or assume real platform credentials.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Markdown `SKILL.md` files per workflow |
| Scripts | Python CLIs, mostly stdlib plus optional API clients |
| Eval | TypeScript `eval/run-eval.ts` for API scenario checks |
| Security helper | Python PII/sensitive-data sanitizer and pre-commit hook |
| Telemetry | Local JSONL logging, optional remote post stub |
| Integrations | HubSpot, Instantly, RB2B, Brave Search, Google Search Console, Gong, Anthropic, OpenAI, Whisper, YouTube, Google Slides |
| CI | Safety workflow exists as `skill-safety.yml`, but not in `.github/workflows` in the reviewed checkout |

## Key Features

### Broad Marketing Skill Catalog

The repo has unusually wide coverage for marketing operations. Categories include growth experiments, sales pipeline automation, content ops, outbound, SEO, finance ops, revenue intelligence, conversion ops, podcast ops, team ops, sales playbooks, autoresearch, deck generation, YouTube competitive analysis, and X long-form writing.

That breadth is useful for teams that want agent-readable playbooks for recurring marketing work. It is also a maintenance burden: each workflow has different credential, data-quality, privacy, and approval requirements.

### Expert Panel and Content Quality Gates

`content-ops/SKILL.md` defines an expert-panel workflow that auto-assembles domain reviewers, chooses scoring rubrics, iterates up to three rounds, and uses a mandatory AI-writing detector. The humanizer reference is concrete: it lists 24 AI-writing patterns with penalties and before/after examples.

This is one of the strongest pieces in the repo. It turns subjective "make this better" feedback into a repeatable scoring loop with domain experts, known-bad pattern enforcement, and source-skill feedback.

### Growth Experiment Engine

`growth-engine/experiment-engine.py` tracks experiments, variants, metrics, sample floors, bootstrap lift confidence intervals, Mann-Whitney U tests, and playbook promotion. Winners require both statistical significance and lift.

The implementation is local-file based and understandable. It still needs dependency installation (`numpy`, `scipy`) and real analytics discipline; it should not be confused with a complete experimentation platform.

### Closed-Loop Analytics Upgrade

`closed-loop-analytics-upgrade/SKILL.md` is a good reusable pattern: do not promote prompt or playbook changes until platform analytics prove the change worked. It names baseline/candidate windows, primary and secondary metrics, caveats, source-system status, and promote/rollback/unproven decisions.

This is the most portable idea in the repo because it applies beyond marketing. Any agent skill that changes behavior should eventually read back outcomes and patch the playbook only from evidence.

### Security and Telemetry Helpers

The repo includes a PII/sensitive-data scanner, sanitizer config, pre-commit hook, telemetry init/log/report scripts, and an opt-in telemetry policy. Those are good instincts, but the current execution is rough.

Local scan result:

```bash
python3 security/sanitizer.py --scan --dir . --recursive
```

The scanner found 119 findings across 24 files, mostly dollar amounts that are examples or marketing claims. That means the documented "run the sanitizer before committing" gate would fail on the checked-out repo unless configured differently.

## Architecture

The repository is organized as many small skill folders:

```text
ai-marketing-skills/
  growth-engine/
  sales-pipeline/
  content-ops/
  outbound-engine/
  seo-ops/
  finance-ops/
  revenue-intelligence/
  conversion-ops/
  podcast-ops/
  team-ops/
  sales-playbook/
  autoresearch/
  deck-generator/
  yt-competitive-analysis/
  x-longform-post/
  security/
  telemetry/
  eval/
```

Most folders are independent. That makes selective adoption easy, but it also means there is no single dependency lock, central test suite, or shared runtime boundary. The repo is closer to an operational cookbook with scripts than a cohesive application.

A few architecture details matter before use:

- Several scripts can perform external writes: send cold emails, enroll leads, update outbound systems, or generate CRM-style records.
- Webhook servers bind to `0.0.0.0` in sales-pipeline scripts, so operators should put them behind explicit local/firewall controls.
- Telemetry preambles call `telemetry_init.py` on skill start. On first run that script prompts interactively unless a config already exists.
- `skill-safety.yml` looks like a GitHub Actions workflow but is at the repository root, so it is not active as a normal GitHub workflow in this checkout.

## Comparison

| Aspect | AI Marketing Skills | Claude Ads | compound-engineering-plugin | AutoresearchClaw |
|--------|---------------------|------------|-----------------------------|------------------|
| Primary value | Marketing/revenue workflow library | Paid-advertising skill pack with tests | Cross-harness engineering workflow skills | Research pipeline with strong verification |
| Runtime | Markdown skills plus Python scripts | Claude skills plus helper scripts | Plugin/skill adapters and contract tests | Python research system |
| Best idea | Closed-loop marketing readback and expert panels | Domain skill eval harness | Guardrails-not-choreography planning | HITL/verification gates |
| Main caveat | Uneven enforcement, inactive CI file, external-action risk | Narrower domain | Engineering-focused | Heavier research runtime |

AI Marketing Skills has more marketing breadth than Claude Ads, but Claude Ads has a stronger test and CI posture. Treat this repo as a source of workflows and rubrics first; adopt scripts only after local hardening.

## Self-Hosting Notes

There is no single service to deploy. Clone the repo, choose a skill directory, install that directory's requirements, configure environment variables, and run the relevant script. Do not install every skill globally by default.

Recommended adoption path:

1. Start with read-only or local-only workflows: content scoring, expert panels, growth experiment logs, SEO briefs, finance analysis against sanitized exports.
2. Disable or preconfigure telemetry before loading skills in non-interactive agent sessions.
3. Treat outbound, CRM, webhook, email, and publishing scripts as approval-gated external actions.
4. Run the sanitizer, but tune its config first so example dollar amounts and placeholder companies do not drown out real secrets.
5. Move `skill-safety.yml` under `.github/workflows/` and fix its current scan failures before relying on it as CI.

## Verification

Reviewed commit `a9f11007aca31cc85f231698e22b64412f847b76` from 2026-05-27. GitHub metadata at review time: 2,987 stars, 610 forks, 1 open issue, MIT license, created 2026-03-28, last pushed 2026-07-12.

Local checks:

```bash
python3 -m compileall -q .
python3 security/sanitizer.py --scan --dir . --recursive
python3 sales-pipeline/rb2b_webhook_ingest.py --help
```

Compile passed. The sanitizer reported 119 findings across 24 files. `rb2b_webhook_ingest.py --help` worked. `growth-engine/experiment-engine.py --help` could not run before installing dependencies because `scipy` was missing in the local environment.

---

**Attribution:** ericosiu/ai-marketing-skills, MIT License
