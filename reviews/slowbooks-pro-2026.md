# SlowBooks Pro 2026 (VonHoltenCodes/SlowBooks-Pro-2026)

**Repo:** https://github.com/VonHoltenCodes/SlowBooks-Pro-2026
**Product site:** https://www.slowbookspro.com/
**License:** Custom Source Available License v2.0; free internal business use, not OSI open source.
**Reviewed:** 2026-10-13 (UTC)
**Revision:** 792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d; root application, accounting, reconciliation, audit, backup/export, security, manifests and selected tests/workflows.
**Verification:** Static source review only; no application, installer, migrations, tests or dependency audit executed. Public HTTPS acquisition and product-site retrieval succeeded.
**Stack:** Python, FastAPI/Uvicorn, SQLAlchemy/Alembic, SQLite or PostgreSQL, JavaScript/Jinja2, pywebview, WeasyPrint.
**What it is:** A local-first small-business accounting suite, inspired by QuickBooks Pro 2003, spanning invoicing, double-entry bookkeeping, banking, inventory and US payroll.

---

## Verdict

⚠️ **Interesting — credible solo-business pilot, not a verified replacement for live books.** The inspected code contains meaningful ledger invariants, reconciliation over actual journal lines and regression tests, rather than merely accounting-themed screens. However, default Docker network exposure contradicts its single-host assumption, PostgreSQL restore is not atomic, and “tamper-evident” forms are not signed or independently anchored. Evaluate with a parallel month of non-production books and an accountant-reviewed reconciliation before migrating; do not treat this review as payroll or tax certification.

## What It Is

SlowBooks targets owners who want locally controlled records and familiar QuickBooks-style workflows without an application subscription. The desktop launcher wraps a local web application; native company files use SQLite, while the optional Docker setup uses PostgreSQL. The same application includes a multi-user server mode and scoped API tokens.

The breadth is unusual: invoices and payments, bills, bank statement imports, inventory, class/job reporting, nonprofit terminology, tax forms and optional external integrations. For a solo service business, invoicing, expenses, bank reconciliation and standard reports are the relevant core. Payroll, merchant integrations and AI increase both the sensitive-data footprint and validation burden; they are not prerequisites for bookkeeping.

## Product Claims Versus Evidence

| Product claim | Assessment |
|---|---|
| Free and source-available | Accurate for internal use under the inspected license. Not unrestricted open-source reuse. |
| Local PostgreSQL ledger | Incomplete description: native desktop/company-file operation uses SQLite; Docker uses PostgreSQL. |
| Data never leaves the machine | Only defensible for an appropriately configured offline workflow. AI Insights builds financial prompts and sends HTTP requests; bank feeds, payments and QBO are external integrations. Cloud-backed agents can also receive API results. |
| Export everything / no lock-in | IIF, CSV, PDF and database backups provide useful exit routes, but interchange exports are not full-fidelity application backups. IIF export covers specific document families, converts to home currency and targets Windows-1252 text. Payroll files, attachments, identities and audit history need separate preservation through backups. |
| Tamper-evident tax forms | Canonical input-payload SHA-256 plus a local audit row; not a digital signature over PDF bytes, not an externally anchored append-only chain. |
| Ordinary computer backup means data is safe | Too strong. Live SQLite/WAL or PostgreSQL files require consistency-aware backup and a tested restore; syncing one live file is not proof of recoverability. |

Evidence: [app/database.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/database.py), [app/services/ai_service.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/ai_service.py), [app/services/iif_export.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/iif_export.py), [app/services/document_audit.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/document_audit.py), [app/models/document_audit.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/models/document_audit.py) and the product homepage retrieved 2026-10-13. The homepage itself correctly distinguishes source-available from OSI open source; this is not an allegation that it currently labels the license OSS.

## Stack

| Layer | Technology |
|---|---|
| HTTP/API | FastAPI, Uvicorn, Pydantic |
| Persistence | SQLAlchemy, Alembic; per-company SQLite or PostgreSQL |
| UI | Local JavaScript, Jinja2 templates, optional pywebview shell |
| Documents | WeasyPrint; optional system OCR tools |
| Authentication | Argon2 passwords, signed sessions, roles and bearer tokens |
| Integrations | HTTPX, Stripe, QuickBooks libraries, optional AI/bank services |

[requirements.txt](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/requirements.txt) mixes exact pins and bounded ranges; it is not a fully locked, hash-verified dependency graph. Desktop requirements separately pin pywebview and Windows pythonnet. Native rendering and OCR add platform dependencies beyond Python.

## Key Features and Financial Correctness

### Real double-entry controls

[app/services/accounting.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/accounting.py) centralizes Decimal half-up cent rounding, rounds invoice lines before summing, rejects negative or dual-sided journal lines, checks debit/credit equality, and enforces closing dates at journal creation. [app/models/transactions.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/models/transactions.py) adds a database CHECK requiring each stored split to be strictly debit-only or credit-only. Reversals preserve class/job/cost dimensions. Those are substantive safeguards.

Limits matter: balance equality is an application-level cross-row invariant, not a shown database-wide constraint. Journal insertion also updates cached account balances through read-modify-write without an account row lock in that helper; simultaneous PostgreSQL postings deserve a targeted concurrency test before multi-user reliance. Payment paths do take document row locks ([app/routes/payments.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/routes/payments.py)), but that is not evidence all concurrency cases are safe. This is a static risk observation, not a reproduced lost-update incident. A balanced ledger also cannot establish correct account classification or tax treatment.

### Reconciliation is tied to the ledger

[app/services/reconciliation.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/reconciliation.py) reconciles journal lines for a chosen bank account, carries the prior completed statement balance, rejects backward statement dates and stamps completed lines. Completion rejects differences above half a cent. This is considerably stronger than marking imported CSV rows reconciled independently of the ledger. Statement-import deduplication and matching still require real bank-specific trials; no connection or bank statement was tested here.

### Invoicing, exports and migration

Invoice/payment posting and reversal tests exercise the document-to-ledger relationship. IIF export sanitizes tabs/newlines, neutralizes spreadsheet formula-like text, and includes invoices, payments, bills and other selected records. CSV/PDF reports are useful for accountant handoff. A successful import or balanced trial balance does not prove all historical documents, tax flags, foreign currency and outstanding allocations migrated correctly. Compare opening balances, A/R and A/P aging, taxes and a bank statement independently.

### Audit trail is useful, not immutable

[app/services/audit.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/audit.py) uses ORM flush hooks to retain old/new values with the acting user, preserves Decimal amounts as strings, redacts password hashes and avoids copying binary document contents. This provides operational traceability but is not a separately protected evidence store: direct database edits can bypass ORM hooks and a database administrator can modify local history.

Document hashing covers canonical company/form inputs. The inspected document-audit model has a content hash and actor/time metadata but no previous-hash link or external signature. Keep trusted copies of issued forms and backups; a printed hash alone cannot prove that a PDF was never edited or that its tax figures were lawful.

## Architecture and Security

A large modular monolith organizes routes, services, schemas, models and templates around one FastAPI application. Core journal logic is shared, while many orchestration decisions remain in route handlers. Request-scoped database sessions roll back on errors; caller-owned commits let related financial writes share a transaction. Desktop packaging and server mode introduce distinct storage and lifecycle paths that must be tested separately.

[app/main.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/main.py) implements central session/token authentication, coarse admin/bookkeeper/read-only policies, restricted HR routes, explicit CORS origins, HTTPS options and startup checks against the public development encryption key. [app/services/settings_service.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/settings_service.py) encrypts designated integration credentials with Fernet and provides redaction helpers. This is more nuanced than the stale SECURITY.md note suggesting SMTP passwords simply remain in settings: current code encrypts them. Field encryption is not full-database encryption; exported records, documents and backups remain sensitive.

**Concrete deployment concern:** [docker-compose.yml](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/docker-compose.yml) publishes both application and PostgreSQL ports without a loopback host binding, supplies a known fallback database password, disables forced HTTPS by default, and enables a flag that skips transport checks on the assumption traffic stays on-host. Standard Docker port publishing is not localhost-only. Host firewall behavior was not tested, but the configuration does not enforce the stated boundary. Bind explicitly to loopback or a deliberately restricted interface, remove unnecessary database publication, set unique credentials and establish TLS before LAN exposure. No exploitation or live deployment was attempted.

**Concrete recovery concern:** [app/services/backup_service.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/app/services/backup_service.py) uses SQLite's online backup API, a good consistency choice, and PostgreSQL dump/restore tooling. Its PostgreSQL restore invokes pg_restore with clean/if-exists, but without single-transaction or exit-on-error options; partial changes can remain after failure. It also bases a nonzero-result error decision on matching stderr text. Rehearse recovery into a disposable database rather than discovering failure on the only copy of business books. Preserve encryption keys separately and verify restored secrets remain readable.

## Tests, CI and Maturity

At this revision, a static file count finds **342 test_*.py files**, not 342 executed tests. Selected tests explicitly cover void/reversal symmetry and sub-cent rounding ([tests/test_void_reversal_symmetry.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/tests/test_void_reversal_symmetry.py), [tests/test_rounding_consistency.py](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/tests/test_rounding_consistency.py)); many additional files target authorization, backups, migrations and browser behavior.

[.github/workflows/ci.yml](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/.github/workflows/ci.yml) defines lint, Linux pytest/coverage, Windows pytest with a skip budget, strict pip-audit, and a Docker import smoke check. The main test fixtures use SQLite; the workflow does not provision a PostgreSQL test service, so it does not establish PostgreSQL race/restore correctness. A container import smoke test is narrower than a health-checked application startup. Browser/native dependencies cause some test modules to skip unless separately provisioned. Weekly dependency audit and CodeQL workflows exist; their existence is not proof that every check passed for this review.

Public GitHub metadata retrieved 2026-10-13 showed 575 stars, 101 forks, creation on 2026-04-11, last push 2026-10-13T03:20:37Z, and four open issue/PR items combined. The latest public release was v2.22.2, published 2026-10-12T10:40:14Z. A scheduled CodeQL run for the reviewed SHA reported success ([run](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/actions/runs/38258963437)); the complete workflow matrix and detailed issue triage were not verified. These are activity signals, not financial assurance. The changelog openly documents recent fixes to taxes, allocations, imports and company-file isolation: responsiveness is positive, but the pace warrants upgrade/regression discipline.

## Comparison

| Option | Better fit / tradeoff |
|---|---|
| SlowBooks | Broad QuickBooks-like local workflows and an API in one package; young codebase and custom reuse restrictions. |
| [GnuCash](https://www.gnucash.org/) | Established local double-entry bookkeeping with business invoicing; a conservative first comparison for a solo business that does not require this integrated payroll/HR scope. |
| [Frappe Books](https://frappebooks.com/) | Local small-business invoicing/accounting alternative; compare actual regional tax, inventory and migration requirements rather than assuming parity. |
| [hledger](https://hledger.org/) | Text-ledger transparency and versionable records; less turnkey invoice/payroll workflow, more manual process. |
| QuickBooks | Consider retaining an existing validated workflow during parallel reconciliation, especially for accountant handoff and payroll. Feature resemblance alone is not migration equivalence. |

These are fit comparisons, not fresh security audits of the alternatives.

## Self-Hosting Notes and Solo-Business Acceptance Gate

Do not start with production financial or employee data. Prefer a single-user, offline evaluation; leave AI, bank feeds and public payment pages disabled until their data flows are understood. Server operation needs an explicit network boundary, role tests, backups and restore testing; do not use default Compose publication as proof of isolation.

Before replacing QuickBooks for a solo business:
1. Run a parallel month: invoice, partial payment, credit/void, expense, sales tax and bank reconciliation; compare reports and balances with the current books.
2. Validate every imported opening balance and outstanding invoice/bill, including taxes and foreign currency if used.
3. Restore a real backup into an isolated copy and verify documents, history, settings and encryption keys; keep independent/off-device copies.
4. Export the ledger and accountant-facing reports, and prove the receiving tool can use them. Retain original migration exports.
5. Have a qualified reviewer check payroll/tax outputs before use. License section 6 explicitly disclaims professional advice and filing certification; generated forms and NACHA files are not filing/payment execution or legal validation.

**Go/no-go:** Promising for a non-payroll solo-business trial; not a deploy recommendation from static inspection. Use a more established accounting workflow if there is no capacity to reconcile, test recovery and validate upgrades.

## License and Reuse

[LICENSE](https://github.com/VonHoltenCodes/SlowBooks-Pro-2026/blob/792c7617ee241a7c8cf3d19bf9b7786cb89c9d3d/LICENSE) is Source Available License v2.0, copyright 2026 Trent Von Holten. It permits personal and internal business use, including bookkeeping for one's clients, and separate commercial programs that interoperate without incorporating source. It restricts selling the software or derivatives, paid hosted access, inclusion in paid products/services, and use of the original branding for forks. Redistribution must retain the license, copyright and specified attribution; forks must be renamed. The terms also include indemnity and no-warranty provisions. “Free to run your own business” does not mean a permissive commercial embedding license. No source code was extracted for reuse in this review.

## Verification Limits

Public source and website inspected; exact SHA recorded; code paths and selected test assertions read. No installation, live demo, dependency resolution, vulnerability scan, migration, concurrent posting, backup restore, payroll calculation or test suite was run. Neither installer signatures nor performance/accessibility claims were independently validated. This is a technical evaluation, not a security audit or accounting opinion.

---

**Attribution:** SlowBooks Pro 2026 — originally created by Trent Von Holten; VonHoltenCodes/SlowBooks-Pro-2026, custom Source Available License v2.0. Public product claims attributed to slowbookspro.com.
