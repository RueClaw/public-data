# Public Data web interface

## Run locally

```sh
uv run --no-project scripts/review-web.py
```

Open http://127.0.0.1:8765 to browse publicly in read-only mode. Use **Login** and the initial **admin / admin** credentials to access administration. Use uv with Python 3.10+. Scripts use only the standard library; `--no-project`
avoids creating a project environment or requiring a package install. The server binds to loopback by default. No package installation, build step, third-party scripts or external font requests are needed.

The interface indexes Markdown files from reviews, patterns, prompts, agents, tools, notes, ai-patterns and inbox. README table metadata supplies review summaries, verdicts, source URLs and licenses. A matching HTML file enables the visual guide reader. Catalog changes appear within 30 seconds; entries without a recorded review date are labeled Undated. Guides are sanitized to scriptless HTML in a sandboxed iframe without same-origin privileges. Markdown is displayed with escaped text and a small safe renderer; raw HTML is never executed.

Search titles, summaries, stack, source names and licenses; filter verdicts; sort by date or name; use grid/list views; bookmark entries; open text or visual guides; submit requests and move them through the queue. Bookmark, theme and layout choices stay in the current browser. Theme choices: Catppuccin Mocha, Dracula, Nord, Tokyo Night, Solarized Light, Paper, or system preference. Themes apply to the library shell and text reader; existing standalone guides retain their own design.

## Local accounts and settings

The library, guides and review queue are publicly readable. Visitors see a Login button; no login dialog opens automatically. Submitting or changing requests and using Assistant require a local login. Settings requires an administrator. Direct links to protected views return visitors to the library. Administrators open **Settings** to add users, reset passwords, change roles and disable accounts. User changes revoke that user's sessions; the last active administrator cannot be disabled or demoted. Change the default admin password before sharing access. Sessions expire after 12 hours and use HttpOnly, SameSite=Strict cookies (Secure behind the configured public HTTPS origin). Login attempts are limited per peer address. Behind a proxy, peers may share that limit.

Settings also manages multiple OpenAI-compatible AI connections, including LLM router proxies. Supply a name, API base URL (for example `https://router.example/v1`), model or router alias, and optional bearer key. The server appends `/chat/completions`; remote endpoints require HTTPS, while loopback HTTP supports local models. Redirects are refused. Select a connection in Assistant to ask questions with library search evidence. These connections provide answers; file maintenance continues to use administrator-only command adapters.

Saved endpoints, models and keys have no read/export API, even for administrators. Lists expose only ID, display name and enabled status; use a display name without secrets. Select a connection to replace its settings; blank private fields retain existing values. Provider failures return generic errors, and literal saved values are redacted from model answers. Credentials are never placed in the model messages or browser storage. Questions and matching public library evidence are sent to the selected provider.

Private state defaults to `~/.local/state/public-data/access.sqlite3`; override with `--state-dir /private/path` outside this repository. The directory is mode 0700 and database 0600. Passwords use salted scrypt hashes; session tokens are stored as hashes. AI credentials must remain available to the server and are stored in the private database. The service account, root and anyone with access to its backups can read them: application access controls do not protect against a compromised host. Back up private state separately and never publish it. Browser bookmarks and theme preferences remain shared within the same browser profile.

## Checks

```sh
uv run --no-project scripts/test_review_web.py
node --check web/app.js
```

Integration tests use temporary files, never the real queue. They cover catalog metadata, HTML serving, submission persistence, duplicate detection, revision conflicts, URL validation, cross-origin/host checks and private-path isolation.

## Deployment and security

Use a dedicated service account behind a trusted TLS reverse proxy. The deployment examples add Basic authentication or an Authentik forward-auth policy in front of local application login. Backend access additionally requires a private gateway token. Keep credentials and concrete hostnames, addresses and filesystem paths outside the repository. See the generic examples in `deploy/` for both authentication modes and resource ceilings.

Only the four explicitly allowed web assets are served. Guides are sanitized to scriptless HTML with an HTTP sandbox and a deny-by-default content security policy, including on direct links. Existing guide JavaScript is intentionally disabled; tab sections are expanded for reading. These controls reduce active-content risk but do not verify factual accuracy or prevent deceptive text and links.

Deployment is an explicit file synchronization; preserve the live review queue and private authentication configuration. There is no automatic Git synchronization or publication. Back up request records separately.

## Agent assistance

Open Assistant in the sidebar and use the Ask the library panel for full-text discovery and age checks. Administrators can configure AI connections in Settings and operator-owned adapters for review updates and HTML improvements; see [agent access and protocol](AGENT.md). Direct agents start with [AGENTS.md](../AGENTS.md) and the same JSON CLI.
