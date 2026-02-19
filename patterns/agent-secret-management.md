# Agent Secret Management Pattern

**Source:** [joelhooks/agent-secrets](https://github.com/joelhooks/agent-secrets) (MIT)
**Author:** Joel Hooks

## Problem

AI agents need credentials (API keys, tokens) but giving them raw access to a password manager exposes all secrets to exfiltration risk, with no audit trail, no revocation, and no rotation.

## Solution: Lease-Based Secret Access

Instead of static env vars or password manager access:

1. **Encrypted store** — secrets encrypted at rest (age encryption)
2. **Lease model** — agents request time-bounded access (TTL), not permanent credentials
3. **Audit logging** — every access recorded in append-only log
4. **Killswitch** — emergency revoke-all with optional rotation and wipe
5. **Heartbeat** — auto-killswitch if monitoring endpoint goes down

## Architecture

```
CLI → Unix Socket (JSON-RPC) → Daemon Process
                                    ├── Encrypted Store (age)
                                    ├── Lease Manager (TTL-based)
                                    ├── Audit Log (JSONL, append-only)
                                    ├── Rotation Hooks (custom commands)
                                    └── Killswitch + Heartbeat
```

## Key Design Decisions

- **Daemon model** — long-running process manages state, CLI is stateless
- **JSON envelope with `next_actions`** — every response tells the agent what to do next (self-documenting API)
- **Raw value default for `lease`** — `export TOKEN=$(secrets lease name)` just works
- **`.secrets.json` per-project** — declare what secrets a project needs, generate `.env` from it
- **`secrets exec`** — run command with secrets loaded, auto-cleanup on exit

## Agent Integration Pattern

```bash
# 1. Lease with descriptive client ID + appropriate TTL
export TOKEN=$(secrets lease github_token --ttl 1h --client-id "agent-task-123")

# 2. Do work...

# 3. Revoke when done
secrets revoke --all
```

Or project-based:
```json
// .secrets.json
{
  "secrets": [
    {"name": "github_token", "env_var": "GITHUB_TOKEN"},
    {"name": "api_key", "env_var": "API_KEY", "ttl": "30m"}
  ],
  "client_id": "my-project"
}
```

```bash
secrets exec -- npm run deploy  # auto-generates .env, runs command, cleans up
```

## Lessons

- Time-bounded access > permanent credentials
- Audit trail is non-negotiable for agent security
- Self-documenting APIs (next_actions) help agents discover capabilities
- Killswitch is a real incident response tool, not just a feature checkbox
