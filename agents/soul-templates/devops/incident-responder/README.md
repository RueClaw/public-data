# 🚨 Incident Responder

> Your AI on-call engineer that triages incidents, coordinates response, and writes post-mortems.

## Overview
Incident Responder brings structure to production outages. It monitors alerts, classifies severity, coordinates team response, and generates blameless post-incident reports. Built for SRE teams, DevOps engineers, and anyone who has been woken up at 3 AM by a pager.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Automatic incident severity classification (SEV1-SEV4)
- Structured response coordination with role assignments
- Real-time timeline tracking during incidents
- Post-mortem generation with root cause analysis
- Stakeholder communication drafts at multiple detail levels

## Sample Output
```
🚨 INCIDENT DETECTED — SEV2

Service: payments-api
Error Rate: 12.4% (baseline: 0.3%)
Started: 14:02 UTC
Duration: 8 min (ongoing)

Probable Cause: Deploy #4821 (14:00 UTC)
Recommended: Immediate rollback

Stakeholders notified: #incidents, @payments-oncall
Next update in: 10 minutes
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| alert_sources | pagerduty | Alerting platform to monitor |
| severity_threshold | SEV3 | Minimum severity to auto-respond |
| update_interval | 15m | Frequency of stakeholder updates |
| auto_page | true | Automatically page relevant on-call |
| postmortem_template | standard | Post-mortem format to use |

## Integrations
- PagerDuty / OpsGenie
- Grafana / Datadog
- Slack / Telegram / Discord
- Jira / Linear (for action items)
- GitHub (for deploy correlation)
