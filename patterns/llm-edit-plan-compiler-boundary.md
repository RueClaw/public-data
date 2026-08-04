# LLM Edit-Plan Compiler Boundary

**Source:** boldsoftware/meat
**Repo:** https://github.com/boldsoftware/meat
**License:** Apache-2.0
**Reviewed:** 2026-08-03

## Pattern

When an LLM needs to transform trusted source material, make it propose a constrained edit plan and let deterministic local code validate and render the final artifact.

The shape is:

```text
trusted source artifact
  -> assign stable coordinates
  -> expose bounded read-only context tools
  -> ask model for structured operations, not final output
  -> validate every operation against the original artifact
  -> compile/render locally
  -> report machine-computed retention or change statistics
```

## Why It Works

Free-form LLM rewriting is hard to trust because the model can add, drop, or subtly change content while sounding plausible. A compiler boundary reduces the model's authority. The model can still apply judgment, but only through operations the host program can check.

In meat, the model submits `remove`, `replace`, and `fold` operations over 1-based original diff lines. The local compiler validates range bounds, overlap, elision projections, fold legality, mandatory import removal, and exact-move symmetry before producing the displayed reading diff. The model never writes the displayed diff wholesale.

## Implementation Notes

- Number or otherwise anchor the original artifact before sending it to the model.
- Keep coordinates immutable; operations should refer to the original, not to a shifting intermediate result.
- Use a strict JSON schema with explicit empty arrays instead of missing fields.
- Prefer operations that are easy to validate: remove a range, elide a substring, fold a homogeneous block, select known spans.
- Generate placeholders locally, not from model prose.
- Provide a preview/validate tool so the model can repair invalid plans without weakening invariants.
- Give the model bounded read-only tools for context, and confine those tools to the intended root.
- Include the prompt/tool/compiler protocol version in cache keys and regression fixtures.
- Treat compiled output as an aid, not as proof that the model selected the right spans.

## When To Use

Use this for:

- source-derived diff compression;
- redaction where the host can enforce what was removed;
- structured document condensation;
- agent-generated patch review;
- log or transcript compaction that must preserve quoted evidence;
- any LLM workflow where "mostly faithful" output is not enough.

Avoid it when the model must genuinely author new material, or when the transformation cannot be expressed in operations that local code can verify.

---

**Attribution:** boldsoftware/meat, Apache-2.0
