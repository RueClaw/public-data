# OneCLI (onecli/onecli)

**Rating:** 🔥🔥🔥  
**License:** Apache 2.0  
**Source:** https://github.com/onecli/onecli  
**Reviewed:** 2026-03-21

## What It Is

Credential injection gateway for AI agents. Agents get fake placeholder tokens; the gateway intercepts their HTTP traffic and swaps in real credentials. Agents never see actual secrets.

```bash
docker compose -f docker/docker-compose.yml up
# → Dashboard: http://localhost:10254
# → Gateway proxy: http://localhost:10255
```

## How It Works

```
Agent (with FAKE_KEY)
    │
    │ HTTP via Proxy-Authorization header
    ▼
OneCLI Gateway (Rust, MITM)
    ├── Generate local CA → terminate TLS from agent
    ├── Match host+path pattern → look up real secret
    ├── Decrypt AES-256-GCM secret → inject into headers
    └── Re-establish TLS → forward to real API
```

The gateway generates its own local CA certificate, terminates TLS from the agent, rewrites auth headers (swaps `FAKE_KEY` for real key), and forwards the request to the actual API over a new TLS connection. Agents configure it via standard `http_proxy`/`https_proxy` environment variables.

## Architecture

```
apps/
  gateway/   # Rust: MITM proxy, credential injection, Bitwarden vault
    src/
      ca.rs       # Local CA generation + management
      inject.rs   # Header injection logic
      policy.rs   # Host+path matching rules
      vault/      # Bitwarden integration (Noise protocol)
      crypto.rs   # AES-256-GCM decrypt
  web/       # Next.js: dashboard + API (port 10254)
packages/
  db/        # Prisma ORM + PostgreSQL migrations
  ui/        # shadcn/ui components
```

## Bitwarden Vault Integration (Key Feature)

Instead of storing secrets in the OneCLI database, the gateway queries your local Bitwarden vault on-demand:

1. `aac listen --psk` → generates pairing code
2. Paste pairing code in dashboard → gateway establishes encrypted Noise protocol session to Bitwarden app
3. Agent makes HTTPS request → gateway asks Bitwarden for credential by domain → injects, caches 60s in memory, discards
4. Credentials never hit disk or database

Credential injection rules by host:
- `api.anthropic.com` → `x-api-key: <password>`  
- Everything else → `Authorization: Bearer <password>`

This is the right security posture: password manager stays single source of truth, gateway is stateless with respect to secrets.

## Security Model

- AES-256-GCM encryption at rest (auto-generated key, or set `SECRET_ENCRYPTION_KEY`)
- Secrets decrypted only at request time
- Per-agent access tokens with scoped permissions
- Bitwarden path: credentials never stored on server at all
- Audit log: every request shows which agent called which API

## When It Matters

**Ideal for:**
- Multiple AI agents with different permission levels (agent A can call Anthropic, agent B can only call GitHub)
- Team environments where you don't want to share raw API keys
- Audit trail of agent API usage
- Centralized key rotation (rotate once in OneCLI, all agents updated)

**Less compelling for:**
- Single-machine solo use where env vars or a password manager already cover you
- Adds Docker + Postgres operational overhead

## Tech Stack

- Rust gateway (tokio + rustls + hyper, MITM proxy)
- Next.js 15 + shadcn/ui dashboard
- Prisma + PostgreSQL
- Turborepo monorepo + pnpm workspaces
- Two auth modes: single-user (no login) or Google OAuth for teams

## Reference Value

Clean example of how to build an HTTPS MITM proxy in Rust: `ca.rs` (local CA generation), `connect.rs` (proxy CONNECT tunnel), `inject.rs` (header rewriting), `crypto.rs` (AES-256-GCM at rest). The Noise protocol Bitwarden integration is also a good reference for external vault bridging patterns.
