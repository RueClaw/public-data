# Edge Agent Command Allowlist

**Source:** https://github.com/getarcaneapp/arcane  
**Author:** getarcaneapp / Arcane contributors  
**License:** BSD-3-Clause  
**Reviewed:** 2026-07-03

## Pattern

When a central control plane manages remote agents, do not proxy arbitrary HTTP requests to the agent. Define a registry of allowed operations as method, path pattern, command name, and stream mode. Resolve every requested remote operation through that registry before forwarding it, then apply the caller's permission set against the resolved command and environment.

This turns "remote agent proxy" from an open tunnel into a named operation surface.

## Core Components

- **Command route registry:** an explicit list of method and path patterns, each mapped to a stable command name such as `container.start`, `project.logs.stream`, or `system.prune`.
- **Separate stream flag:** streaming routes such as logs, stats, and terminals are differentiated from normal REST requests.
- **Path normalization and trie lookup:** request paths are normalized and matched against static and parameterized route nodes.
- **Permission resolver:** the manager maps the command route to the permission required for the selected environment.
- **Agent-side high authority:** the remote agent can run with local authority, but only manager-approved commands reach it.
- **Audit names:** command names become clean audit/event labels, independent of URL details.

## Why It Matters

Agent tunnels are tempting to implement as generic reverse proxies. That is easy, but it creates a large and often invisible blast radius: new local endpoints become remotely reachable by default, stream endpoints bypass normal request handling, and authorization logic drifts from the manager API.

A command allowlist makes the remote contract explicit. New capabilities require adding a route, naming the command, mapping its permission, and testing the authorization path.

## Design Rules

1. Make the allowlist the only remote routing entry point.
2. Include method and stream/non-stream identity in the route key.
3. Keep command names stable and domain-oriented.
4. Treat terminal, logs, file browsing, hook execution, and system operations as high-risk commands.
5. Put permission checks on the manager before forwarding to the agent.
6. Add tests that every remote route resolves to a known permission or an intentionally public command.
7. Fail closed when a route is unknown.

## Good Fit

- Remote Docker, VM, or host-management agents.
- Edge agents that dial out from private networks.
- Multi-tenant or multi-environment infrastructure dashboards.
- Agentic operations systems where a central scheduler invokes remote workers.
- Any control plane where remote workers are more privileged than the caller.

## Watch Outs

- An allowlist is not a sandbox. The allowed commands can still be dangerous.
- Command names must stay in sync with permission mappings and UI affordances.
- WebSocket and terminal streams need the same discipline as REST endpoints.
- Generated or plugin-defined routes should be rejected unless they go through the same registration process.
- The remote agent should still authenticate the manager, because manager-side checks do not protect against a stolen agent token.

## Minimal Checklist

1. List every remote operation as a typed route.
2. Resolve method, path, and stream mode to a command name.
3. Map command names or route templates to permissions.
4. Enforce permissions before forwarding.
5. Log command names in audit events.
6. Add tests for unknown routes, parameterized paths, stream routes, and permission coverage.
7. Review the registry as part of every privileged feature addition.

---

**Attribution:** getarcaneapp/arcane, BSD-3-Clause, https://github.com/getarcaneapp/arcane
