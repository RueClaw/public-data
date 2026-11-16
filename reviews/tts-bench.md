# TTS Bench (5uck1ess/tts-bench)

**Repo:** https://github.com/5uck1ess/tts-bench
**License:** MIT for benchmark code; models, checkpoints, reference recordings and provider outputs require separate rights review.
**Reviewed:** 2026-11-16 (UTC)
**Revision:** 06df9001f0ed4f3d82b0239c989777eef7b9499c, master; benchmark harness, representative runners, scoring, hosted collector, arena, installers, publication and CI.
**Verification:** Static review plus independent parsing/counting of committed result records. No upstream tests, installs, model runs, audio listening, device access or provider requests.
**Stack:** Python, per-model virtual environments, PyTorch/ONNX/MLX/native backends, FastAPI, SQLite/Turso, static HTML.

## Verdict

⚠️ **Interesting — a useful audition workbench, not a definitive TTS ranking.** The project genuinely combines hardware-specific timings, listenable samples, automatic failure signals and human preference collection. Its six-prompt coverage, inconsistent cold-start semantics, private NAQ evaluator and unresolved voice/provider rights make it a shortlist generator rather than sufficient evidence for a deployment or a “best model” claim.

## What It Is

This is an independent benchmark and sample-publishing system, not a speech model or one uniform inference engine. The README tracks 102 local model/engine variants and a separate 28-product hosted API board. Per-model environments handle incompatible dependencies; adapters emit JSON timing records and WAVs. Reports offer speed, listening and scoring views. A separate public arena collects default-voice and cloning preferences.

The distinction between model and implementation matters: Audio8 stock and compiled paths compare engines; Drama 3 measures a third-party ComfyUI port; Higgs v3 uses an already-running server; Mac paths can use different quantization and runtimes. These are useful product configurations, not controlled architecture-only comparisons. [README.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/README.md), [harness.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/harness.py).

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Orchestration | bench.py → harness registry → per-cell subprocess → JSON lines |
| Inference | Model-specific runners and virtual environments; local and server-backed exceptions |
| Artifacts | results.csv, meta.json, generated WAVs; merge/report/publish scripts |
| Quality | Whisper-large-v3 WER, UTMOS, WavLM/UniSpeech speaker similarity, deterministic health checks |
| Human preferences | FastAPI arena, signed pair nonces, adaptive pairing, SQLite or Turso vote log, replayed Elo |
| Hosted collection | httpx/WebSocket adapters, encrypted Windows key cache, public/private sidecars |

This separation is practical: dependency failures stay largely model-specific and published failures need not disappear silently. It is not security isolation: runners inherit host environment and filesystem authority. The CPU path hides CUDA to counter libraries that ignore requested devices, but that is a measurement guard, not a sandbox. [harness.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/harness.py).

## Evaluation Methodology

### Six authored prompts are not a multilingual benchmark corpus

The actual corpus is four English assistant/coding sentences, one French introduction and one Spanish sentence. It includes short commands, a longer ASR-themed paragraph and code spoken as words. There is no Chinese test despite many Chinese/English models, no broad accents, dialogue, long-form narration, noisy-reference matrix or representative speaker demographic coverage. Expressive-control features are catalogued but explicitly not exercised by the plain prompts. Languages supported by a model card are distinguished from languages enabled in its runner, which is a good practice. [bench.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/bench.py), [README.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/README.md).

Default presets differ by model and sometimes language. Reference-only models use a house reference, so “default” does not necessarily mean a native preset. Local cloning chiefly uses one celebrity reference; hosted cloning uses a different recording described by the author as consented, with different accepted cut lengths per provider. That is a defensible product-as-sold comparison, not an equal-reference-duration experiment, nor evidence about unseen speakers. Local and hosted cloning SIM should not be compared directly. [docs/cloning.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/docs/cloning.md), [docs/hosted.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/docs/hosted.md), [scripts/hosted/core.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/core.py).

### Automatic scores measure different things

- **WER:** jiwer edit-distance WER after English Whisper normalization or lighter French/Spanish punctuation normalization. The direction is correct: lower is better; insertions can produce values above 1. Whisper errors are not necessarily TTS errors, and lexical accuracy is not naturalness. The direct feature-extractor/generate path does not implement explicit long-audio chunking; normal short prompts are the intended use, but long/runaway output needs special validation rather than assuming all speech was evaluated.
- **SIM:** cosine similarity between normalized reference/output speaker embeddings. This is a speaker-verification proxy, not proof of voice consent, intelligibility, expression or human likeness. Using seed-tts-eval-style encoders does not make six custom prompts comparable to the paper's dataset scores.
- **UTMOS:** a learned reference-free MOS predictor, not a collected human MOS. Resampling to mono 16 kHz means high-frequency fidelity is not evaluated at original bandwidth. Domain/language calibration and fine-grained preference accuracy are not established here.
- **Health:** clipping fraction, whole-clip RMS and interior silence thresholds catch obvious defects; an empty flag is not a quality certificate. The implementation intentionally avoids flagging ordinary speech transients as clicks.
- **NAQ:** published predictions of preference against a typical bench clip, trained on arena votes. Training code, weights and full validation methodology are private. The claim that it agrees with held-out listeners much more often than UTMOS is an author claim, not independently reproducible evidence. Do not read 80 as “80% of people voted for this model.”

Evidence: [scoring/wer.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/wer.py), [scoring/sim.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/sim.py), [scoring/utmos.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/utmos.py), [scoring/health.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/health.py), [docs/methodology.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/docs/methodology.md).

The publisher takes means over available selected clips and skips missing metric cells. These are macro means, not pooled word-count WER; English-only and multilingual rows can cover different prompt sets. One displayed count is not necessarily each metric's denominator. Local selected clips and hosted three-take sets also have different replication. Report language-stratified scores, per-metric counts and failure rates before interpreting small rank differences. [publish.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/publish.py).

### Human votes are valuable, but the evidence is narrow

The arena randomizes sides and biases pairing toward undersampled and similarly ranked models. Ties count as half a win; “both bad” is excluded from Elo, so ranking does not itself reflect absolute unusability. Live Elo is sequential with K=24, not the Bradley–Terry fit described for the frozen historical table. No confidence intervals or rater-cluster uncertainty accompany that table. Its stated 397 votes are not 397 independent listeners, and individual rows have only 10–28 games.

The UI is blind for ordinary listeners, but a 302 redirect leads to model-named public media; a motivated voter can inspect identity. Playback and dwell are client assertions. Nonces, replay rejection, rate limits and token flagging help, but persistent self-issued tokens do not establish unique humans. Turnstile outages explicitly pass the clean gate, and the source acknowledges spoofable forwarded-IP inputs. Those tradeoffs weaken claims of research-grade ground truth; they do not make the votes worthless. [arena/app.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/arena/app.py), [arena/pairing.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/arena/pairing.py), [arena/elo.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/arena/elo.py), [docs/cloning.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/docs/cloning.md).

The prosody report is commendably explicit that silence-segmented human reference material is not matched human readings of the test prompts and cannot establish a human-versus-synthetic direction. Its F0 contours are descriptive, not a validated replacement for listening. Draft PR #53 discusses a vote-based follow-up, but is not part of this reviewed commit. [docs/prosody-report.md](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/docs/prosody-report.md), [PR #53](https://github.com/5uck1ess/tts-bench/pull/53).

## Speed: Useful Numbers with Important Boundary Errors

**RTFx is implemented correctly as audio seconds / generation seconds**, the reciprocal of conventional RTF. The CSV field is named rtf, which can confuse downstream consumers. Extra silence or repetition can inflate duration and apparent speed; cross-check WER, audio health and listening.

**“Cold” is not deployment cold start.** The default is three generations in one subprocess per model/device/prompt: index 0 is labeled cold and indices 1–2 warm. Representative runners load the model before starting the generation timer. AuroraTTS even runs an untimed warm-up before run 0. The harness stores total subprocess wall time, but that includes loading plus all generations, not a clean startup-to-first-playable-audio measurement. The methodology's restart-experience description is therefore too strong. [bench.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/bench.py), [harness.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/harness.py), [runners/auroratts_runner.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/runners/auroratts_runner.py).

**TTFA is adapter-specific.** Nonstreaming Aurora reports full generation latency; Kokoro records its first yielded audio before conversion to CPU NumPy. There is no universal synchronization/playable-buffer contract across backends, no standard chunk size or underrun measurement, and no playback-device latency. Streaming first chunk, first non-silent speech and full waveform completion are different quantities. Sampled runners should be audited individually before treating millisecond differences as hardware truth. [runners/kokoro_runner.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/runners/kokoro_runner.py).

**Memory names overclaim.** The shared peak_mem_mb helper actually samples current process RSS after generation, not peak RSS. CUDA memory is PyTorch maximum allocated tensor memory, not full device residency or external-server usage; CPU/MPS and other runtimes can return blanks. These are useful hints, not capacity guarantees. [runners/_meminfo.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/runners/_meminfo.py).

Per-rig tables prevent a 5090 being silently ranked against an M4. However, two warm repetitions, fixed execution order, unequal kernels/precision/threads, model-specific warm-up and missing software/weight fingerprints in meta.json leave variance and reproduction gaps. No concurrency/load test, p99 local latency or run-to-run confidence intervals are established. The broad assertion that samples are hardware-independent is also too strong: precision, runtime, kernels and stochastic sampling can change audio, not merely speed.

### Hosted timing is more carefully sampled, but documentation has drifted

The actual speed sampler warms a connection and measures three calls of the **same English prompt 2**, alternating transports where supported. It does not implement the draft's promised per-prompt p1/p3 sweep. The page filters successful warm speech-onset samples, reports median/p90 and errors, and can fall back to marked warm sweep samples. Cold reconnects and successful responses without detectable onset do not enter the warm median. That is not end-to-end user latency or a reliability-adjusted service score. [scripts/hosted/speed_sample.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/speed_sample.py), [scripts/hosted/page.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/page.py).

The PCM speech metric finds the arrival chunk containing the first sample above −40 dBFS: better than awarding credit for headers or leading silence, but a loud transient is not necessarily speech, and chunk arrival is not speaker playback. The helper does not provide byte-offset onset timing for MP3. Vendor pacing makes total delivery time/RTFx different from backend compute throughput. Regional network and vendor queue conditions remain part of these numbers; there is no basis to subtract a simple RTT and declare pure model latency. [scripts/hosted/core.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/core.py).

## Independently Checked Evidence and Reproducibility

A reviewer-written, standard-library-only parser counted the committed text records without importing repository code:

| Artifact | Count at reviewed SHA | Meaning |
|---|---:|---|
| hosted/speed/samples.jsonl | 1,316 rows, 28 slugs, 18 error rows | Recorded calls dated November 1–4, 2026; not an independent rerun |
| scoring/scores.csv | 2,034 rows | Includes multiple rigs/modes, not 2,034 independent prompts |
| scoring/hosted_scores.csv | 834 rows | Multiple takes and lenses |
| scoring/naq_scores.csv | 567 rows | Only prompt IDs 1–4 |
| test_*.py files | 27 | Inventory, not executed/passing-test count |

Local score rows by prompt were 441/439/436/436/210/72 for IDs 1–6; hosted rows were 147/147/147/147/120/126. The imbalance is concrete evidence against assuming equally populated language coverage. None of these counts authenticates the audio, scorer outputs or provider identities.

The source commit pins this review, not every upstream dependency or historical benchmark. Scores are keyed by directory and WAV filename, with no audio/scorer hash in the local score schema. Incremental scoring skips existing keys; even rescore merges preserve old nonblank values when a new metric fails. Replacing a WAV at the same path can therefore retain stale or mixed-generation scores unless the operator deliberately invalidates them. Hosted sidecars improve provenance with truncated content hashes, model ID, voice/settings, time and connection state, but ID-sent is not proof of the provider's actual served checkpoint. [scoring/scores_io.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/scores_io.py), [scoring/score_all.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/score_all.py), [scripts/hosted/core.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/core.py).

Documentation is not synchronized: results.md is explicitly May-era with five prompts and older license/configuration entries; cloning.md retains older model/vote counts; hosted.md is a draft with separation and timing statements superseded by code and the README. Prefer exact source and dated artifacts over mixing their headlines.

## Security, Privacy, Retention and Costs

- **Local does not mean offline by default.** Installers and first loads fetch packages, upstream code, model weights and tokenizer/scoring assets. Some runners talk to local HTTP inference servers. Inference and dependency code have the invoking user's environment, files and potentially cached Hub credentials. Per-model venvs are compatibility boundaries, not secret isolation.
- **Hosted calls transmit text and, for cloning, reference audio/transcripts or persisted vendor voice IDs.** Requests may route through an intermediary, such as OpenRouter. Provider retention/training/deletion terms remain separate; no global deletion or data-residency guarantee is implemented.
- **Key storage is better than plaintext but strongly environment-specific.** The collector reads a configured password-manager item and caches its fields under Windows DPAPI. The normal disk freshness window is 12 hours, but unattended speed sampling explicitly permits stale cache; this is not credential expiry or revocation. Public sidecars include short key fingerprints, not keys. No credential was read during this review.
- **Public/private logging is useful, not a general redaction guarantee.** Successful public sidecars omit full request bodies/headers; private logs retain text, headers and request details after heuristic scrubbing. Error paths can place truncated vendor response text in public error fields. Audit failures as well as success metadata before publishing sensitive material. The scrubber omits bytes and strings over 4,000 characters, not every possible secret field.
- **Audio publication is an intentional boundary crossing.** Local cloning copies the reference into run artifacts for an A/B player. Generated WAVs, references and reports can become permanent public Git history; removing a working file does not revoke downstream copies. Use only explicitly publishable material.
- **Arena visitors generate persistent pseudonymous data.** Vote records include voter/session tokens, user agent, time, salted IP hash and choices; hosted deployments use Turso, Turnstile and GitHub-hosted audio. CSV export can include rater tokens/full schema. No automatic retention window or user erasure workflow was found in the reviewed paths. Token flagging excludes votes and rebuilds rankings; it does not erase them.
- **Recovery is partial.** Append-only vote logging and Elo replay support recalculation; exported CSV aids audit. They do not prove backup/restore readiness. Collector clone IDs are cached by slug/cut rather than reference-content hash; changed audio requires intentional recreation. Multi-file WAV/JSON writes and score CSV replacement are not transactional, and reruns can remove prior output before a replacement succeeds.
- **Costs extend beyond API synthesis.** README estimates roughly 165 GB for a complete local setup; GPU/RAM/electricity and scorer downloads add operational cost. Hosted sweep prices are author estimates, not a spending ceiling. Warmups, retries, cloning charges, minimum top-ups and region/plan-specific tariffs matter. Byte/time guards bound individual responses, not total currency spend.

Evidence: [bench.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/bench.py), [scripts/hosted/keys.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/keys.py), [scripts/hosted/core.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scripts/hosted/core.py), [arena/db.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/arena/db.py), [arena/export_votes.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/arena/export_votes.py), [arena/config.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/arena/config.py).

## Installation Trust and Rights

Installers contain a mix of pinned packages/Hub commits and floating package names/Git clones; there is no single resolved lock covering every backend. Aurora is a good example of pinned remote-code revision, but scoring UTMOS loads a mutable torch.hub repository with trust_repo=True. SIM temporarily bypasses the Hub trust prompt, and representative runners permit remote Python code or pickle-capable torch.load. Pinning reduces drift; it does not remove the need to trust the code/checkpoint publisher. Do not run the all-model installer in a credential-rich workstation merely to inspect this project. [install.sh](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/install.sh), [install.ps1](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/install.ps1), [scoring/utmos.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/utmos.py), [scoring/sim.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/scoring/sim.py), [runners/vibevoice_runner.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/runners/vibevoice_runner.py).

The actual LICENSE grants MIT for bench code only despite GitHub's generic “Other” classification. Model terms include permissive, GPL, noncommercial and custom licenses; datasets, reference recordings and outputs are not automatically covered by that MIT grant. The Coqui runner sets COQUI_TOS_AGREED by default, so an operator must review its terms before execution rather than treating the script as consent. [LICENSE](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/LICENSE), [runners/coqui_runner.py](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/runners/coqui_runner.py).

The local celebrity voice reference lacks an established consent grant in the reviewed evidence. Hosted documentation explicitly recognizes that it cannot attest to celebrity consent and instead describes a consented recording. That is not a transferable voice license for everyone who clones the repository. More seriously, hosted.md records several vendors' benchmarking restrictions and an author decision to publish and remove on objection. Removal-on-objection is not prior permission. Independently verify provider terms and rights before reproducing or redistributing the samples; no legal conclusion or copied audio is provided here.

## Maturity and Verification Limits

Public GitHub metadata on the review date showed 467 stars, 13 forks, last push November 14, 2026, no published releases, and two open issue/PR records. Popularity is not correctness evidence. CI installs developer dependencies, runs pytest, compiles sources and runs a narrow correctness-oriented Ruff ruleset. Actions use version tags rather than immutable SHAs. pytest's configured discovery includes arena/tests and scoring/tests, but not tests/test_prosody.py or scripts/hosted/tests by default; important files can exist without being exercised by that command. [.github/workflows/ci.yml](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/.github/workflows/ci.yml), [pyproject.toml](https://github.com/5uck1ess/tts-bench/blob/06df9001f0ed4f3d82b0239c989777eef7b9499c/pyproject.toml).

No source code was executed, no test pass is claimed, and no advisory audit was performed. Audio files, datasets and model weights were not downloaded. The static review sampled representative runners rather than proving all 102 paths. The live arena was not probed, its votes were not exported, and the private NAQ system was not accessible. Author measurements and listening opinions remain author evidence.

## Comparison and Practical Use

| Option | Better fit | Tradeoff |
|---|---|---|
| TTS Bench | Auditioning many local/product configurations and seeing hardware-specific failure modes | Tiny authored corpus; incomplete reproducibility and rights controls |
| [seed-tts-eval](https://github.com/BytedanceSpeech/seed-tts-eval) | Dataset-based zero-shot WER/SIM evaluation | Its README specifies 1,000 English and 2,000 Mandarin samples; still needs human listening and separate runtime benchmarking |
| Controlled human A/B or MOS study on consented, application-matched material | Selecting a voice for a real audience, language and task | Requires recruitment, randomized presentation, rater QC and uncertainty analysis |

Use the gallery to choose a small set, then pin exact engines/weights, confirm rights, and test your own consented speaker/language/task matrix. Measure model-load-to-first-playable-audio separately from warm streaming, record underruns and concurrency, stratify failures, and report variance. Require content-addressed score invalidation and explicit artifact-publication review. The project is worth studying and selectively running; its headline winner is not a substitute for that acceptance process.

---

**Attribution:** 5uck1ess/tts-bench; benchmark code copyright Tym Rabchuk, MIT. This review is independent analysis, not an endorsement or redistribution of voices/models.
