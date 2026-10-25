# OpenUI (thesysdev/openui)

**Repo:** https://github.com/thesysdev/openui
**License:** MIT
**Reviewed:** 2026-10-25 (UTC)
**Revision:** 9d73d17d2bbac565672a85e78f6eb7740cb0d9ca; sampled repository-wide architecture, documentation, manifests, security boundaries and tests listed below.
**Verification:** Static source review only. No source execution, installs, device operations, deployments or paid calls.
**Stack:** TypeScript, pnpm, Zod, React / Vue / Svelte / Angular
**What it is:** Streaming generative-UI language and component runtimes with library-derived prompts.

---

## Verdict

⚠️ **Interesting.** A strong integration candidate for constrained generative interfaces, not a security sandbox or a finished authenticated application. Pilot its parser and component contracts against real model outputs before adopting the advertised token savings.

## What It Is

Streaming generative-UI language and component runtimes with library-derived prompts. OpenUI Lang streams structured component expressions instead of verbose JSON. Component libraries generate model instructions and schemas; the parser and evaluator progressively materialize the interface.

## Stack

| Layer | Technology |
|---|---|
| Implementation | TypeScript, pnpm, Zod, React / Vue / Svelte / Angular |
| Runtime and deployment | See platform constraints below; no deployment was performed. |

## Key Features

### Functionality

OpenUI Lang streams structured component expressions instead of verbose JSON. Component libraries generate model instructions and schemas; the parser and evaluator progressively materialize the interface.

### Boundaries and recovery

lang-core is framework-independent. React has the richest prebuilt UI/chat packages; Vue, Svelte and Angular bindings share the language core, not necessarily feature parity with React libraries.

### Integration and evidence

The repository also includes server utilities, A2UI support, LangChain/AG-UI adapters, CLI scaffolding and an optional hosted observability sink. These are distinct integration surfaces, not one mandatory hosted service.

## Architecture

packages/lang-core separates lexer/parser/AST/materialization, schema validation, prompt generation and reactive runtime evaluation. The evaluator dispatches typed AST cases and host-provided library functions; framework packages supply rendering. This is a registered-component/action model, not arbitrary model-authored JavaScript as the intended output format. Host-provided functions and actions still determine real capabilities.

## Security and Privacy

Constrained component rendering reduces arbitrary-markup exposure but does not authorize side effects. Enforce permissions, tool arguments, navigation/URL policy and sensitive data access in the host, not model instructions. Installation telemetry runs in postinstall unless disabled; runtime telemetry is separately opt-in. Source documents random identifiers, hashed project/config identities and transport-visible IP metadata. OPENUI_TELEMETRY_DISABLED or DO_NOT_TRACK disables telemetry; browser runtime telemetry is excluded. Optional cloud observability and chosen LLM providers create separate data-egress decisions.

## Platform and Self-Hosting Notes

Use the package matching the application framework and pin compatible versions across the monorepo packages. Browser-bundle embeds carry the renderer/UI/runtime weight; they are not evidence that every package is framework-free. Authentication, rate limits, provider credentials, persistence and safe tool handlers remain application responsibilities. No hosted deployment or paid provider is needed for static evaluation.

## Evidence, Tests and Limitations

Build JS CI installs a frozen pnpm lockfile, builds packages and invokes package CI; separate CLI E2E/example workflows exist. None were run. The up-to-67%-fewer-tokens headline is a project benchmark claim, not a reproduced end-to-end cost, latency or quality result; actual savings depend on schemas, prompts, retries and workload.

This is a sampled static assessment, not a certification or exhaustive security audit. Source claims about hardware, performance and operational recovery remain unverified unless explicitly identified otherwise. Dependency advisories and released-binary provenance were not audited.

## Maturity and Releases

Latest-release API returned @openuidev/cli@0.6.0 (2026-10-15); this is a package-specific release, not a single version for all runtimes. Public API snapshot 2026-10-25: 13881 stars, 913 forks, 176 open issues/PRs; created 2024-12-02T10:40:06Z; last push 2026-10-25T19:30:12Z.

Popularity and issue counts are discovery signals, not evidence of safety or test success. Mutable metadata was retrieved anonymously on the review date; conclusions refer to the exact source revision above.

## Comparison

A2UI is worth comparing for protocol-oriented native rendering, json-render for schema/catalog-driven React output, and assistant-ui for chat UX rather than a new UI language. Choose OpenUI when compact streaming grammar plus multi-framework bindings justify another protocol layer.

## License and Reuse

The root MIT terms permit reuse with copyright and permission notices retained. Bundled dependencies, fonts, media and external services retain their own terms; the stated exceptions must not be flattened into MIT-only redistribution. No upstream code was extracted in this review.

## Source Evidence

- [README.md](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/README.md)
- [LICENSE](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/LICENSE)
- [packages/lang-core/src/parser/parser.ts](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/packages/lang-core/src/parser/parser.ts)
- [packages/lang-core/src/runtime/evaluator.ts](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/packages/lang-core/src/runtime/evaluator.ts)
- [packages/lang-core/src/telemetry/install.ts](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/packages/lang-core/src/telemetry/install.ts)
- [packages/lang-core/src/telemetry/runtime.ts](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/packages/lang-core/src/telemetry/runtime.ts)
- [packages/lang-core/src/telemetry/shared.ts](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/packages/lang-core/src/telemetry/shared.ts)
- [.github/workflows/build-js.yml](https://github.com/thesysdev/openui/blob/9d73d17d2bbac565672a85e78f6eb7740cb0d9ca/.github/workflows/build-js.yml)

---

**Attribution:** thesysdev/openui; MIT. Analysis based only on public source.
