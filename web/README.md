# Public Data web interface

## Run locally

```sh
python3 scripts/review-web.py
```

Open http://127.0.0.1:8765. Python 3.10+ is the only dependency. The server binds to loopback by default. No package installation, build step, third-party scripts or external font requests are needed.

The interface indexes Markdown files from reviews, patterns, prompts, agents, tools, notes, ai-patterns and inbox. README table metadata supplies review summaries, verdicts, source URLs and licenses. A matching HTML file enables the visual guide reader. Catalog changes appear within 30 seconds; entries without a recorded review date are labeled Undated. Guide scripts run in a sandboxed iframe without same-origin privileges. Markdown is displayed with escaped text and a small safe renderer; raw HTML is never executed.

Search titles, summaries, stack, source names and licenses; filter verdicts; sort by date or name; use grid/list views; bookmark entries; open text or visual guides; submit requests and move them through the queue. Bookmark, theme and layout choices stay in the current browser. Theme choices: Catppuccin Mocha, Dracula, Nord, Tokyo Night, Solarized Light, Paper, or system preference. Themes apply to the library shell and text reader; existing standalone guides retain their own design.

## Checks

```sh
python3 scripts/test_review_web.py
node --check web/app.js
```

Integration tests use temporary files, never the real queue. They cover catalog metadata, HTML serving, submission persistence, duplicate detection, revision conflicts, URL validation, cross-origin/host checks and private-path isolation.

## Nautilus deployment

The instance is installed at `/home/zob/services/public-data`, served by `public-data-reviews.service`, and reached by Caddy at `172.23.0.1:8765` (the host side of Caddy's Docker bridge). The service accepts the exact public origin `https://reviews.zlyxy.me`. The backend is not bound to LAN/WAN interfaces. Caddy serves the library publicly and restricts all `/api/requests` routes to LAN/tailnet clients. There is no application account/password system: do not expose queue routes publicly without adding authentication and abuse controls.

The live deployment is a file snapshot, not a second Git checkout. Refresh explicitly after new reviews are committed:

```sh
rsync -az --exclude=.git --exclude=__pycache__ --exclude=review-requests/ \
  -e 'ssh -F ~/.ssh/config' ./ nautilus:/home/zob/services/public-data/
ssh -F ~/.ssh/config nautilus 'sudo systemctl restart public-data-reviews'
```

Run from the repository root. This preserves the server's request records. There is no automatic Git synchronization or publication. Back up the live queue separately. To inspect: `sudo systemctl status public-data-reviews`; logs: `sudo journalctl -u public-data-reviews`. Before changing the Caddy route, back up `/home/zob/caddy/Caddyfile`, validate with the running Caddy container and reload only after validation passes.
