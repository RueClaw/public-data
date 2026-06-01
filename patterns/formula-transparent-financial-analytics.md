# Formula-Transparent Financial Analytics

**Source:** JerBouma/FinanceToolkit  
**Repo:** https://github.com/JerBouma/FinanceToolkit  
**License:** MIT  
**Reviewed:** 2026-05-31

## Pattern

Build financial analysis tools so data ingestion, field normalization, and formulas are separate, inspectable layers. The user should be able to trace any ratio, risk measure, option Greek, or valuation output back to a plain formula implementation and normalized input fields.

## Shape

```text
provider data
  -> source-specific fetcher
  -> source-specific normalization map
  -> standardized statements / prices / factors
  -> controller API
  -> formula model modules
  -> dataframe outputs
  -> snapshot tests
```

## Why It Works

Financial metrics are easy to misread because providers use different definitions. A transparent analytics library should not just return "PE ratio"; it should make the calculation method obvious and reusable.

The useful implementation details are:

- keep each data provider in its own fetch module;
- normalize provider-specific statement labels into stable internal names;
- put formulas in small model modules rather than hiding them behind a large controller;
- expose batch controllers for notebooks and research workflows;
- support caller-supplied datasets so users can bypass external providers;
- encode provider/rate-limit failures as structured states, not random exceptions;
- regression-test representative outputs with committed CSV/JSON snapshots.

## Implementation Notes

- Prefer pandas dataframe outputs when the target user is doing exploratory analysis.
- Separate financial statements, market prices, risk-free rates, factors, and portfolio transactions.
- Keep rounding explicit and configurable.
- Include growth and trailing-period variants as first-class parameters.
- Use provider fallback carefully and let users force one source when consistency matters.
- Document which outputs are formulas and which are provider-supplied fields.

## Caveats

Snapshot tests for numeric finance outputs are useful but can drift across dependency versions. Pin test environments or compare with tolerances where exact string output is not part of the contract.

Do not treat transparent formulas as validated investment logic. Data quality, corporate actions, survivorship bias, time alignment, and provider terms still matter.

---

**Attribution:** Pattern extracted from JerBouma/FinanceToolkit, MIT.
