# Knowledge Work Plugins Architecture

> **Source:** [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins)
> **License:** Apache 2.0
> **Description:** Plugin architecture for role-specific AI assistants. Skills, connectors, slash commands, and sub-agents bundled by job function.

## Overview

Knowledge Work Plugins turn Claude into a specialist for specific roles, teams, and companies. Each plugin bundles skills, connectors, slash commands, and sub-agents for a job function.

## Plugin Categories

| Plugin | Focus | Key Connectors |
|--------|-------|----------------|
| **productivity** | Tasks, calendars, daily workflows | Slack, Notion, Asana, Linear, Jira |
| **sales** | Prospects, calls, pipeline, outreach | HubSpot, Close, Clay, ZoomInfo |
| **customer-support** | Tickets, responses, escalations | Intercom, HubSpot, Guru, Jira |
| **product-management** | Specs, roadmaps, user research | Linear, Figma, Amplitude, Pendo |
| **marketing** | Content, campaigns, brand voice | Canva, HubSpot, Ahrefs, Klaviyo |
| **legal** | Contracts, NDAs, compliance | Box, Egnyte, Jira |
| **finance** | Journal entries, reconciliation, audits | Snowflake, Databricks, BigQuery |
| **data** | Queries, visualization, analysis | Snowflake, Hex, Amplitude |
| **enterprise-search** | Cross-platform search | Slack, Notion, Guru, Jira |
| **bio-research** | Literature, genomics, targets | PubMed, ChEMBL, Benchling |

## Plugin Structure

```
plugin/
├── README.md           # Overview and commands
├── CONNECTORS.md       # Data source configuration
├── .mcp.json           # MCP server connections
├── commands/           # Slash command definitions
└── skills/             # Skill implementations
```

## Skills Pattern

Skills fire automatically when relevant. Example from productivity:

### memory-management

Two-tier memory system:
- `CLAUDE.md` — Working memory (current context)
- `memory/` directory — Deep storage (long-term reference)

### task-management

Markdown-based task tracking:
- Shared `TASKS.md` file
- Claude reads, writes, and executes against it
- Syncs with external project trackers

## Slash Commands

Commands for explicit actions:

```
/start               — Initialize tasks + memory, open dashboard
/update              — Triage stale items, check memory gaps, sync tools
/update --comprehensive — Deep scan email, calendar, chat for todos
```

## Connector Architecture

Each plugin defines its data sources in `CONNECTORS.md`:

```markdown
## Chat
- **Slack** — Team context and message scanning

## Email & Calendar
- **Microsoft 365** — Action item discovery

## Knowledge Base
- **Notion** — Reference documents

## Project Tracker
- **Asana** | **Linear** | **Jira** — Task syncing
```

## Workplace Memory Pattern

Two-tier memory enables shorthand decoding:

**Before memory:**
```
User: ask todd to do the PSR for oracle
Claude: Who is Todd? What is PSR? Which Oracle deal?
```

**After memory populated:**
```
User: ask todd to do the PSR for oracle
Claude: "Ask Todd Martinez (Finance lead) to prepare the
         Pipeline Status Report for the Oracle Systems deal
         ($2.3M, closing Q2)"
```

## Building Custom Plugins

1. **Define skills** for your workflows
2. **Configure connectors** for your tools
3. **Create commands** for common actions
4. **Seed memory** with your terminology

```yaml
# Example: cowork-plugin-management
- Create new plugins or customize existing ones
- Organization-specific tools and workflows
- No external connectors required
```

## Key Design Principles

- **Role-specific bundles** — Each job function gets tailored capabilities
- **Connector flexibility** — Swap tools per category
- **Memory enables shorthand** — No clarifying questions after setup
- **Skills fire automatically** — Commands for explicit actions
- **Customize for your org** — Starting points, not final solutions
