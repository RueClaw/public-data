# Floci (floci-io/floci)

**Repo:** https://github.com/floci-io/floci
**License:** MIT; retain copyright and permission notices in redistributed substantial portions. Dependencies, vendored data and container images retain their own terms.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** d51729143b36554d6dd4011edf5a9d2c09188e4e, main; repository-wide architectural survey with focused routing, IAM/signature, storage, container-launch, S3, SQS, DynamoDB and Lambda inspection.
**Verification:** Static source review; no builds, application tests, containers, cloud resources or dependency installations run. Public GitHub reports CI success for this SHA; that is upstream evidence, not an independently reproduced result.
**Stack:** Java 25, Quarkus 3.40.1.1, Maven, Jackson 2.22.4, Docker-backed service runtimes; JVM and GraalVM-native packaging.
**What it is:** A local AWS emulator for application development and CI, exposing AWS-shaped APIs and selected real container-backed workloads. This repository is the AWS member of the Floci family, not the separate Azure, GCP or OCI emulators.

---

## Verdict

⚠️ **Interesting — a strong isolated-development candidate, not an AWS-equivalence or security oracle.** The implementation is substantial: protocol-aware dispatch, account-aware stores, real runtime containers and serious regression infrastructure are considerably more than canned responses. Pilot it against your own critical SDK/IaC workflows, pin the image, and keep a final real-AWS validation stage: accepted operations, authorization behavior and durability guarantees differ from AWS in consequential ways.

## What It Is

Floci serves a single familiar endpoint, normally port 4566, so SDKs, the AWS CLI and infrastructure tools can be redirected without rewriting application calls. It is positioned as a free, no-account alternative to LocalStack. Its README's “drop-in replacement” should be read as a migration convenience claim, not a universal behavioral guarantee.

The important distinction is between in-process service emulation and actual local execution. S3, SQS and DynamoDB model cloud behavior in Java; Lambda and multiple database/compute services can start real containers. Real PostgreSQL or Linux processes improve integration fidelity but do not reproduce managed-service orchestration, distributed consistency, tenancy or AWS hardware. The optional browser console is another container, lazily started on first access, not a bundled inert web page.

Source identity is confirmed by the public GitHub API and checkout. Older references to hectorvent/floci remain in compatibility documentation; the current canonical project is floci-io/floci. [README](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/README.md) is the product-claim source.

## Stack

| Layer | Technology / responsibility |
|---|---|
| HTTP and lifecycle | Quarkus REST/JAX-RS, CDI, Vert.x, virtual-thread request handling |
| Wire compatibility | AWS JSON, Query, REST routes and protocol-specific errors; shared service catalog and request/account/region context |
| State | In-memory maps, JSON snapshots, hybrid flush, binary WAL and partitioned stores |
| Execution | docker-java/container lifecycle helpers; Lambda runtime API and workload launchers |
| Testing | Java/JUnit/Quarkus tests; real SDK clients in Java, JavaScript, Python, Go and AWS CLI; Terraform, OpenTofu and CDK fixtures |
| Packaging | Maven/JVM image, native builds; advertised standalone Linux/macOS/Windows binaries |

The pinned versions and dependency overrides are in [`pom.xml`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/pom.xml). Overrides document native-image and HTTP-client compatibility constraints; this is an active dependency graph, not a tiny dependency-free binary. No resolved dependency audit or image vulnerability scan was performed.

## Key Features and Architecture

### Shared protocols, service-specific semantics

[`src/main/java/io/floci/aws/core/common/AwsJsonController.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/common/AwsJsonController.java) routes target-prefixed JSON requests, uses strict trailing-token parsing and runs blocking calls on virtual threads. Catalog-based routing coexists with service-specific controllers and filters for S3, Query and REST APIs. This keeps common protocol handling centralized while allowing specialized error envelopes and operations.

The inspected [`src/main/java/io/floci/aws/services/sqs/SqsService.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/services/sqs/SqsService.java) contains visibility/deduplication/redrive state rather than just queue CRUD; [`src/main/java/io/floci/aws/services/dynamodb/DynamoDbService.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/services/dynamodb/DynamoDbService.java) has per-item reentrant locking around condition/write paths and transaction-related machinery. These are encouraging implementation signals, not a proof of every ordering or transaction edge case.

### Real workloads, real host authority

[`src/main/java/io/floci/aws/services/lambda/LambdaExecutorService.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/services/lambda/LambdaExecutorService.java) orchestrates synchronous, asynchronous and dry-run invocation, timeouts and retries, with async destination routing. Shared Docker helpers centralize endpoint discovery, networking, lifecycle and credentials. This makes end-to-end application tests more meaningful than SDK mocks, while introducing image pulls, runtime resources and executable-code trust.

### Account-aware, selectable persistence

[`src/main/java/io/floci/aws/core/storage/StorageFactory.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/storage/StorageFactory.java) wraps stores in an account-aware decorator, loads lazy-created backends once, reuses backends by path to avoid stale-store overwrite, and attempts every shutdown flush while collecting failures. Append-heavy stores can use journaling even in persistent mode; partitioned stores reduce whole-map rewrite costs. This is thoughtful recovery engineering, not merely a volume mount.

## Compatibility: breadth is not equivalence

| Area | Evidence and practical consequence |
|---|---|
| S3 restore | [`src/main/java/io/floci/aws/services/s3/S3Service.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/services/s3/S3Service.java) implements restoreObject as object lookup plus a stub log. A successful restore call does not exercise Glacier restore timing/state. |
| S3 edges | [`docs/services/s3.md`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/docs/services/s3.md) explicitly documents unsupported list-bucket filtering/pagination parameters, incomplete copy headers and ACL leniencies. Tests that rely on AWS rejecting an operation can give false confidence. |
| Fault Injection Service | [`docs/services/fis.md`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/docs/services/fis.md) says experiment state is simulated; it does not actually inject latency, terminate resources or interrupt networking. Use it for control-plane wiring, not resilience validation. |
| Aurora DSQL | [`docs/services/dsql.md`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/docs/services/dsql.md) describes PostgreSQL-backed SQL adaptation, including blocking conflict behavior unlike DSQL's optimistic commit conflict model, statement-body limitations and error-detail differences. The README's shorter “not yet limits and async indexes” description lags this deeper documentation. |
| EC2 / CloudFormation | [`docs/services/ec2.md`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/docs/services/ec2.md) describes Docker-backed instances and concrete update/rollback differences: some LaunchTemplate updates retain an instance where AWS replaces it; mixed updates can end UPDATE_ROLLBACK_FAILED. Plan/apply success alone is not replacement or rollback parity. |
| IAM | Optional enforcement is useful for selected policy tests, but built-in test-key bypass and unmapped-route allowances mean it is not a complete least-privilege validator. |

The service list is useful discovery material, not a denominator for a coverage percentage. A service can contain fully implemented paths, approximations and accepted stubs simultaneously. Require operation-level acceptance criteria for the specific features your application uses.

## Persistence and Recovery

Default storage is memory: mounting the data directory does not by itself turn every service durable. Hybrid mode has an intentional flush window. Container-backed databases also have Docker-volume state separate from emulator metadata; backup and restore both, not just one directory.

[`src/main/java/io/floci/aws/core/storage/WalStorage.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/storage/WalStorage.java) appends before publishing ordinary mutations to the in-memory map, replays snapshots plus logs, handles torn records and supports atomic batch frames. Its ordinary put/putAll path calls a buffered write and flush; the atomic-batch path has explicit FileChannel.force handling. Do not translate “WAL” into “every acknowledged write survives power loss.”

[`src/main/java/io/floci/aws/core/storage/StorageFiles.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/storage/StorageFiles.java) replaces snapshots using a sibling temporary file and atomic rename, but that helper does not fsync the file and parent directory. WAL compaction writes a snapshot and removes/reopens the log; this ordering merits power-cut testing before any stronger durability claim. Corrupt snapshot handling uses quarantine. These mechanisms improve local restart behavior but are not evidence of distributed durability, multi-process writer safety or crash-consistent backups across services.

Failure-focused tests exist, including [`src/test/java/io/floci/aws/core/storage/WalStorageWriteFailureTest.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/test/java/io/floci/aws/core/storage/WalStorageWriteFailureTest.java), atomic storage batches, partition journals and lifecycle/duplicate-backend regressions. None were run in this review.

## Security and Trust Boundaries

### Local defaults versus container exposure

[`src/main/resources/application.yml`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/resources/application.yml) binds the host application to loopback and requires explicit unsafe-network consent for another bind address. Global signature validation and IAM enforcement are both disabled by default. The Docker image deliberately enables non-loopback listening inside the container; the supplied Compose publishes ports without a host-interface restriction and mounts the Docker socket. Thus the safe native bind default does not make the Compose example loopback-only. Set host port bindings deliberately, and separately restrict the UI sidecar's bind address.

[`docker/entrypoint.sh`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/docker/entrypoint.sh) starts as root for permissions/group setup and normally drops to uid 1001 with Docker-socket group access. That is better than permanently running the app as root, but Docker daemon access remains high authority over the host. It is not a safe boundary for hostile tenant code. Use a disposable isolated runner; omit the socket when only in-process services are needed.

### Authentication is emulation, not an access gateway

[`src/main/java/io/floci/aws/core/common/SigV4HeaderSignatureFilter.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/common/SigV4HeaderSignatureFilter.java) is conditional on signature validation and lets unsigned requests proceed to authorization decisions. [`src/main/java/io/floci/aws/core/common/IamEnforcementFilter.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/common/IamEnforcementFilter.java) explicitly treats the literal test access key as root/admin and permits some REST requests without an action mapping. Turning on the two flags improves fidelity but does not convert this into a hardened shared service. Use actual modeled non-root principals for policy tests and retain independent AWS policy validation.

### Credential and network boundaries

[`src/main/java/io/floci/aws/core/common/docker/LaunchedContainerAwsEnv.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/common/docker/LaunchedContainerAwsEnv.java) prioritizes mounted AWS configuration, then injected workload session credentials. Without either, a known owning account gets synthetic credentials; launch paths without that account can inherit the Floci process's AWS environment, with a warning. Endpoint injection is not a secret-isolation boundary: workload code can read supplied credentials and select a different destination. Start Floci with dummy credentials and no real AWS credential mounts or ambient production environment.

[`src/main/java/io/floci/aws/core/common/GlobalCorsFilter.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/common/GlobalCorsFilter.java) uses configured origins and opt-in private-network preflights rather than a blanket claim of permissive CORS. [`src/main/java/io/floci/aws/core/common/SsrfProtection.java`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/src/main/java/io/floci/aws/core/common/SsrfProtection.java) distinguishes full private-address blocking from metadata-only blocking for integrations that legitimately need neighboring containers. These are useful controls, but they do not establish a universal no-egress sandbox. External integrations, downloadable images, init hooks and executable workloads must be treated as intentional capabilities. This review did not establish an exploitable vulnerability or test every fetch/redirect path.

## Tests, Evidence and Maturity

- README advertises **2,576 compatibility tests** across five SDK/client lanes and three IaC tools; its table sums to that number. These are project-maintained compatibility scenarios, not 2,576 independently certified AWS behaviors or a line/branch coverage percentage.
- A static filename inventory found **3,404 files ending Test.java** under src/test/java. This is a file count, not an executed test-case count. Parameterized cases, skips and other naming conventions differ.
- [`.github/workflows/ci.yml`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/.github/workflows/ci.yml) shards Java tests across five jobs, compares source-derived class lists with compiled classes, and checks that shard unions are complete/disjoint. Pinned action revisions and a stable summary gate are positive signals.
- [`.github/workflows/compatibility.yml`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/.github/workflows/compatibility.yml) builds native images and runs SDK/IaC lanes. [`compatibility-tests/README.md`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/compatibility-tests/README.md) explicitly notes that its convenient test-all command excludes the IaC suites; run those separately. SDK calls against Floci without mocks are valuable integration evidence, but not by themselves differential execution against AWS.
- The [public CI run for the reviewed SHA](https://github.com/floci-io/floci/actions/runs/42379873053) was reported completed/success by GitHub on retrieval. The SHA-filtered run response did not establish a successful compatibility workflow for this exact revision. No logs/artifacts were exhaustively audited and no upstream result was reproduced.
- Public metadata retrieved 2026-11-07: created 2026-02-18; 30,980 stars, 3,375 forks, 203 open issues including pull requests; last push 2026-11-07. Latest release reported **2.4.0**, published 2026-10-31; the reviewed main SHA is newer. These numbers show activity and attention, not reliability. [`SECURITY.md`](https://github.com/floci-io/floci/blob/d51729143b36554d6dd4011edf5a9d2c09188e4e/SECURITY.md) limits supported security fixes to the current stable minor line.

The documentation is unusually candid at operation level, but broad README claims and specific service documentation can drift. Large service classes and cross-service authorization/resource mapping are maintenance hotspots. Treat upgrades as compatibility changes: pin, rerun your contract suite, inspect migration notes, then promote.

## Comparison

| Option | Prefer it when | Trade-off |
|---|---|---|
| Floci | You want a broad MIT local AWS endpoint with optional real database/compute runtimes and no vendor account requirement | Uneven semantic depth; Docker authority and a rapidly evolving service surface |
| [LocalStack](https://github.com/localstack/localstack) | An existing stack already depends on its exact integrations and supported service behavior | Evaluate current edition, licensing and account requirements; neither emulator guarantees AWS parity |
| [Moto](https://github.com/getmoto/moto) | Python unit tests need fast isolated AWS-shaped mocks or a mock server | Different integration depth; not a substitute for real workload execution |
| [DynamoDB Local](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) or [Dynoxide](https://github.com/nubo-db/dynoxide) | DynamoDB alone is the requirement | Narrower scope can simplify qualification; does not reproduce a whole AWS application. See the existing [Dynoxide review](dynoxide.md). |

These are fit comparisons, not a newly executed cross-product benchmark. No paid offering is required for the recommendation.

## Self-Hosting Notes

1. Use a pinned release/image digest in an isolated developer or CI environment. Keep all API, UI and database proxy ports private; do not expose the example directly to the Internet or an untrusted LAN.
2. Use synthetic credentials, explicit endpoint overrides and a fresh state namespace. A per-test instance avoids accidental shared-account collisions.
3. Start with in-process services and no Docker socket. Add Docker-backed services only when needed, budget image downloads/RAM/disk, and regard submitted code and image names as trusted inputs.
4. Select storage mode explicitly. Exercise process restart, failed writes, corrupted-state recovery and coordinated metadata/database-volume restore using disposable fixtures.
5. A source build requires **Java 25**, not the Java 17 compatibility-client requirement. Native binaries remove the JVM runtime prerequisite, not the Docker dependency of container-backed features. The Dockerfile's healthcheck syntax requires Docker Engine 25+ to build; exact released binary/platform behavior was not tested.
6. Gate adoption on your own queue redelivery/order cases, DynamoDB conditional/transaction cases, S3 metadata/error cases, IAM denials, and IaC update/delete/rollback scenarios. Keep an AWS validation stage for semantics that matter; this review created no cloud resources.

## Verification Limits

This was a selective static review, not an exhaustive audit of every service. Source and public metadata were read anonymously; no source code, build hooks or application test suite was executed, no images were pulled, and no secrets or private context were used. Throughput, startup size, all-platform builds, real-AWS parity, adversarial isolation and power-loss durability remain unverified. Artifact validation covers the review files, not the emulator's correctness.

---

**Attribution:** Floci and its contributors, [floci-io/floci](https://github.com/floci-io/floci), MIT. Analysis only; no source components extracted.
