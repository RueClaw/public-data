# AI SAFE² Framework

*Source: https://github.com/CyberStrategyInstitute/ai-safe2-framework | License: Dual (MIT code / CC-BY-SA 4.0 docs) | Author: Vincent Sullivan, Cyber Strategy Institute | Reviewed: 2026-03-22*

## Rating: 🔥🔥🔥🔥

## One-liner
A comprehensive agentic AI governance framework — 128 controls, 5 pillars, compliance crosswalks to 14+ standards — with a working OpenClaw integration and substantive threat research that fills real gaps left by NIST and ISO.

## What It Is
AI SAFE² (Secure AI Framework for Enterprise Ecosystems) is an open GRC standard for securing agentic AI. Where NIST AI RMF and ISO 42001 are abstract policies, this translates them into concrete engineering controls for modern AI stacks: swarms, RAG, non-human identities (NHI), MCP servers, vector DBs.

**The 5 Pillars:**
- **P1 Sanitize & Isolate** — Input validation, prompt injection defense, cryptographic agent sandboxing
- **P2 Audit & Inventory** — Immutable logging, chain-of-thought traceability, asset registry
- **P3 Fail-Safe & Recovery** — Kill switches, circuit breakers, safe mode reversion
- **P4 Engage & Monitor** — Human-in-the-loop workflows, real-time anomaly detection
- **P5 Evolve & Educate** — Red teaming, threat intel integration, operator training

**Current version:** v2.1 — 128 controls. v1.0 had 10 conceptual topics; they've done real work getting here.

## The Genuinely Good Stuff

### Research Directory (14 threat intelligence docs)
This is the most underappreciated part of the repo. Not marketing copy — actual threat analysis:
- `001_rag_poisoning.md` — Memory poisoning via Vector DB injection (AgentPoison/MINJA)
- `002_nhi_secret_sprawl.md` — Non-human identity lifecycle failures
- `003_swarm_consensus_failure.md` — Infinite loop / cascade failure in multi-agent systems
- `005_memory_injection_minja.md` — Deep dive on MINJA attack vector
- `009_web_grounding_risk.md` — Prompt injection via retrieved web content
- `011_the_kill_switch.md` — Engineering a real kill switch (not a wishlist)
- `013_the_7_layer_stack.md` — Full stack model from LLM weights to NHI users

The hop-count swarm circuit breaker and "sanitize on retrieval" RAG pattern in `ADVANCED_AGENT_THREATS.md` are immediately usable.

### AISM (AI Sovereignty Maturity Model)
Five maturity levels: Ad-Hoc → Managed → Defined → Quantified → Optimizing. With a scoring matrix that distinguishes self-assertion from evidence. The comparison table showing every other framework (NIST AI RMF, CSA AICM, MS RAI MM, ISO 42001) scoring below 2.55/5.0 on agentic-era criteria is backed by a methodology doc, not just marketing.

### OpenClaw Integration (examples/openclaw/core/)
11 governance files that apply the SAFE² pillars to OpenClaw workspaces. The interesting one is their `SOUL.md` variant, which formalizes alignment using the **Love Equation**:
```
dE/dt = β(C − D)E
```
- E = alignment score
- C = cooperation (truth-seeking, autonomy support)  
- D = defection (deception, manipulation, harm)

"When C ≫ D: alignment grows. When D > C: alignment decays." — framing alignment as a dynamical system rather than a static policy document is a genuinely interesting approach. The `SUBAGENT-POLICY.md` and `MODEL-ROUTER.md` files have practical guidance on worker trust tiers and graceful degradation.

### skill.md
Drop this in Claude Projects and get an AI SAFE² Secure Build Copilot. Model-neutral YAML skill definition for triggering framework-aware security review on any codebase.

### Compliance Crosswalk
Claims 100% mapping to NIST AI RMF, ISO 42001, OWASP LLM Top 10, MIT AI Risk Repo (1600+ risks), 98% MITRE ATLAS. The `AISM/AISM-Compliance-Crosswalk.md` has the actual mapping tables. Whether the coverage claims are accurate requires deeper audit, but the crosswalk structure itself is solid reference material.

## Honest Caveats

**Marketing hyperbole is thick.** "The race is over." "Game over matrix." "$97 toolkit." The free framework is the taxonomy; the actual implementation assets (Excel scorecards, legal templates, engineering SOPs, the MCP server) are paywalled. The README is partly a sales page.

**FORGE Act section is a distraction.** There's a `FORGE-Act/` directory full of HTML files for some AI governance advocacy campaign. Feels out of place in a technical framework repo and reads like a separate project stuffed in.

**128 controls is a lot of checkbox.** For a solo developer or small team, the full AISM compliance stack would be paralyzing. The framework doesn't have a strong "minimum viable security baseline" path — the 5-minute quickstart exists but the scanner just tells you what you're missing, not what to prioritize.

**OpenClaw core files are opinionated derivatives.** The `examples/openclaw/core/SOUL.md` rewrites the standard OpenClaw SOUL.md with SAFE² alignment bands and the Love Equation. Worth reading as governance philosophy, but don't replace your own workspace files with these uncritically — they add overhead without much runtime enforcement.

## What to Actually Take From This

**High value:**
- `research/` directory — read all 14. Good threat model vocabulary for agentic systems.
- `ADVANCED_AGENT_THREATS.md` — the hop-count pattern and sanitize-on-retrieval code are direct lifts.
- `AISM/maturity-model.md` — useful scoring framework when you need to explain agent risk posture to non-engineers.
- `skill.md` — drop in any Claude Projects context where you're building agent infrastructure.
- `examples/openclaw/core/` — specifically SOUL.md (Love Equation framing) and SUBAGENT-POLICY.md (trust tiers).

**Lower value:**
- The scanner CLI (`scanner/`) — basic heuristic audit, nothing deep.
- The gateway (`gateway/main.py`) — thin Python proxy, mostly an illustration.
- FORGE-Act, VANGUARD_PROGRAM — skip.

## License
- Code (.py, .json, .html, .js): **MIT** — take freely
- Framework docs (.md, PDFs): **CC-BY-SA 4.0** — use with attribution, derivatives must share-alike
- Attribution: "Cyber Strategy Institute, AI SAFE² Framework v2.1"
