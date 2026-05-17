# Earned Autonomy Gates

**Source:** https://github.com/arian-gogani/nobulex
**License:** MIT
**Reviewed:** 2026-05-17
**Use case:** Agent platforms that need graduated permissions based on verifiable behavior history.

---

## Pattern

Do not grant powerful agent capabilities on day one. Start every agent in a restricted tier, record each action as verifiable evidence, and unlock higher autonomy only after enough compliant history accumulates.

The pattern has four moving parts:

1. A signed behavioral commitment that states what the agent is allowed to do.
2. A tamper-evident action log or receipt chain.
3. A deterministic scoring function over compliance rate and history depth.
4. Capability gates that map score tiers to concrete permissions.

In Nobulex, this is called Trust Capital. The useful generalization is earned autonomy: access is not binary, and it is not based on vibes. It is a function of evidence.

## Why It Matters

Most agent systems have two crude modes: sandboxed toy or fully trusted automation. That does not match real operational risk. Agents should be able to earn access to broader scopes, larger transaction limits, delegation, sensitive data, or unsupervised operation only after they prove reliability in narrower scopes.

This is especially useful when agents interact with each other. A counterparty should be able to ask: show me your proof, your covenant, your action history, and the task class this proof applies to. If the proof is absent, stale, unauditable, or scoped to the wrong task, the transaction should not happen.

## Minimal Shape

- Define tiers such as restricted, limited, standard, trusted, and autonomous.
- Define concrete capabilities per tier.
- Score behavior from both compliance rate and evidence depth.
- Require minimum receipt counts before high-risk tiers unlock.
- Bind cross-system proofs to audience and task class.

## Design Notes

- Make tiers explicit and boring. Operators should understand exactly what each level unlocks.
- Require minimum evidence depth per tier. Compliance percentage alone is easy to game with a small sample.
- Bind evidence to task class and audience when proofs cross system boundaries.
- Keep denied actions in the evidence stream. Blocks are part of the agent's history.
- Treat key revocation, key custody, log availability, and privacy as separate problems. A trust score does not solve them automatically.

## Failure Modes

- **Score laundering:** agents reset identity after bad behavior. Counter with non-transferable identity, stake, revocation, or admission policy.
- **Tiny perfect histories:** agents earn high trust from too few actions. Counter with minimum receipt counts.
- **Overbroad trust:** proof for one task gets reused for another. Counter with task-class and audience binding.
- **Opaque evidence:** logs are only held by the operator. Counter with third-party verifiable receipts or append-only publication.
- **Unbounded evidence leakage:** receipts expose sensitive action details. Counter with redaction, encryption, or zero-knowledge constructions when privacy is required.

---

**Attribution:** Extracted from arian-gogani/nobulex, MIT.

