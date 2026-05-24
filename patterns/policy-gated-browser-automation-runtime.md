# Policy-Gated Browser Automation Runtime

- **Source:** https://github.com/CloakHQ/CloakBrowser
- **Author:** CloakHQ
- **License:** MIT wrapper code; binary terms separate
- **Extracted from:** `cloakbrowser/`, `js/src/`, `examples/integrations/aws_lambda/`, `tests/test_lambda_security.py`, `BINARY-LICENSE.md`
- **Reviewed:** 2026-05-23

## Pattern

Treat browser automation as a policy-gated runtime, not just a library call. Before an agent or service can drive a browser, validate the target URL, launch arguments, binary provenance, network exposure, and acceptable-use scope.

This pattern is useful for screenshot services, browser agents, scraping endpoints, QA harnesses, and local browser-control tools. The point is not stealth; the point is that a browser is a powerful networked process and should be launched through a controlled boundary.

## Core Controls

1. **URL scheme allowlist:** accept only `http://` and `https://` unless a task explicitly requires something else.
2. **Private-network blocking:** reject loopback, link-local, private, carrier-grade NAT, metadata-service, and reserved IP ranges.
3. **DNS resolution before launch:** resolve hostnames and reject internal addresses before navigation.
4. **Redirect revalidation:** after navigation, revalidate the final URL before returning page content, screenshots, or extracted data.
5. **Launch-arg allowlist:** strip caller-controlled browser flags by default; only internal strategy code may add dangerous flags.
6. **Binary pinning:** pin the browser binary version and verify release checksums or attestations.
7. **Local override:** allow an explicit local binary path for environments that disallow runtime downloads.
8. **Auto-update policy:** disable surprise auto-updates in high-trust or reproducible environments.
9. **Network egress policy:** bind debugging and control ports to loopback unless deliberately exposed.
10. **Audit trail:** record who launched the browser, target URL, binary version, policy decisions, and artifacts returned.

## Why It Matters

A browser automation endpoint can become an SSRF primitive, credential exfiltration tool, metadata-service reader, or internal network scanner if it accepts arbitrary URLs and launch flags. Agent-driven browsers amplify that risk because the agent may follow untrusted page instructions.

The runtime boundary should assume the browser is dangerous by default and make safe use explicit.

## Implementation Notes

- Keep browser launch options in typed config objects rather than raw user-provided flags.
- Separate executable selection from interaction helpers like mouse, keyboard, scroll, and actionability waits.
- Verify downloads before extraction and extract into versioned cache directories.
- Prefer temp-file download plus atomic extraction to avoid partial binaries in cache.
- Treat proxy credentials and browser profile directories as sensitive.
- Make live external tests opt-in; default CI should run deterministic unit/integration tests.

## When To Use

Use this pattern whenever a service, agent, or web UI can ask a browser to visit a URL or execute automation on behalf of a user.

Do not use this pattern to justify bypassing access controls. The same controls that make browser automation safer also make it clear when a task is outside authorized scope.
