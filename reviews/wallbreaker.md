# Wallbreaker (JailbrokenAI/wallbreaker)

- Repository: https://github.com/JailbrokenAI/wallbreaker
- Reviewed: 2026-07-18
- License: AGPL-3.0-or-later in package metadata; LICENSE is AGPL-3.0
- Current commit checked: bfd1d646b2d5ca5aff38b6876ab914c664a20e0e
- GitHub metadata observed: 410 stars, 77 forks, 1 open issue, no tagged release
- Package version observed: 0.1.0
- Stack: Python 3.11+, Textual/Rich CLI, httpx provider clients, MCP bridge, optional FastAPI dashboard, optional barcode/steganography/image tooling

## Verdict

⚠️ Interesting, but authorized-lab-only.

Wallbreaker is a serious LLM red-team harness, not a general agent utility. It combines an attacker/target/judge setup, provider adapters, a terminal operator interface, transform engines, automated campaign loops, reporting/export tools, an optional dashboard, and a large catalog of red-team techniques. The project is useful to study if you are building controlled model-safety evaluation workflows, especially around run logging, role separation, rate gating, and evidence review.

The caveat is the same thing that makes it interesting: it is built to generate and evaluate jailbreak attempts. Run it only in an explicitly authorized environment, with throwaway credentials, isolated working directories, careful artifact handling, and license obligations understood.

## What It Is

Wallbreaker is a Claude-Code-style terminal harness for testing LLM safety boundaries. A configured attacker model drives the campaign, a target model receives probes, and an optional judge grades outputs. Providers can be OpenAI-compatible endpoints, Anthropic-compatible endpoints, OpenRouter-style routing, Z.AI/GLM profiles, local servers, or a local Claude Code CLI acting as the attacker brain.

The repo includes:

- CLI entry points: `wallbreaker`, `wb`, and `p4rs3lt0ngv3-mcp`.
- Profiles for attacker, target, judge, art/image, and MCP servers.
- A Textual/Rich terminal app plus one-shot and automated modes.
- Run logs, findings export, HTML reports, regrading, baseline checks, and dashboard views.
- File, shell, transform, judge, target, image, session, campaign, and library tooling.
- A large test suite covering providers, tools, CLI behavior, dashboard controls, session logging, transforms, and red-team orchestration.

## Notable Design Choices

- Separates attacker, target, and judge roles in configuration instead of assuming one provider or model.
- Uses env-var-backed API keys in the example config, while still allowing inline keys and CLI `--api-key` overrides.
- Applies a process-wide provider request gate with concurrency and request-start pacing keyed by endpoint origin and credential hash.
- Logs model/run metadata and supports later regrading and report generation.
- Defaults the dashboard server to `127.0.0.1:8787`; CORS accepts only localhost/127.0.0.1 origins.
- Gitignores runtime outputs such as `wb_runs/`, `wb_images/`, `wb_artifacts/`, `findings/`, `sessions/`, `.env`, and `config.toml`.
- Explicitly warns in `SECURITY.md` that artifacts may contain sensitive or harmful content and should be handled accordingly.

## Verification

- Fresh shallow clone of `main` checked at `bfd1d646b2d5ca5aff38b6876ab914c664a20e0e`.
- GitHub metadata observed on 2026-07-18: 410 stars, 77 forks, 1 open issue, no latest release.
- `python -m compileall -q wallbreaker p4rs3lt0ngv3_mcp` passed in a clean virtualenv.
- Installed editable with dev, dashboard, barcode, and stego extras.
- `python -m pytest -q` result: 1056 passed, 27 skipped, 41 failed, 7 errors.
- The failing/erroring tests consistently depended on non-redistributed, gitignored runtime corpora under `library/`, especially ENI files and leaked system-prompt folders. That makes the published checkout partially unverifiable unless those corpora are supplied out-of-band.
- Secret-pattern scan found placeholders, test fixtures, and deliberately fake planted secrets, but no obvious committed real credentials.

## Risks And Caveats

- This is dual-use red-team software. Treat all generated prompts, target outputs, logs, reports, images, and findings as potentially sensitive.
- Some functionality depends on external corpora that are intentionally not redistributed in the repo. The tests assume those corpora exist, so the public checkout does not fully pass in isolation.
- The harness exposes shell and file tools to the attacker agent. The implementations add timeouts and working-directory handling, but the safe operating model is still a disposable sandbox.
- Inline API keys and CLI `--api-key` are supported. Prefer environment variables or a secret manager to avoid shell history and config leakage.
- The config supports requesting reasoning/thinking output from targets. That may be sensitive and should be disabled unless the tested model/provider and authorization scope explicitly allow it.
- The sample red-team GitHub Actions workflow writes secrets into a generated `config.toml` during CI. It is an example, not a drop-in safe workflow.
- AGPL applies to modified/network-hosted versions; confirm obligations before adapting or operating a modified service.
- Third-party jailbreak/prompt corpora mentioned in NOTICE may have no explicit upstream license. Do not treat them as freely reusable assets.

## Useful Patterns

- Model-safety harnesses benefit from explicit attacker/target/judge role separation.
- Request gating should group by supplier origin and credential, not just by process-wide concurrency.
- Runtime artifacts from adversarial testing should be gitignored by default and documented as sensitive.
- Regrading and report/export commands make red-team runs auditable after the fact.
- Localhost-only dashboard defaults and constrained CORS are the right baseline for operator dashboards.
- Tool docs should state what authority the agent gets, especially for shell and file tools.

## Recommendation

Study it as a red-team harness architecture and possibly pilot it only inside an authorized lab with disposable credentials, a clean working directory, network controls, and artifact retention rules. Do not install it into a normal personal agent workspace or run it against third-party systems.

