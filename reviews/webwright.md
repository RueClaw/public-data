# Webwright (microsoft/Webwright)

**Repo:** https://github.com/microsoft/Webwright
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-05-26
**Stack:** Python 3.10+, Playwright, Typer, Pydantic, Jinja2, httpx, Flask task-showcase app
**What it is:** A small browser-agent harness that treats the browser as a disposable execution environment and the local workspace as the durable state. The agent writes and repairs Playwright scripts until the task is captured as rerunnable code with logs, screenshots, and optional self-reflection.

---

## Verdict

✅ **Deploy candidate for coding-agent browser tasks.** Webwright is worth using or forking when the desired output is not just an answer, but a reusable browser automation script plus evidence. The implementation is young and intentionally sharp-edged, but the core pattern is strong: make the agent produce code, artifacts, and verification state instead of hiding a click-by-click loop inside a framework.

---

## What It Is

Webwright is a minimal SWE-style browser-agent framework from Microsoft Research. It gives a coding model a terminal, a Playwright browser environment, and a strict contract: solve the web task by writing scripts, inspect screenshots or ARIA snapshots when needed, then finish with a rerunnable `final_script.py` and run artifacts.

The repo targets long-horizon web tasks where one-action-at-a-time browser agents tend to drift. Instead of preserving browser session state as the primary artifact, Webwright preserves workspace state: scripts, step logs, screenshots, `trajectory.json`, self-reflection outputs, and optional rendered task reports.

It also ships host-agent integrations through a shared `skills/webwright/` folder plus Claude Code and Codex plugin manifests. That matters because the most useful version of this idea may be as a skill contract inside an existing coding agent rather than as a standalone model loop.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.10+ |
| Browser control | Playwright Chromium, local launch, local persistent context, local CDP, Browserbase-style workspace mode |
| Agent loop | Custom Python loop in `src/webwright/agents/default.py` |
| Model backends | OpenAI Responses API, Anthropic Messages API, OpenRouter |
| Config | YAML overlays merged with Pydantic config classes |
| CLI | Typer entrypoint `webwright` |
| Evidence tools | Screenshot capture, ARIA snapshots, `image_qa`, `self_reflection` |
| Showcase UI | Small Flask/Jinja app under `assets/task_showcase/` |
| Distribution | Python package, Claude Code plugin manifest, Codex plugin manifest, shared skill files |

## Key Features

### Code-as-action browser loop

Webwright pushes the model to write shell or Python snippets that drive Playwright directly. The local workspace environment persists each generated shell command to `steps/`, appends it to `command_history.sh`, captures output logs, previews `final_script.py`, and reports recent screenshots back to the loop.

The browser is not the durable memory. The durable memory is the code and evidence the task leaves behind.

### Multiple browser modes

The repo supports a shell-workspace mode and a live local-browser mode. The local browser environment can launch a clean browser, a persistent context, or connect to a real local Chrome/Edge instance over CDP. There is also a `persistent_local_browser` helper that creates a detached Chromium session and stores `{id, pid, connectUrl, userDataDir}` as JSON so later steps can reconnect.

This is a practical design choice. Web tasks often need fresh browser reconstruction for repeatability, but some exploration tasks benefit from persistent state, cookies, or a manually authenticated browser.

### Verification-first task contract

The strongest part of the repo is the skill contract in `skills/webwright/SKILL.md`: write `plan.md`, enumerate critical points, build `final_script.py`, run it inside `final_runs/run_<id>/`, save evidence screenshots, write `final_script_log.txt`, and self-verify every critical point before declaring success.

That contract is stricter than most browser-agent demos. It turns a browsing session into an auditable artifact.

### Model backend simplicity

OpenAI, Anthropic, and OpenRouter adapters are thin. Each backend serializes the same message/action abstraction and relies on the base model class for retries, usage metrics, JSON parsing, screenshot attachment, and format-error recovery.

### Task showcase renderer

The Flask task showcase is intentionally small. It renders `task.json`, `report.json`, logs, steps, sources, screenshots, and final results without needing a custom UI per task. This is a useful pattern for turning agent runs into inspectable demos or recurring reports.

## Architecture

The architecture is refreshingly direct:

- `run/cli.py` loads YAML config overlays, resolves task/start URL/output paths, instantiates model, environment, and agent, then runs one task.
- `agents/default.py` owns message history, strict JSON action parsing, debug artifacts, trajectory writing, compaction, and completion gates.
- `environments/local_workspace.py` executes model-generated shell commands in a bounded workspace and captures command output plus recent files/screenshots.
- `environments/local_browser.py` executes async Python snippets against a prepared Playwright page and returns ARIA, screenshot, URL, console, and exception observations.
- `models/*` hide provider-specific request formats while keeping the agent loop provider-neutral.
- `tools/image_qa.py` and `tools/self_reflection.py` provide visual checking and final run verification through OpenAI-compatible model calls.

The risk is also clear: the core environment intentionally executes model-generated shell or Python. This is a local automation harness, not a sandbox boundary. Use it where the agent is authorized to operate in the workspace and browser profile.

## Comparison

| Aspect | Webwright | agent-browser | browser-use | Stagehand |
|--------|-----------|---------------|-------------|-----------|
| Primary abstraction | Rerunnable code artifact | CLI/browser daemon commands | Autonomous DOM/action loop | Playwright plus natural-language helpers |
| State model | Local workspace artifacts | Browser daemon session | Browser session | Browser/page session |
| Action space | Free-form shell/Python/Playwright | Discrete CLI operations | Indexed click/type/extract actions | Code plus `act`/`extract` style helpers |
| Best use | Long-horizon tasks that need evidence and reruns | Tooling an existing agent with browser primitives | Quick autonomous browsing flows | App automation with mixed code/NL |
| Main caveat | Executes generated code; young repo; limited tests visible | Less opinionated about final artifacts | More hidden loop state | More framework/platform surface |

## Self-Hosting Notes

Install is conventional:

```bash
pip install -e .
playwright install chromium
```

For standalone model-driven runs, provide the relevant API key such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `OPENROUTER_API_KEY`. For host-agent plugin usage, the bundled skill can avoid separate model API keys because the host agent performs the reasoning and verification.

Operational caveats:

- Run in a disposable or intentionally scoped workspace.
- Treat browser profiles and `userDataDir` as sensitive.
- Do not expose CDP ports beyond loopback.
- Expect to add policy gates if this becomes a shared service.
- The README mentions tests in the project map, but this checkout did not include a `tests/` tree.

---

**Attribution:** microsoft/Webwright, MIT
