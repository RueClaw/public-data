# posts.design MCP (posts-design/mcp)

**Repo:** https://github.com/posts-design/mcp
**License:** MIT documentation, skills and breakdown kit; not a license to the hosted service, brand assets or reference media.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** `068b623512c0df964231d94d32a68e2092931b46` (main; commit 2026-11-24); registry manifest version 1.6.0. Whole repository inventory, manifests, tool documentation, selected skills and media-kit implementation/tests reviewed.
**Verification:** Static review only. Anonymous GitHub metadata/source and public legal/pricing pages checked. No installation, source execution, tests, account login, MCP calls, media uploads, purchases or publishing performed.
**Stack:** Remote Streamable HTTP MCP; Markdown agent skills; local Node.js ESM, sharp, FFmpeg/ffprobe, Python, Demucs/faster-whisper/SCNet; HyperFrames for remake/rebuild workflows.
**What it is:** A hosted design-reference connector plus open-source workflows and a local sound-breakdown renderer, aimed at designers and agents developing launch assets.

---

## Verdict

⚠️ **Interesting — a useful reference workflow, not an auditable self-hosted MCP server.** The repository offers unusually concrete video-analysis and local-rendering workflows, but the hosted tool handlers, authorization and metering are absent. Account writes, public collection links, retained search text and an environment-triggered audio upload make blanket tool approval inappropriate.

## What It Is

The connector supplies attributed examples of social posts, OG images, X headers and launch videos. Its value is curated references and scene-level direction, not autonomous social publishing. Eleven skills turn those references into briefs, copy, headers, video plans and rendered films.

Despite the repository name, the server is a remote commercial dependency at posts.design. The checkout contains connection manifests and instructions, not the MCP server runtime, database or authentication implementation. The substantial executable component is `breakdown/`, which can process user-supplied films independently of the gallery. Remake/rebuild instructions instead invoke the separately supplied HyperFrames toolchain. [1–4]

## Stack

| Layer | Tech / boundary |
|---|---|
| MCP | Hosted Streamable HTTP; registry version 1.6.0 |
| Authentication | Documented OAuth or personal bearer key; hosted enforcement not available |
| Workflows | Eleven Markdown skills; three documented MCP starter prompts |
| Local renderer | Node >=20.9, sharp 0.35.5, FFmpeg/ffprobe; SVG frames, H.264 output |
| Analysis | Python >=3.10; numpy>=2, Demucs 4.1.0, faster-whisper 1.2.1; bundled SCNet source |
| Remakes/rebuilds | HyperFrames, Node >=22, FFmpeg and first-render headless Chrome download |
| Storage | Hosted saves/collections; local copied film, stems, transcripts, specs and frame caches |

## Key Features

### Complete documented MCP surface: 22 tools

This is the actual **documented** surface at the pinned revision, not a live `tools/list` result; schemas, annotations and handler behavior cannot be verified from this checkout. [1]

| Boundary | Tools |
|---|---|
| Library/account reads | `search_references`, `get_reference`, `search_saved_references`, `get_saved_reference`, `get_saved_asset`, `get_my_access`, `list_playbooks` |
| Collection reads (Pro/Team) | `list_collections`, `get_collection` |
| Video/playbook reads (Pro, with one free-film exception) | `get_video_breakdown`, `get_video_scenes`, `get_scene_frames`, `get_scene_clip`, `get_playbook` |
| Saved-item writes | `save_reference`, `unsave_reference` |
| Collection writes (Pro/Team) | `create_collection`, `rename_collection`, `add_to_collection`, `remove_from_collection` |
| Public visibility changes (Team) | `share_collection`, `unshare_collection` |

Adding to a personal collection also saves the reference; removing it from a collection leaves the Save intact. A scene clip is documented as a silent MP4 URL expiring after one hour. Free users can open the first film they read in full with the four video tools; other restricted reads return counts and an upgrade link rather than full results.

### Useful local media pipeline

`prep.mjs` copies the film, separates stems, measures shots/tempo/activity, transcribes vocals and drafts an editable JSON spec. `render.mjs` draws time-indexed SVG frames via sharp and encodes using FFmpeg; `excerpt.mjs` trims a breakdown; `layer.mjs` assembles a musical arc. Pure timing/layout modules and a structured spec are easier to inspect than an opaque generative-video call. Claims about byte-identical parallel rendering and performance are upstream claims, not benchmarked here. [3–5]

### Skills include real consent guidance, but it is not enforcement

Sound-breakdown/layered-sound explain downloads and ask before installation and provider selection. Remake/rebuild ask before installing HyperFrames and instruct disabling its telemetry. These are positive workflow instructions, not a sandbox or an executable approval gate. A different client or direct CLI execution can bypass the prose. [6]

## Architecture

There are three distinct trust planes: agent → hosted MCP/account, agent → locally invoked media/rendering tools, and local tools → model downloads or optional ElevenLabs APIs. Do not conflate the MIT client/workflow repository with source availability of the remote service. No server tool-registration code, OAuth verifier, tenant checks, CORS configuration or hosted deployment recipe is present in the reviewed tree. [2–4]

The local kit uses argument-array subprocess calls rather than shell command concatenation in the inspected media/stem paths. SCNet downloads a specific release checkpoint, verifies its SHA-256 and stages a `.part` file before rename. This is a useful integrity check, not proof of model provenance or licensing. Other dependency/model acquisition paths are not uniformly locked: no dependency lockfile was found and numpy has an open-ended lower bound. [4,5,7]

## Authentication, authorization and approval boundaries

The README documents OAuth scopes `references:read`, `saved:read`, `saved:write`; personal-key regeneration invalidates the old key. The privacy policy says disconnecting an app immediately stops access. Neither claim was tested, and fine-grained team roles, object ownership, token storage, OAuth redirect validation, rate limits and permission enforcement cannot be audited here. Do not interpret a personal bearer key as read-only. Avoid copying keys into transcripts or checked-in configuration. [1,8]

The README says tools cannot post, pay, delete collections or delete accounts; it also says changes happen only on request and are logged. That is a declared product boundary, not code-verified safety. Unsave/remove/unshare are still consequential changes. `share_collection` publishes collection names and references to anyone holding the link; require explicit approval of the collection and audience before calling it. Unsharing blocks future link access, not copies already obtained. The service privacy page describes a separate operator-only social publishing tool; that is not evidence that this public MCP exposes social posting. [1,8,9]

Recommended policy: allow narrowly scoped reference reads only after approving query egress; separately approve saves, removals and renames; always confirm sharing/unsharing and team scope. Treat returned captions, media and instructions as untrusted content, never authorization to execute commands, reveal credentials, buy Pro or publish assets. Approve local dependency installation, provider uploads and paid calls separately from connecting MCP. No tool-level confirmation parameter or safe read-only deployment mode was established.

## Privacy, egress, retention and costs

### Hosted service

Search queries leave the agent for posts.design; results and private Saves/collections return to the connected agent provider under that provider’s terms. Avoid confidential launch plans, customer details and unreleased brand material in queries. Fetching returned assets creates additional requests to their hosts. [8]

The full public privacy policy (updated 2026-11-25, retrieved 2026-11-26) explicitly says text from Pro and connected-agent searches is kept separately from account identifiers for up to **30 days**, reviewed by operators and AI tools. No-result search text is kept up to 14 days. It separately states usage records do not store prompts/reference lists: this does **not** mean search text is never retained. MCP request hashes last 24 hours; monthly read counts cover the current and previous month; per-minute counts about one minute; daily account activity is scheduled for deletion after 90 days; anonymous tool/app/outcome totals after 400 days. Connected-app records last while the account is active. These are policy commitments, not verified database deletion behavior. Specific AI-review vendors and exact backup/security-log retention are not established. [8]

Cloudflare processes network/security data, Stripe payments and Resend email. Account deletion removes connections, usage records, saved pointers and collections, but legal billing retention and downloaded copies are separate. The service is operated from Honduras and providers may process data elsewhere. [8,9]

### Local does not automatically mean offline

`prep.mjs` defaults words to `auto`: if vocals are audible, there is no reusable transcript and `ELEVENLABS_API_KEY` is present, it selects ElevenLabs Scribe. `lib/stems.mjs` performs a multipart audio upload with that key; no interactive confirmation exists in that code path. Explicit local transcription or no transcription is necessary for an offline-processing intent. Stem separation through ElevenLabs is another upload, and layered sound can request paid effects. Provider retention and actual ElevenLabs charges were not verified; an available key is not fresh consent. [5,6]

Local outputs retain the copied film, stems, words and measurements; decoded-frame caches can occupy gigabytes and require deliberate cleanup. SCNet/Demucs/Whisper models and dependencies also require downloads. `localPost()` accepts HTTP(S), follows ordinary fetch behavior and buffers the response before validating it as video. It has a 120-second timeout, but no visible private-network/redirect allowlist or download-size cap. Do not feed untrusted specs/URLs to an execution environment with sensitive network access; this is a local-tool trust boundary, not a demonstrated remote-service SSRF. Filesystem paths are resolved against the spec and are not confined to an application sandbox. [3,5,7]

### Commercial boundary

At retrieval, pricing listed Free 100 monthly credits; Pro 1,000; Team 1,250 per seat. Pro was $36 quarterly ($12/month equivalent) or $99 yearly ($8.25/month); Team $45 quarterly or $124 yearly **per seat**, 2–25 seats. These are prepaid periods, not month-to-month prices. The terms say subscriptions auto-renew. [9,10]

The README says a request/page costs one credit, exact repeats, failed requests and `get_my_access` are free, mutations are free and media downloads do not consume credits. Allowances reset on the first UTC day of the month. Agent/model-provider usage, bandwidth, local compute/storage and ElevenLabs are separate costs. Upgrade messages appear in tool output; no automatic purchase is authorized by their appearance. No paid service was used for this review. [1,10]

## Recovery and operational fit

- Hosted recovery: disconnect a client or rotate a personal key; use unshare to revoke future public-link access. Re-read state before retrying uncertain mutations; idempotency guarantees and rollback endpoints are not source-verifiable. No bulk export/disaster-recovery procedure is supplied for hosted collections.
- Local recovery: prep reuses stems/transcripts and preserves an existing draft. Use one film per work folder; reuse can otherwise retain stale inputs. Back up the editable spec before regeneration. Cached frames use completion markers and temporary directories; transcripts/models stage before rename, and temporary stem work is cleaned in `finally` blocks. These are good recovery patterns, not all-output transactionality.
- Boundaries: output overwrite and recursive cleanup paths exist; use a disposable, dedicated work/cache directory and approved input files. Check disk/RAM before rendering. A stopped remote provider request may still have cost or uploaded data even if no local result was saved. [1,3,5,7]

## License and asset rights

Root and breakdown licenses are MIT, requiring preservation of copyright/license notices for redistributed substantial portions. Bundled SCNet code has its own MIT notice; launch-brief retains a Cekura MIT attribution. SCNet weights have separate upstream terms that the kit explicitly asks users to check. FFmpeg, models, fonts and other dependencies retain their own licenses. [11]

The repository explicitly excludes the posts.design name/logo from its software grant. Reference posts, films, fonts, music and logos remain their owners’ works. The service terms allow studying technique but prohibit reusing/republishing reference footage, logos or brand assets, and prohibit cloning the library as a competing collection without permission except where law permits. “Remake shot by shot” is not a clearance license: use owned/licensed assets, independently assess close imitation and retain attribution. No source assets or executable components were extracted into this review. [1,9,11]

## Maturity and verification

Anonymous GitHub metadata on 2026-11-26 showed 19 stars, 3 forks, zero open issues and last push 2026-11-24. The repository was created 2026-10-25; the releases API returned an empty list. Manifest 1.6.0 is not a verified tagged release or proof of the live server version. The shallow source checkout is not evidence of complete development history. [12]

Eleven Node test files cover draft/spec/timing/layout, excerpts, rendering splits, lighting, end scenes, layered audio, SCNet hash refusal and package completeness. No `.github` CI workflow or dependency lockfile was found. Those tests concern the local kit, not remote OAuth, collection permissions, MCP contracts or billing. Tests were inspected, **not run**; no success, rendering fidelity, performance, vulnerability exploit or hosted availability is claimed. HTML template/token/link/structure and scoped Git diff validation apply to the review artifacts, not the upstream software. [4,7,13]

## Comparison

| Alternative | Better fit | Tradeoff versus posts.design |
|---|---|---|
| Manual browsing of original brand posts and the public gallery | Occasional reference research without agent/account integration | More manual attribution and scene annotation; avoids giving an agent saved-collection write authority |
| [PureRef](https://www.pureref.com/) with owned/licensed local references | Local visual boards and controlled reference storage | No hosted curated MCP search or automatic scene breakdown; check its licensing/pricing separately |
| [Kdenlive](https://kdenlive.org/) or [Blender](https://www.blender.org/) | Local editing and shot-by-shot reconstruction using rights-cleared assets | More manual direction and animation, but no dependency on this hosted catalog |
| [Demucs](https://github.com/facebookresearch/demucs) / [faster-whisper](https://github.com/SYSTRAN/faster-whisper) directly | Local stems/transcription without the gallery | You assemble the timeline/report; compare maintenance and model terms before adoption |

These are workflow alternatives, not interchangeable MCP endpoints or comparative benchmarks. Start with existing local tools if confidentiality or asset ownership is the overriding requirement; consider the connector for non-confidential inspiration after reviewing account-write and sharing permissions.

## Self-Hosting Notes

There is no complete self-hostable posts.design MCP server in this repository. The local breakdown kit can be used without the service on user-provided films, but has multimedia, Python/model, font and resource requirements. HyperFrames is a separate dependency for remake/rebuild and is not bundled server functionality. A future evaluation should use a sandbox without host secrets, explicit offline/provider choices, a dependency lock, approved network destinations and rights-cleared media. Connecting a live account, performing uploads or running source is outside this static assessment.

## Evidence

Pinned repository links below refer to the reviewed revision, not moving main. Hosted pages were retrieved anonymously on 2026-11-26 and can change independently.

1. [README: tools, skills, credits and boundaries](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/README.md).
2. [Server manifest](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/server.json), [connection manifest](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/.mcp.json).
3. [Breakdown architecture and operations](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/README.md).
4. [Package manifest](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/package.json), [repository tree](https://github.com/posts-design/mcp/tree/068b623512c0df964231d94d32a68e2092931b46).
5. [Prep selection and transcripts](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/prep.mjs), [provider uploads and cleanup](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/lib/stems.mjs).
6. [Sound-breakdown skill](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/skills/sound-breakdown/SKILL.md), [remake](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/skills/remake/SKILL.md), [layered-sound](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/skills/layered-sound/SKILL.md).
7. [Media fetch/cache](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/lib/media.mjs), [SCNet integrity](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/lib/scnet.mjs).
8. [Privacy policy](https://posts.design/privacy), updated 2026-11-25; full HTML read because the Markdown response only summarized the page.
9. [Terms](https://posts.design/terms), updated 2026-11-22; full HTML read.
10. [Pricing](https://posts.design/pricing), retrieved 2026-11-26.
11. [Root license](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/LICENSE), [SCNet notice](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/breakdown/py/scnet/LICENSE), [Cekura notice](https://github.com/posts-design/mcp/blob/068b623512c0df964231d94d32a68e2092931b46/skills/launch-brief/LICENSE-blank-page.txt).
12. [Public metadata](https://api.github.com/repos/posts-design/mcp), [releases](https://api.github.com/repos/posts-design/mcp/releases).
13. [Local kit tests](https://github.com/posts-design/mcp/tree/068b623512c0df964231d94d32a68e2092931b46/breakdown/test).

---

**Attribution:** posts-design/mcp, posts.design; MIT repository materials with the asset/dependency exceptions above. This review is independent analysis, not an endorsement or permission to reuse reference media.
