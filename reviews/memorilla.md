# Memorilla (snap-stanford/memorilla)

**Repo:** https://github.com/snap-stanford/memorilla

**Paper:** [Memorilla: Latent Semantic Memory for LLMs](https://arxiv.org/html/2610.21375v1)

**License:** Apache-2.0 code; preserve license/notices and mark modifications. Dataset and model licenses are separate; PersonalizationV4 is CC BY 4.0.

**Reviewed:** 2026-11-08 (UTC)

**Revision:** d8f18891a50bf33c18f04fe5167c22f51e58c9cd (2026-11-06), whole repository; external RL fork and model/data downloads not audited.

**Verification:** Static source/documentation review only. No source execution, dependency installation, model/dataset downloads, training, inference, or paid API calls. Public CI status checked separately.

**Stack:** Python 3.11+, PyTorch 2.7, Transformers 4.53.3, vLLM 0.9.1, Lightning 2.6.1, Arrow/Parquet, safetensors, Qwen3.

**What it is:** Learned, query-conditioned compression of document embeddings into soft prompt tokens for a frozen local LLM—not a general-purpose agent memory database.

---

## Verdict

📚 **Study: compelling latent-memory research, not a drop-in durable memory service.** The cleanly separated memory module, frozen decoder interface, explicit data layouts and substantive CPU tests make this worth studying or benchmarking on suitable GPUs. Production adoption needs application-owned lifecycle, deletion/invalidation, access controls, provenance and adversarial testing; headline token and latency reductions do not imply a cheap, provider-independent replacement for RAG.

## What It Is

Stanford SNAP's canonical repository implements the paper by Adibvafa Fallahpour and collaborators. A frozen Qwen3-Embedding-4B encodes each document; a learned module reads the entire embedding collection conditioned on a question and emits 16 vectors in Qwen3-8B's input embedding space. The decoder sees these vectors plus normal prompt text, not the original documents. This is lossy semantic compression, not lossless storage of a conversation in 16 tokens.

The intended users are researchers and teams able to train/serve open-weight models. The supervised path uses approximately 194 million trainable memory parameters according to the paper; encoder and decoder are frozen. A separate TextWorld experiment trains eight memory slots with reward. Neither path is autonomous personal-memory capture or an API-compatible plug-in for arbitrary hosted chat models.

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Collection input | Parquet rows: collection_id, documents, question, answer |
| Persistent representation | FP16 document shards and row-aligned question embeddings in safetensors |
| Memory readout | Learned slots, query conditioning, two cross-attention/FFN blocks, output projection |
| Training | Lightning, frozen Transformers decoder, answer-token loss; YAML recipes |
| Inference | vLLM prompt_embeds and copied decoder input embedding matrix |
| Evaluation | Eight benchmark protocols; closed-book/RAG/full-context runners |
| Optional tools | OpenAI PV4 generator, W&B logging, external SkyRL-Memorilla fork |

[MemoryModule](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/memorilla/memory.py) is legible: learned slots (or optional cosine top-k initialization), query cross-attention, optional document self-attention, document cross-attention, and projection. With default self-attention disabled, the read still touches every document: fixed decoder context is not constant storage or asymptotically constant retrieval cost. Enabling document self-attention also introduces quadratic document interactions.

[MemoryLLM](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/memorilla/llm.py) injects vectors at reserved memory-token positions during training; [MemoryVLLM](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/memorilla/vllm.py) implements corresponding prompt-embedding generation. [train.py](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/train.py) explicitly freezes the text model. Changing decoder family is not simply swapping an API endpoint: dimensions, tokenizer, projection and training distribution must match.

## Memory Lifecycle

- **Capture:** callers supply document lists or dataset collections. No background interception, salience policy, identity resolution, factual extraction or consent workflow. RL records trajectory turns, but its runtime lives elsewhere.
- **Read:** every collection embedding participates in learned attention; optional retrieval initialization does not eliminate that full read. No evidence snippets, source citations, confidence scores or inspectable facts accompany the answer.
- **Persist:** [EmbeddingStore/EmbeddingWriter](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/memorilla/embeddings.py) index sorted collection IDs into lazily opened, memory-mapped shards; collections are embedded from their first row. The dataset path reuses these representations. However, the convenient answer(question, documents) method re-embeds all supplied documents on every call: it does not implement an amortized persistent write path for application callers.
- **Update:** the architecture permits replacing changed document vectors, but the shipped store is a split-oriented writer plus read-only store, not a CRUD database. No document-level update/version/conflict/recency API. Repeated collection IDs are assumed to share documents.
- **Delete:** no deletion API, tombstones, TTL, retention policy or audited erasure. Applications must rebuild/remove raw Parquet, embedding shards, prediction files, caches and backups. If private data trained the module, deleting an external vector is not model unlearning.
- **Invalidation hazard:** missing_files() checks existence; load_split_with_embeddings() checks question row count—not content hashes. Editing/reordering a split without changing its count can silently reuse stale/misaligned embeddings. Encoder directory names use only the last model-name component, not an immutable revision. Treat source data, encoder revision and embeddings as one versioned bundle.

### Durability and Recovery

The builder has a file lock, missing-shard detection, chunked writes and lazy reading. But index, question and document writes are separate, with no transactional generation manifest, content hashes tying embeddings to rows, or end-to-end backup/restore protocol. Missing files can reveal interrupted initial builds; existence is not integrity, and complete-looking old files can conceal an interrupted overwrite. Memory weights/config are also separate ordinary writes.

[Training recovery](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/docs/training.md) restores optimizer/step state from last.ckpt, but explicitly does not reproduce remaining batch order. Epoch memory checkpoints are retained; evaluation reruns overwrite prediction/metric paths. PV4 generation uses atomic replacement and resumes existing files, stronger write behavior than the embedding store, but changed prompts/personas require deliberate invalidation.

## Evidence, Benchmarks and Reproducibility

The paper reports 84.33% FactKG accuracy versus 80.43% full-context accuracy at 108× fewer document tokens, a 49.68 average across benchmark primary scores, and a 16-token Pareto-frontier result. These are author results, not independently reproduced here. Token counts exclude question/shared instructions and do not include stored embeddings, model weights or ingestion/training compute.

The release includes eight benchmark protocols, explicit metrics, recipes and downloadable assets. [Evaluation docs](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/docs/evaluation.md) explain exact-match/generation metrics, nearest-choice embedding scoring, outputs and numerical variability. This is much better than a README-only leaderboard, with important qualifications:

1. **Supervised adaptation, not zero-shot general memory.** Stage 3 trains on training splits of all eight evaluated benchmarks; personalization gets additional tuning. This is legitimate supervised evaluation but differs from generic RAG without benchmark-specific training. Backbone pretraining contamination and upstream dataset overlap were not independently audited.
2. **Split names matter.** Paper Appendix B evaluates LaMP development splits, 500 seed-selected TriviaQA validation examples and a 100-example PubMedQA test portion of a 900/100 split. Released “test” labels do not imply original official test sets. Small/subsampled sets deserve uncertainty estimates.
3. **PV4 is synthetic and clustered.** [PV4 docs](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/personalizationv4/README.md) specify 119 training users, 30 disjoint test users, 4,237 test questions and 629 hard questions. Validation questions share training users. Chats/questions derive from the same generated persona, permitting shared synthetic style and assumptions; this is not real-user preference validation. The hard subset is selected by a particular untrained decoder's failures in no-memory/top-1 settings, not model-independent hardness. Training docs disclose one PMv2 test persona is not unseen.
4. **Accuracy can mean embedding preference.** PMv2, PV4 and FactKG answers map to the nearest candidate using Qwen3-Embedding-4B, also used for memory. Candidates are hidden from generation, but nearest-choice scoring does not prove exact factual precision or calibrated personalization. Averaging heterogeneous metrics is not a universal utility score.
5. **Prompts/context differ.** [Benchmark registry](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/memorilla/benchmarks.py) gives Memorilla and text baselines different prompts/suffixes and some different generation settings. Oversized baseline chats truncate from the front, potentially removing system prompt/header; context fit is reported. Equalize prompts and inspect truncation before attributing every difference to architecture.
6. **Paper coverage exceeds the runner.** The release runs closed-book, cosine RAG and full context. Appendix C additionally describes official Mem0/MemoRAG with a 4B memory writer, a reimplemented per-benchmark-trained xRAG bridge, LLMLingua-2 budget sweeps and ComMer's reported results. These are not each alternative's best latest/hosted configuration. Their full reproduction runners were not found in this release. Best-depth/budget-per-metric selection needs provenance; it is not itself proof of leakage.
7. **Checkpoint provenance has a documentation mismatch.** The README hosted table labels personalization checkpoints as from Stage 1, whereas standard personalization recipes continue Stage 3; the example single-task recipe starts Stage 2. Verify each hosted model card/config before assuming its folder reproduces the displayed curriculum. Helper downloads do not pin revisions.
8. **Reliability remains unverified here.** Supervised results use greedy decoding/fixed seed; docs acknowledge numeric drift. No independent training repetitions, confidence intervals, overlap audit or full reproduction were performed for this review.

### Latency and Cost

Paper Appendix F's 0.739-second versus 19.932-second comparison uses one H100-80GB, batch size one, 32 generated tokens, 250-token documents, medians of five timings after two warmups, and Hugging Face generation **without paged KV cache**. At 512 documents, full context uses YaRN for roughly 128K tokens. Encoding those documents is a separately accounted write cost of about 2.589 seconds. This is an amortized read-path result, not cold-start latency of answer(), nor an optimized vLLM serving comparison.

Sixteen memory tokens can greatly reduce decoder prefill but still require a 4B encoder, roughly 194M-parameter module, training and compatible local decoder. README requirements are Linux/CUDA, one 80GB GPU and roughly 25GB model download for the example; three stages reportedly take 19 hours on four H100-80GB GPUs and about 310GiB data/embeddings. These are source estimates, not measured costs here. Measure ingestion, repeated-query amortization, factual quality, throughput, GPU memory and wall-clock dollars—not compression alone.

### TextWorld Is a Different Experiment

[RL docs](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/rl/README.md) report 18.6% to 24.2% average success using eight soft tokens **in addition to full textual history**. Forty test prompts represent 30 distinct games; sampled rollouts are correlated, not independent tasks. Training has a 16K input budget and evaluation 4,096 tokens; terminal/truncation metrics matter. Longer simulator tiers retain four recent five-turn documents, unlike the all-turn medium/hard setting. The commit-pinned external SkyRL fork and Python 3.12/vLLM 0.11 environment are separate from the main environment and were not audited here. This does not establish unrestricted lifelong learning.

## Security, Privacy and Trust Boundaries

**Local does not mean automatically offline.** Helpers download assets from Hugging Face when absent. Standard inference runs local models rather than sending documents to a hosted text provider. The optional [PV4 generator](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/personalizationv4/generate.py) sends persona-derived prompts to OpenAI using OPENAI_API_KEY; it has retries/atomic output but no total spend cap or explicit Responses store=false. Provider retention depends on API/account policy: do not infer zero retention. Optional W&B exports run telemetry/configuration. No credentials were supplied or used in this review.

**Supply chain:** decoder/tokenizer loading sets trust_remote_code=True, permitting repository Python where applicable—not proof default Qwen assets execute custom code. Helper downloads lack immutable revision pins. Prefer audited local snapshots, restricted egress and isolation. Positives include safetensors, yaml.safe_load and weights_only=True for memory-state loading; they do not sanitize all dependencies/model code or external framework loading.

**No authorization boundary:** this is not a server with authentication, tenant ACLs, encryption or managed secrets; CORS is not an applicable built-in feature. Collection IDs route tensors, not authenticated users. The application must restrict documents before compression. Embeddings retain sensitive semantics. Inferred health/preferences in the README example should not become verified facts or assumed consent.

**Prompt injection is untested.** Questions/system prompts enter chat templates. Documents influence soft vectors placed in the system-prompt region; compression is not a demonstrated instruction/data firewall. No injection benchmark, source trust labels or policy enforcement layer was found. The tokenizer registers a reserved memory marker and inject_memory() assumes the expected placeholder count rather than validating per row. User text containing that marker is a static robustness concern (possible count/shape failure or unintended placement), not a dynamically demonstrated exploit. Empty/unbounded inputs also need application checks: the builder rejects empty collections, while answer() has no equivalent explicit guard. Do not expose the library directly to hostile tenants or privileged tools without separate controls.

## Tests, Dependencies, License and Maturity

Nine test modules plus fixtures/helpers cover memory masks/config/checkpoint round trips, embeddings, data/scoring, recipes, PV4 and RL aggregation. Fixtures use synthetic data/fake encoders. CI runs lint and CPU pytest, deliberately excluding vLLM; wrapper tests use importorskip and fake engines, so green CI does not validate real GPU inference. Real checkpoint tests require an opt-in directory. [CI run 42135886072](https://github.com/snap-stanford/memorilla/actions/runs/42135886072) succeeded at the reviewed SHA; that is upstream evidence, not tests run here.

Core GPU dependencies are pinned, with an NCCL override for multi-GPU stalls; other ranges/extras float and no complete lockfile is checked in. Main and RL installations have distinct platform contracts. This was not a dependency vulnerability scan.

Public metadata on 2026-11-08 showed 659 stars, 50 forks, zero open issues, November 6 latest push and no GitHub releases. Popularity/clean issue counts are not production proof. Readable code, clear limitations and automated tests are strengths; absent service/lifecycle guarantees and unreproduced GPU results limit readiness.

[LICENSE](https://github.com/snap-stanford/memorilla/blob/d8f18891a50bf33c18f04fe5167c22f51e58c9cd/LICENSE) is Apache-2.0 for code, with patent grant and standard notice obligations. Source datasets retain individual licenses; PV4 is CC BY 4.0. Inspect model cards and each dataset's terms before redistribution/commercial use; the code license does not cover all assets.

## Comparison

| Approach | Prefer when | Tradeoff versus Memorilla |
|---|---|---|
| Dense/hybrid RAG | Exact citations, mutable facts, portable hosted/local LLMs | More prompt tokens; inspectable retrieval and straightforward document provenance |
| Mem0 / Letta-style application memory | Explicit facts and agent memory workflows | Application-oriented text memory, not equivalent latent compression |
| MemoRAG | Global understanding should guide document retrieval | Still provides text; extra memory/model work but more inspectable evidence |
| xRAG / ComMer | Studying compact learned interfaces | Different compression scope/training; match backbones and data |
| Full context | Small collections and minimal infrastructure | Simple baseline; growing prefill/context requirements |

## Self-Hosting Notes and Practical Verdict

The useful idea is query-conditioned readout over reusable embeddings, not “all memory solved in 16 tokens.” GPU research teams should reproduce a small held-out task with immutable assets, equalized prompts and complete cost accounting. A deployed assistant should start with auditable RAG and explicit lifecycle controls; add latent memory only when measured gains justify coupling and reduced interpretability. A hybrid latent-plus-text evidence path is promising and consistent with the paper's own fine-detail limitation.

Use the documented Linux/CUDA/Python environment rather than assuming a CPU/macOS turnkey install. Avoid mixing the main and RL dependency stacks. Application deployment additionally needs encryption/access control, versioned data+embeddings, deletion across derived artifacts, validated inputs, authenticated serving, monitoring and backup/restore drills. None was deployed in this review.

## Verification and Limits

Inspected README/license/manifests/CI, memory/inference modules, embedding persistence, training recovery, evaluation protocols, tests, PV4 generation and RL documentation/configuration; fetched the public paper including computational/baseline appendices and public GitHub metadata. Local/live public review indexes were checked; no prior review of this canonical repository was found. No source tests or benchmark reproduction were run. Full released data, model cards, contamination, GPU behavior, deletion effectiveness and external RL implementation remain unverified.

**Attribution:** snap-stanford/memorilla and the authors of *Memorilla: Latent Semantic Memory for LLMs*, Apache-2.0 code; paper/data retain their own terms.
