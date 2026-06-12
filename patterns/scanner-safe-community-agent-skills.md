# Scanner-Safe Community Agent Skills

**Source:** [tmchow/agent-skills](https://github.com/tmchow/agent-skills)
**License:** MIT
**Reviewed:** 2026-06-11

## Pattern

Community-installable agent skills should be designed for hostile scanner interpretation. The skill must not merely be benign; it must avoid patterns that look like credential exfiltration, supply-chain drift, unsafe subprocess behavior, or hidden install bloat.

The core rules:

- keep `SKILL.md` focused on agent operating judgment, not a full manual;
- put human prerequisites and install commands in `README.md`;
- require `name`, `description`, and `version` in front matter;
- keep descriptions specific enough that the skill does not hijack broad tasks;
- do not read ambient secret-shaped environment variables from community skill code;
- do not accept secrets through CLI flags;
- write credentials only through a user-run init flow into a mode-600 config file;
- pin install commands quoted in docs or scripts;
- keep functional assets inside the installed skill and docs-only examples outside it;
- checksum binary assets and provide a repair path for runtimes that corrupt multi-file installs.

## Why It Works

Agent skills are not ordinary libraries. They are executable operating instructions loaded into a privileged agent context. A scanner has to assume the worst: an env read might steal another tool's API key, a subprocess might exfiltrate data, and a large binary bundle might hide more than the user expected to install.

Designing for scanner-safe interpretation gives users and runtimes a clearer trust boundary. It also makes skills more portable across Claude Code, Codex, Hermes, OpenClaw, Cursor, and future Agent-Skills-compatible systems.

## Implementation Notes

- Use one top-level directory per skill, with `SKILL.md` and `README.md`.
- Move deep material into `references/` and load it only when the task needs it.
- Put runtime-specific metadata in additive front matter blocks; unknown fields should be safe to ignore.
- Tell agents to verify external tool syntax with live `--help` instead of copying stale flag catalogs.
- If a skill needs an API key, provide an init command that prompts the user and writes a local config file with restrictive permissions.
- For ephemeral cloud environments, document a setup-hook bridge from the platform's scoped secret store into the skill config file.
- For binary assets, generate a manifest of known-good hashes and immutable source commits; verify in CI and provide a repair script.

## Good Fit

This pattern is useful for public or semi-public skill catalogs, marketplace-distributed skills, multi-runtime Agent Skills repositories, and any skill that wraps credentialed APIs or ships binary assets.

## Caveats

Scanner-safe does not mean risk-free. It only means the skill avoids common static red flags. Runtimes still need permission boundaries, users still need to review what each skill does, and external tools still need live verification.

---

**Attribution:** tmchow/agent-skills, MIT License.
