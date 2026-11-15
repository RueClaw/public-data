# Moshi-Finetune (kyutai-labs/moshi-finetune)

**Repo:** https://github.com/kyutai-labs/moshi-finetune
**License:** Apache-2.0 code; model and dataset terms are separate.
**Reviewed:** 2026-11-15 (UTC)
**Revision:** 2acc879fe7c48f885a18f6cc9548bccb2674d87b (main; commit dated 2025-07-07). Scope: training, annotation, all finetune modules, configuration, notebook, dependency metadata and CI; selected upstream Moshi modules at the lockfile revision.
**Verification:** Static review only. No installation, source execution, model/dataset downloads, training, inference, GPU access or runtime tests. Public metadata and text model/dataset cards fetched separately.
**Stack:** Python ≥3.10, PyTorch 2.6, CUDA/NCCL/FSDP, Moshi/Mimi, SentencePiece, sphn, whisper_timestamped, safetensors, TensorBoard, optional W&B and SLURM.
**What it is:** Kyutai's supervised adaptation toolkit for Moshi full-duplex speech dialogue models—not a generic voice-cloning service or a standalone inference server.

## Verdict

📚 **Study — useful official reference, but repair and qualify before expensive training.** The stereo-audio-to-aligned-text pipeline and LoRA/FSDP implementation are concrete and relatively small. However, evaluation is not repeatable as wired, checkpoints are inference exports rather than full training recovery, configuration logging can expose an explicitly supplied W&B key, and dependency drift makes a fresh installation materially different from the locked environment. These are reasons to treat it as research code, not a turnkey fine-tuning product.

## What It Is

The intended user is a speech-model researcher with consented two-party recordings and NVIDIA compute. One stereo channel represents Moshi's output and the other the user's input. A frozen Mimi codec turns the waveforms into parallel audio token streams; timestamped main-speaker words become the aligned text stream. Supervised teacher-forced learning adapts the Moshi language model, not Mimi.

The documented/default target is the original 7B **kyutai/moshiko-pytorch-bf16** model. Custom Moshi/Mimi/tokenizer/config paths exist, but there is no version compatibility matrix proving arbitrary newer Kyutai speech models, other languages, quantized variants or conditional models work. The model card identifies English, limited reasoning/tool capabilities and research-oriented intended use. Its full-duplex latency statements are base-model claims, not fine-tuned measurements from this review. [1][2][9]

## Stack

| Layer | Implementation |
|---|---|
| Entrypoint | Fire CLI in train.py; torchrun even on one GPU |
| Model | Upstream Moshi temporal transformer plus depth transformer over audio codebooks |
| Audio/text | Frozen Mimi, sphn decoding/chunking, SentencePiece, timestamp interleaver |
| Optimization | AdamW, OneCycleLR, gradient accumulation, BF16 parameters with FP32 trainable master copies |
| Distribution | NCCL; full-shard FSDP for multiple GPUs; ordinary CUDA model for one |
| Artifacts | safetensors weights, JSON config, YAML arguments, local JSONL/TensorBoard metrics |
| Optional services | W&B experiment logging; SLURM annotation jobs; Colab/Gradio tutorial |

## Architecture and Key Features

### Real multistream adaptation, not text-only PEFT

train.py loads CheckpointInfo, freezes Mimi and constructs the token interleaver and model. Upstream Moshi's temporal transformer consumes summed text/audio embeddings across time. Its depth transformer predicts the assistant audio codebooks within each time step; delays are applied and outputs realigned before masked loss. The default upstream configuration has 16 audio input streams and predicts eight assistant codebooks plus text. The user channel conditions the prediction rather than becoming a second assistant-target loss. Text and audio cross-entropies are added; the example weights the first semantic codebook by 100 and text padding by 0.5. [2][3][4][8]

### LoRA versus full fine-tuning

LoRA is genuinely implemented: the locked upstream loader recursively replaces Linear modules with frozen base weights plus low-rank A/B paths, scaling the update directly by the configured factor. The wrapper enables gradients by parameter name containing lora; ft_embed additionally enables names containing emb. This is broader than attention-only adaptation. A is Kaiming-initialized and B starts at zero. Full fine-tuning requires full_finetuning=true and lora.enable=false and trains all language-model parameters; Mimi remains frozen. This is not QLoRA and the reviewed pipeline provides no quantized-base training recipe. [2][3][8]

The default example uses rank 128, scaling 2, 100-second chunks, batch 16 per GPU and 2,000 steps. Gradient checkpointing trades computation for activation memory. FSDP separates trainable/frozen groups and shards transformer layers. The loop accumulates microbatch gradients, then upcasts trainable state for AdamW. Multi-GPU qualification is still necessary: clipping uses generic clip_grad_norm_ on local parameters rather than FSDP's global-norm operation, and the accumulation branch assumes every trainable parameter has a local gradient. These are static concerns, not a reproduced distributed failure. [2][3]

## Data, Preprocessing and Quality

The JSONL manifest contains path and duration fields. Each stereo audio file needs a same-stem JSON sidecar with alignments shaped like {"alignments": [["hello", [0.1, 0.5], "SPEAKER_MAIN"]]}. Left/channel 0 is the assistant, right/channel 1 the user. sphn supplies fixed-duration, sample-rate-converted segments; the loader supports weighted source mixtures and rank-strided shuffling. Mimi codes are computed during iteration, rather than loaded from an offline codec cache. [1][4]

annotate.py runs local whisper_timestamped (default medium, forced English) on channel 0, resamples to 16 kHz, uses auditok VAD for longer audio and writes word-level main-speaker labels. It does not diarize a mixed mono recording despite the parser description. **The README's bare annotation command defaults to SLURM submission; --local is needed for its local path**, which still requires CUDA. Existing sidecars are skipped, error markers suppress retries unless requested, and writes use temporary files plus rename. It reads manifest paths directly, so path resolution should be validated separately from the training loader. [5]

Important contracts are weakly enforced: no dedicated preflight validates two-channel identity, finite ordered timestamps, consent, manifest/sidecar completeness or split leakage. Binary search selects alignments before a later sorting step, so inputs must already be sorted. Overlapping/dense words can replace pending text tokens under default keep_and_shift=false. There is also a visible units mismatch: InterleavedTokenizer passes this_num_audio_frames to prepare_item's segment_duration, which multiplies by frame rate again; downstream padding/cropping hides final shape differences but not the redundant construction. None of these paths was run here. [4]

Use speaker/session-disjoint train, validation and test sets; manually audit timestamp alignment, channel order, overlap, silence, clipping, ASR errors and duplicated conversations. Preserve natural pauses instead of optimizing solely for transcript accuracy. The README warns that shortening chunks to fit memory may make the model become silent earlier during inference. There is no automatic consent or de-identification system. Voice likeness, conversation privacy and participant withdrawal must be handled before training; adapters can retain sensitive material.

### Dataset and model rights are not the code license

The root LICENSE is Apache-2.0 and README credits Apache-2.0 mistral-finetune code; preserve applicable notices when reusing code. The default Moshiko model card declares CC BY 4.0 and separately describes research-only intended use and discourages impersonation. Those statements should not be silently collapsed into the repository's Apache grant or an invented noncommercial license. [1][9]

The linked DailyTalkContiguous card declares **CC BY-SA 4.0**, describes concatenated stereo DailyTalk conversations with word timestamps, and says freely available for academic use. That wording does not establish unrestricted rights to voices or settle how share-alike applies to a proposed trained artifact. Review the original dataset, attribution and applicable rights before distribution or commercial use. The brief card is not participant-consent evidence; this review downloaded no dataset and verified no consent records. [10]

## Evaluation and Reproducibility

**Do not trust the emitted perplexity as a standard comparable benchmark.** The example disables evaluation. When enabled, train.py creates one finite generator outside the loop and reuses it: later evaluations continue through or exhaust that generator instead of restarting the same validation set. evaluate increments its batch counter before checking the 40/world_size cap, potentially counting an unprocessed batch; the data loader discards incomplete batches. Empty/exhausted evaluation has no positive-denominator guard. Unequal rank-local batch counts also need coordinated FSDP handling. [2][4][6]

Losses are averaged per batch rather than globally by effective token weight. The code computes 2**eval_loss even though PyTorch cross_entropy uses natural-log units; moreover eval_loss is the sum of differently weighted modality means. That is not ordinary token perplexity. Separate text/audio values are stored in state but are not supplied by the training call to get_eval_logs. There are no supplied WER, intelligibility, listening-preference, turn-taking, interruption, latency, safety or forgetting evaluations. A README training-curve image does not establish improvement against an untouched base model. [2][6]

Seeds, saved YAML, explicit example hyperparameters and a uv lockfile are helpful, not proof of deterministic replay. Dataset/Hugging Face revisions are not exposed as pinned training arguments, GPU determinism is not enforced, and optimizer/scheduler/RNG/data-cursor restoration is absent. Before a pilot, freeze the full environment and artifact hashes, repair validation, compare base versus adapted outputs on consented held-out conversations, and measure both dialogue quality and regressions. No training-quality result was independently verified here.

## Hardware, Time and Cost Evidence

| Evidence | What it actually establishes |
|---|---|
| README: 1×H100 ≈12k tokens/s, 39.6 GB peak allocated | Author-reported example configuration; not independently reproduced or a minimum-VRAM promise |
| README: 8×H100 ≈10.7k tokens/s, 23.7 GB peak allocated | Author-reported distributed case; do not read the lower number as total cluster throughput |
| Colab notebook: A100, batch 1, 100 seconds, 300 steps | Suggested smaller tutorial, not a recorded successful run or guaranteed free-tier fit |
| Full fine-tuning / adapter merging | Implemented, but no comparable memory/time table supplied |

The source metric counts text/audio mask elements per rank, including invalid/padded positions; it is not ordinary LLM text tokens/s. Memory logging divides bytes by 1024³ despite labeling GB, and allocated memory excludes other reservation/driver overhead. No reliable end-to-end wall time, annotation budget or dollar cost is supplied. On the single-H100 headline alone, the documented nominal 360 million token positions (2,000×16×100×9×12.5) divided by 12k/s implies roughly **8.3 hours of counted work**, not a measured job duration; preprocessing, startup, checkpointing and throughput variability can add cost. Multi-GPU batch scaling changes total examples processed, so equal steps are not equal-data comparisons. No rental price or 24-GB-card fit is asserted. [1][2][7]

## Privacy, Provider Egress and Checkpoint Trust

Training is principally local, and the reviewed logger explicitly sends scalar metrics rather than raw audio/transcript tables. That is not an air-gap guarantee: model/tokenizer/Whisper acquisition contacts upstream hosting; optional W&B sends run configuration and metrics; hosted notebooks put recordings on a provider, and the tutorial's Gradio tunnel moves interactive audio across another service boundary. The inference server is supplied by upstream Moshi, not secured by this repository. Review its authentication, TLS, bind address and recording behavior separately before exposing it. [1][2][5][7]

**Credential disclosure path:** TrainArgs includes wandb.key, args.save writes the arguments to args.yaml, pprint logs the complete dataclass, and MetricsLogger passes the same configuration to wandb.init. Thus a key placed in the suggested YAML reaches local artifacts/logging and is handed to the SDK as configuration; SDK-side redaction was not verified. Avoid putting credentials in this field; use an approved external authentication mechanism and redact configuration before logging. Annotation error logs can include transcript word/segment contents and paths. Audio, sidecars, errors, run files, caches and adapters have no repository-level encryption, retention or deletion policy. [2][5][7]

The training wrapper requires safetensors for the main weights; exports use safetensors plus config.json, a stronger default than arbitrary Python pickle. It still uses non-strict loading, trusts the selected model/config, and has no authenticity/signature policy. The pinned upstream loader has torch.load fallbacks for non-safetensors artifacts (including codec paths), whose behavior depends on the installed PyTorch version. Treat all checkpoints/configs and package sources as trusted inputs, not sandboxed data. [3][8]

### Export is not resume

Checkpoint saving gathers adapter weights or merges LoRA into full weights, writes into a temporary consolidated directory and renames it. This reduces partial-visible output, but no fsync durability or verified restore is provided. Although Checkpointer accepts an optimizer and has a broad docstring, it saves neither optimizer nor scheduler, RNG, step state or data position. There is no resume argument/loader in the training entrypoint. Initializing a new run from exported weights is a warm start, not exact continuation. [2][11]

Retention defaults to three checkpoint directories and deletes older directories by filesystem ctime. overwrite_run_dir recursively deletes an existing run directory, and the setup branch can be entered on every torchrun rank, creating a distributed race risk. Use unique run directories and independent backups; do not treat overwrite as recovery. Adapter merging additionally needs CPU/GPU headroom. The README's full-model inference command has a duplicated consolidated/config path segment; inspect actual export paths instead of copying it blindly. [1][2][11]

## Dependencies, CI and Maturity

pyproject.toml pins torch==2.6 and sphn==0.1.12 but installs Moshi from mutable Git HEAD; several other dependencies are unconstrained. uv.lock records Moshi **061cc4c630d9e11722e08b7d02b1836ba58f30e8**, so pip and a locked uv environment need not select the same APIs. Explicitly pin compatible source/artifact revisions and review native audio/CUDA dependencies before an isolated install. No install or vulnerability audit was performed here; absence of an audit is not evidence of safety. [12]

The tracked CI is a CPU environment plus pre-commit lint/format/notebook-output checks; it does not prove CUDA, FSDP, model loading, training, checkpoint restore or speech quality. No tracked runtime test suite was found (pytest is merely a dev dependency). CI uses version-tagged checkout/setup-python/cache actions rather than full-SHA pins and installs the editable project from mutable dependency metadata. CONTRIBUTING calls this research-paper implementation, prioritizes bug fixes over features/refactoring and requires a substantive CLA. [13]

Public metadata observed 2026-11-15: 532 stars, 88 forks, 22 open issues/PRs, no releases returned; repository last-push field 2026-09-09, while reviewed main's tip remains dated 2025-07-07. These are distinct metadata fields, not proof of ongoing main-branch maintenance. Public open PRs [#28](https://github.com/kyutai-labs/moshi-finetune/pull/28) and [#29](https://github.com/kyutai-labs/moshi-finetune/pull/29) propose evaluation and dependency fixes; they were **not merged into the reviewed SHA**, and their test claims were not reproduced. [14]

## Comparison and Practical Fit

- **Upstream Moshi inference:** start here if the goal is simply to converse with the base model; fine-tuning adds data rights, GPU spend and regression obligations. This repository exports into that runtime rather than replacing it.
- **Hugging Face PEFT/TRL-style text adaptation:** more general text training tooling, but not a drop-in substitute for synchronized Mimi audio streams, delayed codebooks and depth-transformer losses.
- **ASR → text LLM → TTS composition:** easier to swap and evaluate components independently; does not preserve Moshi's native full-duplex acoustic/overlap modeling. Choose it when modularity and application controls matter more than joint speech generation.
- **Purpose-built TTS adaptation:** more appropriate if the requirement is only a licensed voice/style or read-aloud output, rather than two-stream dialogue behavior. Do not adopt a 7B dialogue training stack merely for voice customization.

**Go/no-go:** study the multistream adaptation design now. A funded research pilot should first fix logging and validation, freeze compatible dependencies and model/data revisions, add input-contract and distributed tests, establish a recovery strategy, obtain dataset/voice permissions, and define base-versus-finetuned listening/behavior acceptance gates. Broad deployment is not justified by the evidence in this repository alone.

## Evidence and Verification Limits

All code conclusions above are source inspection, not executed reproductions. Only public code, documentation, metadata and text cards were acquired. No private data, user audio, accounts, paid endpoints, training jobs or live inference were used. External model/dataset cards are moving main-branch documents retrieved 2026-11-15, not frozen weights reviewed here. The lockfile-selected upstream source is inspected for architecture/loader context, not certified as safe or currently supported.

1. [README and documented examples](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/README.md)
2. [Training loop](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/train.py), [argument schema](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/args.py), [example configuration](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/example/moshi_7B.yaml)
3. [Model wrapper](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/wrapped_model.py), [mixed precision](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/mixed_precision.py)
4. [Dataset](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/data/dataset.py), [batch loader](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/data/data_loader.py), [interleaver](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/data/interleaver.py)
5. [Annotation](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/annotate.py)
6. [Evaluation](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/eval.py), [loss](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/loss.py)
7. [Metrics/logger](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/monitoring/metrics_logger.py), [state/seed](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/utils.py), [notebook](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/tutorials/moshi_finetune.ipynb)
8. Locked upstream Moshi: [LM](https://github.com/kyutai-labs/moshi/blob/061cc4c630d9e11722e08b7d02b1836ba58f30e8/moshi/moshi/models/lm.py), [LoRA](https://github.com/kyutai-labs/moshi/blob/061cc4c630d9e11722e08b7d02b1836ba58f30e8/moshi/moshi/modules/lora.py), [loaders](https://github.com/kyutai-labs/moshi/blob/061cc4c630d9e11722e08b7d02b1836ba58f30e8/moshi/moshi/models/loaders.py)
9. [Moshiko model card](https://huggingface.co/kyutai/moshiko-pytorch-bf16/blob/main/README.md)
10. [DailyTalkContiguous card](https://huggingface.co/datasets/kyutai/DailyTalkContiguous/blob/main/README.md)
11. [Checkpointing](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/finetune/checkpointing.py)
12. [Manifest](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/pyproject.toml), [lock](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/uv.lock)
13. [CI](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/.github/workflows/precommit.yml), [build action](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/.github/actions/moshi_build/action.yml), [contribution policy](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/CONTRIBUTING.md), [license](https://github.com/kyutai-labs/moshi-finetune/blob/2acc879fe7c48f885a18f6cc9548bccb2674d87b/LICENSE)
14. [Public metadata](https://api.github.com/repos/kyutai-labs/moshi-finetune), [releases](https://api.github.com/repos/kyutai-labs/moshi-finetune/releases)

---
**Attribution:** Kyutai / kyutai-labs/moshi-finetune, Apache-2.0 code; upstream Moshi and linked model/dataset authors retain their respective rights. This is independent analysis, not an upstream certification.
