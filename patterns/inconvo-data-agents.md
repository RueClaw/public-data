# Inconvo Data Agents Pattern

> **Source:** [inconvoai/inconvo](https://github.com/inconvoai/inconvo)
> **License:** Apache 2.0
> **Description:** Build chat-with-data agents for customer-facing applications. Safe queries, permissions, and structured outputs over production databases.

## Overview

Inconvo is the open-source platform for building data agents on production data. A data agent answers natural-language questions over live databases — safely, with enforced permissions, and in structured outputs.

## Core Capabilities

- **Safe queries** — All generated queries validated and constrained before execution
- **Permissions & multi-tenancy** — Row-, table-, and column-level access enforced automatically
- **Stateful interactions** — Agents retain filters and refinements across turns
- **Observability** — Every run is traceable with query logs and execution details
- **Semantic modeling** — Layer business context over raw schemas

## Agent Architecture

### Calling Agents from Code

```typescript
import Inconvo from "@inconvoai/node";

const inconvo = new Inconvo({
  apiKey: process.env.INCONVO_API_KEY,
});

// Create a conversation with an agent
const agentConvo = await inconvo.agents.conversations.create("agt_123", {
  user: { id: "user_456" },
  context: {
    tenantId: "tenant_789"  // For multi-tenant filtering
  }
});

// Ask questions
const response = await agentConvo.message({
  content: "How many orders did we process last month?"
});

// Response includes structured data
console.log(response.data);  // { orderCount: 1234 }
```

### Multi-Turn Conversations

```typescript
// Agents maintain state across turns
await agentConvo.message("Show me orders over $1000");
// Returns filtered order list

await agentConvo.message("Now just the ones from California");
// Refines the previous filter without re-stating
```

## Permission System

### Table-Level Permissions

```yaml
tables:
  orders:
    allowed: true
    columns:
      - id
      - customer_id
      - total
      - created_at
  customers:
    allowed: true
    columns:
      - id
      - name
      - email
  internal_notes:
    allowed: false  # Hidden from agents
```

### Row-Level Security

```yaml
# Filter all queries by tenant
row_filters:
  orders: "tenant_id = :tenantId"
  customers: "tenant_id = :tenantId"
```

### Column Masking

```yaml
# Mask sensitive columns
column_masks:
  customers.email: "masked"
  customers.ssn: "hidden"
```

## Semantic Modeling

Add business context without changing queries:

```yaml
semantic_layer:
  metrics:
    - name: total_revenue
      sql: "SUM(orders.total)"
      description: "Total revenue from completed orders"
    
    - name: avg_order_value
      sql: "AVG(orders.total)"
      description: "Average order value"

  dimensions:
    - name: customer_segment
      sql: "CASE WHEN orders.total > 1000 THEN 'enterprise' ELSE 'smb' END"
      description: "Customer segment based on order value"

  terminology:
    - term: "big deals"
      means: "orders over $10,000"
    - term: "churned"
      means: "customers with no orders in 90 days"
```

## Structured Outputs

Define expected response schemas:

```typescript
const response = await agentConvo.message({
  content: "What's our revenue breakdown by region?",
  outputSchema: {
    breakdown: [{
      region: "string",
      revenue: "number",
      orderCount: "number",
      percentOfTotal: "number"
    }]
  }
});
```

## Observability

Every agent run includes:

```typescript
{
  runId: "run_abc123",
  query: "What's our revenue breakdown by region?",
  generatedSQL: "SELECT region, SUM(total) as revenue...",
  executionTimeMs: 234,
  rowsReturned: 5,
  tokensUsed: 1250,
  model: "gpt-4",
  errors: []
}
```

## Key Design Principles

- **Safe by default** — Query validation before execution
- **Permission-first** — Access control is not optional
- **Stateful** — Conversations remember context
- **Observable** — Debug and monitor every query
- **Semantic layer** — Business terms over raw SQL
- **Structured output** — Typed responses for applications
