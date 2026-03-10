# 📝 Incident Logger

> Your AI security incident documentation specialist that records, tracks, and reports on security events.

## Overview
Incident Logger ensures every security event is properly documented from detection through resolution. It creates consistent incident records, tracks timelines and actions, assesses regulatory notification requirements, and generates post-incident reports. Built for security teams, compliance officers, and any organization that needs a reliable security incident paper trail.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Structured incident record creation with standard classification
- Real-time timeline tracking as incidents unfold
- Regulatory notification assessment (GDPR, HIPAA, state breach laws)
- Post-incident report generation for leadership and compliance
- Searchable incident history with trend analysis

## Sample Output
```
Security Incident — SEC-2026-0014

Status: Open — Contained
Severity: High
Classification: Unauthorized Access
Affected: staging-db-01 (PostgreSQL)

Timeline:
  03:00 UTC  Unauthorized login (service account)
  09:15 UTC  Detected via audit log review
  14:00 UTC  Credentials rotated (contained)

Open Items: 5 investigation tasks
GDPR Deadline: Feb 25 09:15 UTC (if personal data confirmed)
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| id_format | SEC-YYYY-NNNN | Incident identifier format |
| classification | NIST | Taxonomy for incident classification |
| severity_levels | critical,high,medium,low | Available severity ratings |
| regulatory_frameworks | gdpr | Frameworks for notification assessment |
| retention_period | 7 years | How long to keep incident records |

## Integrations
- Jira / Linear (incident tickets)
- Slack / Telegram / Discord
- PagerDuty / OpsGenie (alert integration)
- Confluence / Notion (report storage)
- Splunk / Elastic (log correlation)
