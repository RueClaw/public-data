# Legal Document Workspace Access Model

**Source:** https://github.com/willchen96/mike
**Author:** willchen96
**License:** AGPL-3.0-only
**Reviewed:** 2026-05-23

## Pattern

Build a legal document assistant around backend-owned data access, centralized access helpers, authenticated signed downloads, encrypted per-user model keys, and explicit document-citation rules.

This pattern is summarized from an AGPL-licensed project. Treat it as architectural analysis, not permissively reusable code.

## Why It Works

Legal-document assistants handle sensitive files, private model keys, generated documents, and shared workspaces. The risky default is to scatter user_id filters, hand browser clients direct database access, and pass raw storage URLs through model outputs.

Mike's architecture points toward a safer model:

- Browser uses Supabase primarily for authentication.
- Application data access goes through the backend.
- Backend verifies the user's JWT, then uses service-role database access.
- Owner/shared-member checks live in shared helpers.
- Storage downloads use backend-relative signed tokens, not arbitrary external URLs.
- User model keys are encrypted server-side.
- Prompt/tool rules require citations and constrain document editing behavior.

## Core Components

- **Backend-owned database access:** revoke direct table access from browser roles for app-owned tables.
- **Central access helpers:** one project/document/review permission model reused by routes.
- **Authenticated download route:** signed token identifies storage object, but auth and document access are still checked before streaming.
- **Off-origin URL refusal:** frontend only attaches bearer tokens to backend-relative download URLs.
- **Encrypted user provider keys:** store encrypted model keys with a server-side encryption secret; let environment keys override user-managed keys.
- **Document-specific prompt contract:** require exact citations, prevent fabricated document claims, and make editing tools explicit.
- **Rate limits by workflow type:** uploads, chat, and chat creation get separate limits.

## Implementation Notes

- Sign download payloads with an HMAC, but do not treat signature validity as authorization.
- Check document access after resolving the signed storage path to a document/version row.
- Normalize and sanitize filenames before Content-Disposition headers.
- Use per-provider key status APIs that reveal presence/source, not raw key values.
- Keep sharing logic out of route bodies where possible; access drift is easier to miss than syntax errors.
- For legal edits, force cross-reference and numbering updates into the same edit operation.

## Good Fit

- Legal document review assistants.
- Contract lifecycle or diligence workspaces.
- Healthcare, finance, or compliance document tools with shared projects.
- Any app where model-generated file links must not exfiltrate bearer tokens.

## Watch Outs

- Upload libraries and document parsers are high-risk dependencies and need active patching.
- Backend service-role architecture depends on complete route-level authorization.
- Non-expiring signed download tokens should remain coupled to auth/access checks.
- Per-user API key encryption needs rotation and incident-response planning.
- Copyleft licensing of the source project limits direct code reuse in closed deployments.

---

**Attribution:** willchen96/mike, AGPL-3.0-only
