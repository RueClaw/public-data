# Sandbox Credential Brokering For Agent Workers

**Source:** vercel-labs/deepsec
**Repo:** https://github.com/vercel-labs/deepsec
**License:** Apache-2.0
**Reviewed:** 2026-05-19

## Pattern

When running coding-agent workers inside disposable sandboxes, keep real provider credentials on the orchestrator host. Put only recognizable placeholder tokens inside the worker environment, restrict worker egress to the selected provider host, and inject the real Authorization header at the sandbox network-policy layer.

## Why It Matters

Agentic security tools often ask an LLM-powered coding agent to inspect untrusted or dependency-heavy source trees. If the worker has real API keys in environment variables, prompt injection or malicious code can try to read and exfiltrate those credentials. deepsec reduces that exposure by ensuring the worker process can initialize SDKs with placeholder credentials while the real token is added only as traffic leaves the sandbox boundary.

## Implementation Shape

```text
orchestrator host
  real AI token
      |
      | creates sandbox env with placeholder token
      v
worker sandbox
  agent SDK sees placeholder credential
  egress limited to selected AI host
      |
      | network policy transform
      v
AI provider request with real Authorization header
```

Key details:

- Placeholder values are deliberately recognizable and not provider-shaped secrets.
- The worker egress allowlist is backend-specific: Claude workers do not also get OpenAI host access, and vice versa.
- Header injection is attached to the allowed provider host rule.
- Extra hosts are explicit additions, not ambient network access.
- The same sandbox path also disables nonessential telemetry where supported.

## When To Use

Use this for:

- Agent workers processing untrusted source code.
- Distributed code review or security scanning.
- Browser/computer-use workers that need provider credentials but should not be able to read them.
- Any sandbox where an SDK insists on a token at construction time even though the boundary can broker credentials later.

Do not treat this as the only control. It should be paired with source tarball exclusions, no `.git` upload when history is not needed, per-host egress allowlists, short-lived sandboxes, and careful handling of downloaded artifacts.

## Source Files

- `packages/deepsec/src/sandbox/setup.ts` — brokered credential resolution, placeholder environment, and network policy header injection.
- `packages/deepsec/src/__tests__/credential-brokering.test.ts` — tests that real tokens do not appear in sandbox env.
- `packages/deepsec/src/__tests__/network-policy.test.ts` — tests provider-host allowlisting and Authorization injection.

---

**Attribution:** vercel-labs/deepsec, Apache-2.0
