# Deep Agents with LangSmith (langchain-samples/deepagents-with-langsmith)

**Repo:** https://github.com/langchain-samples/deepagents-with-langsmith
**License:** No license specified; educational/personal use only, do not redistribute code as reusable project material.
**Reviewed:** 2026-06-06
**Stack:** Python 3.11+, Jupyter, Deep Agents, LangGraph, LangSmith, LangChain, Tavily, OpenAI/Anthropic model providers, Gmail API sample
**What it is:** A workshop repository showing how to build Deep Agents, add tools/subagents/memory/HITL/skills, deploy to LangSmith, and evaluate agent trajectories with LangSmith datasets.

---

## Verdict

📚 **Study it as a current LangChain/Deep Agents reference, not a deployable project.** The workshop is compact and useful because it demonstrates several production-adjacent agent patterns in one place: path-routed memory, subagent delegation, tool approval interrupts, skills, LangSmith deployment, and trajectory evaluation. The missing license, workshop-specific package metadata, lack of tests, and vendor-bound deployment surface make it reference material rather than something to fork directly.

---

## What It Is

This repository is a hands-on Deep Agents workshop. The main `notebooks/workshop.ipynb` walks through a bare `create_deep_agent()` agent, custom Tavily search, isolated research subagents, backend routing for memory, middleware hooks, human approval interrupts, AGENTS.md instructions, skills, LangSmith deployment, and LangSmith evaluation datasets.

The code examples are intentionally small. `agents/deep_agent/` is a deployable research assistant with a Tavily search tool, a research subagent, skills for Twitter/X and LinkedIn posts, virtual filesystem storage, `/memories/` routed to a store backend, and interrupt gates for file writes. `agents/memory_backed_agent/` is a one-file deployment script that routes durable memory to Context Hub and wires a LangSmith issues board. `agents/email_agent/` shows a Gmail-send tool behind Agent Auth and a human approval interrupt.

The target user is someone learning the current LangChain/LangSmith agent stack. It is not a general agent framework, a polished template, or a standalone application.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.11+, `uv` |
| Agent framework | `deepagents>=0.6.3`, LangGraph, LangChain |
| Observability/evals | LangSmith tracing, datasets, evaluators |
| Notebook | Jupyter Notebook |
| Search tool | Tavily |
| Model providers | OpenAI by default; Anthropic, Azure OpenAI, AWS Bedrock examples |
| Memory/storage | StateBackend, FilesystemBackend, StoreBackend, ContextHubBackend, CompositeBackend |
| External action sample | Gmail API via Agent Auth OAuth |
| Deployment | `deepagents` CLI, `langgraph deploy`, LangSmith |

## Key Features

### Path-Routed Agent Memory

The strongest reusable idea is the backend split: ephemeral scratch state for normal files and durable memory under `/memories/`. The research agent uses a `CompositeBackend` with a filesystem default and a `StoreBackend` route. The memory-backed deploy script uses `StateBackend` for thread-local scratch and `ContextHubBackend` for durable memories.

This is a clean pattern because it gives agents a familiar file interface while keeping persistence explicit. A user can let an agent draft, edit, and discard scratch files without accidentally making every temporary artifact long-lived.

### Subagent Delegation

The workshop models a research subagent as a named dictionary with its own prompt and tool list. The main agent is told to delegate research rather than search directly, so tool-heavy work stays out of the main context until summarized.

That is the right shape for long-running research agents: isolate noisy exploration, return concise findings, and keep the primary thread focused on synthesis and final outputs.

### Human Approval Interrupts

The examples use `interrupt_on` for risky operations: file writes/edits in the research agent and `send_email` in the email agent. The email example is particularly important because it treats external side effects as approval-gated tool calls rather than normal assistant text.

The sample is minimal, but the principle is correct: irreversible or externally visible actions should cross an explicit approval boundary.

### LangSmith Evaluation Walkthrough

The notebook includes trajectory-style evaluations: expected tool-call sequences, a target function that runs the agent, and evaluators for match, extra steps, and missing steps. That is more useful than only grading final answers, especially for agents where the process matters.

## Architecture

The repository is workshop-shaped:

| Area | Role |
|------|------|
| `notebooks/workshop.ipynb` | Main tutorial covering Deep Agents, deploy, tracing, datasets, and evals |
| `agents/deep_agent/agent.py` | Deployable research assistant with Tavily, subagent, skills, memory routing, and HITL file writes |
| `agents/deep_agent/AGENTS.md` | Agent identity and workflow instructions |
| `agents/deep_agent/skills/` | Two small social-post skills |
| `agents/memory_backed_agent/deploy_memory_backed_agent.py` | One-file LangSmith deploy and Context Hub issues-board wiring script |
| `agents/email_agent/agent.py` | Gmail send example with service JWT, Agent Auth token retrieval, and send approval interrupt |
| `utils/models.py` | Central model initialization helper |

The code favors direct examples over abstraction. That is fine for a workshop, but it means there are no tests, no packaging polish, no reusable module boundaries, and no deployment hardening beyond the examples themselves.

## Comparison

| Aspect | Deep Agents with LangSmith | 12-Factor Agents | Agentic Stack |
|--------|----------------------------|------------------|---------------|
| Primary value | Hands-on LangChain/LangSmith workshop | Production-agent design principles | Portable `.agent` memory/skills/protocol layer |
| Reuse mode | Study the patterns and API usage | Use as a design checklist | Pilot/fork after verifying current quality |
| Memory pattern | File-like `/memories/` route to store/context backend | Principle-level context/state ownership | Portable data layer and transfer bundles |
| Eval posture | LangSmith trajectory eval examples | Conceptual guidance | Some local test coverage, but current quality caveats |
| License posture | No license specified | Apache-2.0 code / CC BY-SA content | Apache-2.0 |

The closest comparison is not another app, but a curriculum: this repo shows the current Deep Agents/LangSmith mechanics in executable form, while `12-factor-agents` is better as a broader rubric for production agent design.

## Self-Hosting Notes

Local use is straightforward if you already use `uv`:

```bash
uv sync
cp .env.example .env
uv run jupyter notebook notebooks/workshop.ipynb
```

You need API keys for OpenAI, LangSmith, and Tavily for the default path. Some examples use Anthropic, Agent Auth, Gmail, Context Hub, and LangSmith deployment permissions. The README correctly warns that LangSmith deploy requires a service key with deployment permissions.

Operational caveats:

- No root `LICENSE` file is present.
- No automated tests are present.
- The package metadata still says `capitalone-workshop`, which marks this as workshop material.
- Open Dependabot PRs include security-relevant dependency bumps for packages such as `notebook`, `idna`, `starlette`, and `langchain-openai`.
- The notebook contains captured deployment output. I did not find committed live API keys in the source scan.
- External-action samples should remain approval-gated and scoped to test accounts until audited.

---

**Attribution:** langchain-samples/deepagents-with-langsmith, no license specified
