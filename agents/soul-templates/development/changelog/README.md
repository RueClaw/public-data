# 📋 Log - The Changelog Generator

> Your AI changelog writer that turns git commits into human-readable release notes.

## Overview

Log automates your release process:

- Generates changelogs from git commit history
- Groups by features, fixes, and breaking changes
- Writes release notes for different audiences
- Suggests semantic version numbers

## Quick Start

### Installation

```bash
mkdir -p ~/.openclaw/agents/changelog/agent
cp SOUL.md ~/.openclaw/agents/changelog/agent/

openclaw agents add changelog --workspace ~/.openclaw/agents/changelog
```

### First Conversation

```bash
openclaw chat changelog "Generate changelog from last 10 commits"
```

## Use Cases

### 1. Changelog Generation
```
You: "Generate changelog from last 10 commits"
Log: [Categorized changelog: Added, Changed, Fixed, Removed, Breaking]
```

### 2. User-facing Release Notes
```
You: "Release notes for users"
Log: [Non-technical summary: what's new, what's fixed, what changed]
```

### 3. Release Announcement
```
You: "Write a release tweet"
Log: [Concise announcement with key highlights]
```

### 4. Version Suggestion
```
You: "What version should this be?"
Log: [Semantic version based on changes: major if breaking, minor if features, patch if fixes]
```

## Example Outputs

### Changelog

```
## [1.4.0] - 2026-02-16

### Added
- PostgreSQL integration for AI agents
- Checkout failure tracking in Mixpanel

### Changed
- Agent pricing: $9 → $5

### Fixed
- Stripe checkout failing on large configs
- Price ID newline validation error
```

### Release Notes

```
What's New - Feb 16

Lower pricing: Agent package now $5.
PostgreSQL: Connect your agent to any database.
Checkout fix: Some users couldn't complete payment.
```

## Tips

1. **Use conventional commits** - `feat:`, `fix:`, `breaking:` help Log categorize
2. **Generate before tagging** - Review the changelog before creating a release
3. **Write for users** - Ask for user-facing notes, not developer notes
4. **Include migration steps** - For breaking changes, always explain what to do

## Changelog

- **v1.0.0** - Initial release with git log parsing
- **v1.1.0** - User-facing release notes
- **v1.2.0** - Version suggestion and GitHub Releases

## Author

Created by [@openclaw](https://github.com/openclaw)

## License

MIT
