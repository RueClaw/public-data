# lencx Skills (lencx/skills)

**Repo:** https://github.com/lencx/skills
**License:** MIT; retain the copyright and permission notice in copies or substantial portions.
**Reviewed:** 2026-11-28 (UTC)
**Revision:** `b848e124111be50a795cc961558247e7751825e2` on main; entire tracked tree, especially both skills, all eight reference documents, plugin manifests and packaging script.
**Verification:** Static review only. Anonymous HTTPS acquisition and public GitHub metadata checked; no skills installed, source scripts executed, agent evaluations run, accounts connected or paid calls made.
**Stack:** Markdown Agent Skills, JSON Claude Code/Codex plugin metadata, optional Bash/zip packaging.
**What it is:** Two composable instruction sets for coding-agent execution discipline and architecture decisions. It supplies judgment prompts, not an enforcement runtime.

---

## Verdict

⚠️ **Interesting — unusually careful authority and recovery language, without demonstrated agent-level reliability.** The strongest material separates review from mutation, fact authority from writing, and a passing check from a sensitive check. Read and selectively adapt it behind existing host permissions; do not mistake installation for a sandbox, approval system or proven improvement in coding outcomes.

## What It Is

The repository contains exactly two skills: **coding-protocol**, a risk-scaled repository execution and evidence protocol, and **keel**, an architecture decision, judgment and governance workflow. Their applicability gates explicitly allow exiting instead of imposing process on every task. Focused workflows retain their methods and completion criteria. [1][2]

This is a small prose library rather than an agent framework. Claude Code and Codex manifests both declare version **1.4.0** and point at the same skills directory. The README offers either a skills installer or native plugins, warning that using both duplicates skills. It recommends independent engineering and design companions, not bundled implementations. [3][4]

## Stack

| Layer | Actual implementation |
|-------|-----------------------|
| Agent behavior | Two Markdown SKILL.md entry points; eight Markdown references |
| Distribution | Claude marketplace/plugin JSON and Codex plugin JSON |
| Packaging | One optional Bash script using system zip and standard filesystem utilities |
| Runtime, database, authentication | None supplied; inherited from the host agent and its tools |
| Dependencies | No tracked package manifest or lockfile; installer route invokes external npx skills@latest |

## Key Features

### Execution authority is not inferred from activation

Coding-protocol distinguishes Mixed, Execution, Evidence and Exit. A review is read-only; planning is not permission to mutate; automatic skill loading is not authorization. It expressly excludes inferred commit, push, deployment, publication, external communication and machine-wide operations. It also requires exact targets and recovery information for consequential actions and preservation of unfamiliar user changes. These are useful textual constraints, not a tool-level permission implementation. [1]

### Verification includes a negative control

The verification reference asks for a known failing input, pre-fix failure, reversible mutation or planted violation, with exact restoration of pre-existing changes. It distinguishes behavioral evidence from incidental source shape and admits narrow suppressions only with an owner, removal condition and residual risk. This is stronger than “run the tests,” but the agent still needs permission and a safe workspace before creating a negative control. [5]

### Architecture covers ownership and the time axis

Keel separates Decision, Judgment, Governance and Exit. Judgment keeps the supplied target fixed rather than silently redesigning it. Its model distinguishes fact authority, decision authority, accountable owner, writers, replicas, commit rules, conflict and recovery. Failure paths include uncertain commit, retry, restart, duplication and cancellation. A recovery description needs a trigger, owner, authority, terminal invariant and evidence—not merely the word rollback. [2][6]

### Governance can remove structure rather than add ceremony

Record guidance separates editorial rights from rights to change facts or retire records. Rot audits prefer existing version-control and check artifacts over a new persistent store. Surface/cutover and rewrite guidance require consumer scope, retained behavioral evidence and recovery before retiring old paths. Conditional references and explicit no-action options reduce, but do not eliminate, cognitive overhead. [7][8][9]

## Architecture and Actual Inventory

- `skills/coding-protocol/SKILL.md`: 91 lines; two references, `rule-rationale.md` and `verification.md`.
- `skills/keel/SKILL.md`: 134 lines; six references, `architecture-records.md`, `recovery-guards.md`, `rot-audit.md`, `rule-rationale.md`, `surface-cutover.md` and `task-routes-and-lenses.md`.
- Total skill/reference content: 531 lines. Reference reads are gated by concern; not all of it must enter every prompt.
- Distribution metadata: `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`; shared SVG icon.
- One executable script, `scripts/package-codex-plugin.sh`. No shipped hooks, MCP servers, backend, scheduler, network client, test harness or CI workflow was found in the tracked tree. `.github` contains funding metadata only. [10]

The packager checks zip and required paths, creates a temporary directory, archives the Codex manifest, icon, skills, license and README, then force-moves the fixed-name archive to its output directory. An EXIT trap removes its temporary directory. It does not download dependencies or contact a provider. It can overwrite an existing archive; output defaults to dist but accepts another path. Path-existence checks are not schema/content validation. Recursive inclusion also means locally added files under bundled directories can enter the archive; inspect contents before distributing. It has no signing, checksum manifest or explicit reproducible-build controls. These are static findings, not an executed packaging test. [11]

## Security, Privacy and Operational Boundaries

**Approval and execution.** The text defers to host precedence and permissions, but no independent policy engine intercepts shell calls or external side effects. Enforcement must remain in the host's approval rules, filesystem/network isolation and human review. The prose does not confer authority on itself. [1][2]

**Prompt injection.** Both skills consume repository instructions, contracts and runtime evidence; they do not implement provenance validation, taint tracking or an adversarial-input filter. An untrusted repository can present malicious instructions as “governing” material. Host precedence language is helpful but not proof of resistance. Treat source comments, logs, downloaded documentation and plugin updates as data until their authority is established; keep tool permissions independent of the model's interpretation. No prompt-injection exploit or defense benchmark was run. [1][2][7]

**Secrets and network.** No credential store, required API key, telemetry client or service endpoint appears in the supplied skill implementation. That does not make an agent session local or private: repository excerpts, logs and architectural records may enter the chosen model provider's context. Data retention, redaction and tool access are host/provider obligations. Gitignore excludes several environment files, local settings and private planning paths, but ignores are neither a secret scanner nor an access boundary. [12]

**Supply chain and cost.** The README's npx skills@latest route introduces a moving external installer and package-registry trust; plugin updates are a separate version-selection boundary. Pin and review the chosen source revision and installer independently. There is no repository-defined paid API, subscription or cloud deployment. Host model inference, optional tools, broader evidence collection and extra reference reads can still incur token, latency or service costs; no cost or efficiency benchmark is provided. [3][4]

**Persistence and recovery.** There is no autonomous memory database, daemon or durable job queue. Installed prompt files and any host-generated records persist according to the installer/host. Keel gives design guidance for recovery, not a transaction manager that resumes interrupted work. The packager's cleanup trap is practical but cannot guarantee cleanup after an uncatchable kill; replacement of an old archive has no backup/restore procedure. [6][8][11]

## Maturity and Evidence

Anonymous GitHub metadata on the review date reported **243 stars, 19 forks, zero open issues/PRs in the repository aggregate**, creation on 2026-04-13 and last push on **2026-08-21T16:41:22Z**. The reviewed head commit is dated that same UTC instant. Popularity and a zero issue count are not evidence of correctness or safety. [13]

The public releases endpoint returned an empty array. A **v1.4.0 annotated tag exists**, with tag object `411623f051d7d131fa52fae74cdcbe7917517c7f` and peeled commit `388116ee866a2098c96c8a069df90bd8bcae3169`; it is not the reviewed main commit. A manifest version and tag are not a GitHub Release. [14][19]

The rationale documents carefully distinguish Karpathy's cited observations from the project's later failure-mode hypotheses, and Keel names design traditions without presenting them as controlled experiments. This is good attribution and reasoning documentation, not measured evidence that the rules improve success rates. The tracked snapshot contains no tests, CI workflows or published evaluation reports; `evals/` is ignored, so absence here does not prove private evaluations do not exist. The shallow acquisition does not establish longitudinal maintenance quality. [10][12][15]

**Checks performed:** inspected all tracked skill/reference text, manifests, script, license and file inventory; parsed public metadata and manifests; checked anonymous source access, exact head, tags and releases. **Not performed:** installation, script execution, host integration, agent behavior/safety evaluations, provider calls, performance measurements or archival reproducibility tests. No runtime success is claimed.

## Comparison

| Aspect | lencx/skills | Matt Pocock's Skills | Anthropic Skills |
|--------|-------------|----------------------|------------------|
| Primary fit | Two cross-cutting execution/architecture protocols | Composable engineering workflows | Broad examples of task-specific skills and resources |
| Best use | Improve authority, boundary and verification reasoning | Select focused engineering methods | Study skill structure and domain implementations |
| Tradeoff | Abstract prose needs host-specific enforcement and evaluation | Broader catalog needs task selection and overlap management | Breadth does not make every example suitable for a particular host |

These alternatives were compared from their public READMEs, not installed or independently evaluated in this review. The source itself recommends Matt Pocock's collection and Impeccable as companions, not replacements. If existing repository instructions already cover authority and verification well, a small local amendment plus tested host permission rules can be cheaper than loading another overlapping protocol. [3][16][17]

## Self-Hosting Notes

There is no server to self-host. Evaluate one skill at a time in a disposable repository with a pinned revision, no production credentials and constrained tools. Use either copied skills or a native plugin, not both. Before broader adoption, test read-only review versus fix requests, injected repository instructions, unrelated dirty changes, withheld publication authority, failing/insensitive tests and interrupted recovery. Those are proposed acceptance cases, **not tests passed by this review**.

MIT permits adaptation with the required notice; the inspected license credits lencx, 2026, and disclaims warranties. Installer, host-agent and model-provider terms remain separate. No source code or skill text is extracted into this review collection. [18]

## Evidence

All source-file links below are pinned to the reviewed commit; metadata and comparison READMEs are mutable observations retrieved on 2026-11-28 UTC.

[1]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/coding-protocol/SKILL.md
[2]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/keel/SKILL.md
[3]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/README.md
[4]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/.codex-plugin/plugin.json
[5]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/coding-protocol/references/verification.md
[6]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/keel/references/recovery-guards.md
[7]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/keel/references/architecture-records.md
[8]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/keel/references/rot-audit.md
[9]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/keel/references/task-routes-and-lenses.md
[10]: https://github.com/lencx/skills/tree/b848e124111be50a795cc961558247e7751825e2
[11]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/scripts/package-codex-plugin.sh
[12]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/.gitignore
[13]: https://api.github.com/repos/lencx/skills
[14]: https://github.com/lencx/skills/tags
[15]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/skills/coding-protocol/references/rule-rationale.md
[16]: https://github.com/mattpocock/skills/blob/main/README.md
[17]: https://github.com/anthropics/skills/blob/main/README.md
[18]: https://github.com/lencx/skills/blob/b848e124111be50a795cc961558247e7751825e2/LICENSE
[19]: https://api.github.com/repos/lencx/skills/releases

---

**Attribution:** lencx/skills by lencx, MIT.
