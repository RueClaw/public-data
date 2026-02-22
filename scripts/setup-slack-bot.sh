#!/usr/bin/env bash
# setup-slack-bot.sh — Interactive Slack bot setup
# Creates a Slack app with Socket Mode, generates tokens, and saves config.
#
# Prerequisites: A browser (opens Slack API portal)
# Output: Bot/app tokens saved to ~/.openclaw/bots/<name>/slack.env

set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${CYAN}${BOLD}  Slack Bot Setup${RESET}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════${RESET}"
echo

# Step 1: Name
read -rp "Bot name (e.g. 'anek', 'rue'): " BOT_NAME
BOT_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
BOT_DIR="$HOME/.openclaw/bots/$BOT_NAME"
mkdir -p "$BOT_DIR"

echo
echo -e "${BOLD}Step 1: Create the App${RESET}"
echo -e "${DIM}Opening Slack API portal...${RESET}"
echo
echo "  1. Click ${BOLD}Create New App${RESET}"
echo "  2. Choose ${BOLD}From scratch${RESET}"
echo "  3. Name it: ${BOLD}$BOT_NAME${RESET}"
echo "  4. Select the workspace to install to"
echo "  5. Click ${BOLD}Create App${RESET}"
echo
open "https://api.slack.com/apps" 2>/dev/null || echo "  → Go to: https://api.slack.com/apps"
read -rp "Press Enter when the app is created..."

echo
echo -e "${BOLD}Step 2: Enable Socket Mode${RESET}"
echo
echo "  1. In the left sidebar, click ${BOLD}Socket Mode${RESET}"
echo "  2. Toggle ${BOLD}Enable Socket Mode${RESET} ON"
echo "  3. Give the app-level token a name (e.g. '${BOT_NAME}-socket')"
echo "  4. Click ${BOLD}Generate${RESET}"
echo "  5. Copy the token (starts with ${BOLD}xapp-${RESET})"
echo
read -rp "Paste App-Level Token (xapp-...): " APP_TOKEN

echo
echo -e "${BOLD}Step 3: Subscribe to Events${RESET}"
echo
echo "  1. In the left sidebar, click ${BOLD}Event Subscriptions${RESET}"
echo "  2. Toggle ${BOLD}Enable Events${RESET} ON"
echo "  3. Under ${BOLD}Subscribe to bot events${RESET}, add:"
echo "     • ${BOLD}message.channels${RESET}    (messages in public channels)"
echo "     • ${BOLD}message.groups${RESET}      (messages in private channels)"
echo "     • ${BOLD}message.im${RESET}          (direct messages)"
echo "     • ${BOLD}message.mpim${RESET}        (group DMs)"
echo "     • ${BOLD}app_mention${RESET}         (when @mentioned)"
echo "  4. Click ${BOLD}Save Changes${RESET}"
echo
read -rp "Press Enter when events are configured..."

echo
echo -e "${BOLD}Step 4: Set Bot Permissions (OAuth Scopes)${RESET}"
echo
echo "  1. In the left sidebar, click ${BOLD}OAuth & Permissions${RESET}"
echo "  2. Under ${BOLD}Scopes → Bot Token Scopes${RESET}, add:"
echo "     • ${BOLD}app_mentions:read${RESET}"
echo "     • ${BOLD}channels:history${RESET}"
echo "     • ${BOLD}channels:read${RESET}"
echo "     • ${BOLD}chat:write${RESET}"
echo "     • ${BOLD}groups:history${RESET}"
echo "     • ${BOLD}groups:read${RESET}"
echo "     • ${BOLD}im:history${RESET}"
echo "     • ${BOLD}im:read${RESET}"
echo "     • ${BOLD}im:write${RESET}"
echo "     • ${BOLD}mpim:history${RESET}"
echo "     • ${BOLD}mpim:read${RESET}"
echo "     • ${BOLD}reactions:read${RESET}"
echo "     • ${BOLD}reactions:write${RESET}"
echo "     • ${BOLD}users:read${RESET}"
echo "     • ${BOLD}files:write${RESET}         (for sending images/files)"
echo "     • ${BOLD}pins:write${RESET}          (optional: pin messages)"
echo
read -rp "Press Enter when scopes are added..."

echo
echo -e "${BOLD}Step 5: Install to Workspace${RESET}"
echo
echo "  1. Still on ${BOLD}OAuth & Permissions${RESET}, scroll up"
echo "  2. Click ${BOLD}Install to Workspace${RESET} (or Reinstall if already installed)"
echo "  3. Review permissions and click ${BOLD}Allow${RESET}"
echo "  4. Copy the ${BOLD}Bot User OAuth Token${RESET} (starts with ${BOLD}xoxb-${RESET})"
echo
read -rp "Paste Bot Token (xoxb-...): " BOT_TOKEN

echo
echo -e "${BOLD}Step 6: Invite to Channels${RESET}"
echo
echo "  The bot needs to be invited to each channel it should participate in:"
echo "  In Slack, type in each channel:"
echo "    ${BOLD}/invite @${BOT_NAME}${RESET}"
echo
read -rp "Press Enter when done (you can always invite to more channels later)..."

# Save config
cat > "$BOT_DIR/slack.env" << EOF
# Slack Bot: $BOT_NAME
# Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
SLACK_BOT_TOKEN=$BOT_TOKEN
SLACK_APP_TOKEN=$APP_TOKEN
EOF
chmod 600 "$BOT_DIR/slack.env"

echo
echo -e "${GREEN}${BOLD}✅ Slack bot '$BOT_NAME' is set up!${RESET}"
echo
echo -e "  Config saved: ${DIM}$BOT_DIR/slack.env${RESET}"
echo
echo -e "  ${BOLD}To use in OpenClaw config:${RESET}"
echo -e "  channels.slack.botToken = \"$BOT_TOKEN\""
echo -e "  channels.slack.appToken = \"$APP_TOKEN\""
echo -e "  channels.slack.mode = \"socket\""
echo
echo -e "${DIM}Tip: To add the bot to more channels later: /invite @${BOT_NAME}${RESET}"
