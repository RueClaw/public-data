# ART (OpenPipe/ART)

**Repo:** https://github.com/OpenPipe/ART  
**License:** Apache-2.0. Permissive reuse with attribution.  
**Reviewed:** 2026-06-06  
**Stack:** Python 3.12+, OpenAI-compatible clients, vLLM, GRPO, LoRA, Unsloth/PEFT/torch/TRL, Megatron/NVIDIA stack, W&B/serverless backend, MCP/LangGraph/Tinker integrations  
**What it is:** ART, Agent Reinforcement Trainer, is an open-source framework for training multi-step LLM agents with reinforcement learning from task rollouts. It separates agent/environment code from GPU training and inference backends, so developers can gather trajectories, assign rewards, and train LoRA checkpoints against local or managed GPU infrastructure.

---

## Verdict

✅ **Deploy candidate for serious agent-RL experiments.** ART is not lightweight, but it is real: Apache-2.0, heavily used, actively developed, documented, CI-covered, and architected around the right primitives for agent reinforcement learning. The main caveats are infrastructure cost, reward-model fragility, a large CUDA/Megatron dependency surface, and one invasive auto-capture path that monkey-patches `httpx`.

---

## What It Is

ART targets teams trying to improve agents through repeated task execution rather than only prompt tuning or supervised fine-tuning. A user defines scenarios and rollout functions, gathers multiple trajectories for each scenario, assigns rewards, and sends grouped trajectories to a backend for GRPO training.

The project splits responsibilities cleanly. The ART client runs inside the user's agent code and exposes an OpenAI-compatible inference client. The backend runs vLLM plus training machinery, updates LoRA checkpoints, and reloads the latest trained adapter for future inference. That means the same training loop can point at a local GPU backend or a managed W&B/serverless backend.

The most interesting built-in reward path is RULER, Relative Universal LLM-Elicited Rewards. Instead of requiring hand-labeled rewards, it has an LLM judge rank several trajectories for the same scenario and uses those relative scores for GRPO. That is useful, but it should be treated as a reward-development accelerator, not as a guarantee against reward hacking.

## Stack

| Layer | Tech |
|-------|------|
| Core package | Python 3.12+, `openpipe-art`, Pydantic-style dataclasses, async training/inference APIs |
| Inference | OpenAI-compatible client surface, vLLM servers, LoRA adapter routing |
| Training | GRPO, LoRA, Unsloth, PEFT, torch, TRL, Transformers, optional Megatron/NVIDIA stack |
| Backends | `LocalBackend`, `ServerlessBackend`, Tinker/TinkerNative backends |
| Rewards/evals | RULER LLM-as-judge reward, task-specific examples, trajectory logging, W&B metrics |
| Agent integrations | MCP training, LangGraph wrappers, tau-bench support, example games/tasks |
| CI | GitHub Actions `prek` gate on CUDA runner, package install smoke tests |

## Key Features

### Trajectory-Grouped RL Loop

The central abstraction is a `Trajectory`: messages, tool calls, model choices, reward, metrics, metadata, and logs. `TrajectoryGroup` lets ART train on multiple attempts for the same scenario, which matches GRPO's relative-advantage shape and keeps reward assignment close to the task environment.

### Client/Backend Split

The client side stays close to the agent workflow. The backend side owns GPU concerns: vLLM serving, checkpoint storage, LoRA loading, training, memory management, and metrics. This is the right boundary for agent RL because rollout code is application-specific while training infrastructure is not.

### RULER Rewards

RULER uses an LLM judge to score several trajectories relative to one another. The implementation deduplicates common prefixes to reduce judge-token cost, supports custom rubrics and LiteLLM-compatible judge models, and records judge cost in the metrics context.

### Local And Managed Backends

`LocalBackend` supports local vLLM/training workflows for GPU machines. `ServerlessBackend` uses W&B-backed managed training and artifacts, which lowers setup friction but creates a vendor dependency. There are also Tinker/TinkerNative paths for other training infrastructure.

### MCP Training Examples

The MCP-RL path is a useful applied example: discover MCP tools/resources, generate scenarios, run tool-use rollouts, judge them with RULER, and train the model to use the server more effectively. This is one of the clearer examples of how agent-RL could improve tool selection and multi-step workflows.

## Architecture

ART is organized around a few strong interfaces:

- `Model` and `TrainableModel` wrap inference identity, metrics, OpenAI-compatible clients, logging, and checkpoint state.
- `Backend` defines register, train, SFT train, checkpoint deletion, and backend preparation.
- `Trajectory` and `TrajectoryGroup` define the durable unit of rollout evidence.
- Backend implementations handle the messy runtime details: vLLM launch, LoRA lease management, checkpoint push/pull, W&B artifacts, GPU accounting, and Megatron-specific routing/replay paths.

The codebase is broad but coherent. It has docs for the training loop, ART client, ART backend, RULER, SFT training, metrics, checkpoint deletion/forking, MCP-RL, LangGraph, and notebooks. The examples cover games, email search, MCP servers, tau-bench, summarization, and distillation.

The risk is also architectural: this is a lot of moving machinery. Optional extras pull in current CUDA/PyTorch/NVIDIA/Megatron packages; some tests are live/integration tests gated by API keys or GPU memory; and full local validation is not representative unless you have the same GPU stack.

## Comparison

| Aspect | ART | Deep Agents with LangSmith | CUDA Agent | Defending Code Reference Harness |
|--------|-----|----------------------------|------------|----------------------------------|
| Primary goal | Train task agents with RL from rollouts | Build/deploy/evaluate deep agents | Train CUDA-kernel agents at scale | Verify vulnerability discovery/patch loops |
| Core state | Trajectories and grouped rewards | Agent state, memory paths, traces | Synthesized tasks, kernels, profiler rewards | PoCs, containers, reports, patches |
| Reward/eval | Task rewards, RULER, GRPO | LangSmith datasets/trajectory evals | Correctness and runtime rewards | Fresh-container exploit/patch grading |
| Best use | Agent capability training | Agent app scaffolding and tracing | Specialized codegen RL research | Security-agent verification reference |

ART is more deployable than most agent-RL repos because it gives developers a usable client/backend loop instead of only a paper implementation. It is less plug-and-play than hosted eval/tracing tools, but it goes deeper: it changes model weights.

## Self-Hosting Notes

Basic use starts with the Python package, but meaningful local training expects a strong GPU machine and the backend extras. The serverless path expects a W&B API key and stores LoRA checkpoints as W&B artifacts.

Local verification on 2026-06-06:

- Reviewed commit: `ce4e4293b064fd53a62726a3510fb0c7d009a66d`.
- GitHub metadata: 9,909 stars, 884 forks, 126 open issues, pushed 2026-06-06.
- Latest checked GitHub Actions runs included successful `Prek` and `Package Install` jobs on 2026-06-06 for the most recent PR run.
- Basic secret-pattern scan found expected environment variable references and test/example placeholder keys, not obvious committed live credentials.
- Full local tests were not run because representative verification requires the repo's heavy CUDA/W&B/API-key backend stack, not just a small import check.

Operational caveats:

- RULER and other LLM-judge rewards need held-out validation and adversarial checks.
- `auto_trajectory.py` monkey-patches `httpx.Response` methods to capture OpenAI-style traffic. That is powerful, but it should be opt-in and carefully isolated in larger applications.
- The managed backend reduces setup friction but ties production-ish workflows to W&B artifacts/inference.
- The Megatron/NVIDIA path is impressive but version-sensitive.

---

**Attribution:** OpenPipe/ART, Apache-2.0.
