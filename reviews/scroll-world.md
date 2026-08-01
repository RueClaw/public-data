# Scroll World (oso95/scroll-world)

**Repo:** https://github.com/oso95/scroll-world  
**License:** MIT  
**Reviewed:** 2026-08-01  
**Stack:** Agent Skill, Claude plugin metadata, vanilla JavaScript, HTML/CSS, Bash pipeline snippets, Python/Pillow, ffmpeg, Monid, Higgsfield, Codex image generation  
**What it is:** An agent skill for turning a brand or story into a scroll-scrubbed 3D-feeling landing page built from AI-generated stills, dive clips, connector clips, and a small zero-dependency browser runtime.

---

## Verdict

✅ **Deploy candidate for deliberate cinematic site builds, not casual default use.** Scroll World is a well-shaped skill package: the intake prompts, budget gates, scene continuity rules, mobile strategy, and scrub engine all show real production taste. The main caveat is operational: good results depend on paid/volatile media-generation providers, careful seam QA, and trusted configuration. Use it when the project actually wants a scroll-driven video world and the user has approved generation spend.

---

## What It Is

Scroll World packages the process for building immersive "fly through the brand world" pages. The skill asks for subject, brand kit, art direction, camera language, journey beats, mobile requirements, and budget, then guides an agent through:

1. generating a set of cohesive scene stills;
2. optionally cutting subjects out into transparent layers;
3. producing dive clips for each still;
4. extracting true end/start frames from rendered clips;
5. generating connector clips between those exact frames;
6. wiring the assets into a vanilla scroll-scrub runtime.

The strongest idea is that the visual chain is treated as a continuity problem, not a pile of independent videos. Connectors should begin and end on frames extracted from actual rendered clips, so transitions are judged by composition and seam continuity rather than raw similarity to the source prompts.

## Stack

| Layer | Tech |
|-------|------|
| Packaging | Claude plugin metadata, `SKILL.md`, Vercel skills install notes |
| Agent workflow | Markdown skill instructions and prompt templates |
| Still generation | Higgsfield, optional Codex image generation |
| Video generation | Monid default path, Higgsfield fallback, Kling fallback notes |
| Media processing | `ffmpeg`, `ffprobe`, Bash 3.2-compatible snippets |
| Helper script | Python/Pillow flood-fill knockout |
| Frontend runtime | Vanilla JS `mountScrollWorld(container, config)` engine |
| Example | Standalone `index-template.html` |

## Key Features

### Frame-Locked Seam Discipline

The pipeline repeatedly emphasizes that connectors must use the actual final frame of one clip and the actual first frame of the next clip. That avoids a common AI-video failure mode where the source stills look coherent but the rendered video endpoints drift before transition.

This is the repo's most reusable pattern: design the scroll journey around rendered-frame continuity, not prompt continuity.

### Budget-Aware Intake

The skill explicitly asks for budget and approval before generation. That matters because the intended providers can spend real credits quickly: multiple scene stills, multiple dive videos, multiple connector videos, and optional native mobile variants.

The prompts also tell the agent to verify provider availability and schema details before running batches, which is realistic for fast-moving media APIs.

### Native Mobile Path

Scroll World does not treat mobile as an automatic crop. It asks whether the user wants a native 9:16 chain, then provides a separate mobile pipeline. The fallback crop path is documented, but the skill treats it as lower quality.

### Scrub Engine

`scrub-engine.js` is a small reusable browser runtime. It:

- interleaves dive and connector segments;
- fetches videos into blobs for seekable playback;
- maps scroll progress to segment-local video time;
- coalesces seeks through `requestAnimationFrame`;
- crossfades active/inactive layers;
- supports mobile clip variants;
- primes iOS videos;
- provides reduced-motion still fallback;
- renders copy and route navigation from config.

It is intentionally plain JavaScript rather than a framework component, which makes it easy to drop into one-off landing pages.

### Practical Fallback Notes

The references include provider-specific gotchas: Monid result URLs can expire, model schemas should be probed, NSFW false positives can require alternate providers, and concurrency should be kept conservative to avoid wasting credits.

## Caveats

- **Paid external services are central.** The best path assumes Monid/Higgsfield/Kling or Codex image generation access, auth, and balance.
- **No CI or test suite.** The repo is a skill and example assets pipeline, not a packaged application with automated coverage.
- **Provider interfaces are volatile.** The skill tells the operator to inspect current schemas and costs before use; that is not optional.
- **Config should be trusted.** The scrub engine escapes copy strings before injecting HTML, but CTA URLs are escaped rather than protocol-policy checked. Do not pass untrusted config without URL validation.
- **Shell snippets assume sane slugs and paths.** Keep section ids and filenames simple, quoted, and generated by the agent rather than pasted from untrusted input.
- **README embeds a Star History URL with a sealed token.** It appears to be a public chart token, not a project secret, but it is still an odd public embed detail.

## Verification

Local checks performed on 2026-08-01:

- `python3 -m py_compile skills/scroll-world/references/knockout.py` passed.
- `node --check skills/scroll-world/references/scrub-engine.js` passed.
- `jq empty .claude-plugin/plugin.json .claude-plugin/marketplace.json` passed.

The generation pipeline itself was not executed because it would require authenticated paid media-generation services and user budget approval.

## Reuse Notes

The browser runtime and the frame-locked seam workflow are the portable parts. The provider scripts should be treated as runbook snippets that need current API probing before each real project.

Good fit:

- cinematic product or venue landing pages;
- portfolio demos where custom motion is worth the cost;
- agent-skill examples for budget-gated media generation;
- reusable scroll-video UI experiments.

Poor fit:

- routine SaaS/admin/productivity UIs;
- projects needing deterministic builds without external media APIs;
- untrusted multi-user config without URL sanitization;
- low-budget static sites where a still image or short hero video would do.

---

**Attribution:** oso95/scroll-world, MIT License
