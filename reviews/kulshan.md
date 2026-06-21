# Kulshan (azz-kikkr/kulshan)

**Repo:** https://github.com/azz-kikkr/kulshan
**License:** Apache-2.0 in `kulshan/LICENSE.txt`; GitHub does not currently detect a root license
**Reviewed:** 2026-06-20
**Stack:** Python 3.9+, boto3, Click/rich-click, Rich, Jinja2, pandas, NumPy, NetworkX, plotext, prompt_toolkit, PyJWT, pytest, Hypothesis, Ruff, GitHub Actions
**What it is:** A local-first, read-only AWS audit CLI that produces FinOps and operational baseline reports from AWS APIs without uploading customer data to a SaaS service.

---

## Verdict

✅ **Deploy candidate, with beta caveats.** Kulshan is useful today as a controlled local AWS baseline tool, especially for cost, tag, waste, and read-only posture scans. The project is young and low-adoption, but the implementation is more substantial than the repo metadata suggests: 704 tests pass locally, the IAM policy is explicit, exports are redacted by default, and the CLI is designed around read-only AWS access.

The main caveats are maturity and coverage. Many scanner modules have thin direct test coverage even though the overall suite is broad, the changelog lags the package version, and Cost Explorer calls have real AWS API cost.

---

## What It Is

Kulshan runs local AWS account audits and generates reports for FinOps, security, resilience, lifecycle, drift, tagging, observability, quota, topology, and waste review.

The default command is intentionally narrow:

```sh
kulshan report
```

That runs the cost pack, uses the local AWS credential chain, asks for confirmation before billable Cost Explorer calls, and writes local output. Additional packs are opt-in through `--packs`.

Output formats include:

- terminal dashboard
- self-contained HTML
- JSON
- SARIF
- CSV

The project positions itself as a "baseline before deeper FinOps work" rather than a remediation engine. That matters: it does not require write access to AWS.

## Maturity

GitHub metadata at review time:

- Stars: 1
- Forks: 0
- Open issues: 0
- Latest reviewed commit: `cabcaf63c57a9602486eb9e187b1e1cc75f5fe8c`
- Package version from CLI: 0.1.4
- Security policy: present inside `kulshan/SECURITY.md`
- PyPI package: advertised in README

This is an early project, but it is not just a README. It has docs, CI, tests, sample reports, an explicit IAM policy, per-check IAM policy fragments, agent integration docs, and export redaction.

## Architecture

Kulshan ships as one Python package and one CLI. The root repo is mostly documentation and samples; the actual package lives under `kulshan/`.

Core layout:

| Area | Role |
|------|------|
| `src/kulshan/cli.py` | Click CLI, report generation, output dispatch |
| `src/kulshan/orchestrator.py` | Selects packs, runs them, validates findings, computes weighted score |
| `src/kulshan/checks/` | Ten audit packs: cost, security, sweep, dr, age, drift, tag, pulse, limit, topo |
| `src/kulshan/report/` | Terminal, HTML, JSON/SARIF/CSV rendering |
| `src/kulshan/redact.py` | Account, ARN, email, IP, bucket, hostname, and key redaction |
| `src/kulshan/history/` | Local scan history support |
| `kulshan/iam/` | Composed read-only IAM policy plus per-check policies |
| `agent-pack/`, `kulshan/agents/` | Agent-facing instructions and MCP config examples |

Each check pack exposes a common `run_scan(session, regions, *, quick=False, **kwargs) -> dict` contract. The orchestrator imports packs dynamically, enforces a timeout per pack, adapts legacy finding shapes, validates canonical finding schema, and aggregates pack scores with fixed weights.

## Standout Features

### Read-Only IAM Model

The published IAM policy contains 147 audit actions, mostly `Get*`, `List*`, and `Describe*`, across roughly 30 AWS services. The notable exception is `cloudformation:DetectStackDrift`, which starts an assessment but does not mutate stack resources.

The policy is explicit, versioned, and split into per-check policy fragments. That is the right shape for a security-sensitive audit tool.

### Local Reports, No SaaS Upload

Kulshan uses local AWS credentials and writes reports to local files. There is no active telemetry implementation, no cloud ingestion requirement, and no CUR upload path.

Exports redact PII by default for file-based formats. The redaction code handles account IDs, ARNs, email addresses, IPs, bucket names, hostnames, AWS access key IDs, and likely AWS secret key strings.

### Pack-Based Audit Surface

The ten-pack model gives users a clean escalation path:

- default: `cost`
- FinOps add-ons: `tag`, `sweep`
- broader diagnostics: `security`, `dr`, `age`, `drift`, `pulse`, `limit`, `topo`
- all packs: `--packs all`

That is better than forcing a noisy all-account audit as the first run.

### Agent-Friendly Output

JSON and SARIF outputs make the tool usable in CI and by coding agents. The repo also includes agent instruction packs for Claude Code, Codex, Kiro, Cursor, and similar shell-capable agents.

## Verification

Local checks on 2026-06-20:

```sh
python3 -m venv /tmp/kulshan-venv
/tmp/kulshan-venv/bin/python -m pip install -e ".[dev]"
/tmp/kulshan-venv/bin/python -m pytest
/tmp/kulshan-venv/bin/python -m ruff check --select E9,F63,F7,F82 src tests
/tmp/kulshan-venv/bin/python -m pip_audit
/tmp/kulshan-venv/bin/kulshan --version
```

Results:

- `pytest` passed: 704 tests.
- Ruff fatal-error check passed.
- `pip-audit` found no known vulnerabilities.
- Installed CLI reported version 0.1.4.

Notes:

- Running `python -m pip install ...` failed because the host Python is externally managed; using a venv worked.
- Test coverage total was 33%. Core models, adapter, orchestrator, redaction, and many cost/security paths are covered, but many pack scanner modules show little or no direct coverage.
- The test suite emitted deprecation warnings for Python 3.14-era datetime/pytest behavior.

## Security Notes

The security design is sane:

- no AWS write/remediation permissions by design
- uses AWS credential chain rather than storing credentials
- reports stay local
- file exports redact by default unless `--show-pii` is explicit
- published IAM policy is auditable
- private vulnerability reporting path is documented

The risk to watch is output handling. Even redacted reports can contain sensitive architecture, service, cost, and exposure information. Treat generated reports as confidential unless explicitly sanitized.

## Limitations

- Early project with 1 star and no release object on GitHub.
- GitHub does not detect the license because the Apache license is nested under `kulshan/`.
- Changelog stops at 0.1.3 while the package version is 0.1.4.
- Cost Explorer calls are billable, usually around $0.15-$0.25 for default cost reports according to the README.
- Full `--packs all` scans touch many AWS APIs and may need careful region/permission scoping.
- Total test coverage is modest because many scanner modules are not directly covered.
- No live AWS run was performed during this review.

## Comparison

| Aspect | Kulshan | AWS Cost Explorer | Security Hub/Config | SaaS FinOps tools |
|--------|---------|-------------------|---------------------|-------------------|
| Runs locally | Yes | No | No | No |
| Uploads data | No | AWS-native | AWS-native | Usually yes |
| Requires write access | No | No | Varies | Varies |
| Output | Terminal, HTML, JSON, SARIF, CSV | Console/API | Console/API | Dashboards |
| Best fit | Baseline, CI, agent-readable audit | Cost analysis | Continuous compliance | Ongoing managed FinOps |

## Who Should Use It

Good fit:

- AWS teams that want a quick local FinOps baseline.
- Consultants doing an initial account review.
- CI or agent workflows that need machine-readable AWS posture output.
- Teams that cannot upload billing/security data to a third-party SaaS.
- Engineers who want an auditable read-only IAM policy for account inspection.

Poor fit:

- Continuous monitoring as a managed service.
- Automated remediation.
- Environments that cannot tolerate Cost Explorer API charges.
- Teams that need mature vendor support.

---

**Attribution:** azz-kikkr/kulshan, Apache-2.0
