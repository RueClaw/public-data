# Hardware-Aware Local AI Appliance Installer

**Source:** https://github.com/Light-Heart-Labs/DreamServer
**License:** Apache-2.0
**Extracted:** 2026-05-24

## Pattern

Build local AI infrastructure as a hardware-aware appliance installer instead of a static compose file.

The reusable structure:

1. Detect OS, GPU vendor, accelerator backend, RAM, disk, Docker availability, and port availability before installation.
2. Convert detected hardware into a deterministic capability tier.
3. Select models and runtime settings from a versioned catalog rather than hard-coded installer branches.
4. Generate environment files, service credentials, and operator-facing recommendations as install artifacts.
5. Compose the stack from a base file plus hardware/backend overlays plus extension manifests.
6. Keep an explicit network exposure policy that maps every host-facing service to risk, LAN exposure, and auth expectations.
7. Validate release claims with automated contract tests for tiers, manifests, compose overlays, generated config, and security-sensitive defaults.
8. Provide support-bundle and diagnostic tools that redact or warn about sensitive local state.

## Why It Matters

Local AI stacks are brittle when installation is just “run these Docker commands.” Model size, GPU backend, memory limits, ports, service auth, and remote exposure all vary by host. A hardware-aware appliance installer turns that variability into explicit product logic.

This pattern is useful for:

- local LLM workstations;
- self-hosted AI labs;
- media generation servers;
- RAG/search appliances;
- edge AI deployments;
- any self-hosted stack with GPU-specific runtime paths.

## Implementation Notes

- Treat detection output as structured data that later phases consume.
- Keep model choice in a catalog with memory requirements, context settings, download metadata, and recommendation text.
- Split compose behavior into overlays instead of branching every service in one file.
- Make extension manifests the unit of optional capability.
- Generate strong per-install secrets; never ship shared defaults for auth-bearing services.
- Keep localhost as the default binding and make LAN mode explicit.
- Add tests that fail if a host-facing service is missing from the exposure policy.
- Add tests that compare documented release claims with executable support matrices.
- Make diagnostics safe to share by default, or make unsafe sharing hard to miss.

## Caveats

The pattern adds real maintenance burden. The installer, model catalog, compose overlays, docs, and validation matrix must evolve together. It works best when a project has enough test discipline to keep the appliance behavior from drifting as services are added.

---

**Attribution:** Light-Heart-Labs/DreamServer, Apache-2.0 License.
