# LiveKit (livekit/livekit)

**Repo:** https://github.com/livekit/livekit
**License:** Apache-2.0; permissive reuse with attribution and patent grant
**Reviewed:** 2026-08-24
**Stack:** Go, Pion WebRTC, Redis, Twirp/Protobuf, JWT auth, Prometheus, Docker/Kubernetes
**What it is:** Production-grade open-source realtime media infrastructure for adding multi-user audio, video, data channels, livestreaming, WHIP, SIP, ingress/egress, and AI-agent participants to applications.

---

## Verdict

✅ **Deploy candidate when realtime media is core product infrastructure.** LiveKit is mature, actively maintained, and unusually complete: SFU, signaling, distributed routing, JWT permissions, TURN, metrics, webhooks, SDK ecosystem, deployment docs, and AI-agent hooks are all real. It is not a casual dependency; operating it means owning WebRTC networking, Redis-backed clustering, key management, TURN exposure, and observability.

---

## What It Is

LiveKit is an open-source WebRTC server and realtime stack. The core repository is the Go media server: it handles room creation, participant signaling, SFU forwarding, data channels, subscriptions, ICE/TURN connectivity, auth enforcement, webhooks, metrics, and clustered routing.

The broader ecosystem includes client SDKs for JavaScript, Swift, Android/Kotlin, Flutter, Unity WebGL, React Native, and Rust, plus server SDKs, CLI tooling, Helm charts, egress/ingress services, SIP, and LiveKit Agents for realtime AI participants. The current README tagline, "real-time video, audio and data for developers," is accurate; this is infrastructure for building realtime products rather than a standalone meeting app.

The repo is old enough and busy enough to judge by maintenance posture rather than promise. It has 20k+ stars, regular tagged releases, a large Go test surface, pinned GitHub Actions, dependency automation, a changelog with security-relevant TURN/auth changes, and local focused tests mostly passed in this review.

## Stack

| Layer | Tech |
|-------|------|
| Media server | Go 1.26, Pion WebRTC with LiveKit-maintained `warp` forks for WebRTC/DTLS/ICE |
| Signaling/API | HTTP/WebSocket, Twirp, Protobuf, LiveKit protocol packages |
| SFU/media | RTP/RTCP forwarding, simulcast, SVC, dynacast, congestion control, NACK/PLI, packet buffers |
| Clustering | Redis routing, node registry, room-to-node map, PSRPC signal relay |
| Auth | JWT access tokens signed by configured API key/secret pairs |
| Networking | UDP/TCP ICE, embedded/external TURN, STUN, WHIP, SIP/ingress integrations |
| Observability | Prometheus metrics, structured zap logging, optional pprof/debug server, Grafana dashboard |
| Delivery | Single binary, Docker image, Kubernetes/Helm docs, Homebrew/install script |
| Testing/CI | Go unit/integration tests, race-test workflow, Redis service in CI, lint, release automation |

## Key Features

### Distributed WebRTC SFU

LiveKit is primarily a Selective Forwarding Unit. Publishers send media once; the server forwards appropriate layers to subscribers. The codebase has deep machinery for RTP sequence handling, codecs, simulcast/SVC, video layer selection, stream allocation, bandwidth estimation, packet buffering, retransmission, and connection quality.

### Room And Participant Control

The service layer exposes room and participant management APIs with JWT grant checks. Tokens can grant join, create, list, admin, record, ingress, SIP, and room-scoped permissions. The server also supports participant metadata/attributes limits, selective subscription, remote mute/unmute controls, data tracks, and webhooks.

### Distributed Routing With Redis

When Redis is configured, LiveKit can run multiple nodes. The Redis router stores node state and room placement, while PSRPC relays signaling and internal service calls. This makes the single-binary development path scale into clustered production without changing the application-facing API.

### Connectivity And TURN Hardening

LiveKit includes WebRTC networking features that matter in production: UDP port ranges, ICE/TCP fallback, TURN/TLS, external IP discovery, interface/IP filters, loopback candidate toggles, and per-user TURN relay allocation quotas. Recent releases tightened TURN credential TTLs and default-deny behavior for relaying to restricted/private peer CIDRs.

### AI-Agent Participant Surface

The `pkg/agent` and service APIs support worker registration, job dispatch, worker availability, agent participant permissions, and job tokens. That makes LiveKit a direct substrate for realtime voice/video/data agents, not just human conferencing.

## Architecture

The repo is a Go server with clear package boundaries:

- `cmd/server` is the production server CLI and config entry point.
- `cmd/test-server` is a mock server for SDK/client tests.
- `pkg/config` owns YAML/CLI config, validation, defaults, and TURN/key handling.
- `pkg/service` owns HTTP/Twirp routes, auth middleware, room/agent/ingress/egress/SIP/WHIP services, TURN, and server lifecycle.
- `pkg/routing` owns local and Redis-backed node/room routing plus node selectors.
- `pkg/rtc` owns rooms, participants, signaling, transports, subscriptions, data tracks, and agent room integration.
- `pkg/sfu` owns RTP/SFU packet forwarding, receivers/downtracks, bandwidth estimation, codec mungers, and stream tracking.
- `pkg/telemetry` owns metrics and event reporting.

The important pattern is separation between control plane and packet path. Service/routing code decides who may join, where rooms live, and what participants can do; RTC and SFU code handle low-latency media state and forwarding. Redis is optional for local development but becomes the shared coordination layer in distributed deployments.

Security-wise, the repo shows real hardening: JWT verification before room/API access, grant-specific permission checks, request body size limiting, short-secret warnings, TURN secret-file permission checks, TURN credential TTLs, restricted-peer deny/allow policy, optional metrics basic auth, pprof separated onto a dedicated port, and CI with pinned actions. A lightweight secret-pattern scan found examples/test tokens/config placeholders, not obvious committed production secrets.

## Comparison

| Aspect | LiveKit | Janus | Jitsi Videobridge |
|--------|---------|-------|-------------------|
| Primary shape | Product-ready realtime platform and SFU | General-purpose WebRTC gateway | Conferencing-focused SFU stack |
| Main language | Go | C | Java/Kotlin ecosystem |
| App developer ergonomics | Large SDK/API ecosystem, JWT room grants, CLI, managed/cloud option | Plugin/gateway oriented | Strong for conferencing, heavier platform shape |
| AI-agent fit | First-class LiveKit Agents ecosystem and server worker hooks | Possible but external | Possible but less central |
| Self-hosting | Single binary, Docker, Kubernetes/Helm | Native packages/containers | Usually heavier conferencing deployment |

LiveKit is the easiest of these to adopt when the product is custom realtime collaboration or AI voice/video/data interactions. Janus remains attractive for gateway/plugin-heavy media plumbing, and Jitsi remains strong for full meeting/conferencing stacks, but LiveKit has the best developer-platform shape.

## Self-Hosting Notes

The development path is simple: `livekit-server --dev` starts with `devkey` / `secret`. Do not carry that into production. Use `livekit-server generate-keys`, configure real API secrets of at least 32 characters, put HTTP behind TLS, expose only the required UDP/TCP/TURN ports, and use Redis for multi-node deployments.

Operational gotchas are the usual hard WebRTC ones: public IP and NAT behavior, UDP firewall ranges, TURN/TLS placement, Redis availability, bandwidth/CPU capacity, observability, and key rotation. Treat `/debug/*` and pprof as private-only, protect Prometheus if exposed, and test clients from the networks your users actually occupy.

Local validation in this review: focused `go test` passed for `cmd/server`, `cmd/test-server`, `pkg/config`, `pkg/routing`, `pkg/routing/selector`, `pkg/rtc`, `pkg/sfu/...`, `pkg/telemetry`, `pkg/utils`, `pkg/clientconfiguration`, `pkg/agent`, and related subpackages. `pkg/service` did not run locally because its `TestMain` requires a Docker API socket to start dependencies; upstream GitHub Actions run the broader race test on Ubuntu with Redis.

---

**Attribution:** livekit/livekit, Apache-2.0
