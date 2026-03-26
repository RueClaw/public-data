# MoneyPrinterV2 — #260

**Repo:** https://github.com/FujiwaraChoki/MoneyPrinterV2  
**Author:** FujiwaraChoki (Sami Fujiwara / @DevBySami)  
**License:** AGPL-3.0  
**Language:** Python 3.12  
**Stars:** 25,776 | **Forks:** 2,676  
**Created:** 2024-02-12 | **Reviewed:** 2026-03-25  
**Rating:** 🔥🔥🔥  
**Cloned:** ~/src/MoneyPrinterV2

---

## What It Is

Automation platform for "passive income" content pipelines. Four modules:

1. **YouTube Shorts automater** — generate topic → script → metadata → AI image prompts → images → TTS audio → video assembly (MoviePy) → subtitle burn-in → upload via Selenium/Firefox
2. **Twitter bot** — LLM-generated tweets, scheduling via `schedule`
3. **Affiliate marketing** — Amazon product pitch generation → auto-post to Twitter
4. **Outreach** — Google Maps scraper (Go binary) → cold email via yagmail + SMTP

Config: `config.json` with Ollama, Gemini, AssemblyAI, Firefox profile paths, SMTP credentials.

---

## Architecture

~3000 lines of Python across `src/classes/` (YouTube, Twitter, AFM, Outreach, TTS) plus a menu-driven `main.py`. CRON scheduling via `schedule` library. Video pipeline uses MoviePy + ImageMagick. Browser automation via Selenium + Firefox (headless supported).

**Full pipeline for a YouTube Short:**
```
LLM → topic
LLM → script (n sentences of configurable length)
LLM → image prompts (one per sentence)
Gemini image API → images
Local Whisper / AssemblyAI → STT for timing
TTS (configurable voice) → audio
MoviePy → stitch images + audio + subtitles (SubtitlesClip)
Selenium/Firefox → upload to YouTube
```

**Outreach pipeline:**
```
google-maps-scraper (Go) → business CSV with emails
LLM → personalized pitch per business
yagmail → send HTML email via Gmail SMTP
```

---

## What's Useful

**Full video assembly pipeline** — the MoviePy + ImageMagick + SubtitlesClip stack in `YouTube.py` (~878 lines) is the most reusable piece. It's a working reference for: image sequence → timed TTS audio → subtitle burn-in → final video. Not elegant but functional.

**Multi-provider LLM abstraction** (`llm_provider.py`) — wraps Ollama + Gemini. Minimal but a clean starting point.

**Google Maps → email pipeline** — uses the open-source `gosom/google-maps-scraper` Go binary, parses CSV, LLM-generates personalized outreach messages. The scraper integration pattern is useful independent of the marketing use case.

**25K stars** — this is real signal that people want automated content pipelines. The demand is legitimate; the implementation is reference-grade.

---

## What's Weak

The code is functional but rough — global imports from `cache`, `utils`, `config`, `constants` everywhere, no real abstraction beyond the class layer. The YouTube class is 878 lines doing 7+ distinct things. Error handling is minimal.

AGPL-3.0 is the most restrictive OSS license — if you use it in any networked service, you must open-source your entire app. Fine for personal automation, not for any product.

The "make money online" framing and the YouTube/Twitter automation are legally and platform-policy gray areas. YouTube's ToS prohibits automated uploads without their API; the Selenium approach uploads via the browser UI to dodge this. Twitter's ToS prohibits automated posting without their API. These pipelines work until they don't.

---

## Relevance

**Direct relevance: moderate.** We don't need the money-printing angle, but the video assembly pipeline is a working reference for the Parkinson's project — specifically, if we ever want to generate video summaries or visual aids for Marcos. The MoviePy + TTS + subtitle pipeline is exactly what you'd need.

**LarryLoop** (#246) was the polished SaaS version of this concept. MoneyPrinterV2 is the scrappy open-source version that's been running in the wild for 2 years and has 2.6K forks. More battle-tested, less polished.

**For vidameat / content marketing (zob's question from review #246):** This is the most complete open-source answer. LarryLoop and Remotion (#241) are the cleaner alternatives, but this one is free and runs locally.

---

## Verdict

🔥🔥🔥 — 25K stars reflects real demand for content automation pipelines. The YouTube video assembly stack (`YouTube.py`) is a useful reference. AGPL limits reuse in any networked product. The gray-area ToS surface is a liability for anything production-facing. Good as a study object; don't copy-paste into anything public-facing.

**Worth stealing (MIT-clean extraction needed):** MoviePy + SubtitlesClip pipeline pattern from `YouTube.py`. Multi-provider LLM wrapper pattern from `llm_provider.py`.
