# Context Doctor (michal-franc/context-doctor)

**Repo:** https://github.com/michal-franc/context-doctor
**Author:** Michal Franc
**License:** MIT; retain the copyright and permission notice when redistributing substantial source portions.
**Reviewed:** 2026-10-31 (UTC)
**Revision:** `764159eb52170a138b6e29ab141ed8fae09e01ea`, default branch `master`; whole repository, focusing on CLI, rules, reference traversal, reporting, templates, tests and CI. Commit dated 2026-10-24.
**Verification:** Static source review only. No build, upstream tests, installation, model calls, or real-user context/transcript processing.
**Stack:** Go (module requires 1.25.4), standard library, gopkg.in/yaml.v3 v3.0.1, embedded YAML rules and Markdown templates.
**What it is:** A local, deterministic linter for coding-agent instruction files, not an LLM-powered context optimizer or a session-trace doctor.

## Verdict

⚠️ **Interesting — useful advisory lint, not proof of better agent performance.** The small offline architecture, inspectable rules, reference graph and JSON reports make this a reasonable optional maintenance tool. Its scores encode opinionated text heuristics, not measured correctness or instruction compliance. Configure it for the actual harness, keep fixes human-reviewed, and isolate scans of untrusted repositories because linked Markdown can escape the target tree.

## What It Is

Context Doctor discovers CLAUDE.md and AGENTS.md in a directory, or analyzes an explicitly supplied file. It checks length, estimated instruction count/density, generic advice, formatter-style rules, progressive disclosure, missing/stale referenced documentation and repeated instruction text. It also detects stack marker files and suggests appropriate starter templates when no context file exists.

The advertised self-reinforcing loop is an external coding agent running the CLI, reading its report, and editing files. The binary itself does not invoke an agent, rewrite context, repair files, compact conversations, measure token usage, or evaluate downstream task success. “Fix any issues” is workflow advice, not an implemented autofix mode; autofix and conflict detection remain open feature requests.

## Stack

| Layer | Implementation |
|---|---|
| Entry point | Standard Go flags and filesystem/Git discovery in main.go |
| Rule engine | 38 embedded YAML rules; comparison, substring, regex, list and boolean-composition predicates |
| Configuration | Root .context-doctor.yml/.yaml; suppressions, orphan ignores and agent-root declarations |
| Extensions | Automatically discovered *_rules.yaml/yml and rules.yaml/yml in the file directory and .context-doctor/ |
| Context graph | Recursive local Markdown reference resolution, lexical-path visited set, Git dates with reference mtime fallback |
| Reporting | Terminal text and structured JSON, per-file dimensions and separate repository structure penalty |
| Dependencies | One declared external module, yaml.v3 v3.0.1 (marked indirect despite direct imports); go.sum present |

## Key Features

### Inspectable policy rather than a hidden judge

The rule catalog is easy to inspect and extend without a provider account. Primary-only rules distinguish instruction entry points from referenced human-facing documentation. Suppression and explicit agent roots are important escape hatches for knowledge repositories and deliberately layered context.

### Repository and reference visibility

Git-backed discovery includes tracked and untracked nonignored context files. Non-Git fallback walks skip hidden directories, node_modules and vendor; that is not equivalent to full gitignore semantics. References are followed recursively, with missing targets, age and secondary-rule findings reported. Orphan reporting inventories other Markdown filenames; it does not make every Markdown file an agent input.

### Structured reports, but no automatic enforcement

JSON separates files, references, duplicates, structureIssues and summary. Filters affect violation lists rather than recomputing scores/counts. Ordinary lint findings do not cause a failing exit status. CI must parse the appropriate single-file or repository schema, including structureIssues and any desired reference findings. Also inspect command success and valid JSON: analyzeFile prints an analysis error then returns without a nonzero exit, and repository mode can skip failed files while reporting the rest. A report is not necessarily proof of complete coverage.

## Architecture

main.go discovers files and config, loads embedded plus custom rules, reads content, builds metrics, resolves references, adds stack/activity information, evaluates primary and secondary rules, then formats results. rules/actions.go is a fixed registry of data predicates, not an arbitrary shell action system. templates/ embeds starter text; suggestions are printed, not written to disk.

This decomposition is straightforward and substantially tested in source, although the CLI/report orchestration remains a roughly 1,100-line main.go. Invalid custom-rule files warn and continue; unknown actions return false and invalid regex patterns can be silently skipped. Since problem rules use a match to mean a violation, malformed policy may disappear from findings rather than fail closed. Treat repo-owned rules and suppression config as policy inputs requiring review, not an independent security authority.

## Diagnostic Methodology: What the Numbers Actually Mean

- **Instruction count is a lexical estimate.** Imperative English prefixes and sufficiently long bullet/numbered lines are counted, without Markdown AST, code-fence exclusion, semantic intent or tokenizer. It can count examples as instructions and miss non-English or paraphrased directives. Text reporting adds a hard-coded “+50 Claude” even though AGENTS.md is supported.
- **Thresholds are hand-set.** The catalog flags over 100/300 lines and over 50/100 estimated instructions; density flags require more than 20 lines and over 50%/80% directives. Stronger and weaker rules can both fire. Whitespace and rephrasing can change scores without improving behavior.
- **Scores are a rubric, not accuracy.** Dimensions start at 100, subtract 15/5/2 for error/warning/info matches and add 5 for positive rules, then clamp. Overall weights are correctness 40%, style 20%, compliance 20%, freshness 20%. “Correctness” mostly means structural checks; “compliance” is not observed model compliance.
- **Freshness is mostly age.** Git file age maps to 100 within seven days and zero after a year; missing Git history yields 75. A separate staleness rule considers scope activity, but the numerical freshness component still penalizes old, potentially correct instructions. Reference age falls back to mtime, so copying files and shallow history affect interpretation.
- **Duplicates are normalized text, not contradictions.** The implementation lowercases and strips leading bullets, compares imperative-looking lines of at least 15 characters, and does not reason about scope or meaning. It cannot establish that two instructions conflict.
- **Single-root policy is optional opinion.** Multiple nonexempt context files incur CD060 and a 30-point repository penalty. Hierarchical AGENTS.md/CLAUDE.md layouts can be intentional; use agent-roots or suppress this rule rather than consolidate automatically.

The README cites HumanLayer guidance and Lost in the Middle as motivation for lean context. Neither establishes the exact rule weights, universal 150–200 instruction ceiling, or predictive validity of this score for current models/harnesses. No controlled before/after task benchmark, compliance dataset, false-positive calibration or token/cost improvement experiment was found in the reviewed tree. Example “bad” and “good” reports demonstrate the rubric, not independent improvement. Tests of the engine establish expected software behavior, not causal gains in coding quality.

## Privacy, Filesystem and Execution Boundaries

**Local by design:** inspected runtime source contains no model/provider SDK, HTTP client/server, telemetry transport, account login or credential lookup. It reads the target files, discovered rule/config files, recursively referenced Markdown, filesystem metadata/stack markers, and local Git listings/history. No transcript-directory ingestion was found. Auth/CORS are inapplicable to a CLI with no service endpoint. Build-time dependency/toolchain downloads and manual binary acquisition are separate network boundaries.

**Read-only is not root-confined:** rules/refs.go joins reference paths to the current file directory, allows ../ traversal, follows os.Stat/os.ReadFile symlinks, and has no repository-containment check. gitignore restricts discovery, not explicit linked-file reads. Its visited set uses absolute lexical paths, not resolved symlink identity; no explicit depth, file-size or total-byte budget is present. A malicious or simply expansive reference tree can cause out-of-tree reads or excessive work. These are static code findings, not reproduced exploits.

**Reports can carry sensitive data:** duplicate records include instruction text and filenames; custom rules supply messages, suggestions and links. There is no redaction layer. Keep reports private unless reviewed, and do not treat source-controlled report prose as trusted instructions when handing it to an agent. Scanning is local, but a subsequent hosted coding-agent interaction may upload report/context content under that agent's own provider settings.

**Subprocess boundary:** Git is invoked with argument arrays, not shell-concatenated commands; runtime source does not execute build/test commands mentioned in context. Git still inherits the process environment and local configuration, and calls lack explicit deadlines. Use a trusted Git executable and a secret-free, read-only sandbox with only intended files mounted for untrusted scans. The standalone CLI is not a sandbox.

**Modification boundary:** normal analysis and template suggestion paths do not write project files. Installation targets copy/chmod binaries; external agents implementing suggestions can edit anything their own permissions allow. Never automatically delete safety constraints merely to raise a score.

## Correctness Caveats Worth Testing Before Adoption

1. Reference extraction uses several overlapping regexes, not a Markdown parser. A docs/ suffix inside a longer link can become an extra target; upstream issue #38 independently reports this false-positive class. Common Markdown forms outside the regex grammar may be missed.
2. Orphan detection iterates immediate fa.Refs and uses ref.Path rather than a fully normalized flattened resolved graph. Nested linked documentation and references relative to nested context files can therefore be mislabeled orphaned.
3. Primary duplicate accumulation does not deduplicate a repeated line within that file before checking for two entries; “cross-file” duplicate results can include a same-file repeat. Shared references can also be counted repeatedly across separately analyzed roots in repository totals.
4. Primary dimension scores do not directly aggregate secondary-document rule findings; reports expose more than the headline score. Inspect detailed findings instead of ranking repositories by score.

These observations follow the implementation at the pinned revision. They were not dynamically validated; they are concrete test targets, not claims of an exercised exploit or a measured failure rate.

## Maturity, License and Verification

Public GitHub metadata retrieved 2026-10-31 showed 18 stars, one fork, 16 open issues, creation on 2026-01-17 and last push on 2026-10-24. These are adoption/activity signals, not quality evidence. The newest listed release was v0.3.3, published 2026-05-29; reviewed master is explicitly marked unreleased after v0.3.3. Do not assume a latest-release binary contains all reviewed features.

The tree contains 92 top-level Go Test functions covering predicates, scoring, config, references, discovery-related helpers, templates and JSON contracts. CI builds, lints and runs make test (go test -v ./...). Tests were inspected, not executed; coverage percentage and present CI success were not independently verified. No install, dependency vulnerability scan, release-binary verification, real-user data scan or agent-performance evaluation was performed.

README source prerequisites and release workflow still say/use Go 1.21 while go.mod requires 1.25.4; CI correctly reads go.mod. Automatic toolchain selection may bridge this, but the published prerequisite is stale. Release automation builds Linux/macOS amd64/arm64 and Windows amd64 binaries; actions use mutable major tags and the workflow has no explicit signing/attestation step. Pin a revision/release and verify artifact provenance rather than blindly following latest-download-and-sudo examples.

The actual root LICENSE is MIT, copyright 2026 Michal Franc. yaml.v3 is a separate dependency with its own upstream terms; no dependency code was copied or license/vulnerability audit performed. This review extracts no source components.

## Comparison

| Need | Context Doctor | Better complement or alternative |
|---|---|---|
| Offline instruction-file hygiene | Specialized rule catalog and repo graph | markdownlint / Vale for general Markdown and prose policy; less agent-specific |
| Correct nested-context behavior | Configurable single-root preference, regex reference traversal | Harness-native context-loading documentation plus human scope review |
| Prove an edit improves agent outcomes | No task evaluation | Inspect AI or a small held-out task suite with baseline/candidate runs and cost/quality tracking |
| Reduce live-session payloads | No interception or compaction | Context Governor addresses proxy/context payload handling; a different operational problem |
| Detect semantic conflicts or injection | No semantic/security guarantee | Human review and a dedicated threat-model-aware scanner/evaluator |

Related public reviews: [Inspect AI](inspect-ai.md), [Context Governor](context-governor.md), and [Harper](harper.md). These comparisons distinguish problem scope, not benchmark superiority; no head-to-head test was run.

## Self-Hosting Notes

There is no server to host, database, provider subscription or GPU requirement. If trialing the CLI, begin with a pinned source revision or verified binary and synthetic fixtures, not private home-directory context. Match build tooling to go.mod. Use advisory JSON reports first; independently validate complete analysis before enabling CI gates. Declare intentional agent roots, tune suppressions, inspect recursive reads, and retain human review of proposed edits. Measure real task outcomes separately before calling score increases an optimization.

## Evidence Map

All source links below are pinned to the reviewed revision:

- [README and claims](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/README.md)
- [CLI discovery, analysis, exit paths and orphan reporting](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/main.go)
- [Rule catalog](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/builtin.yaml), [engine](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/engine.go), [predicates](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/actions.go)
- [Reference traversal](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/refs.go), [duplicates](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/crossfile.go)
- [Dimensions](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/dimensions.go), [freshness](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/freshness.go), [JSON contract](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/report_json.go)
- [Config](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/config.go), [custom-rule loader](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/rules/loader.go)
- [Module](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/go.mod), [MIT license](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/LICENSE), [CI](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/.github/workflows/ci.yml), [release workflow](https://github.com/michal-franc/context-doctor/blob/764159eb52170a138b6e29ab141ed8fae09e01ea/.github/workflows/release.yml)
- Public [releases](https://github.com/michal-franc/context-doctor/releases), [reference false-positive issue #38](https://github.com/michal-franc/context-doctor/issues/38), [autofix request #10](https://github.com/michal-franc/context-doctor/issues/10), [conflict detection request #9](https://github.com/michal-franc/context-doctor/issues/9).

---

**Attribution:** Michal Franc / michal-franc/context-doctor, MIT. Independent analysis; no source-code extraction.
