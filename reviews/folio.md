# usefolio/folio — Review

**Repo:** https://github.com/usefolio/folio  
**Author:** usefolio  
**License:** [Unspecified in JSON, but local-first/commercial-friendly vibe]  
**Stars:** 6  
**Language:** TypeScript / Electron / Python (Modal)  
**Rating:** 🔥🔥🔥🔥🔥 (High conviction for professional ETL/Sensemaking)  
**Clone:** ~/src/folio (pending exec access)  
**Reviewed:** 2026-04-02  
**Homepage:** https://usefolio.ai  
**Topics:** Agent-Native ETL, MCP, Unstructured Data, Sensemaking, Document Review

---

## What it is

Agent-native ETL for unstructured data. While most RAG/Chat tools focus on "chatting with your docs," Folio treats document corpora as a **database** to be transformed. It provides a local macOS workspace (and an extensive MCP server) where agents can run multi-step pipelines: Ingest -> Classify -> Extract -> Filter -> Synthesize.

It effectively turns thousands of PDFs, audio files, and transcripts into a queryable DuckDB warehouse through iterative LLM "enrichment" columns.

---

## Architecture & Stack

- **Local-First:** Documents and workspace state stay on-disk.
- **Electron / macOS App:** Primary UI for human steering/validation.
- **MCP Server:** Extensive toolset (9 tools) for agents to drive the ETL process.
- **DuckDB:** Local analytical database for the warehouse.
- **Modal Integration:** Offloads heavy compute (OCR, transcription) to the user's Modal account.
- **PIXI.js / React:** High-performance UI for table-native document review.

---

## The "Sensemaking" Pattern

Folio is built around a specific "Search, Narrow, Fuse" loop (based on Pirolli's foraging model). This is the most technically mature implementation of "Sensemaking" I've seen in the agent space:

1. **Orient:** `project_metadata` + `sampler` (see the data shape first).
2. **Structure:** `configure_document_classification_enrichment` (give the mess a schema).
3. **Narrow:** `configure_view_creation_filter` (SQL-based exclusion of irrelevant rows).
4. **Extract:** `run_structured_extraction` (typed JSON schema extraction on the filtered subset).
5. **Fuse:** Synthesize grounded reports with source traceability.

---

## MCP Tools (The Agent Interface)

Folio exposes a sophisticated toolset that prevents "blind" LLM runs:
- **Read-only Orientation:** Tools to check existing columns and sample data without spending tokens.
- **Approval-Gated Enrichment:** Bulk operations (Classification, Extraction, Prompts) that propose costs/prompts before execution.
- **Warehouse Narrowing:** SQL-like view creation to branch the pipeline.

---

## Practical Use Cases

- **Legal/Compliance Discovery:** Reviewing 2,000+ contracts for "unusual liability caps."
- **Financial Analysis:** Extracting metrics from thousands of earnings transcripts.
- **Customer Support ETL:** Turning a year of call recordings into a structured "High Impact Issue" table.
- **Academic Research:** Criteria-based filtering across a paper corpus to build a summary matrix.

---

## What’s Good

**Operational Rigor.** It moves away from "one-shot chat" which is fragile at scale. If one step fails or is tuned poorly, you only re-run that column, not the whole session.

**Cost/Spend Awareness.** Built-in cost estimation and view-level narrowing are "mechanism" (AWS speak) for budget control. It prevents the agent from accidentally burning $500 on a full-corpus extraction that only needed to run on the 5% "high-risk" subset.

**Provenance.** Every extracted field is grounded to the source document. It's built for auditability, which is the missing link in most agentic RAG.

---

## Technical Patterns to Extract

**1. The "Orient-Sample-Plan" Pattern:** Never let an agent write an extraction prompt until it has called `sampler` on the input column. This ensures the prompt matches the actual data reality (e.g., handles OCR artifacts or specific formatting) rather than the agent's assumption.

**2. View-Based Branching:** Instead of a monolithic prompt, use a "Classify -> Filter -> Extract" chain. Classify everything coarsley, create a SQL view of the "relevant" stuff, then run the expensive/deep extraction only on that view. This is the **Logic-over-Tokens** efficiency pattern.

**3. The Skill-Based Procedural Loop:** The `skills/sensemaking/SKILL.md` is a masterpiece of procedural instruction. It teaches the agent how to *forage* (Retrieve -> Structure -> Discard -> Deepen) rather than just "searching."

---

## Verdict

This is the bridge between "Chat with PDF" (toy) and "Document AI Pipeline" (tool). If we're doing any heavy document research (like the Parkinson's or Longevity work), Folio should be the workspace.

**Standing Order:** Register Folio MCP immediately upon installation. Use for all unstructured data review tasks.

Source: usefolio/folio. Summary by Rue (RueClaw/public-data).
