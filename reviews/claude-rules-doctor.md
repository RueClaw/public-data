# claude-rules-doctor (nulone/claude-rules-doctor)

*Review #264 | Source: https://github.com/nulone/claude-rules-doctor | License: MIT | Author: nulone | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥

---

## What It Is

Linter for `.claude/rules/*.md` `paths:` globs. Detects rules that are silently dead — specified path globs that match zero files in your project. One job, does it well.

```bash
npx claude-rules-doctor check --root .
```

## The Problem It Solves

Claude Code's `paths:` frontmatter in rules files scopes a rule to only certain files. If your globs are wrong (typo, stale after a refactor, wrong cwd assumption), the rule silently does nothing. No error, no warning, just... ignored. This catches that.

## Output Taxonomy

- ✅ **OK** — global rule (no paths) or globs match ≥1 file
- ⚠️ **WARNING** — rule misconfigured: invalid YAML, empty `paths: []`, non-string values in paths, or invalid glob pattern
- ❌ **DEAD** — paths specified, 0 files match

## Architecture

~400 lines TypeScript, four modules:
- `parser.ts` — glob-discovers `.claude/rules/**/*.md`, extracts YAML frontmatter with regex + `yaml` lib
- `checker.ts` — runs each `paths:` entry through `glob` (cwd=project root), collects matches, classifies result
- `reporter.ts` — colored terminal output or `--json`
- `cli.ts` — thin commander wrapper, `--ci` flag exits 1 on dead rules

Notable: glob runs with `ignore: ['node_modules/**', '.git/**']` and `nodir: true`. Nothing clever, nothing surprising — that's appropriate for a tool this focused.

## Gaps

- No `--fix` mode (can't update stale globs automatically — would need heuristics)
- No watch mode for editor integration
- Doesn't validate that glob patterns are intentional vs accidentally global (e.g., `**/*.ts` matching 10,000 files is probably wrong)
- No support for `globs:` key (alternate frontmatter key some tools use)

## Relevance

Direct: we have `.claude/rules/` at `~/.claude/rules/` (8 files seeded 2026-03-25) and on ODR. After any project refactor, rules with `paths:` will silently break. This is a one-liner CI check that catches it.

Worth wiring into ODR's CI as:
```yaml
- run: npx claude-rules-doctor check --ci
```

Mentioned in awesome-claude-code. Companion to `cclint` (schema validation) — different concerns, both useful together.

Install: `npm install -g claude-rules-doctor` or just `npx claude-rules-doctor check`
