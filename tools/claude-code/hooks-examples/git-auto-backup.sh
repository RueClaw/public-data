#!/bin/bash
# PreToolUse Hook: Auto-backup with git before major operations
#
# Creates a git stash before risky operations to enable easy rollback.
#
# Configuration in ~/.claude/settings.json:
# {
#   "hooks": {
#     "preToolUse": {
#       "Edit": "~/.claude/hooks/git-auto-backup.sh",
#       "Write": "~/.claude/hooks/git-auto-backup.sh"
#     }
#   }
# }

# Only run if we're in a git repository
if ! git rev-parse --git-dir &> /dev/null; then
    exit 0
fi

# Check if there are changes to stash
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    STASH_MSG="claude-code-auto-backup-$TIMESTAMP"

    echo "📦 Creating git backup: $STASH_MSG"

    # Create stash with untracked files
    git stash push -u -m "$STASH_MSG" &>/dev/null

    if [ $? -eq 0 ]; then
        echo "✓ Backup created successfully"
        echo "   To restore: git stash apply stash@{0}"
    else
        echo "⚠️  Backup creation failed (continuing anyway)"
    fi
fi

# Always proceed with operation
exit 0
