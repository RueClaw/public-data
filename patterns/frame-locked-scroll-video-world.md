# Frame-Locked Scroll Video World

**Source:** oso95/scroll-world  
**Repo:** https://github.com/oso95/scroll-world  
**License:** MIT  
**Extracted:** 2026-08-01  

## Pattern

Build a scroll-scrubbed cinematic page as an ordered chain of short video segments whose transitions are anchored on rendered frames, not only on prompt descriptions or original stills.

The key rule is simple: every connector clip starts from the actual last frame of the previous rendered video and ends on the actual first frame of the next rendered video. That keeps the scroll journey visually continuous even when generative video models drift inside individual clips.

## Core Structure

1. Define a small set of journey beats, each with a scene still and copy.
2. Generate scene stills with one shared visual preamble so style stays consistent.
3. Render a "dive" clip for each scene.
4. Extract the final frame of each dive clip and the first frame of the next dive clip.
5. Generate connector clips from those extracted endpoint frames.
6. Interleave dive and connector clips in the browser.
7. Map scroll progress to the current segment and seek video time with `requestAnimationFrame`.
8. Crossfade between adjacent media layers rather than swapping abruptly.
9. Provide a reduced-motion still fallback.
10. Build native mobile clips when quality matters; crop only as a fallback.

## Why It Works

AI video models can satisfy a prompt while changing composition, lighting, or subject geometry during the clip. If a connector is generated from the original stills, it may begin or end on frames the user never actually sees in the rendered sequence.

Extracting endpoints from rendered clips makes continuity concrete. The seam is judged against what exists, not what the prompt intended.

## Design Rules

Use one exact style preamble across all still prompts. Variation should come from the scene beat and camera direction, not from changing the art vocabulary each time.

Keep scene count modest. More beats means more stills, dive clips, connectors, QA passes, and cost.

Ask for budget approval before generation. Scroll worlds can multiply spend quickly because every scene may create several media assets and mobile doubles the chain.

Use browser blobs or otherwise ensure videos are seekable. Scroll scrubbing needs reliable random access; raw remote video URLs can behave inconsistently across hosts and browsers.

Prefer coalesced seeks. Update target time on scroll, then set `currentTime` inside an animation frame loop so scroll events do not overload video decoding.

Treat mobile as its own composition. A desktop fly-through often crops poorly to 9:16; native mobile clips preserve the subject and camera intent.

## Caveats

This pattern depends on media generation quality and provider behavior. Re-probe model schemas, costs, durations, and result URL expiry before a real run.

Continuity still needs human QA. Pixel similarity is a weak proxy; judge composition, subject position, lighting, and motion direction.

Sanitize runtime config if it can come from users. Text escaping is not the same as URL policy enforcement.

---

**Attribution:** Based on oso95/scroll-world, MIT License.
