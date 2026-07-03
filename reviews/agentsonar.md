# AgentSonar (knostic/AgentSonar)

**Repo:** https://github.com/knostic/AgentSonar  
**License:** No license specified; treat as educational/reference only, not reusable code  
**Reviewed:** 2026-07-03  
**Stack:** Go, libpcap/gopacket, SQLite, Cobra CLI, Linux/macOS packet capture  
**What it is:** A local network-monitoring CLI/library that watches outbound DNS/TLS/streaming traffic and scores process-to-domain pairs for likely AI-agent activity.

---

## Verdict

⚠️ **Interesting local detector, limited as a router sensor.** AgentSonar is useful on endpoints because it combines destination domains with local process attribution. On a router or mirrored interface it can still classify domains and traffic shape with `--enable-pid0`, but it loses the strongest signal: which local process made the connection.

---

## What It Is

AgentSonar is a "shadow AI agent" detection tool. It captures outbound traffic, extracts DNS queries and TLS SNI from client hellos, associates connections with local processes, computes JA4 TLS fingerprints, and scores process-to-domain pairs for likely AI tool usage.

The core workflow is local and operator-driven. Run `agentsonar` or `agentsonar start`, then review live events or query stored SQLite events. Known AI tools can be added as process/domain patterns, noisy domains can be ignored, and unclassified events can be triaged into local overrides. There is also a classify-only mode for JSONL events from another source.

The important distinction: AgentSonar is not a full network IDS. It is an endpoint-aware detector. It works best where it can see both packets and the OS socket table. If it only sees gateway traffic, it can infer "this domain looks AI-like" but not "this process on this machine is the agent."

## Stack

| Layer | Tech |
|-------|------|
| CLI | Go, Cobra |
| Packet capture | libpcap via `github.com/google/gopacket` |
| Process attribution | macOS `netstat`/libproc, Linux `/proc/net/tcp` plus `ss` |
| Traffic parsing | DNS parser, TLS ClientHello/SNI parser, JA4 fingerprinting |
| Scoring | Built-in heuristic classifier plus external classifier protocol |
| Persistence | SQLite via `github.com/mattn/go-sqlite3` |
| Config | Gzip/gob overrides file for known agents, noise domains, classifiers |
| Platforms | macOS and Linux |

## Key Features

### Process-To-Domain Attribution

The strongest feature is pairing local process identity with destination domain. On macOS it uses `netstat` and libproc process path lookup. On Linux it reads `/proc/net/tcp`/`tcp6`, maps socket inodes back to processes, and uses `ss` for connection byte counters.

That makes it useful for answering questions like "is this unknown binary talking to an LLM API?" A gateway alone usually cannot answer that question because it does not have endpoint process tables.

### Heuristic AI Traffic Scoring

The default classifier scores features associated with LLM API traffic: asymmetric response bytes, small streamed packets, sustained packet rate, long-lived connections, TLS plus streaming, concurrent connections, programmatic TLS, and repeated observations. Infrastructure-looking subdomains such as logs, telemetry, CDN, OCSP, auth, and metrics subtract from the score.

Known agents override the heuristic with a 1.0 score. Known noise domains are filtered or scored 0.0.

### Router/Mirror Capture Mode

The README explicitly supports traffic without process attribution:

```bash
agentsonar -i bond0 --enable-pid0
agentsonar -i eth0 --enable-pid0
```

That mode is for containers, proxy/gateway servers, TAP/span ports, and mirrored traffic. It is the right mode for a router-adjacent deployment, but it should be understood as domain/traffic classification rather than endpoint attribution.

### Classify-Only Mode

`agentsonar classify` accepts JSONL events from stdin. That makes it possible to use external packet captures, SIEM exports, or `tshark` output:

```bash
tshark -r capture.pcap -Y 'tls.handshake.extensions_server_name' \
  -T fields -e tls.handshake.extensions_server_name | \
  jq -Rc '{domain: ., source: "tls"}' | agentsonar classify
```

This is probably the cleanest integration path for router-generated pcaps.

### SIEM And Sigma Hooks

The repo includes import/export of overrides, Sigma-format export/import, external classifier loading, and a Graylog forwarding example. That gives it a path into a broader security workflow without turning the core CLI into a server.

## Architecture

The code is compact and easy to follow. Platform capture implementations live under `internal/capture/monitor_darwin.go` and `internal/capture/monitor_linux.go`; the public API wraps those monitors behind `NewMonitor`. Events flow into an accumulator, which combines repeated observations and calls a classifier registry. CLI commands handle monitoring, daemon control, event queries, triage, overrides, imports/exports, and external classifier management.

The classifier design is deliberately simple. It does not maintain a hardcoded global list of AI providers; instead, it combines local overrides with traffic-shape features. That keeps the tool useful as new AI domains appear, but it also means false positives are expected and triage is part of the workflow.

Build quality is better than the repo size suggests. `go test ./...`, `go test -race ./...`, and `go vet ./...` all passed locally. CI covers Linux and macOS and includes a gitleaks workflow. The biggest project risk is not tests; it is that GitHub reports no license file, so code reuse is not legally clean.

## Comparison

| Aspect | AgentSonar | NetWatch | Traditional DNS logs | Endpoint EDR |
|--------|------------|----------|----------------------|--------------|
| Primary job | Detect likely AI-agent traffic | General network diagnostics/TUI | Domain visibility | Broad process/security telemetry |
| Process attribution | Yes on local host | Yes on local host | No | Yes |
| Router/mirror usefulness | Partial with `--enable-pid0` | Packet visibility, not AI scoring | Good for domains only | Usually endpoint-based |
| AI-specific scoring | Yes | No | No | Product-dependent |
| Best deployment | Endpoint or Linux sensor | Workstation/server diagnostics | DNS resolver/gateway | Managed fleet |

## Self-Hosting Notes

For an endpoint, use the release binary and run `agentsonar install` to configure capture permissions. On Linux, install libpcap and set `cap_net_raw,cap_net_admin` on the binary. On macOS, the installer configures BPF access.

For a Ubiquiti Cloud Gateway Fiber or similar router, the practical answer is:

- **Do not plan on installing AgentSonar directly on the gateway as a normal supported deployment.** UniFi gateways are appliance-style systems, and third-party binaries/capabilities may be unsupported, non-persistent, or fragile after firmware updates.
- **Use a separate Linux box or VM as the sensor** if you can mirror gateway/LAN traffic to it, then run `agentsonar -i <iface> --enable-pid0`.
- **Use router packet captures offline** if live mirroring is not available: capture traffic from the gateway, extract DNS/SNI with `tshark`, and pipe JSONL into `agentsonar classify`.
- **Expect weaker results from router-only data.** You will see domains and traffic shape, but process names will be blank/PID 0. You also miss traffic hidden by encrypted DNS, ECH, VPNs, or clients that bypass visible DNS.

Treat the SQLite event database and overrides as sensitive telemetry because they reveal local applications and contacted domains.

Verification performed:

- `go test ./...` passed.
- `go test -race ./...` passed.
- `go vet ./...` passed.
- `govulncheck` was not installed locally, so dependency vulnerability scanning was not performed.

---

**Attribution:** knostic/AgentSonar, no license specified
