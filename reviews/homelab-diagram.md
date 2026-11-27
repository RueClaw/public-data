# Homelab Diagram (Goblinmine/homelab-diagram)

**Repo:** https://github.com/Goblinmine/homelab-diagram
**License:** MIT for code and original glyphs; preserve copyright and permission notices. Downloaded service logos and system fonts have separate rights.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `a9a458ae1824f93b516007176b1f515685757375`, main; both Python scripts, inventory, documentation, glyph inventory, manifest, lockfile and repository file tree.
**Verification:** Static source inspection only. Anonymous GitHub metadata and HTTPS clone succeeded. No installation, source execution, rendering, network discovery, accounts or paid calls; upstream tests were not run.
**Stack:** Python 3.11+, PyYAML, Pillow, hand-written SVG, librsvg, fontconfig, Fira fonts.
**What it is:** An editable, code-based illustration of one homelab, not an automatic network mapper or general diagram editor.

---

## Verdict

📚 **Study: an unusually detailed diagram recipe, not a turnkey inventory tool.** The visual vocabulary is useful: cable width encodes speed, VLANs color ports and cards, and hardware, guests and storage share a coherent view. Adoption means editing Python coordinates as well as YAML; default redaction is too narrow to make an arbitrary private inventory safe to publish. Use it for a manually maintained illustration with trusted inputs, not a multi-user upload service.

## What It Is

The author explicitly calls this a starting point and discloses AI-assisted implementation. YAML supplies labels and many repeated card contents, while Python supplies the fixed topology, cable routing and layout. There is no drag-and-drop canvas, graph layout engine, browser application, database or continuously refreshed infrastructure inventory in the reviewed main branch. [README](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/README.md)

The intended user is a homelab owner comfortable adjusting code and inspecting images. The documented agent-assisted interview/render loop is optional authoring guidance, not an embedded AI service. Its examples of checking live systems describe a separate workflow: neither Python script implements SSH, SNMP, Proxmox/TrueNAS API discovery or network scans. Do not interpret the diagram's security labels as measurements of actual enforcement.

## Stack

| Layer | Tech |
|-------|------|
| Input | Local YAML via PyYAML safe_load; no schema validator |
| Layout | Single 977-line build.py with SVG primitives and absolute coordinates |
| Typography | Pillow measurement, fontconfig lookup, approximate fallback |
| Export | SVG with base64 icon images; rsvg-convert PNG at 1.6× scale |
| Assets | Original glyphs plus downloaded dashboard-icons service logos |
| Persistence | YAML, Python, icons and output files; no database or autosave |
| Auth / web | None: local command-line scripts, no server or CORS layer |
| Dependencies | uv.lock pins Pillow 13.0.0 and PyYAML 6.0.3; system tools/fonts remain external |

## Key Features

### Readable physical and logical topology

Port VLAN ticks distinguish tagged and untagged membership; trunk cables use a contrasting inner stroke, and link widths encode speeds. Folder-shaped physical device cards distinguish hardware from guests. These are useful design patterns, but the actual cable endpoints and several speed labels remain hardcoded: changing a YAML port target alone does not reroute the line. [build.py](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L363-L568)

### Dense server and storage views

Hardware lists, grouped VM/container cards, multi-app containers, disks, pools and a media-flow explainer make one image unusually information-rich. Optional fields support guest kinds, cluster-node labels and multi-VLAN SSIDs. Some overflow assertions and text measurements help detect fit problems, but they are not automatic layout or general collision detection; Python optimization can disable assertions. [server and guest rendering](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L638-L868)

### Two output modes, not a privacy guarantee

Default mode substitutes the configured domain in text, selects a redacted title and uses each SSID's redacted field. Unredacted mode uses separate filenames. Internal addresses, hostnames, inventory IDs, hardware/OS versions, exposed services, topology and watermark remain visible unless the user edits them. SSID replacement is specific to its rendering section, not a general text scrub. Inventory flags can disable redaction even without the unredacted CLI option. Review the entire SVG and PNG before sharing; never place credentials in inventory notes. [redaction setup](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L30-L77), [SSID rendering](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L515-L529)

## Architecture

The build script loads inventory at module top level, builds VLAN/color lookup maps, appends SVG strings into one list, computes the final canvas height, writes SVG and invokes librsvg. It is a script, not a reusable import-safe library: importing it also performs the build. The icon helper caches base64 bytes to avoid repeatedly reading each image. Text helpers apply domain substitution and HTML escaping. The final height follows the main server panel rather than computing a bounding box over every rendered element. [input/helpers](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L16-L160), [export](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L960-L977)

### Discovery and outbound access

The renderer has no application-level network client. Its subprocesses are font lookup and image conversion, using argument arrays rather than shell interpolation. The separate icon downloader contacts jsDelivr, then raw GitHub on failure, using a fixed mapping of names. It has a 20-second request timeout, bounded retries, modest delays and an aggregate failure exit; it does not implement Retry-After handling. It downloads from moving upstream paths without content digests, MIME/XML validation, download-size bounds or redirect restrictions. Once icons are present, no downloader is needed for ordinary builds. Dependency installation is another optional network step, not performed for this review. [fetch_icons.py](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/fetch_icons.py)

### Rendering and input safety

PyYAML safe_load avoids arbitrary Python-object constructors, and text nodes go through html.escape with quotes enabled. Those are worthwhile protections, not a complete trust boundary. Inventory-derived VLAN colors are interpolated directly into SVG attributes without validation or escaping; crafted colors could break attribute boundaries or introduce markup in a directly opened SVG. Icon names are joined to the icon directory without checking containment, allowing traversal to other readable files with an SVG suffix; those bytes are embedded in the output. Base64 encoding is not SVG sanitization. Exploitability in a particular browser or librsvg version was not tested.

There are no schema, numeric-range, input-size or rendering-time limits. Wrong keys/types can fail with exceptions; oversized inventories, images or values can consume resources or break geometry. PNG conversion has check=True but no timeout. Keep inputs and icons trusted, validate colors and paths before offering any upload workflow, and isolate rendering with no host secrets. Do not expose these scripts unchanged as a public service. [SVG primitives and icon loading](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L121-L160)

### Persistence, export and recovery

The editable source of truth is YAML plus Python, not the exported picture. There is no round-trip SVG import, undo history, built-in backup or multi-user conflict handling. Output and downloaded logos are ignored by Git, but inventory is tracked: adding real infrastructure details to it can disclose them through repository history regardless of render redaction. Keep private inventory outside a public checkout and pass it with --inventory; also remember that outputs still go into the script's own out directory.

Builds overwrite fixed filenames. SVG is written before PNG conversion; a failed conversion can leave a new SVG beside an old, missing or partial PNG, so file existence is not a success receipt. No atomic publish pair, manifest or freshness checksum exists. Icon fetching overwrites successful files while retaining other old files on failure, allowing mixed upstream versions. Recovery is a rerun after fixing inputs/dependencies, with independently backed-up sources and verified outputs. For reproducible snapshots, archive permitted icon bytes and system dependency versions as well as the Python lockfile. [export](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/build.py#L969-L977), [.gitignore](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/.gitignore)

## Maturity, Licensing and Verification

Anonymous metadata on 2026-11-27 reported 1,918 stars, 164 forks and five open issues/PRs combined; last push was 2026-11-14. The open listing contained four PRs and one issue. Interactive web UI and optional NetBox import appeared as open PRs, not features of this reviewed commit. These counts are snapshots, not quality evidence. The releases endpoint returned no releases and the tag listing was empty; 0.1.0 is the project manifest version, not a verified release tag. [metadata](https://api.github.com/repos/Goblinmine/homelab-diagram), [releases](https://github.com/Goblinmine/homelab-diagram/releases), [open work](https://github.com/Goblinmine/homelab-diagram/pulls)

The tracked tree contains no test suite or CI workflow. Layout assertions, a sample image and the author's claimed fresh-clone render check are useful signals, but not independently reproduced tests. We inspected both scripts, the full inventory, README, authoring guidance, license, manifest and lockfile dependency entries; no source was executed and no new image was generated. Dependency vulnerability scanning, full history secret scanning and platform compatibility tests were not performed. No credential mechanism was found in the two scripts; this is not a certification that every asset or repository history is secret-free.

MIT permits adapting the code and original glyphs with notices retained. Service logos are explicitly separate, fetched from dashboard-icons, and fonts are separately licensed; the project's MIT file does not grant blanket trademark or third-party asset rights. No upstream code or icons are redistributed in this review. [LICENSE](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/LICENSE), [manifest](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/pyproject.toml), [lockfile](https://github.com/Goblinmine/homelab-diagram/blob/a9a458ae1824f93b516007176b1f515685757375/uv.lock)

## Comparison

These are workflow alternatives, not benchmarked substitutes or fresh audits.

| Aspect | Homelab Diagram | Alternative |
|--------|-----------------|-------------|
| Visual editing | Change code and render again | [diagrams.net](https://github.com/jgraph/drawio): interactive general-purpose diagram authoring |
| Text-to-layout | Absolute coordinates and fixed topology | [Graphviz](https://graphviz.org/): declarative graphs and automatic layout, less bespoke card styling |
| Python diagrams | Custom SVG primitives | [Diagrams](https://github.com/mingrammer/diagrams): reusable diagram-as-code abstractions and Graphviz layout |
| Infrastructure truth | Manually maintained YAML | [NetBox](https://github.com/netbox-community/netbox): structured infrastructure modeling; substantially heavier, not an automatic equivalent of this illustration |

Choose diagrams.net for occasional manual edits, Graphviz/Diagrams for changing graphs, and NetBox when maintaining structured inventory is the primary job. Study this repository when polished homelab-specific visual conventions matter more than generic editing.

## Self-Hosting Notes

There is no server to host. A local workstation needs Python, the declared dependencies, librsvg, fontconfig and Fira fonts. The README documents uv and plain-Python paths. The lockfile improves Python dependency repeatability but does not pin fonts, librsvg or downloaded icons; font fallback can alter layout. Use an unprivileged, isolated environment with trusted data, separate private inventories, pinned/reviewed assets and visual output inspection. Automated generation should publish only after both artifacts succeed and pass disclosure checks.

---

**Attribution:** Goblinmine/homelab-diagram, MIT code and original glyphs; third-party assets retain their own terms.
