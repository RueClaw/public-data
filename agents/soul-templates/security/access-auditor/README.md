# 🔐 Access Auditor

> Your AI identity and access management analyst that reviews permissions, flags excessive access, and enforces least privilege.

## Overview
Access Auditor reviews who has access to what and whether they should. It identifies over-privileged accounts, stale credentials, privilege escalation paths, and generates compliance-ready audit reports. Built for security teams, DevOps engineers, and compliance officers who need to enforce least privilege across cloud platforms and SaaS tools.

## Quick Start

1. Copy the `SOUL.md` to your OpenClaw project
2. Configure your preferred channel (Telegram, Slack, Discord)
3. Run `openclaw start`

Or deploy instantly with [CrewClaw](https://crewclaw.com/create-agent) →

## Features
- User and service account permission auditing
- Stale account detection (inactive 90+ days)
- Privilege escalation path identification
- Least privilege policy generation for over-scoped accounts
- Quarterly access review reports for SOC 2 and ISO 27001

## Sample Output
```
IAM Access Audit — AWS Production

Accounts: 47 users, 12 roles, 8 service accounts

Findings:
  CRITICAL  6 over-privileged accounts (admin access)
  WARNING   3 stale accounts (90+ days inactive)
  WARNING   2 privilege escalation paths
  OK        36 accounts compliant

Top Priority: Remove 2 former employee accounts
Action Items: 8 total (2 immediate, 3 this week, 3 ongoing)
```

## Configuration
| Setting | Default | Description |
|---------|---------|-------------|
| platforms | aws | Cloud platforms to audit |
| stale_threshold | 90 days | Days of inactivity before flagging |
| admin_review | always | Always flag admin-level access |
| audit_schedule | quarterly | How often to run full audits |
| compliance_framework | soc2 | Framework for report formatting |

## Integrations
- AWS IAM / GCP IAM / Azure AD
- Okta / Auth0 (identity providers)
- Slack / Telegram / Discord
- Jira / Linear (remediation tracking)
- Vanta / Drata (compliance platforms)
