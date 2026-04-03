# Netflix/void-model — Review

**Repo:** https://github.com/Netflix/void-model  
**Paper:** arXiv:2604.02296 — "VOID: Video Object and Interaction Deletion"  
**Authors:** Saman Motamed, William Harvey, Benjamin Klein, Luc Van Gool, Zhuoning Yuan, Ta-Ying Cheng (Netflix / INSAIT)  
**License:** Apache 2.0 ✅  
**Stack:** Python / PyTorch / CogVideoX / SAM2 / Gemini / Blender / Kubric  
**Weights:** HuggingFace (netflix/void-model)  
**Reviewed:** 2026-04-03  
**Rating:** ⭐⭐⭐⭐½ — Genuinely novel; hard to run but the ideas are production-quality

---

## What It Is

A video inpainting model from Netflix Research that removes objects from video along with **all interactions they induce on the scene** — not just cosmetic artifacts (shadows, reflections) but *physical interactions* (objects that fall, shift, or react when the removed entity is gone).

The canonical example: remove a person holding a guitar → the guitar falls naturally. Not just "paint over the person" — the model understands that the guitar's position was causally dependent on the person and simulates what happens when that cause is removed.

This is a fundamentally different problem from standard video inpainting ("fill in the hole") or object removal ("paint it out"). VOID is doing *counterfactual video synthesis* — generating what the scene would look like if the object had never been there.

---

## Core Technical Contributions

### 1. Quadmask Conditioning

The key innovation. Instead of a binary mask (remove / keep), VOID uses a 4-value semantic mask encoding:

| Value | Meaning |
|-------|---------|
| `0` | Primary object to remove |
| `63` | Overlap region (primary + affected) |
| `127` | Affected region — objects that interact with the removed entity |
| `255` | Background — preserve exactly |

The `127` (grey) region is the novel part: it tells the model "this area will change as a consequence of the removal, but you need to figure out *how* based on physics." The model learns, during training, what physically plausible consequences look like.

### 2. Two-Pass Inference

- **Pass 1:** Base inpainting — removes the object and its direct region, generates an initial counterfactual video
- **Pass 2:** Warped-noise refinement — uses optical flow from Pass 1 to warp latents and initialize a second diffusion pass, improving temporal consistency on longer clips

The two-pass design is smart: Pass 1 is good enough for most shots; Pass 2 adds ~50% more compute but meaningfully improves consistency for sequences over ~100 frames.

### 3. VLM-Mask-Reasoner Pipeline

Automated mask generation using a three-stage pipeline:
1. **User points** (GUI click on object) → SAM2 propagates across frames → binary mask for primary object
2. **Gemini VLM analysis** → identifies affected/interacting objects (semantic reasoning about what physically depends on the removed object)
3. **Grey mask generation** → affected objects get `127` value
4. **Quadmask combine** → final mask ready for inference

The use of Gemini to reason about *physical dependencies* between objects is clever. SAM2 segments "what's there"; Gemini reasons about "what will change when this is gone."

### 4. Training Data Generation

Released the data generation pipeline instead of the actual data (licensing constraints). Two sources:
- **HUMOTO** — motion capture data + Blender physics simulation. Human + object interaction → counterfactual without human → objects fall via physics
- **Kubric** — Google Scanned Objects + Kubric physics simulator. Objects launched at a target; remove launcher → target trajectory changes

Both produce paired counterfactual videos (with object / without object / quadmask) as training data. Generating this kind of physically-plausible counterfactual data via simulation is the hard-to-replicate part of this work.

---

## Hardware Requirements

- **Inference:** 40GB+ VRAM (A100). Not runnable on our homelab.
- **Training:** 8× A100 80GB + DeepSpeed ZeRO stage 2. Research cluster territory.
- **Base model:** CogVideoX-Fun-V1.5-5b-InP (5B parameter video inpainting foundation model from Alibaba PAI)

This is firmly in "cloud GPU or academic cluster" territory. Not something we can run locally.

---

## Architecture Notes

Built on top of [CogVideoX-Fun](https://github.com/aigc-apps/VideoX-Fun) (Alibaba PAI), which is itself a video generation framework built around CogVideoX (THUDM). VOID fine-tunes CogVideoX for video-to-video inpainting with quadmask conditioning.

The `videox_fun/` directory is a fork of the CogVideoX-Fun codebase with VOID-specific modifications:
- `models/cogvideox_transformer3d.py` — custom attention with quadmask conditioning
- `data/dataset_image_video_warped.py` — warped-noise dataset for Pass 2 training
- `pipeline/pipeline_cogvideox_fun_inpaint.py` — modified inference pipeline

Multi-node distributed inference via `xFuser` is supported for very long videos.

---

## Interesting Patterns

**1. Counterfactual Video via Simulation**
The training data strategy is replicable for other domains: use physics simulation to generate "world with X" / "world without X" pairs as training signal. Blender + Kubric are both accessible tools. The insight that you can train a video model to understand *physical consequences* by supervising on simulation is broadly applicable.

**2. Semantic Mask Hierarchy**
The quadmask abstraction (0/63/127/255) is a clean representation for "primary target / overlap / consequential region / background." This four-tier semantic hierarchy could generalize to other conditional generation tasks where you want fine-grained control over which regions change vs. are preserved.

**3. VLM as Physics Reasoner**
Using Gemini to reason about physical dependencies (what else will change when I remove this?) rather than just visual segmentation (what pixels look like this?) is a clean division of labor. SAM2 handles spatial precision; Gemini handles causal reasoning about scene dynamics.

**4. Warped Noise for Temporal Consistency**
Optical flow-warped latent initialization for a second diffusion pass is a clean technique for improving video temporal consistency without full retraining. The warping "primes" the latent space with temporal structure from Pass 1.

---

## Relevance

Primarily research-interest. Not directly applicable to our current work (no A100, wrong domain for what we're building). But the conceptual contributions are significant:

- **For VOS/ODR:** The VLM-as-reasoner-about-consequences pattern is interesting. Could adapt for "what else changes if we accept this document edit?"
- **For Parkinson's support work:** Long-term: if Marcos needs video editing for content creation, VOID-style tools could be useful for removing background distractions or medical equipment from video calls
- **For general ML literacy:** Good example of how to frame a video generation task as counterfactual reasoning rather than masked inpainting

---

## Verdict

Genuinely novel research from Netflix. The quadmask formulation and the VLM-as-physics-reasoner pipeline are the interesting contributions. The training data generation approach (physics simulation for counterfactual pairs) is the hard-to-replicate moat. Practical constraints (40GB VRAM minimum) limit immediate applicability, but the ideas are worth tracking.

The paper landed on arXiv April 2026 and HuggingFace Spaces demo is live. Worth revisiting when the ecosystem around CogVideoX matures and inference costs drop.

Source: Netflix/void-model (Apache 2.0). Review by Rue.
