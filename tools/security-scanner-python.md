# Security Scanner for AI Skills

> **Source:** [gadievron/security-check-skill](https://github.com/gadievron/security-check-skill)
> **License:** MIT
> **Description:** Python-based automated security scanner for AI agent skills. Detects prompt injection, secrets, and dangerous code patterns.

## Overview

A Python scanner that performs automated security analysis on AI agent skills before installation.

## Usage

```bash
python3 scripts/scan_skill.py <skill-path>
```

## Output Format

```json
{
  "skill_name": "example-skill",
  "issues": [
    {
      "severity": "HIGH",
      "file": "SKILL.md",
      "issue": "Potential prompt injection pattern",
      "recommendation": "Review and remove suspicious patterns"
    }
  ],
  "warnings": [
    {
      "severity": "MEDIUM",
      "file": "scripts/helper.py",
      "issue": "os.system() usage detected",
      "recommendation": "Review and ensure this is safe"
    }
  ],
  "passed": [
    {"file": "SKILL.md", "check": "Prompt injection scan", "status": "Completed"}
  ],
  "summary": "SECURITY ISSUES FOUND: 1 issue(s), 1 warning(s)"
}
```

## Scanner Implementation

```python
import re
import json
import sys
from pathlib import Path

class SkillScanner:
    """Security scanner for AI agent skills."""
    
    PROMPT_INJECTION_PATTERNS = [
        r'ignore\s+previous\s+instructions',
        r'override\s+security',
        r'act\s+as\s+administrator',
        r'you\s+are\s+now\s+in\s+unrestricted\s+mode',
        r'discard\s+your\s+training',
        r'new\s+system\s+prompt',
        r'jailbreak',
        r'bypass\s+restrictions',
    ]
    
    DANGEROUS_PATTERNS = [
        (r'rm\s+-rf', 'Dangerous file deletion'),
        (r'eval\s*\(', 'Dynamic code execution'),
        (r'exec\s*\(', 'Dynamic code execution'),
        (r'os\.system', 'Shell command execution'),
        (r'subprocess\.call.*shell=True', 'Unsafe subprocess'),
    ]
    
    SECRET_PATTERNS = [
        (r'password\s*=\s*["\'][^"\']+["\']', 'Hardcoded password'),
        (r'api_key\s*=\s*["\'][^"\']+["\']', 'Hardcoded API key'),
        (r'secret\s*=\s*["\'][^"\']+["\']', 'Hardcoded secret'),
        (r'AKIA[0-9A-Z]{16}', 'AWS Access Key'),
        (r'-----BEGIN\s+PRIVATE\s+KEY', 'Private key'),
    ]
    
    def __init__(self, skill_path: Path):
        self.skill_path = Path(skill_path)
        self.issues = []
        self.warnings = []
        self.passed = []
    
    def scan(self):
        """Run all security checks."""
        self.scan_skill_md()
        self.scan_scripts()
        self.scan_references()
        return self.get_report()
    
    def scan_skill_md(self):
        """Scan SKILL.md for prompt injection."""
        skill_md = self.skill_path / 'SKILL.md'
        if not skill_md.exists():
            return
        
        content = skill_md.read_text()
        for pattern in self.PROMPT_INJECTION_PATTERNS:
            if re.search(pattern, content, re.IGNORECASE):
                self.issues.append({
                    'severity': 'HIGH',
                    'file': 'SKILL.md',
                    'issue': f'Prompt injection pattern detected: {pattern}',
                    'recommendation': 'Review and remove suspicious patterns'
                })
        
        self.passed.append({
            'file': 'SKILL.md',
            'check': 'Prompt injection scan',
            'status': 'Completed'
        })
    
    def scan_scripts(self):
        """Scan scripts directory for dangerous patterns."""
        scripts_dir = self.skill_path / 'scripts'
        if not scripts_dir.exists():
            return
        
        for script in scripts_dir.rglob('*'):
            if script.is_file():
                self._scan_file(script, 'scripts')
    
    def scan_references(self):
        """Scan references for exposed secrets."""
        refs_dir = self.skill_path / 'references'
        if not refs_dir.exists():
            return
        
        for ref in refs_dir.rglob('*'):
            if ref.is_file():
                self._scan_for_secrets(ref)
    
    def _scan_file(self, file: Path, category: str):
        """Scan a file for dangerous patterns."""
        try:
            content = file.read_text()
        except Exception:
            return
        
        # Check dangerous patterns
        for pattern, description in self.DANGEROUS_PATTERNS:
            if re.search(pattern, content):
                self.warnings.append({
                    'severity': 'MEDIUM',
                    'file': str(file.relative_to(self.skill_path)),
                    'issue': description,
                    'recommendation': 'Review and ensure this is safe'
                })
        
        # Check secrets
        self._scan_for_secrets(file)
    
    def _scan_for_secrets(self, file: Path):
        """Scan a file for hardcoded secrets."""
        try:
            content = file.read_text()
        except Exception:
            return
        
        for pattern, description in self.SECRET_PATTERNS:
            if re.search(pattern, content):
                self.issues.append({
                    'severity': 'HIGH',
                    'file': str(file.relative_to(self.skill_path)),
                    'issue': description,
                    'recommendation': 'Remove hardcoded credentials'
                })
    
    def get_report(self):
        """Generate final report."""
        return {
            'skill_name': self.skill_path.name,
            'issues': self.issues,
            'warnings': self.warnings,
            'passed': self.passed,
            'summary': self._get_summary()
        }
    
    def _get_summary(self):
        """Generate summary string."""
        if self.issues:
            return f"SECURITY ISSUES FOUND: {len(self.issues)} issue(s), {len(self.warnings)} warning(s)"
        elif self.warnings:
            return f"WARNINGS: {len(self.warnings)} warning(s) - review recommended"
        else:
            return "PASSED: No security issues detected"


def main():
    if len(sys.argv) < 2:
        print("Usage: python scan_skill.py <skill-path>")
        sys.exit(1)
    
    scanner = SkillScanner(sys.argv[1])
    report = scanner.scan()
    print(json.dumps(report, indent=2))
    
    # Exit codes for CI/CD
    if report['issues']:
        sys.exit(2)  # FAIL
    elif report['warnings']:
        sys.exit(1)  # WARN
    else:
        sys.exit(0)  # PASS


if __name__ == '__main__':
    main()
```

## Detection Patterns

### Prompt Injection

| Pattern | Risk |
|---------|------|
| `ignore previous instructions` | Context manipulation |
| `override security` | Safety bypass |
| `act as administrator` | Authority impersonation |
| `unrestricted mode` | Jailbreak attempt |
| `new system prompt` | Instruction replacement |

### Dangerous Code

| Pattern | Risk |
|---------|------|
| `rm -rf` | File deletion |
| `eval()` / `exec()` | Code injection |
| `os.system()` | Shell execution |
| `shell=True` | Unsafe subprocess |

### Secrets

| Pattern | Type |
|---------|------|
| `password=` | Credentials |
| `api_key=` | API keys |
| `AKIA...` | AWS keys |
| `-----BEGIN PRIVATE KEY` | Cryptographic keys |

## Key Design Principles

- **Pattern-based detection** — Regex for known bad patterns
- **Severity classification** — HIGH blocks, MEDIUM warns
- **Exit codes** — CI/CD integration ready
- **JSON output** — Machine-readable results
- **Comprehensive scan** — Skills, scripts, and references
