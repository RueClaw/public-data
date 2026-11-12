# Extend-Write: A Reversible Structural Assimilation Primitive for Hyper-dimensional Knowledge Lattices and Continual Learning in Autonomous Super-intelligent Systems

**Source:** https://github.com/thePM001/ExtendWrite-NLA-Research-Paper-004
**Author:** the.PM; Iberian Peninsula Human Civilization Continuation Project / New Lisbon Agency (NLA)
**Date:** 2026-06-10 (stated public release)
**Reviewed / retrieved:** 2026-11-12 UTC
**Revision:** `04df43898ab577d36c6768eeaac30934de998a35`; all four tracked artifacts, including the PDF and both appendices.
**Type:** Self-published theoretical manuscript, 21-page PDF; not an executable research package. No peer-review venue or acceptance evidence supplied.
**License:** Root Apache-2.0 license; retain applicable notices for reuse. This review provides analysis, not a redistributed paper or code extraction.
**Verification:** Full PDF text, both figures, README, license, Appendix A sketches, Appendix B taxonomy and end statements inspected. Static mathematical/code review only; no source execution, model calls or performance reproduction. OpenTimestamps proof not cryptographically verified.
**Topic:** Hyperdimensional computing (HDC), vector symbolic architectures (VSA), reversible knowledge updates and continual learning.

---

## Verdict

❌ **Pass as a validated continual-learning primitive; revisit after specification repair.** The factorize–classify–recompose workflow is intelligible and its insistence on checked updates plus undo is useful. However, the published classification rules can discard factors, the undo record does not establish exact reconstruction, and neither strict enrichment nor continual-learning benefits are demonstrated. Read it as a design proposal to critique, not an established fifth memory primitive or an implementation to adopt.

## Summary

Extend-Write decomposes an existing and incoming hypervector with resonator networks, classifies recovered factors as shared, novel or preserved, and recomposes them with different weights. Shared pairs are bundled at weight 1.5, novel factors are bound to their nearest preserved neighbor at weight 0.8, and preserved factors retain weight 1.0. A domain-supplied predicate accepts or rejects the output; a diff supports undo (§§3.1–3.6).

At the graph level, a new capsule is located among nearby capsules, relationships are classified, and node insertion, edge insertion and attractor-field changes are proposed as one atomic transaction. Sector boundaries and trust rings are checked before commit (§4). Figures 1 and 2 illustrate this pipeline and before/after connectivity; they are conceptual diagrams, not experimental results.

The author claims five universal properties: preservation, relationship modification, structural integrity, strict enrichment and reversibility (§5). The larger thesis is that this operation resolves forgetting and superposition degradation for indefinitely growing autonomous intelligence (§6). Those conclusions substantially exceed the evidence. Section 7 explicitly leaves convergence guarantees, formal verification and empirical scaling to future work; the data statement says no external datasets were used and executable code is available only upon request.

## Source identity and evidence map

The reviewed commit contains four tracked artifacts: README.md, LICENSE, the public-release PDF and its .ots timestamp sidecar. There are no package manifests, runnable Rust/Elixir modules, tests, CI workflows, datasets or benchmark logs. The README largely transcribes the manuscript; the PDF adds the two diagrams. Appendix A contains sketches rather than a separate implementation. Appendix B is a positioning table, not an evaluation supplement.

- **Canonical repository:** [thePM001/ExtendWrite-NLA-Research-Paper-004](https://github.com/thePM001/ExtendWrite-NLA-Research-Paper-004).
- **Pinned paper:** [public-release PDF](https://github.com/thePM001/ExtendWrite-NLA-Research-Paper-004/blob/04df43898ab577d36c6768eeaac30934de998a35/Extend%20Write%20NLA%20research%20paper%20004%20public%20release%20version.pdf).
- **PDF SHA-256:** `918dfbea36a3b8bb65e2a33ea0b300cc815f89f24ac56e83900c553e53374465`
- **Pinned textual evidence:** [README sections and appendices](https://github.com/thePM001/ExtendWrite-NLA-Research-Paper-004/blob/04df43898ab577d36c6768eeaac30934de998a35/README.md); [license](https://github.com/thePM001/ExtendWrite-NLA-Research-Paper-004/blob/04df43898ab577d36c6768eeaac30934de998a35/LICENSE).
- **Public metadata snapshot:** main branch; last push 2026-06-10; 1 star, 0 forks, 0 open issues; releases endpoint returned an empty list. These are distribution/activity facts, not scientific validation.

The sidecar has an OpenTimestamps header and embeds the PDF's SHA-256 digest. No timestamp-chain validation was performed. Even a verified timestamp would establish a commitment to document bytes, not correctness, peer review or scientific priority over all prior work. Authorship is attributed to the manuscript's stated author, not inferred from document-editor metadata. The paper discloses LLM assistance in drafting and exposition; the assessment below concerns the actual definitions, not the use of those tools.

## Key claims and technical assessment

### 1. The classification is not an exhaustive partition

**Author claim:** Every old factor is either preserved or represented in a shared pair (§5, Invariant 1).

**Independent deduction from §3.3:** Shared pairs require similarity at least 0.7; an old factor is preserved only if no new factor reaches 0.3. Consequently an old factor whose maximum new-factor similarity is 0.5 is neither shared nor preserved. The analogous incoming factor is not novel either. The entire interval [0.3, 0.7) is a classification gap.

This is not merely floating-point ambiguity. For an admissible bipolar example of dimension 10,000, take an all-positive old vector and a new vector with 2,500 negative entries: their cosine is exactly 0.5. Conditional on recovering these as singleton factor sets, the stated rules produce no shared, novel or preserved factor. This is an analytical counterexample to the partition claim, not a measured resonator experiment. An unspecified predicate could reject the resulting state, but that does not make the partition correct or recover the discarded old factor in the proposed diff.

Shared is also a set of all qualifying pairs, not a one-to-one matching. One old factor can be paired with several new factors. Appendix A's loops can then reinforce and restore that factor multiple times; lattice connection strength can exceed one when pair count exceeds new-factor count. A matching policy, duplicate semantics and explicit handling of ambiguous factors are needed.

### 2. Recomposition is partial, and enrichment is not checked

**Author claim:** Every successful update preserves all knowledge and yields a strictly richer result (§5).

**Finding:** Novel-factor integration calls nearest(preserved, new_factor). Suppose all old factors have shared matches while the incoming set also contains an orthogonal novel factor: preserved is empty, and the nearest-neighbor call has no defined result (§3.4; Appendix A.1). Empty existing memories also lack an initialization rule.

Conversely, identical old and new factors can produce no novel factors at all. The sketch still returns success whenever the generic structure checker accepts; there is no explicit novel-count or recoverable-count gate. The published type of P accepts only the output vector, not the input pair or classification. Captured context could supply relational checks, but that interface and required checks are not specified.

Moreover, the displayed enrichment condition is only output recoverable count ≥ old recoverable count plus a separate requirement that the input classification contains novelty. It does not state a strictly larger output count or verify that each new concept survives decoding. Binding a new factor to a neighbor changes its representation; counting the resultant composite as a reliably recoverable concept requires an explicit decoder and codebooks. Preserving an additive component before normalization does not guarantee its later retrieval.

### 3. Exact undo requires more information and stronger assumptions

Section 3.6 reconstructs old shared and preserved factors with unit weights. The diff does not retain original coefficients, normalization residuals, representation parameters or the original vector bytes. The existing vector may itself be the output of a previous weighted update. There is no lossless factorization/recomposition theorem ensuring that unit-weight bundling recreates it.

The hash can detect a mismatch if checked; it cannot restore missing information. Appendix A.1's undo ignores the extended vector and does not verify the stored previous-state hash. The classification gap further omits old factors altogether; many-to-many matches can duplicate them. Even cosine 1 is not general byte-for-byte equality, particularly for representations with scale. Exact undo is feasible with a full before-image or a proved sufficient invertible representation, but neither is established here. Audit/history storage must be counted in any memory-efficiency comparison.

### 4. The underlying representation and lattice remain underspecified

The paper ranges over binary, bipolar and complex hypervectors but does not define their distinct binding, bundling, normalization and similarity conventions. Real-weighted addition needs a projection rule to stay within a binary/bipolar space. Standard resonator factorization recovers factors of a specified compositional encoding from codebooks; it is not automatically a generic semantic decomposition oracle for arbitrary weighted sums of bound and bundled structures.

The cited [Frady et al. primary abstract](https://arxiv.org/abs/2007.03748) specifically describes factoring products of code vectors. Its [companion analysis](https://arxiv.org/abs/1906.11684), absent from the nine-item bibliography, explicitly says global convergence is not guaranteed. This supports using resonators as a research component, not assuming reliable decomposition across Extend-Write's recursive outputs. Stable fixed-point convergence alone also does not establish correct factor recovery.

At lattice level, (N, E, A) describes nodes, weighted edges and a continuous attractor field. No order/join/meet or hyperoperation axioms establish the claimed mathematical hyperlattice, and no field equation, distance, update law or retrieval algorithm lets the reader verify geodesic preservation. Sector and trust constraints are named rather than defined. Local graph neighborhoods do not by themselves prove noninterference when the continuous field or other state is shared.

### 5. Transactional guarantees are requirements, not implemented evidence

Appendix A.2 pipelines add_node, add_edges and update_attractor_field, then returns either a new lattice and diff or an error. For purely functional immutable helpers, returning no candidate on failure could preserve the caller's original value. Their definitions are absent, however, so this is not evidence of rollback for external effects, atomic visibility, locking, serialization or durable crash recovery. Returning an in-memory diff is not itself durable storage. The timestamp source and attractor-change capture are external, undefined helpers.

The Rust sketch likewise omits all core types/helper implementations and does not visibly propagate factorization failure despite the prose's error contract. These are reasons to treat the appendices as API illustrations, not tested implementations or demonstrated ACID semantics.

## Methodology, evaluation and reproducibility

This is a theoretical/design contribution; absence of a dataset is not inherently a defect. The problem is that its universal guarantees are not proved and some stated rules undermine them. The river/bridge/dam example (§3.7) assigns similarities and asserts recoverability without supplying actual vectors, codebooks or decoding traces. It cannot establish robustness.

There are **no empirical datasets, task streams, train/test splits, baseline runs, controls, uncertainty estimates, significance tests or ablations**. Leakage and contamination therefore cannot be evaluated—not a clean bill of health, simply no experimental protocol to inspect. No empirical evidence supports superiority to replay, EWC, progressive networks, ordinary HDC bundling, event-sourced graph updates or a transactional memory with stored before-images.

Section 3.8 asserts sub-millisecond execution at d = 10,000, codebook size ≤ 1,000 and factor count ≤ 50, but provides no hardware identity, implementation, iteration distribution, timing protocol or measurements. Its complexity formula is not a latency benchmark. Because shared includes all qualifying pairs, its count can reach k_old × k_new; recomposition is not necessarily linear in k_old + k_new as stated unless a bounded matching rule is added. Approximate-neighbor O(log n × d) is also index/recall/distribution-dependent, not an unconditional guarantee.

A meaningful next evaluation would first repair the definitions, then publish executable codebooks/encoders/decoders, seeded property tests for round-trip undo and preservation, and a pinned reproduction environment. Tests should include intermediate similarities, duplicate matches, empty anchors, repeated identical updates, contradictory facts, failed convergence, capacity saturation and long repeated updates. Compare equal total storage and compute—including diffs—with ordinary bundling, explicit factor storage and a versioned graph. Ablate factorization, weights, anchoring and predicate gating. Report old/new retrieval accuracy, forgetting, order sensitivity, rejection rate, latency distributions and memory growth across seeds; tune thresholds separately from held-out evaluation. These are proposed tests, not work performed in this review.

## Novelty, citations and counterarguments

The nine references connect the proposal to genuine established topics: AGM belief revision; CRDTs; EWC, progressive networks and PackNet; resonator networks; and VSA/HDC work by Gayler, Kanerva and Plate. Selected primary abstracts were checked for resonators, EWC and progressive networks; the entire bibliography was not exhaustively audited and no systematic novelty search was possible with the available search service.

The narrow claim—this exact named combination may be new—is plausible but unverified. It does not establish a new computational capability. Ordinary reads/writes can implement a factorize/classify/recompose transaction; abstraction into a useful semantic operation is different from proving those underlying operations insufficient. Table 1 compares a rich operation with verification and history against bare storage operations without the same infrastructure. A fair comparison would give conventional updates validation, provenance and undo too.

CRDT convergence is not obtained simply by discussing merges: order-dependent nearest anchoring and repeated reinforcement are not accompanied by commutativity, associativity or idempotence proofs. AGM's central challenge includes revising contradictory beliefs; geometric similarity alone does not distinguish confirmation, contradiction, redundant evidence or a false statement. Preserving every previously accepted belief and maintaining truth across changing evidence can require explicit retraction, which is outside this mechanism.

Calling all gradient updates destructive by construction is too broad. [EWC](https://arxiv.org/abs/1612.00796) studies task retention with measured classification/game tasks; [progressive networks](https://arxiv.org/abs/1606.04671) preserve old columns while transferring features. Both have limitations, but an external knowledge-store update is not a substitute for solving continual parameter learning. The paper supplies no bridge experiment between the two.

Finally, a fixed finite-precision hypervector has finite information capacity. Unbounded recoverable knowledge requires growing storage, external factor records, increasing precision/dimension or lossy tradeoffs. The lattice and diff chain may grow, but then their full storage/retrieval costs must be analyzed. Reweighting alone cannot remove the capacity limit or guarantee all signal-to-noise ratios improve simultaneously.

## Strengths and practical relevance

- Separates decomposition, reconciliation and checked commit into understandable stages.
- Treats reversibility and provenance as first-class design concerns rather than incidental debugging features.
- States defaults, sketches interfaces and openly lists convergence, scaling and proof work still needed.
- Publishes a readable paper and accessible textual counterpart, with a drafting-assistance disclosure.

For engineers, the useful takeaway is modest: retain provenance, define invariants, validate candidate knowledge updates and make rollback concrete. A conventional versioned graph or explicit factor store is an adequate comparison before adopting an unspecified hypervector primitive. For HDC researchers, the edge cases above offer a clear specification-repair agenda. Neither audience should rely on the ASI or forgetting-resolution claims.

## Security, privacy and cost implications

No deployed service, provider integration, credential handling or executable implementation is supplied, so no operational security assurance is possible. There is no demonstrated requirement for paid LLM APIs; drafting-tool disclosures are not runtime dependencies. No provider calls or paid experiments were made for this review.

In a future implementation, input provenance and authorization must be independent of cosine similarity: repeated or adversarially similar claims could be reinforced without becoming true. Named trust rings and a boolean structural predicate are not an access-control or poisoning defense. Diff chains can retain sensitive or retracted information indefinitely, so reversible history conflicts with irreversible erasure unless retention, access, encryption and purge semantics are specified. Convergence bounds, factor-count limits, storage budgets and admission limits are needed to contain compute/memory costs. These are architectural implications, not observed exploits in runnable code.

## Verification limits and decision

The actual 21-page PDF was extracted locally and read through its references and end statements; diagram pages were visually inspected. The repository and supplementary timestamp sidecar were inventoried, and public metadata/releases were checked. No private correspondence or author-only code was accessed. No software was installed, no benchmark/model/data workloads were downloaded, and no implementation, formal proof or empirical result was fabricated. The illustrative counterexample is a deduction from the published equations, not a reproduction claim.

The decisive blocker is not merely missing experiments: the current specification does not support its stated invariants. Repair the partition and matching rules, specify the representation and decoder, prove or store enough information for undo, and publish a fair reproducible evaluation before treating Extend-Write as more than a speculative design.

---

**Attribution:** the.PM / New Lisbon Agency, [ExtendWrite-NLA-Research-Paper-004](https://github.com/thePM001/ExtendWrite-NLA-Research-Paper-004), root Apache-2.0. Independent review; author claims are distinguished from analytical findings above.
