# Direct-HTTP Provider Parity Layer

Source: https://github.com/lfnovo/esperanto  
License: MIT  
Extracted from review: [esperanto.md](../reviews/esperanto.md)  
Date: 2026-06-13

## Pattern

Build a small provider adapter layer that calls AI provider APIs directly over HTTP, normalizes responses into typed common objects, and treats cross-provider parity as the main product contract.

This sits between raw vendor APIs and larger agent frameworks. It is useful when an application needs provider flexibility without inheriting the behavior, dependencies, or runtime assumptions of a full orchestration system.

## Design Moves

- Keep the base install tiny: HTTP client plus type/validation library.
- Define one abstract interface per capability, such as language, embedding, reranking, speech-to-text, and text-to-speech.
- Normalize provider responses into shared typed objects.
- Put provider quirks inside provider request builders and response mappers.
- Use declarative profiles for OpenAI-compatible providers that only differ by base URL, API-key environment variable, default model, or small feature flags.
- Use full provider subclasses only when the API shape is genuinely different.
- Make configuration precedence explicit: constructor/config dict, environment variables, provider defaults.
- Provide both sync and async methods for each surface.
- Centralize connection concerns such as timeout, proxy behavior, and SSL verification.
- Keep model discovery separate from provider instance creation.

## Parity Rules

Provider parity does not mean every provider supports every field. It means the library behaves predictably.

Useful rules:

- If a provider cannot support a feature, raise a clear error.
- If a provider supports the feature but a specific model has a request-shape quirk, sanitize the request in the provider adapter and log/debug it.
- Do not synthesize structured response fields that the provider did not return.
- Store provider-specific extras in an escape-hatch metadata dict instead of bloating the common type.
- Prefer defaults that make hot-swapping work for ordinary users, even when that differs from a provider's native default.

## Testing Shape

Use three layers of tests:

- mocked unit/provider tests for the default CI path;
- cross-provider parity tests for shared interfaces and configuration propagation;
- release-gated real API tests that require credentials and can spend money.

The real API suite should be opt-in, clearly marked, and documented as a maintainer release ritual rather than a normal contributor test.

## When To Use It

Use this pattern when:

- the app is Python-native;
- provider choice should remain flexible;
- you need several modalities from one embedded library;
- direct HTTP calls are easier to debug than framework adapters;
- a full gateway/router is operationally too heavy.

Avoid it when:

- you need central billing, quotas, routing, and team policy;
- you need provider failover as infrastructure;
- you need hosted observability and admin controls;
- users should call through one network endpoint rather than importing a library.

## Failure Modes

- Provider drift becomes your maintenance burden.
- "OpenAI-compatible" APIs can be only partly compatible.
- Too many first-class fields can destroy parity.
- Silent feature dropping is worse than a clear unsupported error.
- Optional local-model dependencies can make test/typecheck environments fragile.

The central discipline is restraint: normalize only the fields you can honestly support, and leave the rest provider-specific.
