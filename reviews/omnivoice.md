# OmniVoice (k2-fsa/OmniVoice)

**Repo:** https://github.com/k2-fsa/OmniVoice
**License:** Apache-2.0 code; pretrained model described as CC-BY-NC; bundled audio tokenizer has separate Boson Higgs Audio 2 Community License terms. Not an all-Apache commercial stack.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `4d5ed0f0621507e8aebd4560bde316549e85c553` (master); root README/LICENSE/manifest, model and audio utilities, inference/demo/batch CLIs, training/checkpoint modules, evaluation/training/language documentation, tests and workflows. Commit dated 2026-11-20; repository metadata last pushed 2026-11-23.
**Verification:** Static source and anonymous public metadata inspection only. No dependencies installed, source executed, models/audio downloaded, inference, voice cloning, device access or benchmark reproduction.
**Stack:** Python ≥3.10, PyTorch, Transformers, Hugging Face Hub, Higgs audio tokenizer, optional Whisper ASR, Gradio, Accelerate/WebDataset, optional PEFT and FlashInfer.
**What it is:** A massively multilingual, reference-conditioned speech generator with voice design and training tooling, best evaluated as a research TTS system rather than an authenticated streaming speech service.

---

## Verdict

⚠️ **Interesting for multilingual research; not a turnkey commercial or real-time service.** The implementation makes a compact Qwen-derived masked audio-token model unusually approachable, and its published language inventory is extensive. However, the model's noncommercial terms, the tokenizer's additional license, unproven per-language quality, non-streaming API and demo security boundaries are material adoption gates—not deployment footnotes.

## What It Is

OmniVoice, attributed to k2-fsa and the Xiaomi AI Lab Next-gen Kaldi team, generates 24 kHz speech from text with an optional reference recording/transcript or voice-attribute instructions. A 3–10 second reference is the authors' recommendation; omitting the transcript can invoke local Whisper. Saved voice prompts allow reuse without repeatedly encoding audio. These features require speaker authorization, not merely possession of a recording. [S1, S2]

The repository documents **646 languages and 581k training hours**, not 646 independently established production-quality voices. The inventory ranges from 206,061.1 English hours to 0.04 Haitian hours and 0.02 Macedo-Romanian hours. Voice-design training is Chinese/English only; authors warn of instability elsewhere, unreliable short unprompted clips, and Tai-lo-only Hokkien input. Evaluation recipes cover FLEURS' 102 languages plus other smaller suites, not exhaustive human evaluation of all 646. [S1, S3]

## Stack

| Layer | Tech |
|---|---|
| Speech generator | Qwen3-0.6B-derived Transformer; 8 audio codebooks; iterative masked-token prediction |
| Audio | HiggsAudioV2TokenizerModel; 24 kHz output; soundfile/librosa/torchaudio/pydub |
| Optional ASR | openai/whisper-large-v3-turbo through Transformers pipeline |
| UI / interfaces | Gradio demo, Python API, single and multiprocessing batch CLIs |
| Training | Accelerate, WebDataset, flex attention or SDPA; optional PEFT LoRA |
| Acceleration | Optional NVIDIA FlashInfer kernels and CUDA graphs |
| Storage / auth | Local files/checkpoints/cache; no application authentication configured in demo |

Dependencies have broad lower bounds in pyproject.toml; a uv.lock exists, but a generic pip installation is not equivalent to that locked environment. The uv configuration constrains torch/torchaudio to 2.8.0 with CUDA 12.8 wheels for Linux/Windows. [S4]

## Key Features

### Broad coverage with important quality caveats
Language IDs, voice attributes, pronunciation overrides, non-verbal tags and opt-in number normalization expose useful controls. The language table is a training-coverage disclosure, not evidence of equal intelligibility, prosody or speaker similarity. Require native-speaker review for the actual language, dialect, script, names and numbers before adopting it. UTMOS is predicted MOS, not a human listening panel; ASR WER/CER and embedding similarity have their own biases. [S1, S3]

### Voice reuse is also sensitive-data persistence
VoiceClonePrompt.save stores audio tokens, reference transcript and RMS in a torch file. Its loader explicitly uses weights_only=True and checks a format version—better than unrestricted pickle loading, but not proof that arbitrary files are safe or bounded. Tokens remain voice-conditioning data, not anonymization. No encryption, expiration, consent verification or revocation system was found in this path. [S2]

### Fast batch synthesis is not streaming latency
The headline RTF 0.025 is an author claim. The more specific README benchmark reports a single H100, fp16, 32 steps, Seed-TTS Chinese (2,020 samples, 3.3 hours): baseline batch-one RTF 0.0899; FlashInfer 0.0430; FlashInfer plus CUDA graph 0.0367; batch-eight FlashInfer 0.0115. The authors call outputs ASR-verified lossless; this review did not reproduce speed or perceptual equivalence. [S1]

The batch timer wraps generate(), excludes model startup and subsequent file writes, and allocates batch time across samples; aggregate RTF is not request latency or end-to-end server throughput. No first-audio latency distribution is established. generate() returns completed arrays; long-text chunking accumulates results before decoding/returning, rather than yielding audio to a client. Internal chunking therefore does **not** establish a streaming API. [S2, S5]

## Architecture

This is discrete diffusion-language-model-style iterative unmasking, not an autoregressive speech chatbot and not a conventional continuous waveform diffusion pipeline. The checked model config uses a 28-layer Qwen3 backbone with hidden size 1024. Audio embeddings from eight codebooks are combined with text embeddings; a projection predicts eight sets of 1,025 symbols (including a mask token). A duration estimate or requested duration sets the target frame count. [S2, S6]

Inference begins with masked target tokens, runs conditional and unconditional batches for classifier-free guidance, and progressively selects tokens using confidence, codebook-layer penalties and a time schedule. The explicit attention mask covers the whole valid segment; the Qwen configuration's CausalLM label should not be mistaken for token-by-token autoregressive generation here. Defaults are 32 steps, guidance 2.0, chunk threshold 30 seconds and target chunk duration 15 seconds. Unprompted long-form generation uses its first chunk as the reference for later chunks. The tokenizer decodes tokens and optional silence/fade processing finishes audio. [S2]

Training uses weighted codebook cross-entropy, packed flex attention or padded SDPA batches. Checkpoint helpers save Accelerate state and model/tokenizer artifacts; documentation distinguishes resume from pretrained initialization and offers LoRA fine-tuning. Those are useful research recovery primitives, not a durable inference job service. [S2, S7]

## Compute and Self-Hosting Notes

- **Size is not a VRAM guarantee:** Hub metadata lists 612,577,280 F32 parameters for the main model. Main safetensors is 2,450,344,112 bytes; bundled tokenizer weights are another 805,665,628 bytes (~3.26 GB combined downloads, before optional ASR). Main parameters alone would occupy approximately 1.23 GB at fp16, excluding tokenizer, activations, CFG duplication, runtime and ASR. No reliable minimum-VRAM matrix or CPU latency guarantee was established. [S6]
- **Hardware paths:** README documents CUDA, MPS and Intel XPU, with author-reported tests on 4 GB Arc A310 and 16 GB Arc Pro B50. That is not a universal 4 GB guarantee. The tokenizer is explicitly placed on CPU for MPS; optional ASR adds substantial memory and can be assigned another device. FlashInfer results require compatible NVIDIA/CUDA hardware. Training flex attention requires PyTorch ≥2.5 and a compatible GPU; SDPA is the fallback. [S1, S2, S7]
- **Offline is a prepared deployment:** the model resolver calls snapshot_download on a repo ID, without passing a pinned revision. If bundled tokenizer files are missing, it resolves bosonai/higgs-audio-v2-tokenizer separately; missing reference text may lazily resolve Whisper. Stage exact audited snapshots and dependencies, then use local paths and test denied network access. Do not assume passing revision downstream pins this custom resolver's earlier download. [S2]
- **Integrity:** the checked Hub snapshot is 3fc979d1cd72492cd679c5ac2611e0d7ac047ba1. Metadata advertises safetensors LFS hashes: main 730839316de585f4c8298ec0e1712efc10fb19c6fa4e36eb741cb8d51ebcf6aa; tokenizer fe7c5e8785e0a05833e1bfc3e002ec7f55af21e306b2e7154a448c1f54ccfb0d. These are published integrity references, **not hashes verified against downloaded weights**. No signed model attestation was established. Safetensors reduces pickle risk, not parser/dependency or provenance risk. The documented third-party mirror changes the supply-chain trust boundary. [S1, S6]

## Security, Privacy and Recovery

**Local versus hosted:** the inspected synthesis path performs local model inference rather than sending reference audio to a commercial TTS API. Model downloads still contact Hub infrastructure; optional libraries/UI and deployment settings were not network-audited. Hosted Spaces and Colab necessarily transfer data into third-party infrastructure. Their retention, logging, deletion and training-use policies were not verified; do not present them as equivalent to an offline local run. [S1, S2]

**Retention and consent:** Gradio receives reference files, output files can be cached by its runtime, and CLI output plus explicitly saved prompts persists on disk. The demo does not configure an application deletion schedule; DEBUG logging can include text, reference transcripts and chunked text. A deployment needs explicit consent scope, access control, encrypted storage where appropriate, bounded retention and deletion covering uploads, prompts, generated audio, logs and backups. The README's misuse prohibition is a policy statement, not technical consent enforcement or a speaker-ownership check. No watermarking or impersonation detection was established in the inspected generation path. [S1, S2, S8]

**Exposure and inputs:** demo defaults to 0.0.0.0, offers an optional public sharing link and launches without auth settings. Do not expose it directly: bind privately and add authentication, TLS, request/queue quotas and resource caps. Empty text and missing clone references are checked, but UI sliders are not a complete server trust boundary. The inspected application does not impose a comprehensive upload-byte/text-length/output-duration policy; long references with a supplied transcript are warned about rather than necessarily trimmed. Audio parsing crosses soundfile/librosa and potentially codec dependencies. [S2, S8, S9]

**Trusted batch manifests only:** batch output uses os.path.join(res_dir, save_name + '.wav') from the supplied sample ID without a containment check at the write site. Absolute/traversal IDs can direct writes outside the output directory; duplicate IDs can overwrite results. This is a static local-manifest finding, not a demonstrated remote exploit. Sanitize IDs, constrain reference paths and run with least filesystem privilege before wrapping this CLI in an upload service. [S5]

**Failure handling:** demo catches generation exceptions and returns their type/message, but prompt creation occurs before that try block. Internal details may reach clients and failures are not uniformly handled. Batch workers log per-future failures and continue; fatal paths kill the process group. No durable retry queue, per-item transactional output/manifest, resumable generation or guarantee of a failing exit for partial failure was established. Isolate the batch process group, inspect expected outputs, and implement job accounting rather than accepting a final “Done!” as completeness. [S5, S8]

## Licenses and Reuse

1. **Code:** root LICENSE is Apache-2.0; preserve notices and applicable attribution when reusing it. [S10]
2. **Main weights:** the exact Hub model card says pretrained weights are **CC-BY-NC due to training-data constraints (e.g. Emilia)**. It does not specify the CC version in that statement, and the listed model files lack a root standalone LICENSE. Obtain precise terms before redistribution; do not infer commercial permission from GitHub's Apache label. [S6]
3. **Tokenizer:** the bundled audio_tokenizer/LICENSE is the Boson Higgs Audio 2 Community License, incorporating Meta Llama 3 terms. It includes notices/display obligations, naming provisions, restrictions on improving other large language models and an expanded-license requirement above 100,000 annual active users. This is a separate, consequential dependency, not an Apache codec. Applicability and incorporated terms need legal review. [S11]
4. **Data and voice rights:** model documentation is not a complete per-record training-data rights or speaker-consent audit. Emilia is expressly cited as a noncommercial constraint; no blanket training-data reuse grant or clearance for a user's reference voice follows. Training your own checkpoint does not automatically resolve tokenizer or dataset terms. [S6, S7]

## Maturity and Verification

Anonymous GitHub metadata reported 17,183 stars, 2,520 forks and 81 open issues (snapshot 2026-11-27; counts are not quality evidence). Latest listed release was **0.2.1**, published 2026-07-16, tag ref 5ba967c4d5b0f08244ae856b033eea583d1e4517. The reviewed November source is newer despite pyproject still identifying 0.2.1; pin a commit, not just this version label. [S4, S12]

The tree contains tests/test_lora.py for adapter configuration, gradient behavior, save/resume and merging. The checked workflows are PyPI publication and stale-issue management: distribution metadata checking is not an inference-quality test gate. Ruff pre-commit configuration exists; no comprehensive continuous multilingual/audio/security suite was established. Tests, builds and benchmarks were **not run**. No listening tests, memory measurements, dependency vulnerability scan, host/network observation or service penetration test was performed. [S13]

Static verification checked source identity, model/config/license metadata, control flow, public accessibility, canonical deduplication and artifact markup. The paper is linked as author background, not represented as an independently reproduced evaluation. A production decision still requires rights clearance, target-language listening evaluation, measured warm/cold first-audio latency and peak memory, malformed-input tests, and deployment-specific privacy/security validation.

## Comparison

| Aspect | OmniVoice | Piper (OHF-Voice/piper1-gpl) | F5-TTS |
|---|---|---|---|
| Best starting use | Broad multilingual zero-shot research | Local fixed-voice speech engine | Reference-conditioned TTS research |
| Why consider it | 646-language inventory; voice design; reusable prompts | Fast local engine with espeak-ng phonemization and multiple interfaces | Alternative research implementation for reference-voice synthesis |
| Rights caveat | Apache code ≠ CC-BY-NC weights; separate tokenizer terms | Check engine and each voice's licensing | MIT code; author README says pretrained weights CC-BY-NC due to Emilia |
| Decision criterion | Validate target language and non-streaming latency | Prefer when a suitable licensed stock voice meets the need | Not an automatic commercial-license escape hatch |

Alternative descriptions are documentation comparisons, not head-to-head quality or speed measurements. Piper's initially checked older repository path was unavailable; the active public source used here is piper1-gpl. [S14, S15]

## Evidence and Provenance

All source retrievals were anonymous public HTTPS reads on 2026-11-27 UTC. Code citations are pinned to the reviewed source commit; model citations to the independently recorded Hub commit. No audio or model weights were acquired.

- **S1:** [README, features, limitations and author benchmark](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/README.md).
- **S2:** [Core model, prompt serialization, resolver, generation and chunking](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/omnivoice/models/omnivoice.py).
- **S3:** [Language inventory](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/docs/languages.md), [evaluation methodology](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/docs/evaluation.md), [tips](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/docs/tips.md).
- **S4:** [Package manifest](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/pyproject.toml).
- **S5:** [Batch inference and timing/write/error paths](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/omnivoice/cli/infer_batch.py).
- **S6:** [Pinned model card](https://huggingface.co/k2-fsa/OmniVoice/blob/3fc979d1cd72492cd679c5ac2611e0d7ac047ba1/README.md), [config](https://huggingface.co/k2-fsa/OmniVoice/blob/3fc979d1cd72492cd679c5ac2611e0d7ac047ba1/config.json), [file/size/LFS metadata](https://huggingface.co/api/models/k2-fsa/OmniVoice/tree/3fc979d1cd72492cd679c5ac2611e0d7ac047ba1?recursive=true), [model metadata](https://huggingface.co/api/models/k2-fsa/OmniVoice).
- **S7:** [Training docs](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/docs/training.md), [checkpoint helpers](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/omnivoice/training/checkpoint.py).
- **S8:** [Gradio demo and launch configuration](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/omnivoice/cli/demo.py).
- **S9:** [Audio loading and processing](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/omnivoice/utils/audio.py).
- **S10:** [Code LICENSE](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/LICENSE).
- **S11:** [Bundled tokenizer LICENSE](https://huggingface.co/k2-fsa/OmniVoice/blob/3fc979d1cd72492cd679c5ac2611e0d7ac047ba1/audio_tokenizer/LICENSE).
- **S12:** [Release 0.2.1](https://github.com/k2-fsa/OmniVoice/releases/tag/0.2.1), [public repository metadata](https://api.github.com/repos/k2-fsa/OmniVoice).
- **S13:** [LoRA tests](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/tests/test_lora.py), [workflows](https://github.com/k2-fsa/OmniVoice/tree/4d5ed0f0621507e8aebd4560bde316549e85c553/.github/workflows), [pre-commit config](https://github.com/k2-fsa/OmniVoice/blob/4d5ed0f0621507e8aebd4560bde316549e85c553/.pre-commit-config.yaml).
- **S14:** [Piper public README](https://github.com/OHF-Voice/piper1-gpl).
- **S15:** [F5-TTS README and license distinction](https://github.com/SWivid/F5-TTS).

---

**Attribution:** k2-fsa/OmniVoice; Han Zhu and collaborators; code copyright notices credit Xiaomi Corp. Code Apache-2.0; model and tokenizer terms differ as detailed above. This review is independent analysis, not an endorsement or reproduced benchmark.
