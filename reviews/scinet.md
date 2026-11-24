# SciNet (lukasalthoff/scinet)

**Repo:** https://github.com/lukasalthoff/scinet
**License:** CC BY 4.0 for data and documentation; reuse, including commercial adaptation, requires attribution, a license link and indication of changes.
**Reviewed:** 2026-11-24 (UTC)
**Revision:** 69973ad2cf21a34298b1f7f600f2c3820989113e (main; commit dated 2026-10-29). README calls this v1.10.0; GitHub returned no tags or releases.
**Scope:** Complete tracked file manifest; README, LICENSE, METHODOLOGY, TASK_DIMENSIONS, TIME_USE, WORK_ACTIVITIES, SURVEYS, data dictionary and figures documentation. Dataset payloads, figures/PDFs and external website implementation were not acquired or tested.
**Verification:** Static documentation/manifest review only. No source execution, installations, dataset/model downloads, paid calls or accounts. Counts and evaluation statistics below are author-reported, not independently recomputed.
**Stack:** UTF-8 CSV, gzip CSV, JSON constants, Markdown, PNG and TeX/PDF; no application stack shipped.
**What it is:** An O*NET-inspired database of scientific research tasks and model-derived estimates, intended for science-of-science research and analysis of AI's possible effects on scientific work—not an autonomous scientist or research-agent framework.

---

## Verdict

📚 **Study: a useful research taxonomy, not a measured AI-capability benchmark.** The unusually explicit methodology and portable exports make SciNet worth exploring for task classification and hypothesis generation. Its AI rankings are model judgments rather than task executions, most time-use inputs are synthetic, and the public release cannot reproduce the upstream generation or several published figures. Do not turn these estimates directly into staffing decisions, productivity forecasts or probabilities of automation.

## What It Is

The release describes 7,262 tasks across 6 domains, 34 fields and 318 subfields: 30 universal, 134 domain, 321 field and 6,777 subfield tasks. It reports 90,583 task substeps and groups specialized work into 140 work activities. The hierarchy includes the humanities, formal theory and design—not just laboratory science. Task metadata describe importance, frequency, prevalence in papers, time, cognitive and physical requirements, and AI-training feasibility. [1][2][5]

The core product is a set of published tables. A separate website offers exploration and a researcher survey, but this repository does not ship that site's application code. The survey document lists questions, not a survey-response dataset or evidence of causal productivity effects. The README credits Cristian Alamos and Lukas Althoff and cites their dataset and Althoff's working paper; it directs readers elsewhere for the paper when available. [1][7]

## Stack

| Layer | What is actually present |
|---|---|
| Data interchange | CSV, two gzip CSV files, JSON PCA constants |
| Documentation | Markdown methods, dictionaries and survey questions |
| Presentation | Pre-rendered PNG figures; TeX and PDF time-use slides |
| Backend / frontend / database server | None in the reviewed tracked tree |
| Build / dependencies / CI | No package manifest, lockfile, application entry point, test suite or GitHub Actions workflow in that tree |
| Authentication | No application login or authorization implementation shipped |

The absence of runnable code is a scope fact, not a missing feature of a dataset. GitHub's dominant-language label of TeX is not evidence that this is a TeX application. [8]

## Key Features

### A structured, reusable scientific-work vocabulary

The taxonomy proceeds from universal work down to subfield-specific actions, drawing on O*NET task-statement conventions. Paper-based expansion added a reported 2,223 tasks; expert feedback corrected parts of the taxonomy. The work-activity layer groups similar steps/tools/skills across subject areas, making it more useful for cross-disciplinary comparisons than a simple keyword list. Model generation and expert intervention are described, but should not be mistaken for representative expert validation of every row. [2][5]

### Explicit time-use components rather than one opaque score

Paper-task hours multiply time per instance, instances per paper and papers per researcher-year; general tasks multiply time per instance and annual frequency. Released columns expose overlap adjustments, retiming and caps. Apart from publication/author counts, the documentation says every component is a language-model judgment. Team time is allocated among authors even though staff may do part of the work, and general-task assumptions describe people who teach and supervise whereas publication statistics include students. Those population and measurement mismatches limit literal interpretation of the reported 1,740-hour median annual total. [4]

### AI dimensions with important distinctions

The RL feasibility index is a standardized first principal component of verification, simulability and feedback density. It uses three of an earlier index's eight dimensions and does not zero out physically gated tasks. It is neither observed AI usage nor measured productivity. Its author-reported 79.2% explained variance establishes covariance among the synthetic scores, not predictive validity for training an AI. [3]

The Elo score is even easier to overread: Claude Haiku 5.5, as named in the source, compares which task Claude Opus 5 would more likely complete. A Bradley–Terry model adjusts for first-card advantage. The scenario assumes a human supplies access/data and performs physical actions as specified; it is not end-to-end robot autonomy. The authors explicitly say no one ran Opus 5 on the tasks. Model names are reproduced as source descriptions, not independently verified provider identifiers or available API versions. [3]

## Architecture and Data Integration

The documented upstream flow is taxonomy generation → task generation and paper expansion → per-subfield ratings → step decomposition/timing → task dimensions → activity aggregation and time-weighted subfield summaries. That is a described research pipeline, not executable orchestration available in this repository. Selected prompts are published, but the full generators, input corpora, comparison records and execution environment are absent. [2–6][8]

Practical integration requires care:

- Join tasks using statement, level, domain, field and subfield—not statement alone. The dictionary reports 235 statements occurring in multiple subfields, and two subfield names reused in different fields.
- Universal timing rows are per field, while annual-hours rows expand to subfields; blindly joining them can duplicate or lose observations.
- Work-activity assignments collapse repeated statements to statement-plus-level units. Their 6,956 documented rows are not interchangeable with the 7,262 task rows.
- Preserve Namibia's country code NA as text; common CSV readers otherwise treat it as missing.
- Missingness is meaningful. Forty-three substeps in four universal task/field pairs lack dimension scores, and one task lacks an Elo rating. The data README's broad statement about the only empty scores is less complete than TASK_DIMENSIONS' detailed exceptions; consumers should follow the latter and validate explicitly.
- Do not interpret citation-weighted higher-level prevalence as simply n_involved/n_papers. Do not rely on row position across releases even though same-order dimension files are documented. [1][3][6]

## Research Claims and Evidence

| Claim / measure | Evidence reported by the authors | What it does and does not establish |
|---|---|---|
| Ratings approximate O*NET | 425 tasks / 40 occupations; correlations 0.66 importance, 0.63 relevance, 0.75 frequency | Prompts were anchored/tuned on the same benchmark; not independent out-of-sample validation. |
| Timing resembles protocols | 769 exact matches covering 383 SciNet steps; elapsed-time correlation 0.53 | Narrow wet-lab evidence, not validation of all disciplines, annual hours or hands-on team effort. Matching itself uses a model. |
| Paper support for tasks | About 100 papers/subfield; check of 179 quotes from 52 papers found none invented | A small quote audit is not a broad task-label accuracy audit. English, open-access, cited journal articles from 2000–2020 are a selected frame. |
| Elo judgments are consistent | 95,040 comparisons; split-half correlation 0.87; 72% agreement under order reversal; first card wins 59.5%; stronger-model agreement 70% | Reliability and cross-model agreement are not actual task-success accuracy. Median SE of 106 Elo points limits fine ordering. |
| Researcher counts describe scientific activity | Sample of 746,517 of 10.84 million qualifying OpenAlex author profiles; Haiku/Sonnet subfield agreement 74% | Model-on-model agreement, author disambiguation and single-subfield assignment add uncertainty excluded from sampling SEs. Active-in-2020 publishing authors are not current employed-researcher headcounts. |

All figures in this table are source-reported. [1–3]

Further methodological cautions matter. Paper prevalence misses work rarely narrated in papers; grant writing appears in only 37% of papers acknowledging funding under the reported judgment procedure. Expansion candidates were selected using the same paper pool on which scoring took place. The released prevalence excludes proposing papers, which helps, but does not remove the entire selection process; the documented fresh-sample comparison is a one-off, not a comprehensive external holdout. Timing coverage repairs use different models and calibration factors estimated on small overlap samples. [1][2]

The repository discloses support from Stanford Impact Labs and Anthropic. That is relevant context when interpreting Claude-centered capability estimates, not evidence that the findings are invalid. Independent execution benchmarks, representative researcher time diaries and field-specific expert holdouts would be stronger next tests. [1]

## Permissions, Privacy, Egress and Cost

Reading already acquired CSV/JSON locally needs no API credential, model service or account. There is no executable service in this release to exercise network access, shell permissions, CORS or tenant isolation. No runtime telemetry path is implemented in the reviewed tree. This does not audit the separately hosted website. GitHub access itself is network activity. [8]

Recreating the documented research would involve external providers: Claude for generation/judging and OpenAlex, protocols.io and other scholarly sources for inputs. Actual provider credentials, billing, quotas, retries and budgets are not implemented or fully specified here; there is no substantiated dollar cost for regeneration. Reading public exports is not the same as paying to reproduce them. Do not send unpublished research or identifiable survey responses to those services without separate consent and terms review. [1][2][7]

The researcher table is documented as aggregated country/discipline counts, not individual profiles, and task records can contain public expert attribution. Survey questions ask about AI spending, productivity, skills and work practices; the repository gives no basis to verify the website's respondent authentication, retention, deletion, storage security or provider data handling. No survey was submitted and no private information was accessed. [1][7]

## Persistence, Recovery and Export

Persistence is the release itself: plain files versioned in Git. Export is straightforward CSV/JSON rather than a proprietary database, and gzip is a normal transport format. Pin the exact Git commit, preserve schema and license, and retain a local immutable copy when doing later authorized analysis. There are no service migrations, job queues, checkpoints or recovery commands to evaluate. A file snapshot can be restored; the full scientific pipeline cannot be reconstructed from this release alone. [6][8]

The figures documentation expressly says the generator and some inputs live outside this release. Researcher counts likewise require the full OpenAlex snapshot and cannot be rebuilt from the repository alone. PCA constants make the index more transparent, but do not make the upstream synthetic measurements independently reproducible. [1][3][9]

## Maturity, Licensing and Supply Chain

Anonymous GitHub API access confirmed a public repository. At review time it showed 42 stars, 7 forks and a last push of 2026-10-29. Its one open issues-endpoint item was actually a pull request, not a confirmed outstanding bug. These are activity observations, not quality assurance. The README and commit label v1.10.0 are not a published immutable release tag: both tags and releases endpoints returned empty arrays. Pin the SHA. [10]

The actual LICENSE declares CC BY 4.0 and credits Cristian Alamos, Lukas Althoff and contributors. GitHub's generic “Other” license classification does not override that text. Attribute the dataset, link the license and identify modifications when adapting it. The license is not a warranty of the derived statistics and does not automatically settle rights to separately obtained papers, provider outputs or external website material. [11]

No dependencies or install scripts ship here, so there is no software dependency chain to install or audit. There is also no shipped automated schema-validation suite or CI gate. The primary risks are provenance, statistical validity, schema drift and consuming unvalidated tabular content. When future data acquisition is authorized, check uniqueness, foreign-key coverage, missingness, finite/range constraints, annual-hours products and aggregation totals before use. Spreadsheet consumers should treat imported cells as text where appropriate. None of those dataset tests were run for this review. [8]

## Comparison

| Need | SciNet | Alternative / tradeoff |
|---|---|---|
| Fine-grained research tasks | Broad scientific hierarchy and synthetic estimates | O*NET offers established occupational task/worker measures but is organized around occupations, not 318 research subfields. |
| Literature and researcher metadata | Released mapped summaries, not a full bibliography | OpenAlex is the underlying research catalog; use it for works/authors/institutions rather than inferred work-time estimates. |
| Actual time use or automation outcomes | Hypothesis-generating model judgments | Field-specific time diaries and controlled task-execution studies are more expensive but measure the target behavior directly. No ready-made substitute was validated here. |

The O*NET database page and OpenAlex documentation were checked as public descriptions; no alternative was installed, benchmarked or downloaded. [12][13]

## Self-Hosting Notes

There is nothing to deploy as a service from this repository. A later authorized analysis can consume the pinned tables with an existing CSV-capable tool; pandas is mentioned in the source but is not a repository dependency. The external website cannot be self-hosted from this tree. Start with a small field-specific validity study and explicit missing-value/join checks rather than turning the Elo or RL index into an automation recommendation. [1][6][8]

## Verification and Limitations

- Confirmed anonymous repository metadata, exact commit, tracked tree, documented license and absence of application/test/CI artifacts; checked release/tag and open-item metadata.
- Read all principal methodological and schema documents listed in Scope. Cross-checked documentation for missing-score and join caveats.
- Used a text-only sparse checkout; did not fetch the dataset payloads, images, PDF, models or external corpora. No CSV row counts, formulas, statistical significance or research results were independently verified.
- No source code, LaTeX, prompts, provider calls or website survey was executed. No security certification, live-site privacy assessment or independent capability benchmark is implied.
- This is a new canonical-source review; no prior matching review/index entry was found. Metadata is a 2026-11-24 snapshot.

## Sources

Repository citations are pinned to the reviewed revision.

1. [README: purpose, dictionary, researcher estimates, citation and funding](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/README.md)
2. [Methodology: generation, sampling, calibration and validation](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/METHODOLOGY.md)
3. [Task dimensions: PCA, missingness and Elo evaluation](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/TASK_DIMENSIONS.md)
4. [Time-use formulas and limits](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/TIME_USE.md)
5. [Work activities and aggregation prompts](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/WORK_ACTIVITIES.md)
6. [Data dictionary and join conventions](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/data/README.md)
7. [Survey questionnaire](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/SURVEYS.md)
8. [Complete revision tree](https://github.com/lukasalthoff/scinet/tree/69973ad2cf21a34298b1f7f600f2c3820989113e)
9. [Figure provenance and reproduction limits](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/figures/README.md)
10. [Public metadata](https://api.github.com/repos/lukasalthoff/scinet), [releases](https://api.github.com/repos/lukasalthoff/scinet/releases), [tags](https://api.github.com/repos/lukasalthoff/scinet/tags), [open PR](https://github.com/lukasalthoff/scinet/pull/1) (observed 2026-11-24).
11. [Repository license](https://github.com/lukasalthoff/scinet/blob/69973ad2cf21a34298b1f7f600f2c3820989113e/LICENSE); [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
12. [O*NET database](https://www.onetcenter.org/database.html).
13. [OpenAlex documentation](https://docs.openalex.org/).

---

**Attribution:** Cristian Alamos, Lukas Althoff and contributors, SciNet; data/documentation CC BY 4.0. This review is independent analysis, not an endorsement by the authors.
