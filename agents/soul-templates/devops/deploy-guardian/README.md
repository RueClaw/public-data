# 🛡 Deploy Guardian

> Your AI deployment watchdog that monitors CI/CD pipelines and keeps releases safe.

## Overview
Deploy Guardian watches every deployment across your infrastructure, reporting status in real time and catching failures before they cascade. It tracks DORA metrics, enforces deployment policies, and helps teams decide when to roll back. Perfect for engineering teams shipping multiple times a day.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Real-time pipeline monitoring with failure root cause extraction
- DORA metrics tracking (deploy frequency, lead time, MTTR, change failure rate)
- Canary analysis with automatic rollback recommendations
- Deployment freeze window enforcement
- Post-deploy health checks with baseline comparison

## Sample Output
```
Deploy #847 — web-app → production

Status: Deployed
Commit: a3f91bc (Add user preferences page)
Author: @sarah
Duration: 4m 32s

Post-Deploy Check (5 min):
  Error rate: 0.08% (baseline 0.10%) ✓
  P99 latency: 210ms (baseline 215ms) ✓
  CPU: 28% (baseline 30%) ✓

All clear. Next check in 15 minutes.
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| pipeline_source | github_actions | CI/CD platform to monitor |
| environments | staging,prod | Environments to watch |
| canary_threshold | 5% | Error rate increase that triggers alert |
| freeze_windows | none | Cron expressions for deploy freezes |
| health_check_interval | 5m | Post-deploy monitoring frequency |

## Integrations
- GitHub Actions / GitLab CI / CircleCI
- Datadog / Grafana / New Relic
- Slack / Telegram / Discord
- ArgoCD / Spinnaker
- PagerDuty (for escalations)
