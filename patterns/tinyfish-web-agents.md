# TinyFish Web Agents Cookbook

> **Source:** [tinyfish-ai/tinyfish-cookbook](https://github.com/tinyfish-ai/tinyfish-cookbook)
> **License:** MIT
> **Description:** Recipes for building web agents that turn websites into programmable surfaces. Real browser automation with stealth and structured outputs.

## Overview

TinyFish is a **web agents API** that treats real websites like programmable surfaces. Send a URL plus a natural language goal, get back clean JSON.

## Core Capabilities

- **Any website as an API** — Turn sites without APIs into programmable surfaces
- **Natural language → structured JSON** — Goals in, structured data out
- **Real browser automation** — Multi-step flows, forms, filters, dynamic JS
- **Built-in stealth** — Rotating proxies, stealth browser profiles
- **Production-grade logs** — Full observability for every run

## Recipe Examples

### Anime Watch Hub

Find sites to watch/read anime and manga for free:

```typescript
const result = await tinyfish.browse({
  goal: "Find streaming sources for Attack on Titan Season 4",
  output: {
    sources: [{
      site: "string",
      url: "string",
      quality: "string",
      hasAds: "boolean"
    }]
  }
});
```

### Sports Betting Odds Comparison

Compare odds across bookmakers:

```typescript
const result = await tinyfish.browse({
  urls: [
    "https://bookmaker1.com/nfl",
    "https://bookmaker2.com/nfl"
  ],
  goal: "Get current odds for next NFL game",
  output: {
    game: "string",
    homeTeam: "string",
    awayTeam: "string",
    odds: [{
      bookmaker: "string",
      homeWin: "number",
      awayWin: "number"
    }]
  }
});
```

### Competitor Price Intelligence

Monitor competitor pricing in real-time:

```typescript
const result = await tinyfish.browse({
  urls: competitorUrls,
  goal: "Extract current prices for product SKU-12345",
  output: {
    prices: [{
      competitor: "string",
      price: "number",
      inStock: "boolean",
      lastUpdated: "string"
    }]
  }
});
```

### Summer School Finder

Discover programs across universities:

```typescript
const result = await tinyfish.browse({
  goal: "Find summer computer science programs for high schoolers",
  sites: ["mit.edu", "stanford.edu", "berkeley.edu"],
  output: {
    programs: [{
      university: "string",
      name: "string",
      dates: "string",
      cost: "number",
      applicationDeadline: "string",
      url: "string"
    }]
  }
});
```

## API Usage

### Direct HTTP

```bash
curl -X POST https://api.tinyfish.ai/browse \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "goal": "Extract product listings",
    "output": {
      "products": [{"name": "string", "price": "number"}]
    }
  }'
```

### TypeScript SDK

```typescript
import { TinyFish } from '@tinyfish/sdk';

const tf = new TinyFish({ apiKey: process.env.TINYFISH_API_KEY });

const result = await tf.browse({
  url: "https://example.com/products",
  goal: "Get all products with prices under $50",
  output: {
    products: [{
      name: "string",
      price: "number",
      url: "string"
    }]
  }
});
```

### MCP Server

Use with Claude or Cursor:

```json
{
  "mcpServers": {
    "tinyfish": {
      "command": "npx",
      "args": ["@tinyfish/mcp-server"]
    }
  }
}
```

## Output Schema

Define expected output structure:

```typescript
output: {
  // Primitive types
  title: "string",
  count: "number",
  available: "boolean",
  
  // Arrays
  items: ["string"],
  
  // Objects
  metadata: {
    author: "string",
    date: "string"
  },
  
  // Arrays of objects
  products: [{
    name: "string",
    price: "number"
  }]
}
```

## Multi-Site Scraping

Query multiple sites in parallel:

```typescript
const result = await tf.browse({
  urls: [
    "https://site1.com/products",
    "https://site2.com/products",
    "https://site3.com/products"
  ],
  goal: "Compare prices for iPhone 15",
  output: {
    comparisons: [{
      site: "string",
      price: "number",
      shipping: "number"
    }]
  }
});
```

## Key Design Principles

- **Goal-driven** — Natural language intent, not selectors
- **Structured output** — Define your schema, get clean JSON
- **Multi-site parallel** — Query many sites at once
- **Stealth by default** — Handle anti-bot measures automatically
- **Observable** — Logs for every action taken
