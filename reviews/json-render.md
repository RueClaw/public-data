# json-render (vercel-labs/json-render)

**Repo:** https://github.com/vercel-labs/json-render
**License:** Apache-2.0; retain license/notices and mark modifications when redistributing. Dependency licenses need separate review.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** 18194121c8f087afacd9a8ef65fbda18374ee039; package/release v0.22.0; repository-wide static review with emphasis on core, React, Chat and MCP implementations and the chat example.
**Verification:** Static source inspection only. No dependency installs, repository code execution, builds, tests, provider calls or deployments.
**Stack:** TypeScript, Zod 4, React and other renderer adapters; pnpm/Turborepo/Vitest.
**What it is:** A catalog-driven generative UI framework: application code defines components and actions, a model or other producer supplies JSON, and adapters turn that spec into UI or documents.

## Verdict

⚠️ **Interesting — a useful UI intermediate representation, not a security boundary.** The catalog/registry separation and streaming machinery are worth adopting in a bounded application. Do not deploy an untrusted-spec endpoint assuming catalog prompts or the generic validator enforce component props, action permissions, safe URLs, or resource budgets. Start with read-only UI and an application-owned validation layer.

## Update Notes

This refresh replaces the public review dated 2026-03-23, which did not pin a revision. The same source and artifact slug are retained; a precise commit-to-commit delta is unavailable. The current release adds Chat SDK cards; the tree also contains framework routing/devtools packages and experimental candidate evaluation. More importantly, this review corrects the previous five-fire assessment and unsupported “excellent test coverage” language, distinguishes structural checks from component validation, and removes speculation about future licensing. Current source and actual Apache terms, not a hypothetical future license, govern this assessment.

## What It Is

A flat spec contains a root key and an element map; elements reference component types, props, children and optional slots. State and expression resolution add visibility, repeats, bindings and actions. A developer supplies the actual component implementations. This avoids asking a model to generate and execute arbitrary application code, but the resulting JSON can still select sensitive capabilities exposed by those implementations.

Generation is optional: static specs work without any model. The model-independent core should not be confused with examples that use Vercel AI Gateway, or the optional experimental evaluator that calls a hosted service.

## Stack

| Layer | Implementation |
|---|---|
| Catalog/schema | Core schema builder, Zod props definitions, prompt and JSON Schema generation |
| Interactive web | React, Vue, Svelte, Solid; shadcn catalogs; Next and TanStack Start integration packages |
| Other targets | React Native, React Three Fiber, Remotion, React PDF, React Email, Ink, image/Satori, Chat SDK, MCP Apps |
| State | In-memory StateStore, framework contexts, Redux/Zustand/Jotai/XState adapters |
| Tooling | pnpm 11, Node >=24, Turborepo, TypeScript, Vitest; lockfile and GitHub Actions |

## Key Features

### Catalogs are a vocabulary, not guaranteed model output

The README claims output matches the schema “every time.” Actual [catalog validation](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/core/src/schema.ts) calls a generated Zod schema, but its `propsOf` implementation deliberately returns `z.record(z.string(), z.unknown())` when there are multiple component prop schemas. It does **not** build a discriminated union matching each element type to its props. A catalog with one props schema behaves differently. Known component names can be enforced by the generated enum, but only if validation is actually called; a prompt is not enforcement.

The [React schema](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/react/src/schema.ts) describes root/elements and optional visible/repeat/slots, while runtime specs also use state, on and watch. Its ordinary Zod object generation can strip fields outside that declared shape. Treat validation output as a tested integration contract, not an interchangeable full-runtime spec. Validate each selected component's resolved props explicitly, with separate rules for expression syntax and trusted state-derived values.

[validateSpec](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/core/src/spec-validator.ts) checks roots, child references, visibility forms, repeat contexts and misplaced fields. It does not take a catalog and therefore cannot reject unknown component types or enforce per-component prop schemas. Its ancestor guard avoids looping during one structural traversal but does not report cycles as invalid. A self-referencing child graph needs explicit application rejection before recursive rendering. These are static deductions, not executed exploit demonstrations.

### Streaming and repair are useful but tolerant

[SpecStream](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/core/src/types.ts) buffers newline-delimited JSON patches, mutates a spec and emits shallow snapshots. Malformed lines can be ignored; the parser checks for op/path rather than validating a complete patch schema. Replace intentionally sets missing targets for streaming tolerance; this is not strict RFC 6902 validation. The compiler retains its buffer and applied-patch history without an application budget. Bound bytes, line length, patch count, tree depth, repeat size and elapsed time.

Auto-fix can move misplaced fields and prune dangling references; structured fix details mark lossy pruning. Retrying while preserving content is different from silently accepting a pruned result. React hooks provide abort/error handling; missing components/children can disappear with console warnings, and per-element error boundaries render nothing after failures and reset on a changed reset key. None of this guarantees a complete or semantically correct result.

### State and actions are real application capabilities

[React rendering](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/react/src/renderer.tsx) resolves state/item/template/conditional expressions and calls registered computed functions. Bindings write state; repeated children inherit item scope; watchers skip initial mount and dispatch when watched values change. Registered functions/directives remain trusted executable code, not sandboxed model expressions.

The [action provider](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/react/src/contexts/actions.tsx) implements state mutations and other built-ins, then dispatches registered handlers. Confirmation is driven by the supplied binding; it is not server authorization. The registry helper forwards params to action functions without automatically parsing them against catalog action schemas. Watchers and chained callbacks also mean “the user clicked a button” is not a safe universal assumption.

Keep principal identity, tenant IDs, access policy and secrets out of writable model state. On the server, revalidate action params, authorize every resource, protect against CSRF/replay as applicable, rate-limit and use idempotency keys for side effects. Require server-owned confirmation policy for costly/destructive operations; an absent model-supplied confirm flag must not bypass it. Visibility and disabled controls are presentation, not access control.

## Architecture and Trust Boundaries

1. **Trusted developer catalog/registry → generation prompt.** Catalog descriptions help the model select a vocabulary. User messages, retrieved content and tool output can still inject instructions; the model must not decide its own permissions.
2. **Untrusted JSON → validation → resolution → rendering.** Separate shape, graph, expression, component-prop and policy checks. Revalidate resolved URLs and action parameters; a syntactically valid state reference can resolve to an unsafe value. Render only a minimal allowlisted registry.
3. **Rendered component → browser/network/host side effect.** Ordinary React text escaping is useful, but URLs and custom components are different sinks. [shadcn components](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/shadcn/src/components.tsx) pass image sources and link hrefs onward; [email](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/react-email/src/components/standard.tsx) and [image](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/image/src/components/standard.tsx) likewise accept URLs. The shared layer is not a universal URL sanitizer. Allowlist schemes/origins, block private-network destinations for server-side fetchers, constrain redirects and isolate remote asset retrieval. Browser images can leak requests; server-side rendering dependencies may fetch resources. Actual SSRF exploitability was not tested.
4. **MCP app HTML → host iframe.** [MCP server registration](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/mcp/src/server.ts) validates through catalog.validate, but inherits that validator's limits. Its advertised CSP allows all HTTPS resource and connection domains, not an application-specific allowlist. [buildAppHtml](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/mcp/src/build-app-html.ts) escapes title but deliberately inserts developer-supplied head/CSS/JS. Those are trusted bundle inputs, never places to insert model text. Host isolation and user consent do not replace backend authorization.
5. **Prototype/path and resource handling.** Core mutable JSON-pointer helpers reject __proto__ segments and use own-property/dense-array handling. This is welcome hardening, not a blanket guarantee for every setter: [immutableSetByPath](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/core/src/state-store.ts) is a separate implementation. Reject dangerous path segments at ingress and review each state adapter. No working prototype-pollution exploit is claimed here.

## Platform Adapters and Recovery

Shared vocabulary does not mean identical component sets or validation behavior. PDF, email, image, terminal, video and 3D adapters have different resource and output semantics; choose a target-specific catalog. Routing integrations and code generation expand the trusted surface and deserve a separate deployment review.

The new [Chat renderer](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/chat/src/render.ts) is a notable contrast to generic validation: it resolves elements and checks each component's props, plus structure and optional platform limits, before final card output. [streamCard](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/chat/src/stream.ts) posts partial cards and throttles edits (500 ms default), then validates the final card. If final validation or posting fails, an already-visible partial message can remain. The caller must handle retries, platform 429s, cleanup/error edits and duplicate-post avoidance; the helper does not provide a durable delivery transaction.

## Provider Data and Cost Flows

The [chat API example](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/examples/chat/app/api/generate/route.ts) sends converted conversation messages into an AI SDK agent. Its [agent](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/examples/chat/lib/agent.ts) uses a configurable Gateway model and public-data tools, including a web-search provider, with a five-step stop condition. Prompts, history and tool results therefore leave the application under the selected provider's terms. No inference is required just to render an existing spec.

The example [rate limiter](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/examples/chat/lib/rate-limit.ts) uses Upstash Redis when configured but **allows requests when Redis is absent**. The shown route has no user-authentication check and trusts a forwarded IP header; safe interpretation depends on a trusted reverse proxy. A duration limit and five tool steps are not per-user monetary budgets. Add authenticated quotas, input/output limits, concurrency caps, provider spend limits, request cancellation and retention rules. Keep Gateway and Redis credentials server-side.

The optional [experimental evaluator](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/packages/core/src/experimental-evaluator.ts) explicitly posts evaluation requests to Vercel AI Gateway using a supplied API key/model. Do not describe the whole repository as offline because normal rendering can be offline. Candidate evaluation is a separate opt-in data/cost path. Provider privacy, actual token costs and hosted availability were not tested.

## Maturity, Tests and License

At retrieval, public GitHub metadata reported 19,319 stars, 1,024 forks and 121 open issues/PRs; last repository push was 2026-11-06. The checked commit is dated 2026-11-04, and [v0.22.0](https://github.com/vercel-labs/json-render/releases/tag/v0.22.0) was published that day. Popularity is not a security or reliability test. A small open-work sample included proposed directive and Chat renderer improvements; proposals were not counted as shipped features.

There are 86 package test files matching *.test.* in the acquired tree, including schema, pointer/state, streaming, rendering and chained-action tests. [CI](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/.github/workflows/ci.yml) installs with a frozen lockfile, builds packages and runs tests, lint, type checks and docs builds; version synchronization and a [release workflow](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/.github/workflows/release.yml) are present. This establishes test infrastructure, **not measured coverage or passing checks at this SHA**. Neither local tests nor CI-run outcomes were verified. Recent changelog fixes for JSON pointers, repeated stream operations, YAML copy growth and codegen object keys show active maintenance and why pinning matters.

The root [LICENSE](https://github.com/vercel-labs/json-render/blob/18194121c8f087afacd9a8ef65fbda18374ee039/LICENSE) is Apache-2.0, including patent terms and notice obligations. Core directly depends on Zod; renderer dependencies vary, including React ecosystem libraries, Satori, MCP/Chat SDKs and native/output tooling. A full transitive vulnerability/license audit was not performed. Remotion and other optional ecosystems require their own applicable license review; the root license does not automatically relicense dependencies.

## Comparison

| Approach | Better fit | Tradeoff against json-render |
|---|---|---|
| Handwritten React + AI SDK structured/tool output | Small fixed workflows | Less generic renderer machinery; more explicit domain validation and UI control |
| JSON Forms / react-jsonschema-form | Schema-driven forms | Stronger focus on forms rather than streaming arbitrary component compositions |
| Adaptive Cards | Portable host-supported cards | Narrower host vocabulary; useful when portability matters more than custom interactive components |
| A2UI | Agent-to-UI protocol exploration | Compare protocol/host support and maturity separately; not a drop-in assurance of safer execution |

These are architectural alternatives, not head-to-head benchmarks. For a few screens, explicit application UI is often simpler. json-render becomes more attractive when multiple catalogs and generated layouts justify maintaining a constrained UI language.

## Self-Hosting Notes

This is a library ecosystem, not a ready-to-secure hosted service. Pin a release and only the adapters needed; the development monorepo currently requires Node >=24 and pnpm >=11. Serve model calls behind your own authenticated backend, maintain narrow registries and keep preview state separate from committed business data. Disable side-effecting actions during generation; validate and authorize before enabling them. Add render boundaries, a last-known-good spec, repair budgets and structured failure reporting rather than relying on silent disappearance. For MCP apps, restrict resource/connect origins and supply only trusted bundles.

## Verification and Limitations

Public unauthenticated HTTPS acquisition and exact source SHA were verified. Local and live existing reviews were checked; this is an in-place refresh, not a second review. Source files, manifests, license, CI definitions, tests, changelog and public release/metadata were inspected. This was not an exhaustive audit of every adapter, a runtime exploit test, a benchmark, or a provider compliance assessment. No source code or dependencies were executed. Claims about parser/validator behavior are static source findings.

**Attribution:** Vercel Labs / vercel-labs/json-render, Apache-2.0. Public metadata retrieved 2026-11-07 UTC.
