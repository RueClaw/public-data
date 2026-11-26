# Evolution — Techartist interactive biology atlas

**Source:** https://iamtechartist.com/evolution/
**Application:** https://iamtechartist.com/Apps/evolution/
**Author / publisher:** Techartist (public creator attribution); the About page describes a one-person, AI-assisted practice. No individual byline was established.
**Date:** Landing-page WordPress metadata reports publication and modification at 2026-11-26 16:12:12 UTC; this is not a version date for every application asset.
**Reviewed:** 2026-11-26 (UTC)
**Retrieved:** 2026-11-26, approximately 20:55–20:57 UTC; anonymous HTTPS requests returned HTTP 200 for the landing page, application, teacher guide and sampled bundles.
**Type:** Interactive educational web application with a promotional landing page and teacher documentation, not a research article.
**Revision:** No public repository commit, release tag or source tree was linked in inspected material. Deployed asset filenames and SHA-256 fingerprints below identify the reviewed bytes, not a reproducible source build.
**Verification:** Static review of HTML, teacher guide, shared application code, rendering bundle, anatomy, moth, finch and chapter-test bundles, and service worker. No source execution, installation, browser rendering, classroom trials or device permissions; no full dependency or all-lesson audit.
**Topic / stack:** Secondary-school evolution education; browser JavaScript modules, Three.js/WebGL rendering, canvas assessment/export, local storage and service worker.
**License:** No project-wide reuse license found in inspected material. Publicly playable is not permission to redistribute the application, models or artwork; no upstream code/assets are republished here.

---

## Verdict

📚 **Study — promising guided teaching material, not validated scientific simulation.** The implementation has more substance than its landing page suggests: measurable anatomy, interactive selection, a structured teacher guide and explicit misconception checks. Use it as a teacher-mediated illustration after checking the actual lessons and school privacy requirements; do not treat synthetic populations as raw scientific data, its certificate as a validated assessment, or its broad curriculum/offline claims as independently certified.

## Summary

Evolution is a ten-lesson browser atlas aimed at roughly ages 11–16. The live teacher guide organizes anatomy, variation, natural selection, quantitative finch selection, artificial selection, speciation, fossils, whale transitions, embryology and evolutionary trees into three acts, plus a visual chapter test. Each lesson is described as a 15–25 minute investigation, with curriculum codes, prompts and answer keys. Those timings and alignment are publisher assertions, not results of a learning study. [Landing page](https://iamtechartist.com/evolution/), [teacher guide](https://iamtechartist.com/Apps/evolution/teachers-guide.html).

A significant documentation mismatch matters: the landing page instead advertises cytochrome-c DNA comparison, radiometric half-lives, antibiotic resistance and a deep-time scrubber among its ten lessons. Those topics do not match the current ten-title navigation in the shared bundle and teacher guide. This is evidence of inconsistent descriptions, not proof those topics cannot occur anywhere. Evaluate the current atlas rather than scheduling a class from its marketing paragraph.

The strongest pedagogical feature is asking learners to make a prediction or interact before seeing an explanation. Moth predation separates individual traits from changing population frequencies; the guide explicitly rejects embryos becoming fish, whale fossils forming a literal parent-to-child ladder, and tree-tip adjacency implying closest relationship. The finch lesson also reverses the direction of selection when environmental conditions change. These are useful conceptual safeguards.

The scientific evidence is less reproducible than the presentation implies. Named researchers and numerical constants appear in the assets, but the guide's promised comprehensive SOURCES.md is plain text rather than a link, and the natural deployment-relative URL returned 404. No public repository was linked in the inspected pages. Consequently this review checks what the implementation does and how it labels its data; it does not certify every quoted measurement against original papers.

## Key Claims and Evidence

| Claim | What was verified | Assessment |
|---|---|---|
| Ten interactive lessons aligned to NGSS / KS3 / GCSE | Teacher matrix and shared navigation enumerate ten lessons and a test; lesson 6 is explicitly an HS bridge and some UK entries are enrichment | Concrete planning support, not proof of full standards coverage or independent endorsement |
| Based on real measurements | Anatomy credits Allen, Fedak & Hall and Gündemir; finch constants and Grant/Boag references are present | Distinguish cited aggregate observations from synthesized visuals; primary-data verification remains incomplete |
| Real finch investigation | Code generates 60 representative birds and selects survivors to approach a prescribed mean | Historical-data illustration, not an independent fit or simulation validating natural selection |
| Student-driven moth selection | Catch fractions feed a dominant-allele frequency update; seeded sampling produces moth displays | Mechanism is inspectable, but outcomes depend on designed rules and player perception, not an empirical experiment |
| Works offline after first load | Service worker caches requested same-origin resources | Visited-resource caching, not precaching the whole chapter; initial navigation may precede worker control |
| Progress and certificate | Local completion timestamps and canvas-to-PNG export code exist | Useful formative feedback; no classroom efficacy or assessment-validity evidence found |

## Implementation and Methodology

### Anatomy: morphing is a comparison device, not a transformation history

The first lesson loads same-origin arm JSON and binary geometry, then builds bone-specific forms with length, thickness and pose parameters. It includes named species and anatomical literature credits. Interpolation makes homologous structures legible, but the blended intermediate forms are a visualization, not reconstructed ancestral specimens or evidence that one modern species turned into another. Source: [main-BNssOjCC.js](https://iamtechartist.com/Apps/evolution/assets/main-BNssOjCC.js).

### Finches: honest synthetic specimens, predetermined aggregate targets

The finch bundle sets 1976 mean beak depth to 9.42 mm, 1977 survivor mean to 9.96 mm and 1978 offspring mean to 9.80 mm. A normal-quantile generator produces representative depths; seeded shuffling and a survivor-selection search bring the survivor mean toward the target. The on-page credit explicitly says the 60 birds match measured figures and are **not 60 measured birds**. That disclosure is important and commendable. A student can explore an argument from published summaries, but should not infer that these rendered birds constitute the Grant dataset or an independently predictive evolutionary model. [countingTheChange-xidFddXt.js](https://iamtechartist.com/Apps/evolution/assets/countingTheChange-xidFddXt.js).

### Moths: simplified inheritance plus human selection

The model starts with 24 displayed moths, defaults to seed 7, treats C as dominant, computes dark frequency as 1 − (1 − p)², and updates allele frequency using the observed dark/pale catch fractions. It clamps p between 0.005 and 0.995 and always draws at least one moth of each phenotype. Thus fixation/extinction are deliberately excluded from this display. It extrapolates one round of catches across multiple generations; it is not an individual-level ecological or genetic model with measured migration, mutation or mating behavior. Screen contrast, motor speed and perception can affect the classroom hunt. The copy does acknowledge that the game speeds up real selection. [whoSurvives-CVUSvu21.js](https://iamtechartist.com/Apps/evolution/assets/whoSurvives-CVUSvu21.js).

### Assessment and reproducibility

The test includes randomized layouts and client-side answers; the certificate is generated with canvas and a PNG data URL. This is a formative activity, not secure testing. There is no inspected source-build recipe, dependency lockfile, CI evidence, scientific validation suite or raw-data provenance manifest. Stable bundle hashes allow later comparison, but rebuilding or fully reproducing the deployed experience is a different requirement. No tests of the upstream application were run. [chapterTest-CZRYMM1f.js](https://iamtechartist.com/Apps/evolution/assets/chapterTest-CZRYMM1f.js).

## Strengths

- The teacher guide provides actual misconceptions, discussion prompts, lesson-specific answer keys and explicit curriculum mappings rather than only promotional claims.
- The finch visualization discloses synthetic individuals and illustrates changing selection pressures instead of presenting evolution as inevitable improvement.
- Shared navigation, glossary, local progress and quiet entry support a coherent classroom sequence; static code contains reduced-motion accommodations, though usability is untested.
- Publicly delivered JavaScript permits a meaningful inspection of model assumptions without installing or running unknown software.

## Gaps & Limitations

1. **Inconsistent landing-page syllabus.** Molecular comparison, dating and antibiotic topics advertised there are not the current guide's ten lesson titles. Fixing this is necessary for reliable lesson planning.
2. **Incomplete evidence trail.** The guide asserts every measurement is documented in SOURCES.md, but no public link was supplied and the obvious deployed path returned 404. Short author/year credits are useful but insufficient for a complete audit. No claim here that the underlying research is false.
3. **Learning outcomes unmeasured.** No evaluation design, sample sizes, control group, retention results or validated accessibility report were found. Visual polish and standards labels are not efficacy evidence.
4. **Scientific simplification needs narration.** Normalized limb morphs, allele clamps and target-matched finch populations should be explained as teaching models. Biological species definitions in the glossary are a useful starting point, not universal coverage of asexual taxa, hybrids or all species concepts.
5. **Accessibility and hardware remain open.** The landing page warns that live 3D needs graphics acceleration. Canvas/3D, drag/tap tasks and a timed hunt warrant keyboard, screen-reader, color-contrast, motion and low-end-device testing. Static accommodations do not establish conformance.
6. **No reuse/build assurance.** No project license or linked development repository was found; there is no basis here for recommending a maintained fork or redistributing the app.

## Privacy, Network and Offline Behavior

The direct application uses localStorage key evo-passport-v1 for completion state, including timestamps, and session storage for navigation state. In inspected core/lesson code, anatomy data comes from same-origin paths and the certificate is locally constructed. No microphone/camera request or student-response upload was identified in the inspected scope. This is a static finding, not a captured network trace or whole-site privacy guarantee. Shared browser profiles also share locally stored progress. [Shared bundle](https://iamtechartist.com/Apps/evolution/assets/paper-Srt4SQBg.js).

The public landing page is a WordPress wrapper that includes WordPress.com statistics and Bilmur scripts, plus WordPress-hosted image/assets connections. Therefore “no account” must not be conflated with “no third-party traffic.” Opening the direct app avoids loading that wrapper, but does not independently prove an analytics-free or school-policy-compliant session. No privileged interaction or personal information was supplied during review.

The [service worker](https://iamtechartist.com/Apps/evolution/sw.js) uses cache-first handling for assets/data and **network-first with cached fallback** for HTML; its comment calls that stale-while-revalidate, but its code waits for fetch. It installs no chapter-wide precache manifest. Only requested successful resources are cached, and the first uncontrolled load may not cache everything needed. Its activation deletes all origin CacheStorage entries except evo-atlas-v1 without a project-prefix filter, potentially interfering with other same-origin applications' caches. Unversioned data paths can remain cache-first stale under that fixed cache name. These are static design concerns, not observed browser failures. Before an offline class, load and exercise every required lesson on the actual devices, then test disconnected.

## Alternatives and Fit

For quantitative classroom inquiry, compare the free [PhET Natural Selection](https://phet.colorado.edu/en/simulations/natural-selection) activity; for teacher-led evidence/case-study material, compare [HHMI BioInteractive](https://www.biointeractive.org/); for conceptual explanations and teaching resources, compare [UC Berkeley Understanding Evolution](https://evolution.berkeley.edu/). These are complementary starting points, not alternatives benchmarked in this review. Techartist's distinctive appeal is the unified tactile atlas and anatomy/selection/fossil sequence. Prefer an established, documented teaching resource when auditable evidence and tested accessibility matter more than presentation; use this atlas as a guided supplement pending those checks.

## Provenance and Verification Record

Both application and landing HTML declare https://iamtechartist.com/evolution/ canonical. The [public WordPress page record](https://iamtechartist.com/wp-json/wp/v2/pages/3592) supplies the landing timestamps above; the landing JSON-LD attributes creation to Techartist. The [About page](https://iamtechartist.com/about/) describes its AI-assisted production. AI assistance alone is neither evidence of inaccuracy nor independent quality assurance. Existing public reviews/index were searched by both canonical and direct-application URL; no prior review of this source was found.

SHA-256 values are over raw downloaded response bodies, not readability extracts. Hashes cover a static sample, not the entire application:

| Public resource | SHA-256 |
|---|---|
| /evolution/ | 94efa55ef941b29d31e97a3a6231a876fd4a0dfc8ed6c80c6b67197690e4188d |
| /Apps/evolution/ | c8fec1424dd1815892ea989584bb60a361f11033794e472371d8d82119f8c804 |
| teachers-guide.html | 439bcf0d5c2c08ea28e7e77cec12b248b4bfdc70b4150f5cb09892b592e736b2 |
| assets/main-BNssOjCC.js | b57e2354896d459bcc0dbcd4caa990e4184793cc01a02521d7505c522dd8eb62 |
| assets/paper-Srt4SQBg.js | 1480e3ac7923b3cd3771aa0149f2c0d2976b8e3beb6af02b7be13884b527ed76 |
| assets/stage-D1IM62Q3.js | b82a2c587a6cf2932920e45159880ddda3445dfdb4b7ea8f2d3d21f8a26463bb |
| assets/countingTheChange-xidFddXt.js | 593c026663b3bdc8be2c15a42f56dd65a006af1dc04b2b361f02d038da2b20fd |
| assets/whoSurvives-CVUSvu21.js | b0b3975d734519464bb407af69315dc723cfc0afb6f1e922a56afcfae84db1e5 |
| assets/chapterTest-CZRYMM1f.js | c64eca60d254c2e0abea7de8ae7e5ecc2deb22e2f79bcc60beac482320e5db1b |
| sw.js | 553d7d5f0f71a3b91ee8ca5d32e54372bda1b3e50f09999c08b112b1cd0d2818 |

Anonymous acquisition, canonical matching and static evidence inspection succeeded. SOURCES.md acquisition at /Apps/evolution/SOURCES.md returned HTTP 404. No lesson interactions, visual render checks, live network captures, certificate downloads, offline runs or primary-study replications were performed. Recommendations are bounded accordingly.

---

**Attribution:** Techartist, *Evolution*, https://iamtechartist.com/evolution/. Analysis only; no upstream code, models or artwork redistributed.
