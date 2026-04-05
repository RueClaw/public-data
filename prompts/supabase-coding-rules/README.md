# Supabase Coding Rules

> **Source:** [supabase/supabase](https://github.com/supabase/supabase/tree/master/examples/prompts)
> **License:** Apache 2.0
> **Format:** Cursor rules (also usable as agent coding rules)
> **Extracted:** 2026-04-04

Production coding guidelines from the Supabase team. Cursor-rule format with frontmatter, but the content is universally applicable as agent coding rules for any project touching Supabase or Postgres.

## Files

| File | What it covers |
|------|---------------|
| `code-format-sql.md` | SQL formatting conventions |
| `database-create-migration.md` | Writing Postgres migrations |
| `database-functions.md` | Database function best practices |
| `database-rls-policies.md` | Row Level Security — includes performance optimization |
| `declarative-database-schema.md` | Schema management patterns |
| `edge-functions.md` | Deno edge function patterns |
| `nextjs-supabase-auth.md` | Next.js + Supabase Auth integration |
| `use-realtime.md` | Realtime subscription patterns |

## Highlights

- **RLS performance**: wrapping `auth.uid()` in `(select ...)` triggers an initPlan — Postgres caches the result per-statement instead of calling per-row. Non-obvious, big impact.
- **Edge functions**: codifies Deno import conventions (`npm:`, `jsr:`, no bare specifiers, always pin versions). Saves debugging time.
- **Auth SSR**: covers the cookie/middleware pattern that most Next.js+Supabase projects get wrong on first attempt.
