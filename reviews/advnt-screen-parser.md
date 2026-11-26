# Advnt Screen Parser (arthuryeti/advnt-screen-parser)

**Repo:** https://github.com/arthuryeti/advnt-screen-parser
**License:** MIT wrapper/code; AGPL-3.0 model weights. Do not treat the complete pipeline as MIT-only.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** c689a1491c50c653ff042cdec58866be6216b872 (main, package 5.0.0); scope: README, licenses, manifests/lockfile, Dockerfile, all package modules, scripts, tests, and public release/model metadata. Hugging Face metadata revision: e1e3a667ea344d3bd10a59964aa43540b1b1bb94.
**Verification:** Static source and public metadata review only; no installation, source execution, inference, model/dataset download, device access, screen capture, or benchmark execution.
**Stack:** Python 3.10+, ONNX Runtime CPU, OpenCV, NumPy, RapidOCR, Hugging Face Hub; optional FastAPI/Uvicorn.
**What it is:** A specialized iPhone screenshot-to-element parser for mobile automation: learned social-app icons plus OCR and geometric recovery, not a device-control agent or a general accessibility tree.

---

## Verdict

⚠️ **Interesting — a focused local perception component, not a deployment-ready trust boundary.** The separation of CPU icon detection, parallel OCR, and deterministic geometry is useful for screenshot-only iOS workflows. Reported v5 accuracy is promising but uneven and not independently reproduced; unpinned model acquisition, fail-open default API authentication, incomplete reproducibility, and mixed licensing need attention before production use.

## What It Is

The v5 README targets Instagram, TikTok, X, YouTube, and iOS chrome/app icons. It claims 99 icon classes, including liked/saved states, across 7,357 training/validation frames. Input is an existing image file, byte string, array, or HTTP request body. Output contains text, words, raw icons, inferred elements, normalized coordinates, and timings. There is no screenshot capture, phone pairing, tap execution, or OS accessibility permission request in the reviewed package. The surrounding application owns those permissions and action safety.

The term “UI tree” describes internal geometry processing; the public result is a flattened reading-order list capped at 140 elements, with per-frame sequential IDs. It is not an authoritative hierarchy, stable cross-frame identifier system, or proof that an element is clickable. Nearby text is deliberately labeled “near …” rather than falsely promoted to an icon's semantic name. [S2–S4]

## Stack

| Layer | Tech |
|-------|------|
| Detector | YOLOv11m ONNX, CPUExecutionProvider, default portrait 960×480 |
| Text | RapidOCR PP-OCRv6-tiny, English detection/recognition, word boxes |
| Geometry | OpenCV contours, connected components, glyph recovery, grid slicing |
| Interfaces | Python API; advnt-parse CLI; FastAPI binary-image endpoints |
| State | In-memory inference engines; local model caches; optional CLI JSON/overlay files |
| Packaging | Hatchling; pyproject extras; uv.lock; Python 3.12-slim Docker image |
| Authentication | Optional shared bearer token, not required by default |

## Key Features

### Specialized icon semantics without a runtime vision LLM

The detector letterboxes, converts BGR to RGB, normalizes to a float tensor, runs ONNX, maps coordinates back, and applies class-aware NMS. Per-class thresholds from icons.json override the global fallback threshold. App-prefix voting suppresses weaker cross-app detections; bottom-bar recovery rescues existing low-confidence candidates when at least three aligned slots are detected. It does not fabricate missing detections from coordinates alone. These heuristics encode useful domain knowledge but can misfire on changed layouts or mixed-app imagery. [S3]

### Parallel text and icon work, bounded output rather than bounded resource use

ScreenParser submits OCR to a two-thread executor while running icons on the caller thread, then fuses results. Separate locks serialize OCR and ONNX execution across requests. OCR words are capped at 1,000 and each text value at 256 characters; the element list prefers labeled items when trimming to 140. This bounds response complexity, not image decode memory, queue growth, or worst-case latency. Returned totalMs starts after image decoding and excludes HTTP overhead. [S2]

### Geometry fills gaps, with explicit limits

The tree builder works at up to 540 pixels wide, merges learned icons with OCR, suppresses overlapping blobs, recovers dark glyphs and saturated buttons, and detects approximately three-column photo grids. It nests and orders candidate rectangles internally, removes layout-only roles and large elements, then emits percent boxes/centers and coarse “where” labels. Confidence exists on raw icons/words but is not preserved on the flattened elements; consumers must not assume every candidate is equally reliable. Landscape screens, accessibility scaling, non-English text, app redesigns, and unrelated apps require separate validation. [S4]

## Architecture

Image bytes → OpenCV decode → concurrent RapidOCR + locked ONNX detector → heuristic fusion → JSON. The CLI can write annotated images and JSON; the HTTP service shares one warmed parser. Both /v1/parse and /v1/ocr invoke the same complete parser, so the latter is not an OCR-only isolation boundary. Startup warms models before setting readiness; shutdown only clears readiness and does not explicitly shut down the parser's executor. [S2, S5, S6]

## Accuracy and Performance Evidence

All numbers below are **author-reported**, not reproduced here. The pinned Hugging Face evaluation summary provides 99 per-class entries and reports 834 validation frames, 6,377 boxes, and 46 hard-negative frames. Its overall weighted AP@50 is 95.32%, macro AP@50 92.73%, and AP@50–95 72.06%. It reports 6,058 true positives, 488 false positives, 319 false negatives, 92.55% precision and 95.00% recall. README/model-card figures instead round to 92.5% precision and 94.9% recall (card metadata: 92.47%/94.93%); icons.json reports another operating point, 89.14%/90.93%. These are not interchangeable metrics. [S1, S9]

The summary also records **45 false positives across 46 hard-negative frames**; it does not say that 45 different frames failed. X has 87.71% weighted AP@50, versus TikTok's 98.15%. Rare classes are weakly supported: tt_more has 0 AP on two boxes and yt_liked about 5.26% AP on one; x_more has 45.8% AP on 83. An overall score is not an action-success probability, OCR accuracy score, or full-tree correctness score.

The README claims temporally/job-grouped held-out validation with no training overlap, but split manifests, training images, and an independently held-out post-calibration action benchmark are not supplied in the inspected repository/model file inventory. The training script chooses checkpoints and tunes per-class F1 thresholds on validation data. “Held out from gradient training” therefore does not establish an untouched final test set. Dataset consent, source rights, label audit quality, and generalization cannot be independently verified from these artifacts. [S7, S9]

For v5, eval_summary.json lists **75.4 ms median / 78.7 ms p95**, without CPU model, thread setting, sample count, or full-pipeline timing provenance in that report. The sole GitHub release, v3.0.0, claims 30.6 ms detector / roughly 185 ms full pipeline; those are a different model and must not be carried over to v5. The benchmark script warms the detector and repeats image runs, but full-parser timing is one parse per image, not a throughput/load test. No current-device latency or photographic-screen accuracy was verified. [S7–S9]

## Security, Privacy, and Permissions

- **Inference path:** Reviewed application code processes supplied pixels locally; no screenshot-upload or remote inference call was found. This is a static finding, not an egress capture or dependency audit. Hugging Face downloads and RapidOCR model initialization are network-capable; Docker warm-up performs acquisition during build. A local model path plus auto_download=False affects icon acquisition only, not OCR initialization. Pre-stage both model families and test with network denied before claiming fully offline operation. [S2, S3, S10]
- **Screenshot sensitivity:** API responses contain recognized screen text; CLI stdout, JSON, and overlay files can retain private content. The service contains no request-image persistence or database, but also no redaction, retention policy, encryption-at-rest, secure deletion, or downstream logging controls. Protect caller files, proxy logs, model caches, and generated artifacts separately.
- **Authentication:** If neither ADVNT_API_TOKEN nor OCR_API_TOKEN is set, authorization returns successfully. With a token, hmac.compare_digest checks an exact bearer value. There is no tenant isolation, role model, token rotation service, built-in TLS, or rate limiter. Health routes are unauthenticated. No CORS middleware is configured; this is not an authentication mechanism. Docker binds 0.0.0.0 and the documented port mapping exposes the service beyond container loopback. [S5, S10]
- **Resource/input handling:** PNG/JPEG content types and a 5,000,000-byte limit are checked. However, request.body() buffers the body before its length check if Content-Length is absent or misleading; there is no decoded pixel/dimension cap. Invalid Content-Length integer conversion is outside the parse exception handler. The shared locks/executor do not provide admission control, request deadlines, or bounded concurrency. Add proxy streaming limits, decoded-image caps, authentication, and load controls before accepting untrusted inputs. These are source-derived concerns, not exploited vulnerabilities. [S5]
- **Agent boundary:** OCR strings and screen content remain untrusted input to any downstream LLM. Coordinate suggestions should never bypass confirmation for sensitive actions. Parsing is not authorization to tap, send, buy, or delete.

## Dependencies, Licensing, and Reproducibility

The wrapper is MIT with Arthur Yeti attribution; LICENSE credits Henry Yuan's MIT esp32-iphone-agent tree heuristics. README, package metadata, and the public model card declare **AGPL-3.0 weights derived from Ultralytics YOLOv11m**. LICENSE-MODEL and the model-host LICENSE still describe v3/YOLOv11s: an obvious stale notice, not permission to assume v5 is MIT. Clarify notices and AGPL obligations for the intended distribution/network-service arrangement; obtain legal review where needed. Training imports torch and ultralytics, which are absent from declared runtime/dev extras. [S7, S10]

A uv.lock is committed, but the Dockerfile uses pip install of the project rather than that lock, and dependencies largely have minimum versions without upper bounds. The Python base image is a mutable tag. Default icon download calls fetch model and metadata separately from an unpinned Hugging Face revision; although download_weights accepts a revision, normal constructors do not expose/pass one. There is no application-level hash verification or atomic model/metadata compatibility validation. Failed metadata fetch is swallowed, potentially leaving generic icon_N labels and losing calibration; an explicitly missing local model can leave the detector unavailable yet warm_up succeeds and service readiness still becomes true. [S3, S5, S10]

This review pins public model **documentation/metadata**, not downloaded or inspected ONNX tensors. Dependency licenses, vulnerabilities, transitive model origins, and binary compatibility were not comprehensively audited. Do not infer that MIT wrapper licensing covers OCR model redistribution or every transitive dependency.

## Persistence and Recovery

No workflow journal, database, durable request queue, retry scheduler, cross-frame tracking, or replay protection is implemented. Model files persist in Hugging Face/OCR caches; CLI outputs persist only when requested. Rebuilding from moving package/model references can change behavior. Startup failures prevent readiness, but readiness does not verify semantic metadata completeness or detector availability in every configuration. Exceptions during parsing become generic 503 responses (ValueError becomes 400); no automatic retry or circuit breaker is included. Pin artifacts, retain rollback copies, explicitly validate model availability/class counts, and make the calling agent reacquire its screen before acting on stale results. [S2, S3, S5, S6]

## Maturity and Verification

Anonymous GitHub metadata on the review date showed 12 stars, 3 forks, 0 open issues, and last push 2026-11-26T19:34:18Z. These are a snapshot, not quality or adoption evidence. The only listed release was v3.0.0 (published 2026-11-26), tag resolving to 3b84bad2e664673beb32368ba88b10607ee2c4d1, while the reviewed main/package is v5. CLI help and server version still reference v3; benchmark strings reference v4. [S8]

Nine test functions cover synthetic tree behavior, geometry/overlay output, determinism, a machine-dependent sub-100-ms tree assertion, and an optional detector integration test that skips without local weights. There are no checked-in GitHub Actions workflows and no reviewed server auth/upload/concurrency tests. The training calibration helper imports icon_detector from a services/ocr location absent from this repository instead of the packaged module; its comment claims voting/recovery is disabled, but the shown call does not explicitly disable those heuristics. The standalone training/reproduction route needs repair or explanation. **Tests were read, not run.** [S7, S11]

## Comparison

| Approach | Advantage | Tradeoff versus Advnt |
|----------|-----------|----------------------|
| Native accessibility/DOM via platform automation | Actual roles, labels, hierarchy, and often enabled state | Requires application/platform access; unavailable in some camera-only flows; prefer it when reliable |
| RapidOCR alone | Simpler text extraction; no social icon model | Misses unlabeled icons, semantic icon states and domain-specific recovery |
| Microsoft OmniParser | General screenshot parsing with icon understanding/captioning | Different model/dependency/license footprint; evaluate its current model terms and hardware needs rather than assuming equivalence |
| A vision-language model | Broader semantic understanding of unfamiliar screens | May add compute/network/privacy cost and unreliable coordinates; neither route proves action safety |

These are architectural alternatives, not an executed head-to-head benchmark. Public references: [RapidOCR](https://github.com/RapidAI/RapidOCR), [OmniParser](https://github.com/microsoft/OmniParser), [Appium](https://github.com/appium/appium).

## Self-Hosting Notes

A sensible pilot is an isolated, single-user local perception service on approved non-sensitive fixtures. Pin source, lock dependencies, independently pin and verify icons.onnx plus matching icons.json and OCR files; use prepopulated read-only caches where practical. The Docker non-root runtime user is a good baseline, not a substitute for API authentication or an egress policy. Bind privately, set a token, terminate TLS where traffic leaves a trusted host, enforce upload/pixel/time/concurrency limits, and avoid logging screen-derived data.

Before using it for automation, establish a frozen per-app evaluation set across device sizes, languages, themes, glare/tilt and app versions; measure per-class precision, negative-screen behavior, full-pipeline p95 and concurrent load, then validate actual tap outcomes. Require semantic-health checks and explicit handling of low-confidence/no-result parses. This is a worthwhile specialist pilot for the four supported social apps, not yet a default general desktop/mobile parser.

## Evidence and Provenance

All GitHub file citations below are pinned to the reviewed source commit. Public sources were retrieved anonymously on 2026-11-26; no private source evidence was used.

[S1]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/README.md
[S2]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/src/advnt_screen_parser/parser.py
[S3]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/src/advnt_screen_parser/icon_detector.py
[S4]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/src/advnt_screen_parser/uitree.py
[S5]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/src/advnt_screen_parser/server.py
[S6]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/src/advnt_screen_parser/cli.py
[S7]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/scripts/train_icons.py
[S8]: https://github.com/arthuryeti/advnt-screen-parser/releases/tag/v3.0.0
[S9]: https://huggingface.co/arthuryeti/advnt-screen-parser/tree/e1e3a667ea344d3bd10a59964aa43540b1b1bb94
[S10]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/pyproject.toml
[S11]: https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/tests/test_parser.py

- [S1 — README][S1]; [S2 — parser][S2]; [S3 — detector][S3]; [S4 — geometry][S4]; [S5 — server][S5]; [S6 — CLI][S6].
- [S7 — training][S7]; [benchmark script](https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/scripts/benchmark.py); [S8 — release][S8]; [S9 — pinned model card, evaluation summary, class metadata and license][S9].
- [S10 — package manifest][S10]; [lockfile](https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/uv.lock); [Dockerfile](https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/Dockerfile); [code license](https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/LICENSE); [model notice](https://github.com/arthuryeti/advnt-screen-parser/blob/c689a1491c50c653ff042cdec58866be6216b872/LICENSE-MODEL); [S11 — tests][S11].

---

**Attribution:** Arthur Yeti / arthuryeti/advnt-screen-parser; MIT code, AGPL-3.0 weights. Geometry credits Henry Yuan / onehumanbeing/esp32-iphone-agent (MIT). No source code or model weights redistributed in this review.
