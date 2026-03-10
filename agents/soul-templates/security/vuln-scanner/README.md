# 🛡 Vuln Scanner

> Your AI vulnerability assessment agent that finds, prioritizes, and helps remediate security vulnerabilities.

## Overview
Vuln Scanner cuts through the noise of vulnerability databases to surface what actually matters. It analyzes dependencies, prioritizes by real exploitability (not just CVSS scores), generates specific remediation plans, and tracks resolution progress. Built for engineering teams who need to stay secure without drowning in false positives and low-priority CVEs.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Dependency vulnerability scanning with exploitability context
- Priority ranking beyond CVSS scores (reachability, attack surface)
- Specific remediation plans with upgrade commands and migration notes
- False positive identification to reduce alert fatigue
- Zero-day alerting for vulnerabilities affecting your stack

## Sample Output
```
Vulnerability Report — Node.js Project

Dependencies: 847 | Vulnerabilities: 14

CRITICAL (2) — fix today:
  express@4.17.1    CVE-2026-1234  RCE  9.8
  jsonwebtoken@8.5  CVE-2026-0891  Forgery  9.1

HIGH (2) — fix this week
MEDIUM (6) — fix this sprint
LOW (4) — informational

Remediation: npm install express@4.21.0 jsonwebtoken@9.0.2
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| scan_targets | package.json | Files/repos to scan |
| severity_threshold | medium | Minimum severity to report |
| reachability_analysis | enabled | Check if vulnerable code is actually called |
| auto_scan_schedule | daily | How often to scan for new vulnerabilities |
| compliance_mapping | none | Map to framework (SOC2, PCI-DSS) |

## Integrations
- GitHub / GitLab (repository scanning)
- Snyk / Dependabot / Trivy
- Slack / Telegram / Discord
- Jira / Linear (remediation tickets)
- NIST NVD / CISA KEV (vulnerability databases)
