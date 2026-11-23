# Open Diagram (lukendeasy/open-diagram)

**Repo:** https://github.com/lukendeasy/open-diagram
**License:** MIT code (retain copyright/license); bundled Inter is SIL OFL 1.1; cloud icons retain provider terms.
**Reviewed:** 2026-11-23 (UTC)
**Revision:** e2f9e788778968ab28f8f35a6396554f644be553 (main); scope: README, manifests, license/font notice, Python library/CLI/MCP, examples, tests, workflows and icon integration.
**Release:** Latest public release v0.4.0, published 2026-11-19; tag points to 387b2c09bfb9115b288f302cefeb4115ab043177. Main is newer; package manifest still says 0.4.0.
**Verification:** Static review only; no installation, source execution, local tests, browser launch or provider calls. GitHub reports test and diagrams CI successful at the reviewed SHA; this is upstream evidence, not a local reproduction.
**Stack:** Python 3.9+, fontTools, bundled Inter, optional Chrome-family PNG renderer, optional MCP (Python 3.10+).
**What it is:** A diagram-as-code library for dense architecture/status maps, with measured typography and actionable layout diagnostics, plus JSON/Mermaid input and a local MCP adapter.

---

## Verdict

⚠️ **Interesting — strong layout feedback, not a hardened untrusted-diagram service.** The measured blocks, named collision reports and plain-language description make a useful agent iteration loop. Try it for trusted local documentation; do not treat JSON-only MCP as a complete security boundary until SVG attribute handling, output isolation and resource limits are hardened. Its Mermaid importer is a subset, not a drop-in renderer.

## What It Is

Luke Deasy's project builds panels, tiles, cards, groups and routed connections into SVG and optional PNG. It fits software architecture, process maps and status-oriented documentation better than arbitrary illustration. Python offers the most flexibility; a declarative JSON format and Mermaid flowchart importer make it accessible without writing Python. [1], [2], [3], [4]

The core is deterministic geometry, not an AI model. An external agent can author input, call check, repair reported problems and inspect the result. Nothing automatically discovers a real system or verifies that a diagram's statements are true. Updating an external status file changes displayed states; it does not establish that those states match production. [1], [2], [5]

## Stack

| Layer | Tech |
|-------|------|
| Library and CLI | Python; setuptools; open-diagram entry point |
| Measurement and SVG | fontTools, bundled Inter glyph outlines, handwritten geometry |
| Raster output | Chrome/Chromium/Edge subprocess; optional Pillow crop |
| Agent interface | Optional mcp >=2.3,<3; stdio; four tools |
| Storage | Source files and SVG/PNG outputs; no database or accounts |
| CI | GitHub Actions: unit tests, example checks/drawing, PyPI trusted publishing |

Manifest dependencies have broad ranges and no lockfile was found in the reviewed tree. Pin a tested environment for reproducible builds. [6], [7], [8]

## Key Features

### Measure first, check after placement

Blocks derive dimensions from font metrics and pair kerning. The diagram layer positions columns/rings/free panels, routes links and shifts labels. Diagnostics name overlapping panels, narrow gaps, lines crossing panels, bad endpoint direction, colliding labels and undersized text. This is more useful to an agent than a silent broken image. However, sampled geometry and heuristic placement are not a proof of perfect layout; manual inspection still matters. The typography code maps characters to glyphs and pair kerning rather than a full complex-script shaping engine. [2], [9]

### Portable visuals and inspectable meaning

SVG labels are outlines, avoiding a recipient's font substitution. Title/description and per-label title elements preserve some textual meaning, and describe() lists content, states and connections. Outlines also mean ordinary SVG text editing/search workflows are less convenient; preserve the editable source rather than treating SVG as the canonical project. Screen-reader behavior across applications was not tested. [3], [9], [10]

### Multiple authoring surfaces, different authority

CLI draw/check/describe accepts JSON, Mermaid or Python. Python input is explicitly compiled and executed, even in check mode: it is trusted code, not a safe document format. MCP only accepts JSON/Mermaid, caps source at 200,000 characters, and exposes format_guide, check, describe and draw. Icon paths are deliberately excluded from the JSON tile schema; Python Tile(icon=...) reads local files and embeds their bytes. [4], [5], [11]

Mermaid support covers flowchart/graph directions, chains, labels, states and top-level groups. Styling/click directives are ignored; original shapes are normalized into this library's presentation. Do not expect sequence diagrams or exact Mermaid visual fidelity. [4]

## Architecture

Input flows through CLI or MCP into spec.py/from_spec or mermaid.py/from_mermaid, creating Diagram and measured blocks. Diagram handles relative placement, routing, checks and render reports; Canvas serializes SVG; fonts.py turns glyphs into paths. render.py wraps the SVG in temporary HTML and starts a fresh headless browser profile for PNG. No server-side database, background job queue or embedded model is involved. [2], [3], [4], [5], [7], [9], [10], [11]

The separation of description, measurement and reportable layout failures is the standout reusable idea. The implementation is small enough to inspect, but responsibilities such as rendering and security-sensitive serialization remain custom code rather than a proven sanitized-document pipeline.

## Security, Privacy and Agent Authority

**Local does not mean private end-to-end.** The normal library path has no provider client or telemetry evident in the reviewed code. But MCP returns descriptions, paths and optionally image bytes to the calling AI application; that application may forward them to its model provider. The README's “nothing leaves your computer” describes the local component, not the full agent workflow. Installation fetches dependencies; optional icon acquisition contacts third-party hosts. No account, API key or paid model is required by this library itself. External agent subscriptions/token charges, CI minutes and compute remain outside it. [1], [5], [6], [7]

**Concrete SVG injection concern (static finding, not an executed exploit).** theme_from_spec accepts theme values without strict color/value validation. Canvas._attrs interpolates attribute values without XML attribute escaping; text fill and background fill also interpolate directly. For example, JSON theme.paper reaches the SVG background fill unchanged. A quote-containing value can alter generated markup; PNG rendering then embeds that SVG directly into HTML. This invalidates an assumption that JSON-only input is automatically passive. Use only trusted specifications/themes, validate and escape attributes, and restrict renderer network access. Browser execution/exfiltration behavior was not exercised, and this is not a claim of demonstrated OS code execution. [3], [7], [11]

**Output names are filtered, not sandboxed.** MCP safe_name strips directory syntax and truncates names, but draw opens a predictable filename with normal write semantics. Repeated names overwrite files despite destructiveHint=False; existing symlinks can redirect writes outside the nominal output directory. Use a dedicated non-shared output directory with restrictive permissions; add no-follow/atomic writes and collision handling before exposing it to mutually untrusted actors. The tests check traversal strings, not symlink confinement. [5], [12]

**No network auth layer is needed for the shipped stdio model.** The parent process and OS user are the trust boundary; there is no HTTP auth/CORS configuration to evaluate. Do not turn it into a public multi-user endpoint unchanged. The source-length cap is helpful but not a node-count, numeric-dimension, recursion, CPU or memory limit. The renderer has a 180-second subprocess timeout and a fresh profile, but no network-denial policy. The standalone png command also embeds supplied SVG as HTML: do not feed it hostile SVG. [5], [7], [11]

## Persistence, Recovery and Export

Editable truth lives in Python/JSON/Mermaid plus any status/icon files; version these and pin the environment. Outputs are SVG and PNG, not a database-backed workspace. There is no built-in version history, undo, collaboration, crash recovery or automatic source export from MCP: draw saves images, not the submitted source. Back up the original specifications separately. [1], [5]

save() writes artifacts before raising LayoutError; CLI draw returns a failing layout status after writing. MCP draw reports problems but still produces files. Thus an existing output is not proof that checks passed. Writes are not transactional. PNG availability is optional, and svg_to_png checks output existence without checking subprocess return code or clearing an old output first: a stale PNG can be mistaken for a successful current rendering if the browser exits without producing a new file. Use fresh output names/directories and inspect reports. picture=false in MCP suppresses image return, not PNG generation. [2], [5], [7]

## Maturity, License and Verification

Public anonymous GitHub access was confirmed. At retrieval: 109 stars, 11 forks, zero open issues, last push 2026-11-23T04:42:12Z. These are a mutable snapshot, not quality proof. The visible release series runs from v0.1.0 on November 18 to v0.4.0 on November 19: a young project with fast iteration, not evidence of years of compatibility. [13]

Tests cover font metrics, layout failures, spec errors, Mermaid import, rings, statuses, CLI updates and examples; MCP tests include in-process protocol and stdio calls when the optional toolkit is present. Test CI installs the MCP extra on Python 3.10 and 3.14; the advertised Python 3.9 minimum is not in that matrix. Upstream test and diagrams workflows succeeded for the reviewed SHA. No local tests, visual snapshots, dependency audit, adversarial input tests or browser compatibility checks were run. [8], [12], [14]

MIT permits reuse with copyright/license preservation. The bundled Inter font carries SIL OFL 1.1 and its own notice. Cloud service icons are not covered by the project's MIT grant; the README explicitly identifies separate Amazon/Microsoft/Google terms and a third-party host. This review extracts no library code or icons. [1], [15]

## Comparison

| Aspect | Open Diagram | Mermaid | Mingrammer Diagrams |
|--------|--------------|---------|---------------------|
| Best fit | Dense measured panels and agent-readable layout feedback | Markdown-oriented diagram syntax and integrations | Python cloud/infrastructure node diagrams |
| Rendering model | Custom geometry + outlined SVG; browser for PNG | JavaScript text-definition renderer | Python authoring + Graphviz |
| Authoring tradeoff | JSON/MCP subset or unrestricted Python | Retain native Mermaid when syntax/style fidelity matters | Prefer when cloud-node vocabulary and Graphviz layout fit |
| Why choose this instead | Named collision reports and semantic descriptions | Choose Mermaid for its existing documentation ecosystem | Choose Diagrams for its documented provider-node workflow |

These alternatives were checked through their public documentation, not benchmarked or audited. Mermaid's introduction describes its Markdown-inspired JavaScript renderer and integrations; Diagrams' installation guide demonstrates AWS nodes and requires Graphviz. Existing tools are adequate for those use cases; Open Diagram is worth a trial when measured multi-section panels and a check/fix loop specifically matter. [16], [17]

## Self-Hosting Notes

This is a local library/tool, not a hosted web application. For an evaluation, pin the reviewed commit in an isolated environment, keep trusted source under version control, use SVG-only CLI output if a browser is unnecessary, and review diagrams visually before sharing. For MCP, use a dedicated output directory, least-privilege process credentials and trusted inputs; do not connect it to sensitive diagrams under an assumption of end-to-end local AI processing. Harden the serialization and filesystem issues above before broad agent access. No deployment or installation was performed for this review.

## Evidence

All source links below pin the reviewed commit unless explicitly labeled mutable metadata or external documentation.

[1]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/README.md
[2]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/diagram.py
[3]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/svg.py
[4]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/mermaid.py
[5]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/mcp_server.py
[6]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/pyproject.toml
[7]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/render.py
[8]: https://github.com/lukendeasy/open-diagram/tree/e2f9e788778968ab28f8f35a6396554f644be553/.github/workflows
[9]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/fonts.py
[10]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/describe.py
[11]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/spec.py
[12]: https://github.com/lukendeasy/open-diagram/tree/e2f9e788778968ab28f8f35a6396554f644be553/tests
[13]: https://github.com/lukendeasy/open-diagram/releases
[14]: https://github.com/lukendeasy/open-diagram/actions/runs/45113430660
[15]: https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/LICENSE
[16]: https://mermaid.js.org/intro/
[17]: https://diagrams.mingrammer.com/docs/getting-started/installation

Additional direct evidence: [CLI Python execution](https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/cli.py#L27-L43), [local icon embedding](https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/blocks.py#L42-L45), [font license](https://github.com/lukendeasy/open-diagram/blob/e2f9e788778968ab28f8f35a6396554f644be553/src/open_diagram/fonts/OFL.txt), [successful diagrams CI](https://github.com/lukendeasy/open-diagram/actions/runs/45113430789), [v0.4.0 release](https://github.com/lukendeasy/open-diagram/releases/tag/v0.4.0).

---

**Attribution:** Luke Deasy / lukendeasy/open-diagram; MIT code, Inter under SIL OFL 1.1, separate cloud-icon terms. Independent static analysis; no endorsement implied.
