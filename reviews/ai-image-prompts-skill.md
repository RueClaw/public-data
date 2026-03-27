# ai-image-prompts-skill (YouMind-OpenLab/ai-image-prompts-skill)

*Review #271 | Source: https://github.com/YouMind-OpenLab/ai-image-prompts-skill | License: MIT | Author: YouMind-OpenLab | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥

---

## What It Is

An OpenClaw/Claude Code skill that gives agents access to a curated library of ~11,900 image generation prompts, organized by use case, each with sample images showing actual output. Two modes: semantic search (describe what you want, get top 3 matching prompts + sample images) and content illustration (paste article/script, get matching visual styles).

Model-agnostic: prompts work with Midjourney, DALL-E 3, Flux, Stable Diffusion, GPT Image 1.5, Gemini image models, etc.

Updated twice daily via GitHub Actions pulling from YouMind's CMS.

---

## What's In It

**11 categories (11,889 prompts as of review):**
- Social Media Post: 7,404
- Product Marketing: 4,360
- Profile / Avatar: 1,229
- Poster / Flyer: 571
- Infographic / Edu Visual: 503
- E-commerce Main Image: 424
- Game Asset: 415
- Comic / Storyboard: 337
- YouTube Thumbnail: 196
- App / Web Design: 190
- Uncategorized: 1,259

**Data format per prompt:**
```json
{
  "id": 498,
  "content": "actual prompt text...",
  "title": "Hand-drawn style header image prompt from photo",
  "description": "short description",
  "sourceMedia": ["https://cdn.youmind.com/...jpg"],
  "needReferenceImages": false
}
```

178K lines of JSON across reference files. The `scripts/generate-references.ts` pulls from YouMind's private CMS (requires `CMS_HOST` + `CMS_API_KEY` env vars), but the output JSON is committed to the repo publicly — no API key needed for consumers.

---

## How the Skill Works

The SKILL.md instructs the agent to:
1. Read `references/manifest.json` to find category files
2. Check staleness (`node scripts/setup.js --check`)
3. Load the relevant category JSON based on user's request
4. Do semantic matching (agent's own reasoning over the JSON data)
5. Return top 3 matches WITH sample images mandatory — the skill explicitly flags that text-only recommendations are wrong

The "content illustration" workflow: paste article text → agent analyzes theme/tone/audience → searches for matching prompt templates → user picks style → agent remixes the prompt with specific content details.

---

## What It's Good For

**Genuinely useful if you're doing image generation work.** The value isn't the technology (it's just JSON + agent reasoning), it's the curation — 11K+ prompts sourced from real creators who actually got good results, with images proving it works.

The twice-daily update cadence via GitHub Actions means it tracks viral prompts from the community automatically. That's the right data pipeline: CMS → GitHub Actions → committed JSON → agents consume via file reads, no API dependency at runtime.

The `needReferenceImages` field is interesting — it flags prompts that require you to upload a reference photo (e.g., "recreate this person in X style"), which helps agents avoid recommending those when the user doesn't have images to provide.

---

## Honest Assessment

**This is a data product dressed as a skill.** The skill logic itself is thin — load JSON, do semantic search via agent reasoning, return results with images. The value is entirely in the 11,900 curated prompts with verified sample outputs. That's real value, but it's not a technical achievement.

**The YouMind product pitch is visible throughout.** Several prompts reference "Nano Banana Pro" (YouMind's image generation product). The skill is also a discovery mechanism for their platform. Not a dealbreaker, but worth knowing.

**No vector search.** The semantic matching is done entirely by the LLM reasoning over JSON — not a dedicated retrieval system. At 11K prompts, this means the agent typically searches one category file at a time (category routing first, then match within). It works, but it's not RAG.

**MIT license.** The prompts are community-sourced and free to use.

---

## Relevance

**Practical for creative/marketing work** — if you're generating images for VOS documents, marketing materials, or any project requiring image gen, having pre-validated prompts with sample outputs is faster than trial and error.

**The data pipeline pattern is worth noting:** private CMS → GitHub Actions export → public JSON → agent file reads. This is a clean pattern for publishing live-updating reference data that agents can consume without API dependencies. Stealable for Marcos's KB, for public-data updates, for anything that has a CMS backend and wants agent-accessible snapshots.

**The `needReferenceImages` field** as a structured boolean flag for "this prompt requires extra input" is a useful pattern for any skill that has prompts/templates with varying input requirements.
