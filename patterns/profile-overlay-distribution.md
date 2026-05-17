# Profile Overlay Distribution

**Source:** https://github.com/Diolinux/PhotoGIMP
**License:** GPL-3.0
**Reviewed:** 2026-05-17
**Use case:** Customizing a mature desktop application's workflow without forking or rebuilding the application.

---

## Pattern

Ship a curated user-profile overlay instead of a forked application. The overlay contains configuration files, shortcut maps, layout state, launcher metadata, icons, templates, and visual assets. Users install it by copying the profile into the host application's config directory.

PhotoGIMP uses this pattern for GIMP 3.0. It distributes GIMP profile files that make the app more familiar to Photoshop users while leaving the upstream GIMP binary untouched.

## Why It Matters

Forking a large desktop app is expensive. A profile overlay solves a narrower problem: make the default experience feel right for a specific audience.

This is useful when:

- the host app already supports user-level configuration
- the target audience needs familiar defaults more than new engine features
- the customization should be reversible
- maintenance should track upstream rather than replace it

## Design Checklist

- Document exactly which profile paths are overwritten.
- Tell users to run the host app once before install, so default profile directories exist.
- Put backup instructions before install instructions.
- Provide uninstall and restore steps.
- Avoid executable installers unless they add real value.
- Keep assets and profile files inspectable in the repo.
- Version overlays against host-app major versions.

## Risks

- Profile overlays can overwrite personal settings.
- Host app profile formats may change between major versions.
- Layout files may encode monitor/window assumptions that do not fit every user.
- Users may install into the wrong config path, especially across package formats or operating systems.

---

**Attribution:** Extracted from Diolinux/PhotoGIMP, GPL-3.0.

