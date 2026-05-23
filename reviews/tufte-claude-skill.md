# tufte-claude-skill (aref-vc/tufte-claude-skill)

**Repo:** https://github.com/aref-vc/tufte-claude-skill
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-05-23
**Stack:** Claude Code skill, Markdown, HTML/SVG, React, Recharts, D3
**What it is:** A Claude Code skill that turns chart and dashboard requests into Tufte-style data visualizations by combining design principles, chart-selection rules, a kill list, checklists, and implementation presets.

---

## Verdict

✅ **Deploy candidate for agent-assisted chart work.** This is small, dependency-light, and well-scoped: the skill gives an agent a clear decision path instead of a vague style preference. The main caveat is maturity: it was publicly released today, has one commit, and should be treated as a strong starting point rather than a fully proven visualization system.

---

## What It Is

tufte-claude-skill packages Edward Tufte-inspired visualization guidance as a Claude Code skill. It activates on chart, graph, dashboard, KPI, table-with-data, and visualization requests, then instructs the agent to load a compact set of reference files before producing or improving a chart.

The repo is not an application or library. It is a skill bundle: SKILL.md defines activation and workflow, principles.md frames the visual rules, chart-selection.md maps data shapes to chart types, kill-list.md removes bad defaults, and checklist.md provides a final review pass. Presets cover self-contained HTML/SVG and React with Recharts or D3 fallback.

The useful move is procedural. Instead of saying "make this Tufte-like," it turns chart design into a repeatable sequence: identify the data shape, choose the chart based on the communication goal, strip chartjunk, render in a supported stack, and check honesty/readability before finishing.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Claude Code SKILL.md |
| Core content | Markdown reference files |
| Static output | Self-contained HTML/SVG |
| React output | Recharts with D3 fallback |
| Visual examples | HTML gallery, PNG examples, PDF cheatsheet |
| Runtime services | None |

## Key Features

### Decision Table for Chart Choice

chart-selection.md maps data shape plus reader goal to a preferred visualization. It steers common cases toward sorted dot plots, sparklines, slopegraphs, strip plots, small multiples, and compact tables instead of defaulting to library-native charts.

### Explicit Kill List

kill-list.md is the discipline layer. It bans 3D effects, pie/donut charts, dual-axis charts, rainbow ordered scales, heavy gridlines, remote legends, chart borders, redundant encodings, and context-free KPI cards unless the user explicitly overrides.

### Stack-Specific Presets

The presets are practical rather than purely philosophical. The HTML/SVG preset includes tokens and working snippets for sparklines, dot plots, line charts, small multiples, and sparkline tables. The React preset gives a Recharts theme, examples, and clear guidance for when to drop down to D3.

### Before/After Examples

The visual gallery shows typical AI or BI output beside a stripped-down alternative: 3D bars become dot plots, trapped line charts become sparklines, KPI cards become compact tables, clustered bars become slopegraphs, and decorative funnels become honest stage bars.

## Architecture

The repo is organized like a good single-purpose agent skill:

| File | Role |
|------|------|
| SKILL.md | Trigger, workflow, output stacks, defaults |
| principles.md | Ten design principles with practical interpretation |
| chart-selection.md | Data shape + reader goal decision table |
| kill-list.md | Negative rules for chartjunk and misleading encodings |
| checklist.md | Pre-publish verification pass |
| presets/html-svg.md | Static chart snippets and style tokens |
| presets/react.md | Recharts/D3 implementation guidance |
| before-after.html | Example gallery |

There is no build system, package manifest, CI, or test suite. For this kind of artifact that is acceptable, but the examples and presets are doing the work that tests normally would. Future hardening would benefit from sample prompts plus expected output snapshots.

## Comparison

| Aspect | tufte-claude-skill | Generic chart prompt | Chart library docs |
|--------|--------------------|----------------------|--------------------|
| Chart selection | Explicit table by data shape and goal | Usually model intuition | Usually API-driven |
| Visual discipline | Kill list and checklist | Inconsistent | Depends on user |
| Implementation | HTML/SVG and React presets | Ad hoc | Strong API docs, weak design guidance |
| Scope | Agent skill for visualization decisions | Broad and vague | Library-specific |
| Maturity | Very new, one commit | N/A | Mature but not agent-oriented |

## Self-Hosting Notes

Install is a simple clone into the Claude Code skills directory:

    git clone https://github.com/aref-vc/tufte-claude-skill.git ~/.claude/skills/tufte

There are no runtime services. The included PDF is prebuilt; regenerating it from the HTML requires WeasyPrint.

## Watch Outs

- The repo was released on 2026-05-23 and has only one commit at review time.
- GitHub did not detect the license metadata, though the repo includes an MIT LICENSE file.
- The skill quotes and paraphrases Tufte; the README states the content is original with fair-use quotations, but downstream redistribution should keep attribution intact.
- The visual guidance is opinionated. It is a good default for analytical charts, not a universal rule for every audience or every executive deck.

---

**Attribution:** aref-vc/tufte-claude-skill, MIT
