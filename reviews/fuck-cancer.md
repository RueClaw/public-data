# Fuck Cancer (petergyang/fuck-cancer)

**Repo:** https://github.com/petergyang/fuck-cancer
**Author:** Peter Yang
**License:** MIT; preserve copyright and permission notices when reusing substantial source material. Provider and installer terms are separate.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** ecaef1a3fa5bbee50798942011db508ccdffd5f0, main; all tracked text files. Source commit: 2026-11-02.
**Verification:** Static workflow/code review plus 24/24 bundled offline synthetic unit tests passed in a secret-free, network-isolated, read-only source sandbox. No installation, live trial searches, model calls, Google integration, or patient-data processing.
**Stack:** Markdown agent skill; Python standard-library ClinicalTrials.gov helper; Codex metadata; GitHub Actions.
**What it is:** A caregiver/patient care-navigation brief workflow for an existing AI assistant, not a cancer-treatment engine, medical record system, or clinically validated decision-support product.

---

## Verdict

⚠️ **Interesting — thoughtful advocacy workflow, with unvalidated clinical behavior and substantial host-owned privacy responsibilities.** The small action list, explicit uncertainty, source hierarchy, and distinction between study and site recruitment are useful. Study or cautiously adapt it for human-reviewed appointment preparation; do not mistake the prompt checklist or passing helper tests for evidence that generated medical guidance is safe or effective.

## What It Is

The [README](https://github.com/petergyang/fuck-cancer/blob/ecaef1a3fa5bbee50798942011db508ccdffd5f0/README.md) and [actual skill](https://github.com/petergyang/fuck-cancer/blob/ecaef1a3fa5bbee50798942011db508ccdffd5f0/skills/fuck-cancer/SKILL.md) describe one living family brief: identifying/contact information, up to three next actions, confirmed/uncertain facts, optional medical definitions, and a compact care log. A tabbed document separates the current Overview from historical Log. The host agent reads supplied reports and the existing brief, researches a current question, edits the document, then reads back the saved result.

Google Docs through an already-connected host integration is the default. Local Markdown is available on request or when Google cannot be connected; otherwise the brief can remain in chat. There is no bundled Google connector, OCR implementation, model runtime, database, or patient portal. “Works with your favorite agent” is an interoperability intention, not demonstrated parity across platforms.

The README's family experience and caregiver quotations motivate the problem; they are anecdotes, not outcome evidence. This review does not reproduce patient records, identifiers, screenshots, or sensitive family details. The bundled example image and external personal narrative/video were not clinically evaluated.

## Architecture and implementation

| Layer | Implementation and boundary |
|---|---|
| Workflow | SKILL.md supplies instructions; enforcement depends on the host/model |
| Medical research | Host browsing of official agencies, regulators, guidance and selected primary research |
| Trial retrieval | Python urllib GET requests to ClinicalTrials.gov API v2 |
| Ranking | Deterministic token-overlap weights, phase/status/recency preferences; no clinical eligibility model |
| Persistence | Host Google Docs/Drive tools, ordinary local Markdown, or chat |
| Checks | Manual self-check in eval.md; synthetic Python unit tests; CI compile/test matrix |

The [491-line helper](https://github.com/petergyang/fuck-cancer/blob/ecaef1a3fa5bbee50798942011db508ccdffd5f0/skills/fuck-cancer/scripts/search_trials.py) normalizes selected country/state aliases, fetches at most five pages of 1,000 study records, filters matching sites, calculates great-circle distance, ranks candidates and returns JSON. It preserves study update dates, obtains the API data timestamp, flags pagination truncation, and labels eligibility previews truncated after 2,000 characters. Full criteria require an explicit flag. It defaults to ten returned records; the skill separately asks the model to present only three to five candidates.

Important implementation qualifications:

- **“Open” does not mean accepting volunteers now.** The accepted statuses include NOT_YET_RECRUITING and ENROLLING_BY_INVITATION, with explanatory status notes. A missing site status falls back to the overall study status and is honestly labeled “not listed”; that is not confirmation that the site recruits.
- **Ranking is lexical, not medical.** It rewards query words even when they occur in exclusion criteria; it does not reason about negation, stage compatibility, prior-treatment requirements, age/sex eligibility, organ function, or competing risks. Age/sex fields are reported, not matched to a patient.
- **Treatment bias is explicit.** Phase III and treatment intervention types gain points; supportive-care words lose points. This may be useful for a treatment-focused query but can suppress precisely the quality-of-life studies a caregiver needs. Trial phase is not proof of personal benefit.
- **Preview affects ranking.** Ranking reads the extracted, potentially truncated eligibility text. Changing to full criteria can change ordering, not just display detail.
- **Geography trades recall for locality.** Missing geoPoints are excluded when proximity filtering is active. Exact city/state/country matching and a page cap can miss candidates. Great-circle distance is not road distance, cross-border feasibility, or travel burden.
- **Resilience is modest.** Requests have 30-second timeouts and three attempts for 429/server/network errors, with exponential delays but no Retry-After handling. Failure of the final version request fails the whole search. There is no response-size cap or strict returned-record schema validation.

## Medical claims and evidence

No disease-specific therapeutic efficacy claim, experimental intervention protocol, survival analysis, or clinical evaluation of this skill is supplied in the reviewed text. It would be misleading to manufacture a treatment literature review from the repository title.

| Evidence category | What this repository actually establishes |
|---|---|
| Anecdotes | Motivation and user needs; not causal evidence of improved outcomes |
| Research hypotheses / preclinical findings | May be encountered during later agent research; none establishes this tool's clinical utility. Cell/animal results must not be promoted to human efficacy |
| Clinical research | A trial registration identifies research, not a positive result, regulatory approval, or patient eligibility |
| Validated care | Current indication-specific evidence, local regulation/guidance and the treating team's judgment remain external to the skill |
| Software evidence | Unit tests support helper mechanics, not triage accuracy, hallucination rate, patient comprehension or clinical benefit |

Selected authoritative first-party references checked on 2026-11-14:

1. [NCI PDQ overview](https://www.cancer.gov/publications/pdq) describes evidence-based summaries intended to inform and educate and support clinician–patient decisions. This supports using PDQ as evidence context, not pretending the skill is a clinical guideline. The source skill explicitly makes that distinction.
2. [NCI: What Are Clinical Trials?](https://www.cancer.gov/research/participate/clinical-trials/what-are-clinical-trials) defines trials as research testing approaches in people and explicitly includes supportive/palliative-care studies. That supports both the research-versus-established-care distinction and the warning about this helper's supportive-care ranking penalty.
3. ClinicalTrials.gov's disclaimer and study-basics pages returned only a client-rendered shell in this retrieval. Their substantive text was **not independently verified**; no live API study query was performed. Implementation/API compatibility is therefore supported by inspected code and mocked tests, not a current end-to-end registry probe.

These are primary agency references for the narrow claims evaluated, not clinical trials validating the repository. No model-based clinical benchmark, prospective study, independent oncology review, regulator clearance, or clinical safety case was found in the tracked materials.

## Clinical safety and human oversight

Good instructions prohibit diagnosis from incomplete material, treatment selection, eligibility declarations, unauthorized medical disclosure, and delaying urgent evaluation or standard care. They favor newest records, distinguish pending from unknown, make missing tests respectful questions, and require permission before contacting clinicians/trials or editing shared records. Sources must be linked inline; early or indirect evidence must be labeled.

These are **prompt-level safeguards**, not runtime authorization or clinical controls. The skill also routes every cancer-related conversation into the workflow and offers emergency/today/next-appointment symptom triage without a validated triage protocol or tested escalation cases. A host must not let this become an autonomous triage service. Report extraction, chronology, units, biomarker interpretation, citations and next steps require human checking against original documents; treatment and eligibility questions belong with qualified clinicians and trial staff.

The instruction to omit a research date and disclaimer from the brief keeps it concise but weakens freshness/role visibility when it is shared outside chat. Preserve an explicit reviewed/as-of date and clear AI-draft status in a deployment's surrounding workflow. The generated brief should supplement, never replace, original records and the clinical team’s plan. This review supplies no personalized treatment advice.

## Privacy and health-data handling

**Local Markdown output is not local inference.** The README's “no account, database, or API key” statement for local mode concerns the brief/helper, not necessarily the chosen assistant. Uploaded reports and the full brief may pass through the host's model provider, OCR tools, chat history, tracing, or other enabled integrations. This repository does not specify their retention, training use, region, subprocessors, deletion guarantees, or contractual health-data protections.

| Data path | Observed behavior / responsibility |
|---|---|
| Input reports and conversations | Host receives sensitive content; no repository redactor or minimization filter |
| Brief contents | Skill explicitly permits names, care contacts and medical/insurance identifiers in authorized chat/documents |
| Google Docs default | Host integration supplies credentials and sharing permissions; no repository OAuth scope checks or share-link policy |
| Web/trial search | Prompt forbids names/care identifiers, but no helper validation enforces that rule |
| Trial GET URL | Sends condition, terms, location and optional precise coordinates to ClinicalTrials.gov; clinical/location combinations remain sensitive even without names |
| Helper output | JSON includes search terms and coordinates; stdout may enter agent logs; --output persists an ordinary file |
| Deletion/export | Markdown/JSON are directly portable; Google export/deletion belongs to that service. No unified export, retention limit, purge, or deletion receipt exists |

No embedded API key or credential-loading mechanism was found in the helper. It requires no API key and has no telemetry SDK. This does **not** establish zero transmission: public registry requests are intentional, while host/model and Google egress are separate. Shell arguments, errors, logs, provider histories, backups, document versions and shared copies can retain data after deleting a local brief. The .gitignore ignores Python bytecode only—not medical briefs—so using a tracked workspace risks accidental commits.

Before real use, explicitly choose destination and audience, minimize identifiers, use coarse locality rather than a home point where sufficient, review provider terms and retention settings, scope connector access, require approval for sharing and external edits, and keep medical artifacts out of source control. No HIPAA/GDPR compliance claim can be derived from the MIT license or these prompt rules.

## Execution, permissions and operational costs

The helper opens outbound HTTPS to a fixed API root and writes only when --output is requested. It has no server, listening port, shell/subprocess execution, privileged install step, or auth/CORS surface. However, urllib follows redirects with its default behavior; this is not an enforced egress allowlist. Output paths are caller-controlled: parent directories are created and an existing file can be overwritten without a confirmation or restrictive file-mode policy.

The encompassing agent may have broad filesystem, browser and connected-account authority. The skill supplies no sandbox, tool allowlist, permission broker, document revision lock, transactional edit, or prompt-injection defense for uploaded reports and retrieved pages. Explicit permission in prose must be reinforced by host tools. Readback checks are useful but emphasize list formatting rather than independent medical fact verification.

There is no service to self-host. README installation delegates to a globally installed skill via an external npx skills installer or a natural-language install request. Neither is revision-pinned in the instructions; global scope increases behavioral reach. This review installed nothing. The helper uses Python standard library only and declares Python 3.8+ in documentation; CI covers 3.9 and 3.13, so the advertised minimum was not verified here. Host model/agent subscriptions, token use, OCR/search connectors and Google storage may have costs; there is no spending meter or budget cap. No paid calls were made.

## Tests, maturity and limits

All **24 bundled unittest cases passed** against synthetic fixtures in a network-isolated sandbox with no home directory or credentials mounted. They cover location aliases, site status fallback, extraction, criteria previews, ranking examples, pagination and geography. This is stronger than a prompt-only repository, but not a clinical safety evaluation. The [eval checklist](https://github.com/petergyang/fuck-cancer/blob/ecaef1a3fa5bbee50798942011db508ccdffd5f0/skills/fuck-cancer/eval.md) is a manual yes/no self-check, not a scored dataset or independent evaluator.

[CI configuration](https://github.com/petergyang/fuck-cancer/blob/ecaef1a3fa5bbee50798942011db508ccdffd5f0/.github/workflows/ci.yml) compiles skills and runs unit tests on Python 3.9/3.13. GitHub reported [run 41534095351](https://github.com/petergyang/fuck-cancer/actions/runs/41534095351) successful for this exact SHA. Action references use major-version tags rather than immutable SHAs. No lockfile/package manifest is needed for the stdlib helper; the external installation and host-agent supply chain remain out of scope.

Public GitHub metadata at retrieval: created 2026-08-22; last push 2026-11-02; 295 stars, 29 forks, zero open issues reported; releases endpoint returned none. These are activity snapshots, not endorsements or evidence of safety. Shallow acquisition did not audit full Git history. No live API availability, Google document round trip, supported-host compatibility, Python 3.8 behavior, provider privacy policy, or diagnostic/triage performance was validated.

## Alternatives and operational fit

- **A manually maintained private brief plus original reports:** less automation, fewer model/provider exposures and no generated-medical-summary risk; still requires disciplined access control and factual updates.
- **NCI PDQ and the patient's official cancer agency:** stronger direct evidence context, but not a personalized record-maintenance tool. Use their material with the care team rather than treating an LLM synthesis as authoritative.
- **ClinicalTrials.gov directly plus a trial navigator/oncology team:** avoids this helper's custom ranking bias; more manual work and still requires current site and eligibility confirmation.
- **An existing clinical portal or institution-approved care-navigation system:** preferable for official records, access governance and accountable care; evaluate actual policies rather than assuming all portals solve every privacy concern.

The reusable idea is a small, uncertainty-aware action brief with one source of truth—not an autonomous cancer advisor. Adoption should begin with synthetic examples and clinician/human review, not identifiable uploads to an unexamined agent stack.

---

**Attribution:** Peter Yang / petergyang/fuck-cancer, MIT. Independent analysis; no patient records or source screenshot reproduced. [Source tree at reviewed revision](https://github.com/petergyang/fuck-cancer/tree/ecaef1a3fa5bbee50798942011db508ccdffd5f0).
