# 🔍 Log Analyzer

> Your AI log intelligence agent that finds patterns, surfaces anomalies, and explains what your logs are trying to tell you.

## Overview
Log Analyzer processes high-volume log data to extract meaningful patterns and surface issues that matter. It clusters errors, correlates events across services, and translates stack traces into plain English. Built for engineers who are tired of grep-ing through thousands of log lines to find the one that matters.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Automatic error clustering and deduplication
- Anomaly detection for new and spiking error patterns
- Cross-service event correlation for distributed systems
- Natural language explanations of stack traces and error codes
- Log query generation for popular platforms (Elasticsearch, Loki, Splunk)

## Sample Output
```
Log Summary — Last 60 min

Events: 284,320 | Errors: 5,971 (2.1%)
Status: ELEVATED (baseline 0.4%)

New Errors:
  ConnectionRefused redis:6379  (1,247x) ← investigate
  TimeoutError upstream 10s     (892x) ← cascading

Correlation: Redis outage → session timeout → API 504s
Suggestion: Check Redis cluster health
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| log_source | elasticsearch | Log aggregation platform |
| anomaly_sensitivity | medium | How aggressively to flag anomalies |
| summary_interval | 1h | How often to generate summaries |
| error_threshold | 1% | Error rate that triggers an alert |
| cluster_similarity | 0.85 | Threshold for grouping similar errors |

## Integrations
- Elasticsearch / Kibana
- Grafana Loki
- AWS CloudWatch Logs
- Splunk
- Datadog Logs
