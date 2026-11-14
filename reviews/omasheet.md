# Omasheet (librasteve/omasheet)

**Repo:** https://github.com/librasteve/omasheet
**Author:** Stephen Roe (librasteve)
**License:** MIT; preserve notices for substantial code reuse. Qt and other dependencies retain separate terms.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** `0ea0f7b66fc2a849328d83c66da5f1b023b96708`; main, workspace version 0.1.8. Scope: six crates, QML UI, format/interoperability docs, tests, installation and CI/package workflows.
**Verification:** Static source review and public GitHub metadata. No build, application, tests, installer, workbook recalculation, or desktop interaction run.
**Stack:** Rust 2024, Polars 0.51, Qt 6 / QML through cxx-qt 0.10, calamine 0.36, rust_xlsxwriter 0.99, pulldown-cmark 0.13.
**What it is:** A local text-native spreadsheet and dataframe-style calculation language with a desktop grid and CLI. Its editable original is a plain-text .omx document, not an XLSX workbook.

## Verdict

⚠️ **Interesting — a compelling text-first calculation workbench, not yet a safe replacement for important workbooks.** Named column formulas, typed data, readable source and conservative Polars lowering are genuinely useful. Non-atomic saves, incomplete interchange, a narrower-than-advertised exactness guarantee, and document-driven local reads warrant a disposable-data pilot with independent numerical checks and external backups.

## What It Is

The slogan “What Markdown is to text, Omasheet is to numbers” describes an actual language and implementation, not merely a skin for Excel. A document contains named sheets, Markdown-like tables, constants, functions, schema/format declarations and expressions. A computed column can be written once as `Profit := Revenue - Cost` rather than copied across cells. Relative row references support running balances; transformations and external dataframe views bridge spreadsheet work and columnar analysis.

The intended fit is technical users who value diffs, version control and reusable calculations, including agent-assisted authoring. The optional AI skill is instructions for an external agent, not an embedded model or cloud AI service. It is not an Obsidian plugin at this revision: that is the subject of the sole open issue observed. There is no collaboration server or account requirement in the inspected application.

## Stack and Architecture

| Layer | Implementation and implications |
|---|---|
| Language | omasheet-omx: lexer/parser, typed checker, IR, decimal representation and dependency analysis |
| Evaluation | omasheet-engine: scalar execution, selectively lowered Polars expressions, external tables and editable Document |
| Interchange | omasheet-interop: XLSX translation, CSV/JSON conversion, Parquet types and optional formula metadata |
| Reports | omasheet-md: inline expressions and OMX blocks in Markdown, Markdown/HTML output |
| User interfaces | omasheet-cli dispatches commands; omasheet-ui wraps Document in a Qt bridge and QML grid |
| Storage | Plain-text originals and referenced local datasets; derived Parquet cache rather than an application database |

[Document](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/src/doc.rs) makes text authoritative: edits rewrite the source and rebuild evaluation; snapshots supply displayed cells and errors. Its undo limit is 200, not a durable transaction log. The separation between language, execution, interchange and UI is strong, although large central files (roughly 9,000 lines in doc.rs and 7,000-plus in Main.qml) increase maintenance complexity.

[Dependency analysis](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-omx/src/deps.rs) uses strongly connected components and distinguishes same-row, backward, forward and whole-column reads. This allows ordered recurrence without treating every self-reference as circular. [Lowering](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/src/lower.rs) has two gates: row-local eligibility and semantic support. Exact division/mean, some display types, date arithmetic and many calls deliberately fall back rather than silently adopting different Polars semantics. Overflow-risk tracking is another good design choice.

## Key Features and Numerical Correctness

### Readable calculations, but exactness has boundaries

The decimal type stores an i128 significand with up to 38 digits and a signed scale; integers are bounded rather than arbitrary precision. Common finite-decimal arithmetic such as 0.1 + 0.2 avoids binary floating-point error. However, “exact decimal arithmetic” is **not** an unlimited mathematical guarantee:

- Division rounds; comparison/display generally suppress eight guard digits, leaving 30 significant digits for long fractional values. Whole-number digits are retained where possible. Fraction display reconstructs a fraction with a bounded denominator; it is not rational storage.
- The README says an oversized value is reported rather than quietly rounded, but [Dec::align, checked_add and checked_mul](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-omx/src/decimal.rs#L372-L440) explicitly reduce scale and round to fit. The precision-ceiling test even expects the sum of two 38-digit all-nine operands to succeed with scale -1. The engine's [exact_arith](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/src/value.rs#L798-L853) reports an error only when these operations return None. This is a source-supported mismatch with the broad README promise, not a runtime reproducer.
- Exact division by zero becomes Float infinity or NaN, not necessarily an Excel-style error. Math functions, complex arithmetic and quantities have floating-point paths. Guard-digit equality cannot establish arbitrary-precision algebraic identity or bound accumulated error in every long calculation.

The [decimal tests](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-omx/src/decimal.rs#L755-L877) explicitly distinguish held 0.999… from displayed/compared 1 after one-third times three. That transparency is valuable; downstream consumers must still understand what “equal” means. For money, scientific measurements or threshold-sensitive logic, pin the version and independently check rounding, cancellation, non-finite values, units and boundary cases.

### Interchange is a translation, not workbook preservation

The [interop guide](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/docs/interop.md) is refreshingly explicit about losses. The first row becomes column names, names can be normalized, supported formulas translate, and unsupported formulas become cached values with notices. XLSX formatting/objects/macros and arbitrary workbook behavior are not a fidelity contract.

[XLSX import settlement](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-interop/src/xlsx.rs#L86-L198) compiles and evaluates translations and repeatedly replaces failing/mismatching formulas with cached values. This is a useful guard, but the numeric check allows relative error of 1e-9, compares through f64, and exempts volatile formulas. A stale workbook cache can reject a valid formula; matching one cached result does not prove future-input equivalence. For example, the documented no-default SWITCH/IFS mapping uses the last case as fallback, changing behavior outside the currently cached case.

Export writes supported Excel formulas plus calculated caches but does not run Excel or LibreOffice to validate recalculation. Null/failed cells can become blanks; exact numbers become floating point; uncertainties can be dropped; quantities may become text. Export-generated ISBLANK/IFERROR formulas are not all importable again. Keep the OMX original and review notices; “opens successfully” is not a round-trip test.

CSV/JSON export is values-only. JSON string/date inference and nested-value text conversion change schemas. CSV quote escaping is not formula-injection prevention: [CSV export](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-interop/src/csv.rs) writes text values without neutralizing formula-leading characters, so untrusted text may become active formulas when opened in another spreadsheet program. This is a downstream consumer boundary, not an observed Omasheet code-execution exploit.

Parquet best preserves supported dtypes, but unsupported nested columns are omitted with notices, Percent display is normally lost, and values outside its decimal range can become null. Optional --meta preserves OMX definitions, not a self-contained multi-sheet workbook: cross-sheet references can remain unresolved. Treat imported metadata as calculation source rather than passive descriptive metadata.

### Large files and reproducibility

Large external datasets can remain read-only views, with derived Parquet copies and samples for CSV/JSON/XLSX. [Table readers](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/src/table.rs) support projected columns and sliced row-group reads; the guide's blanket statement that head(5) reads every row group is stale relative to read_range/with_slice. No performance headline was reproduced.

Saving such a document saves references, not the source dataset. Archive the referenced files alongside the OMX and pin their versions; moving or modifying them changes results. [Cache identity](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/src/table.rs#L438-L454) is based on length/mtime (length alone for cache files), not a content digest. Equal-size replacements with preserved timestamps are outside that freshness model.

## Persistence, Backup and Recovery

**The most important operational gap is the original-document save path.** [File::save_file](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-ui/src/file.rs#L869-L885) directly calls std::fs::write on the destination, then marks the source saved. GUI exports and the CLI writer likewise write directly. There is no temporary-file/atomic-rename/fsync sequence in these paths. A crash, disk-full condition or interrupted write can leave an existing file truncated or partially written. An error status does not restore the old bytes.

The UI does provide modified-state tracking, a save/discard/cancel guard for closing/opening, and in-memory undo. Those protect normal interactive mistakes, not process crashes or competing external edits. No autosave journal, versioned document backup, or compare-before-overwrite protection was found in the inspected save path. Multiple windows sharing a Document are not equivalent to coordination between independent processes/editors.

Interestingly, the derived cache has stronger partial-write handling: [sink_to/sample/convert](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/src/table.rs#L1406-L1580) write partial files and rename completed copies. That does not protect the source document. Use independent versioned backups; save/export to new files during a pilot and test actual restoration. The cache is disposable acceleration, not a backup of a referenced dataset.

## Security, Privacy and Authority

- **Local does not mean confined.** External table paths are joined to the document base without a workspace allowlist; absolute paths and parent traversal can reference other readable local data. Markdown front matter has the same boundary through the [CLI loader](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-cli/src/lib.rs#L337-L355). Evaluating an untrusted document in a private working environment can pull local data into displayed or exported results. Use a secret-free, restricted filesystem for untrusted documents.
- **No general shell evaluation was found in formulas.** The visible subprocess path runs the current Omasheet executable as a conversion child with a source-path environment variable; this is not a shell command assembled from a cell. It is a memory-lifetime optimization, not a security sandbox.
- **HTML output is active-content-capable.** Cell inline HTML is escaped by inline_html, but [whole-page rendering](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-md/src/lib.rs#L450-L465) passes ordinary Markdown parser events directly to HTML output, preserving raw document HTML. Do not open generated reports from untrusted Markdown in a privileged browser context or publish them as sanitized content.
- **Links cross the desktop boundary.** [openLink](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-ui/qml/Main.qml#L430-L435) passes schemes to Qt.openUrlExternally and resolves relative links beside the file; no scheme allowlist appears there. Clicking a document link can invoke a browser or registered external handler. No click or handler was exercised in this review.
- **Retention is broader than the original file.** Parquet samples/full copies, clipboard content, report exports and remembered file paths are additional local traces. Cache directory/file permissions follow the surrounding environment rather than an explicit private-storage policy in the sampled creation paths. No application telemetry, provider credentials, built-in cloud sync or service listener was found in the inspected core. This was static inspection, not a network trace or full dependency audit. External AI tools used with the optional skill have their own upload and execution policies.

## Platform, Accessibility and Installation

Arch/Omarchy is the packaged target, with x86_64 and aarch64 artifacts. macOS ARM and other Linux builds are documented through Qt/Rust; Windows support is not established by the inspected CI. The “Pure Rust” repository description needs qualification: the desktop uses Qt/QML and a C++ bridge. Even the combined CLI executable is built through the Qt-linked UI package, though command-only execution avoids starting Qt.

The QML UI includes extensive keyboard shortcuts, adjustable font size, theme handling and save dialogs. No explicit Accessible annotations were found in the two QML files. Native controls may supply some accessibility automatically, but custom grid cell semantics, screen-reader navigation, focus, contrast and assistive-technology behavior remain unverified. Keyboard support alone is not proof of accessibility.

[install.sh](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/install.sh) fetches the latest release package and SHA256SUMS, checks the selected package, then uses sudo pacman -U. Without a terminal it adds --noconfirm. Updates rerun the same mutable main-branch installer; a release can be selected with OMASHEET_REF, but that does not pin the downloaded installer itself. Checksums protect against corruption, not compromise of the release publisher supplying both files.

The [package workflow](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/.github/workflows/package.yml) produces provenance attestations and limits publishing permissions to the attach job—a positive signal. The shell installer does not verify those attestations. Actions/container references are mutable tags, and the ARM root filesystem is fetched over HTTP without a visible digest check before docker import. That weakens build-input provenance even when the final output is attested. No binary or attestation verification was performed here.

Cargo.lock is present and package builds use --locked. The README/installer explicitly document a yanked zip 8.x transitive dependency through calamine, requiring the lockfile for resolution. This is reproducibility/maintenance debt, not by itself proof of a vulnerability. Native Qt compatibility can require distribution updates; there is no tested rollback or document migration guarantee in this review. Version 0.1.6 already changed numeric semantics and type names, so preserve old originals before upgrading.

## Tests, CI and Maturity

GitHub metadata retrieved 2026-11-14 reports creation on 2026-10-07, last push on 2026-11-13, 15 stars, one fork and one open issue. Latest release v0.1.8 was published 2026-11-13; the reviewed main commit is later than that release publication, so this is not an audit of the released binary. These are time-sensitive metadata, not quality scores.

The tree contains real unit/integration tests: numeric limits and guard digits, units/uncertainty, complex math, dataframe/formula semantics, row groups, interop, Markdown rendering and CLI behavior. The [kernel differential suite](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-engine/tests/kernel.rs) compares row-wise versus lowered execution across types/operators, edge cases and seeded inputs. [Interop differential tests](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/omasheet-interop/tests/differential.rs) compare inline imports and cached views and explicitly acknowledge type differences. That is stronger evidence than screenshots or example output alone, but internal agreement is not an independent Excel correctness oracle.

[CI](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/.github/workflows/ci.yml) runs fmt, clippy and workspace tests in an Arch container with Qt. The public API reported [CI run 43471896121](https://github.com/librasteve/omasheet/actions/runs/43471896121) successful for the exact reviewed SHA. This is observed upstream status, not tests run by this reviewer; job logs and individual test totals were not audited. No macOS/Windows matrix or live accessibility/data-loss qualification was established. The project's own “Early and changing. MAY CONTAIN ERRORS” warning is appropriate.

## Comparison and Practical Fit

| Need | Better fit / tradeoff |
|---|---|
| Text-first named calculations with a grid | Omasheet is unusually cohesive; accept a new language and explicit compatibility limits |
| Existing office workbooks and familiar editing | LibreOffice Calc is the safer default shortlist; still validate complex Excel-specific formulas/macros and formatting |
| Terminal-first tabular exploration | VisiData offers an established exploration workflow, but not Omasheet's text-source calculation model |
| Repeatable dataframe pipelines | Polars directly (see [public review](polars.md)) gives explicit program/test control; Omasheet adds an author-friendly grid and language |
| Plain-text tables embedded in notes | Emacs Org tables are another established option, with different formula semantics and editor tradeoffs |

These are workflow alternatives, not a performance benchmark. No paid service or new custom implementation is needed to evaluate the idea.

**Pilot acceptance gates:** independently check synthetic formulas and rounding; recalculate exported XLSX in the intended consumer; compare schemas and loss notices across all required formats; test interrupted saves and restoring external backups; archive view dependencies; verify a pinned build and its native dependencies; test keyboard and screen-reader operation. Until then, use it for exploratory/reporting work on copies, not the only copy of payroll, accounting or scientific records.

## Verification Limits

Static review only: no source execution, installs, configuration changes, desktop access, live document probes, real spreadsheets or credentials. No exploit, crash or data-loss event was reproduced. Findings above distinguish implementation paths and documented limitations from hypotheses requiring runtime tests. Public source accessibility, canonical identity, revision, release metadata and upstream CI status were checked. No private context or source code extraction is included.

**Attribution:** [librasteve/omasheet](https://github.com/librasteve/omasheet), Stephen Roe, [MIT license](https://github.com/librasteve/omasheet/blob/0ea0f7b66fc2a849328d83c66da5f1b023b96708/LICENSE). Analysis is independent; quotations and identifiers are attributed to their public source.
