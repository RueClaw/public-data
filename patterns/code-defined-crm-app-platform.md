# Code-Defined CRM App Platform

**Source:** https://github.com/twentyhq/twenty
**Reviewed:** 2026-05-23
**License context:** Twenty is AGPL-3.0 with Enterprise-marked files. This pattern is a clean-room architecture summary with attribution, not copied implementation.

## Pattern

Treat CRM customization as a code-defined application layer rather than only as admin-panel configuration. A CRM platform can expose typed app packages that declare objects, fields, views, navigation items, roles, logic functions, frontend components, skills, and agents as source-controlled project files.

This gives teams the operational benefits of normal software delivery:

- changes can be reviewed in pull requests;
- app definitions can be tested, linted, built, and published;
- local development can run against a disposable CRM instance;
- generated clients and metadata can keep frontend/backend/API surfaces in sync;
- production workspaces can install versioned app packages instead of replaying manual setup.

## Why It Matters

CRM systems accumulate domain-specific schema and workflow changes quickly. If those changes live only in a database or admin UI, they are hard to diff, migrate, test, roll back, or share across environments.

A code-defined app layer makes business configuration reproducible. It also creates a natural bridge for agents: an agent can reason over typed objects, views, actions, and skills because the domain shape exists as files with stable names and declarations.

## Typical Building Blocks

### App Scaffolder

Provide a one-command project generator that creates a typed app package with package scripts, test and lint configuration, API client setup, local development server configuration, example domain entities, and clear generated-file boundaries.

### Entity Generators

Expose CLI commands for adding common CRM extension entities: object, field, logic function, frontend component, role, skill, agent, view, navigation item, and page layout.

Generators should create required IDs and boilerplate consistently so humans and agents do not invent incompatible shapes.

### Local Development Runtime

Use Docker or another reproducible runtime to start a local CRM instance for app development. The scaffolder should configure a development API key or OAuth flow and regenerate typed clients as metadata changes.

### Metadata-Aware Client

Generate a client that knows the current object/field model. This reduces brittle stringly typed API calls and gives UI, tests, and agents a stable vocabulary for records.

### Guardrails

Add custom lint rules or validation gates for platform-specific invariants: user-visible objects need usable views, navigation views need navigation items, API endpoints and resolvers must declare auth and permission guards, generated IDs and filenames must follow conventions, and frontend components must fit the host canvas or widget constraints.

## Implementation Notes

- Keep the runtime product and app SDK versioned together, or publish a compatibility matrix.
- Make local development disposable; app authors should be able to reset the CRM container and reapply their app.
- Separate public app definitions from private workspace secrets and credentials.
- Generate types from metadata, but make regeneration deterministic and cheap enough to run often.
- Keep an escape hatch for manual admin changes, but treat source-controlled app definitions as the durable system of record.

## Good Fit

- CRMs and internal tools with repeated customer/workspace customization.
- Vertical SaaS platforms that need tenant-specific workflows.
- Agent-facing business systems where typed objects/actions improve tool reliability.
- Marketplace ecosystems where extensions need build/test/publish lifecycles.

## Poor Fit

- Small teams with one static schema and no deployment promotion path.
- Products where all customization is ad hoc and never reused.
- Highly regulated deployments that cannot accept AGPL/open-core licensing without legal review.

---

**Attribution:** Pattern derived from the public architecture of twentyhq/twenty.
