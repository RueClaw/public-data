# llm.asm (alesha-pro/llm.asm)

**Repo:** https://github.com/alesha-pro/llm.asm
**Author:** Alexey Fateev (alesha-pro).
**License:** MIT for repository code; retain copyright and permission notices on substantial reuse. Qwen3-0.6B weights have separate Apache-2.0 terms.
**Reviewed:** 2026-11-26 (UTC).
**Revision:** 48feccbfd57cb669440f31ff64958d95bb8b848e (main; commit dated 2026-11-25 15:40:22 UTC). Scope: all three project READMEs, build/export tooling, shared inference kernels/loader/tokenizer/thread pool, selected bare-metal and trainer paths, and verification harnesses. No published release returned by GitHub at retrieval.
**Verification:** Static source inspection and anonymous public metadata/model-license checks only. No upstream code, builds, tests, benchmarks, model downloads, installs or paid calls executed.
**Stack:** NASM x86-64, AVX2/FMA/F16C, GNU binutils; optional Python/NumPy/PyTorch reference tools and QEMU/GRUB.
**What it is:** Three educational systems projects: a Linux Qwen3-0.6B inference engine, a bootable inference kernel, and a small character-level Transformer trainer, with assembly runtime implementations rather than a general-purpose serving stack.

---

## Verdict

📚 **Study: compelling low-level engineering, not a production inference replacement.** The shared Linux/bare-metal numerical core and explicit reference harnesses make this unusually useful for learning layout, quantization, threading and backpropagation. The headline speedups remain workload-specific author reports; weak input validation, contention sensitivity, incomplete checkpoint recovery and non-enforcing inference parity checks prevent a deploy recommendation.

## What It Is

The interesting result is not merely a tiny executable. The project places model conversion, weight layout, quantization, tokenization, scheduling and numerical kernels under one implementation's control. Phase 1 performs Qwen3 inference through raw Linux syscalls. Phase 2 reuses much of that numerical code with a small Multiboot kernel. Phase 3 implements a different, trainable character-level model, not training the pretrained Qwen3 model. [S1–S4]

“Zero runtime dependencies” describes the linked application library surface, not the complete environment. Linux remains a dependency for phases 1 and 3; inference needs roughly 614 MiB of exported weights plus KV/scratch memory, CPU instruction support, and offline conversion tools. The bootable edition also requires a bootloader or compatible hypervisor and model image. The 14.7 KB / 24.3 KB / 32.9 KB binary headlines exclude weights, BSS, arenas, tooling and boot media. [S1–S5]

## Stack

| Layer | Technology / boundary |
|---|---|
| Build | NASM and GNU ld; objcopy for the bare-metal ELF wrapper; Makefile |
| Linux runtime | Raw mmap/openat/write/clone/futex syscalls; no libc or dynamic runtime linked by the build rules |
| Inference | Qwen3-0.6B, custom .asmbin v1/v2, Q8 weights; AVX2/FMA, F16C for FP16 scales |
| Training | FP32 character vocabulary, RMSNorm/RoPE/causal attention/SwiGLU, handwritten backward pass and AdamW |
| Bare-metal | Multiboot 1, long mode, 2 MiB identity mappings, ACPI/APIC SMP, VGA/PS2/COM1 |
| Offline tooling | Python + NumPy exporter; optional Hugging Face download CLI; torch/transformers for references; QEMU/KVM and image tooling for OS verification |
| Service/database/auth | No HTTP inference service, database, authentication or tenancy layer in the reviewed main tree |

No dependency lockfile or GitHub Actions workflow was present in the checked tree. The source is predominantly assembly, but “100% assembly” applies to runtime implementations, not the Python and shell development tools. [S5, S11–S14]

## Key Features

### 1. A genuinely shared numerical core

The Makefile builds the same math, matmul, tokenizer and transformer files for Linux and bare-metal targets using BARE_METAL. That reduces implementation drift and makes cross-environment parity meaningful. The boot edition replaces allocation, I/O and worker coordination; it is not a Linux program hidden inside an image. Its portability is nevertheless constrained by x86 instructions, firmware, memory maps and supported devices. VM demonstrations are not proof of broad physical-hardware compatibility. [S3, S5, S6]

### 2. Layout-aware Q8 decode

The exporter stores each matrix row as signed int8 weights followed by block scales and aligns sections/rows to 64 bytes. Version 2 uses FP16 scales; version 1 retains FP32 scales. FAST_Q8=1 quantizes activations once per matmul and uses AVX2 integer multiply-add instructions plus scale conversion; FAST_Q8=0 keeps FP32 activations. Fused QKV and gate/up layouts reduce barriers, and head-major KV storage supports parallel grouped-query attention. This is a coherent bandwidth/dispatch design, not evidence that assembly is inherently faster than C++. [S6, S7, S11]

### 3. Small-model training with numerical references

The trainer includes a register-blocked 6×16 SGEMM, analytical backward kernels, gradient clipping, AdamW and a live terminal visualization. Its PyTorch harness checks gradients, optimization trajectory and cross-thread agreement. The documented 21-tensor comparison is for a small two-layer verification model; it is not exhaustive validation of every CLI shape or all training runs. [S4, S13]

## Architecture

Phase 1 enters at _start, parses CLI arguments, mmaps the exported model, allocates KV and scratch storage, initializes a clone/futex pool, encodes a prompt, and performs token-by-token prefill followed by sampled or greedy decode. Qwen3 uses 28 layers, 16 query heads / 8 KV heads, per-head QK normalization and tied embedding/output weights. The BPE merge table is generated offline and looked up through an open-addressed hash table at runtime. [S2, S6–S9]

The Linux worker pool statically partitions rows and isolates completion words on cache lines. Idle workers eventually sleep on futex, but the main thread waits for active workers in an unbounded pause loop. Default inference thread count is a literal 32, not a discovered affinity-aware CPU count. This favors a quiet matched machine and can penalize oversubscribed or shared systems. Source inspection confirms that mechanism; the size of the slowdown comes from public issue reports, not measurements made here. [S8, S9, P2]

The bare-metal path transitions from Multiboot into long mode, uses a physical-memory arena, starts AP cores and exposes console chat. It is an experimental single-purpose kernel, not an isolated multiuser OS. The trainer has separate model layout/SGEMM/backprop code and shares selected syscall/math helpers. Clear module boundaries and extensive comments help auditability, but manually maintained offsets and assembly arithmetic increase the cost of checking every shape, length and failure path.

## Performance and correctness evidence

| Claim / evidence | Assessment |
|---|---|
| FAST_Q8=1 decode 18–36% above llama.cpp Q8_0 across 1–40 threads | Author's EPYC 7642, 34-token prompt, 64-token generation, three-run comparison. At 40 threads the table reports 125.86 tok/s mean and 126.81 peak; do not present the peak as the mean. No independent reproduction here. |
| 64/64 greedy tokens and cosine 0.9996517 vs PyTorch FP32 | Useful single-prompt regression evidence, not broad task-quality equivalence. The same table reports maximum logit difference 0.603448; quantized activations are not numerically identical to FP32. |
| OS matches Linux on five prompts and SMP configurations | Tests shared-engine consistency across environments, not an independent correctness oracle for that engine. Screenshots prove much less than reproducible logs. |
| Trainer gradients / ten-step AdamW trajectory | Real threshold-based harness exists and returns failure when its gates fail. Documented results remain author reports; public issue reports add corroboration, not our replication. |
| make check / check-all | Inspect binary size/type/sections/dynamic dependencies and line counts. These targets do not invoke the numerical Python suites. |
| verify_ref.py inference parity | Computes and prints token/logit comparisons, but mismatch does not trigger an explicit failing exit status. A successful process exit alone is not a numerical pass. |

Sources: [S1–S5, S12–S14]. test_math.py contains explicit error assertions for math and v1/v2 matmul cases; verify_train_ref.py and verify_os.py aggregate gates and exit nonzero on failure. Those are stronger automated gates than verify_ref.py's printed diagnostics. No CI workflow was found to run them automatically. Python assertions also depend on not disabling assertions.

The comparison does not freeze a llama.cpp SHA, full command/configuration, immutable GGUF provenance, or a table-producing paired benchmark script. Issue #8 asks for those details and points out differing OS table values. The README acknowledges that llama.cpp uses batched prefill while llm.asm uses token-wise GEMV: decode advantage cannot be generalized to time-to-first-token, long prompts, throughput under concurrency or overall service latency. An attribution of the OS advantage specifically to huge pages needs an ablation with comparable Linux page settings; multiple environment changes are bundled. [S1–S3, P2]

Open reports #9/#10 describe default-thread oversubscription and roughly 20× degradation under competing CPU work on a 16-thread desktop. These are unreplicated reporter measurements. The hardcoded default and spin-wait source make the concern operationally credible, without establishing a universal ratio. Reports #11/#13 describe invalid training shapes and stale trainer size/TUI numbers; the checked documentation itself disagrees on trainer size (32,752 versus 32,944 bytes). [S1, S4, S8–S10, P2]

Before using the speed claims, pin both engines, model/tokenizer conversions, CPU affinity and thread counts; measure cold/warm load, prefill, decode, context depth, concurrent interference and tail latency. Preserve per-run records and enforce numerical gates across multilingual, long-context, sampled and multi-turn workloads. This echoes the public [Inference Optimization Playbook review](inference-optimization-playbook.md): adopt its quality-before-speed discipline, not unqualified transfer of results from one rig. That notebook covers a different, largely GPU/MoE problem; it does not independently validate this implementation.

## Security and privacy

**Trust model files as executable-risk inputs, not harmless data.** model_init checks magic/version, but reads the header without first enforcing a minimum file length and resolves offsets/dimensions into mapped memory without comprehensive file-bound checks. Allocation arithmetic and kernel shape assumptions are not comprehensively checked. The activation-quantization buffer has a fixed Q8_MAX_K limit while the loader accepts dimensions from the file. Malformed/truncated files can therefore cause faults or unsafe memory accesses; no exploit was attempted or proven. The checkpoint loader does perform minimum-size and parameter-size checks, but initializes layout using file-supplied dimensions before completing size validation. [S6, S7, S10]

Trainer gpt_init_layout divides dimension by head count without checking the remainder at that point. The surrounding argument path lacks a comprehensive shape-validation gate; this agrees with issue #11's report. Treat documented SIMD dimensions as prerequisites, not enforced guarantees. Do not expose model upload, arbitrary CLI flags, or checkpoint loading to untrusted clients. [S10, P2]

The inspected application paths are local file/console programs, with no inference network endpoint or credential-management layer. Auth/CORS are therefore not applicable to the present CLI; proposed HTTP/serial relay PRs are not functionality shipped in the reviewed commit. The verification tooling launches binaries/QEMU and uses control sockets, which is a separate development-tool boundary. Adding a relay requires authentication, limits, isolation and output handling rather than assuming a tiny kernel provides them. [S8, S14, P2]

Local execution avoids a required remote inference service, but is not a complete privacy guarantee. Prompts can appear in process arguments, stdout/stderr, terminal scrollback, serial consoles and verification logs. Debug dumps include training batches and weights; checkpoints may retain information from sensitive training data. Raw token bytes are written to the terminal without a general terminal-control sanitization layer. Use a disposable least-privilege environment, trusted pinned model files, restricted logs and explicit output-file permissions. sys_openat_wr creates/truncates output files with mode 0644 subject to umask; select private directories/umask for sensitive artifacts. [S9, S10, S15]

## Recovery and operational limits

- Chat retains KV state in RAM and resets the logical position when context fills; /clear is a conversation reset, not persistence or secure memory erasure. A reset discards history rather than summarizing or paging it. Restart loses the session. [S8]
- Append-only chat retains empty think blocks/reasoning from previous turns. The code confirms retention; issue #12 reports a difference from official Qwen3 history formatting. That is a template-compatibility concern, not demonstrated universal quality loss. [S9, P2]
- Training checkpoints contain architecture metadata, vocabulary and weights. They do **not** serialize Adam moments or RNG state; load does not restore the saved step into the training loop, which starts at zero. “Resume” is a weight warm-start, not exact optimizer/scheduler recovery. [S10]
- Checkpoint save truncates the destination and writes directly, with no temporary-file atomic rename or fsync transaction. An interrupted save can destroy the previous checkpoint. Keep versioned backups; implement atomic saves and full-state round-trip tests before relying on long runs. [S10, S15]
- Worker completion has no active-job timeout/recovery protocol. A stalled worker can stall inference; the bare-metal environment has fewer containment layers than a Linux process. Plan external timeout/restart controls for experiments. [S8]

## Comparison

| Aspect | llm.asm | llama.cpp | llm.c |
|---|---|---|---|
| Best fit | Learning assembly kernels, bare-metal inference, tiny-model training | General local inference and server integration | Learning C/CUDA training implementations and PyTorch-reference comparisons |
| Model/platform scope | Narrow Qwen3-0.6B/custom format and character trainer; x86-64 | Broader inference ecosystem and GGUF tooling | GPT-style training focus; CPU reference and CUDA implementations |
| Service layer | Console/CLI; no shipped HTTP API in reviewed main | Documented OpenAI-compatible server | Training-focused, not a substitute inference service |
| Main tradeoff | Minimal runtime surface, high manual correctness/portability burden | Larger code/dependency surface, broader operational functionality | Easier high-level code inspection than assembly; different numerical/workload scope |

Alternative READMEs were checked publicly, not benchmarked or security-audited. Prefer the existing llama.cpp path for practical local serving unless a measured, validated requirement justifies maintaining this specialized runtime. Prefer llm.c for a more approachable training-code study; choose llm.asm specifically when instruction-level implementation or boot/runtime design is the learning objective. [P4, P5]

## Self-Hosting Notes

No hosted service or paid API is required. Plan a compatible x86-64 CPU, NASM/binutils, Linux for phases 1/3, and an offline model conversion step. The checked exporter uses NumPy and a local safetensors/tokenizer/config input rather than requiring PyTorch at inference runtime. Optional parity testing adds torch/transformers; bare-metal experiments add QEMU/KVM and GRUB/ISO tooling. These tool dependencies are not version-locked. [S2–S5, S11–S14]

Start in an isolated VM/process environment with known-good files. Select thread count explicitly and leave headroom on shared CPUs; do not blindly accept 32 workers. Pin source, weights and converter together, retain the original export and use separate checkpoints for each save. Run the explicit numerical harnesses, inspect inference comparison output or add failing thresholds, and test malformed inputs and interrupted saves before widening use. Do not boot experimental kernels on an important host simply because a VM screenshot exists.

The Qwen model card and actual LICENSE were retrieved anonymously. At model revision c1899de289a04d12100db370d81485cdf75e47ca, the weight license is Apache-2.0, not this repository's MIT license. Redistribution of converted weights needs the applicable license/notice handling and identification of changes; code licensing does not replace model or dataset obligations. TinyShakespeare corpus provenance/redistribution terms were not independently audited in this review. No upstream code or model weights were extracted into this publication. [S16, P3]

## Maturity and verification limits

Public metadata on 2026-11-26 reported creation 2026-11-25 07:28:51 UTC, last push 2026-11-25 15:42:44 UTC, 1,361 stars, 195 forks and 14 open issue/PR items (eight issues, six PRs in the returned list). Releases returned an empty list. Rapid visibility is not a maturity or safety signal; a shallow checkout does not establish a long maintenance record. Unmerged PRs requesting other models, ARM or relays were not treated as supported features. [P1, P2]

Static checks verified the described source paths, loader/checkpoint behaviors, benchmark qualification gaps and harness exit semantics. No assembly build, runtime smoke test, fuzzing, numerical test, performance test, GPU job or model download was performed. External issue results remain attributed reports. The review is not a complete instruction-by-instruction audit, hardware certification or proof of exploitability. Publication artifact checks cover markup, provenance, template integrity and diff hygiene—not upstream runtime correctness.

## Evidence

All S-links pin the reviewed source revision. Public APIs/issues and alternative documentation are observations retrieved 2026-11-26.

- [S1 — README.md](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/README.md)
- [S2 — 01-qwen3-inference/README.md](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/01-qwen3-inference/README.md)
- [S3 — 02-baremetal-os/README.md](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/02-baremetal-os/README.md)
- [S4 — 03-minigpt-train/README.md](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/03-minigpt-train/README.md)
- [S5 — Makefile](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/Makefile)
- [S6 — shared/transformer.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/shared/transformer.asm)
- [S7 — shared/matmul.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/shared/matmul.asm)
- [S8 — shared/threads.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/shared/threads.asm)
- [S9 — shared/tokenizer.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/shared/tokenizer.asm)
- [S10 — 03-minigpt-train/main.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/03-minigpt-train/main.asm)
- [S11 — scripts/export_weights.py](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/scripts/export_weights.py)
- [S12 — scripts/verify_ref.py](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/scripts/verify_ref.py)
- [S13 — scripts/verify_train_ref.py](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/scripts/verify_train_ref.py)
- [S14 — scripts/verify_os.py](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/scripts/verify_os.py)
- [S15 — shared/syscalls.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/shared/syscalls.asm)
- [S16 — LICENSE](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/LICENSE)
- [Additional source — 01-qwen3-inference/main.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/01-qwen3-inference/main.asm)
- [Additional source — 03-minigpt-train/model.asm](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/03-minigpt-train/model.asm)
- [Additional source — scripts/test_math.py](https://github.com/alesha-pro/llm.asm/blob/48feccbfd57cb669440f31ff64958d95bb8b848e/scripts/test_math.py)
- [P1 — GitHub metadata](https://api.github.com/repos/alesha-pro/llm.asm), [releases](https://api.github.com/repos/alesha-pro/llm.asm/releases).
- P2 — Public reports: [#8](https://github.com/alesha-pro/llm.asm/issues/8), [#9](https://github.com/alesha-pro/llm.asm/issues/9), [#10](https://github.com/alesha-pro/llm.asm/issues/10), [#11](https://github.com/alesha-pro/llm.asm/issues/11), [#12](https://github.com/alesha-pro/llm.asm/issues/12), [#13](https://github.com/alesha-pro/llm.asm/issues/13).
- [P3 — Qwen3-0.6B model card](https://huggingface.co/Qwen/Qwen3-0.6B/blob/c1899de289a04d12100db370d81485cdf75e47ca/README.md), [Apache-2.0 LICENSE](https://huggingface.co/Qwen/Qwen3-0.6B/blob/c1899de289a04d12100db370d81485cdf75e47ca/LICENSE).
- [P4 — llama.cpp](https://github.com/ggml-org/llama.cpp), [P5 — llm.c](https://github.com/karpathy/llm.c).

---

**Attribution:** Alexey Fateev (alesha-pro), llm.asm, MIT. Qwen model attribution and terms are separate. This is independent public-source analysis; reported performance is not a reviewer measurement.
