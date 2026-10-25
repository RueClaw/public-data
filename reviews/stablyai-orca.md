# Orca (stablyai/orca)

**Repo:** https://github.com/stablyai/orca
**License:** MIT
**Reviewed:** 2026-10-25 (UTC)
**Revision:** c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7; sampled repository-wide architecture, documentation, manifests, security boundaries and tests listed below.
**Verification:** Static source review only. No source execution, installs, device operations, deployments or paid calls.
**Stack:** Electron, TypeScript / React, native terminal helpers, pnpm
**What it is:** Desktop control plane for parallel coding agents, worktrees, terminals, review and remote sessions.

---

## Verdict

⚠️ **Interesting.** Interesting for developers already coordinating multiple coding agents; pilot before making it the sole development control plane. It has substantive lifecycle and credential machinery, but worktree separation is not security isolation and the integration surface is exceptionally broad.

## What It Is

Desktop control plane for parallel coding agents, worktrees, terminals, review and remote sessions. Parallel worktrees keep agent edits on separate Git working directories and branches. Integrated diffs, annotations and issue/PR workflows support comparing and reviewing results rather than merely launching more terminals.

## Stack

| Layer | Technology |
|---|---|
| Implementation | Electron, TypeScript / React, native terminal helpers, pnpm |
| Runtime and deployment | See platform constraints below; no deployment was performed. |

## Key Features

### Functionality

Parallel worktrees keep agent edits on separate Git working directories and branches. Integrated diffs, annotations and issue/PR workflows support comparing and reviewing results rather than merely launching more terminals.

### Boundaries and recovery

The desktop includes terminal splits, browser/design capture, SSH workspaces and a mobile companion. These extend where privileged development sessions can be viewed and steered; they are not merely UI decorations.

### Integration and evidence

Provider-specific integrations live beside shared runtime, PTY, persistence, host, SSH and daemon services. The large collection of lifecycle, deletion, recovery and credential regression tests is a real engineering signal, not a verified pass count.

## Architecture

src/main owns Electron-side privileged orchestration, provider launch/auth integrations, Git/worktree management, terminal processes and local/remote runtime services. src/renderer supplies the application UI; shared contracts and native helpers bridge runtime needs. package.json declares Electron build/test/typecheck pipelines and version 1.4.214 at the reviewed branch snapshot. The public latest release is a different revision; source conclusions are pinned here, not transferred wholesale to its binary.

## Security and Privacy

A Git worktree does not isolate filesystem, credentials, processes or network access. agent-workspace-trust-spawn enables preflight workspace trust unless explicitly disabled; trust-preset helpers prewrite provider-specific trust records, while comments distinguish that from the agent approval/sandbox policy. Review both layers. ProtectedSecretPersistence retains prior ciphertext or omits new secrets when protection is unavailable rather than silently promising successful storage. That sampled code is not a full credential audit. Telemetry, crash reporting, browser capture, cloud/mobile and SSH modules require deliberate privacy and connectivity review before sensitive use.

## Platform and Self-Hosting Notes

Targets macOS, Windows and Linux, with separate native/WSL and SSH paths. Model/agent accounts and their costs remain external; installing the UI does not provide free inference. Start on a non-sensitive repository, retain independent Git/terminal access, verify cleanup and restart behavior, and audit every enabled remote/mobile integration. Platform support in README is not proof of parity on a particular machine.

## Evidence, Tests and Limitations

package.json orchestrates Vitest, typechecks, dependency/security checks, native-runtime preparation and extensive custom reliability gates. Numerous OS-specific workflows and trust/credential tests exist. Nothing was installed, built or executed; no binary signing, update, mobile relay, SSH reconnect or sandbox behavior was independently validated. The size and churn make this a sampled architectural assessment, not an exhaustive audit.

This is a sampled static assessment, not a certification or exhaustive security audit. Source claims about hardware, performance and operational recovery remain unverified unless explicitly identified otherwise. Dependency advisories and released-binary provenance were not audited.

## Maturity and Releases

Latest public release API: v1.4.240 (2026-10-25), target 86de8f90e22a15846a49912015278c1e440d00c7. Not the reviewed branch SHA; no released binary was assessed. Public API snapshot 2026-10-25: 105644 stars, 6682 forks, 8545 open issues/PRs; created 2026-03-17T03:28:57Z; last push 2026-10-25T19:30:25Z.

Popularity and issue counts are discovery signals, not evidence of safety or test success. Mutable metadata was retrieved anonymously on the review date; conclusions refer to the exact source revision above.

## Comparison

Plain Git worktrees plus tmux and existing agent CLIs are simpler and easier to audit; VS Code or Zed offers a more conventional editor-centered workflow. Orca is justified when unified parallel-session review and remote/mobile steering save enough time to justify a larger trusted application.

## License and Reuse

The root MIT terms permit reuse with copyright and permission notices retained. Bundled dependencies, fonts, media and external services retain their own terms; the stated exceptions must not be flattened into MIT-only redistribution. No upstream code was extracted in this review.

## Source Evidence

- [README.md](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/README.md)
- [LICENSE](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/LICENSE)
- [package.json](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/package.json)
- [src/main/agent-workspace-trust-spawn.ts](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/src/main/agent-workspace-trust-spawn.ts)
- [src/main/agent-trust-presets.ts](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/src/main/agent-trust-presets.ts)
- [src/main/protected-secret-persistence.ts](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/src/main/protected-secret-persistence.ts)
- [src/main/agent-workspace-trust-spawn.test.ts](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/src/main/agent-workspace-trust-spawn.test.ts)
- [src/main/credential-file-protection.test.ts](https://github.com/stablyai/orca/blob/c6ce72d0c2efe5a6e7f44092e9a5011c4dd41fa7/src/main/credential-file-protection.test.ts)

---

**Attribution:** stablyai/orca; MIT. Analysis based only on public source.
