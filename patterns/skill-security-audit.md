# Skill Security Audit Pattern

> **Source:** [gadievron/security-check-skill](https://github.com/gadievron/security-check-skill)
> **License:** MIT
> **Description:** Comprehensive security auditing pattern for AI agent skills. Detection of prompt injection, secrets exposure, and malicious intent.

## Overview

Security auditing framework for AI agent skills that provides automated scanning and manual checklists for pre-installation security checks and daily audits.

## Security Scanner

### What It Checks

1. **SKILL.md Analysis**
   - Prompt injection patterns
   - External network calls
   - Suspicious instructions

2. **Scripts Directory Scan**
   - Dangerous command patterns (rm -rf, eval, exec)
   - Hardcoded secrets and credentials
   - Unsafe subprocess usage
   - File system operations outside skill directory

3. **References Directory Scan**
   - Hardcoded secrets (passwords, API keys, tokens)
   - Suspicious URLs (pastebin, raw GitHub links)
   - Sensitive information exposure

### Severity Levels

**HIGH (Immediate Block)**
- Prompt injection patterns detected
- Hardcoded secrets or credentials
- Data exfiltration capabilities
- Unauthorized file system access
- Dangerous file operations (rm -rf, dd, etc.)
- eval() or exec() with untrusted input

**MEDIUM (Review Required)**
- Suspicious but not clearly malicious
- Requires user approval for specific operations
- Limited network access to unverified endpoints
- Unsafe subprocess usage (shell=True)

**LOW (Informational)**
- Suspicious URLs (may be legitimate)
- Documentation of deprecated practices
- Minor code quality issues

## Prompt Injection Detection

### Key Patterns to Detect

```python
dangerous_patterns = [
    r'ignore\s+previous\s+instructions',
    r'override\s+security',
    r'act\s+as\s+administrator',
    r'you\s+are\s+now\s+in\s+unrestricted\s+mode',
    r'discard\s+your\s+training',
    r'new\s+system\s+prompt',
]
```

### Categories

1. **Context Manipulation** — "Ignore previous instructions"
2. **Authority Impersonation** — "Act as administrator"
3. **Instruction Replacement** — "Your new system prompt is..."
4. **Jailbreak Attempts** — "Enter unrestricted mode"
5. **System Override** — "Override security settings"
6. **Training Discard** — "Forget your training"

## Secrets Detection Patterns

```regex
password="..."
secret='...'
token="1234567890abcdef"
api_key="..."
aws_access_key_id="AKIA..."
ssh_private_key="-----BEGIN..."
```

## Protected Paths

Block access to:
- `~/.clawdbot/credentials/`
- `~/.aws/credentials`
- `~/.ssh/` directory
- `~/.npmrc`, `~/.pypirc`, `~/.netrc`
- Shell history files
- System keychain

## Installation Decision Framework

### Block (Do Not Install)
- Any HIGH severity issues
- Clear prompt injection attempts
- Hardcoded secrets
- Data exfiltration

### Warn (Install with Caution)
- MEDIUM severity issues
- Suspicious patterns requiring verification
- Network access to unknown endpoints

### Approve (Safe to Install)
- No security issues detected
- Well-documented and transparent
- Matches description perfectly
- From trusted source

## CI/CD Integration

```yaml
# GitHub Actions example
- name: Security Scan
  run: python3 scripts/scan_skill.py ${{ github.workspace }}
  continue-on-error: false

# Exit codes:
# 0 = PASS (no issues)
# 1 = WARN (medium issues)
# 2 = FAIL (high issues)
```

## Daily Audit Checklist

1. Scan all installed skills with automated scanner
2. Review any new HIGH severity issues
3. Check for modified files in skill directories
4. Verify skill descriptions still match behavior
5. Audit new dependencies if added

## Key Design Principles

- **Scan before installing** — Never skip security checks
- **Severity-based action** — Different responses for different risks
- **Pattern matching** — Automated detection of known bad patterns
- **Command-behavior alignment** — Verify code matches description
- **Continuous monitoring** — Regular audits, not one-time checks
