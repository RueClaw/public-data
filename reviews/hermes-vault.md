# Hermes Vault (asimons81/hermes-vault)

**Repo:** https://github.com/asimons81/hermes-vault
**License:** MIT - permissive reuse with attribution
**Reviewed:** 2026-05-24
**Stack:** Python 3.11, Typer, Rich, SQLite, cryptography, Pydantic, PyYAML, MCP SDK, requests
**What it is:** Hermes Vault is a local-first encrypted credential broker for AI agents and developer tools. It scans for plaintext secrets, imports credentials into an encrypted SQLite-backed vault, gates access through per-agent policy, verifies credentials, exposes an MCP server, and ships a local operator dashboard.

---

## Verdict

✅ **Deploy candidate for local agent credential brokering, with one repo hygiene caveat.** The security model is unusually concrete for a young credential tool: policy-gated service actions, ephemeral env materialization, no raw secret exposure in dashboard/MCP metadata paths, OAuth PKCE, refresh handling, backup verification, and a sizeable test suite. The biggest observed issue is developer-platform hygiene: the repository contains both docs/ARCHITECTURE.md and docs/architecture.md, which collide on case-insensitive filesystems such as default macOS.

---

## What It Is

Hermes Vault is built for local agent operators who need a safer way to give autonomous tools access to API keys and OAuth tokens. Instead of letting agents search dotfiles or ask for re-authentication whenever a credential is missing, it provides a central local vault with explicit broker decisions.

The core workflow is: scan managed paths for plaintext secrets, import supported values from env files or JSON, encrypt them in a local SQLite database, grant agent-specific access through a YAML policy, and provide credentials as short-lived environment variables when policy allows. It also verifies credentials against providers before recommending re-authentication, which is a practical answer to a common agent failure mode.

The project has expanded beyond the CLI into an MCP server and a token-guarded local dashboard. The dashboard intentionally stays on localhost and returns metadata/action results rather than raw secrets, making it an operator console rather than a browser-based secret viewer.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Typer, Rich |
| Runtime | Python 3.11+ |
| Storage | SQLite plus local salt/key material |
| Crypto | cryptography |
| Config/policy | YAML, Pydantic models |
| Agent integration | MCP server over stdio |
| OAuth | PKCE, callback server, provider registry, refresh engine |
| Dashboard | Localhost HTTP server with packaged static assets |
| Tests | pytest |

## Key Features

### Policy-Gated Credential Brokering

The broker checks agent identity, service allowance, action permissions, TTL ceilings, verification requirements, and raw-secret policy before returning anything useful. The preferred path is ephemeral environment materialization rather than direct raw-secret reads.

This is the strongest pattern in the repo: credentials are not merely encrypted at rest; they are mediated at use time.

### Secret Scanning and Conservative Import

The scanner detects common AI/dev tokens and reports plaintext secret findings, duplicates, and policy classifications. The env importer is deliberately conservative: broad database URLs, passwords, app/session secrets, public client config, and unknown names are skipped unless explicitly mapped.

That conservative import posture is the right default for a tool that may be used around sensitive local developer environments.

### MCP and Dashboard Surfaces Without Raw Secret Display

The MCP server exposes tools such as credential metadata, ephemeral env retrieval, verification, rotation, scanning, OAuth login, and OAuth refresh. Recent versions also expose read-only resources for service, health, and policy metadata. The dashboard follows the same boundary: inventory, health, policy findings, audit activity, MCP status, recovery posture, and safe dry-run operations without displaying credential payloads.

### OAuth Lifecycle Support

The OAuth implementation includes PKCE login, provider registry, callback handling, token exchange, refresh-token storage, proactive refresh, and migration/normalization of older OAuth metadata. The design pays attention to alias scoping, metadata sanitization, and refresh-token pairing.

## Architecture

The code is organized around small service modules under src/hermes_vault/:

- vault.py owns encrypted persistence, credential records, metadata, rotation, backup, and master-key rotation.
- policy.py loads and normalizes agent policy, including legacy compatibility and per-service action gates.
- broker.py enforces policy decisions and wraps vault/verifier/scanner operations.
- mcp_server.py exposes broker capabilities to MCP hosts with optional allowed-agent binding.
- scanner.py and detectors.py classify plaintext findings and env import decisions.
- oauth/ owns PKCE, state, callback, exchange, provider registry, normalization, and refresh.
- dashboard.py and dashboard_static/ implement the local operator console.

The notable design decision is the separation between encrypted storage and brokered access. The vault can store secrets, but the broker decides whether a caller gets raw access, ephemeral env materialization, verification, rotation, or only metadata. That separation makes it easier to reason about policy and audit behavior.

## Comparison

| Aspect | Hermes Vault | General password manager | Environment-only secrets |
|--------|--------------|--------------------------|--------------------------|
| Agent policy | First-class per-agent/service/action gates | Usually human-user oriented | Usually absent |
| Local-first | Yes | Often yes, depending on tool | Yes |
| MCP integration | Built in | Usually absent | Absent |
| Raw secret avoidance | Explicit dashboard/MCP metadata boundaries | Varies | Weak once exported |
| Verification before re-auth | Built in for supported providers | Usually absent | Absent |
| Maturity | Young but well-tested | Mature products available | Simple but fragile |

Hermes Vault is not a replacement for enterprise secret management or a polished password manager. Its niche is narrower and useful: local AI-agent credential operations with explicit broker policy.

## Self-Hosting Notes

Install via uv tool install or pipx install from the repository, then set a local vault home and passphrase. The common path is:

- set HERMES_VAULT_HOME
- set HERMES_VAULT_PASSPHRASE
- run hermes-vault scan
- preview env import with hermes-vault import --from-env .env --dry-run
- import, verify, run policy doctor, and launch the dashboard with --no-open when needed

For MCP use, run hermes-vault mcp from the MCP host and bind allowed agents with HERMES_VAULT_MCP_ALLOWED_AGENTS and HERMES_VAULT_MCP_DEFAULT_AGENT when the deployment has a known host identity.

Observed verification: the documented uv sync --extra dev && uv run python -m pytest tests/ -q run completed with 584 passed and 1 failed in this environment. The failing test expects a dashboard runtime warning for temporary homes, but this machine's pytest temp root was outside /tmp while the implementation only treats /tmp as temporary.

---

**Attribution:** asimons81/hermes-vault, MIT
