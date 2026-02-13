# Custom Slash Commands for Claude Code

This document showcases powerful custom slash commands that can enhance your Claude Code workflow. These commands demonstrate how to create reusable, project-specific automation.

## Getting Started with Custom Commands

Custom commands are stored in `~/.claude/commands/` as markdown files. Each file becomes a slash command that can be invoked with `/filename`.

### Setting Up Commands

1. Create the commands directory: `mkdir -p ~/.claude/commands`
2. Add any of the commands below as `.md` files in that directory
3. Use them with `/command-name` in Claude Code

## Available Commands

### 📚 `/docs` - Documentation Generator
```markdown
Update both the README.md and CLAUDE.md files as appropriate.
If either file does not exist, please create it. Generate the
CLAUDE.md file as though the user invoked the init task.
```
**Use case:** Quickly generate or update project documentation

### 🛡️ `/security-review` - Security Code Review
```markdown
# Security Code Review

Review code for security issues:
- SQL injection vulnerabilities
- XSS prevention
- Authentication/authorization flaws
- Input validation gaps
- Sensitive data exposure
- Insecure cryptography
```
**Use case:** Comprehensive security analysis of your codebase

### 🚀 `/onboard` - Codebase Onboarding Generator
```markdown
# Codebase Onboarding Generator
1. Analyze project structure and key components
2. Write findings to CODEBASE.md with architecture overview
3. Convert analysis to PRESENTATION.md using Slidev format
4. Include: setup instructions, key patterns, gotchas
5. Run: npm run dev to view presentation

Use professional tone, focus on practical insights.
```
**Use case:** Generate onboarding materials for new team members

## Java-Specific Commands

### ⚡ `/modernize-java` - Java Modernization
```markdown
# Modernize Java Code

Update the selected code to use:
- Records instead of POJOs
- Switch expressions
- Local variable type inference where helpful
- Pattern matching where applicable
- Virtual threads for I/O operations (if Java 21+)
- Modern collection factory methods
- Sequenced collections (if Java 21+)
- Text blocks for multiline strings
- Sealed classes if appropriate
```
**Use case:** Upgrade legacy Java code to modern language features

### 🎯 `/spring-controller` - Spring REST Controller Generator
```markdown
# Create Spring REST Controller

Generate a $ARGUMENTS REST controller with:
- @RestController and @RequestMapping("/$ARGUMENTS")
- CRUD endpoints (GET, POST, PUT, DELETE)
- Proper HTTP status codes
- Request/response DTOs for $ARGUMENTS
- Validation annotations
- OpenAPI documentation
- Integration tests

**Usage:** `/spring-controller users` creates UsersController
```
**Use case:** Rapidly scaffold complete REST controllers

### 🔧 `/spring-service` - Spring Service Generator
```markdown
# Create Spring Service

Create a new Spring Boot service class named $ARGUMENTS with:
- @Service annotation
- Constructor injection for $ARGUMENTS repository
- Basic CRUD operations for $ARGUMENTS entity
- Comprehensive logging
- Exception handling
- Unit tests with @MockitoBean and @MockitoSpyBean as necessary

Use modern Java features and follow Spring best practices.
```
**Use case:** Generate service layer components with best practices

## Creating Your Own Commands

### Command Structure
```markdown
# Command Description

Your instructions here...
- Use bullet points for clarity
- Include specific requirements
- Reference $ARGUMENTS for parameters

**Usage examples and notes**
```

### Best Practices
1. **Be Specific**: Clear, actionable instructions work best
2. **Use Variables**: `$ARGUMENTS` gets replaced with command parameters
3. **Include Context**: Mention frameworks, patterns, or standards to follow
4. **Add Examples**: Show expected usage patterns

### Pro Tips
- Commands can reference files, generate tests, and perform complex workflows
- Use commands for repetitive tasks across multiple projects
- Share useful commands with your team via version control
- Start simple and iterate based on actual usage patterns

## Exercise: Create Your First Command

Try creating a simple command for your workflow:

1. `mkdir -p ~/.claude/commands`
2. Create `test-generator.md`:
   ```markdown
   # Generate Test File
   
   Create comprehensive unit tests for the $ARGUMENTS class with:
   - Setup and teardown methods
   - Happy path and edge case tests  
   - Mock dependencies where needed
   - Follow project testing conventions
   ```
3. Use it: `/test-generator UserService`

## Ready-to-Use Command Files

All commands shown above are available as ready-to-use files in the `commands/` directory of this repository. Simply copy them to your `~/.claude/commands/` directory to start using them immediately.

### Quick Setup
```bash
# Copy all commands to your Claude commands directory
cp commands/*.md ~/.claude/commands/
```

## Integration with Course Labs

These commands can enhance the lab exercises:
- **Lab 4-6**: Use custom commands during refactoring exercises
- **Java Projects**: Demonstrate Spring-specific commands with certificate-service
- **Security Focus**: Show security-review command with vulnerable code examples
- **Documentation**: Use onboard command to analyze unfamiliar codebases