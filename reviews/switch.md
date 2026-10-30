# Switch (osolmaz/switch)

**Repo:** https://github.com/osolmaz/switch
**Author:** Onur Solmaz
**License:** MIT; retain copyright and permission notices when reusing substantial code. Dependencies and external models/services retain their own terms.
**Reviewed:** 2026-10-30 (UTC)
**Revision:** `7c5b6b9bae55e9e7cda3efe310f585187eb7c717`; repository-wide architectural review, focused on core loop/replay, model adapter, CLI persistence, viewer and rubric-judge example.
**Verification:** Static source and public GitHub metadata review only. No installation, source execution, tests, inference, model downloads or document conversion performed.
**Stack:** TypeScript ESM, Node.js >=22.18, pnpm, pi-ai, Commander, Zod; Vitest and separate example/viewer workspaces.
**What it is:** A framework for writing finite-choice decision-model harnesses. Application code enumerates questions/actions and owns state transitions; a classifier such as Jev selects answers rather than generating free-form tools or text.

---

## Verdict

⚠️ **Interesting — a clear, reusable decision-loop design, not a production-ready general agent or validated replacement judge.** The strongest parts are host-generated action menus, inspectable typed answers, and state-based replay that does not repeat recorded effects. Adopt for a bounded experiment where the domain can enumerate safe actions; first validate provider limits, private-data handling and task-specific accuracy. This is five-day-old software with concrete interoperability gaps and non-held-out evaluation claims.

## What It Is

Switch is neither an OS switcher nor a model-routing proxy. Its canonical identity is Onur Solmaz's decision-model harness library, published as `@osolmaz/switch` (manifest version 0.1.1). Developers implement a JSON state machine: `initial`, `questions` and asynchronous `transition`, optionally projecting the state through `view`. Questions can be boolean, choice or score; when none remain, the run ends. [1–3]

The motivation is selective evidence gathering: a rubric judge can read individual documents, inspect images or search terms before grading, instead of passing an entire document collection to a chat model. Examples cover rubric judging, chess and Wikipedia link navigation. This is an SDK and example suite, not a ready-made business application, inference engine, training pipeline or durable multi-tenant service. The README's potential hundredfold task-cost saving is an aspiration about specialized models, not an independently established result. [1,8]

## Stack

| Layer | Technology and boundary |
|---|---|
| Core | TypeScript state machines, typed question/answer contracts, JSON traces and SHA-256 definition hashes |
| Model access | pi-ai 1.4.0 classifier registry; provider/id selection; optional explicit key or provider environment lookup |
| CLI | Commander 15.0.0; run/replay and domain-specific extensions; local JSON/JSONL files |
| Validation | Zod 4.6.7, especially persisted artifact schemas |
| Viewer | Separate source workspace; Node HTTP loopback server, embedded browser modules, standalone case export |
| Examples | chess.js; PDF.js, XML/ZIP/email parsers for document ingestion; Wikipedia HTTP API |
| Development | TypeScript 6.0.3, Vitest 5.0.5, ESLint, Prettier, coverage gates, Slophammer; Stryker configuration |

Direct dependencies are exact-version pinned and a pnpm lockfile is committed. That aids reproducibility, not proof of vulnerability freedom. No package advisory audit or full transitive-license audit was performed. The root MIT license is genuine, copyright 2026 Onur Solmaz. External converters, Stockfish, model weights and hosted service access are not relicensed by Switch. [1,10]

## Key Features

### Host-owned menus, with explicit validation

The `picking` helper rejects duplicate choice keys/text, retains the lowest-priority-value choices up to a limit, gives them compact labels and keeps stable keys in trace metadata. The model receives the question without Switch's internal `data`. The loop rejects missing answers, wrong answer types and choice labels outside the offered criteria. This materially reduces invented-action surface compared with arbitrary generated tool calls. [2,3]

The action space is only as good as the domain author: omitted choices are impossible to select, and truncating menus can discard the useful next step. Choices are regenerated for transition, so choice generation should be deterministic for a given state. Type membership is not permission enforcement, correctness, probability calibration or a sandbox.

### Bounded views and request adaptation

Question batches are estimated with JSON characters per token; 40% of the usable window is allocated to question grouping. A domain view receives the remaining budget. Recognized context overflow retries shrink the view by 0.7, for at most three requests; without a custom view, the loop cannot shrink state. A configured step limit bounds transitions, but the limit is optional and is not a total token/dollar budget. The adapter defaults to a 300-second request timeout and two provider retries. [2,5]

Three open pull requests identify real compatibility risks consistent with the inspected implementation: one-option choices still reach the provider (#42), batching has no 64-question-count cap (#41), and overflow detection misses some vLLM-SR/llama.cpp error spellings (#40). These are public contributor reports, not failures reproduced here; fixes were not in the reviewed SHA. More than 32 rubric items can create over 64 boolean questions, though whether they land in one batch also depends on their estimated size. [2,5,12]

### Replay without repeating recorded effects

Trace replay takes recorded states and answers rather than rerunning past transitions or contacting a model for recorded steps. It checks domain/case consistency and question compatibility; picks can be relabeled by stable key. A fork repeats a prefix, then permits new inference and transitions. This is an unusually useful debugging boundary for effectful domains. [2,4]

Do not confuse this with proof of reproducibility or exactly-once processing. A changed definition hash is noted rather than rejected during replay, and the default hash covers limits, not the complete domain program. Recorded state is trusted as domain state. A trace is neither a signed attestation nor safe input for arbitrary continuation; a fork resumes executable domain code and can make paid requests.

## Architecture

1. A domain supplies shared name/version/limits/definition and a per-case state machine.
2. The loop asks the current state's questions, projects state into a model view, batches requests and validates answer fit.
3. Trusted application transition code computes the next state; the trace records questions, answers and states.
4. A pi-ai adapter maps this to classifier API context and normalizes errors/timing. A separate recording wrapper preserves requests/results, replacing image bytes with image labels in request logs.
5. CLI runs produce `run.json` plus per-case `result.json`, `trace.jsonl` and `requests.jsonl`. The viewer reads those artifacts independently. [2–7]

The separation is clean: core has no chess or legal-domain imports, and examples consume the package as outside clients. JSONL writes are serialized through a promise chain. This is useful local persistence, not a distributed transactional scheduler. Application callbacks can throw; the core's modeled failed-request result does not guarantee every domain exception becomes a completed failure trace.

## Security, Privacy and Execution Boundaries

- **Credentials and egress:** pi-ai receives the explicit API key or resolves provider environment credentials. State, questions and optional page images are sent to the configured classifier. Using an open-model-compatible interface does not itself make inference local. Review provider data policy before sending legal/client material. No credentials were supplied or used in this review. [5]
- **Logs are sensitive:** requests and full successive states can retain document text, judgments and errors. Images are logged by label in the request recorder, but source case assets and exported viewer pages can remain sensitive. There is no general redaction/encryption/retention layer in the inspected recording path. Keep run directories private and inspect exports before sharing. [6,7]
- **Actions remain privileged code:** transitions, setup and viewer extension modules are trusted application code. Finite choices reduce syntactic freedom but cannot stop prompt-injected evidence from influencing a harmful allowed choice. Put authorization, human approval and resource restrictions in the host/domain.
- **Document ingestion is a native-code boundary:** the rubric example invokes Poppler, LibreOffice and Netpbm with `execFile` argument arrays and temporary files, avoiding shell-string interpolation. These parsers still process potentially hostile files with the process's privileges. LibreOffice has a timeout; not every converter call has an explicit timeout, and image subprocess buffers permit up to 256 MiB. Use isolated ingestion with resource caps and maintained converters, not a trusted-workstation blanket import. [9]
- **Viewer is local-only, not authenticated hosting:** `serveRun` binds 127.0.0.1; there is no application authentication or Origin/Host gate in the inspected server. It does not add permissive CORS headers. Page text is escaped and embedded JSON escapes less-than signs. Keep it loopback-only; a reverse proxy/tunnel requires its own access controls. Custom domain JS is trusted, not sandboxed. [7]

## Evidence, Tests and Maturity

Public metadata retrieved 2026-10-30: repository created October 25; last push October 30 05:12:52 UTC; 282 stars, 21 forks, three open items (all pull requests). Latest listed release is v0.1.1, published October 29. Popularity is an adoption signal, not operational evidence. [11,12]

The repository has meaningful tests for loop state/trace ordering, answer fitting, choice metadata, replay, CLI behavior, model adapters and viewer/example behavior. Root Vitest config sets 85% thresholds for lines, functions, branches and statements, with exclusions. CI on Ubuntu 24.04/Node 22 installs ingestion utilities and schedules format/lint/typecheck/tests/coverage/build plus workspace checks. Actions use version tags, not immutable SHA pins. Publishing is configured for npm OIDC and provenance; this review did not verify an npm tarball or its attestation. [10]

**Observed CI is not a passing proof for this revision.** A revision-filtered Actions query returned no runs for the reviewed SHA. The latest main-branch run returned by GitHub was for `86b39a64ede7039a1ef6de74a6e22512c0b171fd` and failed at `pnpm format`; later test/build steps were skipped. This proves a formatting gate failure on that other commit, not failing functional tests at the reviewed SHA. Also, Stryker still names absent `src/core/choices.ts` rather than current `pick.ts`: configuration drift, not verified mutation coverage. [10,13]

The author's first legal-judge report claims 94.6–95.0% agreement on 1,288 rubric items from 100 saved answers and roughly 0.29-second median calls. It explicitly uses a private, previously seen dataset rather than held-out tasks; raw cases/labels were not available for independent reproduction. Its approximately $0.13 cost is an estimate using another provider's listed rate, not a verified billed total. Later meets-and-misses experiments report 94.6% labeled accuracy and 84.1% agreement with another model; model agreement is not human ground truth. These are historical author experiments, not a fresh benchmark of this SHA. [8]

The rubric combiner `min(P(meets), 1-P(misses))` implements a useful two-check threshold rule, but numerically it is an upper bound on the conjunction probability without a joint model. Do not treat that value as a calibrated pass probability. Require held-out human labels, false-pass analysis and baseline comparisons before using it for consequential evaluation. [8,9]

## Comparison

| Option | Best fit | Tradeoff relative to Switch |
|---|---|---|
| Direct pi-ai/classifier calls | One routing/classification decision | Less machinery; you write multi-step control, trace and replay yourself |
| LangGraph | Explicit graph orchestration, persistence and human interrupts | Broader workflow abstraction; does not itself supply Switch's finite-choice domain design |
| Pydantic AI / Pi-style agents | Open-ended generated text and tool use | More expressive actions; a different boundary from selecting only code-generated options |
| Inspect AI | Evaluation suites, datasets, scoring and sandboxed agent evaluation | Broader evaluation infrastructure; Switch's judge can be a specialized component rather than a replacement |

Related public reviews: [Laya](laya.md), [Pydantic AI](pydantic-ai.md), [Inspect AI](inspect-ai.md), and [typed TypeSafe integration](langchain-typesafe.md). Local classifier serving is a separate operational decision from choosing this harness.

## Practical Use / Self-Hosting Notes

Start with a narrow, read-only domain and the exported fake decider; build deterministic transitions and small synthetic cases before connecting a provider. Define a finite step limit, bounded view and externally enforced cost/time budget. Test one remaining option, over-64-question workloads, oversized images and real provider overflow responses. Pin both the package and model revision where possible; `jev-latest` is not a stable benchmark identity.

Node >=22.18 and ESM are required. The npm package excludes the example/viewer workspaces; those are source-checkout components. PDF/legacy Word/image ingestion needs extra system programs, and Stockfish is optional for chess. The inspected CI covers Linux, not a cross-platform matrix: do not infer turnkey Windows/macOS parity from TypeScript alone. Wikipedia races depend on current network content and HTML structure. No database/server fleet is required for the basic library, and no deployment was attempted here.

**Adoption gate:** prove your domain's accuracy on unseen cases; exercise provider limits; isolate document conversion; review every offered side effect; secure traces; establish retry and failure handling. Until then, use Switch as an experimental harness and architecture reference, not an unattended legal judge.

## Sources and Verification Record

Source-file links below are pinned to the reviewed commit; metadata and PR/CI links are live snapshots.

1. [README and identity](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/README.md)
2. [Core loop](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/src/core/loop.ts)
3. [Choice construction](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/src/core/pick.ts)
4. [Replay](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/src/core/replay.ts)
5. [pi-ai adapter](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/src/models/pi-ai.ts)
6. [Request recording](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/src/core/record.ts)
7. [Viewer server](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/viewer/src/server.ts)
8. [First legal-judge report](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/docs/2026-10-25-first-legal-judge-run.md)
9. [Rubric judge](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/examples/rubric-judge/README.md)
10. [CI](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/.github/workflows/ci.yml)
11. [Public metadata](https://api.github.com/repos/osolmaz/switch) and [v0.1.1 release](https://github.com/osolmaz/switch/releases/tag/v0.1.1).
12. Open compatibility PRs: [#40](https://github.com/osolmaz/switch/pull/40), [#41](https://github.com/osolmaz/switch/pull/41), [#42](https://github.com/osolmaz/switch/pull/42).
13. [Observed failed main CI run](https://github.com/osolmaz/switch/actions/runs/41007106584); [Stryker config](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/stryker.conf.json).
14. Additional inspected evidence: [tests](https://github.com/osolmaz/switch/tree/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/tests), [package manifest](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/package.json), [license](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/LICENSE), [meets-and-misses report](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/docs/2026-10-26-meets-and-misses.md), [converter implementation](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/examples/rubric-judge/src/ingest/tools.ts), [definition hashing](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/src/core/definition.ts), [HTML escaping](https://github.com/osolmaz/switch/blob/7c5b6b9bae55e9e7cda3efe310f585187eb7c717/viewer/src/page.ts).

**Verification limits:** No functional execution, dependency installation/audit, live classifier comparison, cross-platform test, hostile-document fuzzing or browser interaction was performed. Static findings are not a comprehensive security audit.

---

**Attribution:** Onur Solmaz / [osolmaz/switch](https://github.com/osolmaz/switch), MIT. Analysis only; no source-code extraction.
