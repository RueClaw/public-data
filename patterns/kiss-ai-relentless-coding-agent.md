# "Relentless" Coding Agent Pattern

> Extracted from [KISS AI](https://github.com/ksenxx/kiss_ai) by Koushik Sen (Apache-2.0)

## Core Idea

A single-agent architecture that handles arbitrarily long tasks by chaining bounded sub-sessions with structured progress handoff. Each sub-session reports what it completed and what remains as JSON, enabling the next session to pick up seamlessly.

## The Pattern

```python
# Sub-session prompt structure:

TASK_PROMPT = """
# Task: {task_description}
# Working Directory: {work_dir}
# Rules:
# - BATCH: Combine related commands in ONE Bash() call
# - SUCCESS: Call finish(success=True, summary="done") when complete
# - At step {step_threshold}: finish(success=False,
#     summary={"done":["task A","task B"], "next":["task C"]})
"""

CONTINUATION_PROMPT = """
# CONTINUATION - Pick up where the previous trial left off
# DO NOT recreate files that already exist.
# {existing_files}  ← actual file listing from work_dir
# {progress_text}   ← accumulated done/next from previous sessions
#
# Strategy:
# 1. Verify existing state (ls key files, check tests)
# 2. Identify remaining work from "next" items
# 3. Continue implementation
# 4. Report progress in structured format
"""
```

## Key Mechanisms

### Structured Progress Tracking
```json
{
  "done": ["created database module with CRUD ops", "added unit tests for db"],
  "next": ["add API endpoints", "add integration tests", "write README"]
}
```
- Items are **deduplicated** across sessions (string matching)
- "done" items from prior sessions accumulate
- "next" items tell the new session exactly what to focus on

### Adaptive Step Thresholds
- Early sub-sessions get conservative step limits
- Sub-sessions showing good progress get more steps
- Prevents runaway sessions while rewarding productive ones

### Context Management
- Long tool outputs auto-truncated to fit context window
- Existing file listing injected into continuation prompt
- Progress summary kept compact via deduplication

### Budget Tracking
- Cost tracked across all sub-sessions
- Global budget limit prevents runaway spending
- Token usage monitoring per sub-session

## Why This Works

The fundamental problem: LLM context windows are finite, but real coding tasks can require hundreds of steps. Solutions:

1. **Naive**: One long session → context overflow, degraded output quality
2. **Multi-agent**: Orchestrator + workers → complex, coordination overhead
3. **Relentless**: Single agent, bounded sessions, structured handoff → simple, robust

The key insight is that **structured progress JSON** is a much better handoff mechanism than raw conversation history. It's compact, deduplicated, and tells the next session exactly what to do.

## Integration Points

- Works with Docker isolation (bash commands run in container)
- Path access control (read/write permissions on filesystem)
- Can be wrapped by RepoOptimizer for iterative code improvement
- Composable with the self-evolving pattern (the agent's own code can be evolved)
