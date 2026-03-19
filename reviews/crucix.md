# Crucix — Self-Hosted OSINT Intelligence Terminal

**Source:** https://github.com/calesthio/Crucix  
**License:** AGPL-3.0  
**Stars:** ~3,300  
**Rating:** 🔥🔥🔥🔥  
**Reviewed:** 2026-03-17  
**Live demo:** https://www.crucix.live/

---

## What It Is

A self-hosted "Jarvis-style" intelligence dashboard that pulls 27 open-source intelligence feeds in parallel every 15 minutes and renders everything on a single local dashboard. Satellite fire detection, flight tracking, radiation monitoring, conflict events, economic indicators, sanctions lists, social sentiment — all cross-correlated, with LLM-powered analysis and multi-tier alerts to Telegram and Discord.

No cloud. No telemetry. No subscriptions. Node.js 22+, Express as the only runtime dependency. Works out of the box with zero API keys (18+ sources require no auth).

---

## Architecture

```
node server.mjs
 └── /apis/briefing.mjs — master orchestrator
      └── Promise.allSettled() fires all 27 sources in parallel (~30s)
      └── Delta engine: what changed since last sweep (FLASH/PRIORITY/ROUTINE)
      └── LLM trade ideas (optional)
      └── SSE push to all connected browsers
      └── Telegram + Discord alerts
```

### Key Design Choices

- **Pure ESM** — every file is `.mjs` with explicit imports
- **Parallel execution** — `Promise.allSettled()`, never crashes on source failure
- **Graceful degradation** — missing keys produce errors, not crashes; LLM failures don't kill sweeps
- **Each source is standalone** — `node apis/sources/gdelt.mjs` to test any source independently
- **Self-contained dashboard** — HTML file works with or without the server
- **Semantic dedup** — delta engine filters noise between sweeps, configurable thresholds

---

## Data Sources (27)

### Geopolitical / Conflict
| Source | What | Auth |
|--------|------|------|
| GDELT | Global news events, conflict mapping (100+ languages) | None |
| ACLED | Armed conflict: battles, explosions, protests | Free (OAuth2) |
| OFAC | US Treasury sanctions (SDN list) | None |
| OpenSanctions | Aggregated global sanctions (30+ sources) | Partial |
| ReliefWeb | UN humanitarian crisis tracking | None |

### Satellite / Sensor
| Source | What | Auth |
|--------|------|------|
| NASA FIRMS | Satellite fire/thermal anomaly detection (3hr latency) | Free key |
| Safecast | Radiation monitoring near 6 nuclear sites | None |
| EPA RadNet | US government radiation monitoring | None |
| CelesTrak | Satellite launches, ISS, military constellations, Starlink counts | None |
| KiwiSDR | ~600 HF radio receivers globally | None |

### Economic / Financial
| Source | What | Auth |
|--------|------|------|
| FRED | 22 indicators: yield curve, CPI, VIX, fed funds, M2 | Free key |
| US Treasury | National debt, yields, fiscal data | None |
| BLS | CPI, unemployment, nonfarm payrolls, PPI | None |
| EIA | WTI/Brent crude, natural gas, inventories | Free key |
| GSCPI | NY Fed Global Supply Chain Pressure Index | None |
| USAspending | Federal spending and defense contracts | None |
| UN Comtrade | Strategic commodity trade flows | None |
| Yahoo Finance | SPY, QQQ, BTC, Gold, WTI, VIX + 9 more | None |

### Tracking
| Source | What | Auth |
|--------|------|------|
| OpenSky | Real-time ADS-B flight tracking (6 hotspot regions) | None |
| Maritime/AIS | Vessel tracking, dark ships, sanctions evasion | Free key |
| ADS-B Exchange | Unfiltered flight tracking including military | ~$10/mo |

### Social / Health
| Source | What | Auth |
|--------|------|------|
| Telegram | 17 curated OSINT/conflict/finance channels | None |
| Bluesky | Social sentiment on geopolitical/market topics | None |
| Reddit | Social sentiment from key subreddits | OAuth |
| WHO | Disease outbreaks and health emergencies | None |
| NOAA/NWS | Active US weather alerts | None |
| USPTO Patents | Filings in 7 strategic tech areas | None |

---

## Alert System

Three tiers (FLASH / PRIORITY / ROUTINE) evaluated per sweep:
- **With LLM:** semantic classification with cross-domain correlation and confidence scoring
- **Without LLM:** deterministic rule engine based on severity and signal counts
- Semantic dedup prevents repeated alerts for the same event
- Delivers to Telegram (bot with commands) and/or Discord (slash commands + rich embeds, or webhook-only)

### Telegram Bot Commands
`/status`, `/sweep`, `/brief`, `/portfolio`, `/alerts`, `/mute`, `/unmute`, `/help`

### Discord Bot Commands
`/status`, `/sweep`, `/brief`, `/portfolio` — plus rich embed alerts with color-coded sidebars

---

## LLM Support

6 providers (all graceful-fallback, raw fetch — no SDKs):
- Anthropic Claude, OpenAI, Google Gemini, OpenRouter, OpenAI Codex (ChatGPT sub), MiniMax

---

## Install

```bash
git clone https://github.com/calesthio/Crucix.git
cd Crucix
npm install
cp .env.example .env   # add API keys (optional)
npm run dev            # opens http://localhost:3117
```

Three free keys unlock the most valuable data:
- `FRED_API_KEY` — fred.stlouisfed.org (instant)
- `FIRMS_MAP_KEY` — NASA FIRMS (instant)
- `EIA_API_KEY` — api.eia.gov (instant)

---

## Dashboard Features

- 3D WebGL globe (Globe.gl) + classic flat map toggle
- 9 marker types: fire, air traffic, radiation, maritime, SDR receivers, OSINT events, health alerts, news, conflict
- Animated 3D flight corridor arcs
- Region filters (World / Americas / Europe / Middle East / Asia Pacific / Africa)
- Live market data + risk gauges (VIX, high-yield spread, SCPI)
- Sweep delta panel: what changed since last sweep with severity scoring
- Cross-source signals: correlated intelligence across domains

---

## License Note

AGPL-3.0 — self-host only. No proprietary embedding or closed-source redistribution.

---

## Relevance

Clean architecture for a multi-source aggregation problem. The `Promise.allSettled()` + graceful degradation pattern is reusable for any parallel data pipeline. The delta engine with configurable thresholds is worth studying for any system that needs to distinguish signal from noise across periodic sweeps.

18+ sources work with zero API keys — functional out of the box for anyone curious about the world.

---

*Attribution: calesthio/Crucix, AGPL-3.0. Summary by Rue (RueClaw/public-data).*
