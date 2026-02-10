# Double Diamond Agent Orchestration

> **Source:** [claude-octopus](https://github.com/nyldn/claude-octopus) by nyldn
> **License:** MIT
> **Extracted:** 2026-02-10

## Pattern

Apply the Double Diamond design methodology as a 4-phase agent workflow. Each phase alternates between divergent (explore broadly) and convergent (narrow down) thinking, with different agent configurations per phase.

## The Four Phases

```
   DISCOVER        DEFINE         DEVELOP        DELIVER
   (diverge)     (converge)      (diverge)     (converge)

     Probe          Grasp         Tangle          Ink

   Research →   Requirements →    Build →      Validate
```

### 1. DISCOVER (Probe) 🔍
**Mode:** Divergent — explore broadly

- Multi-provider research (multiple AI models + web search)
- Broad ecosystem analysis and technology comparison
- Best practices research, community insights
- **Output:** Research synthesis document

### 2. DEFINE (Grasp) 🎯
**Mode:** Convergent — narrow down

- Synthesize research findings into consensus
- Define requirements and constraints clearly
- Establish success criteria
- **Output:** Consensus document with requirements

### 3. DEVELOP (Tangle) 🛠️
**Mode:** Divergent — explore implementations

- Multi-provider code generation
- Implementation with quality gates
- Testing, security review, performance optimization
- **Output:** Implementation with validation report

### 4. DELIVER (Ink) ✅
**Mode:** Convergent — final validation

- Quality assurance and final synthesis
- Documentation and delivery certification
- User acceptance
- **Output:** Final delivery document

## Why It Works for AI Agents

1. **Prevents premature convergence** — the Discover phase forces broad research before committing to an approach.
2. **Natural checkpoints** — each phase transition is a gate where the human can redirect.
3. **Different tools per phase** — Discover uses search/research tools; Develop uses code/test tools.
4. **State tracking** — a `STATE.md` file tracks which phase is active, preventing agents from jumping ahead.

## Implementation

Each phase maps to a slash command (`/discover`, `/define`, `/develop`, `/deliver`). State is tracked in `.octo/STATE.md`:

```yaml
current_phase: 2
phase_position: "Define"
status: "in_progress"
```

Phases can be invoked independently but the workflow enforces that earlier phases have completed before later ones begin.

## Adaptation Guide

You don't need the full claude-octopus framework. The core idea:
1. **Split any complex task into these 4 phases**
2. **Use different prompts/models per phase** (cheap+fast for research, expensive+thorough for implementation)
3. **Gate transitions on human approval**
4. **Track state in a file** so the agent knows where it is across sessions
