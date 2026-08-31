# Reverse Skill (zhaoxuya520/reverse-skill)

**Repo:** https://github.com/zhaoxuya520/reverse-skill  
**License:** MIT; safe to study, fork, and adapt with attribution.  
**Reviewed:** 2026-08-30  
**Stack:** Markdown Agent Skills, JSON routing config, Bash/PowerShell/Python scripts, GitHub Actions, Java/Node Burp MCP bridge  
**What it is:** A cybersecurity skill-router pack for AI coding agents. It routes reverse-engineering, CTF, malware-analysis, authorized pentest, cloud, API, supply-chain, and related security tasks into domain skills, case folders, tool bootstrap manifests, evidence logs, findings, attack paths, and review gates.

---

## Verdict

⚠️ **Interesting; harvest the structure, isolate the operator workflows.** The project is unusually complete for an agent-skill corpus: one routing config drives 43 routing rules, 173 regression cases pass, case initialization writes explicit scope/auth/network contracts, and case review checks evidence-to-finding traceability. The same qualities that make it useful also make it sensitive: it is full of high-authority security instructions, optional tool installation, local MCP control bridges, and strong "do this now" agent directives. I would not install it as a broad global instruction set; I would use it only in an authorized lab or extract the scope-gated routing pattern.

---

## What It Is

Reverse Skill is a bilingual security workflow pack for AI agents that encounter tasks like APK reverse engineering, binary analysis, obfuscated frontend crypto, CTF challenges, authorized web testing, firmware, malware analysis, incident artifacts, cloud/Kubernetes security, identity, wireless, hardware, and related domains.

The top-level flow is:

1. Read the router rules.
2. Route the task through `skills/config/routing.json`.
3. Create a case folder and `scope.md`.
4. Stop active work unless authorization, target scope, network mode, and `ready_for_act` are explicit.
5. Open one primary skill.
6. Use the local tool index or bootstrap manifest when tools are missing.
7. Record timeline, evidence, findings, paths, reports, and field-journal lessons.

That is the right shape for a dangerous domain: route narrowly, require a scope contract, keep evidence IDs stable, and review the case before reporting.

## Stack

| Layer | Tech |
|-------|------|
| Agent instructions | Markdown skills, `RULES.md`, `AGENTS.md`, `CLAUDE.md`, platform bootstrap docs |
| Routing | `skills/config/routing.json`, generated routing docs, Bash/PowerShell route entrypoints |
| Case lifecycle | `case-init`, `case-guard`, `case-review`, timeline/evidence/workitem/report templates |
| Tooling | Bash, PowerShell, Python helper scripts |
| Optional tool bootstrap | Homebrew/apt/winget, pip/pipx, npm/npx, GitHub release downloads, pinned git checkouts |
| MCP/control surfaces | Optional Burp MCP bridge, IDA/Ghidra/Reqable/JS hook style integrations |
| CI | GitHub Actions on Windows, Ubuntu, shell syntax, routing, coherence, supply-chain, and case-contract checks |

## Standout Features

### Single Routing Source Of Truth

`skills/config/routing.json` is the route table, and both Bash and PowerShell entrypoints consume it instead of duplicating keyword rules. The repo reports 43 route rules and 173 regression cases. Local review confirmed:

```text
bash skills/scripts/test-routing.sh
TOTAL=173 PASS=173 FAIL=0
OVERALL: ALL PASS (173 routing cases + default-root regression)
```

This is a strong pattern for large skill packs. A route table can be tested, generated into docs, and kept coherent across agent clients.

### Scope Gate Before Active Security Work

`case-init.sh` creates `work/<case>/scope.md` with auth status, auth basis, in-scope assets, network mode, exclusions, and `ready_for_act`. `case-guard.sh` reads fields only from their expected sections, rejects unsupported network modes, and says `--force` does not bypass the hard gate.

The allowed network modes are intentionally explicit: `offline`, `lab_only`, `authorized_target_only`, and `unrestricted_lab`.

### Evidence-To-Finding Case Review

`skills/case-review/scripts/review_case.py` checks that workitems, timeline entries, reports, findings, paths, and evidence IDs line up. The included CTF demo passes strict review:

```text
python3 skills/case-review/scripts/review_case.py examples/ctf-demo --verify-hashes --strict
status: PASS
errors: 0
warnings: 0
evidence: 3
workitems: 5
timeline_events: 5
findings: 1
paths: 1
```

This is one of the most reusable parts of the repo. Security work benefits from stable evidence IDs and a mechanical traceability check before final output.

### Client-Neutral Bootstrap Posture

The README and scripts repeatedly say MCP client registration is opt-in. The default Bash bootstrap uses `--mcp-host=none`, and local review confirmed the client-neutral bootstrap regression passes:

```text
bash skills/scripts/test-client-neutral-bootstrap.sh
client-neutral Bash bootstrap/discovery regression passed
```

The bootstrap manifest pins several versions, verifies GitHub release SHA-256 digests when available, pins git-clone capabilities by commit, and refuses to overwrite dirty existing checkouts.

### Broad Skill Coverage

The corpus includes modules for APK/mobile/JS/binary reverse engineering, IDA, radare2, Ghidra, firmware, malware, digital forensics, pwn, attack chains, pentest tools, API, supply chain, LLM security, cloud/Kubernetes, Windows/AD, threat hunting, threat intelligence, OT/ICS, wireless/radio/SDR, hardware security, database security, email security, identity federation, docs, diagrams, and CTF sandbox orchestration.

That breadth makes the router useful, but it also means the repo should be treated as a security-operations corpus, not a harmless prompt pack.

## Caveats

### Very High Instruction Authority

The instructions are deliberately imperative. They tell the agent to route, create cases, bootstrap tools, execute primary skills, and continue through reports. That may reduce lazy agent behavior inside a lab, but it is risky as a global instruction pack because it can compete with local project rules and make side effects feel mandatory.

Install it as a project-scoped skill in a disposable authorized workspace, not as a general-purpose default for all coding tasks.

### Offensive Content And Tool Control

The repo contains detailed offensive-security workflows and references, including exploitation, brute-force testing, payloads, EDR-bypass topics, malware analysis, and active web testing. It also includes optional control surfaces for tools like Burp, IDA, and Ghidra. Those are legitimate in authorized contexts, but they need hard target boundaries.

The Burp MCP server is loopback-bound and bearer-token-protected, which is good. It still exposes powerful actions: active scans, request replay, Intruder-style attacks, collaborator payloads, scope updates, proxy rules, cookie manipulation, and passive secret extraction. Treat enabling it like granting an agent operator access to Burp.

### Bootstrap Still Requires Human Review

The bootstrap scripts are much better than a curl-pipe-shell blob: they use manifests, pins, guarded install directories, digest checks, and opt-in MCP registration. But they can still install packages, clone tooling, start services, and write client config when asked. Review the manifest and run the bootstrap manually.

### Portability Drift Found Locally

Most Bash checks passed, but `skills/scripts/test-bash-workflow.sh` fails on macOS because it uses GNU-style `sed -i` without a BSD-compatible backup argument:

```text
bash skills/scripts/test-bash-workflow.sh
sed: ... invalid command code f
```

The dedicated macOS workflow avoids this exact test and exercises a narrower compatibility path, so this is a small but real portability gap.

### Burp Gradle Build Drift

The Burp MCP bridge's Node test passes:

```text
node --test test/mcp-bridge.test.js
pass 1
```

The Java build did not pass locally with Gradle 9.4.1:

```text
Could not set unknown property 'sourceCompatibility' for root project 'burp-mcp-full'
```

The checked-in `gradlew` is also not executable in this clone. CI does not appear to build this Java subproject, so the Burp extension should be verified separately before relying on it.

## Comparison

Compared with a single reverse-engineering skill, Reverse Skill is a router and operating system for security cases. Compared with a scanner or harness, it is mostly instruction, case structure, and tool orchestration. Compared with a general coding-agent skill pack, it has much stronger scope/auth machinery because its domain demands it.

The closest reusable pattern is: tested route table plus scope contract plus evidence graph plus pre-report verifier.

## Best Use

Use it for:

- Authorized lab reverse-engineering and CTF workflows.
- Designing safer security-agent case structure.
- Borrowing the route-table and evidence-traceability patterns.
- Building project-scoped, not global, security skills.

Avoid using it for:

- General coding-agent defaults.
- Unreviewed auto-bootstrap in a sensitive workstation.
- Any target where authorization and scope are not written down.
- Exposing local MCP control endpoints without understanding their permissions.

## Review Notes

Local review inspected the routing config, top-level rules, agent bootstrap docs, master skill, scope contract, Bash/PowerShell bootstrap scripts, case guard, case review script, CI, Burp MCP bridge, and Gradle project.

Validation run:

```text
bash skills/scripts/test-routing.sh                         pass
bash skills/scripts/test-client-neutral-bootstrap.sh         pass
bash skills/scripts/test-bootstrap-manifest.sh               pass
python3 skills/case-review/scripts/review_case.py ...        pass
node --test burp-mcp-full/test/mcp-bridge.test.js            pass
bash skills/scripts/test-bash-workflow.sh                    fail on macOS sed -i portability
gradle -q test in burp-mcp-full                              fail with local Gradle 9.4.1 build script incompatibility
PowerShell CI parity tests                                   not run locally; `pwsh` unavailable
```

---

**Attribution:** zhaoxuya520/reverse-skill, MIT
