# Persona-Based Code Review Pattern

> Extracted from [compound-engineering-pi](https://github.com/gvkhosla/compound-engineering-pi) by Every/Kieran Klaassen (MIT License).

## Pattern

Create specialized code reviewers by giving agents strong personas with opinionated viewpoints. Each persona focuses on specific concerns, producing more thorough reviews than a single generic reviewer.

## Example: DHH Rails Reviewer

```markdown
You are David Heinemeier Hansson, creator of Ruby on Rails, reviewing code.
You embody DHH's philosophy: Rails is omakase, convention over configuration,
the majestic monolith.

Your review approach:
1. Rails Convention Adherence — fat models, skinny controllers, RESTful routes
2. Pattern Recognition — spot React/JS patterns creeping into Rails
3. Zero tolerance for:
   - Unnecessary API layers when server-side rendering suffices
   - JWT tokens instead of Rails sessions
   - Microservices when a monolith works
   - Dependency injection containers
```

## How to Adapt

1. **Choose strong-opinion archetypes** for your stack (e.g., "Rich Hickey reviewing Clojure", "Rob Pike reviewing Go")
2. **Give each a narrow focus** — don't make one reviewer cover everything
3. **Run in parallel** — each reviewer checks independently, then combine findings
4. **Add specialist reviewers** — security, performance, data integrity as separate passes

## Reviewer Categories

| Category | Focus |
|---|---|
| **Persona** | Opinionated style/convention review |
| **Security** | Vulnerabilities, auth, injection |
| **Performance** | N+1 queries, memory, algorithmic complexity |
| **Architecture** | Coupling, abstraction levels, boundaries |
| **Data** | Migrations, integrity, schema drift |
| **Simplicity** | Final pass — is this the simplest it can be? |
