# Unlimited OCR Works (baidu/Unlimited-OCR)

**Repo:** https://github.com/baidu/Unlimited-OCR
**License:** MIT repository code; model card declares MIT separately; dataset rights unverified.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** 37cf646758611a3b81f53863d1e91128a98d58b1 (main; 2026-11-16). Scope: full GitHub file tree, README, LICENSE, infer.py, utils; supplemental model metadata/configuration and inference/save paths at Hugging Face revision cb16b920ec2249c4b280f3aa67942e00b5099122; paper v1.
**Verification:** Static public-source review only. No source execution, installs, model/dataset downloads, inference, document uploads, service probes or benchmark reproduction.
**Stack:** Python, PyTorch, Transformers custom model code, customized SGLang, CUDA/Triton, Pillow; PyMuPDF in PDF example.
**What it is:** Baidu ERNIE Team's long-document vision-language OCR research, currently focused on Unlimited OCR 2: ordered page images become structured layout blocks, with cross-page text/table continuity and a Markdown conversion stage.

## Verdict

⚠️ **Interesting — strong long-document research, not a turnkey private OCR service.** Sparse reference attention plus bounded page-window decoding is a meaningful architectural contribution. The authors report compelling long-document scores, but the inaccessible benchmark release, custom serving wheel, unsanitized output and incomplete operational controls leave substantial validation work before production.

## What It Is

This is not a browser OCR application or a complete PDF-management product. The GitHub repository supplies a batch HTTP client and output postprocessor; the actual model implementation and weights live in a separate Hugging Face repository. Transformers runs locally; the recommended high-throughput path sends page images to an operator-run SGLang server. Baidu Cloud/TextMind and Hugging Face Spaces are separate hosted options, not evidence that local inference must upload documents. [1–4]

“One-shot” describes the document-level request, not necessarily all pages resident in GPU memory simultaneously. The paper explicitly explains that sparse attention alone does not stop all-page visual KV memory growth; overlapping page chunks and cache eviction are needed. Nor does “unlimited” mean infinite context fidelity, constant whole-document runtime or absence of output/page limits. [1,5]

## Stack

| Layer | Implementation / boundary |
|---|---|
| Visual backbone | DeepEncoder, inherited from DeepSeek OCR; model module imports SAM/CLIP builders and projector |
| Decoder | Paper: 3B MoE, 500M active parameters/token; SR-SWA replaces earlier R-SWA |
| Local API | Transformers AutoModel/AutoTokenizer with trust_remote_code; BF16 CUDA examples |
| Serving | Bundled development SGLang wheel; OpenAI-compatible chat-completions HTTP API |
| Batch client | requests + ThreadPoolExecutor; JSON usage/error logs and raw text files |
| Reconstruction | Standard-library regex parsing, union-find grouping, HTML table merging |
| Storage/auth | Filesystem outputs; no application database, auth layer or retention controller in the reviewed GitHub code |

## Key Features

### Cross-page structure, not just character recognition

Raw output contains PAGE/BLOCK/FORK markers, labels, bounding boxes and heading levels. The converter joins cross/append text and table chains, merges repeated table headers, preserves page numbering across blanks and normalizes headings into a single-root tree. These are explicit benchmark-aligned transformations, not proof that the original document hierarchy was recognized correctly. Figure references are emitted as coordinate-based filenames; this converter does not create those image crops. [3]

### Sparse references plus chunk continuity

The paper's Page Gate restricts visual candidates by page; Token Sieve selects a fixed budget of remote blocks alongside a local window. Overlapping chunks reuse boundary-page visual KV and a text tail, dropping inactive caches. This is useful for transcription but deliberately gives up full global context: the paper names heading hierarchy/global-document understanding and training-data diversity as limitations. [5 §§3,6]

### Inspectable evaluation plumbing—with caveats

infer.py orders page images numerically, packs every page as base64, sends one document per request, records finish_reason/page markers/usage/time and saves raw results. It uses benchmark-specific length limits (131,072 and 786,432), a 30% fallback output allowance and one server-length refit. If token tables are available, it uses ground-truth text-token length to decide whether to fall back from tiled “gundam” to base mode. That is evaluation-time oracle information, not ordinary production input; compare a non-oracle deployment policy separately. Failures are logged and the batch continues, so process completion alone is not an all-documents success signal. PNG inputs are also labeled image/jpeg in this client. [2]

## Accuracy, Layout and Language Evidence

The following are **author-reported**, not independently reproduced. Overall is an aggregate parsing score, not a percentage of correctly recognized characters. Edit distance is lower-is-better; CDM/TEDS/F1 are higher-is-better. [5 Tables 1–3]

| Benchmark | Overall | Text edit | Cross-page text edit | Table TEDS | Cross-page table TEDS | Heading TEDS |
|---|---:|---:|---:|---:|---:|---:|
| MPDocBench | 84.59 | 0.052 | 0.100 | 87.78 | 89.54 | 60.10 |
| MarathonDocBench | 77.06 | 0.104 | 0.123 | 74.81 | 71.11 | 48.20 |

MarathonDocBench is described as 100 documents, 103–300 pages each, with 205k annotated layout elements. Structures start from parser output and receive human refinement; transcriptions undergo VLM refinement with flagged disagreements adjudicated by humans. This is useful methodology disclosure, but it remains an author-created benchmark with machine-assisted labels. The public dataset URL returned HTTP 401 (page displayed 404); its API and raw card were also inaccessible without authentication. No dataset was obtained, and its license, splits, source-document rights and scoring artifacts could not be verified. [5 §3.1.2; 7]

Single-page OmniDocBench v1.6 overall is 94.02; the same table reports TeleOCR 96.91 and OvisOCR2 96.47. Thus long-document leadership in the authors' comparison is not universal OCR leadership. Marathon heading TEDS 48.20 and figure F1 71.79 also caution against “perfect layout” interpretations. Formula CDM is 89.39 on MPDocBench and 87.93 on MarathonDocBench. [5]

The model card says multilingual, but the inspected release/card/paper does not establish a per-language accuracy matrix or guaranteed language list. Handwriting, low-resolution scans, unusual scripts, rotated photos and domain-specific tables need separate evaluation. No blanket language/handwriting suitability is inferred from the multilingual tag. [4,5]

**Reproducibility:** public client and conversion rules help, but GitHub has no scoring harness, dataset snapshot, dependency lockfile, CI or tests in its complete reviewed tree. The model is separately versioned; README model loads are not revision-pinned. Ground-truth-based mode selection and postprocessing must accompany any score comparison. No independent accuracy, latency, memory or robustness measurement was made. [1–5,8]

## Hardware, Performance and Costs

README's tested Transformers configuration is Python 3.10 and an NVIDIA A800-80GB with specified torch/Transformers versions. This is a tested configuration claim, not a demonstrated minimum GPU requirement. The HF metadata lists 3,343,978,240 BF16 parameters: roughly 6.69 GB decimal (6.23 GiB) for those weights alone, excluding KV, activations, encoder tensors, allocator overhead and concurrency. “500M active” does not mean only 500M parameters need storage. CPU, Apple Silicon and consumer-GPU performance were not established. [1,4]

Paper Table 4 reports peak **KV cache**, not total VRAM, dropping from 47.00 GB to 1.77 GB at batch 1, and throughput rising from 360 to 1,315 tokens/s at batch 16. Its 7.0×/5.6× abstract speedups concern per-step decoding versus full attention/R-SWA; the latency study uses gundam mode, batch 3 and fixed 1,024 generated tokens/page. These are different measurements, not a universal end-to-end speed guarantee. The text does not sufficiently tie Table 4 to a complete reproducible hardware/software measurement manifest. [5]

README explicitly discusses OOM-prone allocations, shared-memory transport, prefill buckets, GPU headroom and smaller page windows hurting cross-page merging. The batch client still loads/base64-encodes all document pages into a payload; bounded server KV does not bound client RAM or transfer size. Base64 alone expands binary data by approximately one third. [1,2]

There is no repository license fee, but GPU time, electricity, RAM/storage, serving engineering and dependency maintenance cost money. No hosted price, free quota or retention guarantee was verified; cloud use requires separate commercial/security review. Training is not a cheap reproduction path: the paper reports 25×8 H800 GPUs and 12 million training documents. [5]

## Privacy and Security

- **Local versus hosted:** the inspected Transformers infer path opens local images and generates locally. Model acquisition is a separate Hugging Face network trust boundary. The batch client deliberately transmits full page images to its configured server; selecting a remote server is document egress. Hosted Spaces/TextMind are third-party processing paths with unverified retention, geographic processing, training-use and deletion terms. No upload was performed. [1,2,4]
- **Not secure-by-default serving:** README binds SGLang to all interfaces and shows no API-key/TLS configuration. infer.py constructs plain HTTP URLs, offers no auth-header option and does not correctly support a supplied HTTPS URL. It uses requests.post with default environment/proxy behavior; unlike the README's separate example, it does not set trust_env=False. Keep a prospective deployment private and add authenticated transport and quotas; no actual exposure was probed. [1,2]
- **Retention is operator-owned:** PDF example writes page images to a temporary directory without cleanup. infer.py persists raw text; the HF save_results path writes result.md, raw Markdown and annotated page JPEGs/crops. Neither reviewed path provides expiry or secure deletion. Terminal output and service/proxy logs can retain document content. Disabled serving caches are not a data-retention policy. [1,2,4]
- **Output is untrusted:** converter preserves raw text/HTML tables and attributes, fixing spans but not sanitizing markup or URLs. Rendering generated Markdown with raw HTML enabled can expose a downstream XSS/content-injection surface; no exploit was executed. Sanitize HTML, disable active content and treat OCR text as data—not agent instructions. [3]
- **Hostile PDFs/images:** native image/PDF decoding, large page counts, giant raster dimensions and long outputs need isolated workers, patched parsers, resource/page/pixel limits and cancellation. Reviewed examples supply no comprehensive upload validation or sandbox. Page-count/output guards are not document-safety controls. [1–4]
- **Credentials:** local examples need no hosted API key. That does not make an exposed server safe, nor prove cloud access needs no account. Do not give model-loading workers unrelated credentials. [1,2]

## Supply Chain and Licenses

**Code:** GitHub LICENSE is MIT, copyright 2026 Baidu: retain copyright/permission notices when redistributing substantial code; no warranty. **Model:** the separate HF card declares MIT; that is separate evidence, not an inference from the code license. The model file listing has no standalone LICENSE, so preserve the declaration and investigate inherited component notices before redistribution. **Datasets:** MarathonDocBench was not publicly retrievable in this review; its terms and underlying-document redistribution rights remain unknown. The training corpus description is not a released, licensed training dataset. Model/code permission does not clear document copyright. [4–7]

Transformers examples enable trust_remote_code=True; safetensors limits weight-format risk but does not sandbox imported Python or CUDA/Triton code. The model's imports fan out to several custom modules. SGLang is a repository-supplied development wheel, represented as an LFS pointer in the Git tree; it was not downloaded, unpacked or audited. The README pins some packages but not the whole dependency graph or model revision; no reproducible build/attestation for that wheel was established. Audit exact revisions and artifacts before installing. Pillow, PyTorch, Transformers, SGLang and PyMuPDF have their own terms; notably PyMuPDF's AGPL/commercial licensing needs separate deployment review rather than assuming MIT covers the stack. [1,4,6,8,11]

## Maturity

Public GitHub metadata at review time: 31,984 stars, 3,431 forks, 97 open issues/PRs combined; created 2026-06-18, last push 2026-11-16. The API returned no GitHub releases; one tag, UnlimitedOCR1.0, points to 92ad94b53a51950fea0416aced42331dfb4dd59e. README announces version 2 on 2026-10-27 and TextMind availability on 2026-11-16. Popularity and issue count do not establish quality. Latest public issue samples were not a useful basis for a bug-rate assessment. No CI/tests were present in the inspected GitHub tree, and no tests were run here. [8–10]

## Comparison

| Option | Better fit / tradeoff |
|---|---|
| Unlimited OCR 2 | Research into long-form cross-page transcription; specialized model/runtime and careful completeness checking required |
| PaddleOCR / PaddleOCR-VL | Compare established OCR/document parsing pipelines and multilingual task coverage; do not assume equivalent cross-page semantics |
| DeepSeek OCR 2 | Closely related visual/decoder lineage and single-page baseline; does not make this implementation interchangeable |
| Tesseract / OCRmyPDF | More conventional local text extraction/searchable-PDF workflows; not an equivalent end-to-end cross-page structural model |
| MinerU | Compare practical structured-document pipelines; independently review current code/model licensing and operating requirements |

These are fit comparisons, not a new head-to-head benchmark. Official source links: [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR), [DeepSeek OCR 2](https://github.com/deepseek-ai/DeepSeek-OCR-2), [Tesseract](https://github.com/tesseract-ocr/tesseract), [OCRmyPDF](https://github.com/ocrmypdf/OCRmyPDF), [MinerU](https://github.com/opendatalab/MinerU).

## Self-Hosting Notes

Before adoption: pin and audit the model/custom-code revision and wheel; resolve dependency licenses; isolate GPU workers; keep the API nonpublic behind authenticated encrypted transport; bound pages/pixels/output/time; sanitize rendered output and define image/text/log retention. Evaluate a licensed representative corpus without oracle token tables, checking missing pages, truncation, tables, reading order, heading trees, language variation and human correction effort. Require explicit success accounting instead of trusting batch exit status. This review intentionally provides no executed deployment or inference result.

## Evidence and Limitations

1. [Pinned README and runtime instructions](https://github.com/baidu/Unlimited-OCR/blob/37cf646758611a3b81f53863d1e91128a98d58b1/README.md).
2. [Pinned batch client](https://github.com/baidu/Unlimited-OCR/blob/37cf646758611a3b81f53863d1e91128a98d58b1/infer.py), especially plan, build_payload, request_one and main.
3. [Pinned postprocessor](https://github.com/baidu/Unlimited-OCR/blob/37cf646758611a3b81f53863d1e91128a98d58b1/utils/process_unlimitedOCR2.py) and [format documentation](https://github.com/baidu/Unlimited-OCR/blob/37cf646758611a3b81f53863d1e91128a98d58b1/utils/README.md).
4. [Pinned model card](https://huggingface.co/baidu/Unlimited-OCR-2/blob/cb16b920ec2249c4b280f3aa67942e00b5099122/README.md), [configuration](https://huggingface.co/baidu/Unlimited-OCR-2/blob/cb16b920ec2249c4b280f3aa67942e00b5099122/config.json), [model implementation](https://huggingface.co/baidu/Unlimited-OCR-2/blob/cb16b920ec2249c4b280f3aa67942e00b5099122/modeling_unlimitedocr.py), [public metadata](https://huggingface.co/api/models/baidu/Unlimited-OCR-2).
5. [Unlimited OCR Works 2, arXiv v1](https://arxiv.org/html/2610.39308v1), Baidu ERNIE Team; retrieved 2026-11-22. Retrieved HTML SHA-256: 8693547c741620011b1fe48755052e46d94e1e2bf3753cb05c8e017da01292a6. Full static HTML was read after the initial text extractor omitted later sections.
6. [MIT license](https://github.com/baidu/Unlimited-OCR/blob/37cf646758611a3b81f53863d1e91128a98d58b1/LICENSE).
7. [Advertised MarathonDocBench location](https://huggingface.co/datasets/baidu/MarathonDocBench) — inaccessible in this review; no private details or dataset contents inspected.
8. [Exact source tree](https://github.com/baidu/Unlimited-OCR/tree/37cf646758611a3b81f53863d1e91128a98d58b1).
9. [Repository metadata](https://api.github.com/repos/baidu/Unlimited-OCR).
10. [Releases](https://github.com/baidu/Unlimited-OCR/releases) and [tags](https://github.com/baidu/Unlimited-OCR/tags).
11. [PyMuPDF licensing](https://pymupdf.readthedocs.io/en/latest/about.html#license-and-copyright).

Limits: no wheel/kernel dependency audit, malicious-document tests, full model-code audit, hosted terms verification, language benchmark or independent model performance measurement. Static findings identify integration risks, not confirmed exploitable vulnerabilities. No private documents or accounts were used.

---

**Attribution:** Baidu / Baidu ERNIE Team, Unlimited OCR Works; MIT repository code and separately MIT-declared model. Analysis is independent; no model, dataset, wheel or source implementation is redistributed here.
