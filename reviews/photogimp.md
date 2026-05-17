# PhotoGIMP (Diolinux/PhotoGIMP)

**Repo:** https://github.com/Diolinux/PhotoGIMP
**License:** GPL-3.0 - summarize and study patterns; keep redistributed derivatives GPL-compatible
**Reviewed:** 2026-05-17
**Stack:** GIMP 3.0 profile files, desktop launcher metadata, icons, splash screen, README translations
**What it is:** A configuration and asset patch that makes GIMP 3.0 look and feel more familiar to Adobe Photoshop users.

---

## Verdict

✅ **Deploy candidate for Photoshop-to-GIMP migration, with backups.** PhotoGIMP is a focused usability patch, not a full application. The repo contains profile/configuration files, icons, and documentation; it has no executable installer script in the cloned source, and no suspicious command surface showed up in a text scan. The main risk is that install instructions intentionally overwrite a user's GIMP 3.0 configuration.

---

## What It Is

PhotoGIMP is a community-maintained patch for GIMP 3.0+. It changes GIMP's default layout, tool ordering, keyboard shortcuts, splash screen, icon, and desktop launcher name so users coming from Photoshop get a more familiar starting point.

The repository is mostly a prepared GIMP user profile. The Linux release is designed to be extracted into the user's home directory, placing files under ~/.config/GIMP/3.0 and ~/.local/share. Windows and macOS instructions copy the provided 3.0 profile into each platform's GIMP application-support directory.

This is useful because the hardest part of adopting a powerful open-source creative tool is often workflow disorientation, not missing features. PhotoGIMP attacks that onboarding problem directly.

## Stack

| Layer | Tech |
|-------|------|
| Host app | GIMP 3.0+ |
| Runtime code | None in repository source |
| Configuration | GIMP rc/profile files: shortcutsrc, toolrc, sessionrc, dockrc, gimprc, contextrc, templaterc |
| Assets | PNG icons, splash screen, desktop launcher |
| Platforms | Linux, Windows, macOS via manual profile copy |
| Packaging | GitHub release ZIPs |
| Documentation | README plus Italian, Polish, Portuguese, and Russian translations |

## Key Features

### Photoshop-Like Defaults

The core value is workflow familiarity: Photoshop-like keyboard shortcuts, tool arrangement, panel layout, and canvas-space defaults. This does not make GIMP into Photoshop, but it reduces initial friction for people who already have Photoshop muscle memory.

### Profile Overlay Instead of Fork

PhotoGIMP does not fork GIMP or ship a custom binary. It overlays a user profile. That keeps the project small and avoids the maintenance burden of patching the application itself.

### Clear Backup and Uninstall Docs

The README repeatedly warns that PhotoGIMP overwrites configuration files and gives backup/uninstall steps for Linux, Windows, and macOS. That is the right UX for a tool that modifies user profile state.

### Multi-Platform Manual Install

The install model is simple: run GIMP once, close it, copy the provided profile folder into the GIMP config location, then reopen GIMP. This is easy to audit and avoids hidden installer behavior, but it also depends on users copying files to the correct directory.

## Architecture

The repository is a static profile distribution:

| Path | Role |
|------|------|
| .config/GIMP/3.0/ | GIMP profile files |
| .config/GIMP/3.0/tool-options/ | Per-tool defaults |
| .config/GIMP/3.0/splashes/ | Custom splash screen |
| .local/share/applications/org.gimp.GIMP.desktop | Linux launcher name/icon override |
| .local/share/icons/hicolor/ | PhotoGIMP icons |
| docs/ | Translated README files |
| screenshots/ | Visual reference |

There are 82 profile/asset files under .config and .local in the cloned repo. The only notable security posture issue is not malicious behavior, but state replacement: users with customized GIMP layouts should back up their 3.0 profile first.

## Comparison

| Aspect | PhotoGIMP | GIMP Defaults | Full App Fork |
|--------|-----------|---------------|---------------|
| Goal | Familiar workflow for Photoshop users | Native GIMP workflow | Custom product experience |
| Install risk | Overwrites user profile files | None | Binary/package trust and update burden |
| Maintainability | Small profile/assets repo | Upstream maintained | High maintenance |
| Reversibility | Delete/restore GIMP profile | N/A | Depends on package manager |

## Self-Hosting Notes

There is nothing to build. Review or mirror the release ZIPs if you need controlled deployment.

Safe install posture:

1. Install GIMP 3.0+ from a trusted source.
2. Open and close GIMP once so the profile exists.
3. Back up the current GIMP profile.
4. Copy the PhotoGIMP 3.0 profile into the appropriate GIMP config directory.
5. Launch GIMP and verify layout/shortcuts.

Local review notes:

| Check | Result |
|-------|--------|
| Shallow clone | Passed |
| GitHub metadata | 9,279 stars, 311 forks, 32 open issues, GPL-3.0 |
| Latest release | 3.0, published 2025-03-17 |
| Source scan | No shell/PowerShell installer scripts found in repo source |
| Text risk scan | No suspicious curl/wget/sudo/rm/eval/token/secret hits outside docs/license |

---

**Attribution:** Diolinux/PhotoGIMP, GPL-3.0

