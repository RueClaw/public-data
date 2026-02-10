# skill-audit CLI

> **Source:** [markpors/skill-audit](https://github.com/markpors/skill-audit)
> **License:** No explicit license (educational use only)
> **Description:** Security auditing CLI for AI agent skills. Scans for prompt injection, secrets, and dangerous code patterns.

## Overview

skill-audit is a CLI tool that audits AI agent skills before trusting them. It detects prompt injection, hardcoded secrets, dangerous shell scripts, and code security issues.

## Features

- 🔍 **Prompt Injection Detection** — Scans skill descriptions for jailbreak patterns
- 🔑 **Secret Scanning** — Finds hardcoded API keys, tokens, credentials (via trufflehog/gitleaks)
- 🐚 **Shell Script Analysis** — Checks bash scripts for dangerous patterns (via shellcheck)
- 🐍 **Code Security** — Analyzes Python/JS for security issues (via semgrep)
- 📄 **SARIF Output** — CI/CD ready format for GitHub Actions
- 🔌 **Extensible** — Plugin architecture for custom scanners

## Installation

```bash
# Clone and install
git clone https://github.com/markpors/skill-audit
cd skill-audit
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Install security tools
brew install shellcheck semgrep trufflehog

# Verify
skill-audit check-tools
```

## Usage

### Basic Scan

```bash
skill-audit scan /path/to/skill
```

### Output Formats

```bash
skill-audit scan /path/to/skill --format json
skill-audit scan /path/to/skill --format sarif  # For CI/CD
skill-audit scan /path/to/skill --format text   # Default
```

### Strict Mode

```bash
skill-audit scan /path/to/skill --strict  # Fail on any issue
```

### Check Available Tools

```bash
skill-audit check-tools
```

## Exit Codes

| Code | Meaning | CI/CD Action |
|------|---------|--------------|
| 0 | PASS — No issues | Continue |
| 1 | WARN — Medium issues | Review |
| 2 | FAIL — High issues | Block |

## GitHub Actions Integration

```yaml
name: Security Audit
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install skill-audit
        run: |
          pip install git+https://github.com/markpors/skill-audit
          sudo apt-get install -y shellcheck
          pip install semgrep

      - name: Run audit
        run: skill-audit scan . --format sarif --output results.sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: results.sarif
```

## Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: skill-audit
        name: Skill Security Audit
        entry: skill-audit scan
        language: python
        pass_filenames: false
```

## What It Scans

### Prompt Injection Patterns

- "Ignore previous instructions"
- "Override security settings"
- "Act as administrator"
- "Enter unrestricted mode"
- System prompt manipulation

### Secrets

- API keys (`api_key=`, `apikey=`)
- AWS credentials (`AKIA...`)
- Private keys (`-----BEGIN`)
- Tokens and passwords
- Database connection strings

### Shell Scripts

- Dangerous commands (rm -rf, dd, eval)
- Unquoted variables
- Missing error handling
- Privilege escalation

### Code Security

- eval()/exec() with user input
- SQL injection patterns
- Command injection
- Path traversal
- Unsafe deserialization

## Scanner Architecture

```python
class Scanner:
    def scan(self, path: Path) -> ScanResult:
        """Run all checks on a skill directory."""
        
class PromptInjectionScanner(Scanner):
    """Detects prompt injection in SKILL.md and docs."""
    
class SecretScanner(Scanner):
    """Finds hardcoded secrets using trufflehog/gitleaks."""
    
class ShellScanner(Scanner):
    """Analyzes bash scripts with shellcheck."""
    
class CodeScanner(Scanner):
    """Static analysis with semgrep."""
```

## Key Design Principles

- **Defense in depth** — Multiple scanners catch different issues
- **External tools** — Leverage proven security tools
- **CI/CD first** — SARIF output for seamless integration
- **Exit codes** — Clear pass/warn/fail signals
- **Extensible** — Add custom scanners as plugins
