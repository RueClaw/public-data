# CleanYourTV (Gathin23/cleanyourtv)

**Repo:** https://github.com/Gathin23/cleanyourtv
**License:** MIT; Outfit font SIL OFL-1.1
**Reviewed:** 2026-10-25 (UTC)
**Revision:** 5ee685b02014fa502ea0951ee1f49abd7ee2e8c1; sampled repository-wide architecture, documentation, manifests, security boundaries and tests listed below.
**Verification:** Static source review only. No source execution, installs, device operations, deployments or paid calls.
**Stack:** Java / Android, Python, Bash / PowerShell, Gradle
**What it is:** Android TV cleanup tools and a small native Apple-TV-style launcher, with recorded restoration.

---

## Verdict

⚠️ **Interesting.** Worth a cautious model-specific pilot, not blind execution of a community package list. Concrete validation and restoration guards are a stronger reason to consider it than its rapid popularity; reversibility still depends on retained records and a reachable TV.

## What It Is

Android TV cleanup tools and a small native Apple-TV-style launcher, with recorded restoration. The core workflow backs up package/settings state, disables selected packages for user 0 rather than uninstalling, and installs a native launcher. Themes and optional module cards extend the UI. It does not root Android or replace the OS.

## Stack

| Layer | Technology |
|---|---|
| Implementation | Java / Android, Python, Bash / PowerShell, Gradle |
| Runtime and deployment | See platform constraints below; no deployment was performed. |

## Key Features

### Functionality

The core workflow backs up package/settings state, disables selected packages for user 0 rather than uninstalling, and installs a native launcher. Themes and optional module cards extend the UI. It does not root Android or replace the OS.

### Boundaries and recovery

disable.sh validates package syntax, rejects core Android packages and skips risky setupwraith handling when network ownership cannot be established. Home guards try to avoid leaving the TV without a usable launcher.

### Integration and evidence

restore.sh uses recovery.py and the recorded original state, preserving already-disabled packages. Without a record it warns and falls back to enabling the list: that is not exact restoration.

## Architecture

examples/<model>/tv.json and package lists are community compatibility data. Shell/PowerShell wrappers route through a Python ADB helper, while recovery.py constructs validated restore plans. The launcher is a separate Java/Gradle app; tests cover tool invariants, documentation and device-list contracts. The agent prompt is an optional orchestration layer, not a security boundary.

## Security and Privacy

ADB authorizes powerful device control and some firmware exposes unauthenticated network debugging. Close debugging after maintenance and isolate the device during work. Core-package and Home guards reduce known failure modes but cannot prove a new firmware combination safe. The source itself documents a device that failed to return after core packages were disabled. Privacy benefits are package-dependent: a new launcher does not establish zero telemetry from all remaining apps or firmware. A cloud coding assistant may receive screenshots and diagnostics if used.

## Platform and Self-Hosting Notes

Main scope is Android TV/Google TV. Fire TV generally supports only the debloat portion; some old Fire OS refuses even that. Samsung Tizen and LG webOS are different systems, and community ports are not this launcher. Contributor model records are reports rather than a certification matrix. Keep the original state record, stock launcher and independent recovery access; avoid changing update/security components merely because they appear on a list.

## Evidence, Tests and Limitations

CI declares Python unittest discovery, generated-table checks, Java 17/Android 34 Gradle unit tests/lint/release assembly and a 576 KiB APK ceiling. Tests were inspected, not run; no device, network-debug or rollback validation was performed. The source was only eight days past public repository creation at review time.

This is a sampled static assessment, not a certification or exhaustive security audit. Source claims about hardware, performance and operational recovery remain unverified unless explicitly identified otherwise. Dependency advisories and released-binary provenance were not audited.

## Maturity and Releases

Public latest release API: v3.0.0, 2026-10-25. Fast community growth is not a hardware-safety guarantee. Public API snapshot 2026-10-25: 34520 stars, 4117 forks, 167 open issues/PRs; created 2026-10-17T08:12:35Z; last push 2026-10-25T18:27:58Z.

Popularity and issue counts are discovery signals, not evidence of safety or test success. Mutable metadata was retrieved anonymously on the review date; conclusions refer to the exact source revision above.

## Comparison

FLauncher offers a narrower launcher-only approach; stock Home plus selective settings changes is less invasive. OmarchyTV adds an Omarchy visual style and desktop/AI/MCP integrations at a larger trust and maintenance cost.

## License and Reuse

The root MIT terms permit reuse with copyright and permission notices retained. Bundled dependencies, fonts, media and external services retain their own terms; the stated exceptions must not be flattened into MIT-only redistribution. No upstream code was extracted in this review.

## Source Evidence

- [README.md](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/README.md)
- [LICENSE](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/LICENSE)
- [tools/disable.sh](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/tools/disable.sh)
- [tools/restore.sh](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/tools/restore.sh)
- [tools/recovery.py](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/tools/recovery.py)
- [tools/requirements.txt](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/tools/requirements.txt)
- [.github/workflows/ci.yml](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/.github/workflows/ci.yml)
- [tests/test_core_packages.py](https://github.com/Gathin23/cleanyourtv/blob/5ee685b02014fa502ea0951ee1f49abd7ee2e8c1/tests/test_core_packages.py)

---

**Attribution:** Gathin23/cleanyourtv; MIT; Outfit font SIL OFL-1.1. Analysis based only on public source.
