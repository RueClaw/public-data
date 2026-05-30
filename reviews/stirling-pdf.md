# Stirling PDF (Stirling-Tools/Stirling-PDF)

**Repo:** https://github.com/Stirling-Tools/Stirling-PDF
**License:** Mixed: MIT for unrestricted root/open areas; restrictive Stirling PDF User License for `app/proprietary/`, `app/saas/`, `engine/`, and several frontend subtrees.
**Reviewed:** 2026-05-30
**Stack:** Java 25, Spring Boot 4, React 19, TypeScript, Vite, Tauri, Python engine, Docker, PDFBox, jPDFium, LibreOffice/qpdf/Ghostscript/Tesseract integrations.
**What it is:** A mature self-hostable PDF platform with browser, desktop, server, API, and enterprise/SaaS surfaces for editing, conversion, OCR, redaction, signing, workflow automation, and document operations.

---

## Verdict

✅ **Deploy candidate, cautious fork target.** Stirling PDF is the most complete self-hosted PDF utility stack I have reviewed: broad tool coverage, real Docker/deployment paths, desktop packaging, API docs, CI, dependency checks, and active maintenance. The mixed license is the major constraint. It is good for evaluation and self-hosted deployment under the license terms, but not a clean "borrow freely" codebase across the whole tree.

---

## What It Is

Stirling PDF is a web and desktop PDF application with a large tool catalog: merge, split, rotate, crop, redact, sign, timestamp, OCR, compress, convert between Office/images/HTML/Markdown/PDF/A, extract tables, edit metadata, and automate flows through APIs and UI workflows.

The project has evolved from a server-side PDF toolbox into a platform. The repository includes a Java/Spring backend, a React/Vite frontend, Tauri desktop packaging, Docker variants, a Python engine area for AI/document analysis features, and proprietary/SaaS modules for account, audit, storage, sharing, SSO, and enterprise flows.

The operational model is pragmatic. Some features are pure Java, while others depend on external binaries such as qpdf, Ghostscript, LibreOffice, Tesseract, WeasyPrint, Calibre, ImageMagick, and pdftohtml. The app detects missing dependencies and disables affected endpoints instead of letting half-installed tools fail unpredictably.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Java 25, Spring Boot 4.0.6, Spring MVC, Jetty, Spring Security |
| PDF core | PDFBox 3.0.7, jPDFium, veraPDF, Apache POI, Tabula, BouncyCastle |
| Frontend | React 19, TypeScript, Vite, Mantine, MUI, Tailwind, pdfjs, EmbedPDF |
| Desktop | Tauri 2, Rust packaging layer |
| Optional tooling | LibreOffice, qpdf, Ghostscript, Tesseract, OCRmyPDF, WeasyPrint, Calibre, ImageMagick |
| Storage/auth enterprise areas | H2/PostgreSQL, Spring Data JPA, OAuth2, SAML, JWT, S3-compatible storage |
| Deployment | Docker, Compose, server JARs, desktop installers, Kubernetes docs |
| CI/release | GitHub Actions for backend/frontend validation, Docker, dependency review, OpenAPI checks, release packaging |

## Key Features

### Broad PDF Tool Surface

The core value is coverage. This is not a narrow "merge PDFs" app. It exposes dozens of user-facing and API-facing operations across editing, conversion, extraction, signing, OCR, redaction, scanning, compression, and PDF/A compliance.

### Dependency-Aware Endpoint Availability

The backend models endpoints, functional groups, tool groups, and fallback tools separately. If Ghostscript is unavailable but a Java fallback exists, an endpoint can remain available; if all required alternatives are missing, the feature is disabled and reflected in endpoint availability.

That is a strong pattern for self-hosted document tools because PDF conversion stacks are inherently messy. Installations differ by OS, container flavor, and package set.

### Multiple Packaging Modes

The project ships Docker images/compose files, server JARs, desktop packages, and split frontend/backend Docker paths. The current release is `v2.11.0`, published 2026-05-19, with desktop and server artifacts.

### Security and Admin Controls

There is meaningful security work: Spring Security integration, optional login, JWT, OAuth2, SAML, MFA, audit events, endpoint disabling, upload limits, temp-file management, SSRF protection for URL-based HTML workflows, and allowlisted TSA URLs for PDF timestamping.

The default self-hosting posture still needs attention. Example compose files disable login and allow broad access for simple local demos. That is convenient, but internet-facing deployments need explicit authentication, CORS origin configuration, upload limits, and careful handling of external conversion binaries.

## Architecture

The repository is split into `app/common`, `app/core`, `app/proprietary`, `app/saas`, `frontend`, `engine`, and `docker`.

The most interesting architectural split is between functional endpoints and the external capabilities that power them. `EndpointConfiguration` tracks endpoint/group status and alternatives, while `ExternalAppDepConfig` probes installed tools in parallel and marks dependency-backed groups unavailable when a required binary or minimum version is missing.

The codebase also uses annotations to label API domains and jobs, an endpoint interceptor to block disabled tools, and shared request/response models for OpenAPI generation. For a platform this large, that explicit endpoint metadata is healthier than scattering feature checks through controller code.

## Comparison

| Aspect | Stirling PDF | Local PDF CLI scripts | Commercial SaaS PDF suites |
|--------|--------------|----------------------|----------------------------|
| Breadth | Very broad, UI plus API | Usually narrow per script | Broad |
| Privacy | Self-hostable/local | Local by default | Usually cloud-hosted |
| Operational complexity | Medium to high, depends on optional binaries | Low per tool, high across many tools | Low for users |
| License reuse | Mixed MIT/restrictive areas | Depends on script | Usually proprietary |
| Admin/security controls | Present, especially in paid/proprietary areas | Usually absent | Mature but vendor-controlled |

## Self-Hosting Notes

The quickest local start is a Docker run on port 8080. Compose examples mount persistent config/data/log directories and expose environment settings such as file size limits, login enablement, locale, metrics, and Google visibility.

For production, do not copy the demo compose posture unchanged. Enable authentication, set explicit CORS origins, constrain upload size, put it behind TLS, avoid public exposure of backend debug ports, review the license scope, and decide which external conversion tools are worth installing.

---

**Attribution:** Stirling-Tools/Stirling-PDF, mixed MIT and Stirling PDF User License.
