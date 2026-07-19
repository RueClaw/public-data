# clodex-ide Review

- Source: https://github.com/mereyabdenbekuly-ctrl/clodex-ide
- Author: mereyabdenbekuly-ctrl / Clodex contributors
- License: AGPL-3.0-only
- Reviewed: 2026-07-19
- Commit reviewed: `8d2618a91a541607944fb7eb7bad30001d5b4aeb`
- Verdict: ⚠️ Interesting

## What It Is

CLODEx is a local-first Electron/TypeScript agentic IDE for long-running software work. It tries to keep code, Git, terminal sessions, browser tabs, model providers, MCP tools, approvals, release evidence, and agent runtime state inside a durable desktop workspace rather than scattering them across a chat UI plus shell.

The project is not just a thin UI wrapper. It has a substantial architecture around process boundaries, capability authorization, deterministic policy, telemetry limits, release provenance, and migration from a legacy application core into independently governed packages.

## Why It Matters

The interesting part is the trust model. The docs repeatedly treat model output, websites, MCP responses, plugins, generated apps, remote runners, and attachments as untrusted input. Authority is meant to come from explicit capabilities, deterministic host policy, user review, bounded tool contracts, and auditable receipts.

That is the right shape for agentic development tools. Most agent IDEs sell autonomy first and retrofit safety later; CLODEx appears to be designing the authority boundary as a first-class product surface.

## Architecture

The desktop app is split into explicit lanes:

- Electron main owns service composition, windows, credentials, file access, policy, and IPC.
- React renderer owns the UI.
- UI preload exposes a narrow renderer-to-main bridge.
- Web-content preload instruments and contains browser-tab content.
- Agent Host supervises agent-step execution outside the main process.
- MCP Host supervises MCP transport and OAuth lifecycle.
- Sandbox workers handle constrained generated-code and tool workloads.
- CLI paths host Agent Core for headless operation.

Important package seams include `@clodex/agent-core`, `@clodex/agent-shell`, `@clodex/guardian`, `@clodex/approval`, `@clodex/kernel`, `@clodex/mcp-runtime`, contracts, evidence, runtime, registry, and production bootstrap packages.

The core agent path is roughly: user action -> renderer -> main -> agent host -> agent core -> policy/tool runtime -> approval or execution. The project also documents deny-by-default egress, protected storage, credential isolation, remote-job receipts, content-free telemetry, component provenance, and fail-closed migration rules.

## Strong Signals

- The security docs are unusually specific: model output cannot grant authority, Guardian/policy must authorize sensitive actions, missing or stale authorization fails closed, and renderers/web content/plugins/generated apps should not receive ambient host authority.
- `@clodex/guardian` implements a shell-independent Safe Coding Guardian around signed intent contracts, caller context, active-contract checks, mandatory policy overlays, adapter registry binding, PREPARE, final authority fences, TTLs, replay resistance, and budget reservation.
- `@clodex/approval` implements canonical approval artifacts with reviewer identity, current commitment checks, replay consumption, expiry, signed envelopes, and fail-closed error handling.
- The repo has extensive release and packaging evidence automation: community unsigned/observed build validators, byte-bound package checks, release publication immutability tests, attribution gates, artifact validation, SBOM/image checks, and signing-readiness workflows.
- GitHub Actions in inspected workflows are pinned to commit SHAs, and there is scheduled/full-history secret scanning with gitleaks.
- The docs are candid about current technical-preview status and unsigned builds. They tell users to verify SHA-256 hashes and use OS-level per-app review flows instead of disabling system protections globally.

## Caveats

- This is a very young project: created 2026-07-12, reviewed one week later. The architecture is ambitious and the docs are ahead of some extracted package maturity.
- The distributed preview builds are unsigned or ad-hoc signed, not notarized on macOS, and not Authenticode-signed on Windows. Treat the current release as a technical preview.
- The root license is AGPL-3.0-only. That is fine for use and study, but code reuse and networked derivative work need deliberate license handling.
- The dependency footprint is large: the lockfile audit saw 2,184 package locators and 463 direct dependency fields across 33 importers. Local install also ran native/postinstall tooling. That is not unusual for Electron, but it matters for a security-forward IDE.
- Some core extraction/migration docs describe scaffolding and boundaries still being established, especially around Agent Core separation from the Electron app.
- The current README points at a published Community Observed 11 build from commit `a2645d0...`, while this review looked at HEAD `8d2618...`. That is normal for an active repo, but do not assume HEAD exactly matches downloaded artifacts.

## Local Verification

Performed on macOS, shallow clone of `8d2618a91a541607944fb7eb7bad30001d5b4aeb`:

- `pnpm install --frozen-lockfile --ignore-pnpmfile` passed.
- `pnpm build:packages` passed.
- `pnpm test:boundaries` passed: 177 tests.
- `pnpm --filter @clodex/guardian test` passed: 19 tests.
- `pnpm --filter @clodex/mcp-runtime test` passed: 27 tests.
- `pnpm --filter @clodex/kernel test` passed: 13 tests.
- `pnpm --filter @clodex/approval test` passed: 32 tests.
- Targeted app tests passed: community-observed telemetry, CLODEx MCP service, and sandbox-JS Guardian approval, 27 tests total.
- `pnpm security:dependencies:test` passed: 15 policy tests.
- `pnpm security:dependencies -- --report=/tmp/clodex-dependency-audit.json` passed with no findings or blockers.

I did not run the full Electron application, full app typecheck, full repo test suite, or package installers.

## Adoption Notes

For evaluation, use a disposable profile and non-sensitive test repository first. Keep provider keys limited, verify release hashes, avoid granting broad filesystem or network authority until the approval surfaces are understood, and treat remote/cloud execution as a separate security review.

The best use today is as a reference-quality pilot for agent authority design, not as a casual daily-driver IDE install. If the project continues to ship signed builds, stable docs-to-code parity, and full release evidence, it could become a deploy candidate.

## Useful Patterns

- Treat model output as untrusted input, not as an actor with authority.
- Bind approval to exact principal, task, workspace, action, resource, policy digest, expiry, and replay state.
- Keep renderer, web content, plugin, generated-app, MCP, and agent-host authority separated.
- Use content-free telemetry allowlists, not "be careful" analytics conventions.
- Validate packaged artifacts byte-for-byte against expected manifests.
- Maintain component provenance and migration-boundary registries in CI.

No separate code or prompt extraction was made because the root license is AGPL-3.0-only and the most valuable takeaways are architectural patterns rather than reusable snippets.
