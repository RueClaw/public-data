# Sealed Agent Trajectory Judge

**Source:** https://github.com/cosmtrek/mindwalk
**License:** MIT
**Extracted:** 2026-07-19

## Pattern

When using an LLM to evaluate an agent session, treat the session trace as untrusted input and run the evaluator as a sealed text function. The evaluator may read a normalized evidence document and return structured findings, but it must not receive tools, project settings, MCP servers, session persistence, or authority to inspect the local machine.

## Shape

1. Normalize raw session logs into a bounded event trace.
2. Build a judge input from task wording, deterministic stats, and per-event summaries.
3. Start evaluation only from an explicit user action.
4. Run the judge subprocess in a neutral working directory.
5. Disable tools, MCP, browser, shell, hooks, user config, memory, and session persistence where the CLI allows it.
6. Require structured JSON output with findings anchored to real event IDs.
7. Reject findings without valid evidence references.
8. Compute verdicts mechanically from normalized severities instead of letting the LLM assign final grades.
9. Cache reports with prompt version and input digest so stale reports can be detected.

## Why It Matters

Agent logs often contain prompt-injection material, command output, file paths, and user task text. A naive "ask another agent to review this session" flow can accidentally give that injected text access to local tools or project instructions. Sealing the judge preserves the benefit of semantic review while keeping the evaluator on the right side of the trust boundary.

## Reference Snippet

mindwalk's Codex judge runner illustrates the posture:

```go
return []string{"exec",
  "--ephemeral",
  "--ignore-user-config",
  "--ignore-rules",
  "--disable", "shell_tool",
  "--disable", "browser_use",
  "--disable", "apps",
  "--disable", "plugins",
  "--disable", "hooks",
  "--disable", "multi_agent",
  "--disable", "memories",
  "-c", "include_apply_patch_tool=false",
  "-c", `web_search="disabled"`,
  "--sandbox", "read-only",
  "--skip-git-repo-check",
  "-C", workdir,
}
```

The important detail is not the exact flag list, which will vary by harness. The invariant is that the evaluated trace is data, not authority.

## Reuse Notes

- Keep raw logs separate from judge input; summarize and bound first.
- Include deterministic stats so the judge does not infer counts from prose.
- Reject malformed severities instead of silently downgrading them.
- Cite only event IDs that exist in the trace.
- Mark reports stale when prompt version, input digest, event count, or user-turn count changes.
- Be explicit that cloud-backed judge CLIs may send the summary off-machine.

---

**Attribution:** Pattern extracted from cosmtrek/mindwalk, MIT.
