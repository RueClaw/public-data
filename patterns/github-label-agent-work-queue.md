# GitHub Label Agent Work Queue

**Source:** [gherghett/ClaudeCodePSymphony](https://github.com/gherghett/ClaudeCodePSymphony)
**License:** package.json declares ISC; no root LICENSE file detected
**Extracted:** 2026-07-25

## Problem

Small teams often already manage work in GitHub Issues. Adding a separate queue database, workflow engine, or issue tracker just to run coding agents adds operational weight. The missing piece is a simple way to mark which issues are ready, claimed, under human review, back for rework, or done.

## Pattern

Use mutually exclusive labels as the agent work queue state:

```text
symphony/todo          ready for agent work
symphony/in-progress   claimed by an orchestrator
symphony/human-review  agent opened a PR or reached handoff
symphony/rework        human wants another pass
symphony/done          terminal state; workspace can be cleaned
```

Then build a small poller:

1. Poll open issues with active labels.
2. Normalize issue title, body, labels, URL, and timestamps into an internal issue model.
3. Sort by priority labels such as `priority:1` or `P1`, then by age.
4. Claim by removing any existing `symphony/*` label and adding `symphony/in-progress`.
5. Create a deterministic workspace path from the issue identifier.
6. Render a repo-owned workflow prompt with issue context.
7. Run the agent in that workspace.
8. Let the agent move the issue to `symphony/human-review`, or let a human move it to `symphony/rework` or `symphony/done`.
9. Reconcile running work by checking current labels and stopping workers when issues leave active states.

## Why It Works

GitHub labels are visible, scriptable, and already part of issue workflows. A label-backed queue gives operators a low-friction control surface: move an issue into `todo`, watch it become `in-progress`, review the PR at `human-review`, then mark it `done` or `rework`.

This is less durable than a real job queue, but it is good enough for single-orchestrator prototypes and keeps the source of truth close to the issue.

## Minimal Version

```text
poll:
  gh issue list --state open --json number,title,body,state,labels,url
  candidates = issues where labels contains todo or rework

claim(issue):
  remove labels matching symphony/*
  add symphony/in-progress

run(issue):
  workspace = root / sanitize("owner/repo#123")
  prompt = render(WORKFLOW.md, issue)
  run agent in workspace

handoff:
  agent or human sets symphony/human-review

cleanup:
  when symphony/done or closed, remove workspace
```

## Implementation Notes

- Label claims are not atomic unless you add an external lock or compare-and-swap step. Do not run multiple pollers against the same label set without handling races.
- Treat issue bodies as untrusted input. They are prompt content, not instructions with authority over credentials or host state.
- Use least-privilege GitHub tokens. Most agents only need issue/PR/contents permissions for one repo.
- Keep workflow hooks short and reviewed. Raw shell hooks are deployment scripts.
- Separate "agent produced a valid PR" from "work is done"; the `human-review` state is the useful handoff boundary.
- Clean workspaces only after an explicit terminal state, not merely after the agent exits.

## Good Fits

- single-repo coding-agent experiments
- small team agent queues
- prototypes before adopting a larger control plane
- GitHub-native repos that already use issue labels
- human-reviewed PR workflows

## Poor Fits

- multi-tenant hosted agent platforms
- public issue trackers without strict token and sandbox boundaries
- multiple independent orchestrators without locking
- compliance-sensitive deployments that need durable audit trails
- unreviewed shell hooks or broad write tokens

---

**Attribution:** gherghett/ClaudeCodePSymphony, package.json declares ISC; no root LICENSE file detected.
