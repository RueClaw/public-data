# Edge-Brokered Coding Sandboxes

**Source:** https://github.com/nkzw-tech/cloudsail
**Reviewed:** 2026-05-23
**License context:** Cloudsail is MIT licensed. This pattern is a clean-room architecture summary with attribution.

## Pattern

Run coding agents inside isolated remote development containers, but keep credentials, egress policy, lifecycle, and public previews in a separate edge control plane.

The agent gets a normal Linux workspace where it can run shell commands, package managers, tests, dev servers, git, Codex, OpenCode, or similar tools. The control plane owns the sensitive parts:

- project and sandbox registry;
- authenticated API access;
- short-lived terminal and preview tickets;
- provider credentials;
- repository-scoped GitHub token injection;
- model-provider credential injection;
- host allowlists and read-only documentation egress;
- cost and keepalive limits;
- checkpoints and destroy operations.

## Why It Matters

Local coding agents are convenient but inherit the user's machine, credentials, network, caches, and filesystem. Generic remote containers improve isolation but often put real secrets directly inside the container, where compromised dependencies, test scripts, or prompt-injected commands can read them.

An edge-brokered design gives agents a realistic development environment without giving the sandbox raw credentials. The sandbox can ask the outside world for GitHub, model, package, or docs access, but the control plane decides what to forward and when to inject secrets.

## Building Blocks

### Per-Project Sandbox Actor

Create one authoritative project actor that owns sandbox ID, repository path, branch, exposed ports, backups, allowed egress hosts, last agent run, and event history. This actor is the durable coordination point even when the container sleeps.

### Worker-Owned Credential Injection

Store GitHub/model credentials as control-plane secrets. The sandbox receives placeholders or no credentials. Intercept outbound HTTP/S requests and inject the real authorization header only for approved hosts and paths.

### Repository-Scoped GitHub Auth

Only inject GitHub auth when the outbound request matches the configured repository owner/name. This prevents a compromised sandbox from using a general token to inspect or modify unrelated repos.

### Read-Only Research Hosts

Allow users to add documentation or research hosts, but restrict non-default added hosts to GET, HEAD, and OPTIONS. This supports normal agent research while blocking accidental or malicious writes to arbitrary third-party services.

### Short-Lived Access Tickets

Use one-time terminal tickets and short-lived preview tickets. Exchange preview tickets for HTTP-only cookies so browser testing works without making raw preview URLs public.

### Cost and Lifecycle Controls

Expose keepalive explicitly, estimate idle cost, and enforce optional maximum active projects or projected monthly cost. Remote agent sandboxes are easy to forget; cost controls are part of the safety model.

### Durable Work Boundaries

Treat the live container filesystem as a working cache. Durable state should be git branches, pull requests, checkpoints/backups, logs, and project metadata.

## Good Fit

- Coding-agent platforms that need stronger isolation than local execution.
- Self-hosted agent workspaces for experiments, PR fixes, and tests.
- Environments where agents need package installs and dev servers but should not receive raw provider tokens.
- Teams that want normal git workflows while keeping agent execution off laptops.

## Poor Fit

- Tasks requiring full private-network access from the sandbox.
- Long-lived VMs with durable running processes.
- Workloads that exceed the remote sandbox CPU, memory, or disk limits.
- Environments where edge outbound interception cannot cover the needed protocols.

## Review Checklist

- Are credentials stored outside the sandbox?
- Is credential injection scoped by host and path, not just by destination host?
- Are added egress hosts validated against localhost/private IP/wildcard bypasses?
- Are added hosts read-only unless explicitly trusted?
- Are terminal and preview URLs authenticated with short-lived credentials?
- Are command strings and git refs shell-escaped?
- Are logs and transcripts bounded before durable storage?
- Are active sandbox count and cost limits configurable?
- Is durability explained as git/checkpoints, not live container state?

---

**Attribution:** Pattern derived from the public architecture of nkzw-tech/cloudsail.
