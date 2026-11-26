# Ableton PyTheory (kennethreitz/ableton-pytheory)

**Repo:** https://github.com/kennethreitz/ableton-pytheory
**License:** MIT extension code; separately licensed SDK, runtime and dependencies. Preserve copyright/license notices.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** abfb9dd66462565308950bb1a7ed119049afcd71 (main / tag v0.5.0); scope: README, license, manifests, build, all src modules, tests and release metadata.
**Verification:** Static source review only; no installation, source execution, DAW access, audio playback or personal project access. Tests were inspected, not run.
**Stack:** TypeScript, Python, Ableton Extensions SDK, Node, Pyodide/WASM, NumPy/SciPy, abcjs.
**What it is:** A context-menu composition and analysis extension for extension-capable Ableton Live builds, running actual PyTheory locally rather than calling a music-generation service.

---

## Verdict

⚠️ **Interesting — substantial musical tooling, but trial only in disposable Sets.** The implementation goes well beyond a wrapper: it joins MIDI analysis, harmony/groove transformations, generation, notation and audio processing to Live's data model. Beta SDK access, broad child-process authority, a concrete notation script-injection boundary and incomplete failure recovery prevent a deployment recommendation without hardening and host-level testing.

## What It Is

Kenneth Reitz's extension registers actions for MIDI clips, empty clip slots, scenes, audio clips, samples and Simpler. Most computation happens in a bundled Python interpreter; TypeScript owns dialogs and Live mutations. This is neither a VST/AU nor a Max for Live device, and it is not an LLM or cloud service. There is no system-Python requirement at runtime. [E1–E4]

The reviewed main commit is tagged **v0.5.0**, with package/manifest version 0.5.0 and PyTheory source requirement 0.59.0. The latest published GitHub Release observed was **v0.4.2**, published 2026-11-08, pointing to commit e37f96be4716a4982343752ca71f17aaacdb0909 and bundling PyTheory 0.58.0. Its downloadable .ablx is therefore not evidence that the new 0.5.0 features have shipped as a release asset. Main's commit date is 2026-11-26; the API reported 29 stars, 0 forks and 0 open issues, context rather than quality evidence. [E1, E8]

## Stack

| Layer | Tech |
|-------|------|
| Host integration | Ableton Extensions SDK 1.0.0-beta.0; API/minimumApiVersion 1.0.0 |
| Extension | TypeScript strict mode, esbuild; Node >=24.14.1 |
| Musical engine | PyTheory 0.59.0 source files staged into Pyodide's virtual filesystem |
| Runtime | Lockfile Pyodide 314.0.0; bundled NumPy, lazy-loaded SciPy |
| UI/notation | Local webview HTML, abcjs 6.6.3; ABC and LilyPond export |
| Persistence/auth | Live Set and project imports, host temp/storage files; no app accounts or server |

## Key Features

### Useful composition operations, not just labels

Key/scale suggestions, chord symbols and Roman numerals, harmonic functions, borrowed chords, secondary dominants, cadences and scale recommendations are implemented. Melody analysis and chord-continuation rankings sit alongside guitar-family fingerings. Generation includes Roman numerals and chord symbols, slash basses, voiced/rhythmic progressions, scales, ragas, drums, Euclidean rhythms, melodies, basslines and four-track song sketches. Transformations include harmonize, arpeggiate, strum, seeded humanize, scale conform, diatonic transpose, voice leading, chordify, inversion, retrograde, negative harmony and reharmonization. [E2, E3]

### Musical inference has specific limits

MIDI key detection discards repetition and duration by deduplicating pitch-class names before calling Key.detect. Its fitness ranking is not calibrated confidence. Chord detection groups onsets within **0.125 beats** of the cluster start, rather than maintaining a time-varying harmony from sustained notes; arpeggiated or heavily strummed material can fragment. Continuation statistics are counted from the built-in PROGRESSIONS dictionary, including cyclic last-to-first transitions, not a verified large recording corpus. [E3]

Set-scale mapping can choose a containing scale or fall back to major/minor; it does not guarantee that an exotic Live scale survives unchanged. Raga-to-MIDI generation should not be mistaken for a complete model of raga performance or microtonal ornamentation. These are helpful composition heuristics, not authoritative musicological analysis. [E3, E6]

### Audio and notation expand scope, with tradeoffs

Audio commands call PyTheory's WAV pitch/chord/tempo analysis and transcription, including optional part splitting; this is not evidence of reliable full-mix stem separation. WAV clips are read by underlying file path, while non-WAV arrangement clips use pre-FX rendering. The direct-WAV path does not pass trim/warp boundaries, so analysis can describe the source file rather than exactly what the clip plays. Sample tuning reports the required transpose; it does not automatically retune the device. [E2, E3]

Synth rendering and effect processing create new audio tracks and import WAV files. The extension monkey-patches a private SciPy STFT helper for WASM memory constraints, a version-sensitive maintenance point. Notation splits overlapping notes into at most eight voices and skips additional simultaneous voices; exported notation is not necessarily lossless. No audio accuracy, latency, long-file memory use or engraving fidelity was measured. [E2, E3]

## Architecture

The entry module initializes the SDK, eagerly starts the Python runtime, and binds commands to typed Live objects. Requests travel as JSON to a worker thread, or to a spawned Node child when worker construction is denied by the managed host. The worker loads staged Python sources and dispatches named analysis functions. Audio input is copied from a host path into a fixed virtual WAV path; rendered PCM returns as base64. Dialogs return JSON, and the extension applies results through Live's APIs. [E2–E5]

The separation is understandable and useful, and pure scale helpers plus the standalone Pyodide test harness improve inspectability. It is still a sizeable monolithic adapter: roughly 3,000 lines of Python analysis and 3,100 lines across extension/dialog modules. The external PyTheory source version is checked by its version string, not a content hash; same-version modified sources can still be bundled. [E3–E7]

### Authority, auth, network and privacy

- **No remote auth surface found:** no HTTP server, CORS policy, user login, API key or telemetry call was found in the inspected extension source. Local host admission and trusted extension installation are the relevant authority boundary, not web authentication.
- **Offline runtime is an intended packaging property, not proof of isolation:** build.ts downloads missing NumPy/SciPy wheels from jsDelivr, and npm dependencies require acquisition. Runtime loads staged assets locally; complete packaged offline behavior was not tested. The build chooses wheel filenames from the Pyodide lock but does not itself compare downloaded bytes with a digest. [E4, E7]
- **WASM is not the whole sandbox:** child fallback inherits the host environment except NODE_OPTIONS and explicitly requests unrestricted filesystem read/write and child-process permission. Host-side code reads supplied audio paths. The TypeScript function union is not a runtime allowlist; the worker resolves function names through Python globals. These are internal IPC paths, not an observed remotely reachable exploit, but dependencies and webview messages must be trusted accordingly. [E4]
- **Concrete notation injection concern:** the clip name becomes a notation title; PyTheory 0.59.0 places that title directly in the ABC T: field. dialogs.ts embeds the resulting ABC using JSON.stringify inside an HTML script element. JSON quoting does not escape an HTML closing-script sequence, so a crafted title can terminate that element. Other displayed names generally use escapeHtml. This is a statically traced injection path, not a demonstrated DAW exploit; webview-to-host privilege escalation was not tested. Escape HTML-sensitive characters in script data or avoid executable inline interpolation, and treat imported Set names as untrusted. LilyPond title export also deserves escaping review before compiling untrusted notation. [E2, E3, E5, E9]
- **Local traces remain:** WAV/notation/HTML files are written to host temp/storage locations, audio is imported into the Set's project, and errors go to host logs. No comprehensive cleanup lifecycle was found. “Offline” does not mean ephemeral or safe to share without reviewing project files. [E2]

### Project modification and recovery

Several transformations replace a clip's complete notes array inside withinTransaction, providing a host undo grouping rather than a backup. Reharmonize deliberately redistributes new chords evenly across the note span with velocity 90; it does not preserve the original performance. Newly constructed note objects may omit original per-note expression/probability metadata. Humanize instead copies note objects, illustrating why preservation needs per-command checking. [E2, E3]

Empty-slot checks reduce accidental overwrites, but track creation, clip creation, import and later note assignment are separate operations. Song-sketch or audio-import failure can leave partial tracks or imported files; no compensating rollback was found. A slow computation can also finish after the user has changed a clip, with no observed revision check before overwriting its notes. Duplicate the Set/clip, save a backup, inspect results, and test undo and reopening before using real sessions. [E2]

The bridge has no production request timeout or cancellation. It rejects pending work on some crashes and clears its cache for restart, but worker exit is not handled like worker error, and zero-code/signaled child exits do not use the nonzero-exit crash path. Hung runtimes can therefore leave requests unresolved. This is a reliability finding, not a measured failure rate. [E4]

## Compatibility and Self-Hosting Notes

This is a local DAW extension, not a server to self-host. The README requires a Live build with Extensions support, described as the Live beta, plus separately obtained SDK/CLI archives from the beta portal. Development instructions and Makefile examples are macOS-oriented. No exact supported Live build, edition matrix or verified Windows/macOS compatibility matrix was established; “Live 12” in release instructions is not sufficient assurance for every retail installation. No Linux Live support is implied. [E1, E7]

Builds need the private-distribution SDK tarballs and the matching PyTheory source checkout. They do not work from this repository alone. Use a supported Live license and documented SDK access; do not bypass the beta distribution or redistribute SDK archives. If evaluating later, first inspect the packaged asset and notices, use a clean test Set, disable unnecessary external connectivity, exercise worker/child transport and undo, and verify reopen/import behavior. No installation or permission changes were made in this review.

## License and Music Rights

The extension LICENSE is MIT, copyright 2026 Kenneth Reitz. PyTheory 0.59.0's own LICENSE is also MIT. The lockfile declares abcjs MIT and Pyodide MPL-2.0; the latter's covered-source obligations and bundled Python/NumPy/SciPy notices need separate distribution review. SDK/CLI entries say SEE LICENSE IN LICENSE.md, and the README says the SDK license forbids redistribution; the actual beta SDK license archive was unavailable and not inspected. The extension's MIT label does not relicense that SDK or all bundled runtime components. [E1, E7, E9]

The build copies only PyTheory .py files, so its root LICENSE is not copied by that staging loop. Runtime-package notices, compiled bundles and final .ablx contents were not audited; do not assume the packaged artifact preserves every required notice. This review republishes analysis, not source or music assets. [E7]

Code licensing also does not clear rights in imported samples, songs, rendered recordings, transcription or notation of copyrighted works. No blanket output-music clearance or independently audited provenance for every progression/preset/impulse response was established. Common musical patterns and generated notes are not automatically infringing, but any source recordings, compositions and third-party content retain applicable rights.

## Tests, CI and Evidence Limits

The repository includes Python unittest regressions for spelling, symbol-to-MIDI conversion, scales, voicings, progressions, groove, Euclidean rhythms and melody/harmony behavior, plus TypeScript Set-key tests. tests/pyodide.mjs loads the staged interpreter and checks both worker and child transports. Its child smoke test starts plain Node without reproducing Live's managed permission flags, and no actual SDK host mutation/undo tests were found. [E6]

No checked-in GitHub Actions workflows were present and the public Actions API returned zero runs. Earlier release notes explicitly document broken installed permission-model behavior in 0.1.0/0.1.1, a useful reason to distinguish dev tests from installed-host proof. No tests, builds, dependency installs, vulnerability scans or release binaries were executed. No DAW, devices, audio playback, paid calls or personal projects were accessed. Anonymous source/API retrieval and static inspection are the evidence here; correctness, audio quality and least-privilege behavior remain unverified. [E8]

## Comparison

| Option | Best fit | Tradeoff versus this extension |
|--------|----------|-------------------------------|
| Ableton's built-in MIDI tools and scale-aware editing | Supported in-DAW transformations | Less third-party runtime/build surface; not equivalent to this entire analysis/notation suite. Check the installed edition/version. |
| PyTheory standalone | Python composition and theory experiments | Same upstream engine without this Live bridge; manage Python and exchange MIDI/audio yourself. |
| music21 | Symbolic analysis, notation and corpus research | Broader research-oriented workflows; not a drop-in Live context-menu integration. |
| Tonal | TypeScript/JavaScript theory utilities | Avoids embedding Python/WASM for narrower symbolic tasks; requires custom DAW integration and lacks this full audio pipeline. |

Recommendation: prefer native Live tools for routine production, and evaluate this extension where its integrated harmony/generation features justify beta integration and runtime trust. For offline research outside Live, start with a standalone theory library rather than rebuilding this bridge. Alternative links: [Live manual](https://www.ableton.com/en/manual/), [PyTheory](https://github.com/kennethreitz/pytheory), [music21](https://github.com/cuthbertLab/music21), [Tonal](https://github.com/tonaljs/tonal). Alternatives were not installed or benchmarked.

## Evidence

All repository file citations below are pinned to the reviewed commit; external metadata was retrieved anonymously on 2026-11-26 UTC.

- **E1:** [README](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/README.md), [LICENSE](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/LICENSE), [manifest](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/manifest.json), [changelog](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/CHANGELOG.md).
- **E2:** [Live integration and mutation paths](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/src/extension.ts), especially activate, wavForAudioClip, showNotation, generateSketch, fillClip and writeNotes.
- **E3:** [Musical implementation](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/src/analysis.py), especially detect_key, _cluster_chords, _transitions, reharmonize, notation and audio functions.
- **E4:** [Request bridge](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/src/python.ts) and [Python worker](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/src/python-worker.ts).
- **E5:** [Webview dialogs and notation interpolation](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/src/dialogs.ts).
- **E6:** [Python regressions](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/tests/regression.py), [transport harness](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/tests/pyodide.mjs), [key tests](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/tests/keys.test.ts), [scale mapping](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/src/keys.ts).
- **E7:** [Build staging](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/build.ts), [package manifest](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/package.json), [lockfile](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/package-lock.json), [PyTheory pin](https://github.com/kennethreitz/ableton-pytheory/blob/abfb9dd66462565308950bb1a7ed119049afcd71/pytheory-version.json).
- **E8:** [Public repository metadata](https://api.github.com/repos/kennethreitz/ableton-pytheory), [tags](https://api.github.com/repos/kennethreitz/ableton-pytheory/tags), [releases](https://github.com/kennethreitz/ableton-pytheory/releases), [Actions](https://api.github.com/repos/kennethreitz/ableton-pytheory/actions/runs).
- **E9:** PyTheory v0.59.0 [LICENSE](https://github.com/kennethreitz/pytheory/blob/v0.59.0/LICENSE), [package metadata](https://github.com/kennethreitz/pytheory/blob/v0.59.0/pyproject.toml), [ABC/LilyPond export](https://github.com/kennethreitz/pytheory/blob/v0.59.0/pytheory/rhythm.py).

---

**Attribution:** Kenneth Reitz / kennethreitz/ableton-pytheory, MIT extension code; dependencies and music rights remain separate.
