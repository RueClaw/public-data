# Verifying formal models of Raft implementations

**Source:** https://antithesis.com/blog/2026/verifying-formal-models/
**Author:** Rohan Padhye (research fellow) and Hillel Wayne (developer educator), Antithesis; Wayne is credited at “Looking ahead.”
**Date:** November 19, 2026 (displayed publication date). No explicit update date found; a footnote refers to November 20.
**Reviewed:** 2026-11-20 (UTC).
**Retrieved:** 2026-11-20; initial article fetch at 20:35:30 UTC. SHA-256 of separately retrieved raw HTML response: 0d94fee029b985fb0874f07f8a7784ef1d2fa1a9e6238c1d043ce87cf8a048dd (page bytes, not normalized article text).
**Verification:** Static reading of the full article, appendix and footnotes, pinned formalization/assumption READMEs, and two public bug reports. No proofs, model checkers, simulations, upstream tests or reproductions executed.
**Topic:** Raft, TLA+/TLC/TLAPS, Lean/Veil, trace validation and AI-assisted proof engineering.

## Verdict

📚 **Good reference — adopt the layered assurance method, not a blanket “verified Raft” conclusion.** This is a substantive case study of tests improving models and proofs improving tests. Published artifacts disclose important limitations, including an unproved trace-binding bridge and storage disciplines outside the model. Useful for distributed-systems engineers and verification practitioners; not evidence that arbitrary deployments of either upstream library are correct.

## Summary

Antithesis describes an iterative workflow: infer implementation-shaped TLA+ models using an AI assistant, manually review safety properties and scope, explore bounded instances with TLC, instrument running implementations, and reject execution traces that do not fit the model. Counterexamples lead to instrumentation repairs, model changes or software patches. Proof attempts supply feedback rather than serving only as a final badge. [Article][1]

The targets are HashiCorp Raft and etcd-raft, not merely abstract Raft. Persistence boundaries, snapshots, concurrency, read indexes and membership-change semantics are where textbook reasoning can stop matching code. The article reports seven patches across the implementations, bounded exploration exceeding 1.6 million states in some instances, and safety proofs in Lean/Veil and directly in TLA+ through TLAPS. These are author-reported results, not independently reproduced here.

The central bridge remains empirical. Proofs concern behaviors admitted by formal models under their definitions and assumptions; trace checking concerns observed, instrumented executions. The authors acknowledge that distinction and exclude liveness and several features. Their closing “mice, not humans” analogy acknowledges that closely aligned implementation/model abstraction levels make this demonstration easier than general industrial conformance checking.

Supporting artifacts sharpen the story. Both formalization READMEs warn that the material is almost entirely AI-generated, a research demonstration, and neither authoritative nor maintained for upstream users. Their assumption documents say the handwritten trace-binding steps and summary-property implications are **argued, not mechanically checked**. That is a specific assurance boundary, beyond the generic observation that testing is finite. [HashiCorp artifact][2] [etcd artifact][3] [HashiCorp assumptions][4] [etcd assumptions][5]

## Key Claims and Evidence

| Claim | Public evidence inspected | Assessment |
|---|---|---|
| Checking, testing and proving together find faults | Two detailed upstream reports, patch descriptions and reproduction entry points | Concrete case-study evidence; not a controlled comparison of discovery methods |
| Both models have unbounded safety proofs | Artifact descriptions list obligations, goals, spec hashes and check commands | Inspectable; proof execution and axiom/hole audit not performed here |
| Implementations match their models | Reported 3/5-node campaigns, trace fixtures, mutations and bindings | Sampled conformance for selected harnesses, not universal refinement |
| AI makes this affordable | Under $1,200 in model tokens and about 2,000 Antithesis compute-hours per library | Vendor-reported figures, not total engineering cost or a general benchmark |
| Direct TLAPS proofs remove translation doubt | Separate proof paths for the claimed properties | Reduces translation reliance for those properties; does not certify bindings or code |

## Four Different Questions, Not One “Verified” Label

1. **Model validity:** Does the model represent the intended system and requirements? Human scope/property review, counterexamples and trace validation help. A sound proof can establish an incomplete or wrong requirement.
2. **Proof soundness:** Does the conclusion follow from stated assumptions under trustworthy checking machinery? Lean kernel checking and TLAPS have their respective trusted components. Neither label eliminates axioms, specification errors, backend trust or configuration mistakes. This review did not check proof terms or audit all trusted declarations.
3. **Implementation refinement:** Does every relevant code behavior map to an allowed model behavior? That is a universal relation, often involving abstraction mappings, stuttering and crash semantics. The case study tests conformance and explains bindings; it does not prove this relation for all Go executions.
4. **Testing:** Did selected workloads, faults and observations violate the oracle? Passing tests add evidence, not proof of unvisited behavior. Conversely, failing to prove a conjecture is not itself a counterexample: proof search can fail on a true statement. Producing and validating a concrete violating scenario is the substantive step.

Proving a property of model M and observing that sampled code traces fit M does not imply that **all** code traces fit M. Even the sampled claim depends on faithful extraction and binding.

## What the Public Artifacts Add

The HashiCorp snapshot claims 3,032 TLAPS obligations across 12 modules and 1,250 Lean goals; etcd claims 9,148 obligations across 19 modules and 1,272 Lean goals. Counts measure proof organization, not independent confidence units. READMEs describe clean-cache strict TLAPS checks, specification hashes, pinned Lean 4.35.0/Veil dependencies and the TLAPM commit used. A rolling 1.6.0-pre binary and its glibc requirement remain reproduction caveats. Expected output is documentation, not an observed review result. [2], [3]

Reported campaigns total about 2,010 compute-hours for HashiCorp and 2,100 for etcd; etcd also reports roughly 12,800 simulator runs. Recorded-trace checks describe 29 and 60 negative mutations respectively; etcd additionally describes 55 seeded implementation/harness-mutant runs. These test the oracle, but do not establish mutation completeness, exhaustive coverage or residual bug probability. Model and oracle can share an error, particularly in a jointly AI-generated workflow.

**Matching state counts is not equivalence.** The reproduction READMEs illustrate TLA+/Veil comparison by matching reachable-state counts on bounded instances (6,488 and 15,800, for example). Equal counts alone do not establish equal states, transitions or behaviors, much less unbounded equivalence. The article calls this bounded equivalence checking; the inspected documented count check supports a weaker sanity check unless accompanied by stronger correspondence evidence. Direct TLAPS proofs reduce translation dependence for the stated TLA+ properties; they do not turn cardinality into semantic equivalence.

## Two Concrete Faults Worth Studying

### HashiCorp: persistence atomicity is a protocol concern

[hashicorp/raft#746][6] reports that saving LastVoteTerm before LastVoteCand can leave a new term paired with an old candidate after a crash. A duplicate-vote shortcut then grants that candidate a vote without rechecking log eligibility. The alleged consequence is **Leader Completeness**, not the previously alleged double-vote failure: a candidate missing committed entries may win. The proposed write-order swap depends on the current term already being durable and each store operation preserving durability/order. The focused reproducer and explanation of why an earlier double-vote interpretation was wrong are stronger evidence than merely attaching “Raft” to a crash bug.

### etcd: membership and commit-index persistence interact

[etcd-io/raft#558][7] describes a five-node joint-membership schedule in which a follower retains a newer configuration log entry but loses the commit-index update. After restart it may campaign under an older configuration, allowing disjoint groups to commit different entries at the same index. The report includes an entries-then-HardState failure/control schedule and notes a liveness cost of its proposed candidate restriction. It explicitly leaves actual etcd reachability and some persistence questions unverified. A library-level reproducer is not a confirmed production etcd incident.

Both reports were open at retrieval and attribute discovery to the researchers. Their schedules and outputs are available evidence, not reviewer reproduction or proof fixes shipped upstream. Seven patches also must not become “seven reproduced safety bugs”: HashiCorp's assumptions document says R1 and R2 were argued from code without a reproducing run; other patches address state-machine/snapshot behavior. [4]

## Assumptions, Oracle and Coverage Limits

### Storage discipline narrows the result

The article's “individual writes are not torn” explanation does not fully characterize the etcd result. The artifact says the service uses **atomic synced Entries + HardState writes**. Term/vote → entries → commit-index split writes are modeled; upstream-documented entries → HardState order is only partly covered, with some crash states explicitly neither proved nor refuted. Membership changes in that order enable E3. Atomicity of each database transaction does not make a multi-transaction protocol update atomic. [5]

HashiCorp likewise assumes per-write all-or-nothing durability and ordered completion. Campaigns crash processes, not corrupt or lose synced data. Device/filesystem failures, faulty adapters and Byzantine peers are not guarantees supplied by these crash-fault models. Formal ASSUME declarations are not the whole operational assumption list: model actions and harnesses encode restrictions too.

### The checker is part of the trusted bridge

Wrappers report writes before they occur and reconcile uncertain final writes on restart. Per-node report order and loss detection matter. Several reports expand to multiple model actions; trace history is summarized rather than retained in the proof model's exact form. Both artifacts say binding correspondence and implication from summarized Safe to model properties are argued, not checked. Negative mutations cannot establish that every incorrect mapping is rejected. [4], [5]

The sensor appendix illustrates the issue: it logs “passed” before adding a reading to a dataset. If the subsequent effect fails without a faithful event/error mapping, the log can look conformant while the business effect did not occur. This is analysis of illustrative pseudocode, not a discovered Raft trace-kit bug. Logging intent and completed effect are different contracts.

### Scope is not the whole product

- HashiCorp excludes membership changes, Restore, the heartbeat fast path and some log-store behavior; application state-machine contents are not proved.
- etcd excludes lease-based reads, Bootstrap, the Node wrapper, applications declining membership changes, and coalescing multiple queued async writes into one. Its read-index trace check evaluates a direct property rather than replaying the complete read-action protocol.
- Both exclude liveness. Safety does not promise eventual elections, bounded responses, deadlock freedom or useful operation after a patch.
- Tests use three/five-node clusters; formal claims quantify over finite server sets under the models. TLC bounds are separate: etcd documentation says it does not exhaust membership instances with more than one change.
- Trace timelines are limited by TLC behavior capacity. Longer clean campaigns are not exhaustive long-history coverage.

Read-index safety is not automatically end-to-end application linearizability: API semantics, serving reads relative to applied state, storage adapters and the state machine remain integration obligations.

## Strengths, Incentives and Counterarguments

**Strengths:** The piece does not pretend the original Raft proof proves production forks. It treats failed proofs, nonconforming traces and invariant violations as different signals; describes human intervention; and publishes limitations, negative controls and reproduction commands. Direct TLA+ proofs after freezing the spec sensibly reduce one translation dependency.

**Commercial incentives:** This is an Antithesis vendor blog, not an independently peer-reviewed evaluation established here. It promotes the platform/plugin and compares resource use to a subscription allowance. That does not invalidate technical artifacts, but encourages crediting the platform and highlighting successful cases. No ablation isolates AI, manual expertise, ordinary simulation, TLC, TLAPS and Antithesis; no success-rate distribution across unrelated systems is supplied. Human review, instrumentation, iteration, hosted compute price and ongoing maintenance are missing from a full cost model. The model name and token expenditure are article claims, not independently benchmarked here.

**Counterargument:** Direct deductive verification or proved implementation refinement can offer a stronger bridge for a small stable component. For a rapidly changing service, cheaper stateful tests, deterministic simulation and history-based consistency checking may offer more operational value per engineering hour. Conversely, bounded TLC alone cannot justify unbounded invariants, and testing alone can miss the rare schedule exposed during proof development. Methods are complementary; choose by failure cost and maintainability, not proof prestige.

## Alternatives and Related Public Reviews

- **TLA+ with TLC and manual review:** Early design exploration without AI or a hosted service; needs deliberate bounds and a separate conformance strategy.
- **Deterministic simulation, stateful property tests and history checking:** Exercise implementations and external behavior; still need reachable workloads and adequate oracles. The public etcd simulator offers a lower-infrastructure path than hosted campaigns, not necessarily equivalent coverage.
- **Direct deductive verification / proved refinement:** Invest in the code/spec connection where feasible; runtime and environmental assumptions remain. The existing [Verus review](verus.md) is relevant to that boundary, not a drop-in verifier for concurrent Go Raft libraries.
- **Property-based UI exploration:** The existing [Bombadil review](bombadil.md) reinforces oracle quality, finite temporal observation and replay lessons. Bombadil is not the Raft proof tool or evidence these campaigns ran.

These are conceptual tradeoffs, not a comparative benchmark or paid-service recommendation.

## Practical Lessons and Reproduction Gate

1. Maintain an assurance matrix: requirement, property, model revision, code/patch revisions, assumptions and unverified bridges. Separate safety, progress and application correctness.
2. Review properties independently before model/proof co-evolution. Freeze baselines; justify every model relaxation against the intended requirement, not merely the latest trace.
3. Audit instrumentation: missing events, ordering, intent versus completion, crashes, stuttering and summaries. Mutate models, events **and** code; retain negative controls and coverage records.
4. Reproduce clean-cache proofs and exact spec hashes before reliance. Inspect holes/axioms, backend versions and trace-binding correspondence. Matching state counts is not a substitute.
5. Recheck deployed storage discipline, feature flags, upstream patch inclusion and integration APIs. Keep regression/fault tests and explicit liveness checks; rerun after relevant changes.

These are acceptance criteria, not upstream tests performed by this review.

## Provenance and Verification Record

The raw page's canonical link confirmed the source identity. Full article, appendix and footnotes were accessible anonymously. Public reviews, README and repository tracking index were checked for the canonical article URL; no prior matching review was found. Page-byte hashes can change with unrelated markup and are not semantic revision identifiers.

Supporting snapshots retrieved 2026-11-20:

- HashiCorp formalization: **abcc6e40ec7a082a480be956981f345aa989664c**, branch antithesis-fm-demo; artifact states upstream base a5b4692.
- etcd formalization: **b3c7c16e9c21d973a53a2894c4c9f33131121cd2**, same branch name; artifact states upstream base 99f9ffb.
- Documentary scope: both top-level READMEs, antithesis-fm/README.md and antithesis-fm/spec/README.md. Public issue bodies #746 and #558 read statically, including reported schedules/outputs.

This is an article review with supporting documentation inspection, not a complete audit of repository proofs, patches or harness code. No installations, toolchain/model downloads, accounts, paid calls, live-system probes or deployments occurred. Review files received offline consistency/markup checks; no browser rendering or formal verification is implied.

## Sources and Attribution

[1]: https://antithesis.com/blog/2026/verifying-formal-models/
[2]: https://github.com/antithesishq/hashicorp-raft-formalized/blob/abcc6e40ec7a082a480be956981f345aa989664c/antithesis-fm/README.md
[3]: https://github.com/antithesishq/etcd-raft-formalized/blob/b3c7c16e9c21d973a53a2894c4c9f33131121cd2/antithesis-fm/README.md
[4]: https://github.com/antithesishq/hashicorp-raft-formalized/blob/abcc6e40ec7a082a480be956981f345aa989664c/antithesis-fm/spec/README.md
[5]: https://github.com/antithesishq/etcd-raft-formalized/blob/b3c7c16e9c21d973a53a2894c4c9f33131121cd2/antithesis-fm/spec/README.md
[6]: https://github.com/hashicorp/raft/issues/746
[7]: https://github.com/etcd-io/raft/issues/558

**Attribution:** Rohan Padhye and Hillel Wayne, Antithesis, [original article][1]; Antithesis and upstream Raft contributors for supporting artifacts. No explicit article reuse license established; independent analysis and short paraphrases only, no article/source republication. Repository licenses do not automatically license blog prose. Index license is N/A for this article review.
