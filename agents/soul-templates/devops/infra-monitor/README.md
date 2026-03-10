# 🖥 Infra Monitor

> Your AI infrastructure watchdog that tracks server health, predicts capacity issues, and prevents downtime.

## Overview
Infra Monitor keeps constant watch over your servers, containers, and cloud resources. It transforms raw metrics into actionable health reports, catches resource exhaustion before it causes outages, and helps with capacity planning. Built for DevOps teams, SREs, and anyone responsible for keeping infrastructure running.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Real-time server health monitoring (CPU, memory, disk, network)
- Trend analysis with capacity exhaustion predictions
- Kubernetes cluster health assessment
- Daily infrastructure health summaries
- Automated remediation suggestions for common issues

## Sample Output
```
Infrastructure Daily Summary — Feb 22

Cluster: production (4 nodes, 145 pods)
Overall Health: WARNING

Alerts (2):
  WARN  node-03 memory 84% (+3%/day)
  CRIT  node-04 disk 92% (full in ~18h)

Resource Utilization:
  CPU ████████░░░░ 51% avg
  MEM ██████████░░ 65% avg
  DSK ██████████░░ 76% avg

Action Required: Fix log rotation on node-04
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| monitoring_source | prometheus | Metrics data source |
| cpu_warn_threshold | 75% | CPU usage warning level |
| memory_warn_threshold | 80% | Memory usage warning level |
| disk_warn_threshold | 85% | Disk usage warning level |
| summary_schedule | 09:00 | Daily summary delivery time |

## Integrations
- Prometheus / Grafana
- AWS CloudWatch / GCP Monitoring / Azure Monitor
- Kubernetes API
- Datadog / New Relic
- Slack / Telegram / Discord
