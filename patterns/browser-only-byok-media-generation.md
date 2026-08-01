# Browser-Only BYOK Media Generation

**Source:** elder-plinius/GL4SS  
**Repo:** https://github.com/elder-plinius/GL4SS  
**License:** AGPL-3.0-or-later  
**Extracted:** 2026-08-01  

## Pattern

Build a static AI media app where the user's provider key stays in the browser, paid generation requires an explicit user action, and generated artifacts are saved locally rather than sent through an app backend.

This is useful when the product goal is an inspectable, deploy-anywhere client app and the operator does not want to custody user API keys.

## Core Structure

1. Serve the app as static assets with no backend secret path.
2. Let users paste their own provider key and verify it directly against the provider.
3. Store the key locally with graceful fallback when browser storage is unavailable.
4. Restrict `connect-src` to the app, the provider API, and any known lookup APIs.
5. Only attach `Authorization` headers to requests whose origin is the intended provider.
6. Keep paid generation behind a clear command, not incidental browsing.
7. Separate demand work from prefetch work and cap both queues.
8. Save generated metadata and media bytes in IndexedDB.
9. Evict low-value prefetched artifacts before user-requested artifacts.
10. Treat user-provided place/query text as data inside prompts and structured model calls.

## Why It Works

A browser-only BYOK app narrows the trust relationship. The application author does not operate a key-custody backend, and the user can inspect that generation requests go straight from browser to provider.

The risky part is that returned media URLs may live on different origins. If client code blindly adds the bearer token to every URL it fetches, a provider response, compromised dependency, or malicious URL could leak the key. Origin-checking before adding authorization headers keeps the key scoped to the intended API origin.

Local artifact storage also changes the user experience. Expensive generated images and videos become a local archive, not ephemeral render state, and the app can avoid accidental repeat billing when the user revisits prior views.

## Design Rules

Use a strict Content Security Policy. `connect-src` is the most important directive for key custody because it limits where authenticated API calls can go.

Make the paid action visible. Generation, video rendering, prefetching, and retry loops should never feel like passive navigation.

Do not assume browser storage works. Private mode, quota limits, and locked-down environments should degrade to session-only behavior instead of crashing.

Split metadata from media blobs in IndexedDB. Metadata stays cheap to scan, while large media bytes can be evicted by policy.

Gate prefetch separately from demand. Prefetch can improve perceived speed, but it should have a smaller queue, lower priority, and easier eviction.

Quote untrusted text as data in prompts. A place name, geocoder label, or user query should not be allowed to become instruction text by accident.

Document the license posture. AGPL/GPL projects can be studied and summarized, but copied implementation may bring source-sharing obligations.

## Caveats

LocalStorage key storage is still readable by any script that runs on the app origin. Keep dependencies small, build with CSP, and avoid third-party script injection.

Broad `img-src` or `media-src` may be necessary for provider-hosted assets, but it does not replace strict `connect-src` and origin checks around authorization.

This pattern does not solve centralized billing, team accounts, abuse controls, or shared quota management. Those usually require a server-side broker with a different trust model.

Generated media needs product framing. If outputs represent history, science, law, medicine, or finance, the app should make clear whether the images are sourced evidence or speculative generation.

---

**Attribution:** Based on elder-plinius/GL4SS, AGPL-3.0-or-later.
