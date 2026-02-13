# Hook Examples

This directory contains advanced hook patterns for Claude Code workflow automation.

## What Are Hooks?

**Hooks** are shell commands that execute in response to Claude Code events:
- **SessionEnd**: Runs when Claude Code session ends
- **PreToolUse**: Runs before specific tools execute (can modify tool inputs)
- **User-Prompt-Submit**: Pre-process prompts before execution

## Hook Configuration

Hooks are configured in `~/.claude/settings.json` or `.claude/settings.json`:

```json
{
  "hooks": {
    "sessionEnd": "path/to/session-end-hook.sh",
    "preToolUse": {
      "Edit": "path/to/pre-edit-hook.sh",
      "Write": "path/to/pre-write-hook.sh",
      "Bash": "path/to/pre-bash-hook.sh"
    },
    "userPromptSubmit": "path/to/prompt-hook.sh"
  }
}
```

## Examples in This Directory

1. **session-end-summary.sh** - Generate session summary and statistics
2. **pre-edit-formatter.sh** - Auto-format files before editing
3. **security-validator.sh** - Validate security before file writes
4. **git-auto-backup.sh** - Create git stash before major operations
5. **test-runner-hook.sh** - Run tests before certain operations
6. **dependency-checker.sh** - Check for dependency updates

## Hook Best Practices

1. **Exit codes matter**: Return 0 to allow operation, non-zero to block
2. **Feedback is user input**: Hook output appears as if from the user
3. **Be fast**: Hooks run synchronously; slow hooks delay operations
4. **Error handling**: Provide clear error messages when blocking
5. **Idempotent**: Hooks should be safe to run multiple times

## Using These Examples

Copy hook scripts to your `.claude/hooks/` directory and configure in settings:

```bash
# Copy example hooks
cp session-end-summary.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/session-end-summary.sh

# Configure in ~/.claude/settings.json
{
  "hooks": {
    "sessionEnd": "~/.claude/hooks/session-end-summary.sh"
  }
}
```

## Lab Exercises

Students will:
1. Configure a SessionEnd hook to generate summaries
2. Create a PreToolUse hook for security validation
3. Build a custom hook for their workflow
4. Understand hook feedback and blocking

## Resources

- [Claude Code Hooks Documentation](https://docs.claude.com/en/docs/claude-code/overview)
- Hook examples from changelog (v1.0.85+, v2.0.10+)
