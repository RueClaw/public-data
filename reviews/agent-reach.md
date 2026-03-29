# Agent-Reach (Panniantong/Agent-Reach)

*Review #287 | Source: https://github.com/Panniantong/Agent-Reach | License: MIT | Author: Panniantong | Reviewed: 2026-03-29 | Stars: 12,720*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A Python CLI + scaffolding layer that gives AI agents read/search access to 15 internet platforms — Twitter, Reddit, YouTube, GitHub, Bilibili, XiaoHongShu, LinkedIn, Weibo, WeChat, V2EX, RSS, Douyin, and more — without paying for APIs.

Key design choice: **Agent Reach is not a wrapper**. After installation, agents call the upstream tools directly (bird CLI, yt-dlp, gh CLI, feedparser, mcporter MCP, etc.). Agent Reach's job is installer + health checker + configuration + SKILL.md registration. The value is in having someone else do the tool selection, dependency management, and integration testing — not in adding another abstraction layer over the tools.

Created 2026-02-24, v1.3.0, 12,720 stars in 33 days. MIT. Currently Chinese-primary but has English docs. Explicitly lists OpenClaw as a supported agent runtime.

---

## Platform Support

**Zero config (works immediately):**
- 🌐 Web — Jina Reader (`curl https://r.jina.ai/URL`)
- 📺 YouTube — subtitle extraction + search via yt-dlp
- 📡 RSS — feedparser
- 📦 GitHub (public repos) — gh CLI
- 💬 WeChat public accounts — search + full-text markdown via camoufox + miku
- 📰 Weibo — hot search, topic search, user timeline, comments
- 💻 V2EX — hot topics, node topics, topic details + replies, user profiles (zero config, public JSON API)
- 📈 Xueqiu (Chinese stock platform) — stock quotes, search, trending posts

**Config needed (free):**
- 🔍 Full web search — Exa via mcporter (free, MCP-based, no API key)

**Login/setup required:**
- 🐦 Twitter/X — bird CLI with Cookie-Editor export
- 📺 Bilibili — yt-dlp works locally, proxy needed on servers
- 📖 Reddit — JSON API + Exa (proxy on server)
- 📕 XiaoHongShu — xiaohongshu-mcp (Docker + cookie)
- 🎵 Douyin — douyin-mcp-server
- 💼 LinkedIn — linkedin-scraper-mcp

**Removed after upstream failure:**
- Instagram — aggressive anti-scraping broke all available tools (instaloader etc.)

---

## Architecture

```
agent_reach/
├── cli.py               — argparse CLI (read, search, doctor, install)
├── core.py              — routing logic
├── config.py            — YAML config (~/.agent-reach/config.yaml, chmod 600)
├── doctor.py            — health check orchestration
├── channels/            — one file per platform
│   ├── base.py          — BaseChannel ABC
│   ├── twitter.py       → bird CLI
│   ├── youtube.py       → yt-dlp
│   ├── github.py        → gh CLI
│   ├── reddit.py        → JSON API + Exa
│   ├── web.py           → Jina Reader
│   ├── rss.py           → feedparser
│   └── ...
├── skill/               — SKILL.md files per agent runtime
└── integrations/        — MCP server integration
```

**Channel contract** (4-method interface):
```python
class Channel(ABC):
    name: str           # e.g. "youtube"
    description: str    # human label
    backends: List[str] # e.g. ["yt-dlp"]
    tier: int           # 0=zero-config, 1=free key, 2=setup needed

    @abstractmethod
    def can_handle(self, url: str) -> bool: ...
    def check(self, config) -> Tuple[str, str]: ...  # (status, message)
    def read(self, url: str) -> str: ...
    def search(self, query: str) -> str: ...
```

Doctor iterates all registered channels, calls `check()`, renders a tiered status report (green/yellow/red). The doctor pattern is clean: channels know their own health, doctor just collects.

---

## Installation Flow

```bash
# Send to your agent:
"帮我安装 Agent Reach: https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/install.md"

# What happens:
# 1. pip install agent-reach
# 2. Auto-installs: Node.js, gh CLI, mcporter, bird CLI
# 3. Configures Exa search via MCP
# 4. Detects local vs server environment
# 5. Registers SKILL.md in agent's skills directory
```

The SKILL.md registration is the key deliverable: after install, the agent reads the skill file and knows which tool to invoke for which platform without being told. "Search Twitter" → bird CLI. "Get YouTube subtitles" → yt-dlp. The agent doesn't need to know the commands.

**OpenClaw-specific note:** Requires `tools.profile = "coding"` in openclaw.json — the installer runs shell commands (pip install, mcporter, bird) that need exec permissions.

**Safety flags:**
- `--safe` — lists what's needed without modifying anything
- `--dry-run` — previews all operations
- `agent-reach doctor` — post-install health check

---

## Tool Selection Rationale

The README documents why each tool was chosen, which makes the substitution surface clear:

| Platform | Tool | Why |
|----------|------|-----|
| Web | Jina Reader | 9.8K stars, free, no API key |
| Twitter | bird CLI | Cookie-based, free; API charges $0.005/read |
| Video | yt-dlp | 148K stars, 1800+ sites |
| Search | Exa via mcporter | Semantic search, MCP, free tier |
| GitHub | gh CLI | Official, full API with auth |
| RSS | feedparser | Python standard, 2.3K stars |

Each entry includes "what to swap in if you don't like it" — the pluggable architecture is intentional, not incidental.

---

## What's Directly Relevant

**We already have most of this.** Our setup already includes:
- bird CLI (Twitter) — in TOOLS.md
- yt-dlp — available
- gh CLI — active as RueClaw
- himalaya — email
- web_fetch / Jina Reader equivalent via OpenClaw
- mcporter — configured for Exa

**What we'd actually get from Agent Reach:**
1. `agent-reach doctor` — a single command to check which channels are working right now. Currently we have no unified health check for our tool ecosystem.
2. The **channel contract pattern** — a clean formalization of what we do ad-hoc. Adding a new tool currently means updating TOOLS.md; the Channel ABC would make this more systematic.
3. V2EX, Weibo, Xueqiu, WeChat public accounts — channels we don't currently have configured.
4. The **SKILL.md auto-registration** concept — when we add a new tool, we should also add a corresponding SKILL.md entry so future sessions automatically know about it.

**The installer is less useful for us** — we already have the tools. The architectural pattern is more interesting.

---

## Security Notes

- Credentials stored at `~/.agent-reach/config.yaml` (chmod 600, not uploaded)
- Cookie-based auth: explicitly recommends burner accounts for Twitter/XHS (bot detection risk + credential blast radius)
- Instagram removed when upstream broke — honest about limitations
- All upstream tools are open-source — transparent dependency chain

---

## Caveats

- Primarily Chinese-language platforms in the interesting columns (XiaoHongShu, Douyin, Bilibili, WeChat, Weibo, Xueqiu, V2EX) — useful for those use cases, irrelevant otherwise
- bird CLI is listed as the Twitter tool — we know from prior review that bird 0.8.0 is broken (Twitter API format changed). Would need verification.
- 12K stars in 33 days = viral in Chinese developer community. Long-term maintenance unclear.
- The "send this URL to your agent and it installs itself" pattern is clever but trusts that the remote install.md doesn't change maliciously — supply-chain concern for any prod deployment.

---

## Verdict

🔥🔥🔥🔥 — The architecture is clean, the pluggable channel pattern is solid, and the `agent-reach doctor` diagnostics concept is directly useful. Most of the actual tools are ones we already have; the value for us is in the health-check pattern and the handful of Asian platform channels we don't have. The "scaffolding, not wrapper" positioning is exactly right — it's notable that they explicitly chose to not add a wrapper layer over the tools. MIT. Cloned to `~/src/Agent-Reach`.
