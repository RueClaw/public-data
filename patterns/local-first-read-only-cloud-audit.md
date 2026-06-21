# Local-First Read-Only Cloud Audit CLI

**Source:** https://github.com/azz-kikkr/kulshan
**License:** Apache-2.0
**Reviewed:** 2026-06-20

## Pattern

Run cloud posture and cost analysis from a local CLI using explicit read-only credentials, then write portable reports without uploading customer data to a SaaS service.

Kulshan applies this to AWS: it uses the AWS credential chain, runs selected audit packs, normalizes findings, scores the account, and emits terminal, HTML, JSON, SARIF, or CSV output.

## Why It Works

Cloud audit tools often fail trust review because they ask for broad permissions and upload sensitive account data. A local-first read-only design gives users a safer first step:

- credentials stay in the user's existing AWS chain
- IAM policy is auditable and version-controlled
- default scope can be small and predictable
- reports are local files
- machine-readable output supports CI and agents
- redaction can be applied before sharing

This is useful for initial baselines, consulting handoffs, executive reports, and agent-readable diagnostics.

## Core Components

- **Explicit read-only IAM policy:** one composed policy plus per-pack policy fragments.
- **Pack selection:** default to a narrow baseline, let users opt into broader diagnostics.
- **Common finding schema:** every pack emits or adapts to one canonical finding shape.
- **Completeness tracking:** distinguish complete, partial, skipped, and permission-limited packs.
- **Local report renderers:** terminal, HTML, JSON, SARIF, and CSV.
- **PII redaction:** redact account IDs, ARNs, emails, IPs, hostnames, bucket names, and keys in file exports.
- **Cost warning:** warn before billable APIs such as AWS Cost Explorer.
- **No remediation path:** audit first; mutation is out of scope.

## Implementation Notes

- Make the orchestrator pure coordination; keep cloud API calls inside packs.
- Give each pack the same entry point: `run_scan(session, regions, quick=False, **kwargs)`.
- Validate findings after pack execution and exclude malformed records.
- Treat missing permissions as partial results, not silent success.
- Use local atomic writes for reports so interrupted runs do not leave corrupt output.
- Keep file exports redacted by default and make full-PII output an explicit flag.
- Document API costs for every pack that can incur usage charges.

## Good Fit

- FinOps baseline reports.
- Read-only cloud security posture checks.
- CI/CD account health checks.
- Agent-readable infrastructure audits.
- Consulting discovery workflows where data cannot leave the customer's machine.

## Watch Outs

- Read-only reports can still expose sensitive architecture and cost data.
- API billing must be disclosed clearly.
- Broad all-region scans can be slow or noisy.
- Redaction should be tested like security-sensitive code.
- A local CLI is not a replacement for continuous monitoring.

## Minimal Checklist

1. Publish an auditable read-only IAM policy.
2. Split broad diagnostics into opt-in packs.
3. Normalize every finding into one schema.
4. Track partial/skipped scans explicitly.
5. Render local human and machine formats.
6. Redact file exports by default.
7. Warn before billable cloud APIs.
8. Keep remediation and mutation out of scope.

---

**Attribution:** azz-kikkr/kulshan, Apache-2.0
