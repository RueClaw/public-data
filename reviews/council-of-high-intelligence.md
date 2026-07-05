# Council of High Intelligence (0xNyk/council-of-high-intelligence)

**Repo:** https://github.com/0xNyk/council-of-high-intelligence
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-07-05
**Stack:** Markdown Agent Skills, Claude Code plugin manifest, Codex/Gemini/opencode skill variants, Bash installer/provider detection, YAML routing configs
**What it is:** A multi-persona deliberation skill that convenes 18 named reasoning personas across multiple LLM providers, runs structured rounds of disagreement, and returns a confidence-weighted verdict.

---

## Update Notes

Checked 2026-07-05 against the prior public review from 2026-03-28.

Material changes:

- Roster expanded from 11 to 18 members.
- License changed from CC0/public domain to MIT.
- Stars grew from 29 to 3,296.
- Claude Code plugin marketplace support landed.
- Codex, Gemini CLI, and opencode variants were added.
- Multi-provider routing expanded to OpenAI/Codex, Gemini, Ollama, NVIDIA NIM, and Cursor CLI.
- Protocol now includes project overrides, method-diversity frontmatter, anonymized cross-examination, anti-conformity language, structured stance voting, confidence weighting, a 1.5x domain seat, and a separate chairman synthesis role.

---

## Verdict

✅ **Deploy candidate as a decision-support skill, with cost and epistemic caveats.** The project has matured from a clever persona pack into a real deliberation protocol with install targets, CI drift checks, provider routing, stance tallying, and security notes. It is still prompt/protocolware rather than a measured decision engine: output quality depends on host-agent compliance, provider availability, and the quality of the personas. But the anti-convergence mechanics are strong enough to reuse directly.

---

## What It Is

Council of High Intelligence is an agent skill/plugin for hard decisions. Instead of asking one model to "consider multiple perspectives," it selects a panel of specialized personas, has them restate the problem, analyze independently, challenge each other, produce final stances, and synthesize a verdict that highlights uncertainty, disagreement, kill criteria, and next steps.

The 18-member roster uses historical/public figures as shorthand for reasoning styles: Socrates for assumption testing, Feynman for first-principles reduction, Ada Lovelace for formal systems, Torvalds for shipping pragmatism, Kahneman for bias audit, Meadows for feedback loops, Taleb for tail risk, Rams for user-centered design, and so on. The better abstraction is not the celebrity names; it is the intentionally conflicting methods.

The repo now ships for several hosts: Claude Code plugin marketplace, installer-based Claude skill, Codex skill, Gemini skill, and opencode skill. It also includes provider detection and model-slot configs for spreading seats across providers to reduce single-model monoculture.

## Stack

| Layer | Tech |
|-------|------|
| Skill/runtime | Markdown `SKILL.md`, host agent subagents |
| Host variants | Claude Code, Codex, Gemini CLI, opencode |
| Packaging | `.claude-plugin/plugin.json`, marketplace manifest, install script |
| Personas | 18 Markdown agent files with frontmatter |
| Routing | Bash provider detection, YAML model-slot configs |
| Providers | Anthropic host runtime, Codex/OpenAI, Gemini, Ollama, NVIDIA NIM, Cursor CLI |
| Validation | Shellcheck, markdownlint, custom simulation checklist |
| CI/release | GitHub Actions lint workflow, release tarball workflow |

## Key Features

### Blind-First Deliberation

The protocol starts with a problem restatement gate and independent analysis before members see each other's outputs. That protects against the common failure mode where the first frame anchors every later "perspective."

### Anonymized Cross-Examination

In later rounds, peer outputs are anonymized as `Member A`, `Member B`, etc. The intent is to reduce identity/self-bias during critique. Real names are restored for final synthesis.

### Anti-Conformity and Structured Voting

Round 2 includes an explicit anti-conformity directive: members should not update just because peers disagree or consensus is forming; if they update, they must name the flaw in their prior argument. Final outputs must include:

```text
STANCE: <short option label> | CONFIDENCE: high|med|low | DEALBREAKER: yes|no
```

The coordinator then tallies votes with confidence factors and a pre-selected domain-weight seat. If no option clears the 2/3 threshold, the verdict reports a split rather than forcing consensus.

### Method Diversity

Each persona now declares a `reasoning_method` in frontmatter. The coordinator is instructed to preserve method diversity when assembling panels, so the skill is not only varying names or domains; it is trying to vary actual analysis modes.

### Multi-Provider Routing

Provider detection supports native Anthropic subagents plus Codex/OpenAI, Gemini CLI, Ollama, NVIDIA NIM, and Cursor CLI. The routing rules separate polarity pairs across providers where possible, spread seats evenly, and fall back when providers fail.

### CI Drift Guard

The custom `council-simulation-checklist.sh` checks for required files, plugin manifest/version parity, protocol features across Claude/Codex/Gemini variants, provider configs, agent structure, frontmatter fields, and installer dry runs. It is a useful pattern for skill repos where "tests" are mostly protocol-parity checks.

## Architecture

The repo is small but structured:

- root `SKILL.md` is the canonical Claude coordinator
- `SKILL.codex.md`, `SKILL.gemini.md`, and `SKILL.opencode.md` adapt the protocol to other hosts
- `agents/council-*.md` define member personas, domains, polarity pairs, triads, provider affinities, and reasoning methods
- `configs/*.yaml` maps providers/models and manual seat layouts
- `scripts/detect-providers.sh` produces JSON availability data
- `scripts/council-simulation-checklist.sh` acts as the protocol regression test
- `.claude-plugin/*` packages marketplace installation

The most important design choice is that the coordinator protocol is explicit. It does not leave "multi-agent debate" as a vibe; it specifies selection, restatement, routing, anonymization, retry/degrade behavior, stance parsing, weighted consensus math, and synthesis output.

## Comparison

| Aspect | Council of High Intelligence | Research Council | dzhng/skills | Palpatine |
|--------|------------------------------|------------------|--------------|-----------|
| Primary job | Multi-perspective decision deliberation | Multi-model research cross-pollination | Software-factory workflow discipline | Power-strategy persona pack |
| Runtime | Agent skill/plugin | Agent workflow pattern | Agent skills | Claude plugin/skills |
| Best idea | Anti-convergence decision protocol | Independent research then skeptical merge | Living slice graph and visual gates | Bounded wave orchestration, but unsafe framing |
| Main caveat | Prompt compliance and cost | Research-specific | No enforcement by itself | Behavior risk |

Council is strongest when the question genuinely benefits from conflicting frames: architecture, risk, product strategy, ethics, launch decisions, and complex tradeoffs. It is overkill for simple factual questions.

## Self-Hosting Notes

Installation is local: clone the repo and run `install.sh`, or install through Claude Code's plugin marketplace. The project intentionally avoids a `curl | bash` install path.

Operational cautions:

- Full 18-member mode can be expensive and slow.
- Multi-provider routing requires local CLI/auth setup for the desired providers.
- Host agents must actually follow the protocol; no external harness verifies final answer quality.
- Historical persona names are useful mnemonic labels, but they should not be mistaken for faithful simulations.
- Provider/model IDs drift; the config comments correctly tell users to verify live catalogs.

---

**Attribution:** 0xNyk/council-of-high-intelligence, MIT License
