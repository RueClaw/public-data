# Deep-Live-Cam (hacksider/Deep-Live-Cam)

*Review #272 | Source: https://github.com/hacksider/Deep-Live-Cam | License: AGPL-3.0 | Author: hacksider (base: s0md3v/roop) | Reviewed: 2026-03-26 | Stars: 81K+*

## Rating: 🔥🔥🔥🔥

---

## What It Is

Real-time face swap for webcam, video, and images using a single source photo. Give it one photo of a face → it replaces faces in live webcam, video files, or images in real-time. No training, no dataset, single-click operation.

**Stack:**
- InsightFace (inswapper_128_fp16.onnx) for face detection and swapping
- GFPGAN/GPEN for face enhancement post-swap
- OpenNSFW2 (Yahoo's NSFW classifier) as a content filter gate
- ONNX Runtime for inference (CPU, CUDA, CoreML, DirectML, OpenVINO)
- Python + tkinter/customtkinter GUI
- ffmpeg for video I/O

81K stars, 11K forks, went viral in August 2024 covered by Ars Technica, Bloomberg, TrendMicro, CNN.

---

## Technical Architecture

Single-pass pipeline per frame:
1. Face detection (InsightFace)
2. NSFW gate (opennsfw2 — rejects inappropriate source/target content at MAX_PROBABILITY=0.85)
3. Face swap (inswapper_128_fp16.onnx → InsightFace's inswapper model)
4. Face enhancement (GFPGAN v1.4 or GPEN256/512)
5. Frame output / webcam virtual device

**Apple Silicon optimizations in the codebase:**
- `IS_APPLE_SILICON` detection
- Face detection caching with 30fps detection rate limit (`DETECTION_INTERVAL = 0.033`)
- `FRAME_CACHE` deque (3-frame LRU)
- Adaptive quality mode
- GPU-accelerated operations via `gpu_processing.py` (wraps OpenCV CUDA or CPU fallback)
- CoreML execution provider support

**Multi-face support:** `--many-faces` processes every face in frame. `--map-faces` does many-to-many source-to-target face mapping for multi-subject scenes.

**Mouth mask feature:** Composites the original mouth region back onto the swapped face for more accurate lip movement. This is the clever one — face swap models typically blur/distort the mouth area, keeping the original mouth solves that.

**Models needed (not in repo):**
- `GFPGANv1.4.onnx` (~300MB)
- `inswapper_128_fp16.onnx` (~250MB)
Both from HuggingFace, auto-downloaded on first run.

---

## License & Ethical Context

**AGPL-3.0** — open source with strong copyleft. Any service using this must open-source their modifications.

**The disclaimers are genuine but limited.** The NSFW filter (opennsfw2) blocks pornographic content, war footage, and graphic material. It does not block non-consensual face swaps of real people in non-NSFW contexts — which is the primary harm vector (identity fraud, non-consensual impersonation, fake video calls). The "obtain consent" language in the disclaimer is advisory, not enforced.

**Why TrendMicro covered it:** The threat model isn't entertainment deepfakes — it's video call impersonation for fraud. "Omegle" is literally listed as a use case in the README. Ars Technica's headline was "raising fraud concerns." Bloomberg noted it "can be used as a tool for deception."

**The base model (InsightFace's inswapper) is licensed for non-commercial research only.** The AGPL project wrapping it doesn't change the underlying model license. Commercial use requires InsightFace commercial licensing.

---

## Honest Assessment

This is technically impressive — 81K stars don't happen for nothing. The single-photo, real-time, no-training approach was a genuine breakthrough in accessibility when it launched. The Apple Silicon optimizations, mouth mask, and multi-face mapping are real engineering.

But it's one of the most ethically fraught repos in this review series. The primary use cases that drove virality were impersonation and deception. The NSFW filter is fig-leaf harm mitigation — it blocks the easiest-to-classify content and does nothing about the core identity fraud use case.

For legitimate creative uses (animation, film VFX, content creation), this is a useful tool. For the fraud/impersonation uses the press articles documented — it's a problem.

**The model license violation risk is real:** InsightFace's inswapper is non-commercial research only. If you build anything commercial on this, you're in violation.

---

## Relevance

**The face detection + analysis pipeline** (InsightFace, face caching, detection rate limiting) is directly applicable to the Parkinson's video call work — knowing *when* a face is present, tracking across frames, face quality assessment. InsightFace's face analyser (`face_analyser.py`) is worth studying separately from the swap functionality.

**The NSFW gate pattern** (opennsfw2 as a filter before processing) is a clean content moderation pattern for any image pipeline that needs to reject inappropriate content before doing expensive inference.

**The Apple Silicon frame caching + detection rate limiting** is a practical pattern for any real-time video processing on M-series chips — don't re-detect every frame at 60fps, cache detections and refresh at 30fps.

**The mouth mask compositing approach** — keep original region, composite on top of model output — is a general technique for any neural face processing where you want to preserve specific authentic features (natural eye movement, original lip sync, etc.).

AGPL-3.0, non-commercial-only underlying model. For research/study, fine. Don't build products on it.
