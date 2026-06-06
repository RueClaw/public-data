# Sandboxed Execution-Verified Security Agent Loop

**Source:** anthropics/defending-code-reference-harness  
**Repo:** https://github.com/anthropics/defending-code-reference-harness  
**License:** Apache-2.0  
**Reviewed:** 2026-06-06  

## Pattern

Treat an autonomous security agent as an untrusted worker inside a constrained execution environment, then accept findings and patches only when independent executable checks pass. The model can explore, hypothesize, and generate artifacts, but the pipeline records durable evidence and uses fresh verification contexts before anything is considered real.

The reusable shape is:

1. Build a pinned target image with a concrete oracle, such as ASAN, tests, or a harness exit code.
2. Run each exploratory agent in an isolated container with bounded filesystem access and narrow model-API egress.
3. Require the agent to produce a minimal artifact, not just prose: PoC bytes, reproduction command, trace, report JSON, or patch diff.
4. Verify that artifact in a fresh container that the producing agent never touched.
5. Deduplicate and report only after verification.
6. For patches, apply an executable ladder: diff applies, build passes, original PoC stops failing, regression tests pass, and an optional re-attack cannot find a bypass.

## Why It Matters

Security agents are useful precisely because they search adversarially. That also makes them poor fits for prompt-only safety controls. A good harness assumes the agent may run surprising commands, misread evidence, overfit a patch to a crash site, or talk itself into a false positive.

This pattern separates creativity from authority. The model can propose and mutate inputs, but a separate process decides whether the crash reproduces. It can write a patch, but build/test/PoC replay decide whether the patch works. A style judge can be helpful, but it should not be the gate.

## Implementation Shape

```text
trusted orchestrator
  |
  | builds pinned target image with executable oracle
  v
isolated find worker
  - reads source
  - mutates inputs
  - writes PoC bytes
  - emits structured tags
  |
  | only artifact crosses boundary
  v
fresh verification worker
  - replays PoC
  - checks oracle output
  - records verdict
  |
  v
dedupe / report / patch
  |
  | only diff crosses boundary
  v
fresh patch grader
  - apply diff
  - rebuild
  - replay PoC
  - run tests
  - optionally re-attack
```

## Design Rules

- Keep the orchestrator deterministic and trusted. It owns phase control, artifact paths, target config, and container lifecycle.
- Put exploratory agents in disposable workers. Their filesystem, shell, and network should be scoped by infrastructure, not by instruction text.
- Do setup before attack. Fetch dependencies and build images before the model-controlled phase, then freeze the attack environment.
- Let only small artifacts cross from worker to verifier: PoC bytes, report JSON, or diff bytes.
- Prefer executable gates over model judgment. Model judges are useful for semantic dedupe and style, but not for proving a crash or accepting a patch.
- Stream transcripts and write checkpoints so interrupted runs leave inspectable evidence.
- Make target definitions declarative: pinned commit, binary path, source root, build command, test command, known bugs, resource limits, and attack surface notes.

## When To Use

Use this pattern for:

- autonomous vulnerability discovery;
- fuzzing or parser-hardening workflows driven by LLMs;
- agent-generated patches that need independent validation;
- any high-risk agent loop where a worker handles untrusted code, files, or inputs;
- benchmark harnesses where false positives and self-confirming reports would poison results.

Do not use this as a substitute for real authorization, disclosure process, secret hygiene, or target-specific threat modeling. The isolation boundary reduces blast radius; it does not make arbitrary target execution harmless.

## Source Files

- `harness/cli.py` - stage orchestration, resume behavior, signal cleanup, result writing.
- `harness/sandbox.py` - gVisor/runtime detection, permission mode, agent container boundary.
- `scripts/setup_sandbox.sh` - runsc setup, internal network, egress proxy, isolation checks.
- `scripts/egress_proxy.py` - allowlist CONNECT proxy for model API egress.
- `harness/find.py` and `harness/prompts/find_prompt.py` - PoC-producing find agents.
- `harness/grade.py` - fresh-container PoC verification.
- `harness/patch_grade.py` - executable patch grading ladder.
- `targets/README.md` - declarative target contract.

---

**Attribution:** anthropics/defending-code-reference-harness, Apache-2.0
