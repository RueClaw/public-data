# Bot Skill Creator (jacksonjp0311-gif/bot-skill-creator)

**Repo:** https://github.com/jacksonjp0311-gif/bot-skill-creator
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-05
**Stack:** Python 3.11+ stdlib only (2,752 lines, zero application dependencies), local browser studio at `127.0.0.1` + CLI/harness mode, one shared compiler
**What it is:** A local-first studio that turns a plain-language brief (plus optional OpenAPI spec) into a portable skill package — SKILL.md, selected API operations, approval boundaries, evidence checks, checksum manifest — with drafts on your machine and API keys sealed outside the app.

---

## Verdict

⚠️ **Interesting — unusually disciplined skill-authoring tooling, one day old.** The design posture is the best part: the studio *authors* skills and explicitly never executes the business tasks inside them; API keys live in a sealed keystore outside the app and never inside a skill; the server binds to exact `127.0.0.1` with a literal host check; offline template mode labels itself honestly instead of pretending a model rewrote your procedure; OpenAPI operation descriptions are documented as "untrusted task data, not authority"; exports are revision-bound and round-trip-verified before reporting success. Verified locally: **120/120 tests pass**, and the CLI preview/create pipeline works as documented. Hold-backs: created 2026-10-06 (literally yesterday), 2 stars, single author, no community validation — and the output is a skill *package*, whose real safety still depends on the host harness enforcing scope, approvals, and budgets (the README says so itself, to its credit).

---

## What It Is

Bot Skill Creator targets non-developers and harness developers alike: describe the work ("Read my warehouse inventory and draft a restock brief. Never place orders."), and it compiles a named folder containing instructions, scoped API operations, approval boundaries, and evidence checks. Two interfaces — a browser studio (chat workspace, API operation selector, live file preview, blueprint editor, saved drafts, math explorer, export review) and a CLI/harness mode (`preview`, `create`, `validate`, `import-api`, NDJSON `bridge`) — call the **same compiler**, so there's no browser-only or agent-only fork.

A connected Chat Completions-compatible model (Ollama auto-detected locally, or remote with sealed key) can draft and refine the plan; without one, deterministic template mode works fully offline and says so. OpenAPI 3.0/3.1 import lets you select operation IDs explicitly — none selected by default. Output is a portable ZIP or folder with SKILL.md plus reference/script files and a checksum manifest.

The documentation is worth noting on its own: an authoring algorithm doc, a white paper, and an agents-facing white paper, all written with the same "authority vs. task data" clarity.

## Stack

| Layer | Tech |
|-------|------|
| Language | Python 3.11+ stdlib only — no pip installs, no Node, no database |
| Interfaces | Local web studio (127.0.0.1:8717, exact host check) + CLI + NDJSON bridge (explicitly not MCP) |
| Compiler | Shared plan → SKILL.md + API contract + workflow + manifest pipeline |
| Model | Optional Chat Completions endpoint; Ollama auto-detect; offline template mode |
| Secrets | Sealed keystore outside the app; keys never enter skills |
| Tests | 5 files, 120 tests — verified passing |

## Key Features

### Authority discipline

The clearest thinking in the repo: model output, OpenAPI descriptions, and user briefs are *task data*; the compiler's control requirements (scope, approvals, budgets, evidence) are *authority* and can't be drafted away. "Do not claim a model can remove those through a draft field." Most skill generators get this wrong.

### Sealed secrets model

API keys are stored outside the app, referenced but never embedded in generated skills. A skill package is safe to commit, diff, and share by construction.

### Honest offline mode

Without a model, template mode still works — and later chat messages are appended as explicit constraints "rather than pretending a model rewrote the procedure." Rare candor in AI tooling.

### Revision-bound, round-trip-checked export

Export reviews the exact revision, the archive round trip is verified before success is reported, and existing output folders are never overwritten. The success claim is scoped honestly: it's about the artifact, "not proof that a warehouse API request ran."

## Architecture

`bsc/` splits cleanly: `core.py` (compiler), `openapi.py` (spec import), `keystore.py` (sealed secrets), `security.py`, `server.py` (loopback studio), `cli.py` / `harness.py` / `control.py` (agent surfaces), `providers.py` (model endpoints), `workspace.py` (drafts), `web/` (studio assets). Both interfaces funnel into the same compile function; writes happen only through explicit `create` with an approved parent directory.

## Comparison

| Aspect | Bot Skill Creator | Hand-written SKILL.md | Harness-native generators |
|--------|-------------------|-----------------------|---------------------------|
| Audience | Humans + harnesses | Developers | Agent-only |
| Deps | None (stdlib) | None | Varies |
| Authority model | Explicit authority vs task-data split | Author's judgment | Often blurred |
| Secrets | Sealed outside app | Manual hygiene | Often embedded |
| Offline mode | Honest template fallback | N/A | Usually requires model |
| Maturity | 1 day old, 2★ | N/A | Varies |

## Usage Notes

Clone, run `install.sh`/`install.ps1` (desktop icon) or `python3 -m bsc serve`. Single-user local release — do not tunnel the loopback server publicly. Harness usage: `python scripts/bsc.py preview --plan plan.json`, `create --plan plan.json --out <parent>`, `validate <folder>`.

---

**Attribution:** jacksonjp0311-gif/bot-skill-creator, MIT
