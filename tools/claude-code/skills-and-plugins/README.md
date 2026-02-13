# Skills and Plugins Examples

This directory contains example custom skills and plugin configurations for the Claude Code training course.

## Directory Structure

```
skills-and-plugins/
├── README.md                           # This file
├── spring-boot-skill/                  # Example: Java Spring Boot generator
│   └── SKILL.md
├── api-documentation-skill/            # Example: API documentation generator
│   └── SKILL.md
├── security-review-skill/              # Example: Security analysis
│   └── SKILL.md
└── plugin-examples/                    # Example plugin configurations
    └── team-standards-plugin.md
```

## What Are Skills?

**Skills** are modular capabilities that extend Claude's functionality with persistent, reusable domain expertise. They:
- Load automatically when contextually relevant
- Persist across conversations
- Use a three-tier loading system (metadata, instructions, resources)
- Can include templates, scripts, and reference files

## What Are Plugins?

**Plugins** (v2.0.12+) are installable packages that can contain:
- Custom slash commands
- Agent configurations
- Hook scripts
- MCP server setups
- Multiple skills bundled together

## Using These Examples

### Installing Custom Skills

1. **Copy a skill directory** to your local skills folder:
   ```bash
   cp -r spring-boot-skill ~/.claude/skills/
   ```

2. **Skill activates automatically** when relevant:
   ```bash
   claude
   > "Create a Spring Boot REST controller for User management"
   # The spring-boot-skill will activate automatically
   ```

### Plugin Development

The `plugin-examples/` directory shows how to structure plugins for team distribution.

## Lab Exercises

Students will:
1. Install and test a pre-built skill
2. Create their own custom skill
3. Understand the three-tier loading system
4. Learn when skills activate vs. when to use custom commands

## Resources

- [Agent Skills Documentation](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview)
- [Plugin System Guide](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md#plugin-system)
