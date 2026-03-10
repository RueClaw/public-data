# 🧪 Probe - The API Tester

> Your AI API tester that validates endpoints, monitors health, and tracks performance.

## Overview

Probe keeps your API reliable:

- Tests endpoints with various inputs and edge cases
- Runs periodic health checks
- Tracks response time trends
- Alerts on failures and slow endpoints

## Quick Start

### Installation

```bash
mkdir -p ~/.openclaw/agents/api-tester/agent
cp SOUL.md ~/.openclaw/agents/api-tester/agent/

openclaw agents add api-tester --workspace ~/.openclaw/agents/api-tester
```

### First Conversation

```bash
openclaw chat api-tester "Health check all endpoints"
```

## Use Cases

### 1. Endpoint Testing
```
You: "Test the checkout API"
Probe: [4 tests with inputs, responses, pass/warn/fail, suggestions]
```

### 2. Health Check
```
You: "Health check all endpoints"
Probe: [Table of endpoints with status, response time, result]
```

### 3. Test Generation
```
You: "Generate tests for this OpenAPI spec"
Probe: [Happy path, validation, edge case, and security tests]
```

### 4. Performance Monitoring
```
You: "Which endpoints are slow?"
Probe: [Endpoints exceeding threshold with trend data]
```

## Example Outputs

### Endpoint Test

```
POST /api/stripe/checkout

Test 1: Valid request → 200 (340ms) PASS
Test 2: Missing type → 200 (125ms) WARN
Test 3: Invalid type → 500 (89ms) WARN
Test 4: Empty body → 500 (45ms) WARN

Summary: 1 pass, 3 warnings
Suggestion: Add input validation
```

### Health Check

```
API Health - Feb 16

GET /           200  45ms  PASS
POST /checkout  200 340ms  PASS
POST /generate  200 890ms  SLOW
GET /health     200  22ms  PASS

5/5 up | Avg 283ms
Alert: /generate > 500ms threshold
```

## Tips

1. **Test after every deploy** - Catch issues before users do
2. **Set response time thresholds** - Know when things slow down
3. **Include edge cases** - Empty inputs, large payloads, special characters
4. **Monitor trends** - A slow endpoint today is a down endpoint tomorrow

## Changelog

- **v1.0.0** - Initial release with endpoint testing
- **v1.1.0** - Health monitoring and alerts
- **v1.2.0** - OpenAPI test generation

## Author

Created by [@openclaw](https://github.com/openclaw)

## License

MIT
