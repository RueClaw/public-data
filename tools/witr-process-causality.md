# witr — "Why Is This Running?"

**Source:** [pranshuparmar/witr](https://github.com/pranshuparmar/witr) (Apache 2.0)
**Install:** `brew install witr` or `curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash`

## What It Does

Answers "why is this running?" for any process. Traces the causal chain — not just PID/parent, but *which system* is responsible: launchd, systemd, cron, docker, supervisor, shell, etc.

```
$ witr --pid 73592
Target      : zsh
Process     : zsh (pid 73592) {forked}
Why It Exists :
  launchd (pid 1) → node (pid 81577) → zsh (pid 73592)
Source      : zsh (shell)
```

## Source Detection (from the code)

The interesting part is the detection chain in `internal/source/`:

1. **Container** — reads `/proc/<pid>/cgroup`, looks for docker/containerd/lxc markers
2. **Systemd** — checks `systemctl status <pid>`, unit files
3. **Launchd** (macOS) — maps to launchd services
4. **Cron** — checks if ancestor is cron daemon
5. **Supervisor** — supervisord, pm2, etc.
6. **Init** — sysvinit, OpenRC, BSD rc.d
7. **Shell** — fallback, traces through shell ancestry
8. **Network** — port binding detection

Each detector returns a `Source` with type, name, and details map. First match wins.

## Architecture Pattern

- `target/` — resolves what you're asking about (PID, port, name)
- `proc/` — builds process ancestry tree
- `source/` — detects *why* (the interesting part)
- `output/` — formats results

Clean separation: resolve target → build ancestry → detect source → format output.

## Useful For

- Debugging: "what started this random process?"
- Security: "why is this listening on port 8080?"
- Agent debugging: tracing spawned subprocesses back to their origin
