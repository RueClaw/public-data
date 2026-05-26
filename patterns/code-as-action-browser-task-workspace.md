# Code-as-Action Browser Task Workspace

**Source:** https://github.com/microsoft/Webwright
**Author:** Microsoft
**License:** MIT
**Extracted:** 2026-05-26
**Type:** Architecture pattern

## Pattern

For browser agents, make the durable output a workspace full of code and evidence rather than a hidden browser transcript. The agent should solve the task by writing an executable script, running it from scratch, saving screenshots and logs, and checking every requirement against those artifacts before claiming success.

This pattern is useful for long-horizon browser tasks, data extraction, recurring web reports, QA automation, site research, and any workflow where "the agent clicked around and answered" is not enough.

## Core Shape

1. **Plan the task as critical points.** Convert every explicit filter, date, sort, selection, and required datum into a checklist item.
2. **Use the browser as an environment, not memory.** Let the agent inspect pages and screenshots, but keep durable state in files.
3. **Write an executable final script.** The final artifact should rerun the workflow from scratch with stable selectors and explicit waits.
4. **Persist exploration and final-run artifacts.** Store generated steps, logs, screenshots, output JSON, and final responses in a predictable run directory.
5. **Capture evidence per critical point.** Every important constraint should have a screenshot, log line, structured assertion, or extracted value proving it.
6. **Verify before completion.** A task is not done until the final script has run cleanly and the evidence covers the checklist.
7. **Make failure repairable.** If verification fails, create a new run folder, adjust the script, rerun, and preserve the prior failed attempt.

## Why It Works

Browser-agent failures are often invisible. A model may click the wrong filter, misread a result, rely on stale page state, or answer from an intermediate page. A code-as-action workspace gives reviewers something concrete to inspect:

- the exact script used,
- the visible UI state at each important step,
- the action log,
- the final extracted data,
- and the failed attempts that led to the working version.

It also turns one-off browsing into maintainable automation. The script can be rerun, parameterized, scheduled, tested, or handed to a human engineer.

## Useful Design Details

- Keep all generated files inside a task-scoped workspace.
- Use monotonically numbered `final_runs/run_<id>/` folders.
- Put `final_script.py`, `final_script_log.txt`, and screenshots in each final run.
- Avoid full-page screenshots when viewport evidence is enough; giant screenshots are harder to inspect.
- Prefer role, label, and accessibility selectors over brittle CSS class chains.
- Log every constraint-relevant action in human-readable text.
- Save task metadata in JSON so rendered reports and verification tools can consume it.
- Treat self-verification as a completion gate, not as an optional polish step.
- Separate disposable exploration steps from the final rerunnable script.

## When To Use

Use this pattern when:

- a browser task may need to be rerun,
- the result needs reviewable evidence,
- a workflow has multiple filters or exact constraints,
- a browser task feeds a report, dashboard, or downstream automation,
- an agent should create a reusable tool rather than a one-shot answer.

## Cautions

- This pattern does not sandbox generated code. Run it with workspace and browser-profile boundaries appropriate to the trust level.
- The final script can still be brittle if it uses weak selectors or site-specific timing assumptions.
- Visual verification is evidence, not proof. Pair screenshots with structured assertions where possible.
- Persistent browser sessions are convenient but can hide state; final scripts should reconstruct task state from scratch unless persistence is the explicit requirement.

## Attribution

This pattern is derived from Microsoft's Webwright repository, especially `skills/webwright/SKILL.md`, `src/webwright/environments/local_workspace.py`, `src/webwright/environments/local_browser.py`, and the `final_runs/run_<id>/` verification contract.
