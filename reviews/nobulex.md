# Nobulex (arian-gogani/nobulex)

**Repo:** https://github.com/arian-gogani/nobulex
**License:** MIT - permissive reuse with attribution
**Reviewed:** 2026-05-17
**Stack:** TypeScript monorepo, Node.js, npm workspaces, Vitest, tsup, MCP, LangChain/A2A adapters
**What it is:** A proof-of-behavior and Trust Capital protocol for autonomous agents. It tries to turn agent reputation into a deterministic score derived from signed behavioral commitments, hash-chained action logs, and verifier-side policy checks.

---

## Verdict

📚 **Study the protocol shape; do not treat the repo as production-ready yet.** Nobulex has a good central idea: autonomy should be earned from verifiable behavior, not granted because an agent exists. The codebase has real tests and useful protocol docs, but the current monorepo has public API drift: npm test and npm run build pass locally, while npm run typecheck fails across SDK/CLI/MCP/A2A/LangChain packages because those packages import exports that @nobulex/core no longer exposes.

---

## What It Is

Nobulex is an agent governance protocol and TypeScript implementation built around behavioral covenants. An agent declares what it is allowed to do, actions are checked against those covenants, and execution history is recorded as tamper-evident evidence that another party can verify.

The repo's language is economic: agents earn Trust Capital through compliant receipts. That score gates future autonomy levels, transaction limits, sensitive access, delegation rights, and unsupervised operation. The useful part is not the branding; it is the explicit model of reputation as a function of compliance rate and evidence depth.

The repository includes a TypeScript monorepo, protocol docs, examples, a CLI package, MCP server package, SDK, LangChain and A2A adapters, a website, observatory docs, conformance fixtures, and a draft proof-of-behavior specification.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js 18+/20, TypeScript |
| Monorepo | npm workspaces |
| Core protocol | Ed25519-oriented signatures, SHA-256 hashes, CCL/covenant language, action logs, Merkle/proof modules |
| Agent integrations | MCP server, LangChain adapter, A2A agent-card extension, Claude Agent SDK adapter |
| Build/test | tsup, TypeScript, Vitest, fast-check property tests |
| Distribution | npm packages under @nobulex/*, Dockerfile, GitHub Actions |
| Docs | README, threat model, proof-of-behavior spec, EU AI Act/NIST mapping, IETF draft |

## Key Features

### Trust Capital Ledger

The standout primitive is a reputation score that combines compliance rate with depth of verified history. The tier system is deliberately conservative: an agent cannot jump straight to high trust with a tiny perfect sample.

The current implementation defines tiers from restricted to autonomous, capability sets per tier, and minimum receipt counts for each tier. This is a good pattern for any agent platform that wants graduated autonomy instead of binary allow/deny.

### Behavioral Covenants

The covenant language is a small policy layer with permit, deny/forbid, require, and limit semantics. The docs emphasize deny-wins, default-deny, and monotonic narrowing for delegated covenants.

That is the right direction for agent control. It keeps enforcement at the action boundary, where concrete tool calls and resources can be checked, rather than trying to audit internal model reasoning.

### Cross-Agent Verification Handshake

The SDK contains a proof-of-behavior handshake concept: verify covenant signature, proof signature, log integrity, compliance, minimum history, required covenant, audience binding, and task class before transacting.

The idea is strong, especially the audience and task-class binding. Trust should be scoped: trusted for payment settlement is not the same as trusted for admin access.

### Documentation and Threat Model

The repo includes a real threat model with explicit non-goals: no key revocation yet, no library-level rate limiting, no formal verification of the CCL evaluator, no third-party audit, no HSM/KMS integration, and privacy limitations because evidence records are not encrypted.

That candor is useful. It keeps the protocol discussion from pretending cryptographic receipts solve key custody, availability, revocation, or privacy by themselves.

## Architecture

The repo is organized as a TypeScript monorepo with these major surfaces:

| Package | Purpose |
|---------|---------|
| @nobulex/core | Covenant lifecycle, CCL, identity, crypto wrappers, proof, verification, stores, trust capital |
| @nobulex/sdk | Higher-level proof/handshake/middleware/client surface |
| @nobulex/cli | Scaffold, verify, inspect, and report on covenant action logs |
| @nobulex/mcp-server | MCP compliance server wrapper |
| @nobulex/langchain | LangChain-style audit/receipt integration |
| @nobulex/a2a | A2A behavioral evidence extension |
| @nobulex/claude-agent-sdk | Claude Agent SDK compliance hook |

The main architectural issue is package boundary drift. Local tests pass because the test setup can exercise source modules directly, and tsup can bundle without full type checking for several packages. Full workspace type checking fails because packages import symbols such as generateKeyPair, ActionLogBuilder, verifyIntegrity, sha256String, createDID, parseSource, EnforcementMiddleware, and ValidationError from package surfaces where they are missing, type-only, renamed, or not exported.

That does not invalidate the protocol idea, but it means the repo currently needs API consolidation before consumers should depend on the package set as a stable SDK.

## Comparison

| Aspect | Nobulex | Decapod | Ruflo |
|--------|---------|---------|-------|
| Primary problem | Agent proof-of-behavior and earned autonomy | Repo-local governance gates for coding agents | Multi-agent orchestration and plugin ecosystem |
| Enforcement target | Agent actions, receipts, covenants, trust scores | Coding workflow boundaries, validation evidence, proof artifacts | Agent/team execution, hooks, skills, memory, federation |
| Strongest idea | Trust score derived from signed behavioral history | Callable governance loop around inference and completion | Signed regression witnesses and install-surface split |
| Current risk | Monorepo package API drift and failing typecheck | Governance artifacts may become ceremony | Broad alpha surface and large install blast radius |

## Self-Hosting Notes

For local development: clone the repo, run npm ci, then run npm test -- --config vitest.config.ci.ts and npm run build.

Local verification on 2026-05-17:

| Check | Result |
|-------|--------|
| npm ci | Succeeded, with deprecation warnings for older consolidated @nobulex/* packages |
| npm test -- --config vitest.config.ci.ts | Passed: 75 files, 2,818 tests |
| npm run build | Passed |
| npm run typecheck | Failed across SDK/CLI/MCP/A2A/LangChain due missing or mismatched exports |
| npm audit --omit=dev | Reported 6 production vulnerabilities: 1 high, 5 moderate |

The typecheck failure is the operational blocker. Treat this as a protocol and pattern source until package exports and consumer-facing examples line up with the current core API.

---

**Attribution:** arian-gogani/nobulex, MIT

