# OAuth-Scoped Application MCP Tools

**Source:** outline/outline  
**Repo:** https://github.com/outline/outline  
**License:** Business Source License 1.1; pattern summary only  
**Reviewed:** 2026-07-03

## Pattern

Expose an application's native objects and actions as MCP tools, but register the tool surface dynamically from the authenticated token's scopes and the workspace's feature preferences.

```text
request -> OAuth/API auth -> workspace feature gate -> scope set
  -> create per-request MCP server
  -> register only allowed tools
  -> run handlers through existing policy checks
  -> return app-native presenters or signed URLs
```

## Why It Matters

An MCP endpoint should not become a second, weaker API. It should inherit the same auth model, authorization policies, and resource presentation rules as the main product.

Outline's implementation is a useful example because the endpoint is app-native:

- MCP requests require authentication.
- A workspace/team preference can hide the endpoint.
- OAuth/API scopes determine which tools are registered.
- Individual handlers still call app policy checks.
- Read-only tools are annotated with MCP read-only/idempotent hints.
- Attachments return short-lived signed URLs rather than raw storage credentials.
- Tests cover auth, protocol handling, feature gating, and scope enforcement.

## Implementation Notes

- Prefer a fresh MCP server instance per request or session so tool registration can reflect current scopes.
- Make "tools/list" itself scope-aware; do not show tools the token cannot use.
- Use existing app presenters to shape returned resources.
- Keep policy checks inside tool handlers even when registration is scope-filtered.
- Gate the whole MCP surface behind an explicit tenant/workspace setting.
- Include OAuth protected-resource discovery metadata for clients.
- Log and rate-limit MCP routes separately from normal UI/API traffic.

## Failure Modes

- Registering all tools and relying only on handler failures leaks capabilities and encourages probing.
- Treating MCP tokens as equivalent to browser session cookies can bypass intended CSRF or session boundaries.
- Returning raw attachment bytes or permanent URLs can expand data exposure.
- Tool instructions can drift from application semantics if they are not generated or maintained close to the handlers.
- Feature flags must fail closed; disabled tenants should not reveal an MCP surface.

## When To Use

Use this pattern for mature SaaS/self-hosted apps that already have:

- clear OAuth/API token scopes;
- object-level authorization policies;
- stable presenters/serializers;
- tenant/workspace settings;
- audit/logging and rate-limit infrastructure.

Do not start with MCP if the underlying app permissions are vague. Agent access should be a projection of an existing security model, not a replacement for one.

---

**Attribution:** Pattern summarized from outline/outline, Business Source License 1.1.
