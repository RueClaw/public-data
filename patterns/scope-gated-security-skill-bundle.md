# Scope-Gated Security Skill Bundle

**Source:** https://github.com/elementalsouls/Claude-BugHunter
**License:** MIT, with upstream/community attribution notes
**Extracted:** 2026-05-24

## Pattern

Build security-oriented agent skills around authorization, scope, evidence, and reporting gates before exposing technique-specific guidance.

The reusable pattern is the workflow shell around the domain knowledge:

1. Start every workflow with written-scope assumptions and target authorization.
2. Route to narrow domain skills only after the target class and task are known.
3. Require a validation gate before a finding can become a report.
4. Downgrade or kill findings that lack in-scope proof, accepted impact, reproducibility, or attacker realism.
5. Treat evidence capture as a first-class workflow with cookie, token, account, and PII redaction rules.
6. Separate candidate discovery, validation, and report writing into distinct steps.
7. Include explicit out-of-scope boundaries for operationally riskier phases.

## Why It Matters

Agentic security tooling has a high failure cost: hallucinated findings waste triage time, unsafe advice can cross legal boundaries, and overly broad context can push a model toward steps that are not authorized. A scope-gated bundle reduces that risk by making authorization and evidence quality part of the tool's control flow.

This pattern is useful outside offensive security too. Any high-risk domain skill bundle can borrow the same shape:

- policy and scope gate first;
- narrow expert context second;
- validation before action;
- evidence handling before disclosure;
- explicit stop here boundaries for adjacent but riskier work.

## Implementation Notes

- Keep the routing layer lightweight. It should decide which domain skill to load, not contain the whole corpus.
- Put policy gates in reusable skills or commands so every path can call the same checks.
- Use binary or small-enum outcomes such as pass, downgrade, chain-required, or kill.
- Make report generation depend on validation output instead of letting a report be drafted from a loose suspicion.
- Keep installer behavior auditable and reversible, especially when installing skills into a global agent environment.
- Document what the bundle deliberately does not cover, so omissions are not treated as invitations to improvise.

## Non-Goals

This extraction intentionally does not include exploit payloads, target-specific procedures, or attack chains. The transferable value is the governance pattern around domain skills, not the operational details.

---

**Attribution:** elementalsouls/Claude-BugHunter, MIT license with upstream/community attribution notes.
