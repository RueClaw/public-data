# Public Data web interface

## Run locally

```sh
uv run --no-project scripts/review-web.py
```

Open http://127.0.0.1:8765. Use uv with Python 3.10+. Scripts use only the standard library; `--no-project`
avoids creating a project environment or requiring a package install. The server binds to loopback by default. No package installation, build step, third-party scripts or external font requests are needed.

The interface indexes Markdown files from reviews, patterns, prompts, agents, tools, notes, ai-patterns and inbox. README table metadata supplies review summaries, verdicts, source URLs and licenses. A matching HTML file enables the visual guide reader. Catalog changes appear within 30 seconds; entries without a recorded review date are labeled Undated. Guide scripts run in a sandboxed iframe without same-origin privileges. Markdown is displayed with escaped text and a small safe renderer; raw HTML is never executed.

Search titles, summaries, stack, source names and licenses; filter verdicts; sort by date or name; use grid/list views; bookmark entries; open text or visual guides; submit requests and move them through the queue. Bookmark, theme and layout choices stay in the current browser. Theme choices: Catppuccin Mocha, Dracula, Nord, Tokyo Night, Solarized Light, Paper, or system preference. Themes apply to the library shell and text reader; existing standalone guides retain their own design.

## Checks

```sh
uv run --no-project scripts/test_review_web.py
node --check web/app.js
```

Integration tests use temporary files, never the real queue. They cover catalog metadata, HTML serving, submission persistence, duplicate detection, revision conflicts, URL validation, cross-origin/host checks and private-path isolation.

## Deployment and security

Use a dedicated service account behind a trusted TLS reverse proxy. All routes require Basic authentication or a configured Authentik forward-auth policy. Backend access additionally requires a private gateway token. Keep credentials and concrete hostnames, addresses and filesystem paths outside the repository. See the generic examples in `deploy/` for both authentication modes and resource ceilings.

Only the four explicitly allowed web assets are served. Guides are sanitized to scriptless HTML with an HTTP sandbox and a deny-by-default content security policy, including on direct links. Existing guide JavaScript is intentionally disabled; tab sections are expanded for reading. These controls reduce active-content risk but do not verify factual accuracy or prevent deceptive text and links.

Deployment is an explicit file synchronization; preserve the live review queue and private authentication configuration. There is no automatic Git synchronization or publication. Back up request records separately.

## Agent assistance

Open Assistant in the sidebar and use the Ask the library panel for full-text discovery and age checks. Configure operator-owned adapters for AI questions, review updates and HTML improvements; see [agent access and protocol](AGENT.md). Direct agents start with [AGENTS.md](../AGENTS.md) and the same JSON CLI.
