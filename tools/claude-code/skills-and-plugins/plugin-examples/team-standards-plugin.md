# Team Standards Plugin Example

This document demonstrates how to structure a plugin for team-wide distribution.

## Plugin Structure

A Claude Code plugin is a package that can contain:
- Custom slash commands
- Agent configurations
- Hook scripts
- MCP server configurations
- Multiple skills bundled together
- Shared templates and resources

## Example Plugin: "Acme Corp Standards"

### Directory Structure

```
acme-corp-standards/
├── plugin.json                     # Plugin metadata
├── commands/                       # Custom slash commands
│   ├── service.md                 # Generate Spring Boot service
│   ├── controller.md              # Generate REST controller
│   └── repository.md              # Generate JPA repository
├── skills/                        # Custom skills
│   ├── spring-boot-best-practices/
│   │   └── SKILL.md
│   └── acme-api-standards/
│       └── SKILL.md
├── hooks/                         # Hook scripts
│   ├── pre-commit-validation.sh
│   └── security-check.sh
├── mcp/                           # MCP server configs
│   └── internal-apis.json
└── templates/                     # Shared templates
    ├── service-template.java
    ├── controller-template.java
    └── test-template.java
```

### plugin.json

```json
{
  "name": "acme-corp-standards",
  "version": "1.0.0",
  "description": "Acme Corporation development standards and tools",
  "author": "Acme Engineering Team",
  "homepage": "https://github.com/acme/claude-plugins",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/acme/claude-plugins"
  },
  "commands": [
    "service",
    "controller",
    "repository"
  ],
  "skills": [
    "spring-boot-best-practices",
    "acme-api-standards"
  ],
  "hooks": {
    "preCommit": "hooks/pre-commit-validation.sh",
    "preToolUse": {
      "Write": "hooks/security-check.sh"
    }
  },
  "mcpServers": [
    {
      "name": "acme-internal-apis",
      "config": "mcp/internal-apis.json"
    }
  ],
  "settings": {
    "outputStyle": "acme-standard",
    "statusline": {
      "items": [
        {"type": "git_branch"},
        {"type": "custom", "command": "echo '[Acme]'"}
      ]
    }
  }
}
```

### Example Command: commands/service.md

```markdown
# Service Generator

Create a new Spring Boot service class for the $ARGUMENTS entity.

Requirements:
- Use constructor injection with @RequiredArgsConstructor
- Include comprehensive JavaDoc
- Add @Transactional where appropriate
- Generate corresponding test class with @ExtendWith(MockitoExtension.class)
- Follow Acme package naming conventions
- Include audit logging for all data modifications
```

### Example Skill: skills/acme-api-standards/SKILL.md

```markdown
---
name: Acme API Standards
description: Enforce Acme Corporation API development standards
---

# Acme API Standards

## API Versioning
All APIs must use URL-based versioning: `/api/v1/resource`

## Response Format
All responses must follow this structure:

```json
{
  "data": { },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "v1"
  },
  "errors": []
}
```

## Error Handling
Use Acme standard error codes:
- ACME-1001: Authentication failed
- ACME-2001: Resource not found
- ACME-3001: Validation failed

## Monitoring
All endpoints must include:
- Request ID header: X-Acme-Request-Id
- Correlation ID for distributed tracing
- Metrics reporting to Acme monitoring system
```

### Example Hook: hooks/pre-commit-validation.sh

```bash
#!/bin/bash
# Pre-commit validation hook for Acme standards

# Check for forbidden patterns
if git diff --cached | grep -i "TODO\|FIXME\|HACK"; then
    echo "ERROR: Found TODO/FIXME/HACK in staged files"
    echo "Please resolve before committing"
    exit 1
fi

# Verify no hardcoded secrets
if git diff --cached | grep -iE "password|secret|api[_-]?key" | grep -v "# pragma: allowlist secret"; then
    echo "ERROR: Potential hardcoded secret detected"
    echo "Use environment variables or add '# pragma: allowlist secret' if false positive"
    exit 1
fi

# Run tests
./mvnw test
if [ $? -ne 0 ]; then
    echo "ERROR: Tests failed"
    exit 1
fi

echo "✓ Pre-commit validation passed"
exit 0
```

### Example MCP Config: mcp/internal-apis.json

```json
{
  "mcpServers": {
    "acme-internal": {
      "command": "npx",
      "args": ["-y", "@acme/internal-api-mcp"],
      "env": {
        "ACME_API_TOKEN": "${ACME_API_TOKEN}"
      }
    }
  }
}
```

## Plugin Distribution

### Internal Marketplace

For enterprise teams, configure a private marketplace:

**~/.claude/settings.json**:
```json
{
  "extraKnownMarketplaces": [
    {
      "name": "Acme Internal",
      "url": "https://plugins.acme.corp/marketplace.json"
    }
  ]
}
```

### Installation

Team members install via:
```bash
/plugin install acme-corp-standards
```

Or add to project `.claude/settings.json`:
```json
{
  "plugins": {
    "acme-corp-standards": {
      "enabled": true,
      "version": "1.0.0"
    }
  }
}
```

## Benefits

1. **Consistency**: Entire team follows same standards
2. **Onboarding**: New developers get tools immediately
3. **Quality**: Automated checks enforce best practices
4. **Efficiency**: Reusable commands and templates
5. **Integration**: Connect to internal tools via MCP

## Plugin Management Commands

```bash
# Install plugin
/plugin install acme-corp-standards

# List installed plugins
/plugin list

# Enable/disable plugin
/plugin enable acme-corp-standards
/plugin disable acme-corp-standards

# Update plugin
/plugin update acme-corp-standards

# Browse marketplace
/plugin marketplace
```

## Version Control

Plugin configurations should be version controlled:

```bash
# Project-level (committed to repo)
.claude/
├── settings.json          # Plugin configuration
└── plugin-lock.json       # Version pinning

# User-level (not committed)
~/.claude/
└── settings.json          # Personal plugin preferences
```

## Best Practices

1. **Version pinning**: Lock plugin versions in projects
2. **Documentation**: Include README with plugin usage
3. **Testing**: Test plugins before rolling out to team
4. **Versioning**: Use semantic versioning for changes
5. **Changelog**: Maintain detailed changelog
6. **Support**: Provide team support channel

## Example Use Cases

### For Java/Spring Teams
- Spring Boot scaffolding commands
- Microservice generation templates
- Security review skills
- Integration test generators

### For DevOps Teams
- Infrastructure-as-code templates
- Deployment automation commands
- Monitoring setup skills
- CI/CD pipeline generators

### For Frontend Teams
- React component generators
- TypeScript best practices skills
- Accessibility check hooks
- Bundle size monitoring

## Creating Your Own Plugin

1. **Define structure**: Use example above as template
2. **Add commands**: Create .md files in commands/
3. **Include skills**: Add SKILL.md files in skills/
4. **Configure hooks**: Add validation scripts
5. **Test locally**: Install and verify functionality
6. **Document**: Write clear usage instructions
7. **Distribute**: Share via marketplace or git repository
