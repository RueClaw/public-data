#!/bin/bash
# Session End Hook: Generate summary of session activity
#
# This hook runs when a Claude Code session ends and creates
# a summary of what was accomplished.
#
# Configuration in ~/.claude/settings.json:
# {
#   "hooks": {
#     "sessionEnd": "~/.claude/hooks/session-end-summary.sh"
#   }
# }

# Get session directory (Claude Code sets this)
SESSION_DIR="${CLAUDE_SESSION_DIR:-.}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
SUMMARY_FILE="${SESSION_DIR}/.claude/session-summaries/${TIMESTAMP}.md"

# Create summary directory if it doesn't exist
mkdir -p "$(dirname "$SUMMARY_FILE")"

# Generate summary
cat > "$SUMMARY_FILE" << EOF
# Claude Code Session Summary
**Date**: $(date +"%Y-%m-%d %H:%M:%S")
**Duration**: ${CLAUDE_SESSION_DURATION:-Unknown}
**Working Directory**: $(pwd)

## Files Modified
EOF

# List files modified in this session (last hour)
if command -v git &> /dev/null; then
    echo "" >> "$SUMMARY_FILE"
    git status --short >> "$SUMMARY_FILE" 2>/dev/null || echo "No git changes detected" >> "$SUMMARY_FILE"
fi

# Add git log if available
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
    echo -e "\n## Commits This Session" >> "$SUMMARY_FILE"
    git log --oneline --since="1 hour ago" >> "$SUMMARY_FILE" 2>/dev/null || echo "No commits in last hour" >> "$SUMMARY_FILE"
fi

# Count tool uses (if log available)
echo -e "\n## Session Statistics" >> "$SUMMARY_FILE"
echo "- Files in repository: $(find . -type f | wc -l)" >> "$SUMMARY_FILE"
echo "- Lines of code: $(find . -name "*.java" -o -name "*.py" -o -name "*.js" -o -name "*.ts" | xargs wc -l 2>/dev/null | tail -1 || echo '0')" >> "$SUMMARY_FILE"

# Notify user
echo "✓ Session summary saved to: $SUMMARY_FILE"

# Optional: Open summary in editor
# code "$SUMMARY_FILE" || vi "$SUMMARY_FILE"

exit 0
