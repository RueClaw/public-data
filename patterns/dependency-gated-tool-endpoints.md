# Dependency-Gated Tool Endpoints

**Source:** Stirling-Tools/Stirling-PDF
**Repo:** https://github.com/Stirling-Tools/Stirling-PDF
**License:** Mixed: root/open areas MIT; some source trees under Stirling PDF User License. Treat this as a design pattern summary, not reusable code.
**Reviewed:** 2026-05-30

## Pattern

When an application wraps optional local binaries, do not let endpoints discover missing tools only after a user submits work. Model feature availability explicitly:

- **Endpoint:** the user/API-visible operation, such as `compress-pdf`.
- **Tool group:** an implementation dependency, such as qpdf, Ghostscript, Java, LibreOffice, Tesseract, or WeasyPrint.
- **Functional group:** a product-level feature area that can be hidden or disabled as a unit.
- **Alternative implementations:** a list of tool groups that can satisfy the same endpoint.
- **Disable reason:** whether an endpoint/group was disabled by config, dependency check, or unknown cause.

Then run startup probes with short timeouts, mark unavailable tool groups, and enforce endpoint availability centrally with middleware/interceptors.

## Why It Matters

Self-hosted document, media, ML, and automation apps often depend on local tools whose availability varies by OS, package manager, container flavor, CPU architecture, and deployment size. Without explicit capability modeling, users hit runtime failures after uploads, agents call tools that cannot work, and UIs advertise features that the host cannot support.

This pattern gives the app a stable capability contract:

- UIs can hide or mark disabled tools.
- APIs can return a clear forbidden/unavailable response.
- Agents can discover what is actually callable.
- Operators can see whether missing capability came from config or host dependencies.
- Multi-implementation endpoints can continue working when one backend is missing.

## Implementation Shape

1. Define endpoint-to-tool-group mappings.
2. Define endpoint alternatives where multiple tools can satisfy one feature.
3. Probe external commands at startup with timeouts.
4. Disable missing tool groups with structured reasons.
5. Resolve each endpoint by checking explicit config, functional groups, and available alternatives.
6. Enforce the result in one request interceptor or router layer.
7. Expose the availability map to UI/admin/API clients.

## Good Fit

- PDF/document conversion suites.
- Media processing apps wrapping ffmpeg/ImageMagick/etc.
- Local AI stacks wrapping model servers, vector stores, OCR, TTS, or STT tools.
- Agent tool gateways where a model needs a truthful callable-tool catalog.
- Self-hosted services deployed across mixed architectures.

## Cautions

- Capability probes should not hang startup indefinitely.
- Version checks matter, not just command existence.
- User-facing "disabled" state should name the missing dependency where safe.
- Do not treat a dependency check as a security sandbox. It is availability logic, not isolation.
- Keep config-disabled and dependency-disabled separate so operators know what to fix.

## Source Notes

Stirling PDF implements this with endpoint/group registries, dependency probes, endpoint alternatives, and request interception. The pattern is especially useful because some PDF operations can use fallback tools while others require a specific binary.

**Attribution:** Stirling-Tools/Stirling-PDF, mixed MIT and Stirling PDF User License.
