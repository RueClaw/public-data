# SkillSpector (NVIDIA/SkillSpector)

**Repo:** https://github.com/NVIDIA/SkillSpector
**License:** Apache-2.0, permissive reuse with attribution
**Reviewed:** 2026-05-31
**Stack:** Python 3.12+, LangGraph, Typer, Rich, Pydantic, YARA, OSV.dev, OpenAI/Anthropic/NVIDIA-compatible LLM providers
**What it is:** A security scanner for AI agent skills that checks skill bundles before installation, combining static rules, AST/taint checks, YARA signatures, MCP-specific checks, OSV dependency lookups, and optional LLM review.

---

## Verdict

✅ **Deploy candidate for pre-install skill screening.** SkillSpector is exactly aimed at a real gap: agent skill bundles are executable trust packages, and most agent runtimes still treat them too casually. It is young, but the implementation is coherent, Apache-2.0, well tested, and already covers the right categories for a first-pass gate.

---

## What It Is

SkillSpector scans a local directory, single `SKILL.md`, zip, raw URL, or Git repository and emits terminal, JSON, Markdown, or SARIF reports. Its threat model is specific to AI-agent skills: prompt injection in metadata, data exfiltration, privilege escalation, supply chain issues, excessive agency, memory poisoning, tool misuse, rogue-agent behavior, MCP least privilege, MCP tool poisoning, and dependency CVEs.

The architecture is a LangGraph workflow: input resolution, context building, parallel analyzers, optional LLM filtering/enrichment, then report generation. That is a good fit for a scanner because deterministic passes can run quickly while semantic passes remain optional and provider-selectable.

The project is still alpha-classified in `pyproject.toml`, and there are signs of active internal TODOs around analyzer discovery and service mode. But the repo is not just a paper demo: it has a broad test suite, fixtures for malicious and clean skills, SARIF output, and documentation for extending analyzers.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Typer, Rich |
| Workflow | LangGraph |
| Models | Pydantic, dataclasses |
| Static scanning | Regex analyzers, AST analyzer, YARA rules |
| Dependency intelligence | OSV.dev via `httpx` |
| Semantic analysis | OpenAI, Anthropic, NVIDIA build endpoint, OpenAI-compatible local endpoints |
| Outputs | Terminal, JSON, Markdown, SARIF |
| Tests | Pytest, pytest-asyncio |

## Key Features

### Agent-Skill Threat Taxonomy

The strongest part is the domain-specific taxonomy. SkillSpector does not just scan Python for dangerous calls; it models prompt injection, memory poisoning, output handling, rogue agent persistence, MCP tool metadata poisoning, and least-privilege mismatches. That makes it a better fit for agent package review than a generic SAST-only tool.

### Two-Stage Analysis

The scanner runs deterministic analyzers first, then optionally uses an LLM meta-analyzer to filter and enrich findings. This is the right shape for a noisy security domain: fast high-recall rules produce candidates, while semantic review can reduce false positives when credentials and model access are available.

### CI-Friendly Outputs

SARIF support matters. A scanner like this is most useful when it can become a required check before skills are installed, published, or promoted. JSON and Markdown outputs make it usable in local review and documentation pipelines.

### Real Test Surface

Verification on 2026-05-31 with Python 3.12 passed:

```text
598 passed, 11 skipped, 22 deselected
```

That is unusually solid for a fresh agent-security repo. The tests cover input resolution, CLI behavior, SARIF, static patterns, semantic analyzer plumbing, MCP checks, graph integration, and report generation.

## Architecture

The main workflow is compact:

```text
resolve_input -> build_context -> parallel analyzers -> meta_analyzer -> report
```

`resolve_input` normalizes Git URLs, file URLs, zips, single files, and directories into a local directory. `build_context` walks files, builds a file cache, parses `SKILL.md` frontmatter, and records executable-file metadata. Analyzer nodes append findings through the LangGraph state reducer. `meta_analyzer` optionally calls an LLM per file or chunk. `report` computes a score, risk band, recommendation, and selected output format.

The biggest design win is keeping analyzers as independent graph nodes. Adding a detector is mostly a registration problem: implement a node that returns findings, add it to `ANALYZER_NODE_IDS`, and the graph fans it out automatically.

## Comparison

| Aspect | SkillSpector | Generic SAST | Dependency scanner |
|--------|--------------|--------------|--------------------|
| Agent metadata attacks | First-class | Usually absent | Absent |
| Executable script risk | Yes | Yes | No |
| MCP metadata/tool poisoning | Yes | No | No |
| CVE lookup | OSV.dev | Sometimes | Primary focus |
| CI output | SARIF/JSON/Markdown | Often | Often |
| Maturity | Alpha but tested | Varies | Often mature |

SkillSpector should complement, not replace, broader scanners. It catches agent-skill failure modes that Bandit, Semgrep, npm audit, or pip-audit are not designed to see.

## Self-Hosting Notes

Use Python 3.12 or 3.13. A Python 3.14 install attempt hit a transitive `jsonschema-rs`/PyO3 compatibility failure through the LangGraph CLI dependency path, even though the project declares `>=3.12` with no upper bound. Python 3.12 installed cleanly and ran the test suite.

For privacy-sensitive scans, run `--no-llm` or point the OpenAI-compatible provider at a local endpoint. The static checks and OSV lookup remain useful without sending skill content to a hosted model. If using live OSV lookup, allow outbound HTTPS to `api.osv.dev`.

Treat Git URL and remote zip scanning as networked input handling. For automated pipelines, prefer scanning already-fetched artifacts from a controlled checkout rather than letting the scanner fetch arbitrary URLs directly.

---

**Attribution:** NVIDIA/SkillSpector, Apache-2.0
