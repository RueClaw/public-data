---
name: API Documentation Generator
description: Generate comprehensive, professional API documentation following industry best practices
---

# API Documentation Guidelines

When generating API documentation, create clear, comprehensive, and developer-friendly documentation.

## Documentation Structure

Every API documentation should include:

1. **Overview** - What the API does, who it's for
2. **Authentication** - How to authenticate (API keys, OAuth, JWT)
3. **Base URL** - The root endpoint URL
4. **Endpoints** - Detailed endpoint documentation
5. **Request/Response Examples** - Real, working examples
6. **Error Codes** - Complete error reference
7. **Rate Limiting** - Usage limits and quotas
8. **Versioning** - API version strategy
9. **Changelog** - Version history

## Endpoint Documentation Format

For each endpoint, document:

```markdown
### GET /api/v1/users/{id}

Retrieves a single user by their unique identifier.

**Authentication Required**: Yes (Bearer token)

**Path Parameters**:
- `id` (integer, required): The unique user identifier

**Query Parameters**:
- `include` (string, optional): Comma-separated list of related resources to include
  - Options: `orders`, `preferences`, `address`
  - Example: `include=orders,preferences`

**Request Headers**:
- `Authorization: Bearer <token>` (required)
- `Accept: application/json` (optional, default)

**Success Response** (200 OK):
```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "created_at": "2024-01-15T10:30:00Z",
  "orders": [
    {
      "id": 456,
      "total": 99.99,
      "status": "completed"
    }
  ]
}
```

**Error Responses**:
- `401 Unauthorized`: Missing or invalid authentication token
- `404 Not Found`: User with specified ID doesn't exist
- `429 Too Many Requests`: Rate limit exceeded

**Example Request**:
```bash
curl -X GET "https://api.example.com/api/v1/users/123?include=orders" \
  -H "Authorization: Bearer your-token-here" \
  -H "Accept: application/json"
```
```

## Best Practices

### 1. Use Clear, Descriptive Language
- Write for developers who are new to your API
- Avoid jargon unless it's industry-standard
- Explain the "why" not just the "what"

### 2. Provide Working Examples
- Use realistic data in examples
- Include complete request/response cycles
- Show common use cases and patterns

### 3. Document Edge Cases
- What happens with missing optional fields?
- How are null values handled?
- What are the validation rules?

### 4. Error Documentation
- List all possible error codes
- Explain what causes each error
- Show how to resolve common errors

```markdown
## Error Codes

| Code | Message | Description | Resolution |
|------|---------|-------------|------------|
| 400 | Bad Request | Invalid request syntax or parameters | Check request body against schema |
| 401 | Unauthorized | Missing or invalid authentication | Include valid Bearer token in Authorization header |
| 403 | Forbidden | Authenticated but lacking permissions | Contact admin to verify account permissions |
| 404 | Not Found | Resource doesn't exist | Verify the resource ID is correct |
| 422 | Unprocessable Entity | Validation failed | Review validation errors in response body |
| 429 | Too Many Requests | Rate limit exceeded | Wait before retrying; check X-RateLimit-Reset header |
| 500 | Internal Server Error | Server-side error occurred | Retry request; contact support if persists |
```

### 5. Authentication Examples

Show multiple authentication methods if supported:

```markdown
## Authentication

### Bearer Token (Recommended)
```bash
curl -H "Authorization: Bearer your-token-here" \
  https://api.example.com/api/v1/users
```

### API Key (Legacy)
```bash
curl -H "X-API-Key: your-api-key" \
  https://api.example.com/api/v1/users
```

### OAuth 2.0
```bash
# First, obtain access token
curl -X POST https://api.example.com/oauth/token \
  -d "grant_type=client_credentials" \
  -d "client_id=your-client-id" \
  -d "client_secret=your-client-secret"

# Then use in requests
curl -H "Authorization: Bearer access-token" \
  https://api.example.com/api/v1/users
```
```

## Code Examples in Multiple Languages

Provide examples in popular languages:

```markdown
### Python
```python
import requests

headers = {
    'Authorization': 'Bearer your-token-here',
    'Content-Type': 'application/json'
}

response = requests.get(
    'https://api.example.com/api/v1/users/123',
    headers=headers
)

user = response.json()
print(f"User: {user['name']}")
```

### JavaScript
```javascript
const response = await fetch('https://api.example.com/api/v1/users/123', {
  headers: {
    'Authorization': 'Bearer your-token-here',
    'Content-Type': 'application/json'
  }
});

const user = await response.json();
console.log(`User: ${user.name}`);
```

### Java
```java
HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create("https://api.example.com/api/v1/users/123"))
    .header("Authorization", "Bearer your-token-here")
    .GET()
    .build();

HttpResponse<String> response = client.send(request,
    HttpResponse.BodyHandlers.ofString());

System.out.println(response.body());
```
```

## OpenAPI/Swagger Integration

When appropriate, include OpenAPI specification:

```yaml
openapi: 3.0.0
info:
  title: User Management API
  version: 1.0.0
  description: RESTful API for managing user accounts

paths:
  /api/v1/users/{id}:
    get:
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          description: User not found
```

## Interactive Documentation

Recommend tools for interactive docs:
- **Swagger UI** - Interactive API exploration
- **Redoc** - Clean, responsive API documentation
- **Postman Collections** - Shareable request collections
- **API Blueprint** - Markdown-based API documentation

## Versioning Documentation

Document version history clearly:

```markdown
## Changelog

### v2.0.0 (2024-03-01)
**Breaking Changes**:
- `GET /users` now requires authentication
- Removed deprecated `username` field; use `email` instead

**New Features**:
- Added `PATCH /users/{id}` for partial updates
- New query parameter `sort` for ordering results

**Bug Fixes**:
- Fixed pagination issue with `limit` > 100

### v1.5.0 (2024-02-01)
**New Features**:
- Added bulk user creation endpoint `POST /users/bulk`
```

## Rate Limiting Documentation

Be explicit about rate limits:

```markdown
## Rate Limits

| Tier | Requests/Hour | Requests/Day |
|------|--------------|--------------|
| Free | 100 | 1,000 |
| Pro | 1,000 | 10,000 |
| Enterprise | Unlimited | Unlimited |

**Rate Limit Headers**:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Requests remaining in current window
- `X-RateLimit-Reset`: Unix timestamp when limit resets

When rate limited, you'll receive a `429 Too Many Requests` response:
```json
{
  "error": "Rate limit exceeded",
  "retry_after": 3600
}
```
```

## When This Skill Activates

This skill automatically activates when:
- Generating REST API documentation
- Creating README files for API projects
- Writing OpenAPI/Swagger specifications
- Documenting GraphQL APIs
- Creating developer onboarding guides
- Questions about API documentation best practices
