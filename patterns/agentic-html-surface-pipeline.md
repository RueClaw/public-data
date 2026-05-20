# Agentic HTML Surface Pipeline

- **Source:** https://github.com/nexu-io/html-anything
- **Author:** nexu-io
- **License:** Apache-2.0
- **Extracted from:** `next/src/lib/agents/`, `next/src/lib/templates/skills/`, `next/src/lib/export/`
- **Reviewed:** 2026-05-19

## Pattern

Use local coding-agent CLIs as render engines for designed HTML artifacts.

The user supplies rough content: Markdown, data, notes, CSV, JSON, or an edit request. The app supplies a skill template with strict visual and structural constraints. A local agent CLI generates complete HTML. The app streams that HTML into a sandboxed preview, then exports it to the user's actual publishing target.

The key distinction: Markdown is source material; HTML is the final artifact.

## Pipeline

1. **Detect local agents.** Scan PATH and common install directories for supported CLIs.
2. **Select a skill.** Choose a surface-specific prompt template with metadata, examples, and output rules.
3. **Assemble the prompt.** Combine skill instructions, source content, format metadata, and edit context.
4. **Invoke the local CLI.** Spawn the selected agent process using its known argv/stdin protocol.
5. **Parse output.** Convert agent stdout into structured stream events: deltas, full HTML replacement, metadata, stderr, raw lines, done, and errors.
6. **Preview safely.** Extract the HTML document, debounce updates, and render it in an iframe.
7. **Export by target.** Transform the HTML for platform-specific constraints: inline CSS, image capture, deck packaging, Remotion/Hyperframes, or standalone file.

## Adapter Shape

Each agent adapter should define:

- stable ID and display label;
- primary binary and fallback binary names;
- optional environment variable override;
- invocation protocol: stdin, argv, message flag, JSON-RPC, or unsupported;
- model options, including a default "use CLI config" option;
- argv builder;
- output parser for the CLI's streaming format;
- clear error for installed but unsupported protocols.

This keeps the app's UX provider-agnostic while preserving each CLI's reality.

## Skill Template Shape

Useful template metadata:

- name and localized display names;
- mode or surface type;
- scenario/category;
- aspect ratio or target canvas;
- tags;
- recommended/featured rank;
- example content and example HTML;
- source attribution when inspired by another public design or tool.

Useful template body constraints:

- exact artifact shape;
- required dimensions;
- layout sections;
- typography and color rules;
- allowed external dependencies;
- data-use rules;
- export constraints;
- "do not invent data" rules;
- single-file output requirement.

## Preview And Export

Generated HTML should be treated as an intermediate internal representation, not the only output.

Common export adapters:

- **Standalone HTML:** preserve the full document.
- **PNG/social card:** render the iframe at high DPI and copy/download an image.
- **WeChat/Zhihu/newsletter:** inline CSS and rewrite platform-specific unsupported constructs.
- **Deck:** detect slide sections and provide navigation or packaging.
- **Video frames:** emit frame metadata and package for a rendering pipeline such as Remotion.

The export layer should own platform quirks. The agent prompt should focus on making a good artifact.

## Safety Rules

This pattern crosses several trust boundaries:

- A web request can trigger local process execution.
- Generated HTML may include scripts.
- Export targets may publish publicly.
- Deployment tokens may live on disk.

Minimum safeguards:

- Bind local-only by default and document that it is not a public service.
- Never interpolate prompt text into a shell command.
- Prefer `spawn` with argv arrays.
- Validate agent IDs against a fixed adapter registry.
- Treat custom binary paths and working directories as local-trust features only.
- Render generated HTML in a sandboxed iframe.
- Mask deploy tokens in API responses.
- Store credentials with restrictive filesystem permissions.
- Keep platform publishing behind explicit user action.

## Why It Matters

Agent-generated HTML is a practical way to produce artifacts that Markdown cannot express well: decks, posters, cards, dashboards, data reports, video frames, and platform-specific publishing snippets.

The reusable idea is not a particular design template. It is the pipeline: local agent + constrained skill + streaming preview + target-specific export.

This is especially useful for:

- personal publishing tools;
- internal report generators;
- social-card and newsletter generators;
- agent-native prototyping environments;
- design systems represented as prompts plus examples;
- local-first tools that reuse existing CLI subscriptions instead of managing new API keys.
