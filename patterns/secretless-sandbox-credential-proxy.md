# Secretless Sandbox Credential Proxy

**Source:** omnigent-ai/omnigent  
**Repo:** https://github.com/omnigent-ai/omnigent  
**License:** Apache-2.0  
**Reviewed:** 2026-07-11  

## Pattern

Keep real credentials out of the sandbox. Let the trusted parent process resolve secrets, then pass host-scoped credential rewrite rules to an egress proxy. The sandboxed tool either sees no credential or receives a short-lived synthetic placeholder that is only valid for the intended host.

## Problem

Sandboxed agent tools often need API access: GitHub, package registries, cloud APIs, private source hosts, or internal services. The easy approach is to inject the real token into the sandbox environment.

That defeats much of the sandbox. Any code the agent runs can print, copy, exfiltrate, or stash the token.

## Approach

Use three roles:

```text
trusted parent process
  resolves real secret from env/file/command
  builds host-scoped rewrite rule

egress proxy
  sees outbound requests
  attaches or swaps credential only for configured host
  rejects synthetic placeholders sent to the wrong host

sandboxed tool
  sends no credential, or sends synthetic oa_cred_* placeholder
```

Default mode is **swap-on-access**:

1. The sandbox receives no credential-shaped value.
2. The tool makes a request to an allowed host.
3. The egress proxy injects the real `Authorization` header only for that host.

Compatibility mode is **placeholder swap**:

1. The sandbox receives a synthetic placeholder such as `oa_cred_<random>`.
2. A client that refuses to run without a token sends the placeholder.
3. The proxy swaps it for the real secret only when the request goes to the bound host.
4. If the placeholder appears on a different host, the proxy rejects the request.

## Minimal Data Model

```yaml
sandbox:
  egress_rules:
    - host: github.com
      allow: true
  credential_proxy:
    - host: github.com
      scheme: bearer
      source:
        kind: command
        command: gh auth token
      inject_env:
        - GH_TOKEN
```

Fields worth keeping:

- `host`: exact hostname the credential may reach.
- `scheme`: bearer/basic/token.
- `source`: env, file, or command resolved by the trusted parent.
- `inject_env`: optional list of env vars that receive the synthetic placeholder.
- `username`: optional basic-auth username.

## Security Properties

- The real secret is never serialized into sandbox policy JSON.
- The real secret is never written into the sandbox environment.
- Placeholder values are random, short-lived, and recognizable by prefix.
- Placeholder replay to the wrong host is denied.
- Credential attachment is bound to egress policy, not agent intent.
- Clients that require local credential presence can still work with placeholders.

## Implementation Notes

- Resolve real secrets only in the parent process.
- Keep rewrite rules parent/proxy-side; do not pass them through helper JSON or logs.
- Use exact host matching unless wildcard behavior has a strong, audited reason.
- Reject unknown synthetic placeholder prefixes rather than forwarding them.
- Pair this with an egress allowlist; credential injection without network policy is weaker.
- Treat `command` sources as trusted parent-side commands, never sandbox-side commands.

## When To Use

Use this when sandboxed agent tasks need scoped access to:

- source repositories;
- package registries;
- cloud APIs;
- model gateways;
- internal HTTP APIs.

Do not use it as a substitute for upstream least-privilege tokens. The real token should still be scoped narrowly.

---

**Attribution:** Derived from `omnigent/inner/credential_proxy.py` and `designs/SANDBOX_CREDENTIAL_PROXY.md` in omnigent-ai/omnigent, Apache-2.0.
