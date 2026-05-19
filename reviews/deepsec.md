# deepsec (vercel-labs/deepsec)

**Repo:** https://github.com/vercel-labs/deepsec
**License:** Apache-2.0; permissive for use, modification, redistribution, and pattern extraction with attribution.
**Reviewed:** 2026-05-19
**Stack:** TypeScript, Node.js 22+, pnpm, Vitest, Biome, Vercel Sandbox, Vercel AI Gateway, Claude Agent SDK, OpenAI Codex SDK, regex matcher registry
**What it is:** deepsec is an agent-powered vulnerability scanner for large codebases. It uses fast regex matchers to identify candidate security-relevant files, then sends batched code context to coding-agent backends for expensive vulnerability investigation, revalidation, reporting, and optional distributed sandbox execution.

---

## Verdict

✅ **Deploy candidate for serious security review workflows, with cost controls.** deepsec is not a toy wrapper around an LLM: it has a staged scan/process/revalidate/enrich/export pipeline, durable per-file records, extensive matcher coverage, plugin hooks, PR-mode scanning, and a thoughtful sandbox model for high-concurrency agent work. The main caveat is operating cost and blast radius: full scans intentionally run high-reasoning agents with broad source access, so teams should start with scoped PR mode, small limits, and sandboxed execution before trusting whole-repo runs.

---

## What It Is

deepsec is a security harness for finding vulnerabilities in existing codebases using coding agents. The first stage is cheap static scanning: built-in and custom regex matchers flag candidate files and security-relevant snippets. The expensive stage batches those files into prompts for Claude or Codex-style agent backends, asks for structured findings, writes those findings into durable JSON records, and can later revalidate, triage, enrich, report, or export them.

The design target is large repositories. Runs are resumable: every file has a `FileRecord`, work is claimed atomically, and re-running a command skips completed work while appending new analysis history. For large monorepos, deepsec can partition work across Vercel Sandbox microVMs and merge the resulting data back into the local `.deepsec/data/` tree.

The repo also ships as a tool meant to be installed into the target repository's own `.deepsec/` workspace. That workspace carries configuration, project context, custom matchers, and optional plugins while keeping generated findings and run data gitignored by default.

## Stack

| Layer | Tech |
|-------|------|
| CLI/package | TypeScript, Node.js 22+, pnpm workspace, bundled `deepsec` npm package |
| Core schema | Zod schemas for file records, findings, runs, revalidation, triage |
| Scanner | Glob/minimatch plus a large TypeScript matcher registry |
| Processor | Claude Agent SDK and OpenAI Codex SDK backends |
| Distributed execution | Vercel Sandbox snapshots, tarball upload/download, partitioned workers |
| Configuration | `deepsec.config.ts`, project `INFO.md`, per-project `config.json`, plugins |
| Quality | Vitest unit/e2e tests, Biome, Knip, TypeScript builds, pinned GitHub Actions |

## Key Features

### Staged, Durable Pipeline

The pipeline is `scan -> process -> revalidate -> enrich -> export/report/metrics`. Each stage reads and writes a consistent on-disk data model. That makes expensive AI work resumable and auditable instead of a one-shot terminal transcript.

### Matcher-Anchored Agent Investigation

The scanner includes broad matcher coverage across JavaScript/TypeScript, Python, Go, Ruby, PHP, JVM, Rust, Terraform, Kubernetes, mobile manifests, MCP handlers, prompt leaks, CI workflows, SSRF, SQL injection, auth bypass, secret exposure, and more. Matchers do not replace agent review; they provide anchors and prioritization for the agent prompt.

### PR Mode

`process --diff`, `--diff-staged`, `--diff-working`, `--files`, and `--files-from` let deepsec review only changed files. This is the practical entry point for CI: scoped, cheaper, and easier to gate than a whole-repo scan.

### Sandbox Credential Brokering

For distributed worker scans, real AI credentials stay on the orchestrator host. Sandboxes receive placeholder tokens, and the Vercel Sandbox network policy injects the real Authorization header at egress for the selected AI host. This reduces the impact of prompt injection or compromised code running inside the worker VM.

### Plugin Architecture

Plugins can contribute matchers, notifiers, agents, ownership lookups, people directories, or executor behavior. That keeps the public package generic while letting organizations layer in internal ownership, notification, and policy context.

## Architecture

```text
source repo
   |
   v
scan: regex matchers -> FileRecord candidates
   |
   v
process: batch candidate files + INFO.md -> agent findings
   |
   v
revalidate/triage/enrich -> verdicts, priority, committers, ownership
   |
   v
export/report/metrics -> markdown, JSON, PR comment, aggregate counts
```

The strongest architectural decision is the per-file data model. One source file maps to one JSON `FileRecord`, and every stage adds to it rather than destructively replacing prior work. That enables crash recovery, multi-worker partitioning, reruns with different models, and later review of analysis history.

The main operational risk is that deepsec asks powerful coding agents to inspect large amounts of source. The repository acknowledges this directly: treat deepsec like a coding agent with shell access, run it on trusted inputs, and prefer sandbox mode when worried about prompt injection or dependency-controlled content.

## Comparison

| Aspect | deepsec | Semgrep | CodeQL | LLM-only review script |
|--------|---------|---------|--------|------------------------|
| Detection approach | Matcher-anchored agent investigation | Static rules | Semantic/static queries | Agent prompt only |
| Large-repo resumability | Per-file records and run history | Yes, tool-managed | Yes, database/query model | Usually weak |
| Customization | Matchers, plugins, INFO.md | Rules | Queries/packs | Prompt edits |
| Cost | Potentially high for process/revalidate | Low | Low/medium | Variable |
| Best fit | Deep review of security-relevant surfaces and PR deltas | Known pattern detection | Mature static analysis | Small ad hoc reviews |

## Self-Hosting Notes

Install into the target repository:

```bash
npx deepsec init
cd .deepsec
pnpm install
pnpm deepsec scan
pnpm deepsec process
pnpm deepsec revalidate
pnpm deepsec export --format md-dir --out ./findings
```

For PR-style review:

```bash
deepsec process --diff origin/main
```

Local verification on 2026-05-19:

- `pnpm install --frozen-lockfile`: completed, with an expected warning about the `deepsec` bin before bundling.
- `pnpm test:unit`: 28 files passed, 2,100 tests passed.
- `pnpm test:bundle`: bundle succeeded, 23 e2e tests passed.
- `pnpm lint`: Biome checked 326 files, no fixes needed.

---

**Attribution:** vercel-labs/deepsec, Apache-2.0
