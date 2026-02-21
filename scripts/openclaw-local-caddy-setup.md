# OpenClaw: Local Caddy Setup with Custom Hostname

Set up Caddy as a local reverse proxy for OpenClaw with HTTPS, HTTP→HTTPS redirect, and a custom hostname.

## Why?

OpenClaw (and other local services) sometimes complain when they receive HTTP on an HTTPS port or vice versa. Caddy solves this cleanly:

- Automatic local HTTPS with its own CA
- HTTP→HTTPS redirect
- Custom local hostname instead of `localhost`
- Reverse proxy to any local service

## Prerequisites

- macOS or Linux
- [Homebrew](https://brew.sh/) (macOS) or [Caddy install docs](https://caddyserver.com/docs/install) (Linux)

## 1. Install Caddy

```bash
# macOS
brew install caddy

# Debian/Ubuntu
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

## 2. Add Custom Hostname to /etc/hosts

Pick a hostname for your local service. Example: `openclaw.local`

```bash
# Add to /etc/hosts (needs sudo)
echo "127.0.0.1 openclaw.local" | sudo tee -a /etc/hosts
```

You can use any hostname you like — `myagent.local`, `rue.local`, `anek.local`, etc.

## 3. Create Caddyfile

Create `~/Caddyfile` (or wherever you prefer):

```caddy
# HTTP → HTTPS redirect
http://openclaw.local {
    redir https://openclaw.local{uri} permanent
}

# HTTPS reverse proxy to OpenClaw gateway
https://openclaw.local {
    tls internal
    reverse_proxy localhost:18789
}
```

### What this does:
- `http://openclaw.local` (port 80) → redirects to `https://openclaw.local` (port 443)
- `https://openclaw.local` → reverse proxies to OpenClaw gateway on `localhost:18789`
- `tls internal` → Caddy generates a locally-trusted certificate using its built-in CA

### Custom ports (if 80/443 are taken):

```caddy
http://openclaw.local:9080 {
    redir https://openclaw.local:9443{uri} permanent
}

https://openclaw.local:9443 {
    tls internal
    reverse_proxy localhost:18789
}
```

### Multiple services:

```caddy
https://openclaw.local {
    tls internal
    reverse_proxy localhost:18789
}

https://vos.local {
    tls internal
    reverse_proxy localhost:8000
}

https://dmarc.local {
    tls internal
    reverse_proxy localhost:3000
}
```

Just add each hostname to `/etc/hosts` and add a block to the Caddyfile.

## 4. Trust Caddy's Local CA

This installs Caddy's root certificate into your system trust store so browsers and CLI tools accept the local HTTPS certs without warnings:

```bash
# macOS — adds to system keychain
caddy trust

# Linux — may need sudo
sudo caddy trust
```

You only need to do this once per machine.

## 5. Run Caddy

```bash
# Foreground (see logs)
caddy run --config ~/Caddyfile

# Background (daemon)
caddy start --config ~/Caddyfile

# Stop background daemon
caddy stop

# Reload config without restart
caddy reload --config ~/Caddyfile
```

## 6. (Optional) Run as a Service

### macOS (launchd)

```bash
# Create a plist
cat > ~/Library/LaunchAgents/com.caddy.server.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.caddy.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/caddy</string>
        <string>run</string>
        <string>--config</string>
        <string>/Users/YOUR_USERNAME/Caddyfile</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/caddy.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/caddy.err</string>
</dict>
</plist>
EOF

# Load it
launchctl load ~/Library/LaunchAgents/com.caddy.server.plist
```

### Linux (systemd)

Caddy installs a systemd unit by default. Just put your Caddyfile at `/etc/caddy/Caddyfile` and:

```bash
sudo systemctl enable caddy
sudo systemctl start caddy
```

## 7. Verify

```bash
# Should redirect to HTTPS
curl -I http://openclaw.local

# Should return 200 (or whatever your service returns)
curl https://openclaw.local

# Check Caddy is running
caddy version
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `bind: permission denied` on port 80/443 | Use custom ports (9080/9443) or run with sudo |
| Browser shows cert warning | Run `caddy trust` and restart browser |
| `curl: (60) SSL certificate problem` | Run `caddy trust` or use `curl -k` to skip verification |
| Hostname doesn't resolve | Check `/etc/hosts` has the entry |
| Service unreachable | Make sure the backend service is running on the configured port |
| Port already in use | Check with `lsof -i :443` and pick a different port |

## Notes

- Caddy's internal CA certs are stored in `~/.local/share/caddy/` (varies by OS)
- Each hostname gets its own certificate, auto-renewed
- `tls internal` is for local/dev use only — for public-facing services, use real domains and Caddy will auto-provision Let's Encrypt certs
- Caddy automatically handles HTTP/2 and HTTPS best practices

---

*Part of [public-data](https://github.com/Bluesun-Networks/public-data) — useful scripts and patterns for OpenClaw and home lab setups.*
