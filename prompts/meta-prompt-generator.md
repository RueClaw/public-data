# Meta-Prompt Generator

> **Source:** [claude-octopus](https://github.com/nyldn/claude-octopus) by nyldn
> **License:** MIT
> **Extracted:** 2026-02-10

## Purpose

Generate well-structured, verifiable prompts using five proven techniques. Turns vague requests into reliable, hallucination-resistant prompts.

## The Five Techniques

### 1. Task Decomposition
Break complex tasks into smaller subtasks with dependencies.
- List all components
- Identify what must happen first
- Group related components
- Order by logical sequence

### 2. Fresh Eyes Review
Use different "experts" for creation vs. validation. Never let the same expert both create and verify.
- Creator: "Expert Technical Writer" produces article
- Reviewer: "Expert Security Engineer" verifies claims
- Reviewer: "Expert Developer" tests code examples

### 3. Iterative Verification
Build explicit verification steps into the prompt.
- After calculations: "Verify by recalculating from opposite direction"
- After code: "Test against these cases"
- After claims: "Confirm by citing source"
- Only proceed when verification passes

### 4. No Guessing
Never assume unverified facts. Disclaim uncertainty explicitly.
- "Note: This figure is approximate and should be verified."
- "I don't have access to [specific data]. Please provide or verify."

### 5. Specialized Experts
Spawn domain-specific personas for subtasks.

| Expert | Use For |
|--------|---------|
| Writer | Content, documentation |
| Mathematician | Calculations, proofs |
| Security | Security review, threat modeling |
| Architect | System design, trade-offs |
| Reviewer | QA, error-finding |

## Generated Prompt Template

```markdown
# [Prompt Title]

## Role
[Role definition + emphasis on verification and uncertainty disclaimers]

## Context
[User's task, goals, background, clarifications]

## Instructions

### Phase 1: [Name]
1. [Step]
2. [Step]
3. **Verification:** [How to verify this phase]

### Phase 2: [Name]
1. [Step]
2. **Verification:** [How to verify]

### Expert Assignments (if applicable)
- **[Expert]:** Handles [subtask]
- **[Reviewer]:** Validates [what]

## Constraints
- [Constraint list]
- [How to handle uncertainty]

## Output Format
[Exact structure of expected output]

## Verification Checklist
- [ ] [Item 1]
- [ ] [Accuracy disclaimers added where needed]
```

## Complexity Assessment

| Complexity | Indicators | Approach |
|------------|-----------|----------|
| Simple | Single step, one output | Direct prompt, no decomposition |
| Moderate | 2-3 steps, clear sequence | Light decomposition, one expert |
| Complex | 4+ steps, dependencies | Full decomposition, multiple experts |

## Usage

Invoke when someone asks to "create a prompt for X", "optimize this prompt", or "help me write a prompt". Do NOT use for direct task execution — just do the task instead.
