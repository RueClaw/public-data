# AgentFS: Virtual Filesystem Sandboxing for Agents

> **Source:** [workflows-acp](https://github.com/AstraBert/workflows-acp) by AstraBert
> **License:** MIT
> **Extracted:** 2026-02-10

## Pattern

Instead of giving agents direct filesystem access, load project files into a virtual filesystem (AgentFS) and expose read/write/grep/glob operations against it. The agent operates on a snapshot, not the live filesystem.

## How It Works

1. **On startup**, walk the project directory and load all files into an AgentFS database (SQLite-backed via `agentfs-sdk`)
2. **Agent tools** (`read_file`, `write_file`, `edit_file`, `describe_dir_content`, `grep_file_content`, `glob_paths`) operate against the virtual FS
3. **Filtering**: skip directories (`.git`, `node_modules`, `__pycache__`) and files (`.env`, lockfiles) via configurable exclusion lists
4. The AgentFS database file is auto-added to `.gitignore`

## Tool Interface

Each tool has a real-FS version and an AgentFS version. The agent framework selects which set to use based on configuration:

```python
# Real filesystem tools
TOOLS = [read_file, write_file, edit_file, describe_dir_content, ...]

# AgentFS-backed tools (same interface, sandboxed)  
AGENTFS_TOOLS = [read_file_agentfs, write_file_agentfs, edit_file_agentfs, ...]
```

The tools have identical signatures — `read_file(file_path)`, `write_file(file_path, content, overwrite)`, etc. — so the agent doesn't know or care which backend is active.

## Benefits

- **Safety**: agent writes go to a virtual FS, not your real files
- **Reproducibility**: the snapshot is a point-in-time view
- **Speed**: file operations hit an indexed database, not disk I/O
- **Auditability**: all reads/writes are logged through the tool layer

## When to Use

- Untrusted or experimental agent runs
- Multi-agent scenarios where you want isolation
- When you need to let agents "write files" without risking real project state
- Demo/sandbox environments

## Limitations

- The snapshot is stale — if real files change after loading, the agent won't see updates
- Writes don't persist to disk unless you explicitly sync back
- Binary files may not round-trip cleanly
