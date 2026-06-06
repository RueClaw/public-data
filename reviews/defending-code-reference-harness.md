# Defending Code Reference Harness (anthropics/defending-code-reference-harness)

**Repo:** https://github.com/anthropics/defending-code-reference-harness  
**License:** Apache-2.0, suitable for reuse with attribution and license preservation  
**Reviewed:** 2026-06-06  
**Stack:** Python 3.11+, Docker, gVisor/runsc, Claude Code CLI, ASAN, YAML, pytest  
**What it is:** A reference implementation for Claude-driven vulnerability discovery, verification, reporting, and patching, focused on C/C++ memory-safety targets instrumented with AddressSanitizer.

---

## Verdict

🔧 **Harvest the architecture, do not treat it as a maintained scanner.** This is one of the more concrete public examples of how to turn security agents into a defensible pipeline: sandboxed workers, reproducible PoCs, fresh-container verification, semantic dedupe, structured reports, and executable patch grading. The repo also says it is not maintained, and local verification on a Mac without Docker exposed test portability gaps around Docker assumptions.

---

## What It Is

Defending Code Reference Harness is Anthropic's open reference for a security-agent loop described in its accompanying source-code security material. It has two surfaces: Claude Code skills for threat modeling, static vulnerability scanning, triage, patch generation, customization, and quickstart guidance; and a Python package named `vuln-pipeline` for autonomous execution-verified vulnerability discovery.

The autonomous harness is intentionally narrow. It expects target definitions under `targets/`, builds ASAN-instrumented Docker images, runs Claude Code agents inside gVisor containers, asks find agents to produce crashing inputs, verifies those inputs in fresh containers, deduplicates findings, writes exploitability reports, and can run a patch agent followed by a deterministic patch-grading ladder.

The repository is best read as a reference implementation for agent safety and verification in a high-risk domain. It is not a general-purpose security product, not maintained, and not something to point at arbitrary production code without adapting the target harness, threat model, credential boundary, and operating environment.

## Stack

| Layer | Tech |
|-------|------|
| CLI / orchestrator | Python package `vuln-pipeline` |
| Agent runtime | Claude Code CLI in headless `stream-json` mode |
| Isolation | Docker plus gVisor `runsc` |
| Network control | Internal Docker network plus allowlist CONNECT proxy |
| Vulnerability oracle | ASAN-instrumented C/C++ target binaries |
| Target config | Per-target `config.yaml`, Dockerfile, entry harness |
| Agent outputs | XML-like tags parsed from assistant messages |
| Artifacts | JSONL transcripts, `result.json`, PoC bytes, structured reports, patch diffs |
| Tests | pytest unit tests and Docker-dependent patch grading tests |

## Key Features

### Sandboxed Agent Execution

The repo treats prompts as advisory and the container boundary as the real control. Agent containers run with gVisor when launched through `bin/vp-sandboxed`, attach to an internal Docker network, and use an allowlist proxy that only forwards approved model API traffic. The docs also make the tradeoff explicit: `--dangerously-no-sandbox` exists for development, but loses syscall isolation and broadens networking.

### Execution-Verified Findings

The find agent is not asked to write a polished vulnerability report. It must write a PoC file, run the ASAN target, reproduce the crash three times, minimize the input, and emit machine-readable tags with the PoC path, reproduction command, crash type, exit code, ASAN trace, and duplicate check. A separate grade agent then gets only the PoC bytes and validates the crash in a fresh container.

### Structured Multi-Agent Pipeline

The pipeline stages are cleanly separated:

- recon proposes focus areas;
- find creates crashing inputs;
- grade verifies the crash;
- judge performs semantic dedupe;
- report writes exploitability analysis;
- patch proposes fixes;
- patch grade applies executable checks before accepting a fix.

That split matters because it reduces self-confirmation. A find agent's reasoning does not automatically become a report or a patch approval.

### Patch Verification Ladder

Patch grading is the strongest reusable idea in the repo. The grader applies the diff in a fresh container, rebuilds the target, replays the original PoC, runs the configured test suite when present, optionally re-attacks the patched binary with a fresh find agent, and treats model style review as advisory only. The gating decisions are executable where possible.

### Claude Code Skills As Operator Workflow

The `.claude/skills/` directory is a parallel operator layer: quickstart, threat model, static scan, triage, patch, and customize. The skills are explicit about which steps only read/write files and which steps execute target code. That distinction is useful for any security workflow that mixes static reasoning with dynamic testing.

## Architecture

The core design is "trusted orchestrator, untrusted agent worker." The Python CLI owns phase control, artifact paths, checkpointing, target config, and container lifecycle. The agents get a narrow workspace inside target containers and must report through structured tags or files.

The target abstraction is deliberately small. A target has a Docker build context, image tag, pinned upstream URL/commit, binary path, source root, optional focus areas, known bugs, attack-surface notes, build command, test command, and resource limits. Adding a new target should not require editing pipeline code.

There are also good operational details: transcripts are streamed to JSONL with fsync, killed runs can resume, direct child processes are cleaned up on signals, and multi-run layouts are checked so a resume does not corrupt result directories.

The weak spots are mostly packaging and portability. The README states the repo is not maintained. GitHub's API reports 4,137 stars, 269 forks, 5 open issues, latest push 2026-06-02, and no releases/tags at review time. Local tests on macOS without Docker failed during Docker-dependent collection/paths instead of cleanly skipping every Docker-bound case.

## Comparison

| Aspect | Defending Code Reference Harness | DeepSec | Claude-BugHunter | SkillSpector |
|--------|----------------------------------|---------|------------------|--------------|
| Primary role | Execution-verified vulnerability discovery and patching reference | Agent-powered vuln scanning with sandbox workers | Bug bounty / external red-team Claude Code skill bundle | Security scanner for agent skills |
| Dynamic execution | Yes, ASAN targets in containers | Primarily scanner workflow | Mostly operator-guided validation | No, scans skill packages |
| Sandbox emphasis | Very high: gVisor plus egress proxy | High: worker sandbox and credential brokering | Scope and evidence gates | Static analyzer boundaries |
| Best reusable pattern | Fresh-container verification and patch oracles | Brokered credentials and resumable scan records | Authorization and evidence hygiene | Pre-install skill security checks |
| Deployment posture | Reference only, not maintained | More product-shaped | Skill bundle, security-sensitive | Deployable scanner |

## Self-Hosting Notes

Run the autonomous harness only on a Linux host or Linux VM with Docker and gVisor. The supported path is `scripts/setup_sandbox.sh` followed by `bin/vp-sandboxed ...`; the setup script registers `runsc`, creates the internal network, starts the egress proxy, builds target images, and verifies isolation. On macOS, a Linux VM is the practical route.

Do not mount credentials, broad source trees, or production sockets into agent containers. The target code and generated PoCs should be treated as hostile. Before using it on a real target, write a target-specific `config.yaml`, keep commits pinned, define a real build command and test command, and start with small runs to estimate token burn and false-positive behavior.

Verification performed for this review:

- `python3 -m venv /tmp/dcrh-venv && /tmp/dcrh-venv/bin/pip install -e '.[dev]'` succeeded.
- `/tmp/dcrh-venv/bin/pytest -q` failed during collection because `tests/test_patch_grade_e2e.py` calls `docker` while Docker is not installed.
- `/tmp/dcrh-venv/bin/pytest -q --ignore=tests/test_patch_grade_e2e.py` reported 179 passed, 5 skipped, 14 failed, with the failures again caused by Docker lookup paths in patch-related tests.

---

**Attribution:** anthropics/defending-code-reference-harness, Apache-2.0
