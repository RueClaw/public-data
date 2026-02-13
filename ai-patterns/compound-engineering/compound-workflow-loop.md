# Compound Engineering Workflow Loop

> Extracted from [compound-engineering-pi](https://github.com/gvkhosla/compound-engineering-pi) by Every/Kieran Klaassen (MIT License).

## The Loop

```
Plan → Work → Review → Compound
```

Each phase compounds knowledge for the next cycle.

### Plan
1. **Idea refinement** — collaborative dialogue, check for existing brainstorms
2. **Local research** (parallel) — repo analyst + learnings researcher scan codebase
3. **Research decision** — based on risk/familiarity, decide if external research needed
4. **External research** (conditional, parallel) — best practices + framework docs
5. **Consolidate** — merge findings, file paths, learnings, conventions
6. **Structure** — choose detail level (Minimal/Standard/Comprehensive), write plan doc
7. **SpecFlow analysis** — validate and find gaps

### Work
Execute from the plan. AI-assisted implementation.

### Review
Multi-agent code review with specialized reviewers:
- **Persona reviewers** — DHH (Rails purity), Kieran (strict conventions per language)
- **Specialist reviewers** — Security sentinel, performance oracle, architecture strategist
- **Pattern reviewers** — Schema drift detector, data integrity guardian, agent-native reviewer

### Compound
Document what was learned. Parallel subagents:
1. Context Analyzer → YAML frontmatter
2. Solution Extractor → root cause + fix
3. Related Docs Finder → cross-references
4. Prevention Strategist → how to avoid next time
5. Category Classifier → where to file it

Assembly agent combines into `docs/solutions/<category>/<slug>.md` with searchable frontmatter.

**Why it compounds:** Next time a similar problem appears, the learnings researcher finds the solution doc during the Plan phase.
