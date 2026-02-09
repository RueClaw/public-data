# Pattern: Focus Mode with Tiered Urgency Detection

> **Source:** [ImTheMars/koda](https://github.com/ImTheMars/koda) (MIT License)

## Problem

AI assistants with proactive features (heartbeat tasks, scheduled reminders, background innovations) can interrupt the user during deep work. But some interruptions are genuinely urgent.

## Solution

A focus mode that holds non-urgent proactive messages, using a two-tier urgency detection system:

### Tier 1: Keyword Pre-Filter (~95% of cases)

**Obviously urgent** (allow through):
```
/urgent/, /emergency/, /asap/, /immediately/, /right now/,
/critical/, /meeting in \d+ min/, /starts? in \d+ min/, /call(ing)?/
```

**Obviously not urgent** (hold):
```
/fyi/, /just wanted to let you know/, /when you get a chance/,
/no rush/, /weekly/, /monthly/, /reminder for tomorrow/, /for later/
```

### Tier 2: LLM Classification (~5% ambiguous cases)

```
System: Reply ONLY 'urgent' or 'hold'. Say 'urgent' for time-critical 
        items (<15 min). Everything else: 'hold'.
```

- Input truncated to 300 chars
- `maxTokens: 5`, `temperature: 0`
- On failure, defaults to "hold" (safe default)

## State Management

```typescript
interface FocusState {
  active: boolean;
  expiresAt: string | null;    // ISO 8601
  reason: string | null;
  heldMessages: HeldMessage[];
}
```

- Persisted to `focus.json` for crash recovery
- Auto-expiry via timer
- On deactivation, all held messages are released
- Focus status injected into system prompt so the agent is aware

## Why This Is Good

- Keyword pre-filter handles the vast majority of cases with zero token cost
- LLM fallback only for truly ambiguous messages
- Safe default on failure (hold, don't interrupt)
- Crash recovery via file persistence
- The agent knows it's in focus mode and can inform the user
