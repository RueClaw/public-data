# Pre-Install Agent Skill Security Scanner

**Source:** NVIDIA/SkillSpector  
**Repo:** https://github.com/NVIDIA/SkillSpector  
**License:** Apache-2.0  
**Reviewed:** 2026-06-20

## Pattern

Treat agent skills as installable trust packages and scan them before they enter an agent runtime. The scanner should understand both ordinary code risk and agent-specific risk: prompt injection, hidden metadata instructions, memory poisoning, excessive agency, tool misuse, MCP tool poisoning, underdeclared permissions, and dependency CVEs.

## Shape

```text
input artifact
  -> normalize into a local scan directory
  -> build file inventory, manifest, executable metadata, file cache
  -> run deterministic analyzers in parallel
  -> optionally use semantic review for filtering/enrichment
  -> emit machine-readable report, human summary, and policy decision
```

For packaged use, run the scanner in a dedicated environment or container:

```text
candidate artifact mounted read-only
  -> static scan by default
  -> optional provider credentials only for semantic analysis
  -> JSON/SARIF report written to a mounted output directory
```

## Why It Works

Agent skills blur documentation, prompts, configuration, and executable code. A useful scanner cannot look only for vulnerable dependencies or only for dangerous function calls. It needs to inspect:

- visible and hidden instructions in `SKILL.md`
- scripts shipped with the skill
- declared permissions versus observed capabilities
- tool metadata and parameter descriptions
- outbound network and environment-variable access
- persistence, self-modification, or broad trigger patterns
- dependency manifests and known advisories

The two-stage approach is practical. Deterministic analyzers provide fast, auditable candidate findings. Optional LLM analysis can reason about intent and filter noise, but the scanner still works when model calls are disabled.

## Implementation Notes

- Keep input resolution separate from scanning so remote Git/zip/single-file handling can be hardened independently.
- Build a complete file inventory first, including file type, line count, size, and executable markers.
- Preserve structured manifest fields, including tool parameters, so metadata-poisoning checks can inspect the same descriptions the agent runtime will see.
- Run analyzers as independent modules that return one normalized finding shape.
- Emit SARIF or another CI-native format so the scanner can gate publication or installation.
- Let semantic analyzers be optional and provider-configurable; skill content may be private or adversarial.
- Use live vulnerability intelligence where possible, but provide an offline fallback so air-gapped scans still produce a baseline result.
- Include fixtures for both malicious and clean skills, since false positives can make a scanner unusable.

## Caveats

Do not let the scanner become the only trust boundary. It should be one gate in a larger install policy that also includes code review, signed sources, sandboxed execution, scoped credentials, and runtime monitoring.

Remote input support needs normal supply-chain caution. Automated pipelines should prefer scanning artifacts already fetched through a controlled source process.

---

**Attribution:** Pattern extracted from NVIDIA/SkillSpector, Apache-2.0.
