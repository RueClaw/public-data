# LLM-anonymization

- **Repo:** <https://github.com/zeroc00I/LLM-anonymization>
- **License:** No license file present
- **Commit reviewed:** `a669c74` (2026-04-13)

## What it is

At the moment, this repository is **not an implemented codebase**. It is a **README-only concept/spec** for a transparent anonymization proxy that would sit between Claude Code and Anthropic during penetration testing work.

The idea is strong:
- Claude Code talks to a local proxy instead of Anthropic directly
- all outbound content is anonymized before leaving the machine
- Claude sees realistic surrogates, not real client data
- returned model output is deanonymized before the operator sees it
- mappings persist per engagement in a vault

That is a genuinely useful security/privacy pattern for AI-assisted pentest workflows.

But right now, the repository contains only `README.md`.

## Important reality check

I verified the git tree at the reviewed commit. There are **no implementation files** beyond the README.

That means the following described components are **architectural claims, not inspected code**:
- FastAPI proxy
- Ollama/qwen detector layer
- regex safety-net layer
- SQLite PII vault
- setup scripts
- Docker support
- tests/integration tests
- self-improvement loop

The README describes all of those in detail, but they are not present in the repository state I reviewed.

So this review is necessarily about the **design**, not the implementation.

## Why the idea is interesting

### 1. It attacks the real adoption barrier
A lot of security people do not want cloud LLMs touching client names, internal domains, credentials, or raw tool output. Fair.

This design directly addresses that by making the model reason over surrogates instead of the real environment.

### 2. The transparent-proxy model is the right UX
If this works as described, it preserves the operator workflow. That matters. Security tooling dies quickly when users have to manually sanitize every prompt and output.

### 3. Two-layer detection is sensible
The proposed split is smart:
- deterministic regex for obvious structured secrets and identifiers
- LLM layer for context-sensitive entities like hostnames, project names, org names, people, and passwords embedded in natural text

That is the right architecture in principle.

### 4. Per-engagement vaulting is exactly the right constraint
Persistent surrogate mappings scoped to one engagement solve an important problem: consistent reasoning without cross-client leakage.

That part is especially well thought through.

## What is strong in the design

### The use case is concrete
This is not generic “privacy-preserving AI” fluff. It is narrowly aimed at **Claude Code during pentests**, which gives the design teeth.

### Surrogate strategy is practical
Using non-routable but believable replacements is better than blunt redaction in many workflows, because the model can still reason about relationships and repeated entities.

### The README thinks operationally
It covers:
- VPS deployment
- local Ollama setup
- Docker path
- engagement management
- health checks
- test gating
- continuous improvement loop

So whoever wrote it is thinking like a user, not just a paper author.

## Where I get skeptical

### 1. There is no code
This is the big one. Right now, this is a proposal with a polished README.

### 2. The hard problems are exactly the parts not proven
The README promises protection for:
- bash output
- file reads
- grep results
- credentials
- hostnames
- org names
- person names
- internal project names

Those are hard. Especially when you need:
- low false negatives
- low false positives
- stable surrogate mapping
- context preservation
- no tool breakage
- no prompt corruption

Without code and tests, there is no evidence any of that actually works.

### 3. Deanonymization correctness is underspecified
This kind of system lives or dies on reversibility and collision handling. If the surrogate mapping or substitution boundaries get sloppy, you can garble outputs or accidentally restore the wrong entities.

### 4. Security claims need implementation proof
The README strongly implies “Claude never touches real client data.” That is a serious claim. It may become true eventually, but it is not something the current repo proves.

### 5. No license means practical reuse is murky
Even if the concept is interesting, the lack of a license is a real friction point.

## Why it matters

Because the design target is right.

There is a real gap between:
- security teams wanting AI assistance
- and security teams refusing to leak client internals to hosted models

A robust anonymization proxy could become a very useful pattern not just for pentesting, but also for:
- incident response
- internal log triage
- support escalations with sensitive customer data
- regulated enterprise AI workflows

So the idea is worth tracking.

## Verdict

Excellent problem selection, promising architecture, currently **READMEware**.

If implemented well, this could be one of the more practically important security wrappers around cloud-assisted coding agents. But today, there is no implementation to validate, only a detailed design narrative. So it should be read as an **aspirational architecture note**, not a working tool.

**Rating:** 2.5/5 as current repo, 4.5/5 as idea

## Patterns worth stealing

- Transparent local proxy instead of manual sanitization workflow
- Layered anonymization: regex first, LLM second
- Stable per-engagement surrogate vaulting
- Realistic surrogates instead of blunt `[REDACTED]` everywhere
- Deployment modes that preserve existing agent UX
- Treat privacy protection as a middleware layer around agent use, not as user discipline
