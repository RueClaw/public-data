# Hermes Agent Control Room (shannhk/hermes-agent-control-room)

**Repo:** https://github.com/shannhk/hermes-agent-control-room
**License:** MIT; reusable with attribution.
**Reviewed:** 2026-05-17
**Stack:** Markdown runbooks, Claude/Hermes-style skills, Bash provisioning scripts, Docker Compose templates, YAML task bus templates
**What it is:** Hermes Agent Control Room is a template for documenting and operating a small team of VPS-hosted Hermes agents. It is a sidecar control-plane repo: agent registry, runbooks, secret maps, backup notes, security SOPs, Docker templates, and task-bus handoff files.

---

## Verdict

🔧 **Harvest the sidecar control-room pattern, but do not run the bootstrap path blindly.** The repo is useful because it insists on setting up the operating manual before scaling agent automation: one agent, then specialists, then orchestrator, then recurring workflows. The implementation is mostly documentation and templates, with thin Bash helpers. The security posture is sensible in the docs, but the VPS bootstrap path installs several moving parts as root through network install scripts, so it deserves review before production use.

---

## What It Is

Hermes Agent Control Room is not an agent runtime. It is a control-plane folder for the agents someone already runs or plans to run. The central distinction is explicit: the control room stores documentation, registries, runbooks, templates, and operating rules; live runtime state stays under per-agent data directories.

The repo proposes a four-level growth path:

1. Agent Control Room plus one agent.
2. Direct specialist agents.
3. Optional orchestrator plus specialists.
4. Automated recurring workflows.

That sequencing is the strongest part. It pushes users away from starting with a broad autonomous system and toward a documented manual workflow first.

## Stack

| Layer | Tech |
|-------|------|
| Control plane | Markdown docs under docs/, shared/, agents/, templates/ |
| Agent skills | SKILL.md files for setup, registry, task routing, backup, security, cron planning |
| Provisioning | Bash scripts for Hetzner VPS creation and control-room bootstrap |
| Runtime template | Docker Compose for Hermes agent/orchestrator containers |
| Coordination | File-based task bus with inbox/working/outbox/archive folders |
| Registry | YAML agent registry template |
| Security model | Secret maps by reference, localhost-bound dashboard/API ports, per-agent data dirs |
| Quality | No tests or CI visible; mostly static docs/templates |

## Key Features

### Sidecar Control Plane

The control room is deliberately separate from runtime state. It documents agent names, roles, ports, data directories, allowed work, forbidden work, credentials by reference, backup plans, and runbooks without storing raw secrets.

### Level-Based Scaling Model

The repo's level model is practical. It says to document one agent first, add direct specialists only when roles are clear, add an orchestrator only when remembering the right specialist becomes annoying, and automate only after manual delegation works.

### Task Bus Handoff Pattern

The task bus template uses shared folders for specialist queues: inbox, working, outbox, and archive. Task and result templates include approval gates, expected output, risks, assumptions, and recommended next action. This is simple, inspectable, and easy to debug.

### Bundled Operations Skills

The repo includes skills for control-room management, task routing, registry maintenance, backup planning, security auditing, team cron planning, VPS provisioning, and control-room setup. These are mostly procedural, but they encode useful operational boundaries.

## Architecture

The architecture is file-first and sidecar-oriented:

| Area | Purpose |
|------|---------|
| docs/ | Architecture, levels, naming, security, task bus, orchestrator, starter guide |
| shared/ | Common commands, API key SOP, security checklist |
| templates/agent/ | Inventory, Docker, env-map, runbook, backup docs |
| templates/docker/ | Compose templates for agent and orchestrator containers |
| templates/task-bus/ | Agent registry, task template, result template |
| skills/ | Agent-readable SOPs for setup and operations |
| agents/ | User-created per-agent documentation folders |

The recommended runtime split is also clear:

| Path | Role |
|------|------|
| /root/agent-control-room | docs, templates, runbooks, registry, no raw secrets |
| /srv/<agent-name>/data | live agent data, .env, memory, sessions, crons, logs |

## Security and Maturity Notes

- Public repo metadata at review time: 214 stars, 31 forks, pushed 2026-05-16.
- License: MIT.
- Current checked commit: 48a1a5a2c3a64416f51b0199a1acc9aba05e6261.
- Quick secret scan found placeholders and references to token names only, not obvious live credentials.
- Docker templates bind gateway and dashboard ports to 127.0.0.1 by default, which is the right default.
- No CI, tests, schema validation, template linting, or shellcheck workflow was visible.
- Bootstrap scripts install NodeSource, Claude Code, Codex CLI, Docker, and Hermes Agent as root. That is convenient, but a broad supply-chain and privilege surface.
- The template is root/VPS-centric. Operators with stricter security requirements should adapt it to non-root users, pinned versions, and hardened SSH/firewall baselines.

## Comparison

| Aspect | Hermes Agent Control Room | Citadel | Ruflo | Decapod |
|--------|---------------------------|---------|-------|---------|
| Primary role | Sidecar operations manual/control plane | Claude Code orchestration plugin | Broad Claude Code orchestration platform | Repo-local governance kernel |
| State model | Markdown docs, templates, YAML registry, task files | Markdown campaign files | Plugins, skills, memory, witnesses | .decapod specs/proofs |
| Runtime coupling | Hermes/VPS/Docker oriented | Claude Code oriented | Claude Code oriented | Agent-agnostic CLI |
| Best pattern | Control room before automation | Campaign persistence | Signed regression witnesses | Governance around inference |
| Maturity | Template/SOP kit | Working framework | Large alpha-heavy platform | Working CLI |

This repo is less technically deep than Citadel, Ruflo, or Decapod. Its value is operational discipline: write down ownership, runtime boundaries, secret locations, runbooks, and approval gates before delegating work to multiple agents.

## Self-Hosting Notes

Use this as a template, not a blind installer. Before running setup scripts on a VPS:

- Read the Bash scripts.
- Pin or verify network install sources.
- Decide whether root-based operation is acceptable.
- Confirm firewall and SSH hardening separately.
- Keep dashboards and gateway APIs bound to localhost unless protected by authentication.
- Add validation for agent registry/task/result files if the system becomes operationally important.

---

**Attribution:** shannhk/hermes-agent-control-room, MIT License.

