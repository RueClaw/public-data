# vision (kunchenguid/vision)

**Repo:** https://github.com/kunchenguid/vision
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-08-18
**Stack:** Agent Skill Markdown, HTML/CSS review-board template, `npx skills`, `lavish-axi`
**What it is:** A single-purpose agent skill for mining a repository's history, drafting a `VISION.md` as an acceptance policy, stress-testing it with hard hypotheticals, and iterating with the project author through an interactive review board.

---

## Verdict

✅ **Deploy candidate for project-vision and contribution-policy work.** This is a small, sharp skill with the right core discipline: it refuses to invent values, grounds every principle in real PRs or commits, and treats vision as a testable acceptance policy rather than brand copy. The caveats are real but manageable: it is a one-commit skill package, has no tests/CI, shells out through `npx -y lavish-axi`, and the HTML template requires careful escaping of generated card content.

---

## What It Is

`kunchenguid/vision` packages one Agent Skill named `vision`. Its job is to help a project author write a `VISION.md` that future humans and agents can use to judge whether a proposed change belongs in the project.

The workflow is evidence-first. The agent checks for an existing `VISION.md`, mines merged PRs or default-branch commit history, builds a private evidence sheet, drafts a 40-70 line vision, then generates 8-12 hard hypotheticals that test the vision's fault lines. The author answers those hypotheticals on a shipped review-board UI, and each answer maps to traced edits.

The repo is intentionally tiny: a README, MIT license, one `SKILL.md`, and two board assets. There is no app backend, package manifest, or runtime code beyond the static review-board template.

## Stack

| Layer | Tech |
|-------|------|
| Skill | Markdown `SKILL.md` |
| Distribution | `npx skills add kunchenguid/vision` |
| Evidence sources | GitHub CLI / gh-axi, git commit history |
| Review loop | `npx -y lavish-axi` |
| Review UI | Static HTML template plus CSS |
| Tests/CI | None visible |

## Key Features

### Evidence Over Vibes

The skill's strongest rule is that every principle must trace to concrete evidence: merged PRs, commits, files, docs, or recorded author answers. If real history is unreadable, the skill stops instead of inventing values.

That is the right boundary for this task. A project vision generated from generic ideals is worse than no vision because it gives future contributors and agents false authority.

### Delta Mode for Existing Visions

If a default-branch `VISION.md` already exists, the skill switches to delta mode. It treats the existing file as the approved baseline and proposes evidence-backed line edits rather than writing a competing document.

That avoids a common agent failure mode: replacing a human-approved artifact because the model can write a smoother new one.

### Hard Hypotheticals

The skill requires 8-12 concrete change proposals that hit real fault lines: tempting off-mission features, principle collisions, slippery slopes, scope expansions, and identity questions. Each hypothetical must steelman both sides and be replaced if the answer is predictable.

This is the best part of the design. The author does not approve a static draft in the abstract; they make decisions under pressure, and those decisions become calibration material.

### Shipped Review Board

The review loop uses a fixed `review-template.html` and `review.css`. The draft stays visible on the left; one hypothetical card appears on the right; verdicts are queued back through `lavish-axi`.

The UI is not just decoration. It enforces the skill's process: latest draft always visible, one decision at a time, both-sided steelman in view, and recorded reasoning for each verdict.

## Architecture

The repo's architecture is mostly instruction design:

- `skills/vision/SKILL.md` is the full agent contract.
- `skills/vision/assets/review-template.html` is a fill-in-place board template with JavaScript for markdown rendering, card navigation, verdict capture, and `window.lavish.queuePrompt`.
- `skills/vision/assets/review.css` is the fixed house style.

The skill is self-contained and host-agnostic. It assumes the host agent can read a repo, run `gh`/`git`, copy the board assets, invoke `npx -y lavish-axi`, and wait for queued verdicts.

The main technical risk is the generated board. The draft renderer escapes markdown lines, but card fields are inserted into `innerHTML` from generated JavaScript object values. A careful agent can escape them, but the template does not enforce that boundary by itself.

## Comparison

| Aspect | vision | Foundry | Compound Engineering Plugin | Tufte Claude Skill |
|--------|--------|---------|-----------------------------|--------------------|
| Primary role | Project vision and acceptance policy | Durable software-work process | Full agent-engineering workflow | Chart design discipline |
| Runtime weight | Low, plus `lavish-axi` review board | Low | Medium-high | Low |
| Best pattern | Evidence-mined principles plus hypotheticals | File-backed staged work | Guardrails-not-choreography planning | Decision table plus kill list |
| Validation | `skills add ./ -l` discovery works; no tests | Tests/CI | Large test suite | Static skill review |
| Main caveat | One commit, no tests, review-board escaping risk | Process weight | Workflow overlap | Narrow chart domain |

`vision` is closest to Foundry in spirit: it creates durable project policy from real work rather than chat residue. It is much narrower than Compound Engineering, which is a benefit if the only job is "make the project direction legible."

## Self-Hosting Notes

Discovery smoke test from a local clone worked:

```text
npx --yes skills add ./ -l
Found 1 skill: vision
```

Normal install:

```bash
npx skills add kunchenguid/vision -g
```

Operational notes:

- The skill needs readable repository history. For private repos, the local agent's GitHub/git access becomes part of the trust boundary.
- The review loop runs `npx -y lavish-axi`, so users should be comfortable executing that package in the target environment.
- Treat generated review-board content as untrusted until escaped, especially if hypothetical text quotes issue titles, commit messages, or PR content.
- There is no committed automated test suite or CI workflow.

---

**Attribution:** kunchenguid/vision, MIT, https://github.com/kunchenguid/vision
