# CloakBrowser Review

- **Source:** https://github.com/CloakHQ/CloakBrowser
- **Author:** CloakHQ
- **License:** MIT wrapper code; proprietary no-redistribution binary license for the patched Chromium build
- **Reviewed:** 2026-05-23
- **Commit:** `8028ddefef43e73101ae46234646e787076e11da`
- **Verdict:** ⚠️ Interesting, security-sensitive

## Summary

CloakBrowser is a Python and JavaScript wrapper around a custom patched Chromium binary designed to look less like automation to browser-fingerprint and bot-detection systems. It presents itself as a drop-in Playwright/Puppeteer replacement, with binary auto-download, checksum verification, humanized input helpers, proxy handling, GeoIP-derived locale/timezone helpers, Docker packaging, and live-detection test claims.

This is not a full open-source browser source tree. The wrapper code is MIT, but the patched Chromium binary is distributed under a separate proprietary license that permits internal use but forbids redistribution, resale, repackaging, modification, and reverse engineering. That distinction matters more than the GitHub license badge.

The wrapper engineering is solid and well tested. The use case is sensitive. It is appropriate to study for browser automation infrastructure, binary distribution, provenance checks, SSRF hardening in browser scrapers, and humanized input APIs. It should not be treated as a general-purpose recommendation to bypass site protections or automate systems without permission.

## What It Does

- Provides Python `launch()` and async `launch_async()` wrappers around Playwright.
- Provides JavaScript Playwright and Puppeteer-compatible launch wrappers.
- Downloads a platform-specific patched Chromium binary on first use.
- Verifies binary archives with SHA-256 checksums when release checksums are available.
- Supports GitHub release fallback, local binary override, cache clearing, and update checks.
- Adds proxy parsing and credential handling for HTTP/SOCKS5 proxies.
- Supports GeoIP-derived timezone/locale options from proxy exit IPs.
- Includes `humanize=True` behavior for mouse, keyboard, scroll, and actionability timing.
- Ships Docker and AWS Lambda integration examples.
- Documents release attestation, tag verification, and Docker signature verification.

## Stack

| Layer | Tech |
|-------|------|
| Python wrapper | Python 3.9+, Playwright, httpx, optional geoip2/socksio/aiohttp/websockets |
| JavaScript wrapper | TypeScript, playwright-core, puppeteer-core, tar, Vitest |
| Browser runtime | Patched Chromium binary distributed through GitHub Releases / cloakbrowser.dev |
| Packaging | PyPI, npm, Docker, Nix flake |
| Verification | pytest, Vitest, pinned GitHub Actions, SHA256SUMS, GitHub attestation, Cosign docs |

## Strong Patterns

### Binary-backed automation wrapper

The wrapper keeps the public API close to Playwright/Puppeteer while swapping the browser executable and launch flags. That is a practical pattern for specialized browser runtimes where users should not learn a new automation API.

### Checksummed binary download with local override

First-run binary download is unavoidable for a patched Chromium distribution. CloakBrowser handles this with cache paths, temp-file downloads, SHA-256 verification, GitHub fallback, and `CLOAKBROWSER_BINARY_PATH` for local builds. The checksum behavior should be stricter for high-trust deployments, but the structure is good.

### Humanized input layer as an adapter

The humanized mouse, keyboard, scroll, and actionability wrappers are separated from launch mechanics. That separation is useful: behavioral automation policy can be changed without rewriting every script.

### Browser scraper hardening examples

The AWS Lambda example includes concrete SSRF protections: reject non-HTTP schemes, block loopback/private/link-local/metadata IPs, revalidate redirect targets, and strip caller-controlled launch args. Those are worth borrowing for any browser-as-a-service or screenshot/scraping endpoint.

See extracted pattern: [`patterns/policy-gated-browser-automation-runtime.md`](../patterns/policy-gated-browser-automation-runtime.md).

## Risks

- The patched Chromium binary is not open under MIT; it has a no-redistribution proprietary license.
- The repo is explicitly built for anti-detection and can be misused for abusive automation.
- The binary patches themselves are not reviewable from this repo.
- Auto-update and binary download introduce a supply-chain trust boundary around CloakHQ release infrastructure.
- JavaScript audit reports 8 vulnerabilities, including 4 high, mostly via dev/test browser tooling (`puppeteer-core` / `tar-fs` / `ws`) and Vite/esbuild.
- Python audit found vulnerabilities in the local `pip` version after tool installation; not a CloakBrowser package issue, but the environment is not clean.
- Live bot-detection claims were not independently re-run during this review.

## Verification

Local verification on 2026-05-23:

- GitHub metadata: 19,772 stars, 1,561 forks, 74 open issues, latest release `chromium-v146.0.7680.177.5`.
- `python3 -m compileall -q cloakbrowser tests` passed.
- Python install in a venv passed with `pip install -e '.[dev]'`.
- `pytest tests/ -q -m 'not slow'` passed: 403 passed, 1 skipped, 36 deselected.
- `cd js && npm install --no-fund && npm run build && npm run typecheck && npm test` passed: 10 test files, 339 tests passed, 11 skipped.
- `cd js && npm audit --audit-level moderate` failed with 8 advisories: 4 moderate and 4 high.
- Secret-pattern scan found no obvious live secrets; hits were expected examples, test credentials, CI placeholders, and proxy-handling code.

Full binary launch and live detection tests were not run. That would require downloading the patched Chromium binary and hitting external detection services, which is a heavier and more policy-sensitive verification step than needed for this review.

## Recommendation

Study CloakBrowser for automation wrapper design, binary provenance, browser-scraper hardening, and local test coverage. Use it only in authorized contexts: owned properties, QA, anti-bot compatibility testing, accessibility testing, or research where automated browsing is permitted.

Do not use this as a casual drop-in for scraping protected services. Before any production use, review the binary license, pin and verify binary releases, disable or tightly control auto-update, fix JS dependency advisories, and write an explicit acceptable-use policy.

**Attribution:** [CloakHQ/CloakBrowser](https://github.com/CloakHQ/CloakBrowser), MIT wrapper code; separate CloakBrowser Binary License for compiled Chromium.
