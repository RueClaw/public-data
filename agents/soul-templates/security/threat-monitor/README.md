# 🔭 Threat Monitor

> Your AI threat intelligence analyst that monitors the threat landscape and alerts on what is relevant to your stack.

## Overview
Threat Monitor filters the constant stream of security advisories, CVEs, and threat reports to surface only what matters to your organization. It assesses relevance based on your technology stack and industry, generates threat briefings at the right detail level, and escalates zero-days immediately. Built for security teams, CTOs, and engineering leads who need to stay informed without reading every advisory themselves.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Stack-aware threat filtering (only alerts on what you actually run)
- Weekly threat briefings with relevance and impact assessment
- Zero-day escalation with immediate remediation guidance
- MITRE ATT&CK mapping for threat actor techniques
- Multi-level reporting (technical, executive, board)

## Sample Output
```
Weekly Threat Briefing — Feb 16-22

Relevant to Your Stack:
  CRITICAL  Express.js RCE (actively exploited) → patch now
  HIGH      PostgreSQL privilege escalation → patch in 2 weeks
  MEDIUM    Phishing campaign targeting SaaS → awareness

Not Relevant (awareness only): 2 items

Active exploits affecting you: 1
Patches needed: 1
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| tech_stack | auto_detect | Technologies to monitor for |
| industry | technology | Industry for sector-specific threats |
| briefing_schedule | weekly | Regular briefing frequency |
| zero_day_alert | immediate | When to escalate critical threats |
| detail_level | technical | Default report depth |

## Integrations
- NIST NVD / CISA KEV / MITRE CVE
- AlienVault OTX / VirusTotal
- Slack / Telegram / Discord
- PagerDuty (for critical escalations)
- Jira / Linear (for remediation tracking)
