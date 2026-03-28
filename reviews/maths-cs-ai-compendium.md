# maths-cs-ai-compendium (HenryNdubuaku)

*Review #277 | Source: https://github.com/HenryNdubuaku/maths-cs-ai-compendium | License: Apache-2.0 | Author: Henry Ndubuaku | Reviewed: 2026-03-27 | Stars: 1,691*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

An open textbook covering maths, CS, and AI from foundations to cutting-edge. Written by an AI/ML practitioner who turned their personal notes into a structured curriculum. Friends used it to get into DeepMind, OpenAI, Nvidia.

86 markdown files, 208 custom SVG diagrams, 17 chapters — all fully written despite the README marking chapters 11-17 as "Coming." The README lied; the content is there.

Live site: https://henryndubuaku.github.io/maths-cs-ai-compendium/

---

## Coverage (All 17 Chapters, All Available)

**Foundations:**
- Ch 01: Vectors — spaces, norms, metrics, dot/cross/outer products, basis, duality
- Ch 02: Matrices — properties, types, operations, linear transformations, LU/QR/SVD decompositions
- Ch 03: Calculus — derivatives, integrals, multivariate, Taylor approximation, optimisation, gradient descent
- Ch 04: Statistics — descriptive measures, sampling, CLT, hypothesis testing, confidence intervals
- Ch 05: Probability — counting, conditional probability, distributions, Bayesian methods, information theory

**ML/AI:**
- Ch 06: Machine Learning — classical ML, gradient methods, deep learning, reinforcement learning, distributed training
- Ch 07: Computational Linguistics — syntax/semantics/pragmatics, NLP, LMs, RNNs, CNNs, attention, transformers, text diffusion, MoE, SSMs, modern LLM architectures
- Ch 08: Computer Vision — image processing, object detection, segmentation, video, SLAM, CNNs, ViTs, diffusion, flow matching, VR/AR
- Ch 09: Audio & Speech — DSP, ASR, TTS, voice/acoustic activity detection, diarisation, source separation, active noise cancellation, WaveNet, Conformer
- Ch 10: Multimodal Learning — fusion strategies, contrastive learning, CLIP, VLMs, image/video tokenisation, cross-modal generation, unified architectures, world models

**Systems & CS:**
- Ch 11: Autonomous Systems — perception, robot learning, VLAs, self-driving, space robotics
- Ch 12: Computing & OS — discrete maths, computer architecture, OS, concurrency/parallelism, programming languages
- Ch 13: Data Structures & Algorithms — arrays/hashing, linked lists/stacks/queues, trees, graphs, sorting/search
- Ch 14: SIMD & GPU Programming — hardware fundamentals, ARM/NEON, x86/AVX, GPU architecture/CUDA, Triton/TPUs/Vulkan
- Ch 15: Systems Design — fundamentals, cloud computing, large-scale infra, ML systems design, worked examples
- Ch 16: Inference — quantisation, efficient architectures, serving/batching, edge inference, scaling/deployment
- Ch 17: Intersecting Fields — quantum ML, neuromorphic computing, AI for finance, AI for biology, emerging intersections

---

## What Sets It Apart

**Intuition-first.** The stated philosophy: most textbooks bury ideas under notation, skip intuition, assume prior knowledge. This goes the other direction — concept first, notation as documentation of the concept, not the other way around.

**208 custom SVG diagrams.** Every major concept has an original illustration: transformer blocks, VQVAE architecture, SVD visualization, spectrogram/STFT, YOLO grid, stable diffusion architecture, sparse attention patterns, etc. These aren't stock diagrams — they're purpose-built for the text.

**`llms.txt` included.** There's an `llms.txt` file at the root — this is the emerging convention for making a site AI-readable (like robots.txt but for LLMs). Means the whole thing is designed to be ingested as reference material by agents and RAG systems.

**Coverage depth.** Ch 14 (SIMD & GPU) covers ARM/NEON, x86/AVX, CUDA, Triton, TPUs, AND Vulkan in 5 files. Ch 09 (Audio) covers WaveNet, Conformer, speaker diarisation, source separation, active noise cancellation. Ch 11 (Autonomous) covers VLAs and space robotics. This is not a survey — it goes deep.

**MkDocs + GitHub Pages.** Clean rendered site, LaTeX math via MathJax, built on Material for MkDocs. The `.github/workflows/deploy-docs.yml` auto-deploys on push.

---

## Relevance

🔥🔥🔥🔥🔥 — Apache-2.0, 1.7K stars (and clearly undervalued given the content depth), comprehensive coverage, SVG diagrams purpose-built for the material.

**Immediate uses:**
- Reference for any ML/AI implementation work — especially Ch 07 (transformers, SSMs, MoE), Ch 08 (diffusion, flow matching), Ch 09 (TTS pipeline, WaveNet), Ch 10 (VLMs, CLIP)
- Background reading for Marcos's Parkinson's project (Ch 09 for TTS/ASR pipelines, Ch 11 for assistive autonomy)
- Ch 16 (Inference) covers quantisation, efficient architectures, edge inference — directly relevant to running models on Apple Silicon/Ollama
- Ch 14 (SIMD/GPU) is reference material for understanding MLX internals

The `llms.txt` and clean markdown structure makes this RAG-ready. Could plug directly into the vault search system or Ori-Mnemos as a reference corpus.

Apache-2.0. Use, adapt, cite freely.
