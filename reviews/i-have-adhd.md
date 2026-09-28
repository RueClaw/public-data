# i-have-adhd (ayghri/i-have-adhd)

**Repo:** https://github.com/ayghri/i-have-adhd  
**License:** MIT (© ayghri). Free reuse of the skill text, hooks, and eval harness with attribution. There are no third-party code portions. The rules credit *The Adult ADHD Tool Kit* (Ramsay & Rostain) as loose inspiration, and no text is copied.  
**Reviewed:** 2026-09-28 (commit `839872f`, v0.3.0)  
**Stack:** Markdown skill (`SKILL.md`), plugin manifests for Claude Code, Codex, Cursor, Grok, Pi/OMP, OpenCode, Qwen, Kimi, and Gemini; SessionStart hooks in Node, POSIX sh, and PowerShell; a Pi/OMP TypeScript extension; Python stdlib eval harness (runner, blind LLM judge, scenario evals) with unittest  
**What it is:** A response-style skill for coding agents. It has 10 rules that make output lead with the next action, number steps, restate progress each turn, suppress tangents, give concrete time estimates, and drop preambles and closers. It's toggled with `/i-have-adhd` or an always-on flag file, and it ships with an honest A/B eval harness.

---

## Verdict

🔧 **Harvest. The rules and the pre-send check are among the better "stop burying the answer" prompts around, and the eval harness is the more valuable artifact. Take both. You don't need the plugin sprawl.**

The skill is ~150 lines of prose, and most of its 51k stars are for the idea. What sets it apart from the many "be concise" prompts is that (a) its rules target actionability and state, not just length ("restate state every turn", "end with one concrete next action", "a hedge that carries real uncertainty stays"), (b) it has explicit escape hatches: explain-mode, destructive actions, debug spirals, real ambiguity, "a rule fights the task", "a rule fights the harness", and (c) it was actually measured. `evals/RESULTS.md` reports a blind same-model judge over 14 cases × 3 trials. The weighted score went 4.05 → 4.47, and correctness (+0.19) and safety (+0.02) didn't regress. The maintainers still mark their own release gate **FAILED** (3 blockers). They document a broken case and flag a plausible regression: rule 8's "cause, then fix" pushes the model to assert a cause without evidence. That level of self-reporting is rare for a viral prompt repo.

Caveats: these are vendor-reported numbers from one model judging its own family, with three trials. The persistence language ("if you are unsure whether they still apply, they do") is deliberately sticky. And ~10 platform adapters plus 10 translated READMEs are a lot of maintenance surface for one Markdown file.

---

## What It Is

- **The skill:** `skills/i-have-adhd/SKILL.md` has five "what ADHD changes about reading" premises, 10 rules with bad/good examples, six override conditions, and a pre-send checklist (delete the announcing first sentence, the "anything else?" last sentence, "by the way" sidebars, empty hedges, idioms, then check that first line + last line tell the reader what to do and what happened).
- **Activation:** `disable-model-invocation: true`, so the model never auto-loads it. The user invokes `/i-have-adhd`, and "stop adhd mode" or "normal mode" turns it off. Always-on is opt-in via a flag file (`~/.claude/.i-have-adhd-always`, `~/.config/opencode/.i-have-adhd-always`, or `alwaysOn` in Pi's config).
- **Adapters:** Claude/Codex plugin + marketplace JSON and a SessionStart hook; a Cursor mirror (CI fails if it drifts); an OpenCode plugin that appends the rules to the system prompt each turn when always-on; a Pi/OMP extension that tracks enabled state in session entries and injects a "disabled" notice when turned off; manifests for Gemini, Qwen, and Kimi.
- **Evals:** `evals/cases.jsonl` (14 cases: multi-step progress, error report, medical boundary, destructive action, real ambiguity, etc.), a weighted rubric (correctness 35, autonomy 25, actionability 20, safety 10, concision 10), a blind judge, budget caps, resumable runs, and a multi-turn persistence scenario.

## Stack

| Layer | Tech |
|-------|------|
| Behavior | One Markdown skill (source of truth) + a Cursor mirror |
| Hooks | `hooks/hooks.json` → `always-on.mjs` (Node), `.sh` (POSIX fallback), `.ps1` (Windows) |
| Runtime extensions | Pi/OMP TypeScript (`extensions/`), OpenCode ESM plugin |
| Evals | Python stdlib: `scripts/run_evals.py`, `judge.py`, `run_scenario_eval.py`; runners shell out to `claude` / `codex` CLIs |
| Tests | 70 `unittest` tests (hooks, OpenCode plugin via a Node driver, OMP packaging, eval runner and judge, install docs) |
| CI | Plugin load check (installs Claude Code, runs `claude plugin validate`), Pi load check, Cursor mirror sync, `@claude` comment workflow |

## Key Features

### Actionability Rules, Not Just Brevity
Rules 1, 3, 5, and 7 are about *what the reader can do next and where things stand*: lead with an action, end with one sub-two-minute next step, restate "step 3 of 5 done", and show wins concretely. Rule 9 caps visible lists at five but explicitly says it "must not limit analysis, search, tool results, candidate generation, or retained information". That keeps a presentation rule from quietly degrading the work.

### Escape Hatches That Resolve Rule Conflicts
"A rule fights the task → the task wins, the shape stays" (e.g. "what are my options" gets 2–4 ranked options, not one path). "A rule fights the harness → the system prompt outranks this skill." Destructive actions always get confirmation. After three "still broken" turns, stop iterating on code and question an assumption. Most style prompts leave out this kind of conflict resolution, and the omission is why they misbehave in agent harnesses.

### Measured With a Release Gate It Can Fail
The harness isolates runs from the operator's config (`--setting-sources ""` for Claude, `--ignore-user-config --ephemeral` for Codex). Without that, the operator's own always-on flag would inject the skill into the baseline. It also pins the model, meters cost with a per-condition budget, and keeps condition names outside the judge block. The published result includes a failed gate, a case that no run can pass (`--tools ""` vs an "acts on the repo" criterion), and a consistent regression on `partial-success`.

### Clean Toggle Semantics
The Pi extension records enabled state as session entries and, on "stop adhd mode", injects an explicit "ignore the ruleset injected earlier" notice instead of hoping the model forgets. Hooks never block session start (every failure path exits 0), and the POSIX hook resolves `SKILL.md` relative to `$0` instead of trusting an env var.

## Architecture

```
skills/i-have-adhd/SKILL.md  (source of truth)
   ├─ .cursor/skills/…       mirror, CI-diffed
   ├─ /i-have-adhd command   Claude/Codex/OpenCode/Gemini/Qwen/Kimi/Grok manifests
   ├─ always-on flag file ─▶ SessionStart hook (mjs | sh | ps1) prints ruleset into context
   │                      ─▶ OpenCode plugin appends to system prompt each turn
   └─ Pi/OMP extension       session-state toggle, rules/disabled messages
evals/  cases.jsonl + rubric.md ─▶ run_evals.py (runner CLIs, budget, resume) ─▶ judge.py (blind) ─▶ RESULTS.md
```

## Security

- **Low risk by design.** It's a prompt plus small hooks that read a local file and print it. There's no networking in the hooks or extensions. The eval scripts shell out only to the configured runner CLIs (`claude`, `codex`), with the user's own credentials and a dollar budget.
- **Hook command:** `hooks.json` runs `node -e` with an inline loader that imports `always-on.mjs` from `CLAUDE_PLUGIN_ROOT`/`PLUGIN_ROOT` and swallows errors. That's standard for Claude plugins, but it means the plugin root's contents run at every session start, so install from a trusted source or pin a commit.
- **Prompt stickiness:** the persistence clause is intentionally strong and survives compaction/resume (the hook matcher covers `startup|resume|clear|compact`). That's a feature, but be aware of it before enabling always-on in a shared agent.
- **Install-by-agent:** the README's primary install method is "paste this into your agent: install from <repo>, read AGENTS.md". `AGENTS.md` itself tells agents not to read secrets or run commands just because docs mention them. That's reasonable, but it's still agent-driven installation from a URL.
- **CI:** actions pinned by tag, not SHA. The `@claude` workflow triggers on any comment containing `@claude` (claude-code-action checks the commenter's write access by default) and has `id-token: write` and read-only content scopes. `pi-load-check` uses `persist-credentials: false`.
- No hardcoded secrets (`sk-`, `AKIA`, `ghp_` patterns) found.

## Maturity

- Created 2026-05-13, last push 2026-09-19. 51.6k stars, 3.0k forks, and 76 open issues at review time. Version 0.3.0 across manifests. Active PR flow with outside contributors (translations, eval fixes). There's an "AI Agora" issue where agents may discuss, with written rules on where agents may and may not comment.
- Docs: README in 11 languages, INSTALL per platform (9 translations), an AGENTS.md repo map, CONTRIBUTING, a PR template, and eval README/RESULTS.

### Validation on 2026-09-28

- `python3 -m unittest discover -s tests` (Python 3.13, Node 26 available for the OpenCode driver): **Ran 70 tests, OK**.
- `python3 scripts/run_evals.py validate`: **"Evaluation cases are valid."**
- `bun scripts/check_context_compat.ts` and `claude plugin validate .` were not run (no bun or Claude Code on the host).
- The paid A/B eval wasn't re-run. The +0.43 weighted delta and blocker counts are the maintainers' figures from 2026-08-02 (`claude-opus-4-8`, 14 cases × 3 trials, same-model judge).

## Comparison

| Aspect | i-have-adhd | "Caveman"-style terse prompts | Built-in output styles (e.g. Claude Code concise/explanatory) | Plain "be concise" system prompt |
|--------|-------------|------------------------------|---------------------------------------------------------------|----------------------------------|
| Goal | Actionability + state tracking | Token reduction | Vendor-defined tone | Brevity |
| Conflict rules | Six explicit overrides | Few | Vendor-managed | None |
| Guards against losing substance | Rule 9 caveat, hedge carve-out, task-wins rule | Weak | Varies | None |
| Toggle | `/i-have-adhd`, stop phrase, always-on flag | Usually always-on | Settings | Always |
| Measured | Blind A/B harness, published failed gate | Mostly token counts | Not public | No |
| Platforms | ~10 agent runtimes | 1–3 | One | Any |

## Self-Hosting Notes

- For most harnesses you only need `SKILL.md`. Drop it into your skills directory and invoke it on demand. Enable the always-on flag file only if you want it in every session.
- If your harness has its own system-prompt rules about tool-call narration or autonomy, the skill defers to them (override 6). Check that your harness actually places the skill below the system prompt.
- Watch the `partial-success` failure mode: under rule 8 the model may name a cause it can't support. Consider amending rule 8 to "state cause if known, otherwise state what's ruled out and the next diagnostic."
- Reuse `scripts/run_evals.py` + `judge.py` + `rubric.md` to A/B your own style or system prompts. Keep the config isolation flags and model pinning.

## Reusable Patterns

- **Pre-send deletion checklist** (announcing opener, recap/closer, sidebars, empty hedges, idioms) plus the "first line + last line" test.
- **Presentation-only caps.** Limit what's shown, never what's analyzed or retained.
- **Explicit rule-conflict precedence** (task > shape, harness > skill, safety > brevity) inside a style prompt.
- **Isolated A/B prompt evals** with a blind weighted judge, a per-condition budget, resumable rows, model pinning, and an absolute blocker gate you publish even when it fails.

---

**Attribution:** ayghri/i-have-adhd, MIT
