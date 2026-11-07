# Deployment controls

Install the repository read-only at `/srv/public-data` and use a dedicated `public-data` system account. Store live requests outside the code in `/var/lib/public-data/requests`. Keep backup copies of the queue; the application does not synchronize it to Git.

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
