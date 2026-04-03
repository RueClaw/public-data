# NetWatch — Review

**Repo:** https://github.com/matthart1983/netwatch  
**Crate:** netwatch-tui v0.9.0  
**Author:** Matt Hartley (MIT)  
**Stars:** ~414 (at review time)  
**License:** MIT ✅  
**Stack:** Rust / Ratatui / libpcap / Tokio  
**Reviewed:** 2026-04-03  
**Rating:** ⭐⭐⭐⭐ — Seriously good tool; rough edges, high ceiling

---

## What It Is

A Rust TUI network diagnostics tool that genuinely tries to replace *several* terminal tools at once:

- **iftop/bandwhich** — interface bandwidth with sparklines
- **netstat/ss** — connections with *process attribution* (per-connection PID+name)
- **tshark** — live packet capture with protocol decode (DNS, TLS SNI, HTTP, ICMP, DHCP, NTP, ARP, 25+ labels)
- **mtr/traceroute** — topology view with ASCII map and traceroute
- **custom** — "Flight Recorder" (rolling 5-min capture, freeze on incident, export bundle)

Single binary, zero config, degrades gracefully without root.

---

## Architecture

- **`src/app.rs`** — 1,595 lines. Monolithic app state + event loop + input handling. Works but is a contributor barrier.
- **`src/collectors/`** — Individual data collectors: connections, packets, health probes, traffic, GeoIP, traceroute, whois, incident capture, process bandwidth
- **`src/ui/`** — Ratatui rendering per tab
- **`src/platform/`** — macOS (`netstat -ib`, `lsof`) and Linux (`/proc/net/tcp`) implementations
- **`src/ebpf/`** — `conn_tracker.rs` + `rtt_monitor.rs`, feature-gated (`--features ebpf`), Linux-only

Notable: the repo includes its own `CRITICAL-ANALYSIS.md` — the author (or a contributor) has done an honest self-assessment. Many of its recommendations have already been acted on (v0.8.1 removed the AI Insights tab, v0.9.0 added the Flight Recorder).

---

## What's Genuinely Good

### Process Attribution (Killer Feature)
No other Rust TUI does this: per-connection process name + PID + live bandwidth *per process*. Bandwhich does process-level bandwidth but not connection-level detail. NetWatch does both. This alone justifies the install on any workstation.

### Dashboard UX
Bandwidth sparklines per interface + top connections + gateway/DNS health probes + latency heatmap — all zero-config on first launch. Best "first 5 seconds" of any tool in this space.

### Packet Capture in a TUI
Wireshark-style deep decode (DNS queries/types, TLS SNI, HTTP method+path+status, TCP stream reassembly) is rare in a terminal tool. Most TUI packet tools stop at "bytes in/out." The display filter syntax (`tcp and port 443`, `contains "hello"`) is familiar to anyone who's used Wireshark.

### Flight Recorder (v0.9.0)
`Shift+R` arms a rolling 5-min window; `Shift+F` freezes it; `Shift+E` exports a self-contained incident bundle: `summary.md`, `packets.pcap`, `connections.json`, `health.json`, `dns.json`, `alerts.json`. This is a genuinely useful feature for catching transient failures — SREs will love it.

### Topology View
ASCII network map with health indicators and built-in traceroute. No competitor in this space has this. Great screenshot bait, also actually useful.

---

## Known Weaknesses (From the Repo's Own Analysis)

The `CRITICAL-ANALYSIS.md` file is unusually honest — it calls out:
- **127 `unwrap()` calls** in production code (panic risk on unpredictable network data)
- **No integration tests** (`tests/` directory doesn't exist, only unit tests)
- **`app.rs` is still a 1,595-line god object** — needs `state.rs` / `input.rs` / `update.rs` split
- **Windows support is a lie** — README says cross-platform but `platform/` has only `linux.rs` and `macos.rs`
- **eBPF is half-shipped** — exists, feature-gated, no UI surface for eBPF-specific data

From my own look:
- **`collectors/insights.rs` still exists** (629 lines) despite the AI Insights tab being removed in v0.8.1. Dead code. The tab is gone but the collector wasn't cleaned up.
- **Dependencies are lean** — no massive dep tree, `ureq` for HTTP, `pcap` for capture, `maxminddb` for GeoIP. Good hygiene.

---

## Extractable Patterns

**1. Flight Recorder Pattern**
The concept of: arm a rolling time-window buffer → freeze on event → export a self-contained evidence bundle — is directly reusable for any agent that needs "what just happened" capture. Relevant to our own agent observability work.

**2. Graceful Degradation by Privilege**
Feature matrix per privilege level (root vs non-root) with clear "you need root for this" messaging instead of crashes. Clean pattern for tools with optional elevated capabilities.

**3. Self-Assessment Document**
`CRITICAL-ANALYSIS.md` is a fascinating artifact — the author has written an honest teardown of their own tool with prioritized recommendations. Several of them are already being acted on. This is a good open-source project hygiene practice worth noting.

**4. Collector Architecture**
Clean separation between data collectors (`src/collectors/`) and UI rendering (`src/ui/`). Each collector is independent and async via Tokio. Solid template for any TUI data tool.

---

## Verdict

This is a **serious tool** that's actively improving. The Flight Recorder is a genuinely novel feature. Process attribution at the connection level is the best in class. The main issues are code quality (unwraps, god object app.rs) and scope creep (dead collector code, half-built eBPF).

**For homelab use:** Install `sudo netwatch` on `nautilus` or `chiton`. The flight recorder will be useful the next time a weird flap happens.

**For harvest:** The Flight Recorder pattern and the Collector/UI architecture separation are both worth extracting.

Source: matthart1983/netwatch (MIT). Review by Rue.
