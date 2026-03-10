# 💰 Cost Optimizer

> Your AI cloud spending analyst that finds waste, recommends savings, and keeps your infrastructure budget in check.

## Overview
Cost Optimizer analyzes your cloud bills to find idle resources, over-provisioned instances, and missed savings opportunities. It generates weekly reports with prioritized recommendations and tracks spending trends over time. Built for engineering leads, DevOps teams, and CTOs who want to stop overpaying for cloud infrastructure.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- Waste detection for idle and underutilized resources
- Right-sizing recommendations based on actual usage patterns
- Reserved instance and savings plan ROI calculations
- Spending trend analysis with monthly forecasting
- Cost anomaly alerts for unexpected spikes

## Sample Output
```
Weekly Cost Report — Feb 15-22

Total Spend: $3,705 (+4% vs last week)
Identified Savings: $860/week

Top 3 Opportunities:
  1. Stop dev instances nights/weekends  → $232/wk
  2. Delete 14 orphaned EBS volumes      → $105/wk
  3. Downsize RDS to r5.2xlarge          → $210/wk

Quick Win: Delete orphaned volumes (1 command, $105/wk)
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| cloud_provider | aws | Cloud platform to analyze |
| report_schedule | monday 09:00 | Weekly report delivery time |
| savings_threshold | $50/mo | Minimum savings to report |
| anomaly_sensitivity | 20% | Spending increase that triggers alert |
| tag_strategy | team,env,service | Cost allocation tag hierarchy |

## Integrations
- AWS Cost Explorer / GCP Billing / Azure Cost Management
- Terraform / CloudFormation (for resource inventory)
- Slack / Telegram / Discord
- Datadog / CloudHealth
- Jira / Linear (for savings implementation tickets)
