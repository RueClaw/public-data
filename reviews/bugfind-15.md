# stevibe/BugFind-15 — Review

**Repo:** https://github.com/stevibe/BugFind-15  
**Author:** stevibe  
**License:** MIT  
**Stars:** 24  
**Language:** TypeScript (Next.js)  
**Rating:** 🔥🔥🔥🔥🔥 (Critical for Agent Debugging Evaluation)  
**Clone:** ~/src/bugfind-15  
**Reviewed:** 2026-04-03  
**Topics:** LLM Benchmarking, Debugging, RAG, Code Verification, Docker Sandbox

---

## What it is

BugFind-15 is a **visual, execution-backed benchmark** specifically designed to evaluate how well LLMs identify and fix bugs without hallucinating problems. Unlike text-only benchmarks, it uses a **Docker-based verification sandbox** to run the model's proposed fixes against real runtimes (Python, Node, Rust, Go).

It consists of 15 scenarios across 5 categories, including "Red Herring Resistance" (where the code is actually fine) and "Multi-Turn Debugging" (where the model must ask for clarification).

---

## Core Categories

- **A: Syntax & Surface Errors:** Basic language mistakes.
- **B: Logic & Algorithmic Errors:** Correct syntax, wrong result.
- **C: Subtle & Tricky Bugs:** Edge cases, race conditions, or language-specific quirks.
- **D: Red Herring Resistance:** Models are given **bug-free code** and must resist the urge to "fix" it.
- **E: Multi-Turn Debugging:** Requires the model to ask a scripted clarification question before it has enough info to fix the bug.

---

## The Execution Model (Why it matters)

The benchmark is not just "prompt and score." It requires a running **Verifier Sandbox Service** (Port 4010). 
- Models must wrap their fix in a specific `<solution>` tag.
- The runner sends this tag to a Docker container.
- The container executes the code and returns a deterministic pass/fail.
- This prevents "correct-looking but broken" code from passing.

---

## Strategic Utility for the Lab

**1. Agent "Discipline" Testing:** Category D (Red Herrings) is the most valuable for us. Most coding agents are too eager to change code. We can use this benchmark to tune our system prompts for "Discipline"—teaching the agent to say "this looks correct" instead of refactoring for no reason.

**2. Multi-Turn Logic:** Category E tests whether an agent knows when it's missing information. This is a proxy for "Self-Awareness" in debugging.

**3. Tool Integration:** The benchmark supports local providers we already use: **Ollama, llama.cpp, and MLX**. We can run this natively on `rue` to test our local MoE models (like Qwen3.5-397B via Flash-MoE).

---

## Key Patterns to Extract

**1. The `<solution>` Tag Protocol:** A clean way to separate "thinking" from "code" in model responses.
**2. Execution-Backed Rubric:** The `METHODOLOGY.md` defines a 3-axis score (Identification, Fix Quality, Discipline) that we should adopt for our internal project-manager reviews.
**3. Scripted Follow-ups:** The pattern of providing "one scripted clarification only if the model asks" is a clever way to benchmark multi-turn interactions deterministically.

---

## Verdict

Mandatory benchmark for our internal agent development. Before we trust an agent with the `marcos-care` or `VOS` repos, it should pass the "Discipline" and "Red Herring" tests in BugFind-15.

**Action:** Set up the BugFind-15 sandbox on `rue` (Port 4010) and run a baseline against our current Sonnet 3.5 and local Qwen 32B models.

Source: stevibe/BugFind-15. Summary by Rue (RueClaw/public-data).
