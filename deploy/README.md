# Deployment controls

Install the repository read-only at `/srv/public-data` and use a dedicated `public-data` system account. Store live requests outside the code in `/var/lib/public-data/requests`. The service stores local users, hashed sessions and private AI connections in `/var/lib/public-data/private` using `--state-dir`. Back up that directory privately. The application is public and read-only by default; login unlocks actions and administrator settings; change the initial **admin / admin** password in Settings before allowing shared access. Keep backup copies of the queue; the application does not synchronize it to Git.

Adapt the service example's bind address and public origin. Behind a containerized proxy, bind only to the host side of that proxy's private bridge, not every interface. Put a random `PUBLIC_DATA_GATEWAY_TOKEN` in a root-readable `/etc/public-data-reviews.env` and set the matching `X-Public-Data-Gateway` header using the proxy's private configuration. The proxy must overwrite the incoming header. Never commit the token, passwords, password hashes or identity-provider secrets.

Require authentication on every route using either the Basic example (hashed password over HTTPS) or the Authentik example. Basic auth is the initial supported deployment mode. Authentik requires a separately installed instance, proxy provider, registered outpost, application and explicit user/group policy. Do not merely trust identity headers supplied by a browser, chain providers with an anonymous fallback, or disable auth when the identity provider is down. Remove incoming identity headers before forward-auth copies verified identity. Strip the Authorization header before forwarding to the application.

The gateway token is an additional backend boundary, not a substitute for user authentication. Local loopback previews omit the token; public-origin startup refuses to run without it.

Install uv system-wide at `/usr/bin/uv` (or adjust `ExecStart` to its absolute
location) and provide Python 3.10+ at `/usr/bin/python3`. The service uses uv in
offline mode with managed-Python downloads and caching disabled, so startup needs
no network access or writable environment/cache under the read-only deployment.

## Explicit resource ceilings

The service example limits CPU to one core, memory to 512 MiB (384 MiB soft threshold), swap to zero, tasks to 64, open files to 256 and individual file writes to 8 MiB. The server allows 32 concurrent connections, ten-second socket waits, 50 requests/second with a burst of 100, 16,000-byte request bodies, 8 MiB served files/responses, 20,000 catalog entries, an eight-entry sanitized-guide cache and a queue bounded by both 10,000 records and 64 MiB. Catalog refreshes are serialized. Queue writes reject operations beyond the configured budget.

Set `request_body { max_size 16KB }` before authentication/WAF inside the site's Caddy `route` block. Apply finite resource ceilings to the proxy too, including CPU, memory, swap and process count; choose headroom for every application sharing it. Backend ceilings do not constrain proxy authentication work. Check actual workloads before reducing existing shared-proxy ceilings.

## Safe guide mode

The server uses a conservative HTML element/attribute allowlist, removes scripts, inline event handlers, forms, frames, SVG and external assets, drops hidden state, and expands tab sections. All guide responses include an HTTP CSP sandbox with no capabilities, script execution disabled, external resources blocked and no form submissions. The library iframe also has an empty sandbox. Direct links receive the same restrictions. Interactive JavaScript features are intentionally unavailable. Sanitization and isolation reduce browser capability; neither establishes that text, links or instructions are truthful or harmless.

Static assets use an explicit allowlist. Deployment documentation is not an HTTP asset. Markdown paths cannot traverse out of their named collection. Run `uv run --no-project scripts/test_review_web.py` after changes.

## Automatic deploys

On the host that serves the site (nautilus), a systemd timer can keep
`/srv/public-data` aligned with `origin/main` without opening an inbound
webhook or running a GitHub Actions runner. Every five minutes
`scripts/auto-deploy-check.sh` fetches `origin/main` and, only when that
commit is a new fast-forward relative to the last successful deploy, runs
`scripts/deploy-reviews.sh`. That script still runs the tests, rsyncs to
`/srv/public-data`, restarts `public-data-reviews`, and rolls back if the
health check fails. Checks with nothing new to deploy stay silent.

The timer unit is `deploy/public-data-reviews-autodeploy.timer`. It runs as
the checkout owner (`zob`) from `~/src/public-data`. A one-line sudoers
rule lets that user run only the root-owned helper installed at
`/usr/local/sbin/public-data-reviews-priv` (copied from
`scripts/public-data-reviews-priv.sh`). Do not grant sudo on the copy in the
clone: a push could replace it. If that helper is present,
`deploy-reviews.sh` uses it automatically; otherwise it still calls `sudo`
as before. The helper must be re-installed only when the helper or sudoers
file itself changes.

The clone's `origin` must be fetchable without an SSH agent; HTTPS is
enough for this public repository. A dirty checkout, or a history that is
not a fast-forward, fails the unit and deploys nothing. If the live site is
already current, you can enable the timer immediately; its first tick
deploys once to record the live SHA (and restarts the service).

```bash
cd ~/src/public-data
git pull --ff-only origin main
# If origin is an SSH URL: git remote set-url origin https://github.com/RueClaw/public-data.git

sudo install -o root -g root -m 0755 \
  scripts/public-data-reviews-priv.sh /usr/local/sbin/public-data-reviews-priv

tmp=$(mktemp)
cp deploy/public-data-reviews-deploy.sudoers "$tmp"
sudo visudo -cf "$tmp"
# sudoers.d skips filenames that contain a dot; install without one.
sudo install -o root -g root -m 0440 "$tmp" /etc/sudoers.d/public-data-reviews-deploy
rm -f "$tmp"

sudo -n /usr/local/sbin/public-data-reviews-priv test -r /etc/public-data-reviews.env

sudo install -o root -g root -m 0644 \
  deploy/public-data-reviews-autodeploy.service \
  /etc/systemd/system/public-data-reviews-autodeploy.service
sudo install -o root -g root -m 0644 \
  deploy/public-data-reviews-autodeploy.timer \
  /etc/systemd/system/public-data-reviews-autodeploy.timer
sudo systemctl daemon-reload
sudo systemctl enable --now public-data-reviews-autodeploy.timer
systemctl list-timers public-data-reviews-autodeploy.timer --no-pager
```

Logs: `journalctl -u public-data-reviews-autodeploy -f`. Disable with
`sudo systemctl disable --now public-data-reviews-autodeploy.timer`.
