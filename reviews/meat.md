# meat (boldsoftware/meat)

**Repo:** https://github.com/boldsoftware/meat
**License:** Apache-2.0
**Reviewed:** 2026-08-03
**Stack:** Go 1.24, OpenAI Responses API, Anthropic Messages API, git CLI, optional exe.dev managed LLM gateway
**What it is:** meat is a small Go CLI that turns a normal code diff into a "reading diff": a shorter, source-derived diff meant to keep the conceptually important parts of agent-written code while eliding imports, boilerplate, repeated call sites, noisy test scaffolding, and mechanical churn.

---

## Verdict

✅ **Deploy candidate for code-review assistance, with privacy caveats.** The core design is unusually good: the model does not author the displayed diff. It proposes line-coordinate edit operations against an immutable unified diff, then a local compiler validates and renders the final reading diff mechanically. That makes meat much more trustworthy than a free-form "summarize this diff" wrapper.

Do not treat it as a replacement for reading the full diff on risky changes. It sends diffs, and sometimes surrounding repository files, to the selected model or gateway; its local cache may also store sensitive abridgements under `~/.meat`.

---

## What It Is

meat answers a specific problem created by agent-written code: the raw diff can be long, repetitive, and hard to review, while a prose summary loses too much source detail. Its output stays shaped like a unified diff, but hides low-value rows so the reviewer can see behavior, architecture, and algorithm choices faster.

Typical use:

```bash
go install meat.dev/cmd/meat@latest
meat
meat HEAD~3..HEAD
git diff --staged | meat
```

The CLI defaults to `git show` of `HEAD`, accepts a revision or range, can read staged/worktree changes, and can read a diff from stdin. Interactive output follows git-like colors and pager behavior; `-json` produces machine-readable output for bots or CI.

## Architecture

The most important boundary is:

```text
raw unified diff
  -> validate and number original lines
  -> model receives rubric + read-only tools
  -> model submits remove / replace / fold plan
  -> local compiler validates plan
  -> local renderer emits source-derived reading diff
```

The model-visible tools are deliberately narrow:

- `read_file` reads UTF-8 files relative to the repo root, with optional line ranges.
- `grep` runs `git grep` inside the repo root.
- `preview_plan` validates a complete proposed plan and reports retention feedback.
- `submit` accepts the final plan plus a one-line summary.

The compiler owns the hard invariants. It removes imports automatically, rejects invalid or overlapping ranges, checks that single-line replacements are true elisions of the original source, folds contiguous same-polarity hunk lines into generated ellipsis rows, enforces exact-move symmetry, validates supported diff structure, and computes the elision manifest locally.

Large diffs are handled structurally. A single run is capped around 400 KiB; larger diffs are split at file boundaries, then hunk boundaries, then synthesized sub-hunks as a last resort, with a 4 MiB total cap and 32 chunk cap. Chunking preserves well-formed unified diffs and pre-resolves whole-diff properties, but it does reduce cross-chunk judgment.

## Provider and Runtime Notes

meat has no third-party Go module dependencies in the reviewed checkout. It talks directly to OpenAI or Anthropic over HTTP, selected by model name:

- default model: `gpt-5.6-sol`;
- Anthropic selected by model IDs beginning with `claude-` or `anthropic/claude-`;
- `MEAT_MODEL` overrides the model;
- `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `ANTHROPIC_API_KEY`, and `ANTHROPIC_BASE_URL` configure providers;
- on exe.dev VMs, an attached `llm` integration can provide a managed gateway without local provider keys.

Results are cached by SHA over the diff text, model id, and rubric/compiler protocol hash. That is a good reproducibility detail: changing the prompt surface, model, or diff misses the cache.

## Strong Ideas

### LLM Edit-Plan Compiler Boundary

The model is not trusted to write final review output. It can only ask for source-derived transformations that the local compiler can verify. This is the main pattern worth reusing anywhere an LLM edits, redacts, or compresses trusted source artifacts.

### Frozen Prompt Surface Hash

The cache key includes a hash of the static prompt/tool surface and compiler protocol. Prompt changes become explicit cache invalidations instead of silently mixing old and new behavior.

### Review-Oriented Diff Semantics

The prompt is opinionated about what reviewers need: behavior, data flow, contracts, architecture, compatibility, security-relevant choices, and representative examples. It explicitly deprioritizes style-only churn, import lists, default git context, repetitive fixtures, and generated-looking boilerplate.

## Risks and Caveats

- Privacy: diffs and model-requested repository files can leave the machine through the configured model provider or gateway.
- Cache sensitivity: cached results under `~/.meat` can include source-derived content and should be treated like code review artifacts.
- Freshness: the repository is very new, with no tags observed at review time.
- Dependency on model quality: the compiler prevents many classes of hallucinated output, but the choice of what to hide is still model judgment.
- Review scope: a reading diff is a triage aid, not an assurance artifact. Security-sensitive or subtle semantic changes still need the full diff, tests, and domain review.
- Pager behavior: interactive rendering uses the user's configured git pager through `sh -c`, matching git behavior but inheriting the trust assumptions of local pager config.

## Validation Notes

Reviewed checkout:

```text
f39f41dfe7b5b37a12b35fdfbaecc7e779855bd3 add LICENSE
```

Local validation:

```text
go test ./...
ok  	meat.dev/cmd/meat	0.864s
ok  	meat.dev/meat	0.722s
```

No git tags were present in the reviewed checkout.

---

**Attribution:** boldsoftware/meat, Apache-2.0
