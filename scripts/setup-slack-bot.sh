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

printf "${CYAN}${BOLD}═══════════════════════════════════════${RESET}\n"
printf "${CYAN}${BOLD}  Slack Bot Setup${RESET}\n"
printf "${CYAN}${BOLD}═══════════════════════════════════════${RESET}\n"
echo

# Step 1: Name
read -rp "Bot name (e.g. 'anek', 'rue'): " BOT_NAME
BOT_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
BOT_DIR="$HOME/.openclaw/bots/$BOT_NAME"
mkdir -p "$BOT_DIR"

echo
printf "${BOLD}Step 1: Create the App${RESET}\n"
printf "${DIM}Opening Slack API portal...${RESET}\n"
echo
printf "  1. Click ${BOLD}Create New App${RESET}\n"
printf "  2. Choose ${BOLD}From scratch${RESET}\n"
printf "  3. Name it: ${BOLD}$BOT_NAME${RESET}\n"
echo "  4. Select the workspace to install to"
printf "  5. Click ${BOLD}Create App${RESET}\n"
echo
open "https://api.slack.com/apps" 2>/dev/null || echo "  → Go to: https://api.slack.com/apps"
read -rp "Press Enter when the app is created..."

echo
printf "${BOLD}Step 2: Enable Socket Mode${RESET}\n"
echo
printf "  1. In the left sidebar, click ${BOLD}Socket Mode${RESET}\n"
printf "  2. Toggle ${BOLD}Enable Socket Mode${RESET} ON\n"
printf "  3. Give the app-level token a name (e.g. '${BOT_NAME}-socket')\n"
printf "  4. Click ${BOLD}Generate${RESET}\n"
printf "  5. Copy the token (starts with ${BOLD}xapp-${RESET})\n"
echo
read -rp "Paste App-Level Token (xapp-...): " APP_TOKEN

echo
printf "${BOLD}Step 3: Subscribe to Events${RESET}\n"
echo
printf "  1. In the left sidebar, click ${BOLD}Event Subscriptions${RESET}\n"
printf "  2. Toggle ${BOLD}Enable Events${RESET} ON\n"
printf "  3. Under ${BOLD}Subscribe to bot events${RESET}, add:\n"
printf "     • ${BOLD}message.channels${RESET}    (messages in public channels)\n"
printf "     • ${BOLD}message.groups${RESET}      (messages in private channels)\n"
printf "     • ${BOLD}message.im${RESET}          (direct messages)\n"
printf "     • ${BOLD}message.mpim${RESET}        (group DMs)\n"
printf "     • ${BOLD}app_mention${RESET}         (when @mentioned)\n"
printf "  4. Click ${BOLD}Save Changes${RESET}\n"
echo
read -rp "Press Enter when events are configured..."

echo
printf "${BOLD}Step 4: Set Bot Permissions (OAuth Scopes)${RESET}\n"
echo
printf "  1. In the left sidebar, click ${BOLD}OAuth & Permissions${RESET}\n"
printf "  2. Under ${BOLD}Scopes → Bot Token Scopes${RESET}, add:\n"
printf "     • ${BOLD}app_mentions:read${RESET}\n"
printf "     • ${BOLD}channels:history${RESET}\n"
printf "     • ${BOLD}channels:read${RESET}\n"
printf "     • ${BOLD}chat:write${RESET}\n"
printf "     • ${BOLD}groups:history${RESET}\n"
printf "     • ${BOLD}groups:read${RESET}\n"
printf "     • ${BOLD}im:history${RESET}\n"
printf "     • ${BOLD}im:read${RESET}\n"
printf "     • ${BOLD}im:write${RESET}\n"
printf "     • ${BOLD}mpim:history${RESET}\n"
printf "     • ${BOLD}mpim:read${RESET}\n"
printf "     • ${BOLD}reactions:read${RESET}\n"
printf "     • ${BOLD}reactions:write${RESET}\n"
printf "     • ${BOLD}users:read${RESET}\n"
printf "     • ${BOLD}files:write${RESET}         (for sending images/files)\n"
printf "     • ${BOLD}pins:write${RESET}          (optional: pin messages)\n"
echo
read -rp "Press Enter when scopes are added..."

echo
printf "${BOLD}Step 5: Install to Workspace${RESET}\n"
echo
printf "  1. Still on ${BOLD}OAuth & Permissions${RESET}, scroll up\n"
printf "  2. Click ${BOLD}Install to Workspace${RESET} (or Reinstall if already installed)\n"
printf "  3. Review permissions and click ${BOLD}Allow${RESET}\n"
printf "  4. Copy the ${BOLD}Bot User OAuth Token${RESET} (starts with ${BOLD}xoxb-${RESET})\n"
echo
read -rp "Paste Bot Token (xoxb-...): " BOT_TOKEN

echo
printf "${BOLD}Step 6: Invite to Channels${RESET}\n"
echo
echo "  The bot needs to be invited to each channel it should participate in:"
echo "  In Slack, type in each channel:"
printf "    ${BOLD}/invite @${BOT_NAME}${RESET}\n"
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
printf "${GREEN}${BOLD}✅ Slack bot '$BOT_NAME' is set up!${RESET}\n"
echo
printf "  Config saved: ${DIM}$BOT_DIR/slack.env${RESET}\n"
echo
printf "  ${BOLD}To use in OpenClaw config:${RESET}\n"
printf "  channels.slack.botToken = \"$BOT_TOKEN\"\n"
printf "  channels.slack.appToken = \"$APP_TOKEN\"\n"
printf "  channels.slack.mode = \"socket\"\n"
echo
printf "${DIM}Tip: To add the bot to more channels later: /invite @${BOT_NAME}${RESET}\n"
