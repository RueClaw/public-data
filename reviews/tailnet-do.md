# tailnet-do (littledivy/tailnet-do)

**Repo:** https://github.com/littledivy/tailnet-do
**Author:** Divy Srivastava (littledivy)
**License:** BSD-3-Clause declared in package.json; root LICENSE/copyright terms missing. Clarify before redistribution; dependency notices remain separate.
**Reviewed:** 2026-11-08 (UTC)
**Revision:** bc36cd45e9e1f42442aa1cfe67b56a462dda72a6 (main); root JS/Go library, patches, build scripts, example and manifests. Tailscale gitlink: b31eb1c9bc582b9251d515ef634cfc99e1fc44e4.
**Verification:** Static source review only; no builds, dependency installs, runtime tests, tailnet enrollment, network probes, or deployment. Public metadata and selected pinned upstream files checked.
**Stack:** JavaScript ES modules, Go js/wasm, Tailscale userspace engine, gVisor netstack, Cloudflare Workers/Durable Objects.
**What it is:** A library that makes a Cloudflare Durable Object a Tailscale device, with inbound tailnet HTTP/TCP, outbound tailnet connections and constrained exit-node forwarding. It is not a DigitalOcean provisioning tool or general task runner.

---

## Verdict

📚 **Study — clever networking port, not a production-ready gateway.** The interesting achievement is embedding the real Tailscale userspace stack inside a Durable Object, rather than inventing a second VPN protocol. However, the included public Worker is an unauthenticated bridge to whatever the node can reach, the shared runtime is not a strong tenant boundary, and lifecycle/resource limits need tests and hardening. Use the architecture as a reference; do not deploy the example unchanged.

## What It Is

A Worker delegates to a named Durable Object. That object owns a Tailscale identity in SQLite-backed object storage and loads a Go WebAssembly engine shared by the Worker isolate. Tailnet peers can reach registered TCP ports; Workers with the object binding can call RPC methods to fetch HTTP resources or open streams through that identity.

The [README](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/README.md) claims control-plane and DERP connections use outbound WebSockets and that an object can be an exit node or subnet router. The implementation wires the real engine, local backend and netstack, with small patches for host TCP and DNS hooks. The pinned upstream [JS control transport](https://github.com/tailscale/tailscale/blob/b31eb1c9bc582b9251d515ef634cfc99e1fc44e4/control/controlhttp/client_js.go) supports the WebSocket control-plane claim. End-to-end connection, relay availability, throughput and compatibility were not independently demonstrated.

## Stack

| Layer | Technology and responsibility |
|---|---|
| Host | Workers ES modules; cloudflare:workers and cloudflare:sockets |
| Identity/state | Tailscale LocalBackend; per-object synchronous storage.kv adapter |
| Networking | Go userspace WireGuard/Tailscale and gVisor netstack; two local upstream patches |
| API | Tailnet.start, connect/fetch, listen/serve, whois/status/ready/logout; TailnetObject RPC |
| Build | Go 1.27.3 declared; pinned Tailscale submodule; shell patch/build steps |
| Deployment | Wrangler 4 development dependency, SQLite DO migration and CompiledWasm rule |

## Key Features

### A real tailnet identity with an application-sized API

[JS API](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/src/index.js#L146-L349) and [engine setup](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L419-L535) provide a compact embedding surface. The wrapper memoizes one start promise per object context and exposes raw TCP streams as well as buffered HTTP. MagicDNS resolution is delegated to Tailscale's user dialer. This is narrower and more platform-specific than a complete Tailscale daemon.

### Caller identity is available, but policy remains necessary

[whois](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L628-L646) maps the connection address through LocalBackend.WhoIs and returns login/display/node names and tags, or null. This is useful identity context, not automatic application authorization: handlers must reject unknown callers and explicitly decide which users/tags may perform operations. Tagged devices should not be treated as human identities. Network reachability is governed by the node's tailnet policy, not by the public HTTP caller's original identity.

### Exit-node forwarding is deliberately incomplete

[Host hooks](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L250-L307) send forwarded TCP through Cloudflare sockets, send UDP port 53 queries to DoH, and drop other forwarded UDP. Applications with TCP fallback may recover from QUIC loss; arbitrary UDP applications do not magically fall back. There is no basis here to promise full VPN/IP-protocol parity.

## Architecture

1. A request or alarm creates/loads the named object and its Tailnet instance.
2. One isolate-wide enginePromise loads Go/Wasm and installs host callbacks. Each object gets its own backend/netstack and persistent state prefix.
3. Tailscale control/relay connectivity carries encrypted overlay traffic; registered local ports dispatch to JS handlers with WhoIs results.
4. Worker RPC fetch/connect originates as the object's node. HTTP crosses a buffered JS/Go boundary; TCP uses adapters.
5. Forwarded exit/subnet TCP goes through cloudflare:sockets; DNS uses the configured DoH endpoint, defaulting to Cloudflare DNS.

The two [patches](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/patches/tailscale/) are small and inspectable. That is a good maintenance shape, but they change networking and DNS policy seams and require regression coverage against the exact upstream revision.

## Security and Trust Boundaries

### High priority: the example is an unauthenticated private-network proxy

[examples/exit-node/src/index.js](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/examples/exit-node/src/index.js#L26-L42) accepts /tailnet?url=... and passes the URL directly to tailnetFetch. There is no caller authentication, target allowlist, per-user authorization or request budget. Other paths expose node status. If this Worker is publicly reachable and its node is enrolled, an unauthenticated visitor can issue HTTP requests as that node to destinations its tailnet permissions allow. This is a static data-flow finding, not a claim that any live deployment was exploited.

The Go HTTP client uses ordinary redirect behavior without a destination policy ([client construction](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L505-L506), [fetch](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L649-L678)). Allowlisting only the first URL would therefore be insufficient. Restrict schemes, resolved destinations, ports and redirects; authenticate before touching the object; constrain the node with least-privilege tailnet grants; preferably expose fixed application operations rather than arbitrary URLs. CORS is not authentication and cannot stop direct HTTP clients. The example contains no explicit cross-origin policy either.

### Enrollment, status and credentials

Auth keys are read from environment secrets, then passed to the backend; no concrete credentials were found in the inspected source. Without an auth key, the backend initiates interactive login and stores its loginURL in status notifications. The example returns that status publicly. Treat enrollment URLs as sensitive and never expose them or internal node names/addresses/peer counts on an unauthenticated status endpoint. JS status merges notifications and does not explicitly clear a previous loginURL on successful login ([status handling](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/src/index.js#L182-L215)).

The [state adapter](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L698-L715) hex-encodes state into object storage. Hex is not encryption; machine/node identity material in that state must be protected through Cloudflare account, binding, backup and operator controls. There is no application-layer key wrapping, rotation runbook, or secure wipe guarantee here. logout delegates to the backend; it is not a complete object teardown or alarm/storage deletion API. All() returns an empty iterator, so state enumeration semantics need compatibility tests rather than assumptions of a complete store implementation.

### Objects are separate identities, not isolated tenants inside the library

[loadEngine/logSinks](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/src/index.js#L16-L56) is isolate-global. The first node's dohURL initializes the shared engine and later nodes do not get an independent resolver. Every registered onLog sink receives engine log lines, with no node-level routing or deregistration. Go's DNS/UDP hooks are global too. Separate storage prefixes do not isolate resolver selection, logs, runtime crashes, memory pressure or CPU consumption. Do not place mutually untrusted tenant configurations/callbacks into one shared Worker isolate on the assumption that this library provides a security boundary.

### DNS and relay privacy require explicit decisions

Traffic crosses Tailscale control/DERP infrastructure and Cloudflare's runtime; DNS queries leave to the configured DoH provider. The overlay encryption ends at the object: Cloudflare-hosted application code sees endpoint plaintext, and forwarded plaintext application protocols remain plaintext on egress unless the application uses TLS. DERP mediation is not a guarantee of direct-peer performance or traffic anonymity.

[Patch 0002](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/patches/tailscale/0002-ipn-ipnlocal-allow-overriding-exit-node-DNS-resoluti.patch) preserves upstream source admission but replaces HandlePeerDNSQuery with a callback that does not receive the nameAllowed filter or caller address. The pinned upstream [peer API](https://github.com/tailscale/tailscale/blob/b31eb1c9bc582b9251d515ef634cfc99e1fc44e4/ipn/ipnlocal/peerapi.go#L748-L892) distinguishes source admission from query-name filtering. The override therefore skips that resolver-level filter when one would apply; this is not evidence that all Tailscale ACLs are bypassed. Verify intended DNS policy and split-horizon behavior before use. The forwarded UDP DNS path also sends port-53 traffic to its chosen DoH provider rather than respecting the original DNS destination.

## Persistence, Concurrency and Recovery

- **Identity survives object recreation:** state is written through synchronous SQLite KV with an explicit prefix. This does not persist open sockets, JS handler state or active HTTP requests.
- **Keepalive has a cost and is not an uptime guarantee:** default alarms reschedule every 20 seconds, about 4,320 invocations/day or 129,600 per 30 days per object. Deployments, crashes and eviction still require recovery.
- **Shared engine failure is sticky:** start promises per object can be retried, but the global enginePromise is not reset on load failure; go.run failures are logged without a recovery protocol. There is no public node dispose/engine restart path.
- **Unbounded HTTP bodies:** request/response conversion buffers bodies in JS and Go. The inbound server uses io.ReadAll without an explicit application byte cap or server timeouts; response reads are also unbounded. The outbound fetch has a 60-second context, but cancellation from the caller's Request signal is not carried across the bridge.
- **Timeout semantics are incomplete:** hostDial/hostDoH accept a Go context but do not wire cancellation to the JS socket/fetch; jsConn deadline setters are no-ops. A five-second Go DNS context does not itself abort the JS DoH request.
- **Resource cleanup deserves tests:** exported connection js.Func callbacks are not released when closed; unlisten deletes the port map entry without closing the HTTP server/listener it created. Socket.closed resolves on explicit finish/error/cancel, not normal readable EOF alone. Repeated connections or listener replacement may retain resources.
- **Limited validation:** listener ports are cast to uint16, with no public range validation. Routes are parsed and rejected on invalid prefixes. Listener maps and read/write paths use mutexes, but no stress, object-restart or multi-node-isolate tests are included.

Evidence: [socket and HTTP adapters](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/src/index.js#L74-L139), [alarms and API](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/src/index.js#L243-L286), [Go connections](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L135-L239), [listeners/HTTP](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/go/main.go#L551-L678). These are static hazards and contract gaps, not measured leak rates or crash reproductions.

## Self-Hosting Notes and Costs

This is Cloudflare-hosted code, not generic VPS self-hosting. Prerequisites are a compatible Workers/Durable Objects account, SQLite-backed object binding/migration, Wrangler, a matching Go toolchain and compiled Wasm, plus an authorized Tailscale tailnet or compatible control plane. The README mentions custom controlURL/Headscale; compatibility was not tested. Exit routes must be approved and client/policy configuration must permit their use; advertising routes is not equivalent to approving them.

A subnet-router advertisement does not create physical access to a private LAN. Forwarded sockets originate at Cloudflare. Its [TCP documentation](https://developers.cloudflare.com/workers/runtime-apis/tcp-sockets/) lists disallowed destinations including private IPs, localhost and Cloudflare IPs, as well as port-25 restrictions. Ordinary tailnet dialing uses the overlay instead, but this does not make arbitrary private subnets directly reachable through the host-forwarding hook. Cloudflare placement hints are preferences, not a contractual country-specific egress guarantee; the example does not set a hint.

Cloudflare's [Durable Objects pricing](https://developers.cloudflare.com/durable-objects/platform/pricing/) at review time offers SQLite objects on Free and Paid plans. Free includes 100,000 requests/day and 13,000 GB-s/day; excess free usage fails rather than silently granting paid capacity. Paid includes 1 million requests/month and 400,000 GB-s/month, with excess rates listed as $0.15/million requests and $12.50/million GB-s, subject to documented billing rounding. Storage and the Workers plan are separate considerations. Persistent outbound sockets/active objects can accrue duration charges; frequent alarms undermine a simplistic “serverless means idle is free” assumption. Tailscale plan/usage terms also apply. No deployment cost or performance was measured, and no paid services were invoked.

### Install/update behavior

The [build scripts](https://github.com/littledivy/tailnet-do/blob/bc36cd45e9e1f42442aa1cfe67b56a462dda72a6/scripts/) initialize the pinned submodule, apply local patches, build js/wasm with many feature-omission tags, and replace wasm_exec.js with the matching Go runtime helper. Wasm is not committed. There is no install-time lifecycle script, auto-updater, release binary verification flow or CI build provenance in this checkout. Building can download the Go toolchain/dependencies and submodule; none was run for this review. Wrangler deployment creates/updates cloud resources and the example enables observability. Pin and audit tooling, preserve identity storage/migrations, canary upgrades and test rollback. Client-update and several security/operational features (including tailnet-lock, SSH and logtail) are omitted by build tags; this is not full daemon feature parity.

## License, Dependencies and Maturity

The manifest version is 0.0.1 and declares BSD-3-Clause, but the checkout has no root LICENSE. [Issue #1](https://github.com/littledivy/tailnet-do/issues/1) independently requests the missing license text and copyright line. Treat this as a declared license with incomplete distribution notices, not a fully verified BSD license package; obtain clarification before redistributing a fork or Wasm bundle. The pinned [Tailscale LICENSE](https://github.com/tailscale/tailscale/blob/b31eb1c9bc582b9251d515ef634cfc99e1fc44e4/LICENSE) is BSD-3-Clause; Go's wasm_exec.js carries a separate Go Authors notice; gVisor and other dependencies require their own notice/term audit. No source code was extracted into this review library.

Go dependencies are versioned with go.sum and the Tailscale gitlink; the example has an npm lockfile but its Wrangler manifest range is ^4. There is no test script, first-party test suite or .github CI workflow in the reviewed tree. The upstream commit is titled “Initial tailnet-do library,” dated 2026-11-07. Public GitHub metadata checked 2026-11-08 reported 113 stars, 2 forks, last push 2026-11-07T05:35:07Z, one open issue and no releases. These are a time-sensitive activity snapshot, not reliability evidence. Full upstream Tailscale/gVisor dependency code and vulnerability history were not audited.

## Comparison

| Option | Fit | Trade-off |
|---|---|---|
| tailnet-do | Experiment embedding a node directly in a Durable Object | No VM, but Cloudflare-specific transport, global runtime hooks, incomplete lifecycle and new integration |
| [Tailscale tsnet](https://pkg.go.dev/tailscale.com/tsnet) | Embed a tailnet service in a normal Go application | Conventional host/container required; avoids this custom Wasm/Workers bridge |
| [Tailscale exit node](https://tailscale.com/kb/1103/exit-nodes) on an existing host | General-purpose tailnet internet egress | Host operations and hosting costs; not constrained to this TCP-plus-DoH adapter |
| [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) with Access policy | Publish selected private applications through an authenticated Cloudflare front door | Requires a connector and different trust model; does not make a DO a Tailscale peer |

For a narrow HTTP application, prefer a fixed, authenticated gateway or an established connector rather than exposing an arbitrary fetch primitive. For a general exit node, a normal supported Tailscale host is the more defensible default. Consider this library for a controlled prototype only after fixing public admission, resolver/log isolation, resource limits, lifecycle tests and licensing notices.

## Verification and Limits

Acquisition succeeded via anonymous public HTTPS Git. Canonical owner/repository and exact source/gitlink revisions were checked; public review/index searches found no prior review for this source. Source tracing covered the complete first-party JS API and Go engine, patches, manifests, build/deploy scripts and example. Selected pinned upstream control/DNS/license files and public platform documentation were inspected. The HTML artifact is validated as standalone markup; this is not proof of runtime networking.

**Not performed:** builds, tests, packet inspection, real HTTP proxy requests, enrollment, ACL enforcement experiments, cloud deployment, billing measurement, load/restart/recovery exercises, full dependency audit, or registry-package verification. No claim here establishes a working production deployment or a remotely demonstrated exploit.

---

**Attribution:** littledivy/tailnet-do by Divy Srivastava; BSD-3-Clause declared, root license text missing at reviewed revision. Tailscale and Go component notices are separate. Analysis only.
