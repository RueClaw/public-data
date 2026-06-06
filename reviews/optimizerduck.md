# optimizerDuck (itsfatduck/optimizerDuck)

**Repo:** https://github.com/itsfatduck/optimizerDuck  
**License:** GPL-3.0; summarize and study freely, but derivative redistribution must respect GPL copyleft  
**Reviewed:** 2026-06-06  
**Stack:** C#, WPF, .NET 10, WPF UI, CommunityToolkit.Mvvm, Serilog, PowerShell, Windows registry, Windows Task Scheduler  
**What it is:** A Windows 10/11 desktop optimizer that applies reversible registry, service, scheduled-task, power-plan, AppX, startup, and cleanup changes through a WPF UI.

---

## Verdict

⚠️ **Interesting Windows optimizer with better safety posture than most tweak tools, but not a blind deploy candidate.** optimizerDuck has real engineering around reversibility, risk labels, CI, localization, and tests for apply/revert behavior. The caution is the domain itself: many tweaks alter services, telemetry, GPU registry keys, scheduled tasks, AppX packages, and cleanup targets, so every applied action should be reviewed like a system policy change, not treated as a generic "speed up my PC" button.

---

## What It Is

optimizerDuck is a portable Windows desktop app for applying system tweaks from one UI. It targets performance, privacy, GPU behavior, power management, service startup types, bloatware controls, desktop customization, startup apps, scheduled tasks, and disk cleanup.

The app's best idea is not any single tweak. It is the operation model: changes are represented as explicit optimization classes, applied through typed providers, recorded into local JSON revert files, and then used to infer applied state and support one-click rollback. That is a much stronger posture than scripts that just write registry keys and hope the user remembers what changed.

It is still a system mutation tool. Some bundled changes are low-risk preferences, while others disable services or set hardware/vendor-specific registry values. The UI's risk labels and restore-point prompt help, but they do not replace per-machine review.

## Stack

| Layer | Tech |
|-------|------|
| Desktop app | C# WPF targeting `net10.0-windows10.0.17763.0` |
| UI framework | WPF UI, CommunityToolkit.Mvvm, XAML views/view-models |
| System mutation | Windows registry, `sc.exe`, PowerShell, Task Scheduler COM/library, `powercfg` |
| State/revert | Local JSON files under `%LOCALAPPDATA%\\optimizerDuck\\Revert` |
| Logging/config | Serilog, Microsoft.Extensions.Hosting/DI, JSON config |
| Tests/CI | xUnit v3 tests, Windows GitHub Actions build/test, release workflow |

## Key Features

### Reversible Optimization Flow

Registry writes, service changes, scheduled task changes, shell commands, and USB power-state changes can record revert steps. The app stores successful steps in indexed JSON so partial application can still be rolled back step-by-step in reverse order.

This is the main reason the repo is worth studying. The code treats "applied" state as the presence of revert data, not as a separate wishful flag.

### Reflection-Based Feature Discovery

Optimization and customization categories discover nested implementations through attributes and reflection. New tweaks can be added as nested classes with metadata rather than manually registering every item in a central list.

That keeps the WPF navigation and optimization registry relatively clean, while still making each tweak inspectable in source.

### Built-In Windows Management Tools

The app includes a dashboard, startup manager, scheduled task browser/actions, disk cleanup, and AppX bloatware remover. These are not novel individually, but packaging them beside the optimization/revert flow makes the tool more useful than a registry-tweak checklist.

### Localization and Release Pipeline

The repository has translated READMEs and app localization resources for multiple languages, plus Windows CI and a release workflow that builds, tests, publishes a single executable, and attaches it to GitHub Releases.

## Architecture

The code is organized around domain categories, provider services, and WPF view-models:

- `Domain/Optimizations/Categories/*` contains concrete tweaks such as telemetry reduction, service startup configuration, GPU registry changes, hibernation/power-plan changes, and UI latency tweaks.
- `Services/Optimization/Providers/*` wraps registry, service, scheduled task, and shell operations.
- `Services/Revert/RevertManager.cs` serializes and replays revert steps with per-optimization file locks and partial-failure handling.
- `Services/Optimization/OptimizationRegistry.cs` discovers optimization categories and updates applied state from revert files.
- `Services/UI/*` implements the bloatware, disk cleanup, scheduled task, startup, dashboard, and update-checking surfaces.

Security scan notes: I found no hardcoded secrets, API keys, or telemetry collection. The update checker calls the GitHub releases API, and the README/privacy language is consistent with an offline app except for explicit update/community links.

Local verification was limited because `dotnet` is not installed in this review environment. Upstream GitHub Actions CI for the latest commit `933c8f8` completed successfully on 2026-06-04.

## Comparison

| Aspect | optimizerDuck | WinUtil-style tweak scripts | Windows Settings/Admin consoles |
|--------|---------------|-----------------------------|---------------------------------|
| Interface | Desktop WPF app with grouped toggles/tools | Script/menu driven | Native but scattered |
| Revert model | JSON-backed revert steps for many operations | Varies widely; often script-specific | Usually manual |
| Transparency | Public GPL source, typed tweak classes | Public if script is open | Built into OS, less centralized |
| Risk | Medium: modifies system services/tasks/registry | Medium to high depending on script | Lower when using supported UI |
| Best fit | Power users who inspect selected changes | Operators comfortable reading scripts | General users/admins |

## Self-Hosting Notes

This is a Windows desktop app, not a server. Use the GitHub release binary or build from source with the .NET 10 SDK on Windows.

Operational cautions:

- Create a restore point and review selected optimizations before applying them.
- Treat service startup changes and GPU registry tweaks as machine-specific.
- Unsigned release binaries may trigger SmartScreen; build from source if binary trust matters.
- GPL-3.0 limits proprietary reuse of code. Summarize patterns or comply with GPL if deriving code.

---

**Attribution:** itsfatduck/optimizerDuck, GPL-3.0. Review based on repository source, README, license, GitHub metadata, latest release metadata, upstream CI metadata, and local static inspection on 2026-06-06.
