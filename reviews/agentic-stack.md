# agentic-stack (codejunkie99/agentic-stack)

**Repo:** https://github.com/codejunkie99/agentic-stack  
**License:** Apache-2.0  
**Reviewed:** 2026-05-31  
**Commit reviewed:** `00eda65cd2030ffc62b9c01b8360dd2d1719eaef`  
**Stack:** Python, shell/PowerShell installers, local Markdown/JSONL memory, adapter manifests, optional OpenAI/Anthropic SDKs  
**What it is:** A portable `.agent/` folder for memory, skills, protocols, hooks, adapters, transfer, and local agent telemetry across multiple coding-agent harnesses.

---

## Verdict

⚠️ **Interesting, but current HEAD is not a clean deploy candidate.** The architecture is genuinely useful: a local portable agent brain, progressive skills, four memory layers, manifest-driven harness adapters, transfer bundles, safe install/remove bookkeeping, and local-only data exports. But local verification found a real Python syntax regression in Mission Control: the full pytest suite reported `82 passed, 13 failed`, with every failure caused by `harness_manager/mission_control_render.py` failing to import under Python 3.11.

The core portable-brain idea is worth studying and piloting in a scratch project. I would wait for the Mission Control import bug to be fixed before relying on the current release as a default install.

## What It Is

agentic-stack packages an `.agent/` directory that can be mounted by many coding-agent tools. The folder contains memory, skills, protocols, hooks, helper tools, and adapter-specific files. The project goal is simple: keep agent knowledge and working conventions in one local place while letting the user switch between harnesses.

The README describes support for Claude Code, Cursor, Windsurf, OpenCode, GitHub Copilot CLI, Gemini CLI, Hermes, Pi Coding Agent, Codex, Antigravity, standalone Python, and other adapter targets.

## Architecture

### Portable Brain

The `.agent/` tree is the center of the system:

- `memory/personal/` stores user preferences.
- `memory/working/` stores current task state and review queues.
- `memory/episodic/` stores raw event JSONL.
- `memory/semantic/` stores distilled decisions and accepted lessons.
- `skills/` uses progressive disclosure through `_index.md`, `_manifest.jsonl`, and per-skill `SKILL.md` files.
- `protocols/` includes permissions, delegation, and tool schemas.
- `tools/` includes recall, learn, show, data export, flywheel export, lesson review, and transfer helpers.

This is a sensible boundary. Harnesses can be thin adapters while the durable knowledge lives in inspectable files.

### Manifest-Driven Adapters

Adapters live under `adapters/<name>/adapter.json`. The Python validator rejects unknown fields, empty file lists, path traversal, absolute POSIX paths, Windows absolute paths, drive-letter paths, and unsafe skills links. The installer records created, overwritten, skipped, alerted, and linked files in `.agent/install.json`, which makes remove/upgrade behavior more conservative than a blind copy script.

### Memory and Learning Loop

The project includes a staged lesson lifecycle: raw events go into episodic memory, candidate lessons can be generated, and accepted lessons render into semantic memory. The host agent is expected to review candidates before promotion. That avoids the worst version of "self-learning memory" where every accidental output becomes a permanent rule.

### Transfer and Data Layer

The transfer bundle code exports selected `.agent` scopes, compresses and base64-encodes them, verifies a SHA-256 digest, blocks secret-like content, merges preferences idempotently, and avoids overwriting permissions. The data layer and flywheel exporters are local-only and produce activity records, context cards, eval cases, training-ready JSONL, and dashboards without sending telemetry to a hosted service.

### Brain CLI Bridge

Version `0.18.0` adds optional bridge support for an external Brain CLI/MCP tool. This is a useful extension point, but it is optional; the project still works as a local file-backed stack.

## Security and Operational Notes

Good signs:

- Adapter path validation handles POSIX and Windows traversal cases.
- Install/remove tracks ownership and avoids deleting pre-existing user files.
- Transfer import refuses secret-like content and blocks overwriting `permissions.md`.
- Mission Control binds to `127.0.0.1` by default.
- Runtime dependencies are small: `anthropic` and `openai` in `requirements.txt`; most installer logic is stdlib Python.

Caveats:

- The transfer import bootstrap downloads the current `master` tarball from GitHub when `AGENTIC_STACK_ROOT` is not present. The memory payload has a digest, but the bootstrap code path is not pinned to a commit.
- Installing an adapter writes harness files and copies `.agent/` into a project, so it should be tested in a disposable repo first.
- Local memories and exports can contain sensitive data even when the tooling is local-only.
- The project has no `pyproject.toml` package boundary; usage is mostly script/Homebrew driven.

## Verification

Local verification on macOS:

- Cloned `codejunkie99/agentic-stack` at commit `00eda65cd2030ffc62b9c01b8360dd2d1719eaef`.
- `uv venv && uv pip install -r requirements.txt pytest` succeeded with Python 3.11.
- `.venv/bin/python verify_codex_fixes.py` passed all regression checks.
- `.venv/bin/python -m compileall -q .agent harness_manager tests onboard.py onboard_*.py verify_codex_fixes.py` failed on `harness_manager/mission_control_render.py`.
- `.venv/bin/python -m pytest -q` reported `82 passed, 13 failed`; all failures were Mission Control import failures from the same syntax error:

```text
SyntaxError: f-string expression part cannot include a backslash
```

The offending expression is an f-string conditional HTML fragment around `data-ops-log` in `harness_manager/mission_control_render.py`.

## Best Reusable Pattern

The strongest reusable pattern is a portable local agent brain with manifest-validated harness adapters:

- keep memory, skills, protocols, and tools in one inspectable project-local tree;
- make each harness an adapter instead of a separate source of truth;
- validate adapter manifests before writing files;
- record install ownership so remove/upgrade can be conservative;
- keep analytics and learning loops local by default;
- export/import selected memory scopes with digest checks and secret scanning.

Extracted as `public-data/patterns/portable-agent-brain-adapters.md`.

## Bottom Line

agentic-stack is one of the more thoughtful attempts at cross-harness agent portability. I would not install current HEAD into an important project without first patching the Mission Control syntax bug, but the memory layering, adapter manifests, transfer model, and local data/flywheel exports are absolutely worth borrowing.

---

**Attribution:** codejunkie99/agentic-stack, Apache-2.0, https://github.com/codejunkie99/agentic-stack
