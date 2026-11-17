# s-means (suayptalha/s-means)

**Repo:** https://github.com/suayptalha/s-means
**Author:** Şuayp Talha Kocabay; accompanying research article credits Kamer Ali Yüksel and Kerem Yalçın as coauthors.
**License:** MIT; retain the copyright and permission notice when redistributing substantial code.
**Reviewed:** 2026-11-17 (UTC)
**Revision:** 83c20d09621bf8be2b7ca896359d17c1cca54f0c, default main branch; all seven package modules, both test files, packaging, README, and four benchmark JSON archives.
**Verification:** Static code review and independent arithmetic over archived results; no package installation, source execution, pytest, GPU execution, or benchmark reproduction. An algebraic finalization counterexample is derived below, not a measured training run.
**Stack:** Python ≥3.10; PyTorch, NumPy, scikit-learn; optional Triton/CUDA.
**What it is:** A dense Euclidean clustering/vector-quantization library pursuing good centroids within a small pass budget, with tensor and scikit-learn interfaces. It is not semantic search, a vector database, or automatic selection of cluster count.

---

## Verdict

⚠️ **Interesting research implementation; not yet a drop-in production replacement.** Distortion-aware revival and fused assignment are worth studying, and the archived accuracy gains are substantial on structured synthetic workloads. However, the benchmark harness is absent, GPU speed is often worse, the declared scikit-learn floor is incompatible with an imported API, and the low-count finalizer has an analytically demonstrable bias. Validate correctness and equal-quality performance on representative data before adopting.

## What It Is

s-means builds on the few-epoch mini-batch strategy of Meta/Faiss e-means. Users provide a dense N×D matrix, K, and an epoch budget; the library returns centroids and optionally nearest-centroid labels/inertia. The sklearn estimator adds fit, predict, transform, score, cloning and pipeline integration. Its scope is squared-Euclidean quantization, not guaranteed recovery of semantic or nonconvex clusters.

The [author's article](https://suayptalha.github.io/s-means-blog/) says EvoForest evolved the algorithm on eight CPU training tasks across four islands and nine rounds. Fitness included held-out test MSE from those training tasks, train MSE, and runtime/memory penalties. Those particular test sets therefore participated in algorithm selection; the separate twelve-task suite is claimed to be unseen. The repository does not include the evolution runs or benchmark-generating harness needed to independently audit that separation.

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Public tensor API | core.py: smeans, assign_clusters, SMeansResult |
| Estimator | sklearn.py: dense NumPy validation, CPU default, optional GPU |
| Algorithm recipe | _recipe.py: dimension-dependent batch/step scaling, fractional budgets, subsampled initialization |
| CPU | _cpu.py: float32 matrix tiles; float64 final-pass accumulators |
| GPU | _gpu.py: eager Python loop; native PyTorch or optional Triton |
| Kernels | _triton_kernels.py: assignment, variance proxy, EMA/pass sums, split, finalization |
| Packaging | setuptools; NumPy ≥1.24, torch ≥2.1, sklearn ≥1.3; Triton ≥3.0 optional |

### Actual algorithm

1. Sample m=min(N,max(4K,512)) rows. Select initial centers in batched rounds, weighting nearest **squared** distance to power 1.5. Thus the code uses Euclidean distance cubed, not Euclidean distance to power 1.5. The D¹·⁵ name needs this convention explained; this is not standard sequential k-means++ and no k-means++ approximation guarantee follows.
2. Choose a batch size from empirical power laws, switching regime at D=16. Use shuffled passes, a cosine-decayed learning rate, moving usage and SSE estimates.
3. Every five steps until approximately 85% of the budget, revive low-usage centers by splitting sampled high-distortion donors. An anisotropic feature-scale proxy and additive Rademacher perturbations avoid the baseline's direct multiplication of center coordinates.
4. Weight later batches more heavily in the final pass, then shrink its cluster means toward tracked EMA centers. A final assignment yields labels and inertia when requested on GPU; CPU always performs it.

The variance proxy is computed from squared cluster-sum deviations, not a conventional unbiased feature variance: cluster counts enter quadratically. These are engineering heuristics, not a proof of convergence or monotonic SSE reduction. Revival can also occur during final-pass accumulation; stored sums are not cleared or transferred when a center is split, so a center's final estimate can mix pre- and post-split assignments.

### Cost and memory are bounded, not free

With T passes and S mini-batch steps, dense assignment costs approximately O(TNKD), plus O(SKD) update work and O(mKD) seeding. Full-output assignment adds O(NKD). Initial and per-pass permutations require O(N) space/work; this is an in-memory algorithm, not a streaming partial_fit API. The source's O(mK) seeding description suppresses D.

CPU assignment scratch is a 512×256 distance tile by default. Triton avoids materializing a full batch-by-K matrix, while native GPU assignment still materializes chunk-by-centroid tiles, up to 8192×4096. Persistent state includes the input, O(KD) centers/accumulators and O(N) permutation/output arrays. sklearn transform returns an N×K host array despite chunking its intermediate computation. “Zero-allocation kernels” does not mean zero allocations or zero-copy behavior throughout: centroids are cast/repacked, batches gathered, scalar values synchronized, and results may move to CPU.

## Correctness and API Findings

### 1. Low-count finalization is not the advertised weighted mean

Both CPU/native and Triton finalizers divide pass_sums by max(pass_counts,1), although final-pass weights can be below one. For a center with one weighted observation x=10, weight 0.65, sum 6.5, EMA center 10 and tau=0.2, the intended mean is 10. The implemented formula returns approximately **7.3235**, pulling toward the origin even though the observation and prior agree. This algebraic counterexample applies when 0<count<1; it is not an end-to-end runtime reproduction. It also breaks blanket translation-invariance claims for such cases. The same clamp occurs in both backends, so agreement between them would not detect it.

### 2. Declared sklearn minimum does not match imports

sklearn.py imports sklearn.utils.validation.validate_data, which the [upstream documentation](https://scikit-learn.org/stable/modules/generated/sklearn.utils.validation.validate_data.html) marks as added in 1.6. pyproject.toml permits 1.3. Because __init__.py eagerly imports SMeans, this affects importing the package even for tensor-only users on older allowed environments. Private sklearn validation APIs and newer estimator-check arguments further increase version sensitivity; a supported-version test matrix is needed.

### 3. sample_weight is approximate outside a narrow path

Integer-like weights with total ≤1,000,000 are expanded with np.repeat. Other nonuniform weights are used to bootstrap a training set, not to perform exact weighted centroid updates. Rare active points may disappear from the resample. The integer-equivalence check uses np.allclose, so sufficiently tiny positive weights can be deemed zero and rounded away. Uniform integer scaling can change the effective training length. The test suite explicitly lists check_sample_weight_equivalence_on_dense_data as an expected failure: the README's unqualified “full compatibility”/check_estimator claim needs that caveat. Sparse input and partial_fit are not implemented.

### 4. Precision, validation and metric caveats

- Training converts CPU data to float32 even if the sklearn output dtype is float64. GPU auto uses BF16 assignment with Triton on SM80+; final GPU inertia therefore need not be full-precision Euclidean inertia.
- Squared norms minus twice the dot product are cancellation-prone for large offsets; clamping negatives to zero cannot restore lost distances. Additive revival alone does not establish numerical shift invariance.
- Core validation checks rank, positive K and N≥K, but does not comprehensively validate finite inputs, nonzero D, integer K, all configuration ranges or supported dtypes. make_recipe runs before the explicit positive-budget check; zero/negative budgets can fail with arithmetic errors instead of a clean contract error.
- CPU compute_labels=False discards labels after computing them and retains inertia; GPU skips both. time_s excludes some preparation/transfers, so it is not a complete application latency metric.
- dead_clusters counts low final-pass usage, not empty clusters after final reassignment; n_iter counts mini-batch updates, not full epochs. CPU and GPU use different shuffle/split RNG paths, and GPU reductions need not be bitwise deterministic.
- In the Triton dispatch, centroids may be padded before the small-batch/K fallback. That fallback passes unpadded x and padded centers to native matrix multiplication: inspect/test nonmultiple-of-16 D with K<16 or a final batch<16 before relying on it. This is a static shape-path concern, not a GPU-reproduced failure.

## Benchmarks: What the Evidence Actually Supports

The four JSON archives are **author-supplied aggregate measurements**, not independent replication or per-seed raw traces. We independently recomputed the following from their fields:

| Suite / method | Mean test-error reduction vs recorded e-means reference | Median time ratio (lower is better) | Median GPU workspace ratio |
|---|---:|---:|---:|
| A100 Triton, 9 tasks | 55.205% | **2.117×** | 0.875× |
| L4 Triton, 9 tasks | 54.350% | **2.109×** | 0.875× |
| T4 native, 9 tasks | 53.814% | 0.881× | 0.658× |
| T4 Triton, 9 tasks | 54.029% | **4.586×** | 0.360× |
| CPU, 12 tasks | 19.670% | 0.977× | N/A |

CPU median sklearn time divided by s-means time is 2.236×. These checks establish internal arithmetic consistency, **not** benchmark correctness. A100/L4's headline quality and memory gains conceal roughly twice the median elapsed time at equal epochs. Native and Triton results must not be combined into one best-of-everything claim.

### Coverage and fairness

The README reports nine GPU tasks × three seeds and twelve CPU tasks × five seeds, not hundreds of independent real datasets. GPU training sizes range from 100k to 1M rows, D=8–256 and K=512–2048; most workloads are synthetic, with Covertype the named real GPU dataset. CPU includes raw/standardized variants of Covertype and digits plus synthetic families, so twelve rows are not twelve independent dataset families. Covertype GPU gains are only about 2–3%, much smaller than the ~54–55% aggregate driven by synthetic cases.

The article reports exact-shape/skew warmups, CUDA allocator peak deltas, and T4 native references because upstream Triton paths fail there. These are useful disclosures, but the checkout contains only a result summarizer, not dataset generators, train/test split and preprocessing code, benchmark runner, pinned e-means revision, complete seed runs or a locked environment. GPU JSON includes system/version strings and some standard deviations; these do not reproduce the experiment by themselves. We did not verify whether all implementations used identical initialization budgets, timer boundaries, restart counts or full-precision evaluation.

Equal epochs are not equal work: s-means adds geometric seeding, while e-means can exploit CUDA Graphs. The archived single-task “1 epoch beats 8” Pareto result is promising but does not establish universal dominance. Fair adoption decisions need equal-quality/equal-wall-clock curves, tuned MiniBatchKMeans and KMeans baselines, multiple restarts, initialization ablations, and held-out real embedding datasets.

### Red flags worth resolving, not proof of misconduct

- CPU covtype_std records test MSE near 250,005 while train MSE is about 4.6–5.2 across methods. This large disparity warrants a preprocessing/split audit; without the runner we cannot identify its cause.
- Leave-one-out ablation uses a full-variant mean gain of 19.862% and median time ratio 1.173, not the main table's 19.670% and 0.977. These appear to be different measurement sets and should not be silently interchanged. Removing distortion revival reduces gain to 7.093%; removing final shrinkage changes it only to 19.860%, weak evidence for that component's practical contribution.
- The two OS memory cases show an unchanged 956.1 MB ru_maxrss high-water mark. Zero increase above a historical peak does **not** mean zero allocations, zero memory cost or proven equivalence. GPU peak_delta_mb is workspace overhead, not total device-resident memory.
- “MSE” in the API is inertia/N, a mean squared vector distance summed over features, not per-coordinate SSE/(ND). Compare like-for-like definitions.

## Security, Installation and Maturity

No network clients, credential loading, service endpoints, telemetry or dynamic model downloads were found in the inspected package modules. Auth/CORS are not applicable to this local numerical library. Arrays stay in the local process/device in the inspected paths; no security audit of PyTorch/Triton or transitive dependencies was performed.

Installation pulls a substantial scientific-computing stack; even CPU use requires torch and sklearn. Dependencies have lower bounds but no lockfile or upper constraints. Optional Triton JIT execution, CUDA compatibility and large allocations are operational risks, not evidence of malicious behavior. Large K, integer-weight expansion and transform can exhaust memory. Use an isolated environment and explicit device/precision settings after correcting the compatibility floor; do not install this directly into an important existing environment without testing.

Version is 0.1.0, classified Beta in packaging. Public GitHub metadata retrieved 2026-11-17 shows creation and last push on 2026-11-13, 16 stars, zero forks, zero open issues, and no GitHub releases. Popularity and a zero issue count are not quality evidence. The shallow checkout does not establish historical maintenance depth.

Two test files contain ten test functions: CPU synthetic quality/determinism, shapes, fractional epochs, limited validation, pipeline/grid search, weights and sklearn checks. The revival test's total_splits≥0 assertion does not prove revival occurred. No tracked CI workflow or GPU parity/precision suite was found. Tests were inspected, **not run**; no pass count is claimed.

## Comparison and Practical Fit

| Alternative | Why choose it instead / comparison needed |
|---|---|
| [scikit-learn KMeans / MiniBatchKMeans](https://scikit-learn.org/stable/modules/clustering.html#k-means) | Established CPU APIs, sparse/weighted workflows and MiniBatchKMeans partial_fit; evaluate tuned restarts and equal-quality latency rather than epoch counts alone. |
| [Faiss e-means](https://github.com/facebookresearch/faiss/tree/main/contrib/e_means) | Direct few-epoch baseline; fewer added heuristics and graph-based GPU execution. Pin the exact implementation and match precision/hardware before comparison. |
| [Faiss clustering](https://github.com/facebookresearch/faiss/wiki/Faiss-building-blocks:-clustering,-PCA,-quantization) | A broader vector-quantization toolchain; useful when clustering is one stage of a retrieval system rather than a standalone sklearn estimator. |

Best fit today: research into mini-batch quantization, distortion-aware revival, and bounded-scratch assignment. Before production: fix low-count finalization and dependency floor, add GPU fallback and pathological-input tests, publish benchmark-generation code, verify real datasets with train-only preprocessing, and evaluate accuracy/time/memory together. No code extraction was made.

---

## Evidence and Verification Limits

All repository links below are pinned to the inspected revision:

- [README and claims](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/README.md)
- [Recipe / initialization](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/smeans/_recipe.py)
- [CPU loop / finalization](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/smeans/_cpu.py)
- [GPU runner](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/smeans/_gpu.py) and [kernels](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/smeans/_triton_kernels.py)
- [Estimator / weights](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/smeans/sklearn.py), [core API](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/smeans/core.py), [manifest](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/pyproject.toml)
- [Archived measurements](https://github.com/suayptalha/s-means/tree/83c20d09621bf8be2b7ca896359d17c1cca54f0c/benchmarks/results) and [tests](https://github.com/suayptalha/s-means/tree/83c20d09621bf8be2b7ca896359d17c1cca54f0c/tests)
- [MIT terms](https://github.com/suayptalha/s-means/blob/83c20d09621bf8be2b7ca896359d17c1cca54f0c/LICENSE)

The accompanying blog was consulted for methodological context, not independently reproduced. No source code was executed, no datasets downloaded and no GPU/device accessed. Performance and generalization remain author claims; arithmetic checks and static code-derived concerns are identified separately.

**Attribution:** suayptalha/s-means, MIT, copyright 2026 Suayp Talha Kocabay.
