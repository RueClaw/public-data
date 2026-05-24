# Pattern: WiFi CSI Edge Sensing Pipeline

## Summary

WiFi Channel State Information can be used as a local sensing substrate for presence, motion, occupancy, and limited vital/activity signals. The reusable pattern is an edge-first pipeline: capture RF signal changes locally, normalize them, infer bounded states, and expose those states to local automation systems without using cameras.

## Core Shape

1. Capture CSI from supported WiFi hardware.
2. Normalize phase, amplitude, timestamps, and device metadata.
3. Filter noise and reject low-quality frames.
4. Extract motion, variance, spectral, breathing-band, and environment features.
5. Run conservative heuristic or model-backed inference.
6. Publish bounded semantic outputs to local systems.
7. Keep raw signal data local by default.
8. Calibrate per environment and expose confidence.
9. Treat health and safety outputs as advisory unless clinically validated.

## Why It Matters

Camera-free sensing can be useful where cameras are intrusive: bedrooms, bathrooms, elder care spaces, industrial safety zones, or privacy-sensitive occupancy automation. RF sensing can detect motion and presence through darkness and some obstructions, but it is also highly environment-dependent.

The product boundary matters. A presence sensor is one thing; a medical monitor or fall detector is another. The pipeline should make uncertainty visible and avoid claiming more precision than the deployment has validated.

## Good Design Properties

- Local-first processing.
- No cloud dependency for basic sensing.
- Hardware capability checks before enabling features.
- Calibration and re-calibration flows.
- Confidence scores and quality flags on every inference.
- Replayable capture format for debugging and model evaluation.
- Integration adapters for MQTT, Home Assistant, Matter, or local APIs.
- Clear privacy mode that suppresses raw or sensitive measurements.
- Test fixtures with known ground truth.

## Risk Controls

- Do not silently upgrade advisory signals into safety-critical decisions.
- Separate raw signal values from semantic states.
- Track false positives and false negatives per deployment.
- Keep model provenance and training data limitations visible.
- Add rate limits and payload caps to network publishers.
- Sign or attest edge modules only if the trust model is documented.
- Audit dependency and firmware update paths.

## Good Fit

- Occupancy automation.
- Non-camera motion sensing.
- Privacy-preserving smart-home signals.
- Lab research on RF sensing.
- Advisory dashboards for environment changes.

## Poor Fit

- Medical diagnosis.
- Emergency response without redundant sensors.
- High-stakes surveillance.
- Uncalibrated multi-room inference.
- Deployments without hardware and ground-truth validation.

## Implementation Guidance

Start with presence and motion, not pose or vitals. Require explicit calibration, store replayable captures, and measure accuracy against ground truth before expanding the semantic vocabulary. If outputs flow into home automation, expose uncertainty and keep potentially sensitive measurements out of default topics.

