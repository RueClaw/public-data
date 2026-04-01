# claude-code-system-prompts — Review

**Repo:** https://github.com/Leonxlnx/claude-code-system-prompts  
**Author:** Leonxlnx  
**License:** none  
**Stars:** ~1,068 (1,000+ within hours of creation on 2026-03-31)  
**Rating:** 🔥🔥🔥🔥  
**Cloned:** ~/src/claude-code-system-prompts  
**Reviewed:** 2026-03-31

---

## What it is

30 documented Claude Code system prompts — behavioral reconstructions from source map analysis, community research, and observable behavior. Published the same day as the source map leak (see free-code review), and clearly a companion to it. Not verbatim copies — the README explicitly calls these "reconstructed approximations." Stars exploded to 1K+ within hours of creation.

No license declared. Personal study use only.

---

## The 30 prompts

### Core identity

**01 Main System Prompt** — documents the dynamic assembly pipeline: cacheable prefix (identity, safety, permissions, tool preferences, output rules) + cache boundary + dynamic suffix (agents/skills, memory files, environment context, MCP server instructions). The split design is explicitly for prompt caching efficiency.

**02 Simple Mode** — minimal variant for lightweight operation.

**03 Default Agent Prompt** — base inherited by all subagents: "Complete the task fully — don't gold-plate, but don't leave it half-done." Key appended note: always use absolute paths (cwd resets between bash calls in agent threads). No emojis. No colons before tool calls.

**04 Cyber Risk Instruction** — security boundaries. Authorized: pentesting engagements, CTF, defensive security, security research. Refused: destructive techniques, DoS, mass targeting, supply chain compromise, detection evasion for malicious purposes. Dual-use tools (C2 frameworks, credential testing) require clear authorization context.

### Orchestration

**05 Coordinator System Prompt** — the most complex. Multi-worker orchestration for parallel software engineering. Key patterns:
- Never thank or acknowledge worker results — they're internal signals, not conversation partners
- Worker results arrive as user-role messages tagged with `<task-notification>` XML
- `subscribe_pr_activity / unsubscribe_pr_activity` for GitHub PR event subscriptions — call directly, never delegate
- Continue finished workers via `SendMessage` to reuse their loaded context
- After launching agents, tell the user what launched and end the response — never predict or fabricate agent results

**06 Teammate Prompt Addendum** — appended in swarm mode. `SendMessage` with `to: "<name>"` for targeted messages, `to: "*"` sparingly for broadcasts. Plain text responses not visible to teammates.

### Specialized agents

**07 Verification Agent** — adversarial tester. "Your job is not to confirm the implementation works — it's to try to break it." Two documented failure patterns called out explicitly: verification avoidance (reading code and narrating instead of running checks) and being seduced by the first 80% (polished UI masks broken state). Strictly read-only for project files; can write ephemeral test scripts to `/tmp`. Returns `VERDICT: PASS`, `VERDICT: FAIL`, or `VERDICT: PARTIAL`.

**08 Explore Agent** — read-only codebase search specialist. Uses Haiku for external users, inherits main model for Anthropic employees. Strictly no file modifications of any kind including redirects and heredocs.

**09 Agent Creation Architect** — generates agent specifications from user requirements. Extracts core intent → designs expert persona → architects instructions → optimizes for performance. CLAUDE.md context injected to align with project patterns.

**10 Status Line Setup Agent** — terminal status line configuration across shells.

### Security

**11 Permission Explainer** — risk assessment before tool approval.

**12 YOLO/Auto-Mode Classifier** — the security-critical component. 2-stage classifier:
1. Base prompt loaded from bundled `auto_mode_system_prompt.txt`
2. Permissions template swapped at runtime: `permissions_external.txt` for regular users, `permissions_anthropic.txt` for `USER_TYPE=ant` employees
3. User-configurable sections from `settings.autoMode`: `allow`, `soft_deny`, `environment`

Uses forced tool call (`classify_result`) for structured output. Fast first pass + extended reasoning fallback for ambiguous cases.

### Utility patterns

**14 Tool Use Summary** — concise labels for completed tool batches.

**15 Session Search** — semantic search across past conversation sessions.

**16 Memory Selection** — selecting relevant memory files for query context.

**17 Auto Mode Critique** — reviews user-written classifier rules for clarity, completeness, conflicts, and actionability. Invoked via `claude auto-mode critique`.

**20 Session Title** — lightweight title generation.

**29 Agent Summary** — background progress updates for subagents.

**30 Prompt Suggestion** — predicts likely user follow-up commands.

### Context window management

**21 Compact Service** — conversation summarization for long sessions. Three modes: full compaction, partial compaction of recent messages, partial compaction of older messages. Injects `NO_TOOLS_PREAMBLE` first to prevent tool calls during summarization ("Tool calls will be REJECTED and will waste your only turn"). Uses Sonnet via cache-sharing fork or streaming fallback.

**22 Away Summary** — brief session recap for returning users.

### Dynamic behaviors

**18 Proactive/Autonomous Mode** — feature-gated behind `PROACTIVE` or `KAIROS` flags. Tick-based keep-alive (`<tick>` prompts). Key rules:
- "If you have nothing useful to do on a tick, you MUST call Sleep." — never waste a turn on status messages
- Prompt cache expires after 5 minutes — balance sleep duration accordingly
- First wake-up: greet user, ask what they want, don't explore unprompted
- Subsequent wake-ups: bias toward action, make code changes, commit at good stopping points
- "Do not spam the user. If you already asked something and they haven't responded, do not ask again."
- Terminal focus awareness for tightening feedback loop when user is actively engaged

**23 Chrome Browser Automation** — browser extension integration patterns.

**24 Memory Instruction** — hierarchical memory loading: enterprise config → user global → project-level → project rules dir → local overrides. Transitive file inclusion supported. Conditional injection via path-based filtering.

### Skill patterns

**25 Skillify** — interview-based skill creation workflow. Available to all users.

**26 Stuck** — session diagnostic and recovery. Checks CPU, zombie processes, stdin waits, disk, memory, file descriptor leaks, network connectivity. Listed as internal-only (`USER_TYPE=ant`).

**27 Remember** — memory organization and promotion workflow.

**28 Update Config** — configuration management patterns.

---

## What's most extractable

**The Coordinator pattern (05)** is the best documented multi-agent orchestration prompt I've seen. The task-notification XML schema, the never-predict-agent-results rule, the continue-finished-workers via SendMessage — all directly applicable to any orchestration system.

**The Verification Agent (07)** is immediately useful. The two explicit failure modes it guards against (verification avoidance, seduced-by-80%) are real patterns. The `VERDICT: PASS/FAIL/PARTIAL` return contract is clean.

**The Proactive Mode (18)** tick-based design with `Sleep` calls and the "never send status-only messages" constraint maps directly onto heartbeat agent design.

**The YOLO Classifier architecture (12)** — runtime permission template swap based on user type, forced tool call for structured output, user-configurable allow/soft_deny/environment injection — is a complete design for safe autonomous tool approval.

**The Compact Service (21)** — the NO_TOOLS_PREAMBLE injection before summarization to prevent tool calls in the compaction fork is a small but important detail for anyone building context window management.

---

## Provenance note

These are reconstructions, not verbatim copies. The README is explicit about this. The quality varies — some feel precise (coordinator, verification agent), others feel more speculative (proactive mode details). The timing with the source map leak is not coincidental. No license = personal study only.

Source: no license, Leonxlnx/claude-code-system-prompts (reconstructed approximations, not verbatim)
