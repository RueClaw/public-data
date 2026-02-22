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

printf "${CYAN}${BOLD}═══════════════════════════════════════${RESET}\n"
printf "${CYAN}${BOLD}  Discord Bot Setup${RESET}\n"
printf "${CYAN}${BOLD}═══════════════════════════════════════${RESET}\n"
echo

# Step 1: Name
read -rp "Bot name (e.g. 'anek', 'rue'): " BOT_NAME
BOT_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
BOT_DIR="$HOME/.openclaw/bots/$BOT_NAME"
mkdir -p "$BOT_DIR"

echo
printf "${BOLD}Step 1: Create the Application${RESET}\n"
printf "${DIM}Opening Discord Developer Portal...${RESET}\n"
echo
printf "  1. Click ${BOLD}New Application${RESET}\n"
printf "  2. Name it: ${BOLD}$BOT_NAME${RESET}\n"
echo "  3. Accept the ToS and click Create"
echo
open "https://discord.com/developers/applications" 2>/dev/null || echo "  → Go to: https://discord.com/developers/applications"
read -rp "Press Enter when the application is created..."

echo
printf "${BOLD}Step 2: Get the Application ID${RESET}\n"
echo
printf "  On the ${BOLD}General Information${RESET} page, copy the ${BOLD}Application ID${RESET}\n"
echo
read -rp "Paste Application ID: " APP_ID

echo
printf "${BOLD}Step 3: Create the Bot${RESET}\n"
echo
printf "  1. Click ${BOLD}Bot${RESET} in the left sidebar\n"
printf "  2. Under ${BOLD}Privileged Gateway Intents${RESET}, enable:\n"
printf "     ✅ ${BOLD}Presence Intent${RESET}\n"
printf "     ✅ ${BOLD}Server Members Intent${RESET}\n"
printf "     ✅ ${BOLD}Message Content Intent${RESET}\n"
printf "  3. Click ${BOLD}Save Changes${RESET}\n"
printf "  4. Click ${BOLD}Reset Token${RESET} and copy the token\n"
echo
printf "${YELLOW}⚠  The token is only shown once! Copy it now.${RESET}\n"
echo
read -rp "Paste Bot Token: " BOT_TOKEN

echo
printf "${BOLD}Step 4: Set Bot Permissions${RESET}\n"
echo
printf "  Click ${BOLD}OAuth2${RESET} in the left sidebar.\n"
echo

# Permissions bitfield:
# Send Messages (2048) + Read Messages/View Channels (1024) + Read Message History (65536)
# + Add Reactions (64) + Embed Links (16384) + Attach Files (32768) + Use Slash Commands (2147483648)
# + Manage Messages (8192) + Send Messages in Threads (274877906944) + Create Public Threads (34359738368)
PERMISSIONS=311385038912

INVITE_URL="https://discord.com/oauth2/authorize?client_id=${APP_ID}&permissions=${PERMISSIONS}&scope=bot%20applications.commands"

printf "${BOLD}Step 5: Invite to Server${RESET}\n"
echo
printf "  Opening invite link...\n"
printf "  ${DIM}${INVITE_URL}${RESET}\n"
echo
echo "  1. Select the server to add the bot to"
printf "  2. Click ${BOLD}Authorize${RESET}\n"
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
printf "${GREEN}${BOLD}✅ Discord bot '$BOT_NAME' is set up!${RESET}\n"
echo
printf "  Config saved: ${DIM}$BOT_DIR/discord.env${RESET}\n"
echo
printf "  ${BOLD}To use in OpenClaw config:${RESET}\n"
printf "  channels.discord.token = \"$BOT_TOKEN\"\n"
echo
printf "${DIM}Tip: To add to more servers, use this invite URL:${RESET}\n"
printf "${DIM}$INVITE_URL${RESET}\n"
