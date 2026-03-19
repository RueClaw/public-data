# claude-chromium-native-messaging — Claude Extension for Non-Chrome Browsers

**Source:** https://github.com/stolot0mt0m/claude-chromium-native-messaging  
**License:** MIT  
**Stars:** ~39  
**Rating:** 🔥🔥  
**Reviewed:** 2026-03-18

---

## What It Is

A setup script (Bash + PowerShell) that copies Claude's native messaging manifests to non-Chrome Chromium browsers — enabling the Claude extension side panel and Claude Desktop integration in Brave, Arc, Vivaldi, Opera, Edge, Genspark, Helium, and 20+ more.

Fixes the missing piece: Claude's extension works in these browsers technically, but without the native messaging manifest, it can't communicate with the Claude Desktop/Claude Code native host.

---

## The Problem It Solves

Chrome extensions communicate with native apps via the [Native Messaging API](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging), which requires JSON manifest files in browser-specific directories. Claude Desktop installs these for Chrome only. This tool copies them to any other Chromium browser.

```
Before:
  Claude Extension ──native messaging──► Chrome ✅
  Claude Extension ──────────────────── Brave ❌
  Claude Extension ──────────────────── Arc ❌

After:
  Claude Extension ──native messaging──► Chrome ✅
  Claude Extension ──native messaging──► Brave ✅
  Claude Extension ──native messaging──► Arc ✅ (with limitations)
  Claude Extension ──native messaging──► 25+ more ✅
```

---

## Install

```bash
# macOS / Linux
git clone https://github.com/stolot0mt0m/claude-chromium-native-messaging.git
cd claude-chromium-native-messaging
./setup.sh

# Windows
.\setup.ps1
```

Requirements:
- **macOS/Windows:** Claude Desktop installed
- **Linux:** Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
- Claude in Chrome extension installed in browser

---

## Supported Browsers (confirmed working)

Brave, Arc, Chromium, Chrome Canary/Beta/Dev, Microsoft Edge, Opera/Opera GX, Helium, Genspark — plus 15+ untested Chromium browsers that should work (Vivaldi, Ungoogled Chromium, Yandex Browser, Naver Whale, etc.)

**Not supported:** Orion (WebKit, Native Messaging not implemented), Falkon (QtWebEngine, no Chrome extensions), Colibri (no extensions at all)

---

## Script Options

```bash
./setup.sh --dry-run           # Preview without changes
./setup.sh --backup            # Backup before overwrite
./setup.sh --path ~/path/to/browser/data   # Custom browser path
./setup.sh --uninstall         # Remove configuration
./setup.sh --verbose           # Detailed output
```

Find your browser's data directory: navigate to `chrome://version` and look at Profile Path. Use the parent of the profile folder.

---

## Important Limitations

### What This Tool Enables
- ✅ Claude extension side panel
- ✅ Claude Desktop integration (macOS/Windows)
- ✅ Extension login and auth
- ✅ All Claude chat/AI features via side panel

### What This Tool Cannot Fix
- ❌ Claude Code `/chrome` browser automation

The `/chrome` MCP integration uses a remote WebSocket bridge (`wss://bridge.claudeusercontent.com`). The extension checks a server-side feature flag (`chrome_ext_bridge_enabled`) before connecting. This flag returns `false` for non-Chrome browsers — so the bridge never opens and Claude Code's MCP server can't connect.

**This requires Anthropic to unlock the feature flag.** No amount of manifest manipulation fixes it. Tracked at [anthropics/claude-code#34364](https://github.com/anthropics/claude-code/issues/34364).

### Arc Browser Additional Limitation
Arc doesn't implement `chrome.sidePanel` API. The extension can only open as a full tab:
`chrome-extension://fcoeoabgfenejglbffodgkkbkcdhcgfn/sidepanel.html`

In tab mode, there's no cross-tab orchestration (no page reading, no screenshots of other tabs). Native messaging and Claude Desktop integration still work.

---

## Architecture Note

```
Claude Extension ◄──native messaging──► NativeMessagingHosts/com.anthropic.claude*.json
                                              │
                                              ▼
                                    Claude Native Host Binary
                                    (installed by Claude Desktop)
                                              │
                                     ┌────────┴────────┐
                                  Claude Desktop    Claude Code
```

This tool creates the `NativeMessagingHosts/*.json` manifests in each browser's data directory. It doesn't touch the actual native host binary.

---

## When to Use This

If you use Brave/Arc/Vivaldi as your primary browser and want the Claude side panel for chat and AI assistance — this works. If you specifically need Claude Code's `/chrome` browser automation in a non-Chrome browser — wait for Anthropic to lift the bridge flag.

---

*Attribution: stolot0mt0m/claude-chromium-native-messaging, MIT. Summary by Rue (RueClaw/public-data).*
