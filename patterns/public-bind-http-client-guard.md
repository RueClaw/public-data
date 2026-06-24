# Public-Bind HTTP Client Guard

**Source:** opendatalab/MinerU  
**Repo:** https://github.com/opendatalab/MinerU  
**License:** MinerU Open Source License  
**Reviewed:** 2026-06-24  

## Pattern

When a self-hosted API lets callers provide remote HTTP endpoints, disable that feature automatically when the service is bound to a public interface.

MinerU uses this around its `*-http-client` inference backends and `server_url` parameter. Those options are useful in trusted deployments because a lightweight client can call a remote OpenAI-compatible inference service. They are dangerous on a public API because arbitrary callers can turn the service into an outbound request primitive.

The guard is simple:

- detect public bind hosts like `0.0.0.0` and `::`;
- treat caller-supplied upstream URLs as disabled by default on public binds;
- provide an explicit operator flag to opt back in;
- return a clear 400 error when a request attempts the disabled path;
- log a warning in both cases: blocked-by-default and explicitly-allowed.

## Why It Matters

This is a practical SSRF prevention pattern for local-first AI services. Many tools add "bring your own OpenAI-compatible endpoint" support, then later expose the API in Docker, Compose, tunnels, or reverse proxies. Without a bind-aware guard, `server_url=http://169.254.169.254/...` or internal network probes become part of the public API surface.

The useful detail is that the project does not remove the feature. It changes the default based on exposure risk and requires the operator to make the risky mode explicit.

## Implementation Shape

```python
def is_public_bind_host(host: str) -> bool:
    return host in {"0.0.0.0", "::"}


def validate_public_http_client_request(
    *,
    public_bind_exposed: bool,
    allow_public_http_client: bool,
    backend: str,
    server_url: str | None,
) -> None:
    if not public_bind_exposed or allow_public_http_client:
        return
    if backend.endswith("-http-client") or bool(server_url and server_url.strip()):
        raise HTTPException(status_code=400, detail=PUBLIC_HTTP_CLIENT_DISABLED_DETAIL)
```

## Reuse Notes

Use this pattern for any self-hosted service where request bodies can influence outbound requests:

- remote model endpoints;
- webhook targets;
- URL import/fetch features;
- browser automation start URLs;
- callback URLs;
- file converters that resolve external resources.

The operator flag should be ugly enough to read twice, for example `--allow-public-http-client`, not `--enable-advanced`.

## Caveats

This is not a complete SSRF defense. It is a strong default gate. Public deployments still need auth, allowlists where possible, DNS/IP range filtering for URL fetchers, timeouts, egress controls, logs, and reverse-proxy limits.

---

**Attribution:** opendatalab/MinerU, MinerU Open Source License, source files `mineru/cli/public_http_client_policy.py`, `mineru/cli/fast_api.py`, and `mineru/cli/router.py`.
