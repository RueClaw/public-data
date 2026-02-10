# Persona-Based Agent Routing

> **Source:** [claude-octopus](https://github.com/nyldn/claude-octopus) by nyldn
> **License:** MIT
> **Extracted:** 2026-02-10

## Pattern

Define a library of expert personas with structured routing metadata (`when_to_use`, `avoid_if`, `examples`) so a coordinator agent can select the right specialist without ambiguity. Each persona is a self-contained markdown file with YAML frontmatter.

## Why It Works

- **Explicit routing hints** eliminate guesswork — the coordinator matches user intent against `when_to_use`/`avoid_if` fields rather than inferring from vague descriptions.
- **Negative routing** (`avoid_if`) prevents misrouting by clarifying boundaries between similar personas.
- **Examples with expected outcomes** give the router concrete pattern-matching targets.

## Frontmatter Schema

```yaml
name: code-reviewer
description: "One-line capability summary"
model: opus                    # Suggested model tier
memory: project                # Memory scope: user | project | none
tools: ["Read", "Grep", "Bash", "Task(security-auditor)"]  # Available tools
when_to_use: |
  - PR reviews and code quality assessment
  - Best practices enforcement
  - Technical debt identification
avoid_if: |
  - Security-focused review (use security-auditor)
  - Performance profiling (use performance-engineer)
  - Architecture decisions (use backend-architect)
examples:
  - prompt: "Review this auth module for quality issues"
    outcome: "Code smells, pattern violations, refactoring suggestions"
hooks:                          # Optional automation
  PostToolUse:
    - matcher: { tool: Bash }
      command: "./hooks/code-quality-gate.sh"
```

## Representative Personas (3 of 29)

### Strategy Analyst
```yaml
when_to_use: |
  - Market sizing and opportunity analysis
  - Competitive landscape assessment
  - SWOT, Porter's Five Forces, BCG matrix
avoid_if: |
  - Technical implementation (use dev agents)
  - User research synthesis (use ux-researcher)
  - Academic research (use research-synthesizer)
```

### Thought Partner
```yaml
when_to_use: |
  - Brainstorming and ideation sessions
  - Uncovering hidden assumptions
  - Naming unnamed concepts
avoid_if: |
  - Technical research (use research-synthesizer)
  - Decision making with clear options (use strategy-analyst)
  - Direct problem solving (just solve it)
```

### Code Reviewer
```yaml
when_to_use: |
  - PR reviews and code quality assessment
  - Clean code principles and SOLID adherence
  - Technical debt identification
avoid_if: |
  - Security-focused review (use security-auditor)
  - Performance profiling (use performance-engineer)
  - Database optimization (use database-architect)
```

## Full Persona List

29 personas covering: academic-writer, ai-engineer, backend-architect, business-analyst, cloud-architect, code-reviewer, content-analyst, context-manager, database-architect, debugger, deployment-engineer, devops-troubleshooter, docs-architect, exec-communicator, frontend-developer, graphql-architect, incident-responder, mermaid-expert, performance-engineer, product-writer, python-pro, research-synthesizer, security-auditor, strategy-analyst, tdd-orchestrator, test-automator, thought-partner, typescript-pro, ux-researcher.

## Implementation Tips

1. **Router prompt**: Feed all `when_to_use`/`avoid_if` blocks as a routing table to the coordinator. It picks the best match.
2. **Fallback**: If no persona scores high, use a general-purpose agent.
3. **Chaining**: Personas can delegate via `Task()` tools (e.g., code-reviewer spawns security-auditor).
4. **Model tiering**: Use `model` field to assign expensive models (opus) only to complex personas and cheaper models (sonnet) to simpler ones.
