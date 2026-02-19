# Pattern: Network Sandbox via Local Proxy

**Source:** [openai/codex](https://github.com/openai/codex) (Apache 2.0)
**Component:** `codex-rs/network-proxy/`

## Core Idea

Instead of trying to control network access at the syscall level (complex, platform-specific), route all child process traffic through a local HTTP/SOCKS5 proxy that enforces domain-level allow/deny policies.

## How It Works

```
Agent spawns child process
    ↓
Child process env: HTTP_PROXY=http://127.0.0.1:<port>
                   HTTPS_PROXY=http://127.0.0.1:<port>
    ↓
All HTTP(S) traffic → local proxy
    ↓
Proxy checks domain against NetworkPolicy
    ↓
Allow → forward to upstream
Deny → return error, log blocked request
```

## Key Components

1. **NetworkProxy** — spawns HTTP + SOCKS5 listeners on localhost
2. **NetworkPolicyDecider** — evaluates domain/URL against allow/deny rules
3. **BlockedRequestObserver** — callback for logging/alerting on blocked requests
4. **Admin endpoint** — runtime policy updates, health checks
5. **Per-attempt IDs** — each tool execution gets a unique attempt ID embedded in proxy auth username for request attribution

## Why This Is Better Than Alternatives

- **Firewall rules (iptables/pf):** Require root, affect entire system, can't do per-process policies
- **Seccomp/Landlock:** Can block `connect()` but can't do domain-level filtering (only IP/port)
- **DNS blocking:** Bypassable with IP addresses, doesn't work for CDN-hosted content
- **Proxy approach:** Works at application layer, domain-aware, per-process, no root needed

## Limitations

- Doesn't catch processes that ignore proxy env vars (raw socket connections)
- Must be combined with filesystem sandbox to prevent proxy bypass
- Some tools don't respect HTTP_PROXY (need wrapper or LD_PRELOAD)

## Implementation Notes

- Proxy supports both HTTP CONNECT (tunneling) and plain HTTP forwarding
- SOCKS5 support for tools that prefer it
- Unix socket permissions for local-only access (no remote connections to proxy)
- TLS passthrough for HTTPS (proxy doesn't terminate TLS, just tunnels)
