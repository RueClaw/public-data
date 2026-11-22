# Cover Your AIs (jdpru/cover-your-ais)

**Repo:** https://github.com/jdpru/cover-your-ais
**License:** No license specified at the reviewed revision. Public visibility is not a general permission to redistribute or adapt the prompt; no prompt text is extracted here.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** `aafd6217a61071beca2faa191e692bfc44651991` (main; commit dated 2026-11-21). Scope: both tracked files, README and the sole audit prompt. No release or tag listed at retrieval.
**Verification:** Complete static reading and tracked-tree inspection; unauthenticated public GitHub metadata checks. No prompt execution, installations, account checks, credential access, live environment audits, or efficacy tests.
**Stack:** Markdown; user-supplied coding agent and its tools.
**What it is:** A two-file prompt collection with one development-environment safety audit checklist, not a security scanner, agent runtime, or enforcement service.

---

## Verdict

📚 **Study — a useful preflight checklist, not a safety control.** The prompt connects agent mistakes to concrete blast-radius controls and separates audit from approval. Its strongest insight is to move protection outside the model; its weaknesses are an uncited efficacy claim, generic remediation recipes, and a scope that invites inspecting sensitive host configuration without a concrete safe acquisition procedure. Use it to structure a human review, not to certify an agent or automatically repair infrastructure.

## What It Is

The public owner, **jdpru**, describes a collection of prompts for catching AI-related mistakes. At this revision there is only one prompt. A person copies it into an existing coding agent, initially read-only, then reviews findings before approving fixes. The README explicitly says prompts are not security boundaries. [S1]

The checklist covers production databases in test configuration, readable production credentials, destructive cleanup, infrastructure deletion and backups, prose-only rules, GitHub permissions, cloud-synced directories, MCP/hooks/skills, privileged AI CI jobs, approval bypasses, and money/message tools. It asks for file-and-line evidence, hazard explanations, remediation, and blast-radius prioritization. These are instructions to another model, not implemented detectors. [S2]

## Stack

| Layer | Implementation |
|---|---|
| Content | README plus one Markdown fenced-text prompt |
| Orchestration | Manual copy/paste into an external coding agent |
| Detection and edits | Whatever tools and permissions that agent already has |
| Authentication, sandbox, approvals | Supplied by the host agent/environment; none implemented here |
| Storage, network, dependencies | No application, database, manifest, lockfile, or network client in the tracked tree |

## Key Features and Evidence

### Audit before modification
The prompt requests no changes initially, no secret values in output, no credential use, approval before fixes, and only in-repository edits; account/token/settings changes become manual steps. This is a good workflow specification. It cannot itself enforce read-only access, prevent tool execution, or constrain approval scope. The final instruction to add command warnings should be interpreted as proposed remediation under the earlier approval gate, not immediate edit authority. [S2, lines 6–7 and 42]

### Real blast-radius controls
The advice to use read-only database roles, narrowly scoped credentials, branch protection, deletion protection, and backups outside an agent token’s deletion authority is more useful than another “be careful” system prompt. The checklist also recognizes that shell aliases are not reliable agent controls and calls out untrusted CI inputs and MCP supply-chain exposure. None of these controls is provisioned or verified by repository code. [S2, lines 18–25 and 30–40]

### Claims need qualification
The final sentence invokes “the study” and claims hazard-and-consequence warnings reduced agent harm much more than repeated rules. Neither tracked file identifies a study, author, URL, sample, baseline, or measured outcome. Treat this as an unsupported claim in this repository, not an independently reproduced result. Warnings may help users and agents, but are not access controls. [S2, line 42]

## Architecture and Execution Boundaries

The entire flow is **human → external coding agent → local files/tool results → findings → human approval → in-repo edits**. There is no CLI, server, API, plugin protocol implementation, background worker, or executable entry point. There are no bundled tests, CI workflows, evaluation fixtures, or dependency installers. Repository text includes shell examples, but this review did not execute them. [S1, S2, S3]

### Permissions, authentication, and prompt injection
The audit’s requested scope is wider than a repository: it names shell-readable cloud/CLI credential locations, default contexts, GitHub scopes, and branch protection. Those checks can conflict with the explicit no-credential-use rule when current settings require authenticated queries. A safe interpretation is to report unavailable evidence and leave authenticated checks to the operator, rather than silently broaden privileges. Read-only filesystem access still permits disclosure. [S2, lines 7, 12, 24]

No mechanism distinguishes untrusted repository instructions from authoritative audit policy. Host agents must independently resist prompt injection from files, hooks, and tool output. Even in-repository fixes can change CI, hooks, or symlink targets with effects outside the repo; “in-repo” is not a sufficient execution boundary. Actual tool restrictions, isolated credentials, network policy, and diff review remain necessary. These are architectural limitations, not demonstrated exploits.

### Credentials, privacy, and egress
This repository itself has no telemetry, remote endpoint, authentication backend, or credential storage. The chosen coding agent may transmit file contents and tool output to a model provider or retain them in logs. “Do not print secrets” only constrains intended reporting, not what tools read or what enters model context. Even names, file paths, account identifiers, and findings can reveal sensitive architecture. Prefer a redacted repository snapshot, metadata-only checks, and separately performed operator checks for host credentials; do not give this checklist broad home-directory access by default. Provider retention and egress behavior are outside the source evidence.

### Remediation is a starting point, not a safe patch generator
- A database hostname that looks local does not prove a disposable database: tunnels and proxies can reach production. Use a dedicated database identity and environment-specific guard, not hostname alone.
- Ignoring a leaked key does not erase Git history or revoke it. The prompt correctly mentions rotation, but incident response must address history, artifacts, logs, and downstream copies separately.
- Shell strict mode and resolved-path checks need shell-aware implementation, failure tests, and handling of symlink/race conditions; strict mode is not universally compatible.
- Terraform lifecycle protection and provider deletion protection have different guarantees; do not treat them as interchangeable. Do not delete or archive state casually without backend ownership and recovery planning.
- Unicode removal and unknown-hook deletion require review: invisible characters can be legitimate, and removing integration files can break workflows.

These caveats qualify the generic fix recipes; no vulnerable target environment was examined. [S2, lines 9–19 and 30–31]

## Persistence and Recovery

No persistent service, audit database, transactional edit mechanism, checkpoint, undo feature, or recovery workflow is shipped. Findings and edits persist only through the external agent, its logs, and the target repository. Backups are recommended, not created or restore-tested. Before any real remediation, retain a clean diff baseline and independent backups; approval should be per reviewed change. The project cannot prove rollback or recover an already destroyed database.

## Supply Chain, Costs, License, and Maturity

The tracked tree has two Markdown files and no third-party runtime dependencies, package scripts, lockfiles, vendored code, or CI. Copying a pinned revision avoids unnoticed prompt drift, but does not pin or secure the host agent, its model, MCP servers, or hooks. The prompt appropriately flags unpinned MCP packages and permission-bypass switches. [S2, S3]

Public API checks on 2026-11-22 returned 22 stars, 4 forks, zero open issues, an empty all-issues result, no releases or tags, and two commits in the returned history. Last push was 2026-11-21T23:24:56Z. This is a very small early collection, not evidence of a validated audit product. Counts can change and are not quality metrics. No evaluation data establishes detection coverage, false positives, model portability, or remediation safety. [S4]

There is no service subscription or bundled inference dependency. Running the prompt may consume paid model tokens or agent subscriptions, with costs depending on context size, tool behavior, and provider. No cost benchmark or budget control is provided.

No LICENSE file or license declaration was found, and GitHub metadata returned no license. The README invites copying into a coding agent, but does not supply general open-source redistribution/modification terms. This review analyzes and links the work rather than republishing its prompt. Obtain explicit terms before packaging it into another product.

## Comparison

| Approach | Useful for | Boundary / tradeoff |
|---|---|---|
| Cover Your AIs | Broad conversational checklist across repo and developer setup | Model-dependent findings; no enforcement or benchmark |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | Dedicated secret detection | More focused, repeatable scanning; does not replace account-scope or agent-permission review |
| [zizmor](https://github.com/zizmorcore/zizmor) | Static GitHub Actions security analysis | Focused workflow analysis, not a general developer-host audit |
| Actual sandbox + least-privilege identities + protected branches | Restricting what an agent can do | Requires configuration and operational validation; complementary to all checklists |

Alternative purpose descriptions were checked against public repository metadata; no head-to-head tests were run. Prefer dedicated scanners for their supported checks and the prompt as a discussion guide for gaps they do not cover.

## Self-Hosting Notes

There is nothing to deploy or self-host here. The operational choice is which already-controlled agent, if any, receives the checklist and what sanitized evidence it can read. Start with a human review of the prompt and read-only, secret-free inputs. Do not run target tests, hooks, installers, cloud CLIs, or production probes merely to satisfy the checklist. This review did none of those actions.

## Verification and Limits

Verified unauthenticated public accessibility and canonical repository identity; read both tracked files at the exact SHA; inspected tree, commit metadata, releases, tags, and issues. The source instructions were treated as evidence, not executed. No runtime tests are applicable to a Markdown-only implementation, and no synthetic model evaluation was attempted. Findings are a static assessment of the checklist’s design and missing guarantees, not a penetration test or proof of harm reduction. Publication markup and consistency checks are separate from source efficacy testing.

## Sources

- **S1:** [README at reviewed SHA](https://github.com/jdpru/cover-your-ais/blob/aafd6217a61071beca2faa191e692bfc44651991/README.md#L1-L15).
- **S2:** [Complete audit prompt at reviewed SHA](https://github.com/jdpru/cover-your-ais/blob/aafd6217a61071beca2faa191e692bfc44651991/prompts/ai-codebase-safety-audit.md#L1-L43).
- **S3:** [Tracked tree at reviewed SHA](https://github.com/jdpru/cover-your-ais/tree/aafd6217a61071beca2faa191e692bfc44651991).
- **S4:** Public GitHub API: [repository](https://api.github.com/repos/jdpru/cover-your-ais), [commits](https://api.github.com/repos/jdpru/cover-your-ais/commits), [releases](https://api.github.com/repos/jdpru/cover-your-ais/releases), [tags](https://api.github.com/repos/jdpru/cover-your-ais/tags), [issues](https://api.github.com/repos/jdpru/cover-your-ais/issues?state=all). Retrieved 2026-11-22 UTC; mutable metadata.

---

**Attribution:** jdpru/cover-your-ais. No license specified; original analysis, no prompt extraction.
