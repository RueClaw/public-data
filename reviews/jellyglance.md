# JellyGlance (Nerdy-Technician/JellyGlance)

**Repo:** https://github.com/Nerdy-Technician/JellyGlance
**License:** Root `LICENSE` is MIT; root `package.json` declares GPL-3.0, so metadata is inconsistent
**Reviewed:** 2026-08-09
**Stack:** JavaScript, Express, React/Vite, PostgreSQL, Socket.IO, Docker, Jellyfin/Arr/Seerr/download-client integrations
**What it is:** A self-hosted Jellyfin operations dashboard for live sessions, users, library stats, recently added media, request queues, Arr calendars, download clients, webhooks, backups, and task health.

---

## Verdict

⚠️ **Feature-rich media dashboard, but not a quiet deploy candidate yet.** JellyGlance has a strong operator surface for Jellyfin-heavy homeservers: live playback, user statistics, media automation, requests, backups, webhooks, health, and calendars are all in one app. The deployment story and CI are active, but the security model needs hardening before broad exposure: local passwords appear to be stored as client-side SHA3 strings rather than proper server-side password hashes, Docker examples ship placeholder/default secrets, license metadata conflicts, and the repo currently has case-colliding workflow files.

---

## What It Is

JellyGlance is an operations dashboard for self-hosted Jellyfin environments. It sits beside Jellyfin and related media automation tools, then centralizes active sessions, playback history, users, library health, recently added media, requests, release calendars, download queues, webhook delivery, backups, admin audit history, and scheduled sync tasks.

The architecture is a split monorepo: an Express API talks to PostgreSQL and external services, while a React/Vite frontend provides the dashboard. Docker is the intended install path, with a bundled Compose file for PostgreSQL plus the app container and visible config/backup paths.

The project is very fresh but active. At review, GitHub reported 52 stars, 1 fork, 7 open issues, latest release `v1.2.1`, and a same-day successful CI and Docker workflow.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js 22, Express, pg/pg-promise/knex, Socket.IO, node-cron |
| Frontend | React 18, Vite 7, Material UI, Bootstrap, Recharts |
| Database | PostgreSQL 16 |
| Auth | JWT bearer tokens, local login, Jellyfin Quick Connect, OIDC setup |
| Integrations | Jellyfin, Sonarr, Radarr, Lidarr, Bazarr, Jellyseerr/Overseerr, qBittorrent, Transmission, Deluge, SABnzbd, NZBGet, webhooks |
| Packaging | Docker image, Docker Compose, GHCR workflow |
| CI | npm ci, i18n check, lint, web build, docs build, Docker build |

## Key Features

### Jellyfin Command Center

The dashboard combines live streams, playback history, watch-time charts, user profiles, favorites, watchlists, recently added shelves, library cards, and media item details. For a Jellyfin operator, this is the core appeal: fewer browser tabs and more consolidated visibility.

### Media Automation Hub

JellyGlance reaches beyond Jellyfin into Arr apps, Seerr apps, and download clients. It can show calendars, request queues, availability, integration health, and active downloads across the surrounding media-server ecosystem.

### Task, Backup, and Webhook Operations

The backend has scheduled task classes, task-manager/scheduler singletons, activity monitoring, webhook delivery history, admin audit logs, JSON backup/restore paths, and importers for Jellystat/Tautulli history. That makes it more of an operations console than a cosmetic dashboard.

### Role and Auth Modes

The app supports local users, role permissions, Jellyfin Quick Connect, and OIDC setup. Route mounting in `server.js` applies JWT/API-key authentication to API, stats, sync, backup, logs, utilities, webhooks, and newsletter routes, with settings-only gates on sensitive groups.

## Architecture

The repo is organized as:

- `apps/api/` - Express API, PostgreSQL models, migrations, sync tasks, integration clients, backup/import routes, webhooks, and WebSocket server.
- `apps/web/` - React/Vite dashboard.
- `docs/` - documentation site.
- `Dockerfile` and `docker-compose.yml` - app container plus PostgreSQL deployment.

Several implementation choices are solid: production startup fails without `JWT_SECRET`, sensitive routes are behind auth middleware, uploaded backup/import files use generated filenames and extension filters, security headers are set globally, and `npm audit --omit=dev` reports zero production advisories.

The weaker areas are operational/security hygiene:

- The root license metadata conflicts: GitHub/root `LICENSE` says MIT, while `package.json` says GPL-3.0.
- The Compose examples use default PostgreSQL credentials and placeholder JWT secrets.
- Local passwords are compared as stored SHA3 strings (`user.password === password`) rather than salted server-side password hashes.
- JWTs are stored in browser `localStorage`, increasing XSS blast radius.
- A shallow clone on macOS reported case-colliding workflow files: `.github/workflows/RELEASE.yml` and `.github/workflows/release.yml`.
- CI builds and lints, but there is no visible test suite in the workflow.

## Comparison

| Aspect | JellyGlance | Tautulli | Jellystat |
|--------|-------------|----------|-----------|
| Primary role | Unified Jellyfin operations dashboard | Plex-focused monitoring/statistics | Jellyfin-focused statistics |
| Scope | Sessions, stats, requests, integrations, downloads, tasks, backups, webhooks | Deep Plex history and notifications | Jellyfin playback analytics |
| Deployment | App + PostgreSQL via Docker | Mature single-service app | Self-hosted app/database |
| Maturity | Young, active, broad feature surface | Mature | More established for stats-only use |
| Best fit | Operators who want one dashboard across Jellyfin and media automation | Plex operators | Jellyfin analytics-only use cases |

## Self-Hosting Notes

Keep it behind a private network, VPN, or trusted reverse proxy until the local-auth storage model is tightened. If deploying, replace every Compose placeholder (`POSTGRES_PASSWORD`, `JWT_SECRET`) with generated secrets, set a canonical external URL if proxying, and prefer OIDC or Jellyfin Quick Connect over local-password mode.

The production dependency audit is clean, but the full dev/docs audit reports 10 advisories, mostly release/docs tooling. CI was green at the reviewed commit, but it does not run tests.

---

**Attribution:** Nerdy-Technician/JellyGlance, MIT root license with GPL-3.0 package metadata conflict
