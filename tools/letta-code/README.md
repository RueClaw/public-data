# Letta Code — Hook Patterns & Tool Contract

Extracted from [letta-ai/letta-code](https://github.com/letta-ai/letta-code) (Apache 2.0).

## Contents

- `hooks/memory_logger.py` — Git-style memory block diffing with interactive history CLI
- `hooks/block-rm-rf.sh` — PreToolUse: blocks `rm -rf` commands
- `hooks/prompt-instructions.sh` — UserPromptSubmit: injects instructions into every prompt
- `hooks/desktop-notification.sh` — macOS notification on agent events
- `hooks/typecheck-on-changes.sh` — Stop: runs tsc if uncommitted changes exist
- `tool-contract.md` — Client-side tool interface spec (args → { toolReturn, status })
