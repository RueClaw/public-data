# correctless

- **Repo:** <https://github.com/joshft/correctless>
- **License:** MIT
- **Commit reviewed:** `0bc1476` (2026-04-14)

## What it is

Correctless is a **Claude Code workflow system** that tries to force correctness-oriented software development through:
- phase-separated skills
- fresh-agent orchestration
- bash hook enforcement
- branch-scoped workflow state
- artifact contracts between phases
- escalating rigor levels (`standard`, `high`, `critical`)

Its thesis is blunt and mostly right: **the same agent that wrote the code should not be trusted to specify it, test it, QA it, and verify it.** So the repo builds a pipeline where those lenses are intentionally separated.

This is not a “few nice prompts” repo. It is a **workflow operating system for Claude Code**.

## Core architecture

The repo has three real pillars.

### 1. Skill-orchestrated phase pipeline
The visible surface is a set of slash-command skills:
- `/cspec`
- `/creview`
- `/ctdd`
- `/cverify`
- `/cdocs`
- plus high/critical extras like `/creview-spec`, `/caudit`, `/cmodel`, `/credteam`

These are not independent utilities. They are designed as a pipeline with explicit handoff artifacts.

### 2. Hook-enforced workflow state machine
The serious part is the shell hook layer:
- `workflow-gate.sh` blocks edits based on phase
- `workflow-advance.sh` is the only state transition writer
- `audit-trail.sh` logs edits
- `sensitive-file-guard.sh` blocks secrets/credential-ish files
- `token-tracking.sh` and statusline hooks add observability

This means the repo is trying to move from “please follow the workflow” to **the workflow actually constrains what the agent can do**.

### 3. Artifact-driven memory and learning
The project writes and reuses artifacts like:
- specs
- verification reports
- antipattern lists
- architecture docs
- audit findings
- branch-scoped workflow state

That gives it a compounding memory loop instead of a purely ephemeral prompt loop.

## What is technically interesting

### 1. The lens model is the right conceptual core
Correctless’s best idea is simple: **framing changes what the model notices**.

That is true. A builder, a reviewer, a QA attacker, and a spec verifier will find different classes of problems even if they are all the same base model.

The repo takes that seriously and builds around it.

### 2. The state machine is real, not decorative
`workflow-advance.sh` is large, explicit, and full of real transition gates.

Examples:
- feature branch required before init
- spec must exist before review
- tests must actually fail before RED → GREEN
- tests must pass before GREEN → QA
- verification artifacts must exist before later transitions

That matters. Too many workflow repos stop at naming phases without enforcing the preconditions.

### 3. `workflow-gate.sh` is the load-bearing piece
This hook is doing actual work:
- fail-closed JSON parsing for hook input
- blocking direct edits to workflow state
- phase-based source/test file restrictions
- special RED-phase allowance only for `STUB:TDD`
- override counters with decrementing bypass budget
- branch-scoped state lookup
- monorepo-aware file classification

It is not elegant in the abstract, but it is more serious than most agent workflow repos.

### 4. It understands that “advisory only” is not enough
The repo repeatedly distinguishes:
- prompt-level guidance
- path-scoped rules
- hook enforcement
- audit visibility

That stack is thoughtful. It acknowledges that prompt instructions fade and that enforcement needs multiple layers.

### 5. The shell test coverage is unusually substantial
For a bash-heavy control plane, the test suite is one of the repo’s strongest signals. There are a lot of targeted shell tests around gate logic, state transitions, overrides, sync, intensity detection, hooks, and regressions.

That raises my confidence a lot.

## What is strong

### Serious operational ambition
This repo is trying to solve the real problem, not the toy one.

### Better than average hook discipline
The hook code actually worries about fail-open behavior, malformed JSON, stale state, and classification bypasses.

### Branch-scoped workflow state is the right call
That is a good design for concurrent worktrees/feature branches.

### Intensity levels are a practical compromise
`standard`, `high`, `critical` is a decent answer to the obvious objection that nobody wants formal methods overhead for every CRUD tweak.

### Artifact contracts are a smart pattern
Having specs, verification docs, antipatterns, and audit findings as explicit artifacts makes the workflow less dependent on chat continuity.

## Where I get skeptical

### 1. This is a lot
Not “a lot” as in verbose. A lot as in **organizationally expensive**.

The repo openly admits the time overhead. Even standard mode adds real process weight. Critical mode is basically token-powered penance.

That means adoption risk is huge unless the project has genuine bug-cost pressure.

### 2. Bash is doing a heroic amount of governance
I respect the craft, but there is still a ceiling to how much complexity I want in shell as the enforcement substrate.

They have mitigated that better than most, but the maintenance burden is real.

### 3. Some of the philosophy edges toward workflow maximalism
A repo like this can drift from “prevent important mistakes” into “ritualize every move.”

The intensity model helps, but the system still has a strong cathedral energy.

### 4. The human cost is not just time, it is flow fragmentation
Fresh-agent separation is intellectually sound, but context resets also carry cost. Sometimes the blind spots are worth it, sometimes they just turn one coherent problem-solving session into a bureaucratic relay race.

### 5. Security boundary claims need restraint
To its credit, the architecture doc explicitly says the gate is an accidental-violation catcher, not a true security boundary. That honesty is good and necessary.

## Why it matters

Because Correctless is one of the clearest examples of a broader shift:

from
- “use AI to code faster”

to
- “use AI inside a governed correctness workflow where different agent roles counterbalance each other.”

That is a much more mature pattern.

The repo is effectively asking: what if we treated coding agents less like pair programmers and more like a structured review pipeline with enforced phase boundaries?

That question is worth taking seriously.

## Verdict

Ambitious, overbuilt, and genuinely interesting.

Correctless is one of the more sophisticated Claude Code workflow systems I’ve seen because it does not stop at prompt theater. The hook layer, state machine, branch-scoped artifacts, and agent-separation model are all real. It is trying to operationalize adversarial lenses, not just talk about them.

The cost is obvious: complexity, ceremony, maintenance overhead, and the ever-present risk that workflow discipline becomes workflow cosplay. But this repo clears that bar better than most because the enforcement and testing are substantial.

This is probably overkill for ordinary app work. For high-bug-cost systems, though, it is a serious blueprint.

**Rating:** 4.5/5

## Patterns worth stealing

- Separate agent roles by lens, not just by task name
- Use a real state machine for workflow phases
- Make one component the only state writer
- Enforce phase constraints at tool boundaries, not only in prompts
- Keep branch-scoped workflow artifacts for concurrent work
- Distinguish advisory guidance from actual enforcement
- Accumulate antipatterns and verification artifacts as reusable project memory
- Scale rigor with explicit intensity levels instead of one universal process
