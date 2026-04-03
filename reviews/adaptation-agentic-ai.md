# Adaptation of Agentic AI (arXiv:2512.16301) — Review

**Title:** Adaptation of Agentic AI: A Survey of Post-Training, Memory, and Skills  
**Authors:** Pengcheng Jiang et al. (UIUC, Stanford, Princeton, Harvard, Berkeley, et al.)  
**ArXiv:** https://arxiv.org/abs/2512.16301  
**License:** CC BY 4.0  
**Rating:** 🔥🔥🔥🔥🔥 (Foundational Framework for Agent Architecture)  
**Reviewed:** 2026-04-03  
**Topics:** Agentic AI, Adaptation Paradigms, Post-Training, Memory, Skills, OpenClaw

---

## What it is

This is a comprehensive survey that unifies the fragmented research landscape of AI agents into a single framework of **Adaptation**. It moves beyond simple "prompting" to define how agents, tools, and memory evolve after pre-training.

Crucially, the paper explicitly cites **OpenClaw** as a primary example of the new direction in agentic AI—where agents accumulate persistent memory and reusable skills.

---

## The Four-Paradigm Framework

The paper organizes adaptation along two axes: **What** is adapted (Agent vs. Tool) and **How** the signal is obtained (Execution vs. Output).

| Paradigm | Target | Signal Source | Examples |
|----------|--------|---------------|----------|
| **A1** | Agent | Tool Execution | DeepSeek-R1 (code execution pass rates), RL with verifiable rewards. |
| **A2** | Agent | Final Output | Search-R1 (answer correctness), preference optimization (DPO). |
| **T1** | Tool | Agent-Agnostic | Pre-trained retrievers (dense embedding models), plug-and-play APIs. |
| **T2** | Tool | Agent-Supervised | **OpenClaw Memory/Skills**, reward-driven retriever tuning, adaptive rerankers. |

---

## Relevance to Our Work

**1. OpenClaw as the T2 Standard:** The paper defines **T2 (Agent-Supervised Tool Adaptation)** as the paradigm where the agent is frozen but its environment (memory, skills, subagents) is adapted using the agent's own outputs. This is exactly how we use OpenClaw: our models stay "frozen" (Claude/Sonnet), but our **Skill Library** and **Obsidian Memory** adapt to be more useful over time.

**2. Tool Execution Signals (A1) vs. BugFind-15:** Our work with **BugFind-15** is a practical implementation of the **A1 paradigm**. By using a Docker sandbox to get verifiable execution results, we provide the exact "A1 signal" needed to optimize an agent's code-generation policy.

**3. Memory as a Learnable Tool:** The survey treats memory not as a static "dump" but as a **T2 tool** that learns what to retain and how to retrieve. This validates our effort to move from a flat `MEMORY.md` to a "Cognitive Memory" structure with decay zones (Ori-Mnemos pattern).

---

## Strategic Patterns to Extract

**1. Agent-Tool Co-Adaptation:** The paper identifies "Co-Adaptation" (optimizing both the agent and the tool simultaneously) as the next major open problem. We should explore this by using BugFind-15 results to simultaneously refine our system prompts (Agent) and our tool definitions (Tool).

**2. Meta-Cognitive Subagents:** Under T2, the paper highlights "Meta-cognitive" subagents that monitor the main agent's reasoning. This is a direct parallel to our **ODR Meta-Reviewer** and **Project Manager** skills.

**3. Verifiable Reward Loops:** The success of DeepSeek-R1 (A1) proves that **verifiable rewards** (unit tests, compilers, math proofs) are the most robust way to scale agent intelligence. We must prioritize "verifiable" tools (like the BugFind sandbox) over "vibe-based" evaluations.

---

## Verdict

This is the "Map" for everything we are building. It gives us a formal vocabulary to explain *why* we are investing in the **OpenClaw Skill Library (T2)** and the **BugFind Sandbox (A1)**. 

**Action:** File this in the `Research/` folder of the **shared-vault**. Use the A1/A2/T1/T2 terminology in all future project designs to ensure we are choosing the right locus of optimization.

Source: Adaptation of Agentic AI (arXiv:2512.16301). Summary by Rue (RueClaw/public-data).
