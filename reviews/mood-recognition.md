# Mood recognition (Libraries.dev)

**Source:** https://libraries.dev/mood-recognition
**Author:** Jakub Antalik / Libraries.dev
**Date:** Page publication/update date not stated. Model License records initial publication as Adaptive UI on 2026-11-24; this is not a verified page publication date.
**Reviewed:** 2026-11-26 (UTC)
**Retrieved:** 2026-11-26 UTC, anonymous HTTP 200; canonical link matches the submitted URL. SHA-256 of retrieved raw HTML response body: c7b3648bba6fdb79074318222983a30b9b2cbfe71dc7b0a574d095117019dda0.
**Revision:** Supporting public repository Jakubantalik/Libraries.dev at d058179b10adf2a2290957c4662b9c0ada1de98b (2026-11-26). Scope: README, Model License, site HTML, public mood documentation, showcase TSX, site manifest and deployment workflow. Deployed page independently hashed; not assumed identical to repository source.
**Verification:** Static public-document/source inspection only. No model/kit download, account, installation, source execution, device access, upload or live inference. Accuracy and runtime privacy not independently tested.
**Topic:** Browser interaction-friction detection and adaptive React interfaces.
**License:** Libraries.dev Model License v1.6, effective 2026-11-26; not MIT for current model/kit downloads.

---

## Verdict

⚠️ **Interesting friction detector, not validated mind reading.** The small local-model design and explicit failure cases merit study for optional, reversible help. Public evidence does not establish reliable inference of internal mood, and the actual model and feature collector are account-gated. Prefer fixing known UI obstacles before adding behavioral inference; do not use these labels for consequential decisions about people.

## Summary

Despite the name, this is not a facial-expression, voice-emotion or text-sentiment service. It maps pointer movement, clicks, scrolling, typing-event patterns and element states to labels such as frustrated, confused and lost. These are hypotheses about interaction friction, not observations of subjective emotional state. Even observable expressions or text sentiment would not by themselves establish internal mood; this product does not claim to consume those modalities. [1, 2]

The documented product comprises a 142 KB JSON gradient-boosted-tree model (32 KB gzipped), version 0.4 beta, plus a TypeScript React kit version 0.5. Both require a free account to download; neither is an npm package. The public repository contains the promotional site and documentation, not the currently distributed model or kit. Other libraries in that monorepo being MIT does not make this product MIT. [2, 3, 5]

The intended intervention is modest: reveal a format hint, emphasize a prerequisite or offer help when a flow appears difficult. Documentation explicitly advises against punishment, blocking, moving controls under the pointer or using it as analytics. Those boundaries are a strength, but integrating applications can still misuse or export outputs. [2]

The checkout showcase is a scripted illustration, not measurement of its visitor. Its source defines a fixed 15.8-second loop, simulated pointer route and hard-coded BEATS containing scores and labels. It demonstrates the design concept, not empirical classification accuracy. [4]

## Architecture and public implementation

| Layer | Documented design / verified boundary |
|---|---|
| Input | 43 behavioral measures; mostly 8-second windows with some 15/30/60-second history |
| Model | 360 flat-array gradient-boosted trees; classes none, blocked, lost, confused, waiting, frustrated |
| Inference | Every 250 ms; public loader traverses thresholds, sums class contributions and applies softmax |
| Fast path | Rules for shaking, orbiting, repeated presses and disabled-control presses |
| UI response | Combined every 66 ms; starts at 0.30, full at 0.65; hold and easing suppress flicker |
| Integration | React 18+, MoodProvider/useMood; non-React createMoodReader; data-mood-ignore exclusions |
| Baseline | Learned personal pace in localStorage by default; baselineKey={null} requests memory-only storage |
| Site, not kit | React/TypeScript/Vite showcase; Cloudflare Pages deployment workflow |

The public loader and file-format description make inference understandable without an LLM: navigate each tree, accumulate leaf values and normalize class scores. But the feature extractor is described as the kit's features.ts, which was not anonymously available in the reviewed repository. Measurement correctness, event cleanup, keyboard/touch behavior, CPU cost and storage implementation remain unverified. Softmax values summing to one do not demonstrate calibration. The reaction score is a UI-control signal, not measured emotional intensity. [1, 2]

No model-specific reproducible training/evaluation harness or public raw study data was found in the inspected scope. The public workflow builds and deploys the site; that does not establish model validity, fairness or privacy. Repository metadata showed 5,166 stars, 305 forks, 24 open issues/PRs combined and last push 2026-11-26T16:28:00Z. Those describe the whole monorepo, not this beta. The three most recent GitHub releases inspected were unrelated library releases, not verification of the model artifacts. [6]

## Key claims and evidence quality

- **“Reads the user's mood.”** Inputs support detection of interaction patterns; no validated relationship to self-reported internal mood is supplied. A disabled-button press establishes a blocked interaction, not frustration. Stillness can mean reading or assistive input, not absence; circling can be exploration rather than confusion.
- **48 of 60 planted problems detected; 2.3% of calm time flagged (median person 1.5%).** Publisher-reported results on more than ten people, each scored by a model that had not seen them. Participant-held-out framing is better than training accuracy, but 48/60 is an 80% planted-event detection rate, not 80% mood accuracy. Calm-time and event denominators differ; precision cannot be derived. [1]
- **80 simulated people plus real sessions.** Simulated behaviors can encode the same assumptions used to label success. Public material omits exact participant count, demographics, recruitment, task durations, per-class confusion matrix, confidence intervals, calibration, threshold selection and an independent external test set. Participant separation alone does not rule out task-design overlap or tuning leakage. [1]
- **Known errors disclosed.** Searches shorter than roughly 20 seconds may miss the threshold; blocked checkout can be classified as lost; ordinary exploration may also be classified as lost. These directly constrain intervention. [1]
- **Local, no runtime network required.** Plausible for bundled JSON trees and consistent with the loader; not independently proven for the gated collector/kit or an integrating application's telemetry. [1, 2]

Generalization needs testing across keyboard-only and screen-reader users, motor differences, device sampling rates, touch/trackpad/mouse, layouts, cultures and tasks. Consecutive windows are correlated; many windows are not many independent people. A useful evaluation should measure task completion and unwanted interventions against explicit-rule and always-visible-help baselines, not just agreement with planted labels. No such comparative outcome study was found.

## Privacy, consent, retention and deletion

**Input boundary.** Documentation says positions, timings and facts such as disabled/invalid states, never text, field values or screen contents. Keystroke/delete and retry patterns are not semantic text analysis. No audio, video, camera, microphone, facial template or speaker identity input is described. This is behavioral processing; whether a deployment constitutes regulated biometric or sensitive profiling depends on purpose and jurisdiction, not its product name. No real person's mental state was assessed here. [1, 2]

**“Nothing recorded” needs qualification.** The page explicitly says personal pointer-speed/press baselines persist in localStorage by default. That is retained local data even if raw sessions are not recorded or transmitted. Memory-only configuration is documented, but no automatic baseline expiry, reset/deletion UI or verified storage teardown is shown. The 8–60-second windows describe feature history, not complete retention guarantees. Before deployment, verify storage keys/deletion, exclusions, listener removal, and whether retry detection derives any representation of values despite the no-field-values claim. These are audit questions, not findings of collection. [1, 2]

**Runtime and vendor website are separate.** Retrieved product HTML contains a GoatCounter page-view script and vendor account/download scripts. Privacy terms name Cloudflare hosting/request logs, Resend email, Stripe billing, and Anthropic for the separate Studio Agent. The latter sends prompts/parameters/recent conversation only when that feature is used; there is no evidence here that Mood recognition sends behavioral inputs to Anthropic. Script inclusion establishes potential requests, not an observed network trace. “No runtime network” does not mean the vendor website makes no network requests. [1, 7]

**Account-service retention.** Policy updated 2026-11-24: account/team data while the account exists, email records for 12 months, anonymized Studio Agent records for three months; access logs only “as long as needed.” It offers account deletion and access/objection requests, with billing-law exceptions. This does not establish deletion of an embedding application's mood baseline or explain consent/retention for real-session training participants. Training-session consent, recruitment and deletion procedures were not established from public material. [7]

**Consent and deployment responsibility.** No browser permission prompt for ordinary page events is not informed consent to profiling. Explain adaptive behavior, offer off/reset controls, prefer ephemeral local state, avoid sensitive fields and export, and retain a nonadaptive path. Do not silently log labels, use them for employment/education/credit decisions, or make mental-health claims. Reversible assistance is the only credible fit supported here.

## Licensing and operational fit

Model License v1.6 covers the model, current kit and page loader, including derivatives. Development, evaluation and qualifying noncommercial use are free; commercial release broadly includes client work and business use. Pro covers up to 10,000 monthly users per product, Business up to 50,000, and larger products need Enterprise or an applicable larger plan. Existing-plan exceptions and upgrade grace periods require reading the terms. Builds released under an active plan can remain available afterward, but new commercial releases/updates require an active qualifying plan. [5]

Distribution is permitted only within the using product, not standalone files, public repositories, registries or model hubs. Competitive training/distillation/evaluation restrictions apply. Earlier MIT kit copies, including React kit 0.4, retain original terms; the license says the model itself was never MIT. Do not transfer historical permission to newly downloaded kit 0.5. No code/model extraction was made here. A permissive monorepo badge is not sufficient diligence. [5]

Self-hosting means bundling a licensed model into your app, not operating an inference server. Acquire/audit exact artifacts only in a separately authorized evaluation. Require model/kit checksums, scoped privacy audit and device/accessibility testing before shipping. No paid plan or download was used here.

## Alternatives

| Approach | Advantage | Tradeoff |
|---|---|---|
| Native HTML constraint validation and explicit prerequisite hints | Deterministic known-invalid/blocked feedback; no mood inference or model subscription | Does not detect every exploratory difficulty; client validation still needs server checks [8] |
| Always-visible help and user-invoked “Need help?” | Users express need; explainable and accessible | Some users will not invoke it; usability testing still required |
| Consented task-based usability testing | Directly examines failures and asks participants about experience | Not continuous runtime adaptation; requires study effort |
| Mood recognition beta | Cross-signal local adaptive hints with easing | Gated implementation, limited generalization evidence, retained baseline and commercial restrictions |

Fix obvious validation/navigation problems first. If a beta trial is justified, compare opt-in assistance against these baselines using task outcomes and reported usefulness, without treating inferred labels as ground truth.

## Strengths and limitations

Strengths: compact interpretable inference format; local processing design; fast-rule/slow-window separation; smoothing; acknowledged failure modes; concrete integration boundaries.

Limitations: first-party promotional evidence, tiny described participant pool, simulated training assumptions, no reproduced evaluation, inaccessible current collector/model, unclear training-data governance and restrictive licensing. No source execution, accuracy/latency benchmark or dynamic egress audit was performed. Static artifacts support a cautious review, not a production endorsement.

## Sources

1. [Product page](https://libraries.dev/mood-recognition), including Install/format/privacy details in raw HTML.
2. [Public integration documentation](https://github.com/Jakubantalik/Libraries.dev/blob/d058179b10adf2a2290957c4662b9c0ada1de98b/sites/home/public/llms/mood-recognition.md).
3. [Repository README](https://github.com/Jakubantalik/Libraries.dev/blob/d058179b10adf2a2290957c4662b9c0ada1de98b/README.md).
4. [Scripted showcase](https://github.com/Jakubantalik/Libraries.dev/blob/d058179b10adf2a2290957c4662b9c0ada1de98b/sites/home/src/mood-recognition.tsx).
5. [Model License v1.6](https://github.com/Jakubantalik/Libraries.dev/blob/d058179b10adf2a2290957c4662b9c0ada1de98b/LICENSE-MODEL.md).
6. [Repository metadata](https://api.github.com/repos/Jakubantalik/Libraries.dev) and [releases](https://github.com/Jakubantalik/Libraries.dev/releases), retrieved 2026-11-26; popularity is not validation.
7. [Privacy policy](https://libraries.dev/privacy) and [pinned product-page source](https://github.com/Jakubantalik/Libraries.dev/blob/d058179b10adf2a2290957c4662b9c0ada1de98b/sites/home/mood-recognition.html).
8. [MDN: client-side form validation](https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Form_validation).

---

**Attribution:** Jakub Antalik / Libraries.dev. Model/kit terms are the Libraries.dev Model License, not general permission to redistribute the product. Independent analysis of public documentation.
