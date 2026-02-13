#!/bin/bash
# PreToolUse Hook: Auto-format files before editing
#
# This hook runs before the Edit tool executes and automatically
# formats the file according to project standards.
#
# Configuration in ~/.claude/settings.json:
# {
#   "hooks": {
#     "preToolUse": {
#       "Edit": "~/.claude/hooks/pre-edit-formatter.sh"
#     }
#   }
# }

# Get file path from Edit tool arguments
# Claude Code passes tool arguments to hooks
FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
    echo "No file path provided"
    exit 0
fi

# Skip if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Determine file type and format accordingly
case "$FILE_PATH" in
    *.java)
        # Format Java files with google-java-format if available
        if command -v google-java-format &> /dev/null; then
            echo "Formatting Java file: $FILE_PATH"
            google-java-format --replace "$FILE_PATH"
        elif [ -f "mvnw" ]; then
            echo "Formatting Java file with Maven: $FILE_PATH"
            ./mvnw spotless:apply -Dspotless.apply.skip=false &>/dev/null || true
        fi
        ;;
    *.py)
        # Format Python files with black if available
        if command -v black &> /dev/null; then
            echo "Formatting Python file: $FILE_PATH"
            black "$FILE_PATH" --quiet
        elif command -v autopep8 &> /dev/null; then
            echo "Formatting Python file with autopep8: $FILE_PATH"
            autopep8 --in-place "$FILE_PATH"
        fi
        ;;
    *.js|*.ts|*.jsx|*.tsx)
        # Format JavaScript/TypeScript with prettier if available
        if command -v prettier &> /dev/null; then
            echo "Formatting with Prettier: $FILE_PATH"
            prettier --write "$FILE_PATH" --log-level silent
        elif [ -f "node_modules/.bin/prettier" ]; then
            echo "Formatting with local Prettier: $FILE_PATH"
            ./node_modules/.bin/prettier --write "$FILE_PATH" --log-level silent
        fi
        ;;
    *.go)
        # Format Go files with gofmt
        if command -v gofmt &> /dev/null; then
            echo "Formatting Go file: $FILE_PATH"
            gofmt -w "$FILE_PATH"
        fi
        ;;
    *.rs)
        # Format Rust files with rustfmt
        if command -v rustfmt &> /dev/null; then
            echo "Formatting Rust file: $FILE_PATH"
            rustfmt "$FILE_PATH"
        fi
        ;;
esac

# Always allow the edit to proceed
exit 0
