#!/usr/bin/env bash
# setup-discord-bot.sh — Interactive Discord bot setup
# Creates a Discord bot application, generates invite link, and saves the token.
#
# Prerequisites: A browser (opens Discord Developer Portal)
# Output: Bot token saved to ~/.openclaw/bots/<name>/discord.env

set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${CYAN}${BOLD}  Discord Bot Setup${RESET}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════${RESET}"
echo

# Step 1: Name
read -rp "Bot name (e.g. 'anek', 'rue'): " BOT_NAME
BOT_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
BOT_DIR="$HOME/.openclaw/bots/$BOT_NAME"
mkdir -p "$BOT_DIR"

echo
echo -e "${BOLD}Step 1: Create the Application${RESET}"
echo -e "${DIM}Opening Discord Developer Portal...${RESET}"
echo
echo "  1. Click ${BOLD}New Application${RESET}"
echo "  2. Name it: ${BOLD}$BOT_NAME${RESET}"
echo "  3. Accept the ToS and click Create"
echo
open "https://discord.com/developers/applications" 2>/dev/null || echo "  → Go to: https://discord.com/developers/applications"
read -rp "Press Enter when the application is created..."

echo
echo -e "${BOLD}Step 2: Get the Application ID${RESET}"
echo
echo "  On the ${BOLD}General Information${RESET} page, copy the ${BOLD}Application ID${RESET}"
echo
read -rp "Paste Application ID: " APP_ID

echo
echo -e "${BOLD}Step 3: Create the Bot${RESET}"
echo
echo "  1. Click ${BOLD}Bot${RESET} in the left sidebar"
echo "  2. Under ${BOLD}Privileged Gateway Intents${RESET}, enable:"
echo "     ✅ ${BOLD}Presence Intent${RESET}"
echo "     ✅ ${BOLD}Server Members Intent${RESET}"
echo "     ✅ ${BOLD}Message Content Intent${RESET}"
echo "  3. Click ${BOLD}Save Changes${RESET}"
echo "  4. Click ${BOLD}Reset Token${RESET} and copy the token"
echo
echo -e "${YELLOW}⚠  The token is only shown once! Copy it now.${RESET}"
echo
read -rp "Paste Bot Token: " BOT_TOKEN

echo
echo -e "${BOLD}Step 4: Set Bot Permissions${RESET}"
echo
echo "  Click ${BOLD}OAuth2${RESET} in the left sidebar."
echo

# Permissions bitfield:
# Send Messages (2048) + Read Messages/View Channels (1024) + Read Message History (65536)
# + Add Reactions (64) + Embed Links (16384) + Attach Files (32768) + Use Slash Commands (2147483648)
# + Manage Messages (8192) + Send Messages in Threads (274877906944) + Create Public Threads (34359738368)
PERMISSIONS=311385038912

INVITE_URL="https://discord.com/oauth2/authorize?client_id=${APP_ID}&permissions=${PERMISSIONS}&scope=bot%20applications.commands"

echo -e "${BOLD}Step 5: Invite to Server${RESET}"
echo
echo -e "  Opening invite link..."
echo -e "  ${DIM}${INVITE_URL}${RESET}"
echo
echo "  1. Select the server to add the bot to"
echo "  2. Click ${BOLD}Authorize${RESET}"
echo
open "$INVITE_URL" 2>/dev/null || true
read -rp "Press Enter when the bot is in your server..."

# Save config
cat > "$BOT_DIR/discord.env" << EOF
# Discord Bot: $BOT_NAME
# Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
DISCORD_APP_ID=$APP_ID
DISCORD_BOT_TOKEN=$BOT_TOKEN
DISCORD_INVITE_URL=$INVITE_URL
EOF
chmod 600 "$BOT_DIR/discord.env"

echo
echo -e "${GREEN}${BOLD}✅ Discord bot '$BOT_NAME' is set up!${RESET}"
echo
echo -e "  Config saved: ${DIM}$BOT_DIR/discord.env${RESET}"
echo
echo -e "  ${BOLD}To use in OpenClaw config:${RESET}"
echo -e "  channels.discord.token = \"$BOT_TOKEN\""
echo
echo -e "${DIM}Tip: To add to more servers, use this invite URL:${RESET}"
echo -e "${DIM}$INVITE_URL${RESET}"
