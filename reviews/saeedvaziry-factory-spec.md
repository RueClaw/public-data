# Factory SPEC — an agent desktop architecture, not a released product

**Source:** https://gist.github.com/saeedvaziry/71180cae1084ebeb9d2fb5081a481946
**Author:** Saeed Vaziry (`saeedvaziry`), GitHub Gist
**Date:** Created 2026-11-27T18:30:17Z; gist metadata updated 2026-11-27T21:37:12Z. The update timestamp does not establish a content revision.
**Reviewed:** 2026-11-27 (UTC)
**Retrieved:** 2026-11-27 (UTC); anonymous API and raw-file requests succeeded. API reports `public: true`.
**Revision:** `81a124db01abb569758a7d7470ef9a03e97ed570`, the sole history entry returned, committed 2026-11-27T18:30:17Z. Entire sole file `gistfile1.txt`, 20,774 UTF-8 bytes.
**Content SHA-256:** `336b3ba11dd18a4548e321b33887cad19cc4afe37ba6fca41fdbd97d778b8590`
**Verification:** Complete static specification review; current API content, revision-specific API content and raw bytes matched. Selected primary integration documentation checked. No source commands, software, accounts, model calls or runtime security probes were run.
**Topic:** Single-user macOS agent orchestration, VM isolation, action policy and durable task flows
**License:** No license or reuse grant in the reviewed file; public visibility and an intention to open-source later are not an open-source license. This review summarizes rather than redistributes the specification.

---

## Verdict

📚 **Study: a thoughtful control-plane specification with deliberately limited isolation.** Worth reading for its commit-bound approvals, unified action registry and explicit trust assumptions. It is not evidence of a working application or a safe environment for hostile agents, sensitive multi-client work or unattended production changes.

---

## Summary

Factory is a working name for a proposed desktop interface around existing coding harnesses, not a new model or agent engine. Its intended audience is one macOS user managing multiple projects. The document proposes a Tauri/Rust shell, QuickJS plugin logic, SQLite state and a guest supervisor, with Codex first and Claude Code later. No implementation, executable, tests, dependency manifest or benchmark accompanies this gist. [1]

A workspace groups projects, secrets, policy, images and task flows. The default local provider gives each task a Linux VM; remote SSH tasks instead share a long-lived host, while the explicit host provider gives agents the user’s Mac privileges and does not enforce policy. Repository subpaths only select the starting directory: the full repository remains present. These are materially different trust boundaries, not interchangeable sandbox backends. [1, “Model”, “Machines”]

The strongest idea is to keep remote Git credentials outside the guest by default and mediate delivery through host actions. Approvals bind to individual commits, policy facts are computed by the host, agent-started flows retain agent identity, and policy changes and plugin installation always require user approval. A central inbox handles pending decisions; action IDs and recorded flow state make asynchronous work explicit. [1, “Code in and out”, “Actions, policy, inbox and activity”]

The proposal also states its limits unusually plainly: guests have root, open outbound networking, readable workspace secrets and harness credentials; co-located reviewer and worker sessions are not isolated. Plugin logic is unsandboxed on the host. Thus the gates regulate supported app operations and accidental delivery, not every possible external side effect or data disclosure. [1, “Trust model”, “Plugins”]

## Key Claims

- **One action layer can unify UI, CLI, agents and flows.** A coherent design that reduces duplicated policy logic, but no dispatcher or authorization code is available to verify complete mediation. The host CLI counts as `user` and always runs; socket permissions, caller authentication, token expiry/revocation and replay protection need an explicit contract. [1]
- **Commit-specific review can protect remote delivery.** Stronger than approving a moving branch. A robust implementation must also bind approval to repository, destination/ref, base and operation, then revalidate before the side effect. Adding a remote credential to guest secrets defeats the intended credential separation. [1]
- **The machine is the sandbox.** Only partly: host filesystem isolation does not stop network exfiltration of data already in a guest. A shared SSH directory is not a per-task VM boundary, and the host provider explicitly abandons enforcement. Network reachability back to the Mac, LAN and cloud metadata would need separate restrictions if those become requirements. These are design risks, not tested vulnerabilities. [1]
- **Saved flows and event logs support recovery.** They describe recovery intent, not exactly-once effects. A crash after a remote PR/push succeeds but before SQLite records it requires reconciliation and idempotency keys, not blind retry. Event deduplication IDs alone do not prove atomic dispatch. [1, “Guest agent”, “Flows”]
- **The chosen harness interfaces are plausible.** OpenAI documents app-server for rich clients, authentication, approvals and streamed events; Anthropic documents `claude -p` and structured output. This corroborates interface availability, not Factory’s adapters, credential portability, version compatibility or mode-switch fidelity. [2][3]
- **Framed plugin UI can avoid core access.** This needs deliberate capability and bridge configuration, not merely choosing Tauri. Tauri’s documentation says registered application commands are available to all windows/webviews by default unless constrained. No capability manifest, frame-origin policy or navigation rules are supplied here. [4]

## Strengths

The specification distinguishes `notify` from approval, uses an ask-by-default fallback, gives deny precedence across policy layers and refuses to widen rights on malformed policy files. It separates the reviewer’s recommendation from the actual approval gate, with a supervised default. These are useful design patterns even without copying the text. [1]

Its staged build plan is sensible: demonstrate one end-to-end Codex/VM/review/push slice, then extract mechanisms and a plugin API rather than designing all adapters up front. It also acknowledges that credential transfer is unresolved and excludes teams, a headless daemon and plugin sandboxing from version one. Those admissions help prevent mistaking a feature list for implementation maturity. [1]

## Gaps & Limitations

### Security, privacy and permissions

A reviewer in the worker’s root-accessible machine is a second opinion, not an independent security principal. Session tokens identifying distinct roles do not establish isolation when processes, files and credentials can be reached by another session. Automated approval based on that reviewer’s verdict should not be marketed as adversarial verification. The operator also spans workspaces; the chat’s current workspace is explicitly context, not an authorization boundary. [1]

Masking parameters marked secret is narrower than preventing secrets in tool output, prompts, diffs, event results, harness configuration and retained transcripts. The document does not specify encryption at rest, retention/deletion rules, credential revocation, model-provider data handling or secret scanning before its automatic pre-review commit. Root and open networking make least-privilege, short-lived guest credentials and data minimization especially important. No actual secret values were found or reproduced in this review. [1]

Host plugin installation is a code-execution trust decision. Pinning a source commit is useful for review, but does not make its transitive dependencies trustworthy or its host APIs sandboxed. Needed details include integrity verification, dependency pinning, update rollback and the security boundary of the plugin-specific UI bridge. Protected install actions help only if direct file writes and the host provider cannot bypass the intended boundary; the latter is explicitly trusted. [1][4]

### Recovery and reproducibility

The proposed recovery preserves Git branches, harness state and non-code outputs, but does not define export completeness, atomic folder delivery, deletion handling, symlink/path safety or collision behavior when several workspaces target the same source. An approved commit alone cannot prevent overwriting subsequent user edits in a plain folder. Multi-project deliveries need per-project receipts and an explicit partial-success policy. [1]

There is also a lifecycle gap: tasks can reopen from their original image, yet images that no task uses are garbage-collected. The specification should define whether closed tasks pin images and what happens after image deletion. Hashing only the setup script does not pin mutable downloads, package repositories, base images or harness versions, so identical script hashes do not guarantee reproducible guests. [1]

Sessions may survive app exit, but schedules and external polling only operate while the app runs. Catch-up, missed schedules, cancellation while awaiting approval and duplicate event delivery are unspecified. “Retry, skip, discard” requires operation-aware safeguards: skipping export or retrying an uncertain publish is not equivalent to rerunning a pure computation. [1]

### Applicability and next evidence

Best fit: architecture study for a trusted single-user desktop, with expendable task environments and deliberate human review. Poor fit without substantial additions: tenant isolation, hostile-source processing with valuable secrets, independent security review, always-on scheduling, or automated macOS work under the same guarantees as Linux VMs. The guest is described as one Linux binary, while a remote Mac is suggested for Xcode work; the guest’s macOS build/support story remains unspecified. The `svm` dependency is named but not linked or version-pinned, so its identity and isolation guarantees were not independently established. [1]

Before adopting an eventual implementation, ask for: an end-to-end slice with pinned dependencies; authorization-negative tests for socket/UI/plugin bridges; immutable destination-bound approvals; crash injection around publish and export; verified restoration after VM/image deletion; and credential/redaction tests using synthetic fixtures. None of those tests were possible from this document. A simpler direct harness integration using the documented APIs is an alternative when a desktop-wide plugin and policy framework is unnecessary. [2][3]

No productivity, performance or security measurement is presented. This review assesses internal coherence and documented platform interfaces, not operational effectiveness. No source instructions were adopted, and no licensed excerpts or runnable templates were extracted.

## Provenance & References

1. Saeed Vaziry, [Factory SPEC, pinned gist revision](https://gist.github.com/saeedvaziry/71180cae1084ebeb9d2fb5081a481946/81a124db01abb569758a7d7470ef9a03e97ed570). Entire `gistfile1.txt`; section names above identify evidence. [Anonymous metadata](https://api.github.com/gists/71180cae1084ebeb9d2fb5081a481946) and [revision API](https://api.github.com/gists/71180cae1084ebeb9d2fb5081a481946/81a124db01abb569758a7d7470ef9a03e97ed570). The API raw URL uses a separate identifier, `5286d063cbdf7bcd2c91dc019eb7b14e6312a2de`; [raw bytes](https://gist.githubusercontent.com/saeedvaziry/71180cae1084ebeb9d2fb5081a481946/raw/5286d063cbdf7bcd2c91dc019eb7b14e6312a2de/gistfile1.txt) matched the revision and the hash above. It is not substituted for the history revision.
2. OpenAI, [Codex app-server](https://developers.openai.com/codex/app-server/), public documentation retrieved 2026-11-27; introductory interface and transport sections checked.
3. Anthropic, [Run Claude Code programmatically](https://code.claude.com/docs/en/headless), public documentation retrieved 2026-11-27; programmatic CLI and structured-output guidance checked.
4. Tauri, [Capabilities](https://v2.tauri.app/security/capabilities/), public documentation retrieved 2026-11-27; capability configuration and application-command exposure checked.

---

**Attribution:** Saeed Vaziry, Factory SPEC, GitHub Gist. No license specified in the reviewed source; no grant to redistribute or adapt it is assumed.
