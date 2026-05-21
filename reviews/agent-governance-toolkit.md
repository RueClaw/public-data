# Agent Governance Toolkit (microsoft/agent-governance-toolkit)

**Repo:** https://github.com/microsoft/agent-governance-toolkit
**License:** MIT - permissive reuse with attribution
**Reviewed:** 2026-05-20
**Stack:** Python, TypeScript, .NET, Rust, Go, GitHub Actions, MkDocs, OpenTelemetry-oriented governance components
**What it is:** A multi-language toolkit for runtime governance of AI agents: policy enforcement, identity/trust, sandbox/runtime control, MCP security scanning, audit/compliance, and reliability engineering.

---

## Verdict

📚 **Study the architecture; adopt selectively.** Agent Governance Toolkit is the broadest open agent-governance repo reviewed so far, with real code, specs, examples, CI, and Microsoft-signed preview packages. It is also sprawling and still preview-grade: the best value is in the pre-execution policy gate, MCP security scanner, audit chain, and trust-bound delegation patterns, not in adopting the entire stack wholesale.

---

## What It Is

Agent Governance Toolkit, or AGT, is an attempt to define an enterprise governance layer for autonomous agents. Its central premise is correct: prompt-level instructions are not enough for safety. Agent actions need deterministic policy checks before tool calls, resource access, inter-agent messages, and workflow steps execute.

The repository is not a single library. It is an ecosystem repo containing Python packages such as Agent OS, AgentMesh, Agent Runtime, Agent Hypervisor, Agent SRE, Agent Compliance, Agent Marketplace, RAG governance, MCP governance, sandboxing, and discovery; plus TypeScript, .NET, Rust, Go, GitHub Actions, examples, specs, and docs.

The project is explicitly marked Public Preview. That matters. The claims are ambitious: sub-millisecond policy decisions, zero-trust agent identity, execution rings, tamper-evident audit logs, OWASP Agentic Top 10 coverage, compliance mapping, and framework integrations. Some of this is implemented. Some of it is more platform vision than hardened default install.

## Stack

| Layer | Tech |
|-------|------|
| Core packages | Python packages under agent-governance-python |
| SDKs | TypeScript, .NET, Rust, Go |
| Policy | YAML/JSON policy documents, OPA/Rego backend, Cedar backend |
| Identity | Agent DID model, Ed25519 signing, trust/delegation models |
| Audit | Hash-chained/Merkle audit entries, CloudEvents serialization |
| MCP security | Tool-description scanning, rug-pull fingerprints, prompt-injection pattern detection |
| Reliability | Agent SRE SLOs, error budgets, circuit breakers, chaos concepts |
| CI/security | CodeQL, Scorecard, dependency review, secret scanning, SBOM, policy validation, fuzzing config |

## Key Features

### Pre-Execution Policy Engine

The cleanest core idea is action interception before execution. Agent OS evaluates structured context against policy rules and returns allow, deny, audit, or backend-derived decisions. It supports folder-scoped policy discovery, rule priority, fail-closed behavior on policy errors, and external OPA/Cedar backends.

This is more operationally useful than prompt-based "please do not call dangerous tools" safety. The policy check sits between the agent and the side effect.

### AgentMesh Identity and Trust

AgentMesh models agent identities as did:mesh identifiers with Ed25519 keys, sponsor metadata, capabilities, delegation depth, and trust policy checks. The best pattern is not the specific DID format; it is binding agent actions to identity, sponsor, delegation, and revocation state instead of treating all agent calls as one generic service account.

### MCP Security Gateway

The MCP scanner is a concrete, useful subsystem. It scans tool descriptions and schemas for hidden instructions, invisible Unicode, markdown/HTML comments, encoded payloads, exfiltration cues, privilege-escalation language, role override patterns, and rug-pull changes. This is directly relevant to the current MCP security problem: tools can carry prompt-injection payloads in metadata that users rarely inspect.

### Audit and Compliance

The audit layer uses hash chaining/Merkle structures for tamper-evident event logs and can serialize audit entries as CloudEvents. The compliance layer maps governance evidence toward regimes such as EU AI Act, SOC 2, HIPAA, GDPR, and NIST AI RMF.

The regulatory mapping should be treated as evidence organization, not automatic compliance.

### Agent SRE

Agent SRE reframes reliability around agent-specific failure modes: task correctness, tool-call accuracy, cost per task, cascading failures, silent degradation, and replay debugging. This is a strong conceptual contribution even if teams should start with a smaller slice than the full SRE package.

## Architecture

The repo is organized as an ecosystem:

| Path | Role |
|------|------|
| agent-governance-python/agent-os | Policy engine, kernel, MCP security scanner |
| agent-governance-python/agent-mesh | Identity, trust, governance, audit, protocol bridges |
| agent-governance-python/agent-runtime | Runtime/session control |
| agent-governance-python/agent-hypervisor | Execution rings, sessions, sagas, kill switch concepts |
| agent-governance-python/agent-sre | SLOs, error budgets, circuit breakers, cost/chaos concepts |
| agent-governance-python/agent-compliance | Compliance checks and evidence organization |
| agent-governance-typescript | TypeScript SDK |
| agent-governance-dotnet | .NET SDK and extensions |
| agent-governance-rust / agent-governance-golang | Rust and Go components |
| action/ | GitHub Actions for governance checks and attestations |
| examples/ | Framework examples and policy templates |
| docs/specs/ | Formal specs for policy, trust, runtime, SRE, audit, and protocol layers |

The repository has substantial process maturity: CODEOWNERS, security policy, DCO, CodeQL, Scorecard, secret scanning, dependency review, SBOM, fuzzing config, policy validation, docs workflows, and many examples. That does not make it turnkey, but it does make the project more credible than a typical governance-themed prototype.

## Comparison

| Aspect | Agent Governance Toolkit | Decapod | Deepsec | LiteLLM-style gateways |
|--------|--------------------------|---------|---------|------------------------|
| Primary focus | Runtime governance across agent systems | Repo-local AI coding governance | Agent-assisted vulnerability scanning | Model/provider routing |
| Enforcement point | Tool/action/message/workflow boundary | Coding-agent repo workflow | Security finding validation loop | Request routing and budgets |
| Best pattern | Deterministic pre-execution policy gate | Local governance kernel | Sandbox credential brokering and revalidation | Provider abstraction |
| Maturity | Broad public preview, many packages | Narrower, easier to reason about | Production-focused scanner | Production gateway, not agent governance |
| Adoption risk | High if adopting whole stack | Lower if adopting process pattern | Medium | Depends on gateway |

AGT is stronger than Decapod on runtime governance breadth, but Decapod is easier to understand and adopt because it stays local to coding-agent workflows. AGT is best mined for enforcement patterns before betting on it as a platform.

## Self-Hosting Notes

Do not start with the full ecosystem. Start with one control: policy evaluation before tool calls, MCP metadata scanning, or audit logging. Treat every package as preview until its install path, dependency set, and framework adapter are verified in your own environment.

Verification notes from review:

- Repository metadata: 1,666 stars, 315 forks, MIT license, pushed 2026-05-20.
- Source scale: roughly 1,791 Python files and 746 test-like files in the clone.
- Python compile check passed for agent-os and agent-mesh source trees.
- TypeScript production npm audit reported 0 vulnerabilities.
- TypeScript package npm install failed on a peer dependency mismatch between @typescript-eslint/eslint-plugin 8.59.3 and @typescript-eslint/parser 8.59.4.
- Copilot CLI package tests passed 6 checks, then failed because @microsoft/agent-governance-sdk was not installed/built in that package-local test context.

---

**Attribution:** microsoft/agent-governance-toolkit, MIT
