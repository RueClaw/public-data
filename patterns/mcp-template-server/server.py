"""
MCP Template Server Pattern

An MCP server that auto-discovers markdown templates from a directory and exposes
them as queryable tools. Templates follow the naming convention: {language}_{type}.md

Based on coding-standards-mcp by ggerve (https://github.com/ggerve/coding-standards-mcp)
MIT License
"""

from mcp.server.fastmcp import FastMCP
import os
import re
from typing import Dict, List, Optional

# Create the MCP server instance
mcp = FastMCP("template_server")

# --- Template discovery helpers ---

TEMPLATE_DIR = os.path.join(os.path.dirname(__file__), "templates")

# Naming convention: {language}_{type}.md
# e.g. python_style_guide.md, react_best_practices.md
FILENAME_PATTERN = re.compile(r"^(\w+)_(style_guide|best_practices)\.md$")


def parse_template_filename(filename: str) -> Optional[Dict[str, str]]:
    """Extract language and type from a template filename."""
    match = FILENAME_PATTERN.match(filename)
    if match:
        language, template_type = match.groups()
        category = "style_guides" if template_type == "style_guide" else "best_practices"
        return {"language": language, "category": category}
    return None


def read_template(filename: str) -> str:
    """Read a template file and return its contents."""
    path = os.path.join(TEMPLATE_DIR, filename)
    try:
        with open(path, "r") as f:
            return f.read()
    except FileNotFoundError:
        return f"Error: Template '{filename}' not found"
    except Exception as e:
        return f"Error reading '{filename}': {e}"


# --- MCP Tools ---

@mcp.tool()
def list_templates() -> Dict[str, Dict[str, List[str]]]:
    """List all available templates grouped by type and language."""
    templates: Dict[str, Dict[str, List[str]]] = {
        "style_guides": {"languages": [], "files": []},
        "best_practices": {"languages": [], "files": []},
    }

    for filename in sorted(os.listdir(TEMPLATE_DIR)):
        if not filename.endswith(".md"):
            continue
        info = parse_template_filename(filename)
        if info:
            templates[info["category"]]["languages"].append(info["language"])
            templates[info["category"]]["files"].append(filename)

    return templates


@mcp.tool()
def get_style_guide(language: str) -> str:
    """Get coding style guidelines for the specified language (markdown)."""
    return read_template(f"{language}_style_guide.md")


@mcp.tool()
def get_best_practices(language: str) -> str:
    """Get best practices for the specified language (markdown)."""
    return read_template(f"{language}_best_practices.md")
