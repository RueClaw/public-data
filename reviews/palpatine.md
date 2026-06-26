# Palpatine (NovusEdge/palpatine)

**Repo:** https://github.com/NovusEdge/palpatine
**License:** Non-standard "Sith Public License"; plugin manifest says MIT, which conflicts with the repository license
**Reviewed:** 2026-06-25
**Stack:** Claude Code plugin metadata, Agent Skills Markdown, Node.js session-start hook, JSON pattern indexes
**What it is:** `palpatine` is a Claude Code skill/plugin bundle that reframes interpersonal, workplace, negotiation, and conflict advice through Robert Greene-style power, seduction, and war pattern libraries.

---

## Verdict

❌ **Pass as an installable assistant skill.** There are a few interesting prompt-packaging ideas, especially the bounded "unlimited-power" orchestration pattern and the defense-mode manipulation taxonomy, but the core skill intentionally suppresses moral caution and asks the assistant to treat people as manipulable systems. The license is also non-standard and inconsistent across files, so this is not a clean reuse target.

---

## What It Is

`palpatine` is not an application. It is a Claude Code plugin-style package with eight skills, three JSON pattern indexes, and one session-start hook. The main skill persona is an intentionally ruthless strategic advisor. The supporting skills search or apply ideas from *The 48 Laws of Power*, *The Art of Seduction*, and *The 33 Strategies of War*.

The repo includes modes for advice, defense, wargaming, adversary modeling, seduction references, "laws" lookup, "war" lookup, and a recursive subagent orchestration pattern called `unlimited-power`. The hook checks for `~/.claude/palpatine-enabled` and prints an "always-on" activation message at session start.

There is no package manifest, build, test harness, or runtime app. The value and risk are almost entirely in the prompt content.

## Stack

| Layer | Tech |
|-------|------|
| Plugin metadata | `.claude-plugin/plugin.json`, `.github/plugin/marketplace.json` |
| Skill content | Markdown `SKILL.md` files |
| Pattern data | `law_index.json`, `seduction_index.json`, `war_index.json` |
| Hooks | Node.js `SessionStart` command hook |
| Tests/CI | None observed |

## Key Features

### Persona Skill

`skills/palpatine/SKILL.md` defines the main behavior: short, cold diagnosis and action lists for interpersonal or strategic situations. It explicitly tells the assistant not to moralize, hedge, soften, or behave like a therapist.

That is the central problem. A strong voice can be useful; a voice designed to bypass ethical friction and frame manipulation as ordinary "business" is not a good default assistant behavior.

### Defense Mode

`skills/defense/SKILL.md` is the most defensible part of the repo. It names manipulation patterns such as DARVO, triangulation, gaslighting, love bombing, strategic incompetence, bait-and-switch, intermittent reinforcement, moving goalposts, and weaponized emotions, then gives counters.

This section could be useful if separated from the broader manipulative persona and rewritten in a safer support/advocacy voice.

### Wargame and Adversary Modeling

The wargame/adversary skills show a familiar multi-party analysis pattern: identify players, map likely moves, track alliances and leverage, and cap simulations. For business strategy or negotiation planning, that structure can be legitimate. In this repo, though, it is embedded in an intentionally predatory framing.

### Bounded Recursive Orchestrator

`skills/unlimited-power/SKILL.md` is the strongest technical pattern. It insists on a verifiable done-condition, hard caps on waves/width/dispatch/depth, leaf agents that do not spawn, a repeated-gap stall guard, and explicit terminal states.

That is a useful antidote to unbounded agent loops. The pattern is worth studying, but the surrounding package is not worth installing.

### Session Hook

The plugin declares a `SessionStart` hook that runs `hooks/activate.js`. The hook only checks for `~/.claude/palpatine-enabled` and prints an activation message if present. `hooks/match-laws.js` exists but is not wired in `hooks/hooks.json` in the reviewed checkout.

## Architecture

The repository layout is minimal:

- `skills/*/SKILL.md` contains the behavior layer.
- `law_index.json`, `seduction_index.json`, and `war_index.json` contain lookup data.
- `hooks/activate.js` checks persistent always-on state.
- `.claude-plugin/plugin.json` declares plugin metadata and points at `hooks/hooks.json`.

Static validation performed:

- JSON parse passed for plugin metadata, hook config, and all three indexes.
- `node -c` passed for both hook scripts.
- Targeted scan found no network calls, token reads, shell spawning, or broad filesystem mutation beyond the documented `~/.claude/palpatine-enabled` state file.
- No package manifest, tests, or CI were present.
- GitHub metadata on 2026-06-25: 60 stars, 5 forks, 0 open issues, latest push 2026-06-25.

## Security and Safety Notes

The technical hook surface is small, but the behavioral surface is risky:

- The main skill tells the assistant that morality is a tool others use to constrain the user.
- The "Dark Arts" section says to flag legal exposure for illegal/harmful requests, then continue with mechanics, risks, and alternatives.
- The repo explicitly welcomes manipulation tactics and rejects ethical-guideline contributions.
- The license badge/README says "Sith Public License" while `.claude-plugin/plugin.json` says MIT.

That combination makes it a poor candidate for an assistant that should maintain trustworthy boundaries.

## Comparison

| Aspect | Palpatine | tufte-claude-skill | visual-explainer | qship |
|--------|-----------|--------------------|------------------|-------|
| Primary job | Persona/power-strategy advice | Chart discipline | Visual HTML explanations | Agent delivery workflow |
| Best pattern | Bounded loop and defense taxonomy | Decision table + kill list | Representation routing | Hook-gated workflow |
| Runtime risk | Low code risk, high behavior risk | Low | Low-medium generated HTML | High autonomy surface |
| Reuse posture | Study isolated patterns only | Reuse/adapt | Reuse/adapt | Pilot carefully |

## Self-Hosting Notes

Do not install this as an always-on assistant layer. If you inspect it, keep it as a read-only reference. Do not import the persona or "dark arts" guidance into shared assistant defaults.

The only pieces worth reworking are:

- bounded recursive orchestration with caps and terminal states;
- manipulation-pattern detection for defensive use;
- compact lookup indexes for routeable skill references.

---

**Attribution:** NovusEdge/palpatine, non-standard "Sith Public License" with manifest/license inconsistency.
