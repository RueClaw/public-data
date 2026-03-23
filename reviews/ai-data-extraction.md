# ai-data-extraction

*Source: https://github.com/0xSero/ai-data-extraction | License: None (README says MIT, no LICENSE file) | Author: 0xSero + contributors | Reviewed: 2026-03-23*

## Rating: 🔥🔥🔥

## One-liner
Eight Python scripts (zero dependencies, stdlib only) to extract your complete conversation history from every major AI coding assistant — Claude Code, Cursor, Codex, Windsurf, Continue, Gemini CLI, OpenCode, Trae — outputting normalized JSONL for ML training or personal search.

## What It Is

8 standalone Python scripts + a bash wrapper. No pip install, no venv. Python 3.6+ stdlib only. Each script auto-discovers the target tool's data directory across macOS/Linux/Windows, extracts all conversations, and writes timestamped JSONL to `extracted_data/`.

**Covered tools:**
- Claude Code / Claude Desktop (JSONL session files from `~/.claude/projects/`)
- Cursor — **all versions** v0.43 through v2.0+ (SQLite `.vscdb` databases, multiple storage format evolutions)
- Codex (rollout JSONL files from `~/.codex/`)
- Windsurf (VSCode-like SQLite format)
- Continue (JSON session files from `~/.continue/sessions/`)
- Gemini CLI (JSON from `~/.gemini/tmp/[hash]/chats/`)
- OpenCode — CLI and Desktop app (JSON + Tauri `.dat` files)
- Trae (JSONL + SQLite hybrid)

## Output Format

Normalized JSONL — one conversation per line:
```json
{
  "messages": [
    {
      "role": "user",
      "content": "How do I fix this TypeScript error?",
      "code_context": [{ "file": "/path/to/file.ts", "code": "...", "range": {...} }],
      "timestamp": "2025-01-16T14:30:22.123Z"
    },
    {
      "role": "assistant",
      "content": "...",
      "suggested_diffs": [...],
      "model": "claude-sonnet-4-5",
      "timestamp": "2025-01-16T14:30:25.456Z"
    }
  ],
  "source": "cursor-composer",
  "name": "TypeScript Type Error Fix",
  "created_at": 1705414222000
}
```

Fields beyond messages/roles: `code_context` (file paths + snippets + line ranges), `suggested_diffs` (AI-proposed edits), `tool_use` + `tool_results`, `diff_histories`, `model`, `project_path`, `session_id`.

## Impressive Bits

**Cursor extraction is thorough.** The README and script comment trace Cursor's storage evolution across 5 distinct formats from v0.x through v2.0+:
- Old Chat mode: `ItemTable` in workspace SQLite
- Composer v1 inline: messages in `composerData.conversation[]`
- Composer v1→v2 transition: messages in `bubbleId:{composer}:{bubble}` keys
- v2.0+ latest format

Someone reverse-engineered all of this. The `extract_cursor.py` comment is literally titled "ULTIMATE Cursor extraction - EVERY VERSION, EVERY FORMAT."

**Zero dependencies.** `import json, sqlite3, pathlib, datetime, hashlib, platform, os` — everything in stdlib. This is a deliberate choice: the script needs to run anywhere without setup friction.

**Multi-contributor growth.** Started as Claude Code + Cursor, grew by PRs:
- Gemini CLI extractor (cgint)
- Continue + improved Cursor (DISCOVERY commit)
- OpenCode (17ac737)
- OpenCode reasoning + tool use (Aunali321)

## Use Cases Beyond ML Training

The stated purpose is ML fine-tuning (Unsloth/QLoRA example in README), but the extracted data is useful for:

- **Personal search** — grep your entire coding history across all tools
- **Usage analytics** — what models/tools you actually use, conversation frequency
- **Context reconstruction** — recover what you were working on in a given session
- **Agent memory seeding** — bootstrap an agent's context with real prior work history
- **Audit trail** — what AI-suggested code actually made it into your codebase

That last two are the interesting ones from an agent perspective.

## Caveats

**No LICENSE file.** README says "MIT License" but there's no actual LICENSE file in the repo. Per public-data policy: treat as "no explicit license, educational/non-commercial use only."

**Privacy surface area is large.** This extracts file paths, code snippets, API keys if they appeared in conversations, proprietary code, personal projects. The README acknowledges this and recommends `detect-secrets` scan before sharing. Don't run this and upload the output anywhere without a thorough audit.

**No Claude Code OpenClaw sessions.** OpenClaw uses its own session format (LCM-based JSONL at `~/.openclaw/`). This toolkit doesn't cover it. The `extract_claude_code.py` looks at `~/.claude/projects/` — Claude Code CLI sessions, not OpenClaw.

**Snapshots not streams.** These are point-in-time extractions. No watching, no incremental updates, no deduplication across runs.

## Relevance

Directly useful for extracting Codex session history (since Codex is the ACP harness used for coding tasks). `python3 extract_codex.py` → JSONL of all prior Codex sessions including prompts, tool calls, and diffs. Good for reviewing what's been done, seeding context, or fine-tuning.

The Cursor extractor is the most technically impressive piece — understanding 5 generations of SQLite schema evolution is real reverse-engineering work.

## License
No LICENSE file (README claims MIT). Use for personal/educational purposes; attribute 0xSero + contributors.
