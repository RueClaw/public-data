# Remotion — Repo Review

**Repo:** https://github.com/remotion-dev/remotion  
**License:** Custom (source-available, NOT open source — see below)  
**Language:** TypeScript / React  
**Stars:** ~22K+  
**Cloned:** ~/src/remotion  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

**Make videos programmatically with React.** You write React components, declare timelines with props, and Remotion renders them to real video (MP4, WebM, GIF) via headless Chromium. Every CSS/Canvas/SVG/WebGL feature works. Think of it as "React, but time is a prop."

Core mental model:
```tsx
const MyVideo = () => {
  const frame = useCurrentFrame();       // 0..durationInFrames
  const { fps, width, height } = useVideoConfig();
  return <div style={{ opacity: frame / 30 }}>Hello</div>;
};
```

Render a 30fps video by stepping through frames 0→N, screenshotting each, stitching. No animation magic — just React at each frame.

---

## Architecture

### Core Rendering Pipeline
- **Remotion Studio:** local dev server with a scrubable timeline preview (like a video editor but in the browser)
- **`remotion render`:** CLI renders via headless Chromium (Puppeteer under the hood)
- **`@remotion/lambda`:** distributed render on AWS Lambda — spawns N lambdas in parallel, each renders a chunk, final lambda stitches. Scales to ~1000 concurrent Lambda invocations. Cost: pennies per render-minute.
- **`@remotion/cloudrun`:** same pattern on GCP Cloud Run
- **`@remotion/ssr`:** self-hosted server-side rendering

### Key APIs
- `useCurrentFrame()` — current frame number
- `useVideoConfig()` — fps, width, height, durationInFrames
- `<Sequence>` — time-shifted sub-composition
- `<Audio>`, `<Video>`, `<Img>` — media with frame-aware timing
- `interpolate()` — map frame → value with easing
- `spring()` — physics-based animation
- `<AbsoluteFill>` — full-canvas positioning

### AI Integration
Has a first-class **Claude Code integration** documented at `/docs/ai/claude-code` — specifically designed for prompting video generation via LLM. Remotion knows agents write code, so they've optimized the scaffolding and prompts for it.

---

## License — IMPORTANT

**Not open source.** Custom source-available license with a company tier:

| Entity | Cost |
|---|---|
| Individuals | Free (even commercial) |
| ≤3 employee for-profit | Free |
| Non-profit | Free |
| Larger for-profit companies | Paid company license (remotion.pro) |

You **cannot** fork and resell a Remotion derivative. Source is available, free to use and modify for your own purposes, but not for sublicensing.

**For our use:** Jon + Rue = individual/tiny org → **free**. No license needed for personal/homelab video generation. This is fine.

---

## Use Cases Worth Noting

### Programmatic Video Generation
This is the killer app. If we ever want to:
- Auto-generate market brief videos (from the market-brief skill output)
- Create animated explainer videos from data
- Generate personalized video reports
- Build TikTok/YouTube-ready content from structured data

...Remotion is the answer. You write React → you get a video file. No video editing software, no manual timeline, no After Effects.

### AI-Driven Video
The Claude Code integration is telling — they've thought hard about LLMs generating video compositions. An agent could:
1. Get a data payload (e.g., market brief JSON)
2. Write Remotion components with `useCurrentFrame`
3. Render to MP4
4. Post to Discord/upload anywhere

### Lambda Scaling
For batch rendering (many videos), the Lambda approach is the right architecture. Spawn 100 lambdas, each renders 3 seconds, stitch. Render a 5-minute video in ~30 seconds for a few cents.

---

## What's Not Interesting

- The internal rendering infra is Chromium-based — not something to customize
- Requires Node.js; won't run in Python
- Large monorepo (~200+ packages) — complex to navigate but well-documented
- Not useful for screen recording, camera capture, or real-time video

---

## Verdict

Excellent, mature tool for **programmatic video creation from React components**. The AI/Claude Code integration is a first-class design decision. For us: zero licensing cost, and it's the right answer if we ever want to automate video generation (market briefs, reports, summaries as video). Not urgent, but worth knowing cold when the use case comes up.

The `interpolate()` + `spring()` + `useCurrentFrame()` API is remarkably clean — generating data-driven animations is genuinely easy once you grok the "frame as prop" mental model.

---

*Source: https://github.com/remotion-dev/remotion | License: Custom source-available (free for individuals/small orgs) | Reviewed: 2026-03-21*
