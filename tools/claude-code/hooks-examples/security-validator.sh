#!/bin/bash
# PreToolUse Hook: Security validation before file writes
#
# This hook runs before Write/Edit operations and checks for
# common security issues like hardcoded secrets.
#
# Configuration in ~/.claude/settings.json:
# {
#   "hooks": {
#     "preToolUse": {
#       "Write": "~/.claude/hooks/security-validator.sh",
#       "Edit": "~/.claude/hooks/security-validator.sh"
#     }
#   }
# }

FILE_PATH="$1"
CONTENT="${2:-}"  # Content may be passed as second argument

# Skip if no file specified
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Create temporary file for content if not available
TEMP_FILE=""
if [ -z "$CONTENT" ] && [ -f "$FILE_PATH" ]; then
    TEMP_FILE="$FILE_PATH"
elif [ -n "$CONTENT" ]; then
    TEMP_FILE=$(mktemp)
    echo "$CONTENT" > "$TEMP_FILE"
else
    # No content to check
    exit 0
fi

# Security checks
VIOLATIONS=()

# Check 1: Hardcoded secrets patterns
if grep -qiE "(password|passwd|pwd|secret|api[_-]?key|token|auth)['\"]?\s*[=:]\s*['\"][^'\"]{8,}" "$TEMP_FILE" 2>/dev/null; then
    # Allow if marked as safe
    if ! grep -q "# pragma: allowlist secret" "$TEMP_FILE"; then
        VIOLATIONS+=("⚠️  Potential hardcoded secret detected")
    fi
fi

# Check 2: AWS/Cloud credentials
if grep -qE "(AKIA|aws_access_key_id|aws_secret_access_key)" "$TEMP_FILE" 2>/dev/null; then
    VIOLATIONS+=("🔒 AWS credentials detected")
fi

# Check 3: Private keys
if grep -q "BEGIN.*PRIVATE KEY" "$TEMP_FILE" 2>/dev/null; then
    VIOLATIONS+=("🔑 Private key detected")
fi

# Check 4: Database connection strings with passwords
if grep -qiE "(mysql|postgres|mongodb)://[^:]+:[^@]+@" "$TEMP_FILE" 2>/dev/null; then
    VIOLATIONS+=("🗄️  Database connection string with password")
fi

# Check 5: JWT tokens
if grep -qE "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\." "$TEMP_FILE" 2>/dev/null; then
    VIOLATIONS+=("🎫 JWT token detected")
fi

# Check 6: Generic base64-encoded secrets (common pattern)
if grep -qE "secret.*=.*['\"][A-Za-z0-9+/]{40,}={0,2}['\"]" "$TEMP_FILE" 2>/dev/null; then
    VIOLATIONS+=("🔐 Base64-encoded secret pattern detected")
fi

# Clean up temp file if created
if [ -n "$CONTENT" ]; then
    rm -f "$TEMP_FILE"
fi

# Report violations
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "❌ Security Validation Failed for: $FILE_PATH"
    echo ""
    echo "The following security issues were detected:"
    for violation in "${VIOLATIONS[@]}"; do
        echo "  $violation"
    done
    echo ""
    echo "Recommendations:"
    echo "  1. Use environment variables: os.getenv('SECRET_KEY')"
    echo "  2. Use configuration files outside version control"
    echo "  3. Use secrets management: AWS Secrets Manager, HashiCorp Vault"
    echo "  4. Add '# pragma: allowlist secret' if this is a false positive"
    echo ""
    echo "To proceed anyway, remove this hook temporarily or fix the issues."

    # Block the operation
    exit 1
fi

# All checks passed
exit 0
