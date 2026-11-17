# Braitenberg-Vehicles (njodal/Braitenberg-Vehicles)

**Repo:** https://github.com/njodal/Braitenberg-Vehicles
**License:** No license specified; public visibility does not grant general permission to modify or redistribute code or assets.
**Reviewed:** 2026-11-17 (UTC)
**Revision:** c6abf11b3b21d8f71c69b5adb021b02120307e04, main; Python simulator, YAML definitions/worlds/scenarios, specs, tests, evolution tools, Webots adapter and separate CSCG experiment.
**Verification:** Static source review and independent arithmetic reasoning only. No installation, source execution, pytest, GUI, Webots, evolution or training run.
**Stack:** Python ≥3.11, NumPy, PyYAML, pygame-ce; optional pytest, Pillow and matplotlib.
**What it is:** A local, inspectable simulation of all fourteen chapters of Valentino Braitenberg’s Vehicles, including explicitly wired learning and prediction circuits—not just the familiar two-sensor phototaxis toy.

## Verdict

📚 **Study: unusually rich executable teaching material, not a validated robotics or cognition platform.** The clean separation of bodies, circuits, worlds and visualization makes the later vehicles genuinely worth reading. Hand-designed tasks, simplified physics, numerical edge cases, unpinned dependencies and absent licensing prevent an unqualified deployment or reuse recommendation.

## What It Is

The README claims implementations of Vehicles 1–14. The tree supports that scope: corresponding specs, named vehicle definitions, scenarios and acceptance-test modules are present. Early vehicles directly connect sensors to motors; later ones add threshold circuits, feedback memory, selection, learned associations, camera processing, temporal prediction and threshold regulation. These are operational interpretations of the book, not evidence that a robot experiences fear, ideas or optimism. [README](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/README.md), [definitions](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/definition.py).

The strongest educational feature is causal visibility: a live circuit diagram shows signals and learned connection strengths while the arena shows trajectories. Specs explain the gap between a literary description and a realizable circuit. Vehicle 14 explicitly reduces its evaluator to pleasing/not pleasing, uses two prepared lanes, notes tuning on seeds 0–4, and distinguishes imagined events from fixed-input events so prediction does not erase learning. That candor is more valuable than a generalized intelligence claim. [Vehicle 14](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/specs/vehicle-14.md).

## Stack

| Layer | Implementation |
|---|---|
| Configuration | Strict-key YAML parsing into dataclasses; worlds, vehicles, modules and scenarios |
| Dynamics | NumPy-backed threshold-network state, fixed-step movement, analytic fields and ray geometry |
| Interface | pygame-ce arena, heat map, trails, camera panels and circuit diagram |
| Outputs | SVG diagrams, Pillow GIF recording, CSV/YAML evolution results and matplotlib plots |
| Optional bridge | Webots e-puck light-sensor/two-wheel adapter |
| Separate experiment | NumPy clone-structured HMM sequence learning; not integrated into vehicle brains |
| Server/database/auth | None required by the reviewed simulator |

## Key Features and Architecture

1. **One generic vehicle engine, many configurations.** Loaders expand modules and array wiring into a common definition. A vehicle consumes readings without querying its world; the simulation owns sensing and boundary/collision correction. Rendering is lazily imported for a window, so the headless engine does not import pygame. [definition.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/definition.py), [sim.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/sim.py).
2. **Transparent signal timing.** Units sum signed active connections over per-input recent maxima, threshold them, then expose activations after a quantized delay. Connection strength is an on/off gate above 0.7, not a continuously multiplied synaptic weight. Mnemotrix changes strength while its source is active according to fixed-input teaching; Ergotrix learns temporally paired onsets, with separate fixed-output history. Threshold controls integrate activity error. [vehicle.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/vehicle.py).
3. **Synthetic vision rather than a real camera feed.** Subpixel rays intersect upright cylinders and boxes; the nearest visible object supplies face brightness, with black ground/sky and shortest wrapped displacement. This supports moving-object and symmetry circuits without models, image datasets or physical camera access. [camera.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/camera.py).
4. **Selection with an actual holdout mechanism.** Evolution mutates declared parameters, ranks mean survival over seeded starts, caches repeated genomes, and evaluates ancestor/best on separately drawn validation starts. This is a useful experimental pattern, but validation in the same synthetic world is not real-world transfer or broad generalization. [evolve.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/evolve.py).

### Sensor–motor equations

For a point source, field intensity is I / (1 + d²/f²); fields add, f is the half-intensity distance, and wrapping uses shortest toroidal distances. This stays finite at d=0 and is not a physical inverse-square radiation solver. Scalar sensors optionally apply directional cones, linear/Gaussian-peak/step responses and habituation; scalar source fields do not implement obstacle shadowing. Camera occlusion is a separate mechanism. [world.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/world.py), [responses](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/definition.py).

Each motor speed is clamp(base + gain × sum(signed active signals), 0, max_speed). For motor lateral coordinates xᵢ (body-right positive), the engine uses v = mean(vᵢ) and ω = sum(vᵢxᵢ)/sum(xᵢ²), with zero turn for zero denominator. Symmetric wheels at ±b give ω = (v_right − v_left)/(2b), consistent with the counterclockwise-positive world coordinates. Equal symmetric wheel speeds go straight; faster right turns left. Same-side excitation in vehicle 2a therefore turns away from a stronger left stimulus; crossed excitation in 2b turns toward it. The acceptance test checks avoidance/approach over five seeds, not merely wiring labels. [vehicle2a](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/vehicles/vehicle2a-fear.yaml), [vehicle2b](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/vehicles/vehicle2b-aggression.yaml), [test_vehicle2.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/tests/test_vehicle2.py).

Heading is advanced first by ωdt plus Gaussian angular noise σ√dt; position then advances vdt along that new heading. This is a first-order endpoint-heading approximation, not exact circular-arc integration. Motors cannot reverse. General asymmetric motor layouts are an abstract steering rule: equal motor speeds can turn if lateral positions do not sum to zero. No mass, wheel slip, acceleration, torque or contact dynamics are modeled.

## Correctness and simulation limits

- **Finite-number validation gap.** Parser.number rejects booleans/non-numbers and checks positivity with value ≤ 0, but never checks finiteness. YAML NaN passes that positivity comparison; positive infinity also passes. For example a NaN simulation.dt reaches delay/dt rounding in vehicle construction and can fail outside the intended ConfigError path. Negative integer seeds also pass scenario parsing although NumPy generators require nonnegative seed integers. These are static input-validation findings, not remotely exploitable service claims. [yamlfile.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/yamlfile.py), [scenario.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/scenario.py).
- **Single-reflection bounce breaks for sufficiently large steps.** Arena.apply_edges reflects each coordinate only once. In a width-100 arena, a proposed x=250 becomes −50, still outside. There is no dt/displacement constraint to prevent this for user configurations. Modulo wrapping does not have that particular limitation. [world.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/world.py).
- **Contact is approximate and endpoint-only.** Obstacles push the vehicle center away using radius=max(half_width, half_length), not the rectangular footprint or its circumscribed radius; only three correction passes are attempted. A large step can cross a thin obstacle and finish outside its correction region. Vehicles are sensed as bodies but world.block only resolves static obstacles, not vehicle–vehicle impacts. Edges are applied before obstacle correction, with no second boundary pass. Treat “cannot drive through” as a normal-step demo intention, not a general collision guarantee. [sim.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/sim.py), [obstacle tests](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/tests/test_obstacles.py).
- **Time-step changes alter circuit semantics.** Delays are max(1, round(delay/dt)) steps, as are temporal pairing windows. Changing dt changes both movement error and effective neural timing; refining dt is not automatically behavior-preserving. Tests explicitly cover delay rounding. Long runs also accumulate floating-point time at periodic source boundaries. [vehicle.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/vehicle.py), [definition tests](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/tests/test_definitions.py).
- **Seeded does not mean configuration-independent.** Noise draws share a simulation generator across vehicles; threshold jitter uses [seed, vehicle index]. Adding or reordering vehicles can change trajectories despite the same top-level seed. Start-of-step body snapshots do avoid sequential sensing of already-moved neighbors. [sim.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/sim.py).

For research use, add finite/range checks, multi-crossing boundary tests, swept collision tests, symmetric-wheel analytic trajectories and dt-convergence studies; report held-out seeds/worlds separately from tuned demonstrations.

## Reproducibility, maturity and scientific claims

The project includes a substantial suite covering loaders, responses, timing, cameras, obstacle sensing, energy, modules, chapter behaviors, a mocked Webots adapter and the separate CSCG experiment. Presence is not a passing result: **none was run for this review**. Default pytest configuration excludes slow tests, so an ordinary pytest invocation does not exercise the full evolution coverage. No tracked GitHub Actions workflow, dependency lockfile or license file was found. The manifest is version 0.1.0 and dependencies are unpinned. [pyproject.toml](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/pyproject.toml), [tests](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/tests).

Public GitHub metadata on 2026-11-17: created 2026-10-19; pushed 2026-11-16T15:03:35Z; 1 star, 0 forks, 0 open issues, no releases returned, not archived. The reviewed commit’s author timestamp is 2026-11-16T11:59:48−03:00. These indicate a young project, not reliability evidence. [metadata](https://api.github.com/repos/njodal/Braitenberg-Vehicles), [releases](https://api.github.com/repos/njodal/Braitenberg-Vehicles/releases).

The separate CSCG experiment models repeated traffic-light colors with six hidden clones per color, soft EM then Viterbi EM. Its README reports learned durations and compares them to Ergotrix sequence associations; it explicitly says integration requires a new probabilistic unit. Those results were not reproduced, and should not be attributed to the simulator’s vehicle brain. [experiment](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/experiments/cscg/README.md).

## UI, platform and accessibility

This is a desktop Python/Pygame application, not a web app or mobile product. Pause, single-step, restart, speed changes and stimulus cycling have keyboard bindings; moving sources and choosing a vehicle use mouse interactions. The diagram and heat maps are primarily visual, with no inspected screen-reader semantic surface or full keyboard alternative for those pointer actions. Headless output reports final positions/headings/speed, not an accessible equivalent to every live signal panel. OS/SDL compatibility, high-DPI behavior and assistive technology were not tested. [render.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/render.py).

Webots is optional and narrower than the main engine: its adapter accepts light sensors and exactly two motors on opposite sides, maps sensors to the nearest e-puck light device and scales wheel velocity. It calls think(), not the simulator’s movement/energy loop. It is not a drop-in route for all fourteen vehicles or proof of physical-robot equivalence. The sample world includes remote Webots PROTO references, so that optional route may require network asset retrieval. [webots.py](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/webots.py), [sample world](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/webots/worlds/vehicle2-fear-and-aggression.wbt).

## Installation, privacy, security and rights

The documented workflow is a Python virtual environment and editable install from the repository, then a scenario path. Keep the repository’s YAML directories: setuptools explicitly packages only braitenberg, not a complete scenario asset bundle. No install was attempted. NumPy/PyYAML/pygame-ce and optional packages come from the package supply chain; without lockfiles, future resolutions can differ. No vulnerability audit or platform installation guarantee is asserted.

The inspected simulator has no account, server listener, cloud model, telemetry or remote sensor dependency. It reads local YAML, generates local artifacts when requested, and the GUI creates a window. This is a small privacy surface, not a sandbox. yaml.safe_load avoids Python object construction and keys are validated; array-index expressions are parsed rather than evaluated as Python. However relative paths resolve without a confined root, referenced module files are local read authority, and large cameras/networks/delay buffers or long runs can consume substantial memory/CPU. Load only trusted scenarios in a resource-bounded environment. GIF recording/evolution/diagram generation write to chosen paths; do not target valuable files. [loaders](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/yamlfile.py), [definition parser](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/definition.py), [recording](https://github.com/njodal/Braitenberg-Vehicles/blob/c6abf11b3b21d8f71c69b5adb021b02120307e04/braitenberg/record.py).

No license grant was found in the manifest or tracked license files, and GitHub reports license=null. Do not infer MIT or unrestricted educational reuse. Specs include generated illustrations and book-related explanatory material; no blanket asset reuse grant was identified. This review links to evidence and does not redistribute source code or images.

## Comparison and practical fit

| Option | Best fit | Tradeoff |
|---|---|---|
| This repository | Reading later Braitenberg chapters through explicit circuits and scenarios | Small, inspectable engine; abstract physics, young tooling, no license grant |
| [Webots](https://github.com/cyberbotics/webots) | Robot/sensor simulation and controllers with richer physical context | Larger installation and modeling burden; this repository’s adapter supports only a light/two-wheel subset |
| [NetLogo](https://www.netlogo.org/) | Classroom agent-based experiments and parameter exploration | Different modeling environment; would need an appropriate model rather than assuming these exact circuits exist |
| Original Vehicles book | Understanding the conceptual thought experiments | No executable acceptance criteria; read alongside, not replace with demo labels |

**Practical recommendation:** read the specs and trace vehicle 2 → 5 → 7 → 11 → 14, comparing predicted circuit changes to the authored acceptance criteria. For a local teaching trial, pin the revision and dependency versions and validate it in isolation first. For redistribution or a derivative application, obtain licensing clarity; for scientific conclusions or robot control, use stronger numerical validation and independent tasks before investing further.

**Attribution:** njodal/Braitenberg-Vehicles; conceptual source: Valentino Braitenberg, Vehicles. No source license specified. Public-source review only; alternatives were not benchmarked.
