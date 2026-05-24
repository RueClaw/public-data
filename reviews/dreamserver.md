# Dream Server (Light-Heart-Labs/DreamServer)

**Repo:** https://github.com/Light-Heart-Labs/DreamServer
**License:** Apache-2.0
**Reviewed:** 2026-05-24
**Stack:** Shell, Python, PowerShell, Docker Compose, FastAPI, React/Vite, TypeScript, Rust, llama.cpp, Open WebUI, LiteLLM, Qdrant, SearXNG, n8n, ComfyUI
**What it is:** Dream Server is a turnkey local AI appliance installer/control plane for running inference, chat, voice, workflows, agents, RAG/search, image generation, observability, and privacy tooling on a PC, Mac, Linux workstation, or homelab server.

---

## Verdict

✅ **Deploy candidate for a controlled local-AI appliance evaluation.** Dream Server is active, Apache-2.0 licensed, unusually well documented, and built around practical operator concerns: hardware detection, model selection, generated secrets, localhost-first defaults, extension manifests, support bundles, and release validation receipts. It is not something to run blindly from a curl pipe on sensitive machines. Treat it as a large infrastructure stack: clone it, inspect the installer choices, run the local validators, and deploy first on a lab host.

---

## What It Is

Dream Server packages the common local AI workstation stack into one installer-managed product. The core install wires together local LLM inference, Open WebUI, a dashboard, LiteLLM, voice services, vector search, metasearch, workflow automation, image generation, agent tooling, privacy tooling, and observability.

The project supports Linux with NVIDIA/AMD/Intel Arc paths, Windows through WSL2/Docker Desktop, and macOS Apple Silicon with native Metal llama-server plus Dockerized supporting services. It also supports cloud mode when no local GPU is available, using external model APIs behind the same general stack.

The strongest idea is that the installer is treated as a product surface rather than a pile of shell commands. Hardware detection selects a tier, a versioned model catalog picks GGUF/model settings, compose overlays adapt to GPU/backend paths, secrets are generated into environment files, and tests assert installer contracts.

## Stack

| Layer | Tech |
|-------|------|
| Installer | Bash, PowerShell, phased installer libraries |
| Orchestration | Docker Compose plus GPU/backend overlays |
| Inference | llama-server / llama.cpp, LiteLLM gateway |
| Chat/UI | Open WebUI, dashboard, dashboard API |
| Voice | Whisper speech-to-text, Kokoro/text-to-speech |
| RAG/search | Qdrant, TEI embeddings, SearXNG, Perplexica |
| Agents/workflows | Agent gateway/proxy, policy engine, n8n, coding assistant surfaces |
| Media | ComfyUI |
| Ops/privacy | Privacy proxy, token usage monitor, Langfuse, support bundles, diagnostics |

## Key Features

### Hardware-Aware Installer

The installer detects GPU/backend capability and maps hardware to deterministic tiers. Linux/macOS paths use a Python catalog selector over config/model-library.json, while Windows uses a PowerShell selector. The selected model, GGUF file, context size, and recommendation metadata are written into generated environment state.

### Localhost-First Network Posture

The documentation and architecture describe local access as the default. A network exposure policy file labels each host-facing service by risk, LAN exposure, and auth requirement. LAN exposure is explicit and operator-controlled rather than treated as the normal path.

### Generated Secrets and Auth Expectations

The stack generates secrets for web UI, workflow, gateway, dashboard, privacy, vector database, and related surfaces. Several services are marked auth-required in the exposure policy, and release/security docs call out support bundle redaction and the sensitivity of backups and diagnostic data.

### Extension/Manifest Model

Services are bundled as extension manifests and compose fragments rather than one monolithic compose file. That makes optional capabilities easier to audit, enable, disable, and test independently.

### Validation Receipts

The README points to a support matrix, validation matrix, distro/container tests, VM tests, and real hardware release gates. The repo also includes release-claim checks, dependency pin checks, installer contracts, network exposure contracts, Bash compatibility checks, and security-audit status tracking.

## Architecture

Dream Server uses a layered compose model:

- base compose defines core services;
- GPU/backend overlays adapt inference and runtime behavior;
- extension compose files add optional services;
- installer phases handle preflight, detection, features, requirements, Docker, directories, dev tools, images, offline mode, backend-specific tuning, services, health checks, and summary;
- a dashboard/control API gives operators a management surface after install.

This is closer to a local infrastructure distribution than a single app. The complexity is justified if the goal is a repeatable local AI workstation/server, but it means upgrade, backup, security, and troubleshooting practices matter.

## Verification

Validation run against commit 1343b02:

- make lint passed: shell syntax checks and dashboard API Python compile checks passed.
- python3 -m compileall over scripts, bin, dashboard API, and tests passed.
- uv run --with PyYAML --with jsonschema make test progressed through the tier map, installer contracts, installer context parity, preflight fixtures, and several cloud-mode assertions, but the full target failed later in tests/test-linux-cloud-mode.sh with a Python ValueError.
- python3 scripts/check-version-consistency.py passed for version 2.5.0.
- python3 scripts/check-dependency-pins.py passed.
- bash scripts/check-release-claims.sh passed.
- validate-env.sh could not be used with the macOS system Bash 3.2; the script requires Bash 4+.
- Secret scan found generated-secret code paths, placeholders, examples, and test fixtures; no obvious live committed credential stood out.

## Deployment Notes

- Prefer cloning and reviewing the installer over piping a network script directly into a shell.
- Start with a lab host, not a primary workstation with sensitive data.
- Keep default localhost behavior unless a LAN deployment is intentional.
- Pair any LAN or remote exposure with firewalling, TLS or VPN, and service-specific auth review.
- Treat support bundles, backups, model logs, traces, and vector stores as sensitive.
- Review the generated .env before sharing diagnostics or moving an install.
- Re-run local validation after changing extension manifests, compose overlays, model catalogs, or installer phases.

## Fit

Dream Server is a strong candidate when the desired outcome is “make this machine a local AI appliance” rather than “install one chat app.” Its strongest reusable contribution is the hardware-aware appliance installer pattern: detect capability, choose models from a versioned catalog, generate secrets/config, compose services from manifests, assert exposure policy in tests, and publish validation receipts.

It is probably too large for casual experimentation if the user only wants one service like Open WebUI or ComfyUI. For a lab, workstation, or home server where local inference plus RAG/voice/workflows/agents should be operated as one product, it is worth serious evaluation.

---

**Attribution:** Light-Heart-Labs/DreamServer, Apache-2.0 License.
