# OpenBB / Open Data Platform (OpenBB-finance/OpenBB)

*Review #281 | Source: https://github.com/OpenBB-finance/OpenBB | License: AGPL-3.0 (core) + commercial exceptions | Author: OpenBB Finance | Reviewed: 2026-03-28 | Stars: 63,683*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

OpenBB is the largest open-source financial data infrastructure platform. 63K stars, 6.3K forks, 2.4GB of repo. It's not a trading app or a charting tool — it's a "connect once, consume everywhere" data abstraction layer that normalizes 40+ financial data providers behind a single Python API, REST server, CLI, MCP server, and Excel add-in.

The core value proposition: financial data is fragmented, inconsistently formatted, and expensive. OpenBB standardizes the schema across providers so `obb.equity.price.historical("AAPL")` returns the same DataFrame shape whether it's pulling from Yahoo Finance, Polygon, Tiingo, or FMP — and you can swap providers with one argument.

---

## Architecture

Five surfaces over one core:

```
                    OpenBB Platform Core
                    (Provider abstraction layer)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
  Python API          REST API           MCP Server
  (obb.equity...)   (FastAPI :6900)  (openbb-mcp-server)
        │                  │                  │
  CLI Tool          Excel Add-in      OpenBB Workspace
                                    (pro.openbb.co)
```

**Provider model:** Every data source is a provider plugin. Each extension (equity, fixed income, economy, etc.) defines a standard query model + response model. Providers implement those models. Same call, different provider argument:

```python
obb.equity.price.historical("AAPL", provider="yfinance")
obb.equity.price.historical("AAPL", provider="polygon")
obb.equity.price.historical("AAPL", provider="fmp")
```

**Extensions (data domains):**
- equity, etf, crypto, currency
- derivatives, options
- fixed_income
- economy, index
- news
- regulators (SEC filings, FINRA)
- technical (indicators)
- quantitative
- econometrics
- famafrench (Ken French factor data)
- uscongress (legislative trading data)
- commodity

**Providers (40+, selected):**
- **Free/no key:** Yahoo Finance, SEC EDGAR, FRED, OECD, IMF, ECB, Federal Reserve, Fama-French, BLS, EIA, FINRA, multpl, government_us
- **Free key:** FMP, Polygon, Tiingo, Alpha Vantage, Nasdaq, CBOE, Biztoc, Finviz, Seeking Alpha, stockgrid, TMX, tradier, WSJ
- **Paid:** Benzinga, Intrinio, TradingEconomics

---

## The MCP Server

`pip install openbb-mcp-server` — the standout feature for our use case.

The MCP server wraps the full OpenBB REST API and exposes it to LLM agents. Key design: **lazy tool activation**. Instead of exposing all 100+ tools at once (which would destroy the agent's context window), agents use discovery tools to find what's available by category, then activate only what they need. Tool visibility is per-session — multiple agents can connect simultaneously with different active toolsets.

Configuration via `~/.openbb_platform/mcp_settings.json`:
- `--allowed-categories` — whitelist which domains to expose
- `--default-categories` — which categories are active at startup
- `--no-tool-discovery` — disable discovery, just expose configured tools
- `--system-prompt` — inject a custom system prompt
- `--server-prompts` — JSON file of server-side prompts

This is the right architecture for a broad-domain MCP server. The "activate on demand" pattern prevents the tool list from becoming noise.

---

## What's Free vs. What Costs Money

**Fully free (no API key needed):**
- Yahoo Finance equity prices, fundamentals, news
- SEC EDGAR (all public filings, earnings, 13F, insider trades)
- FRED (Federal Reserve economic data — ~800K time series)
- OECD, IMF, ECB, Bank for International Settlements
- Federal Reserve, BLS, EIA
- Ken French factor data library (Fama-French factors)
- multpl (Shiller PE, yield curve, etc.)
- US Government data (data.gov)
- FINRA (market transparency data)

**Free key (rate-limited):**
- FMP (50 calls/day free tier — income statements, balance sheets, DCF)
- Polygon (free tier: delayed data, limited history)
- Tiingo (free tier: EOD prices, news)
- Alpha Vantage (25 calls/day free)
- Nasdaq Data Link (some datasets free)

**The market-brief skill already uses some of these manually** — OpenBB would replace those custom fetchers with normalized, provider-agnostic calls.

---

## Python API Quick Reference

```python
from openbb import obb

# Equity
obb.equity.price.historical("AAPL", start_date="2024-01-01")
obb.equity.fundamental.income(symbol="AAPL", period="annual")
obb.equity.fundamental.balance(symbol="AAPL")
obb.equity.fundamental.cash(symbol="AAPL")
obb.equity.price.quote(["AAPL", "MSFT", "GOOGL"])

# Macro / Economy
obb.economy.fred_series(symbol="GDP")          # US GDP
obb.economy.fred_series(symbol="UNRATE")       # Unemployment rate
obb.economy.fred_series(symbol="T10Y2Y")       # Yield curve spread
obb.economy.cpi(country="united_states")

# Crypto
obb.crypto.price.historical("BTC-USD", provider="yfinance")

# Fixed Income
obb.fixedincome.rate.sofr()
obb.fixedincome.rate.treasury(maturity=["3m","2y","10y","30y"])

# News
obb.news.world(limit=10)
obb.news.company(symbols="AAPL", limit=5)

# Options
obb.derivatives.options.chains("AAPL", provider="cboe")

# Congressional trading (free, public record)
obb.uscongress.trading_disclosures()

# Regulators / SEC
obb.regulators.sec.filings(symbol="AAPL", type_="10-K")
```

All return `OBBject` with `.to_dataframe()`, `.to_dict()`, `.to_polars()`, `.results` (raw typed models).

---

## Relevance

🔥🔥🔥🔥🔥 — The most comprehensive open-source financial data normalization layer available. The AGPL-3.0 core license means free for open-source use; commercial use of the platform requires a commercial license from OpenBB.

**Direct applications:**
- **market-brief skill**: OpenBB replaces the manual fetch scripts for equities, crypto, macro data. One normalized API, provider-agnostic, normalized schema.
- **MCP server**: `pip install openbb-mcp-server` → agent gets SEC filings, FRED macro data, equity fundamentals, congressional trading disclosures, options chains — all with one tool set.
- **Research**: Free access to FRED (800K series), SEC EDGAR (all public filings), Fama-French factors, congressional trading records, OECD/IMF/ECB data — significant for quantitative or macro research without paid data subscriptions.

**Caveats:**
- 2.4GB repo — not practically clonable for casual use, but the PyPI package is fine
- AGPL-3.0: free for open-source projects; commercial use needs a license
- OpenBB Workspace (the enterprise UI at pro.openbb.co) is commercial/SaaS; the open-source platform is the data layer only
- Yahoo Finance is rate-limited and terms-of-service gray area for commercial use; for production, use a proper provider (Polygon, FMP)

**Note:** Repo too large to clone locally (2.4GB). Reviewed from GitHub API + web fetch. Install via `pip install openbb` for local use.

AGPL-3.0 (core). Commercial license available. Don't clone — install.
