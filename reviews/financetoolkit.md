# FinanceToolkit (JerBouma/FinanceToolkit)

**Repo:** https://github.com/JerBouma/FinanceToolkit  
**License:** MIT  
**Reviewed:** 2026-05-31  
**Commit reviewed:** `99e649ccd1f49614b6f4023f151bf2d783111943`  
**Stack:** Python 3.10-3.13, pandas, scikit-learn, requests, yfinance, openpyxl, pytest, uv  
**What it is:** A Python toolkit for transparent financial statements, ratios, valuation models, options, performance, risk, technical indicators, fixed income, economics, discovery, and portfolio analysis.

---

## Verdict

✅ **Deploy candidate for research notebooks and internal financial analysis, not for automated trading or unreviewed investment decisions.** FinanceToolkit is mature, well documented, MIT-licensed, broadly tested, and unusually explicit about formulas. The main caveats are external data dependency, API-key/rate-limit behavior, pickle-based local caches, and a local test run with two golden-output drift errors under the newest dependency set.

## What It Is

FinanceToolkit is a pandas-first financial analysis library. It tries to solve a real problem: financial websites often report the same metric with different definitions, while hiding the underlying calculation. FinanceToolkit exposes the calculations directly in Python modules, then lets users feed standardized statements and market data through a consistent set of ratios and models.

The top-level `Toolkit` object coordinates data from Financial Modeling Prep and Yahoo Finance, then exposes modules for:

- historical prices and returns;
- balance sheet, income statement, cash flow, profile, quotes, ratings, analyst estimates, ESG, calendars, and revenue segmentation;
- 50+ ratios across efficiency, liquidity, profitability, solvency, and valuation;
- DuPont, WACC, Altman Z-Score, Piotroski Score, enterprise value, growth, and intrinsic valuation models;
- Black-Scholes, binomial trees, and first/second/third-order option Greeks;
- performance and factor analysis;
- VaR, CVaR, EVaR, drawdowns, skew, kurtosis, EWMA, and GARCH-style risk functions;
- technical indicators;
- fixed-income and economics data;
- portfolio transaction analysis.

## Architecture

### Controller Plus Model Modules

The public API is organized around controllers such as `Toolkit`, `Ratios`, `Models`, `Options`, `Performance`, `Risk`, `Technicals`, `FixedIncome`, `Economics`, `Discovery`, and `Portfolio`. Each controller delegates formulas to smaller model modules. That split keeps the public API ergonomic while leaving formulas inspectable.

### Data Source Normalization

Financial statement fields are normalized through CSV mapping files under `financetoolkit/normalization/`. There are separate mappings for Financial Modeling Prep and Yahoo Finance. This is the right move for a tool that wants consistent ratios across providers.

### Provider Fallback

By default, the toolkit prefers Financial Modeling Prep when an API key is supplied, then falls back to Yahoo Finance when appropriate. Users can force either source with `enforce_source`. The code also models provider errors as sentinel dataframe columns such as `INVALID API KEY`, `LIMIT REACH`, and `YFINANCE RATE LIMIT REACHED`, then aggregates those into clearer log messages.

### Snapshot-Style Tests

The test suite uses a recorder fixture that stores expected CSV/JSON/TXT outputs and compares later runs against those records. That gives broad regression coverage for formula outputs, but it is sensitive to dependency and numerical-output drift.

## Security and Operational Notes

Good signs:

- no hardcoded real secrets found in a quick scan;
- API keys are caller-supplied, not persisted by default;
- network access is limited to data providers such as Financial Modeling Prep, Yahoo Finance, OECD/FRED-style sources, and documented endpoints;
- the portfolio parser works with user files but stays inside pandas/openpyxl/YAML-style configuration rather than shelling out.

Caveats:

- local cache loading uses `pandas.read_pickle` / `pickle.load`; only load cache files you created or trust;
- Financial Modeling Prep API keys are embedded into request URLs, so users should avoid logging full URLs;
- data source accuracy remains external to the library;
- snapshot tests can drift when pandas/scikit-learn/numpy behavior changes;
- this is a financial analysis library, not financial advice or an execution/risk-control system.

## Verification

Local verification on macOS:

- cloned `JerBouma/FinanceToolkit` at `99e649ccd1f49614b6f4023f151bf2d783111943`;
- `uv sync --frozen` succeeded with Python 3.11;
- `uv run python -m compileall -q financetoolkit tests` passed;
- `uv run pytest -q` reported `496 passed, 2 errors, 5 warnings`.

The two errors were teardown snapshot mismatches in `tests/performance/test_performance_controller.py` for `test_get_factor_correlations` and `test_get_fama_and_french_model`. The failures appear to be recorded-output drift rather than import/runtime crashes.

## Caveats

- GitHub API did not detect the license, but `pyproject.toml` and `LICENSE.txt` both declare MIT.
- CI is configured around Poetry while the repo also ships `uv.lock`; the current lockfile path worked locally.
- README and docs are extensive, but the README is extremely long.
- Financial Modeling Prep is central to full functionality and some docs use an affiliate link.
- Users doing serious investment work still need source validation, audit trails, and independent checks.

## Best Reusable Pattern

The strongest reusable pattern is formula-transparent financial analytics: keep provider ingestion, statement normalization, and formula implementations separate, expose calculations through controller modules, and regression-test outputs with committed snapshots.

Extracted as `public-data/patterns/formula-transparent-financial-analytics.md`.

## Bottom Line

FinanceToolkit is worth using when you want reproducible financial analysis in notebooks or internal research scripts. The package's value is not that it magically solves data quality; it makes formulas and assumptions visible enough to review.

---

**Attribution:** JerBouma/FinanceToolkit, MIT, https://github.com/JerBouma/FinanceToolkit
