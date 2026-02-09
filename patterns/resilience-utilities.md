# Pattern: Resilience Utilities for AI Agent Services

> **Source:** [ImTheMars/koda](https://github.com/ImTheMars/koda) (MIT License)

A clean set of three resilience primitives used throughout Koda's provider layer.

## 1. Circuit Breaker

Prevents hammering a failing service. Three states: closed → open → half-open → closed.

```typescript
const breaker = new CircuitBreaker({
  name: "memory-service",
  failureThreshold: 5,    // consecutive failures before opening
  resetTimeoutMs: 60_000, // wait before trying half-open
});

const result = await breaker.execute(
  () => memoryService.recall(query),
  fallbackValue  // returned when circuit is open
);
```

## 2. Retry with Exponential Backoff + Jitter

```typescript
const result = await withRetry(
  () => llm.generate(prompt),
  {
    maxRetries: 3,
    baseDelayMs: 1000,
    maxDelayMs: 30_000,
    retryableErrors: isRetryableHttpError, // 429, 5xx, network errors
  }
);
```

The `isRetryableHttpError` helper parses status codes from error messages and properties — handles the inconsistent error formats across different HTTP clients.

## 3. Sliding Window Rate Limiter

Per-key (userId) rate limiting with automatic cleanup:

```typescript
const limiter = new RateLimiter({ maxRequests: 10, windowMs: 60_000 });

if (!limiter.isAllowed(userId)) {
  return "Too many requests, slow down";
}
```

Notable: enforces a `MAX_KEYS` limit (10,000) with LRU eviction to prevent memory exhaustion from many unique keys.

## Why These Matter for AI Agents

AI agents make many external API calls (LLM, memory, search, voice) and need graceful degradation. These three primitives cover the common failure modes:
- **Circuit breaker**: service is down → stop trying, use fallback
- **Retry**: transient failure → try again with backoff
- **Rate limiter**: user abuse → throttle without crashing
