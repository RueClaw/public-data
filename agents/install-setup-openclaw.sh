#!/usr/bin/env bash
# install-setup-openclaw.sh
# Sets up a new OpenClaw installation with the secure bootstrap guide.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/RueClaw/public-data/main/agents/install-setup-openclaw.sh | bash
#   -- or --
#   bash install-setup-openclaw.sh
#
# What this does:
#   1. Installs OpenClaw via npm (or skips if already installed)
#   2. Creates the workspace directory
#   3. Places the secure bootstrap guide as BOOTSTRAP.md
#   4. Prints next steps
#
# Requirements: Node.js 18+, npm

set -euo pipefail

BOOTSTRAP_URL="https://raw.githubusercontent.com/RueClaw/public-data/main/agents/openclaw-secure-bootstrap-guide.md"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[•]${RESET} $*"; }
success() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }

echo ""
echo "  OpenClaw Secure Setup"
echo "  ─────────────────────"
echo ""

# ── 1. Check Node.js ──────────────────────────────────────────────────────────
info "Checking Node.js..."
if ! command -v node &>/dev/null; then
  echo ""
  warn "Node.js not found. Install it first:"
  echo "    https://nodejs.org/  (or: brew install node)"
  exit 1
fi
NODE_VER=$(node --version)
success "Node.js $NODE_VER found"

# ── 2. Install OpenClaw ───────────────────────────────────────────────────────
info "Checking for OpenClaw..."
if command -v openclaw &>/dev/null; then
  OC_VER=$(openclaw --version 2>/dev/null || echo "unknown")
  success "OpenClaw already installed ($OC_VER) — skipping install"
else
  info "Installing OpenClaw via npm (global)..."
  npm install -g openclaw
  success "OpenClaw installed"
fi

# ── 3. Create workspace ───────────────────────────────────────────────────────
info "Setting up workspace at $WORKSPACE ..."
mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/context/slack/threads"
mkdir -p "$WORKSPACE/context/discord/channels"
mkdir -p "$WORKSPACE/scripts"
success "Workspace directories created"

# ── 4. Place the secure bootstrap guide as BOOTSTRAP.md ──────────────────────
BOOTSTRAP_DEST="$WORKSPACE/BOOTSTRAP.md"

if [[ -f "$BOOTSTRAP_DEST" ]]; then
  warn "BOOTSTRAP.md already exists — not overwriting"
else
  info "Downloading secure bootstrap guide..."
  if command -v curl &>/dev/null; then
    curl -fsSL "$BOOTSTRAP_URL" -o "$BOOTSTRAP_DEST"
  elif command -v wget &>/dev/null; then
    wget -q "$BOOTSTRAP_URL" -O "$BOOTSTRAP_DEST"
  else
    warn "Neither curl nor wget found — writing bootstrap inline"
    # Minimal fallback if no download tool
    cat > "$BOOTSTRAP_DEST" << 'FALLBACK'
# Bootstrap

You just woke up. Read AGENTS.md, SOUL.md, and USER.md if they exist.
Then visit: https://github.com/RueClaw/public-data/blob/main/agents/openclaw-secure-bootstrap-guide.md
FALLBACK
  fi
  success "BOOTSTRAP.md placed at $BOOTSTRAP_DEST"
fi

# ── 5. Scaffold minimal workspace files if not present ───────────────────────
info "Scaffolding core workspace files..."

if [[ ! -f "$WORKSPACE/AGENTS.md" ]]; then
  cat > "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md - Your Workspace

## Every Session

Before doing anything else:
1. Read `SOUL.md` — this is who you are
2. Read `USER.md` — this is who you're helping
3. Read `memory/YYYY-MM-DD.md` (today) for recent context

## Memory

- **Daily notes:** `memory/YYYY-MM-DD.md` — raw logs of what happened
- **Long-term:** `MEMORY.md` — curated memories

## Safety

- Don't exfiltrate private data. Ever.
- Never output credential values in chat. Ever.
- Don't run destructive commands without asking.
- `trash` > `rm`
- When in doubt, ask.
EOF
  success "AGENTS.md created"
fi

if [[ ! -f "$WORKSPACE/SOUL.md" ]]; then
  cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - Who You Are

*Fill this in during your first conversation. Make it yours.*

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" — just help.

**Have opinions.** You're allowed to disagree, prefer things, find stuff amusing or boring.

**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. *Then* ask.

**Earn trust through competence.** Be careful with external actions. Be bold with internal ones.

## Boundaries

- Private things stay private.
- Never output credential values in any chat surface.
- When in doubt, ask before acting externally.

## Vibe

Be the assistant you'd actually want to talk to.
EOF
  success "SOUL.md created"
fi

if [[ ! -f "$WORKSPACE/USER.md" ]]; then
  cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - About Your Human

*Learn about the person you're helping. Update this as you go.*

- **Name:** (fill in)
- **Timezone:** (fill in)
- **Notes:** (fill in)
EOF
  success "USER.md created"
fi

if [[ ! -f "$WORKSPACE/MEMORY.md" ]]; then
  cat > "$WORKSPACE/MEMORY.md" << 'EOF'
# MEMORY.md - Long-Term Memory

*Curated memories. The stuff worth keeping.*

*Private — only load in direct/main sessions, never in group chats.*

---

## First Boot

(Write something here after your first session.)
EOF
  success "MEMORY.md created"
fi

# Create today's daily note stub
TODAY=$(date +%Y-%m-%d)
DAILY="$WORKSPACE/memory/$TODAY.md"
if [[ ! -f "$DAILY" ]]; then
  cat > "$DAILY" << EOF
# $TODAY

## Session Notes

- OpenClaw installed and bootstrapped

## TODO

- Complete initial setup with your human
- Fill in USER.md, SOUL.md, IDENTITY.md
EOF
  success "Daily note created: memory/$TODAY.md"
fi

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────"
success "Setup complete!"
echo ""
echo "  Next steps:"
echo ""
echo "  1. Run the OpenClaw setup wizard:"
echo "       openclaw setup"
echo ""
echo "  2. Configure your first channel (Discord, Slack, iMessage, etc.):"
echo "       openclaw channel add"
echo ""
echo "  3. Start the gateway:"
echo "       openclaw gateway start"
echo ""
echo "  4. Talk to your agent — it will read BOOTSTRAP.md on first boot"
echo "     and walk through secure self-setup automatically."
echo ""
echo "  Workspace: $WORKSPACE"
echo "  Bootstrap: $BOOTSTRAP_DEST"
echo ""
echo "  Docs: https://docs.openclaw.ai"
echo "  Secure bootstrap guide: https://github.com/RueClaw/public-data/blob/main/agents/openclaw-secure-bootstrap-guide.md"
echo ""
