# Automating Eval Design and Hillclimbing with Claude (claude.dev blog + anthropics/skills claude-api)

**Source:** https://claude.dev/blog/automating-eval-design-and-hillclimbing/ (claude.dev blog, Playbooks)
**Author:** Lance Martin (Anthropic)
**Date:** 2026-09-28
**Backing repo:** https://github.com/anthropics/skills, `skills/claude-api/shared/evals/`
**License:** The article is Anthropic blog content (read and cite it, don't republish it). The `claude-api` skill directory ships its own `LICENSE.txt` (Apache-2.0), so the eval guides and the two Node scripts can be reused with attribution. The repo as a whole has no top-level SPDX license on GitHub, and other skills in it carry their own terms. Check the per-skill license before you copy anything else.
**Reviewed:** 2026-09-29 (anthropics/skills commit `8a1541c`, the 2026-09-28 "build-eval and hillclimb guides" update)
**Stack:** Markdown agent guides (`build-eval.md` 233 lines, `eval-hillclimb.md` 338, `eval-audit.md` 204, `cost-hillclimb.md` 441, `report/SCHEMA.md` 339) plus dependency-free Node ESM scripts (`runner-scaffold.mjs` 602 lines, `build-report-lite.mjs` 488 lines). They're invoked as `/claude-api build-eval` and `/claude-api hillclimb` in Claude Code.
**What it is:** A vendor playbook on building evals you can trust and optimizing against them without overfitting. It's packaged as two slash-command workflows inside Anthropic's `claude-api` skill.

---

## Verdict

✅ **Act on this: read the guides, not just the blog post.** The article is a readable summary of standard eval hygiene (production-shaped tasks, headroom, low variance, a validated grader, a train/test split, one change per round). The substance is in the skill files. They're unusually concrete and operational, they're Apache-2.0, and most of them don't depend on Claude Code or Anthropic models.

What's good:
- **The procedure is concrete, not just principles.** There are two mandatory human sign-offs (inputs, grader). Before the first paid call you run oracle and null answers through runner+grader and expect ~100% and ~0%. The judge gets adversarial probes (empty string, "I don't know", a confident answer to the wrong question). You compare a noise floor (`~1/sqrt(n·reps)` for pass rates) against headroom before round 1. The split is stratified by random draw, never by baseline score, which the guide explains as regression to the mean.
- **The data-isolation design is real.** The outer session sees only scores. A fresh analyzer subagent reads *train* transcripts only. Ground truth has to be structurally unreachable from the model under test, including via public solution mirrors when the agent has web access.
- **Failure accounting is explicit.** Every failed attempt gets a failure class (refusal / harness-or-serving error / timeout / genuine), and harness errors go to an `errors.jsonl` sidecar instead of scoring as 0. Resume is idempotent at `(case, rep)`. Billed-but-failed spend is still counted as spend.
- **"Stall → categorize" step.** After 2–3 flat rounds, the loop stops editing content and buckets the remaining failures (artifact gap / grader disagreement / harness / structural / variance). This is the part most homemade loops lack.
- **The scripts are defensively written.** The runner refuses symlinked output paths (`O_NOFOLLOW`), and it hashes itself plus `harness_paths` and exits 2 until a human re-runs it with `--approve-harness`. The lite report builder HTML-escapes case text (verified below).

What gives pause:
- **The headline results are vendor-reported, on internal benchmarks you can't reproduce.** The customer-support example runs on 44 tickets (30 search, 14 held out). The held-out claim is 90.5% vs 78.6%. Those percentages are 38/42 vs 33/42, so it looks like 3 reps. By the guide's own rule of thumb (`1/sqrt(14·3)` ≈ ±15 points), that ~12-point gain is **inside the noise floor**, unless a paired analysis the post doesn't show tightens it. The cost reduction (≈5×) is more robust than the accuracy claim, and much of it comes from the model/pricing change, not the hillclimb.
- **The claude-api skill example (66% → ~88%) gives no held-out number.** Some of that gain came from fixing graders and rewording tasks mid-loop. The guide itself says that's legitimate but that it requires re-grading every earlier variant, and the post doesn't show that re-grading.
- **It's heavy.** About 1,500 lines of guidance get pulled into context for one command, and the process assumes an interactive user who answers `AskUserQuestion` prompts. Headless runs fall back to "one short question at a time", which doesn't really work unattended.
- **The full report viewer (`build-report.mjs` + frontend) is not shipped.** Only the lite builder is.
- **Product placement.** The cost example ends at "move to a newer/cheaper Claude tier". The technique is general, but the demo is also a pricing pitch.

---

## What It Is

The post has three parts:

1. **Eval design principles.** The four marks of a good eval: tasks mirror production; scores rise with stronger models and more effort; there's headroom at the frontier that isn't explained by broken tasks; run-to-run variance is low. It also warns against **adversarial sampling**: picking cases because *today's* model fails them measures that model's failure fingerprint, not what's hard for the application.
2. **`/claude-api build-eval`.** Claude interviews the user and sources inputs in priority order (production transcripts after retention/PII questions → bug reports/tickets → 5–10 hand-written cases → cases synthesized from the codebase and anchored on real ones). It proposes the cheapest adequate grader (programmatic → pairwise blind → pointwise rubric of checkable claims → human spot-check), pilots it, runs diagnostics (grader determinism, plumbing, saturation above ~95%), and reports a baseline with a CI.
3. **`/claude-api hillclimb`.** The user picks a goal (raise a metric, or cut cost/latency while holding quality) and an editable surface (system prompt, skill files, tool descriptions, model/effort/params, harness code). Each round makes one root-cause patch. The patch is kept only if train *and* test improve, and reverted on train-only gains or on any regression. The loop ends at the best test-scoring version with CIs, and recommends against merging if the gain is within noise.

## Stack

| Piece | What it is |
|-------|------------|
| `build-eval.md` | Interview-driven eval construction, sign-off gates, runner contract, cost estimation from pilot `usage` only |
| `eval-audit.md` | Health checklist: task design, harness, metrics hygiene, grader design (incl. LLM judge), detectability (§5), how to report findings (§6) |
| `eval-hillclimb.md` | The loop: prerequisites (Step 0/0.5), goal/scope, stopping rule, state layout, analyzer isolation, stall categorization, final report |
| `cost-hillclimb.md` | Cost-goal variant: caching health → prompt audit → model × effort staircase → prompt climb on frozen model → pre-registered adoption gates |
| `report/runner-scaffold.mjs` | Node runner template: `--variant/--model/--reps/--timeout-s`, resume, jittered backoff, served-model assertion, harness sha gate, `errors.jsonl` |
| `report/build-report-lite.mjs` | Static `report.html` + `trajectory/scores.tsv` from the `baseline/`, `vN/` tree; no dependencies |
| On-disk contract | `.claude/hillclimb/<flow>/{_state.json, baseline/, v1/…}`, each with `results.jsonl`, `traces/<id>_rep<k>.json`, `change.md`, `change.patch` |

## Key Features

### Grader validation before trust
Claude grades a handful of cases and asks the user "would you have scored any of these differently?" If the answer is yes for even one case, the rubric isn't ready. Rubrics are written as checkable claims, not 1–5 scales. The judge must not be the model under test, and pairwise judging randomizes A/B order and freezes the baseline outputs on disk so "win rate" keeps the same meaning across rounds.

### Noise-aware loop control
Before round 1, the noise floor, the headroom, and the smallest improvement worth shipping go side by side. If the noise floor is larger than the effect you care about, the guide tells you to add reps or cases rather than spend rounds. Changes must be big enough to show above the noise (fix the root cause, don't reword a line). A plateau needs K ≥ 3 flat rounds.

### Overfitting defenses
- A random, stratified train/test split, fixed once.
- The analyzer only ever reads train traces. The outer session reads no transcripts at all.
- "Generalize, don't memorize": never paste nouns from failing cases into the prompt.
- Ground truth is kept out of the model's reach structurally, and passing transcripts are screened for fetches of benchmark solution mirrors.

### Build-variance check
If the tuned artifact *builds* something stochastic (a memory store, an index) that then gets scored, you rebuild the baseline 2–3 times with no change and use that spread as the floor. Adding more reps over a single build can't reveal it. The guide cites a climb where three identical builds spanned ~7 points against ~±1.4 rescore noise. This is a subtle point and a useful one.

## Architecture

It's all prompt-level orchestration: the markdown guides are the program, and Claude Code is the interpreter. The only executable parts are the runner scaffold, which you copy into your repo and fill in `loadCases`/`runCase`/`gradeCase`, and the report builder. Loop state lives entirely on disk (`_state.json`, per-variant directories, a rewritten `narrative.md`), so an interrupted session can resume without chat history. The eval command runs as one background shell call, not a subagent. The only subagent is the per-round analyzer.

## Security

- **Harness integrity gate:** the runner hashes itself, any lockfile, and `_state.json.harness_paths`. It refuses to run after an unapproved change until a human passes `--approve-harness`. The guide is candid that this only *detects* changes and that the real boundary is the session allowlist entry for the runner command.
- **Symlink refusal** on all output writes (`O_NOFOLLOW` on POSIX, lstat on Windows). The comment's rationale is that a prompt-injected round could plant `results.jsonl -> ~/.bashrc`.
- **Untrusted case text:** the guides forbid hand-rolled HTML for reviewing inputs sourced from tickets or logs. Case text goes through the report builder, which escapes it, or stays in markdown.
- **Report builder location pinning:** only run `build-report*.mjs` from the extracted skill directory, never a same-named file found in the project, because the builder runs unattended every round.
- **PII/retention:** you ask about retention and PII *before* pulling production data. The options are ID-only storage with fetch-at-runtime, user-side anonymization, or synthetic rewrites the user reviews.

## Maturity

This landed in `anthropics/skills` on 2026-09-28 as part of a larger `claude-api` skill update, the day before this review. The repo is very popular (~179k stars, ~21k forks, 1,382 open issues), but the eval guides themselves are brand new. There are no tests for the Node scripts in the repo.

### Validation on 2026-09-29

- Cloned `anthropics/skills` at `8a1541c` and read `build-eval.md`, `eval-hillclimb.md`, `eval-audit.md` (§5–6) and the heads of `runner-scaffold.mjs` and `build-report-lite.mjs`.
- Built a synthetic flow directory: 12 cases, 8 train / 4 test, 2 reps, `baseline` + `v1` with `change.md`, one `status: "truncated"` row, and a case prompt containing `<script>alert(1)</script>`. Then ran `node build-report-lite.mjs flow/`:
  - Exit 0. Output: "2 variants, 12 cases", plus `report.html` (10 KB) and `trajectory/scores.tsv`.
  - The injected script tag appears only HTML-escaped (`&lt;script&gt;`), with 0 raw occurrences. The escaping claim holds.
  - The truncated row was counted in the "truncated" column and left out of the means.
  - I recomputed the headline independently from `results.jsonl`: baseline 0.500 / test 0.375, v1 0.792 / test 0.500. That matches the report exactly. Note that these are **macro averages of per-case means** over status-ok reps, not pooled per-row rates. My pooled rate for the baseline test split was 0.429. Keep this in mind if you compare against your own numbers.
- Not run: `runner-scaffold.mjs` needs user-supplied case, run and grade functions plus live API calls. Neither of the post's benchmarks is public, so **none of the post's numbers were reproduced**.
- Arithmetic check on the reported results: 74.4/87.8/88.9/98.9% are consistent with k/90 (30 tickets × 3 reps), and 90.5/78.6% with 38/42 and 33/42 (14 × 3). By the guide's own ±`1/sqrt(n·R)` rule, the held-out gain is within noise.

## Comparison

| | claude-api build-eval/hillclimb | DSPy optimizers | promptfoo | Hand-rolled eval loop |
|---|---|---|---|---|
| Unit of change | Any surface (prompt, skill, tools, params, harness code), one patch per round | Prompt/demos/program params | None (eval runner, no optimizer) | Whatever you edit |
| Overfitting guard | Mandated train/test split, analyzer sees train only | Train/dev split in API | N/A | Usually none |
| Grader validation | Mandatory human sign-off + adversarial judge probes | Metric is user code | Assertions + LLM rubric | Rarely |
| Runs unattended | Poorly (built around interactive sign-offs) | Yes | Yes (CI) | Yes |
| Model lock-in | Guides are general. Examples, pricing tables and SDK calls are Anthropic's | None | None | None |
| License | Apache-2.0 (skill dir) | MIT | MIT | — |

## Self-Hosting Notes

- You don't need Claude Code to benefit. `eval-audit.md` and `eval-hillclimb.md` Step 0.5/4.5 work as a checklist for any agent framework, and the on-disk contract (`results.jsonl` + `traces/` + `baseline/` / `vN/`) is framework-neutral. Variant directory names must be exactly `baseline` or `v<N>`, or the report builder silently skips them.
- `build-report-lite.mjs` needs only Node (or Bun) and no npm install. Drop it next to your eval to get a static, sortable, escape-safe per-case report.
- For Python-only projects, the guide says to port the runner's properties rather than install Node: rep-aware resume, backoff, a wall-clock ceiling, a failure sidecar, and the harness gate.

## Reusable Patterns

- **Oracle/null pre-flight:** run the reference answers (expect ~100%) and constant or empty outputs (expect ~0%) through the full runner+grader before spending money.
- **Judge probe triad:** empty string, "I don't know", and a confident answer to the wrong question must all fail.
- **Keep/revert rule:** keep only if train↑ and test↑; revert on train-only gains or any regression; treat train↓/test↑ as noise until it repeats.
- **Stall categorization buckets:** artifact gap / grader disagreement / harness-infra / structural / variance, each with a different fix.
- **Build-variance floor:** rebuild the generated artifact K times with no change before trusting a one-edit delta.
- **Cost estimates from pilot `usage` only**, with cache writes at 1.25× and reads at 0.1× input. The guide says historical-log estimates are routinely off by 2–4×.

---

**Attribution:** Article by Lance Martin, claude.dev blog (Anthropic), 2026-09-28. Guides and scripts from anthropics/skills `skills/claude-api`, Apache-2.0.
