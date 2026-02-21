# OpenClaw: Local Caddy Setup with Self-Signed TLS

Set up Caddy as a local reverse proxy for OpenClaw (or any service) with HTTPS using a self-signed certificate. Designed for LAN-to-LAN encryption where a front-facing Caddy (with Let's Encrypt) proxies to your local Caddy over HTTPS.

## Why?

- Encrypt traffic between reverse proxy and backend on your LAN
- Avoid "Client sent HTTP request to HTTPS server" errors
- Simple self-signed TLS without needing `caddy trust` or sudo
- Standard directory layout for easy management

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

## 2. Create Base Directory

Everything lives under `~/caddy`:

```bash
CADDY_BASE="${HOME}/caddy"
mkdir -p "${CADDY_BASE}"/{certs,logs,data,config}
```

Directory layout:
```
~/caddy/
├── Caddyfile          # Configuration
├── certs/             # Self-signed certificates
│   ├── local.crt
│   └── local.key
├── logs/              # Access and error logs
│   ├── access.log
│   └── caddy.log
├── data/              # Caddy runtime data
└── config/            # Caddy auto-config
```

## 3. Generate Self-Signed Certificate

```bash
CADDY_BASE="${HOME}/caddy"
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')

openssl req -x509 -newkey rsa:2048 \
    -keyout "${CADDY_BASE}/certs/local.key" \
    -out "${CADDY_BASE}/certs/local.crt" \
    -days 3650 -nodes \
    -subj "/CN=$(hostname)-local" \
    -addext "subjectAltName=IP:${LOCAL_IP},IP:127.0.0.1"

echo "Certificate generated for ${LOCAL_IP}"
```

**Note:** No need to run `caddy trust` — the front-facing Caddy uses `tls_insecure_skip_verify` to connect to this self-signed cert. This is fine for trusted LAN traffic.

## 4. Create Caddyfile

```bash
CADDY_BASE="${HOME}/caddy"
cat > "${CADDY_BASE}/Caddyfile" << 'EOF'
{
    # Logging
    log {
        output file {env.HOME}/caddy/logs/caddy.log {
            roll_size 10mb
            roll_keep 5
            roll_keep_for 168h
        }
        level INFO
    }

    # Store data in our base directory
    storage file_system {
        root {env.HOME}/caddy/data
    }

    # Disable admin API if not needed (security)
    # admin off
}

https://:9443 {
    tls {env.HOME}/caddy/certs/local.crt {env.HOME}/caddy/certs/local.key

    log {
        output file {env.HOME}/caddy/logs/access.log {
            roll_size 10mb
            roll_keep 5
            roll_keep_for 168h
        }
        format json
    }

    reverse_proxy localhost:18789
}
EOF
```

### What this does:
- Listens on `:9443` with your self-signed TLS cert
- Reverse proxies to OpenClaw gateway on `localhost:18789`
- Logs to `~/caddy/logs/` with rotation (10MB, keep 5 files, 7 days)
- Access logs in JSON format (easy to parse/search)
- Stores runtime data in `~/caddy/data/`

### Multiple services:

```caddy
https://:9443 {
    tls {env.HOME}/caddy/certs/local.crt {env.HOME}/caddy/certs/local.key

    log {
        output file {env.HOME}/caddy/logs/access.log {
            roll_size 10mb
            roll_keep 5
            roll_keep_for 168h
        }
        format json
    }

    reverse_proxy localhost:18789
}

https://:9444 {
    tls {env.HOME}/caddy/certs/local.crt {env.HOME}/caddy/certs/local.key

    log {
        output file {env.HOME}/caddy/logs/access-app2.log {
            roll_size 10mb
            roll_keep 5
            roll_keep_for 168h
        }
        format json
    }

    reverse_proxy localhost:3000
}
```

### Custom ports (change the backend):

Just change the `reverse_proxy` target to your service's port:

```caddy
reverse_proxy localhost:3000    # Web app
reverse_proxy localhost:8000    # API server
reverse_proxy localhost:18789   # OpenClaw gateway
```

## 5. Run Caddy

```bash
CADDY_BASE="${HOME}/caddy"

# Foreground (see logs in terminal)
caddy run --config "${CADDY_BASE}/Caddyfile"

# Background (daemon)
caddy start --config "${CADDY_BASE}/Caddyfile"

# Stop background daemon
caddy stop

# Reload config without restart
caddy reload --config "${CADDY_BASE}/Caddyfile"
```

## 6. Run as a Service

### macOS (launchd)

```bash
CADDY_BASE="${HOME}/caddy"
CADDY_BIN=$(which caddy)

cat > ~/Library/LaunchAgents/com.caddy.local.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.caddy.local</string>
    <key>ProgramArguments</key>
    <array>
        <string>${CADDY_BIN}</string>
        <string>run</string>
        <string>--config</string>
        <string>${CADDY_BASE}/Caddyfile</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${CADDY_BASE}/logs/launchd-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${CADDY_BASE}/logs/launchd-stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.caddy.local.plist
echo "Caddy service loaded. Logs at ${CADDY_BASE}/logs/"
```

### Linux (systemd)

```bash
CADDY_BASE="${HOME}/caddy"
CADDY_BIN=$(which caddy)

# Create user service
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/caddy-local.service << EOF
[Unit]
Description=Caddy Local HTTPS Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${CADDY_BIN} run --config ${CADDY_BASE}/Caddyfile
ExecReload=${CADDY_BIN} reload --config ${CADDY_BASE}/Caddyfile
TimeoutStopSec=5s
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable caddy-local
systemctl --user start caddy-local
echo "Caddy service started. Logs at ${CADDY_BASE}/logs/"
```

## 7. Verify

```bash
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')

# Test HTTPS (self-signed, use -k to skip cert verification)
curl -sk https://${LOCAL_IP}:9443/
echo

# Check certificate
openssl s_client -connect ${LOCAL_IP}:9443 </dev/null 2>&1 | grep subject

# Check logs
tail -f ~/caddy/logs/access.log

# Check Caddy is running
caddy version
```

## 8. Front-Facing Caddy Config (on your reverse proxy)

On the machine running your public-facing Caddy (e.g., with Let's Encrypt certs), add:

```caddy
@myservice host myservice.example.com
handle @myservice {
    reverse_proxy https://192.168.x.x:9443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

### With LAN-only ACL (recommended for sensitive services):

```caddy
@myservice host myservice.example.com
handle @myservice {
    @blocked not remote_ip 192.168.0.0/22
    respond @blocked 403

    reverse_proxy https://192.168.x.x:9443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

**Important:** Don't configure `trusted_proxies` unless you explicitly need it — without it, `remote_ip` uses the real TCP peer address and ignores `X-Forwarded-For` headers, preventing XFF spoofing.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `bind: permission denied` on port 9443 | Check nothing else is using the port: `lsof -i :9443` |
| `curl: (35) SSL handshake error` | Make sure you're using the self-signed cert, not `tls internal` |
| `502 Bad Gateway` from front Caddy | Backend Caddy not running, or wrong port |
| `400 Client sent HTTP to HTTPS` | Front Caddy using `http://` instead of `https://` to reach backend |
| Logs not appearing | Check `~/caddy/logs/` exists and is writable |
| LaunchAgent keeps respawning old config | `launchctl unload` the plist, kill caddy, then `launchctl load` again |
| `caddy trust` fails (no sudo) | Not needed — use self-signed cert + `tls_insecure_skip_verify` on the front end |

## Log Analysis

```bash
# Recent access logs (JSON, one per line)
tail -20 ~/caddy/logs/access.log | jq .

# Filter by status code
cat ~/caddy/logs/access.log | jq 'select(.status >= 400)'

# Filter by host
cat ~/caddy/logs/access.log | jq 'select(.request.host == "myservice.example.com")'

# Caddy process logs
tail -50 ~/caddy/logs/caddy.log
```

## Quick Setup Script

Copy-paste this to set up everything in one go:

```bash
#!/bin/bash
set -e

CADDY_BASE="${HOME}/caddy"
BACKEND_PORT="${1:-18789}"
LISTEN_PORT="${2:-9443}"
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')

echo "Setting up Caddy: https://${LOCAL_IP}:${LISTEN_PORT} -> localhost:${BACKEND_PORT}"

# Install
which caddy >/dev/null 2>&1 || { echo "Installing Caddy..."; brew install caddy 2>/dev/null || sudo apt install caddy; }

# Directories
mkdir -p "${CADDY_BASE}"/{certs,logs,data,config}

# Certificate
openssl req -x509 -newkey rsa:2048 \
    -keyout "${CADDY_BASE}/certs/local.key" \
    -out "${CADDY_BASE}/certs/local.crt" \
    -days 3650 -nodes \
    -subj "/CN=$(hostname)-local" \
    -addext "subjectAltName=IP:${LOCAL_IP},IP:127.0.0.1" 2>/dev/null

# Caddyfile
cat > "${CADDY_BASE}/Caddyfile" << CADDYEOF
{
    log {
        output file ${CADDY_BASE}/logs/caddy.log {
            roll_size 10mb
            roll_keep 5
        }
        level INFO
    }
    storage file_system {
        root ${CADDY_BASE}/data
    }
}

https://:${LISTEN_PORT} {
    tls ${CADDY_BASE}/certs/local.crt ${CADDY_BASE}/certs/local.key
    log {
        output file ${CADDY_BASE}/logs/access.log {
            roll_size 10mb
            roll_keep 5
        }
        format json
    }
    reverse_proxy localhost:${BACKEND_PORT}
}
CADDYEOF

echo "Done! Run: caddy run --config ${CADDY_BASE}/Caddyfile"
echo "Test: curl -sk https://${LOCAL_IP}:${LISTEN_PORT}/"
```

Usage:
```bash
# Default: proxy 9443 -> 18789 (OpenClaw)
./setup-caddy.sh

# Custom: proxy 9443 -> 3000 (web app)
./setup-caddy.sh 3000

# Custom ports: proxy 8443 -> 3000
./setup-caddy.sh 3000 8443
```

---

*Part of [public-data](https://github.com/Bluesun-Networks/public-data) — useful scripts and patterns for OpenClaw and home lab setups.*
