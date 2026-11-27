# Kumo Engine (NVIDIA/kumo-engine)

**Repo:** https://github.com/NVIDIA/kumo-engine
**License:** Apache-2.0 for NVIDIA-owned source; bundled components retain their own terms, including MIT, BSD-3-Clause and PDDL-1.0 vector data.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `f4a29e4492ce282da300f9e02f822d440e8171b2`, main; root documentation, DiskGraph, Engine/core, benchmark harness, REST security, deployment, assets and CI inspected selectively.
**Verification:** Static review only. Anonymous GitHub metadata/source acquisition and public benchmark documentation checked; no installation, source execution, model download, GPU test, cloud call or live deployment probe.
**Stack:** Python, Rust/PyO3, Arrow/Parquet, PyTorch/Lightning, FastAPI, React, Temporal, PostgreSQL.
**What it is:** An out-of-core relational context sampler and predictive graph-ML pipeline, primarily usable as an in-process Python library. The accompanying Studio service is explicitly prerelease, not an equally supported deployment path. [1][2]

---

## Verdict

⚠️ **Interesting — strong disk-backed sampling architecture; evaluate the library before adopting the platform.** Kumo replaces repeated relationship joins with a reusable graph index and time-aware bounded sampling, then trains models rather than merely retrieving rows. Its performance evidence is unusually candid about limitations, but remains vendor-produced and workload-specific; Studio installation, artifact trust, and large-state operations require separate acceptance work. [1–7]

## What It Is

Tables, primary keys, foreign keys and event timestamps become a graph snapshot. Predictive Query Language describes an outcome and horizon; the engine generates labeled training examples and samples each entity's historical neighborhood. Classification, regression, forecasting and recommendation/link prediction are the intended workloads, with explanations, AutoML, embeddings and batch scoring. This is not an LLM inference server, general-purpose transactional graph database, or a pretrained foundation model. NVIDIA directs training-free foundation-model users to separate Structured Data Models and Kumo-TS projects. [1][2]

The local API runs through `kumo.engine` and `kumo_core` without a REST server. Studio adds shared projects, authentication and workflow infrastructure; the root README says it is coming soon and not yet supported. That distinction materially changes both the deployment burden and attack surface. [1][2][8]

## Stack

| Layer | Tech |
|-------|------|
| Public local API | Python 3.11+, Graph/Table/PredictiveQuery/Trainer |
| Graph storage and sampling | Rust DiskGraph, PyO3 bindings, memory-mapped index, Arrow batches |
| Learning | PyTorch/Lightning, graph neural networks; Faiss-related dependencies |
| Service/control plane | FastAPI REST, Temporal workflows/activities, PostgreSQL StateDB |
| UI/deployment | React, nginx, Docker Compose and Helm; Studio prerelease |
| Data/operations | CSV/Parquet plus optional object-store/warehouse connectors and MLflow |

Source: architecture, package and deployment documentation. [1][2][8][9]

## Key Features

### Pay for relationship resolution once

Ingest resolves keys to compact IDs, builds adjacency ordered by relation/time, and creates a reusable on-disk index. The documented sampler bounds fanout, searches around prediction time, orders large-batch reads and exploits OS page caching. DiskGraph is included as Rust source, not just an unexplained remote binary. This is a useful design for repeated temporal neighborhood retrieval on graphs larger than RAM—not free ingestion or a promise that arbitrary traversals stay cheap. [1][2][3]

### Point-in-time context, with correctness obligations

Temporal sampling and query-generated labels reduce hand-built feature joins. They do not fix wrong source timestamps, late-arriving facts, entity leakage or an inappropriate evaluation split automatically. The benchmark's newer graph trial explicitly fixes timestamp issues in the older synthetic dataset. Validate available-at-time semantics, ties, missing keys and holdout design on the actual business task; bounded latest-neighbor context also changes which evidence the model sees. [1][4]

### Models and lineage are portable, not harmless

MLOps documentation defines snapshots, training tables, model bundles, prediction manifests, asset hashes and lineage. Models may include holdout predictions; manifests can contain source locations, queries, tracking destinations and sampled skipped entity IDs. These are sensitive data products, not metadata safe for unrestricted publication. `record_sources=False` limits source provenance, but does not anonymize all artifacts. [9]

## Architecture

The service pipeline exports connector data to Parquet/blob storage, ingests it with DiskGraph, compiles PQL into training/prediction tables, and feeds core runtime batches to training or scoring. REST follows router → service → DAO/driver → workflow/activity; Temporal coordinates long-running service jobs. The local SDK instead calls the shared core in process. [2]

The reviewed revision introduces typed RuntimeBatch/RuntimeGraph/RuntimeFeatureBlock records with Arrow buffers retaining native ownership; Python consumers no longer need adapter-owned dictionary schemas. Typed SamplingOptions and shard/seed settings make the boundary clearer, but DiskGraph and Python packages must match: this is an actively evolving native/runtime contract, not a stable universal graph interchange API. [3][10]

## Benchmark Methodology and Correctness

**These are source-reported measurements, not reproduced results.** The live benchmark page contains several experiments with different revisions and datasets; combining their best numbers into one speedup would be misleading. [4–6]

- **October 21 context trial:** 50B nodes, 175.5B edges, Engine `392c25ed` versus DuckDB 2.0.0 on the same i4i.32xlarge. Warm normalized times exclude preparation, seed mapping, initialization and training. The reported advantage over prepared DuckDB is 2.4–8.9×, not the older 10–48× range. Repeated seeds and cache warming matter. Identity checks covered only 300 seeds at each of two and three hops, not all timed seeds or four hops.
- **Newer graph-database trial:** Engine `86dc74de`, corrected timestamps, 50B nodes and 87.8B foreign-key edges; do not conflate its counting/schema description with the older edge total. Every reported cell checked 300 seeds hop-by-hop against source Parquet, accepting any equal-timestamp tie break. Named DuckDB versions, two machine sizes, cold/warm passes and preparation/storage costs are supplied; graph databases A/B remain unnamed, limiting independent comparison. Reported run variation is about 10%; this is not a confidence-interval study.
- **No universal winner:** at 1B on i4i, six-hop warm DuckDB is 3,544 seeds/s versus Kumo's 3,104. At 50B, two-hop Kumo is 227,955 warm but 13,314 cold. The 50B Kumo index uses 2,635.1 GiB versus prepared DuckDB's 1,236.2 GiB, and takes 60.7 versus 38.0 minutes to prepare. Cold conditions and preprocessing economics can dominate.
- **Commerce model workflow:** the archived October 10 build is `20261009+9a0321c`, not the reviewed HEAD or the reproduction harness revision. Snapshot + training-table generation + fit total 5.16 hours on a 192-vCPU, 1.5-TiB, eight-L40S host. Only 448,000 seed examples were trained, not all 50B records. The separate 5M-customer prediction takes 78.4 minutes inside prediction, 86.7 including setup, with four GPU scorers; neither number is full-population latency.
- **Baseline fairness/reproducibility:** 9.885 hours for DuckDB feature engineering plus XGBoost uses different model budgets and stage boundaries. Historical SQL, splits, parameters, binary and measured dataset are absent; the provided generator uses a placeholder profile. The Kumo 700-step test population is not the comparator's million-seed evaluation. Treat the approximately 1.9× instance-time ratio as a workflow observation, not matched-model speed or equal-quality proof.
- **Citation-graph comparison:** source reports matched-module PyG training/validation at 64m13s versus Kumo 41m14s, but test accuracy is 63.93% versus 63.26%. GraphStorm's faster distributed training uses more hardware; its different construction resources and separate storage examples do not establish a universal capacity limit.

The supplied commerce runner records environment/configuration, stage outcomes, timing and OOM-related adjustments and refuses nonempty output directories. It also patches private trainer internals to control workers, so its compatibility is version-sensitive. No benchmark or prediction quality was independently verified here. [5][6]

## Hardware and Supported Scope

The root installation matrix specifies CPython ≥3.11; Linux x86-64/ARM64 with glibc ≥2.34; Apple silicon macOS ≥14; Windows x86-64 CPU, or WSL2 for NVIDIA GPUs. AES plus SSE2/NEON are CPU requirements. Small workloads can run on CPU; Apple GPU needs macOS ≥15, while macOS 14 should explicitly choose CPU. NVIDIA GPU and local NVMe are recommended for production. These are documented support claims, not tested compatibility; no AMD GPU support was established. [1]

“Beyond memory” still needs substantial RAM, disk bandwidth and scratch capacity. The headline machines have roughly 1–1.5 TiB RAM and tens of TB local NVMe. Plan capacity for source exports, graph generations, intermediate tables, checkpoints and assets—not just the compressed input. Do not extrapolate those results to network disks or a laptop. [4][8]

## Security, Privacy and Deployment Trust

- **Local library:** runs with the caller's filesystem, process and connector permissions; no server auth barrier protects local Python execution. Use least-privilege data identities and isolate untrusted datasets/artifacts. Cloud connectors and optional MLflow/platform integrations intentionally contact configured destinations; local execution is not a blanket no-egress guarantee. Dependency and asset acquisition are additional network events. [1][9]
- **Model deserialization:** core checkpoint loading explicitly uses `weights_only=False`. Only load model bundles/checkpoints from trusted writers; checksums establish corruption detection, not authorship or sandboxing. Trainer documentation says deserialization occurs at predict. [7][11]
- **Studio authentication:** configuration defaults authentication on, supports direct OIDC/password paths and API-key authorization, and has permission/project/group machinery. However, the internal-testing Compose template explicitly sets `DISABLE_AUTH=true`; disabled principals receive read/write/admin permissions. Never expose this template to an untrusted network. Code presence is not a completed authorization audit. [8][12]
- **CORS:** the main app validates configured origins when credentials are enabled. The public API app uses wildcard origins with credentials disabled. This is not evidence of a cookie-authenticated wildcard flaw by itself; auth, reverse-proxy and origin settings still need integration testing. [13]
- **Secrets:** production credentials use Fernet with a deployment secret; non-production modes use a constant dev/test key. Correct production mode and protected, backed-up key custody are mandatory. Do not mistake encrypted development records for secure secret storage. MLflow explicit-credential calls temporarily change process environment; the docs warn against concurrent independent MLflow/Databricks calls on other threads. [9][14]
- **Network perimeter:** Compose's normal entry is nginx, with internal backend services. TLS, ingress restrictions, trusted proxy handling, OIDC configuration and least-privilege warehouse access are operator duties. Prepared-image access and source backend build prerequisites are not proven anonymous installation paths; README still calls public dependency setup unfinished. [8]
- **Data retention:** exported Parquet, snapshots, model holdouts, predictions, manifests, logs and registry copies need access control, encryption/storage policy and deletion planning. No regulatory compliance, complete telemetry absence, hostile-tenant isolation or penetration-test claim is made by this review. [2][9]

## Downloads and Licensing

The main engine trains task-specific models; it does not require downloading a Kumo foundation model. Optional text support supplies GloVe 6B 50-dimensional embeddings. Its wrapper is Apache-2.0 and vectors are PDDL-1.0; third-party code/licenses are separately listed. Preserve notices and check the selected dependency/asset terms rather than treating the whole tree as only Apache. [1][15]

Distinguish the public text package from the legacy container asset installer: `docker/install_glove_files` uses signed AWS downloads against a bucket its source describes as private, skips already-present files, and moves a temporary download into place without a visible checksum check in that helper. This is an installation/provenance boundary, not evidence that the public Python library requires private AWS access. No bucket was probed. Model assets in the newer MLOps path are content-addressed and checked separately. [9][16]

Dependency manifests/lockfiles, build tooling and wheels form a sizeable native/Python supply chain. The root uv configuration pins its version, supports specific Torch indexes and imposes a seven-day release delay with exceptions. These controls are useful, but do not prove every distributed wheel matches reviewed source. Pin a tested engine/native/CUDA combination and verify asset/image provenance before deployment. [17]

## Persistence and Recovery

Snapshots and model bundles are explicit reusable artifacts. Snapshot export uses generation directories and writes its manifest last; documented loads verify integrity and complete or leave no result. Assets have SHA-256 identities; prediction exports use `_SUCCESS` markers. Object-store replacement deletes then writes, so readers may temporarily see no committed output, and partial destinations can remain recorded in provenance. These contracts help recovery but are not a transaction spanning all external systems. [9]

For Studio, preserve PostgreSQL/Temporal state, dataplane objects, graph storage and encryption secrets consistently. Compose down preserves data by default, while volume deletion removes Docker-managed state but not host-mounted data. A disk index/cache is not a backup strategy, and local NVMe loss must be anticipated. No restore, interrupted-write, failover or upgrade drill was run; require a tested restore plan and retention policy before production. [2][8][9]

## Tests and Maturity

Anonymous GitHub metadata on the review date reported 307 stars, 46 forks and 116 open issues/PRs combined; repository push time was 2026-11-27T17:13:52Z. The reviewed main commit is dated 2026-11-25T23:48:53Z. These indicate activity, not quality. Latest observed Engine release is `kumo-engine-v1.0.1` (2026-11-05), pointing to `663b10bdb1e15f26d58fd49ec4d3f796e6eb233a`; HEAD is not that release. The root README currently says contributions are not accepted. [1][18]

The tree has Python/package tests, Rust sampling tests, UI and Helm checks, public connector workflows, GPU PR/wheel checks, platform smoke tests and lifecycle tests. Documented GPU checks cover eight small task types, finite/complete outputs, save/reload and repeated predictions within absolute tolerance 0.005; training metrics explicitly have no learning-quality threshold. Some tests need services, credentials, GPU runners or first-use Temporal downloads. Workflow definitions and test files were inspected, not current CI execution logs: no green-build, coverage or passing-test claim is made. [10][19]

## Comparison

| Aspect | Kumo Engine | Alternatives and tradeoff |
|--------|-------------|---------------------------|
| SQL feature pipeline | Integrated temporal graph context and learning | DuckDB + XGBoost is simpler for aggregate/tabular features and often cheaper to prepare; bespoke joins/labels are your responsibility |
| Custom GNN research | Integrated out-of-core sampler and model workflow | PyTorch Geometric gives more model-level control; memory and sampler engineering remain workload-dependent |
| Distributed graph ML | Strong single-machine disk-oriented design | GraphStorm targets distributed training; more infrastructure can buy faster training but changes costs and preparation |
| Training-free prediction | Trains task-specific models | NVIDIA Structured Data Models/Kumo-TS address pretrained use cases; separate products and licensing/hardware review required |

These are architectural alternatives, not independently tested rankings. The published comparisons support narrower workload-specific conclusions only. [1][4]

## Self-Hosting Notes

Start with the local library and a small public or synthetic dataset, not Studio's auth-disabled template. Before production, gate adoption on: a compatible pinned runtime; real time-separated quality comparison against a SQL/tabular baseline; cold and warm end-to-end costs including indexing; capacity and crash/restore tests; trusted model writers; connector least privilege; reviewed data/lineage retention; and a verified TLS/authenticated service configuration if Studio is needed. No install commands were executed for this review.

## Evidence and Verification

Repository links below are pinned to the reviewed SHA; external documentation and release metadata are mutable observations retrieved 2026-11-27 UTC. Benchmark Markdown response SHA-256: `b689055eb7bb4d880fb9308055f8c2c5aacce273e1453e675ae5bfe47e9ac241`. Canonical source was anonymously accessible and no prior matching public review was found. Artifact checks cover links/provenance, public-only content, template integrity, markup and task-only diff; they are not runtime tests.

1. [README and support matrix](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/README.md)
2. [Architecture](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/ARCHITECTURE.md)
3. [DiskGraph runtime API](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/packages/diskgraph/README.md)
4. [Published benchmark report](https://docs.nvidia.com/sdgm/kumo-engine/resources/benchmarks)
5. [Commerce protocol and limitations](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/benchmark/commerce/README.md)
6. [Runner and archived results](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/benchmark/commerce/run_e2e.py)
7. [Checkpoint loader](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/packages/kumo-core/src/kumo_core/train/checkpoint.py)
8. [Compose deployment and persistence](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/docker/compose/README.md)
9. [MLOps artifacts, provenance and trust](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/packages/kumo-engine/docs/mlops.md)
10. [Testing contract and prerequisites](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/docs/development/testing.md)
11. [Trainer implementation and bundle trust](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/packages/kumo-engine/kumo/engine/trainer/trainer.py)
12. [Authentication/authorization implementation](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/rest/deps/authentication.py)
13. [Main REST CORS configuration](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/rest/app.py)
14. [Credential encryption](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/rest/config/encryption.py)
15. [GloVe licensing](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/tools/glove-6b-50d/README.md)
16. [Container GloVe installer](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/docker/install_glove_files)
17. [Dependency/workspace configuration](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/pyproject.toml)
18. [Public releases](https://github.com/NVIDIA/kumo-engine/releases)
19. [Engine PR workflow](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/.github/workflows/kumo-engine-pr.yml)

Additional evidence: [public API CORS](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/rest/public/app.py), [authentication defaults](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/rest/config/authentication.py), [internal-testing configuration](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/docker/compose/env.internal-testing.example), [archived commerce results](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/benchmark/commerce/reference-results.json), [root license](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/LICENSE), [third-party notices](https://github.com/NVIDIA/kumo-engine/blob/f4a29e4492ce282da300f9e02f822d440e8171b2/THIRD-PARTY.txt), [public repository metadata](https://api.github.com/repos/NVIDIA/kumo-engine).

---

**Attribution:** NVIDIA/kumo-engine, NVIDIA Corporation & Affiliates; Apache-2.0 with component-specific third-party notices. Independent review; no affiliation implied.
