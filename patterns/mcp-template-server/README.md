# MCP Template Server Pattern

A pattern for building MCP servers that auto-discover markdown templates and expose them as tools. Drop markdown files into a `templates/` directory with a naming convention, and they become queryable MCP tools automatically.

## How It Works

1. A `templates/` directory contains markdown files following the naming pattern: `{language}_{type}.md`
2. The server scans this directory at startup and registers tools to list and retrieve templates
3. Clients can list available templates and fetch them by language/type

## Tools Exposed

- **`list_templates`** — Returns all available templates grouped by type and language
- **`get_style_guide(language)`** — Retrieves the style guide for a given language
- **`get_best_practices(language)`** — Retrieves best practices for a given language

## Running

```bash
uv run --with "mcp[cli]" mcp run server.py
```

## Adapting the Pattern

The core idea is generic — you can adapt it for any domain:
- API documentation templates
- Prompt libraries
- Runbook collections
- Configuration references

Just change the naming convention and the tool signatures to match your domain.

## Attribution

This pattern is extracted from [coding-standards-mcp](https://github.com/ggerve/coding-standards-mcp) by **ggerve**, licensed under the [MIT License](https://github.com/ggerve/coding-standards-mcp/blob/main/LICENSE).
