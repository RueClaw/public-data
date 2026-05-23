# Mike (willchen96/mike)

**Repo:** https://github.com/willchen96/mike
**License:** AGPL-3.0-only; network-service copyleft, summarize patterns rather than extracting code into permissive projects
**Reviewed:** 2026-05-23
**Stack:** Next.js 16, React 19, Express, TypeScript, Supabase Auth/Postgres, Cloudflare R2/S3-compatible storage, Anthropic/Gemini/OpenAI, LibreOffice conversion
**What it is:** Open-source legal document assistant for uploading legal documents, chatting with them, creating tabular reviews, editing/generated DOCX files, and managing projects/workflows.

---

## Verdict

⚠️ **Interesting, but not yet a low-friction deploy candidate.** Mike has a real product shape and several good safety-oriented choices for legal-document workflows: authenticated backend access, centralized project/document access helpers, encrypted per-user model keys, signed authenticated downloads, and direct Supabase table grants revoked from browser roles. The blockers are operational and maturity-related: AGPL obligations, no visible automated tests, frontend lint failures, dependency audit findings, and README/schema drift around migrations.

---

## What It Is

Mike is an AI legal workspace. Users authenticate with Supabase, create projects, upload PDF/DOC/DOCX documents, chat with selected documents, run tabular review workflows, and generate or edit DOCX outputs. It supports Anthropic, Gemini, and OpenAI model providers either via instance-wide environment keys or per-user encrypted keys.

The repo is split into a Next.js frontend and an Express backend. Supabase provides auth and Postgres. R2-compatible object storage holds source documents, generated documents, and converted PDFs. LibreOffice is used locally when DOC/DOCX conversion to PDF is needed.

The app is clearly aimed at legal-review workflows rather than generic document chat. The prompts and tools include document citation rules, DOCX tracked-change style edits, tabular extraction formats, workflow sharing, project sharing, and generated document download handling.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | Next.js 16, React 19, Tailwind CSS, Radix UI, TipTap, React Markdown, Recharts |
| Backend | Express 4, TypeScript, Helmet, CORS, express-rate-limit, Multer |
| Auth/database | Supabase Auth, Supabase Postgres |
| Storage | Cloudflare R2 or S3-compatible object storage |
| Document processing | mammoth, pdfjs-dist, docx, JSZip, LibreOffice conversion |
| Models | Anthropic SDK, Google GenAI, OpenAI-compatible logic |
| Email | Resend |

## Key Features

### Legal Document Chat

The backend builds document context from uploaded project files and streams model responses with tools for listing, reading, editing, copying, and generating documents. The prompt rules strongly emphasize citations, exact quote support, and avoiding fabricated document content.

### Tabular Reviews

Mike includes a tabular review surface for extracting structured answers across documents. Columns can enforce formats such as yes/no, date, monetary amount, currency, percentage, number, tag, or bulleted list, with citation requirements for higher-risk answer types.

### Project, Workflow, and Sharing Model

Projects, documents, workflows, tabular reviews, chats, and shared records are persisted in Supabase. Access helpers centralize owner-or-shared-member checks, which is important because a naive user_id filter breaks once project sharing exists.

### Per-User API Keys

Users can add provider API keys when the server does not provide instance-wide keys. Stored keys are encrypted with AES-256-GCM using a server-side secret-derived key, and environment-provided keys take precedence so browser edits are blocked for centrally managed providers.

### Authenticated Signed Downloads

Generated download URLs are backend-relative HMAC-signed tokens. The frontend refuses absolute tool-provided URLs before attaching the user's bearer token, which helps avoid leaking tokens to off-origin URLs. The backend still requires auth and checks document access before streaming the file.

## Architecture

The backend is organized around route modules and shared helpers:

| Area | Role |
|------|------|
| backend/src/index.ts | Express setup, Helmet, CORS, rate limits, route mounting |
| backend/src/middleware/auth.ts | Supabase JWT verification via service role |
| backend/src/lib/access.ts | Project/document/review access checks |
| backend/src/lib/storage.ts | S3/R2 upload, download, delete, signed URLs, safe filenames |
| backend/src/lib/userApiKeys.ts | Per-user provider key encryption/decryption |
| backend/src/lib/chatTools.ts | Document chat/tool prompt and tool schemas |
| backend/src/routes/tabular.ts | Tabular review creation, generation, chat, sharing |
| frontend/src/app | Next.js app routes and legal workspace UI |

The database schema revokes direct table access from anon and authenticated roles, relying on the backend service role after JWT verification. That is a reasonable architecture for this app class, provided the backend access checks stay comprehensive.

## Verification

Local checks on 2026-05-23:

- npm install --prefix backend completed, but reported 11 vulnerabilities and Multer 1.x deprecation/vulnerability warning.
- npm install --prefix frontend completed, but reported 12 vulnerabilities and several deprecated transitive packages.
- npm run build --prefix backend passed.
- npm run build --prefix frontend failed without required public Supabase env vars (supabaseUrl is required during prerender), then passed with dummy NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY, and NEXT_PUBLIC_API_BASE_URL.
- npm run lint --prefix frontend failed with React compiler/hook lint errors, explicit any errors, and warnings.
- npm audit --prefix backend --audit-level moderate failed: 11 vulnerabilities, including 3 high.
- npm audit --prefix frontend --audit-level moderate failed: 12 vulnerabilities, including 1 high.

## Security Notes

Positive signals:

- Backend disables x-powered-by, uses Helmet, and adds route-specific rate limits.
- Backend verifies Supabase bearer tokens before API access.
- Project/document/review access helpers are centralized.
- Direct Supabase table grants are revoked for browser roles.
- User API keys are encrypted at rest instead of stored plaintext.
- Download links are signed, backend-relative, authenticated, and access-checked.

Risks and gaps:

- AGPL makes direct reuse in proprietary deployments legally consequential.
- Multer 1.x is explicitly deprecated for vulnerabilities; uploads are central to the product.
- Dependency audit findings affect XML/protobuf/doc/backend/frontend tooling surfaces that matter in a document-processing product.
- No automated tests were visible in package scripts.
- README references backend/migrations/, but no such directory exists in the cloned repo.
- The current frontend lint failures should be fixed before production hardening.

## Comparison

| Aspect | Mike | Generic document chat app | Contract review spreadsheet |
|--------|------|---------------------------|-----------------------------|
| Domain focus | Legal documents, citations, edits, tabular review | Broad document QA | Structured legal review |
| Storage model | Supabase + R2/S3 | Varies | Usually external files |
| Editing | DOCX generation/edit workflows | Often none | Manual |
| Collaboration | Project/workflow/review sharing | Varies | Manual permissions |
| Maturity risk | Audit/lint/test gaps | Varies | Process-heavy, less automated |

## Self-Hosting Notes

Mike requires more than a simple npm run dev: Supabase, R2/S3-compatible storage, model provider keys, optional Resend, and LibreOffice for DOC/DOCX conversion. Backend and frontend are installed separately:

    npm install --prefix backend
    npm install --prefix frontend

Useful checks:

    npm run build --prefix backend
    npm run build --prefix frontend
    npm run lint --prefix frontend

For production, fix dependency advisories, upgrade Multer, resolve lint failures, confirm migration files/schema workflow, and review every backend route for access-helper coverage.

---

**Attribution:** willchen96/mike, AGPL-3.0-only
