# LinkBreeze (Manak-hash/LinkBreeze)

**Repo:** https://github.com/Manak-hash/LinkBreeze
**License:** MIT; code can be reused with attribution
**Reviewed:** 2026-08-09
**Stack:** TypeScript, Next.js 16, React 19, Drizzle ORM, SQLite, Tailwind CSS, Docker
**What it is:** A self-hosted Linktree-style link-in-bio app with multi-page profiles, themes, QR codes, email capture, migration import, and privacy-first analytics.

---

## Verdict

⚠️ **Interesting self-hosted link hub, with a few production-hardening caveats.** LinkBreeze is unusually complete for a fresh project: Docker packaging, SQLite persistence, admin UI, multi-page support, tests, CI, and migration tooling are all present. The main reason not to mark it a deploy candidate yet is operational security polish: the Compose default sets a known `SECRET_KEY`, analytics/custom CSS intentionally allow owner-provided HTML/CSS injection, and the project is still young.

---

## What It Is

LinkBreeze is a single-tenant, self-hosted alternative to hosted link-in-bio services. It gives a creator or organization a public profile page with links, social icons, embeds, QR codes, favicon handling, link thumbnails, email capture, themes, and click/pageview analytics.

The app is designed for simple personal deployment. The README leads with one-line Docker or Podman installs, a prebuilt GHCR image, Docker Compose snippets, and deployment notes for Coolify, Synology, Portainer, and manual Node installs. Data lives in SQLite, with Drizzle migrations and a volume-mounted `/app/data` directory in Docker.

The most distinctive feature is the migration wizard. It can import from Linktree, Bento, Hopp.bio, LittleLink, or generic HTML/JSON exports by parsing structured Next.js data first, then falling back to DOM and inline-script scraping.

## Stack

| Layer | Tech |
|-------|------|
| App | Next.js 16 App Router, React 19, TypeScript |
| UI | Tailwind CSS 4, shadcn-style components, lucide-react, dnd-kit, Recharts |
| Database | SQLite via better-sqlite3 and Drizzle ORM |
| Auth | bcrypt password hashes, signed httpOnly session cookie |
| Validation | Zod server-action schemas |
| Packaging | Docker, Docker Compose, GHCR release workflow |
| Tests/CI | Vitest, Playwright config, GitHub Actions lint/typecheck/test/build, Lighthouse CI |

## Key Features

### Multi-page Link Profiles

The current schema has a `pages` table rather than only a singleton profile. Each page carries its own slug, title, bio, avatar, social links, SEO fields, favicon, analytics script, custom CSS, email capture flag, and theme reference. Links belong to pages via `pageId`, which makes LinkBreeze closer to a small link-site CMS than a one-page clone.

### JS-free Click Tracking

HTTP links route through `/go/:id`, where the server records the click and then redirects. That means click tracking still works when client JavaScript is blocked. The route validates that stale or tampered rows only redirect to `http:` or `https:`, skips analytics for bots and authenticated owners, and rate-limits click inflation per IP.

### Migration Wizard

The importer fetches a competitor profile page, rejects local/private URL targets before fetching, caps redirects and response size, parses `__NEXT_DATA__`, scans inline scripts for URL-like records, and falls back to DOM anchor scraping. That is a pragmatic extraction ladder for the messy link-in-bio ecosystem.

### Theming and Owner-controlled Customization

Themes are tokenized in the database, with presets and controls for background, typography, card style, density, hover effects, and layout. LinkBreeze also supports raw custom CSS and analytics snippets per page. That is powerful for a trusted single owner, but it should be treated as arbitrary code execution in the public page context.

## Architecture

The app has a clean server-oriented Next.js shape:

- `src/db/schema.ts` defines the SQLite tables and migration-backed data model.
- `src/server/actions/` contains authenticated server actions with Zod validation.
- `src/server/queries/` centralizes database reads/writes.
- `src/lib/` contains security-sensitive helpers for auth, sessions, rate limiting, URL validation, visitor hashing, import extraction, themes, QR codes, and favicons.
- `src/components/public/` keeps public-page rendering mostly server-side and low-JS.

Security posture is better than many hobby self-hosted apps. Passwords use bcrypt, sessions are httpOnly and signed, production without `SECRET_KEY` throws, link URL schemes are allowlisted, the migration fetcher has SSRF protections, Docker runs as a non-root `node` user, and CI runs lint/typecheck/tests/build.

The main operational footgun is `docker-compose.yml`:

```yaml
SECRET_KEY=${SECRET_KEY:-changeme-in-production}
```

Because the app only fails when `SECRET_KEY` is missing, this default creates a production deployment with a known signing key unless the operator notices and overrides it. A safer Compose file would require the variable or generate it during installation.

## Comparison

| Aspect | LinkBreeze | LittleLink | LinkStack |
|--------|------------|------------|-----------|
| App model | Full admin app with SQLite and analytics | Mostly static/link page | Larger self-hosted link platform |
| Deployment | One Docker container | Static/simple hosting | Docker/PHP stack options |
| Migration | Built-in competitor importer | Manual editing | More platform-like, less importer-focused |
| Analytics | Built-in privacy-first counters | Usually external | Built-in features vary by setup |
| Maturity | Young, active, 108 stars at review | Mature minimalist template | More mature hosted/self-hosted platform |

## Self-Hosting Notes

The Docker path is the right path. Run the GHCR image with a persistent `/app/data` volume and set a real `SECRET_KEY` yourself:

```bash
SECRET_KEY="$(openssl rand -hex 32)" docker compose up -d
```

For internet-facing deployments, also set `BASE_URL` to the canonical domain so generated metadata and QR-code URLs do not depend on incoming host headers. Treat custom analytics snippets and custom CSS as trusted-owner-only features.

---

**Attribution:** Manak-hash/LinkBreeze, MIT
