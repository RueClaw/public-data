# NVIDIA Personal AI Router (NVIDIA/Personal-AI-Router)

**Repo:** https://github.com/NVIDIA/Personal-AI-Router  
**License:** Apache-2.0. Reusable with attribution.  
**Reviewed:** 2026-09-05  
**Stack:** Go services, Electron, React, TypeScript, Ollama, LM Studio, mDNS, JSON-RPC, mutual TLS  
**What it is:** NVIDIA Personal AI Router, or PAIR, is a LAN-first local inference router that lets multiple paired computers present Ollama-compatible and OpenAI-compatible endpoints while routing independent requests to eligible nodes.

---

## Verdict

⚠️ **Interesting, but pilot-only until the dependency and local test failures settle.** The architecture is exactly the right shape for small local inference clusters: peer-to-peer nodes, loopback client endpoints, mTLS between paired machines, model-aware routing, failover, engine management, and desktop plus terminal interfaces. The caveats are real: this is a fresh 0.1.1 repo, production desktop audit reports high-severity `js-yaml` and `undici` advisories, and local Go validation found service test failures on macOS.

---

## What It Is

PAIR turns several local-network machines into a single place for AI applications to send requests. A local app still talks to `localhost` using an Ollama-compatible or OpenAI-compatible API; PAIR's proxy then chooses a paired node that is reachable, has the requested engine running, and advertises the requested model.

It does not pool GPU memory, shard a model, split one inference request across machines, or move a running request. The unit of work is one whole independent request. That makes PAIR a throughput and convenience router, not a distributed inference engine.

The project ships a desktop app, a terminal interface, installers, and a set of Go background services. The services own discovery, pairing, trust, node info, proxying, engine lifecycle, workload replication, errors, settings, scheduling, and model inventory.

## Stack

| Layer | Tech |
|-------|------|
| Desktop | Electron, React 19, TypeScript, Vite, Zustand, NVIDIA UI foundations |
| Backend services | Go 1.25+, thirteen binaries, pure Go/no cgo |
| IPC/control | Newline-delimited JSON-RPC 2.0 over stdio, Unix sockets, or Windows named pipes |
| Discovery | mDNS `_nvpair-node._tcp`, manual-node fallback |
| Inference proxies | Ollama-compatible proxy, LM Studio/OpenAI-compatible proxy |
| Cluster trust | EAP-NOOB-style pairing, six-digit PIN bootstrap, pinned certificates, mutual TLS |
| Scheduling | Model eligibility gate plus pending-work and coarse GPU-pressure priority |
| Packaging | Windows `.exe`, Linux `.deb`, macOS `.dmg`, signed releases according to docs |

## Key Features

### Local Endpoint Compatibility

PAIR tries to preserve existing client configuration. Local applications talk to loopback endpoints that look like Ollama or OpenAI-compatible LM Studio APIs. When possible, PAIR takes the usual engine port and moves the engine behind the proxy instead of asking every client to change.

### Peer-To-Peer Cluster Model

There is no central controller. Every machine is a node, every node can route requests, and membership is symmetric. A workstation can use the whole cluster by becoming a node even if it does not run an engine itself.

### Model-Aware Routing

Routing starts with a hard capability gate. A node is eligible only if its current inventory advertises the requested model for the requested engine. Within eligible nodes, the proxy follows manual selection if present, then scheduler priority, then deterministic node ID order.

### mTLS For Cluster Inference

The proxies expose two personalities on one port. Plaintext HTTP is accepted only from loopback clients; LAN peer traffic uses mutual TLS after pairing. Non-loopback plaintext requests are refused rather than becoming an open LAN relay.

### Engine And Model Management

`nvpair-engine-manager` can detect, install, start, stop, update, and uninstall supported engines, plus list/pull/delete models. It adopts already-running engines rather than killing or moving unknown processes.

### Desktop And Terminal Interfaces

The Electron UI drives the same broker/services as the terminal interface. The terminal interface is intentionally useful for headless nodes, though the docs say it cannot yet do everything the desktop app can.

## Architecture

The service tree builds thirteen Go binaries. `nvpair-ui-broker` is the parent process for the desktop app and supervises workers such as `ollama-proxy`, `lmstudio-proxy`, `nvpair-node-scanner`, `nvpair-engine-manager`, `nvpair-cluster-manager`, `nvpair-node-settings`, `nvpair-workload-manager`, `nvpair-errors`, and `nvpair-job-scheduler`.

The desktop renderer never talks to Go workers directly. It calls a typed preload bridge; Electron main speaks JSON-RPC to the broker; the broker relays commands to supervised workers and events back up to the UI.

The data plane is separate from that control plane. Inference HTTP enters the local proxy, which chooses a failover list of eligible nodes, forwards the whole request to one node, and streams the response back. Peer inference ingress goes through mTLS and is forwarded to that peer's local engine rather than being routed onward again.

The scheduler is deliberately simple. It combines pending routed work with a coarse 0-3 pressure score based on busiest-GPU utilization. It does not account for GPU model, VRAM, token count, model warmness, latency, or external engine load except indirectly through GPU pressure.

Security posture is unusually explicit for a young local tool. The docs call out low-entropy PIN limits, unauthenticated telemetry exposure on the subnet, loopback-only plaintext proxy access, worker authority under the user account, sensitive local settings/logs/cluster keys, and the need for network trust. That candor is a plus.

## Comparison

| Aspect | PAIR | Ollama Alone | LM Studio Alone | Full Serving Cluster |
|--------|------|--------------|-----------------|----------------------|
| Primary job | Route local requests across paired LAN nodes | Serve local models on one machine | Desktop/local model serving | Serve models through managed distributed infrastructure |
| Client surface | Ollama and OpenAI-compatible local endpoints | Ollama API | OpenAI-compatible local API | Usually custom/API gateway |
| Multi-node behavior | Whole-request routing and failover | None by default | None by default | Often load balancing, autoscaling, scheduling |
| Trust model | Pairing plus mTLS for peer traffic | Local engine config | Local engine config | Usually identity/IAM/network policy |
| Best fit | Small trusted LAN with multiple capable machines | Single-node local inference | Single-node desktop model use | Production or shared multi-tenant serving |

PAIR sits in a useful middle ground: more structured than pointing tools at one desktop engine, much lighter than standing up a production inference platform.

## Self-Hosting Notes

The recommended path is a released installer from GitHub Releases: Windows `.exe`, Linux `.deb`, or macOS `.dmg`. Source builds require Go 1.25+, Node >=25.5 for the desktop app, npm, and `jq` for service build scripts.

Validation on 2026-09-05:

```text
desktop npm install
desktop npm run typecheck
desktop npm test
desktop npm audit --omit=dev
service modules: go test ./...
services/tests: go test -timeout 120s ./...
```

Results:

- Desktop typecheck passed.
- Desktop Vitest unit tests passed: 208 tests across 37 files.
- Desktop production audit failed with high-severity `js-yaml` and `undici` advisories; full audit reported 10 advisories including critical `tar` in tooling.
- Most Go modules passed, but `nvpair-engine-manager` failed `TestUninstallTerminatesRunningInstance` locally and `ollama-proxy` failed `TestAliasSelfTargetMatchesBoundLoopbackAddressNotPortAlone` because `127.0.0.2` could not bind on this macOS host.
- Cross-process service tests timed out at 120s in `TestScannerEvictsRecordSupersededAtItsAddress`.

Treat this as a lab pilot, not a quiet install on a sensitive network. Pair only trusted machines, keep it on a trusted LAN/VLAN, and patch dependency advisories before relying on the desktop package in higher-risk environments.

---

**Attribution:** NVIDIA/Personal-AI-Router, Apache-2.0
