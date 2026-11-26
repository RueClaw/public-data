# Modal GPU Glossary

**Source:** https://modal.com/gpu-glossary/readme
**Author:** Modal; no individual byline identified on the inspected pages.
**Date:** No publication or update date identified on the inspected pages.
**Reviewed:** 2026-11-26 (UTC)
**Retrieved:** 2026-11-26 (UTC); anonymous HTTP 200 responses; raw HTML SHA-256 fingerprints below.
**Verification:** Static reading of the introduction and five linked entries, with targeted NVIDIA documentation checks. No installation, compilation, source execution, GPU calls, benchmarks, or account use.
**Topic:** NVIDIA GPU hardware, CUDA execution, and compilation terminology.
**Content license:** The public source repository identifies glossary content as CC BY 4.0 and remaining repository files as MIT. This review is independent analysis, not a redistributed glossary.

---

## Verdict

📚 **Good reference, not a specification.** A useful cross-layer map for developers who encounter CUDA terminology while working with GPU libraries or kernels. The sampled pages connect hardware, execution, and compiler concepts well, but several short explanations need correction or architecture-specific qualification before they become implementation advice.

---

## Summary

The introduction argues that GPU documentation is fragmented: understanding compiler targets requires connecting concepts such as streaming multiprocessors, compute capability, and machine instructions. Modal's solution is a linked dictionary that can also be read linearly. That is a credible educational goal, not a research result or a measured performance claim. [S1]

The strongest sampled material distinguishes PTX virtual targets from physical SM targets, explains why a marketing architecture name is not identical to a major SM version, and explicitly acknowledges Hopper's architecture-specific and Blackwell's family-specific target suffixes. The Ada 8.9 versus Ampere example is a particularly useful warning against simplistic version reasoning. [S2, S4, N1]

The execution pages offer an approachable explanation of latency hiding through selecting ready resident warps. However, the warp-scheduler entry mixes that sound idea with broad claims about GPU context switches and programmer-managed L1 caches. The thread entry's lock-step framing also needs a prominent Volta-and-later independent-thread-scheduling caveat. These are places where a beginner could turn a teaching shortcut into an incorrect programming assumption. [S3, S5, N2, N3]

This is explicitly a NVIDIA-focused resource: the source repository says it concentrates on GPUs used by Modal. The CUDA C++ page also links to Modal's product guide. That commercial context is transparent and does not invalidate the explanations, but the generic title should not be mistaken for balanced coverage of AMD, Intel, or Apple GPU programming. No purchase or Modal account is needed to read the inspected material. [S6, R1]

## Inspected Scope and Method

Read the entire introduction plus these five directly linked entries: **Streaming Multiprocessor Architecture**, **Warp Scheduler**, **Compute Capability**, **Thread**, and **CUDA C++**. This deliberate sample spans device hardware, device software, and host software; it is not random, statistically representative, or exhaustive. Other glossary entries, diagrams, navigation behavior, translations, and linked textbooks were not audited.

The submitted README URL returned HTTP 200 without authentication and without a URL change. Its own glossary links and the linked public source repository corroborate the document identity. No HTML canonical-link element was found in the retrieved introduction, so the stable final URL is used as the canonical review identity rather than claiming publisher-supplied canonical metadata. Search of the public review/index material found no prior review for this URL or the linked source repository.

Primary-reference checks were targeted: current NVCC documentation (displayed as 13.5), current PTX ISA documentation (displayed as 9.5), and the versioned CUDA C++ Programming Guide 12.8.1 for language examples and longstanding semantics. Large vendor documents were not read end to end; initial extraction was truncated, and the PTX target directive was additionally inspected in the full downloaded HTML. The old unversioned CUDA C guide URL now redirects to the reorganized CUDA Programming Guide; old section fragments should not be assumed to survive that move. [N1–N4]

## Key Claims and Evidence Assessment

| Source claim | Assessment |
|---|---|
| Hyperlinks help connect layers of the stack. | Supported by the inspected pages' actual cross-links. Educational effectiveness was not measured. [S1–S6] |
| SM family/version and marketing architecture are not interchangeable. | Sound. The NVCC architecture tables support the Ada/Ampere distinction and the need to select explicit targets. [S2, N1] |
| PTX has forward compatibility, with exceptions for a/f suffixes. | Useful and substantially right, but keep direction and scope precise: ordinary PTX targets support later devices under the documented model; a-targets are architecture-specific; f-targets support later targets within the defined family, not arbitrary backwards compatibility across minor versions. Driver/toolchain support still matters. The SemVer analogy is not the actual compatibility contract. [S4, N1, N3] |
| Warp switching avoids register-context save/restore. | Sound for selecting among resident warps whose state is already held on the SM. It is not a guarantee that GPU process/context preemption is free. The one-nanosecond comparison is an order-of-magnitude illustration, not a portable measured constant. CPU OS context switches and CPU hardware SMT are also different mechanisms. [S3, N2] |
| L1 caches can be entirely programmer-managed. | Misleading as stated. CUDA shared memory is the explicit software-managed scratchpad/cache; hardware-managed L1 is a distinct interface even when the two share on-chip storage. Resident scheduling does not by itself guarantee good cache hit rates. [S3, N2] |
| Threads execute in lock-step for performance. | Converged execution is useful, but lock-step must not become an implicit synchronization guarantee. PTX documents per-thread execution state and sub-warp divergence/reconvergence starting with Volta. Use the applicable synchronization primitives for communication. [S5, N3] |
| CUDA kernels take pointers and shared memory uses the shared keyword. | The sampled CUDA C++ page is too narrow on arguments and wrong on spelling: kernels may also accept scalar values, and the CUDA specifier is `__shared__`, not `shared`. NVIDIA's vector-add example accepts an integer length alongside pointers. Its void-return statement is correct. [S6, N2] |

## Strengths

- **Good conceptual routing:** concise pages link from a term to prerequisites and related concepts rather than isolating definitions. The split between hardware, device software, and host software gives readers a useful mental map. [S1–S6]
- **Better than an entirely generic GPU explainer:** compute-capability coverage includes both a and f target exceptions, showing awareness of post-Hopper details. This is evidence of topic currency, not proof every page is current. [S4]
- **Primary-source escape hatches:** the architecture and compatibility entries point to NVIDIA specifications. These links let a reader graduate from an analogy to the actual contract. [S2, S4]
- **Open attribution and reuse terms:** the linked repository exposes source content and states a CC BY 4.0 content license, allowing attributed adaptation subject to the license. No wholesale extraction was needed for this review. [R1]

## Gaps & Limitations

### Precision matters more than breadth

The shared-memory spelling error is small but directly actionable. The cache/context-switch conflation and lock-step framing are more consequential because they affect performance reasoning and synchronization correctness. Treat “one CUDA core executes one thread's instructions” as a simplified arithmetic-lane explanation, not a universal mapping of logical threads to dedicated cores or of every instruction to the same functional unit. [S3, S5, S6]

### Citations are useful but uneven

The sampled architecture pages cite NVIDIA directly, while the thread and CUDA C++ explanations lean heavily on internal links. The warp-scheduler entry cites a 1991 CPU-cache paper via ResearchGate; that is historical context, not evidence for present-day cross-platform nanosecond/microsecond constants. That paper was not independently evaluated here. The introduction's mentions of textbooks and community discussion describe its process but do not establish fact-by-fact review or reproducible technical validation. [S1–S6]

### Currency is observable only in part

Hopper/Blackwell suffix coverage is a positive signal. Missing visible publication/update dates and a missing pinned deployed revision make comprehensive freshness harder to establish. The source GitHub repository was used for identity and license attribution, not assumed to be byte-identical to the deployed site. This review pins retrieved HTML hashes instead. Website scaffolding changes can alter those hashes without changing article prose.

### Vendor and learning-path limits

Modal's NVIDIA and hosting perspective is useful for its audience but not a vendor-neutral GPU taxonomy. These sampled pages are a reference aid, not a complete course with exercises, correctness tests, profiling methodology, or measured speedups. No claim is made about the quality of uninspected glossary entries or suitability for a specific application.

## Alternatives and Recommended Use

1. **NVIDIA CUDA Programming Guide:** prefer the current official guide for a structured learning path and the versioned guide matching a deployed toolkit for precise semantics. It is longer, but the current guide explicitly separates introductions, practical programming, advanced topics, features, and technical appendices. [N4]
2. **NVCC manual and PTX ISA:** use these for exact compiler flags, target support, compatibility, and execution-model qualifications. They are denser and not a replacement for an introductory glossary. [N1, N3]
3. **For another GPU ecosystem:** choose that vendor's programming and architecture documentation rather than translating CUDA terms literally. No AMD/Intel/Apple documentation was evaluated in this bounded review, so this is a scope recommendation, not a comparative quality ranking.

Recommended workflow: use Modal to learn the term and follow its links; check the relevant official specification and actual device/toolkit version before writing synchronization code or selecting deployment targets. Benchmark performance claims on the intended workload rather than inferring them from glossary analogies.

## Sources

- **S1:** [Introduction / README](https://modal.com/gpu-glossary/readme).
- **S2:** [Streaming Multiprocessor Architecture](https://modal.com/gpu-glossary/device-hardware/streaming-multiprocessor-architecture).
- **S3:** [Warp Scheduler](https://modal.com/gpu-glossary/device-hardware/warp-scheduler).
- **S4:** [Compute Capability](https://modal.com/gpu-glossary/device-software/compute-capability).
- **S5:** [Thread](https://modal.com/gpu-glossary/device-software/thread).
- **S6:** [CUDA C++](https://modal.com/gpu-glossary/host-software/cuda-c).
- **R1:** [modal-labs/gpu-glossary — identity and license statement](https://github.com/modal-labs/gpu-glossary).
- **N1:** [NVIDIA CUDA Compiler Driver manual](https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html), especially GPU architecture/code options and real/virtual architecture feature lists.
- **N2:** [CUDA C++ Programming Guide 12.8.1](https://docs.nvidia.com/cuda/archive/12.8.1/cuda-c-programming-guide/index.html), especially Programming Interface vector-add example, Shared Memory, and Binary Compatibility; versioned reference, not a claim of latest release.
- **N3:** [PTX ISA](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html), especially Independent Thread Scheduling and the .target directive / architecture-family table.
- **N4:** [Current CUDA Programming Guide](https://docs.nvidia.com/cuda/cuda-programming-guide/index.html), organization and learning-path overview.

## Retrieval Fingerprints

SHA-256 of anonymous raw HTML response bytes retrieved 2026-11-26 UTC, not extracted prose or a source-repository commit. All six final URLs match the corresponding source links above.

| Page | SHA-256 |
|---|---|
| S1 | `803e0435f1699896442826a35a2d972966cc45672d24307587393abbbae37596` |
| S2 | `f8e897ec158ba397c281e9f6fb7d48168796ac5d801b246d919e7bafd75125da` |
| S3 | `f079bb7df2d0296fbea5a10f2f1b59b35a33fb19ccfd597190d4bae4d032837d` |
| S4 | `da9212532556eed7e9661c486590878c4608e6fe3042cb1aac6a0f458d022640` |
| S5 | `26e75e83d214ac34c02aa7f5c8e0a75681d53f8d9de1329e19d2c77a71c589b4` |
| S6 | `50d448063bf17b0210e0bc007ac0a1746c08d6b983500645953e051e7641a1fc` |

---

**Attribution:** Modal, *GPU Glossary*, https://modal.com/gpu-glossary/readme; glossary source content licensed CC BY 4.0 according to its public repository. Independent review; no affiliation implied.
