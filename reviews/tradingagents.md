# TradingAgents (TauricResearch/TradingAgents)

**Repo:** https://github.com/TauricResearch/TradingAgents
**License:** Apache-2.0; preserve license, notices and modification attribution. Data and model-service rights are separate.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** 9fa1196fffbcfd9de5146d2dd2869df84ab99838; main snapshot, whole repository with emphasis on graph, dataflows, decision schemas, memory/settlement, backtest, CLI, packaging and tests. Latest source commit: 2026-11-04.
**Verification:** Static source review; no source execution, dependency installation, model calls, brokerage access or trades. Upstream CI status checked separately, not independently reproduced.
**Stack:** Python 3.11+, LangGraph, LangChain provider adapters, Pydantic, pandas/stockstats, yfinance, Typer/Rich, optional SQLite checkpoints.
**What it is:** An inspectable multi-agent financial research pipeline producing recommendations, reports and retrospective decision scores—not a ready-to-use live trading system.

---

## Verdict

📚 **Study the orchestration and point-in-time defenses; do not treat this as validated investment automation.** The current code is considerably more careful than a thin “agents debate stocks” demo: explicit tool-date clamps, as-filed SEC statements, bounded analyst loops and a substantial regression suite deserve attention. But its built-in backtest evaluates independent recommendations, not executable portfolio returns; the paper's attractive simulated results do not establish reliable investment performance for this revision.

## What It Is

Four analyst roles cover market technicals, fundamentals, news/macro and social sentiment. They work in parallel with isolated tool/message histories. Bull/bear researchers debate their reports; a research manager synthesizes a plan; a trader proposes an action; aggressive/conservative/neutral risk debaters feed a portfolio manager's final five-tier rating. Fast and deep model tiers can use different providers. Memory settlement runs alongside analysts, and the portfolio manager receives date-eligible lessons. [Graph wiring](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/graph/setup.py), [runtime](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/graph/trading_graph.py).

The output boundary matters. The graph ends at the portfolio manager and returns state plus a rating. Schemas contain prose, optional entry/stop/target prices and sizing guidance, not validated executable orders. A supplied portfolio is broker-neutral JSON context, not a connected account or a continuously updated ledger. Although the README says approved proposals reach a simulated exchange, the inspected runtime/backtest does not implement that exchange. No live brokerage order path was found in the reviewed package. [Schemas](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/agents/schemas.py), [portfolio context](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/portfolio.py), [backtest](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/backtest.py), [README claim](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/README.md).

## Stack

| Layer | Implementation |
|---|---|
| Orchestration | LangGraph subgraphs, typed state, bounded tool rounds and debate routing |
| Models | OpenAI, Anthropic, Google, Azure, optional Bedrock; OpenAI-compatible routes including OpenRouter and Ollama; subscription auth option |
| Market/fundamental data | Yahoo/yfinance and Alpha Vantage; SEC EDGAR for as-filed US statements |
| Other inputs | FRED macro vintages, Polymarket public odds, Reddit and StockTwits; optional TypeSafe Jev social screening |
| Persistence | Markdown decision/reflection log, JSON state/report output, data cache, optional SQLite checkpoints |
| Interface | Python package and Typer/Rich CLI; Markdown and standalone HTML reports; Docker recipes |

[Configuration](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/default_config.py), [provider factory](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/llm_clients/factory.py), [data router](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/dataflows/router.py), [package manifest](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/pyproject.toml).

## Key Features

### 1. Explicit orchestration beats an opaque agent loop

Analysts have isolated histories and report-only outputs, then synchronize before debate. The default maximum is 20 tool rounds per analyst, one research round and one risk round; exceeding the analyst limit forces a report. Structured decision schemas improve interoperability, but do not prove price validity, suitability or calibrated confidence. Multiple roles commonly share the same underlying model and evidence: consensus is correlated inference, not independent confirmation. [Graph](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/graph/setup.py), [schemas](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/agents/schemas.py).

### 2. Point-in-time controls are real—and still incomplete evidence

The tool layer clamps model-requested dates to the analysis date and canonicalizes them. News/social timestamp filters reject future observations; historical coverage gaps are explicitly unavailable, not silently “no news.” Current-only company profiles, undated statements and undisclosed insider trades are withheld on historical runs; Polymarket live odds are withheld too. SEC facts are filtered by filing date and FRED requests pin realtime vintages. Memory excludes lessons whose outcomes were not known by the analysis date. These are valuable code-level defenses, not proof of a leak-free historical dataset. [Date rules](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/dataflows/date_window.py), [tools](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/agents/tools.py), [SEC](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/dataflows/vendors/sec_edgar.py), [FRED](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/dataflows/vendors/fred.py), [memory](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/memory/log.py).

Residual concerns include unavailable historical text archives, provider revisions/deletions, retrospective instrument universes and mappings, and an LLM's pretrained knowledge of events after the backtest date. Date-filtering tools cannot remove knowledge already inside model weights. Withholding unavailable fundamentals is safer than leaking them, but makes old runs unlike today's full-data run, especially outside SEC-covered US filers.

### 3. “Backtest” means decision scoring, not portfolio simulation

The current harness evaluates ticker/date cells and keeps its own memory log. It measures return from the first final close after the analysis date across a configurable holding window (default five trading days), subtracts a regional benchmark's return and groups outcomes by rating. Buy/Overweight and Sell/Underweight receive directional hit rates; Hold claims no direction. Summary alpha is parsed from percentage strings rounded to 0.1 percentage point. “Alpha” here is simple return difference, not factor-adjusted statistical alpha. [Harness](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/backtest.py), [settlement](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/memory/settlement.py).

There are no actual quantities, fills, cash accounting, compounded equity curve, transaction fees, spread/slippage, market impact, borrow availability/cost, financing or taxes in this evaluator. A Sell hit is not evidence of a profitable executable short. The same supplied portfolio context is reused across cells rather than carried forward. Overlapping holding windows are correlated; per-cell means are not independent observations or portfolio CAGR/Sharpe. Benchmark fallback can be SPY even for an instrument needing a different comparison, so audit the configured benchmark and calendar/currency conventions.

A reproducibility trap is visible in the harness: resumption skips cells by ticker/date in the run's log, not a full configuration identity. Do not reuse a run ID after changing model, prompts, analyst set or holding period. Failures and pending observations must be reported alongside successful scores to avoid selection bias. [Harness](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/backtest.py), [tests](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tests/test_backtest.py).

## Trading Performance Evidence

The linked [TradingAgents paper, arXiv:2412.20138v2](https://arxiv.org/html/2412.20138v2) describes a January 1–March 29, 2024 simulation and comparisons with buy-and-hold, MACD, KDJ/RSI, zero-mean reversion and SMA. Its results prose reports at least 23.21% cumulative return on three sampled stocks, over 26% for AAPL, and Sharpe ratios at least 5.60 across AAPL, GOOGL and AMZN. These are **authors' historical simulation claims**, not independently reproduced returns, audited live results or results measured here. The paper says live deployment is future work.

The inspected experiment/results text asserts daily information availability but does not substantiate a complete timestamped input archive, model-training cutoff audit, survivorship-free universe selection, realistic cost/slippage/shorting assumptions, repeated-seed uncertainty, or a locked prospective/walk-forward out-of-sample evaluation. A short interval and a handful of prominent surviving stocks are insufficient evidence of generalization across regimes. The baseline set is useful but does not isolate whether expensive multi-agent debate beats a matched single-model/no-debate system on identical information and budget. Paper tables/figures were not numerically reconstructed; the readable experiment/results sections were inspected, and no performance statistic was verified by rerunning them.

The 2026 repository has different data adapters, models and evaluation semantics from that paper. It explicitly warns published figures need not reproduce. Do not transfer a paper Sharpe ratio onto this SHA. To substantiate investment reliability, require frozen point-in-time data and model/version manifests, survivorship-aware universes including delistings, realistic executions and all costs, matched baselines and ablations, repeated trials with uncertainty, leakage audits, and genuinely unseen forward evaluation. Agent agreement and coherent explanations are not substitutes.

## Reproducibility and API Expenses

The manifest uses lower-bound dependencies, with no lockfile found in the snapshot; Docker bases and the optional Ollama image are not digest-pinned. Saved run settings include provider/model names, analysts and vendor routing, but the inspected allowlist omits some influential settings such as temperature and holding period. Live text feeds are not archived by the backtest, and the harness samples each cell once. Low temperature is not a determinism guarantee. [Manifest](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/pyproject.toml), [saved settings](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/graph/trading_graph.py), [README reproducibility](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/README.md).

Budget for analyst model/tool iterations, both debates and managers, structured-output retries, reflection calls on settled decisions, and optional per-post Jev requests—not just one “stock analysis” completion. Grid work grows with tickers × dates × calls per cell; parallelism reduces latency, not token bills. Configuration offers retry, token and round controls, but no demonstrated end-to-end dollar ceiling. No dollar estimate is asserted without measured token counts and current provider pricing. Free/keyless market access can be rate-limited or unavailable; subscription limits and optional data/model charges still apply. Local Ollama removes a hosted-model dependency, not hardware cost or all outbound data calls.

## Security, Privacy and Data Terms

- **Outbound data:** Prompts, source text and generated analysis reach the configured model providers; tier overrides may mean two recipients. Portfolio context, if supplied, includes holdings/cash and other positions for decision agents. Optional Jev screening sends social posts to another service. Use synthetic portfolios for evaluation and review provider retention/region terms before sharing anything sensitive. [Portfolio renderer](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/portfolio.py), [Jev](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/agents/post_screen.py).
- **Credentials:** API keys use environment configuration. Query-key HTTP error scrubbing and a report-settings allowlist reduce accidental disclosure. ChatGPT OAuth persists tokens in an owner-readable file (0600 on creation); that is not encryption or a universal secret-management guarantee. Custom endpoints are trusted configuration and can receive keys/prompts. This was a static check, not a credential audit. [HTTP helper](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/dataflows/net.py), [auth](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/llm_clients/chatgpt_auth.py).
- **Untrusted content:** News and social posts are adversarial model inputs. Jev relevance/stance filtering is not a prompt-injection security boundary and fails back to unscreened content on errors. Schemas constrain output shape, not truth. Do not connect generated ratings directly to a broker; an independent deterministic execution/risk layer and human approval would be separate engineering work.
- **Local persistence:** Reports, logs, caches and optional checkpoints retain source material and generated context. Treat outputs as potentially sensitive, restrict filesystem access, and establish retention. Report HTML disables raw HTML and images in Markdown and escapes fields—a positive hardening detail, not a full security certification. [Renderer](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tradingagents/report_html.py).
- **Deployment boundary:** This is principally a local CLI/library, not a hardened authenticated multi-user service; web auth/CORS cannot be inferred. Docker uses a non-root app user and excludes environment files, but it does not make untrusted provider content safe. No deployment was performed.
- **Rights:** Apache-2.0 covers repository code, with notice/modification and patent conditions; it does not license Yahoo/Alpha Vantage/social content or grant redistribution rights to cached data. Check each vendor's access, storage, commercial-use and redistribution terms and model/subscription terms. Public accessibility and a free API tier are not blanket commercial licenses. [License](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/LICENSE).

## Tests, CI and Maturity

There are **88 test_*.py files**, including backtest, graph end-to-end, date boundaries, filing knowledge time, historical social/news, memory point-in-time, provider routing, secret scrubbing, reporting, checkpoint and path-safety tests. Inspected backtest tests use a fake graph: useful regression coverage of bookkeeping, not evidence of market profitability or live-provider compatibility.

CI declares Python 3.11–3.14 plus an America/New_York run, a clean-install import smoke test and Ruff lint. GitHub reported [CI run 41812805325](https://github.com/TauricResearch/TradingAgents/actions/runs/41812805325) successful for the exact reviewed SHA. We did **not** run that suite locally or audit every job log; integration tests are excluded by default in pytest configuration. [Workflow](https://github.com/TauricResearch/TradingAgents/blob/9fa1196fffbcfd9de5146d2dd2869df84ab99838/.github/workflows/ci.yml), [tests](https://github.com/TauricResearch/TradingAgents/tree/9fa1196fffbcfd9de5146d2dd2869df84ab99838/tests).

Public metadata retrieved 2026-11-07: 121,152 stars, 23,168 forks, last push 2026-11-04, and 127 open issues/PRs combined. Latest release was [v0.7.1, published 2026-10-27](https://github.com/TauricResearch/TradingAgents/releases/tag/v0.7.1), with fixes to filing-date normalization, final-close settlement and Docker environment-file exclusion. That is evidence of active maintenance and recently repaired correctness boundaries, not proof that remaining bugs are absent. Popularity is not a safety or returns metric. Trading-R1 advertising in the README concerns a separate product, outside this review.

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| TradingAgents | Inspectable LLM financial research and debate experiments | Narrative richness and provider flexibility; not executable portfolio accounting |
| [Microsoft Qlib](https://github.com/microsoft/qlib) | Quantitative ML research, data/model evaluation and backtest workflows | More conventional quantitative experimentation; still requires careful datasets and leakage control |
| [QuantConnect LEAN](https://github.com/QuantConnect/Lean) | Event-driven backtesting and brokerage/execution engineering | Execution/portfolio infrastructure, not this multi-agent research experience; infrastructure and data obligations remain |
| Single-model research with the same frozen inputs | Cheap control experiment for whether debate adds value | Less role specialization; necessary baseline before paying for many agents |

Alternatives were checked at their public project pages, not installed or benchmarked. None implies reliable future returns.

## Self-Hosting Notes

Start with read-only synthetic research, pinned dependencies/models and a measured per-run budget. Disable unnecessary providers, avoid account/portfolio material, and retain immutable input/output manifests if evaluating historical claims. Configure explicit vendor chains rather than relying on arbitrary fallback; preserve missing-data notices. Do not expose local model endpoints publicly. The supplied Docker/CLI routes are useful packaging, not a production trading deployment recipe.

## Verification and Limits

Reviewed source and public metadata, implementation paths and selected tests cited above; read the paper's experiment/results text. No application tests or financial backtests were executed, no paper results reproduced, no live provider integration validated, no accounts accessed, and no paid services used. Findings are scoped to this exact revision and inspected paths; this is not a financial recommendation, penetration test or exhaustive dependency/license audit.

---

**Attribution:** TauricResearch/TradingAgents contributors, Apache-2.0. Paper by Yijia Xiao, Edward Sun, Di Luo and Wei Wang; arXiv:2412.20138v2. This review is independent analysis, not an endorsement of trading claims.
