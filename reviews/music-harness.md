# Music Harness (enisn/music-harness)

**Repo:** https://github.com/enisn/music-harness
**License:** MIT code/docs/examples; bundled audio declared CC0 1.0, with provenance qualifications below.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** 0cdd996f96c1b590d16d8b9a1bb320fcccb560a7; main; whole repository, focusing on harness/, tools/, examples/, docs/, registry and license records.
**Verification:** Static review only. Python AST parsing and JSON/TSV inventory checks passed; no source imports, installation, rendering, playback, device access, model calls or optional sample fetches performed. The source clone includes its committed WAV assets; their audio was not decoded or auditioned.
**Stack:** Python 3.10+, NumPy, FFmpeg, JSON manifests, local WAV assets.
**What it is:** An offline, script-driven acoustic sample renderer for programmers and coding agents composing folk-inspired tracks and game cues—not a music foundation model, autonomous agent runner, DAW or prompt-to-song service.

---

## Verdict

⚠️ **Interesting — a compact composition toolkit, not yet a proven production mastering pipeline.** The registry, expressive sampling API and bundled provenance make this unusually approachable for code-first acoustic arrangements. Treat composition scripts as fully trusted programs, independently validate final encoded audio, and strengthen tests and asset provenance before commercial or unattended use.

---

## What It Is

Music Harness maps explicit notes and arrangement decisions in Python to recorded instrument samples, then mixes and exports audio locally. “AI-agent-friendly” means documentation and a callable API that an external coding agent can use; there is no bundled model, inference backend, conversational planner or model license. A human or separate agent still supplies the music and code.

The 35 registry entries include multisamplers, percussion kits, natural vocal phrases, ambient beds and three room responses. There are 140 committed WAV files totaling 102,438,624 bytes (about 97.7 MiB), each matched by path to a credits row in the static inventory. Several patches reuse the same recordings. As the README explicitly explains, names such as dombra, morin khuur and tsuur describe intended timbres: the recordings include nylon guitar, erhu, cello, bamboo flute and recorder, not necessarily those named traditional instruments. This distinction matters for cultural and acoustic authenticity claims. [1, 5, 6]

## Stack

| Layer | Tech |
|-------|------|
| Composition | Python Session API; beat-based phrases plus second-based hits, drones and ambience |
| Sampling | NumPy float64 stereo arrays at 44.1 kHz; zone selection and cubic pitch resampling |
| Mixing/mastering | Dry/wet buses, FFT EQ/convolution, gain adjustment and custom sample-peak limiter |
| Audio I/O | FFmpeg decoding, Vorbis/MP3 encoding, ebur128 measurements; Python wave for 16-bit WAV |
| Instruments | Built-in JSON registry plus recursively discovered custom JSON packs |
| Persistence | Composition scripts, manifests, samples and exported files; no database or job queue |
| Dependencies | numpy>=1.24; separately installed FFmpeg with libvorbis, libmp3lame and ebur128 |
| Service/auth | No web service, listener, account system or CORS layer in inspected code |

## Key Features

### An explicit, inspectable composition workflow

The documented sequence is doctor → list → verify → render a Python example → qc the result. Doctor checks Python/NumPy and FFmpeg encoder/filter availability. Verify instantiates all instruments; it does not compare measured pitches to reference targets despite printing “loaded and calibrated.” The eight-bar hello_steppe example and 48-bar Kâtibim arrangement demonstrate actual API usage rather than a hypothetical prompt interface. Both print QC, but neither is an assertion-based regression suite. [1–3, 7]

Session.phrase takes beat-position/duration events with velocity, glides and end falls. Other APIs use seconds; keep these units explicit when generating arrangements. Seeded randomness supplies repeatable timing and velocity variation within a fixed software/data environment. HitKit is described as round-robin, but pick actually chooses randomly with the supplied RNG and can repeat the same hit consecutively. [2, 4]

### Expressive samples without a model dependency

MultiSampler chooses a nearby pitch zone, resamples with a continuous pitch curve and applies envelopes, vibrato, damping and optional sustain extension. NaturalPhraseVoice caps upward shifts at +2.25 semitones and limits output to available recorded material; this is a practical guardrail, not formant-preserving time stretching. Pitch shifting changes playback speed, and the cubic interpolator has no explicit anti-alias low-pass stage. Large shifts and repeated sustain regions need listening tests. [3, 4]

### A local mastering and measurement loop

Exports combine a shared room response with EQ, approximate target-LUFS gain and a limiter, producing WAV/OGG/MP3 by default. Circular bus addition, convolution and EQ support loop-oriented work. These are useful building blocks, but neither “mathematically click-free” nor mastering-target compliance is established by the available evidence. [3]

## Architecture

The CLI dispatches to small modules. InstrumentBank merges the built-in registry with recursively discovered custom JSON, resolves sample paths and lazily caches decoded instruments. Session allocates full-length dry and wet buses, renders event clips and adds them into those buses. DSP performs whole-buffer transforms and file export; tools separately acquire and analyze new samples. There is no streaming audio engine or real-time playback component. [2–4, 8]

The design is readable and modest in size: the six harness modules plus three tools total 1,476 lines at this revision. However, memory scales with full track duration and intermediate FFT arrays. The two stereo float64 buses alone require about 84.7 MB per minute at 44.1 kHz, before samples, reverb, mix buffers and FFT scratch. Lazy caching avoids repeated decode per instrument instance but separate patches can decode the same underlying recordings again. [2–4]

### Correctness and quality findings

- **QC reports are measurements, not gates.** qc_audio_file does not reject the first FFmpeg command on nonzero return code, and parsing failures can leave loudness fields null. measure_lufs_buffer substitutes -18 LUFS when loudness is unavailable. Missing measurement can therefore become an ordinary gain decision rather than a hard failure. A second decode may still raise on unreadable input. [3]
- **Target LUFS and true peak are not guarantees.** Gain is bounded and applied before limiting; no iterative correction follows. The limiter controls discrete sample amplitudes, not oversampled intersample peaks. Export's returned QC covers only the intermediate/final WAV, not the OGG/MP3 files; lossy encoding can change peaks, length and seams. Measure each deliverable separately. [3]
- **Loop seam QC is insufficient by itself.** Seamless export applies roughly 4 ms fades at both ends, driving endpoint discontinuity toward zero but potentially creating a periodic level dip. The metric compares only first/last samples, not derivative continuity, surrounding waveform or perceptual smoothness. Circular convolution also truncates an IR longer than the loop rather than folding its full tail. These are static implementation observations, not measured audible defects. [3]
- **Input and failure handling are lightweight.** No comprehensive manifest schema or numeric range validation protects empty zones, invalid durations/BPM, malformed JSON or unusually short samples. NaN/Inf values are sanitized during mastering/WAV output, potentially masking upstream numerical trouble. [2–4]
- **Pitch calibration needs independent checks.** The analyzer uses harmonic-product-spectrum estimation and a local spectral refinement; the documentation itself warns about octave errors. No reference-tone error distribution or instrument-by-instrument tuning report is supplied. [8, 9]

### Execution authority and security

Render calls runpy.run_path on the supplied Python file: this is arbitrary code execution with the invoking user's filesystem, environment, network and subprocess permissions. It is not a sandboxed score format. Do not expose it directly to untrusted users or let an agent render unreviewed generated code on a credential-bearing host. The repository's agent documentation is guidance, not enforcement. [2]

Custom JSON is data rather than Python, but it can overwrite built-in instrument IDs and reference absolute or parent-relative paths without containment checks. All custom JSON is loaded during bank construction; one malformed pack can disrupt discovery. FFmpeg is invoked with argument arrays rather than shell interpolation, which is good, but inputs are still trusted decoder inputs with no subprocess timeout or general resource limit. Keep FFmpeg patched and isolate untrusted media. No network listener means web authentication is not the immediate issue; local execution authority is. [2, 3]

### Privacy, provider egress and cost

The inspected core renderer has no model-provider client, telemetry or intentional upload path. With local inputs, rendering needs CPU, RAM and disk rather than an API subscription or GPU. This does not constrain arbitrary composition Python, which can perform any network operation its environment permits.

Optional acquisition tools introduce external traffic: VCSL search/download contacts GitHub's API and download URLs; Freesound search/download sends queries, sound IDs and an API token to Freesound, then fetches HQ MP3 previews and converts them to WAV. The token is read from an environment variable or a user token file and placed in URL query parameters; avoid logging such URLs and enforce file permissions externally. Converting a lossy preview to WAV does not restore original recording fidelity. No payment API is present, but provider terms/rate limits, network transfer and any separately chosen coding-model charges remain external concerns. [8]

### Persistence and recovery

There is no checkpoint/resume protocol, job ledger, saved Session object or automatic QC report file. A failed render generally means rerunning the script; reproducibility requires preserving scripts, seeds, registry, sample bytes and dependency/tool versions. Export writes final-named files directly and FFmpeg uses overwrite mode. Failure between formats can leave a partial set, and a WAV is written even when not requested (then removed after QC). Use unique output directories and external atomic promotion after validation. [2, 3]

VCSL's downloader treats any existing file as cached without checksum verification; an interrupted partial download can therefore be reused. Neither downloader implements resumable transfers, retry/backoff or immutable source pinning. Freesound appends credits after successful conversion, while VCSL provenance must be added manually. Repeated Freesound fetches can duplicate credits. [8, 9]

## Licenses and provenance

The MIT license names Enis Necipoglu (2026); preserve its notice for substantial code reuse. The project declares its built-in audio CC0 1.0 and provides 140 per-file credits. Path completeness is independently checked here; upstream ownership and each license grant are not. The asset document says Freesound licenses were rechecked on 2026-11-26, but also acknowledges six source matches inferred from names and durations (two flutes, hooves and three room responses). That is weaker chain-of-custody evidence than original download records plus hashes. Recheck those sources before relying on the blanket commercial-use claim. [5, 6]

The analyzer's default license label is CC0; it does not establish rights in input audio. InstrumentBank does not enforce license fields. Freesound's downloader checks the returned license string; VCSL assumes the selected repository's CC0 status rather than verifying each download. Custom packs require their own provenance. MIT code plus CC0 samples do not automatically clear an external melody, arrangement, recording, performer or personality right; the Kâtibim example's musical-rights position was not independently assessed. No model weights or model license apply to this repository. NumPy and the chosen FFmpeg build retain their separate dependency licenses, including build-dependent FFmpeg obligations if redistributed. [5–9]

## Maturity and Verification

Anonymous GitHub metadata on 2026-11-26 showed a public repository created that day, last push 2026-11-26T17:32:42Z, two stars, zero forks and zero open issues. The releases endpoint and all-state issues query returned empty arrays. The inspected commit is dated 2026-11-26T17:32:40Z; no published release was available. These are a snapshot, not evidence of quality or future maintenance. [10]

The tracked tree contains no automated test suite, GitHub Actions workflow, dependency lockfile or packaged pyproject. Requirements specifies only numpy>=1.24. Documentation and examples are useful, but there are no checked regression baselines for pitch, loudness, clipping, seam behavior, deterministic renders, malformed manifests or interrupted export.

Review checks: parsed all 11 Python files with the standard-library AST parser without importing or executing them; parsed the registry; counted 35 entries and 140 WAVs; confirmed all WAV paths appear in 140 TSV credit rows; inspected CLI, core implementation, tools, examples, documentation and license files. These checks passed. No runtime tests, doctor/verify commands, sound-quality listening, performance measurement, dependency audit or original-source license verification were performed. No optional media/model downloads or paid calls were made; bundled media arrived with the repository clone only.

## Comparison

| Aspect | Music Harness | Alternatives |
|--------|---------------|--------------|
| Code-first offline acoustic cues | Small Python API with bundled folk-oriented palette | Csound or SuperCollider offer broader synthesis/DSP environments but need more audio-language and instrument design work |
| Hands-on arrangement and mixing | Python source is the score; no timeline or mixer UI | Ardour offers a full DAW workflow; more setup and less naturally script-centric |
| Sample-instrument playback | Custom JSON zones and limited articulation engine | sfizz/SFZ provides a richer established sampler format, but needs suitable instruments and a host/workflow |
| Direct sample access | Curated transformations plus a credits table | VCSL directly is useful if only raw CC0 samples are needed, without adopting this renderer |

These are architectural fit comparisons, not executed head-to-head benchmarks or endorsements of particular releases. None requires replacing this project with a paid service. Prefer this repository for inspectable short-form prototypes; choose a mature audio engine/DAW when production mixing, broad articulation support or established validation matters.

## Self-Hosting Notes

There is no server to deploy. In a disposable, nonprivileged environment, pin a source revision and NumPy/FFmpeg versions; ensure required encoders and ebur128 exist. Keep approved samples and composition scripts immutable, restrict network access for rendering, and use separate output directories. Run prerequisite and instrument-loading checks only after reviewing code. Before shipping, render reference tones and boundary cases, enforce numerical/QC thresholds, decode and inspect every final format, and listen for tuning, aliasing, transient and loop artifacts. Add atomic exports and recovery checks before unattended batches.

## Evidence

All repository citations below are pinned to the reviewed commit.

1. [README](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/README.md).
2. [CLI](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/harness/__main__.py), [registry loader](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/harness/library.py), [Session](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/harness/session.py).
3. [DSP and export](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/harness/dsp.py).
4. [Samplers](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/harness/samplers.py).
5. [Code license](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/LICENSE), [asset license/provenance statement](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/LICENSE-ASSETS.md).
6. [Credits](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/instruments/CREDITS.tsv), [registry](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/instruments/registry.json).
7. [Examples](https://github.com/enisn/music-harness/tree/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/examples).
8. [Acquisition and analysis tools](https://github.com/enisn/music-harness/tree/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/tools).
9. [Instrument guide](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/docs/ADDING_INSTRUMENTS.md), [composition cookbook](https://github.com/enisn/music-harness/blob/0cdd996f96c1b590d16d8b9a1bb320fcccb560a7/docs/COMPOSITION_COOKBOOK.md).
10. [Public metadata](https://api.github.com/repos/enisn/music-harness), [releases](https://api.github.com/repos/enisn/music-harness/releases), [issues](https://github.com/enisn/music-harness/issues) (mutable snapshot).

---

**Attribution:** enisn/music-harness, Enis Necipoglu; MIT code and project-declared CC0 1.0 bundled assets. This review is independent analysis, not a license warranty.
