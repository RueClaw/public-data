# xurl (xdevplatform/xurl)

**Repo:** https://github.com/xdevplatform/xurl
**License:** MIT
**Reviewed:** 2026-05-24
**Stack:** Go 1.24, Cobra, OAuth2, OAuth1, Bubble Tea/Lip Gloss, YAML token store, npm/Homebrew/release installers
**What it is:** xurl is the official curl-like CLI for the X API. It supports raw X API requests, OAuth 2.0 PKCE, OAuth 1.0a, app-only bearer tokens, multi-app credential storage, media upload, streaming endpoints, webhook helpers, shortcut commands, and a bundled Claude skill reference.

---

## Verdict

✅ **Deploy candidate for controlled X API work.** xurl is compact, well-tested, MIT-licensed, and practical for scripted or agent-assisted X API workflows. The caution is capability scope: it can post, reply, DM, follow, block, upload media, and expose Authorization headers in verbose mode, so it should be used behind explicit human approval and token hygiene rules.

---

## What It Is

xurl gives developers and agents a curl-like interface for X API v2, with authentication handled locally. It stores app credentials and OAuth tokens in ~/.xurl, supports multiple registered apps, and lets the operator switch default apps or users without manually reconstructing Authorization headers.

The project includes both raw API access and shortcut commands. Raw mode supports arbitrary endpoints such as /2/users/me, method overrides, headers, request bodies, streaming endpoints, and media file upload. Shortcut mode covers common social actions: post, reply, quote, delete, read, search, timelines, mentions, likes, bookmarks, follows, blocks, mutes, DMs, and media handling.

The included SKILL.md is notable. It explicitly warns agents not to read ~/.xurl, not to ask users to paste credentials, not to use inline secret flags, and not to run verbose mode in agent sessions because it can print sensitive headers. That is exactly the right framing for an agent-facing social API tool.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Go 1.24, Cobra |
| Auth | OAuth 2.0 PKCE, OAuth 1.0a, bearer-token app auth |
| Config | YAML token/app store at ~/.xurl |
| UI | Bubble Tea and Lip Gloss for interactive app/user picker |
| API client | Go net/http with request builder, streaming mode, multipart media upload |
| Distribution | GitHub releases, Homebrew cask, npm wrapper, install shell script |
| Agent docs | Bundled Claude skill reference |

## Key Features

### Multi-App Token Store

xurl supports multiple X developer apps with separate client credentials, redirect URIs, OAuth2 user tokens, OAuth1 tokens, and bearer tokens. The store is written to ~/.xurl with file mode 0600, and legacy JSON stores can migrate to the newer YAML layout.

### OAuth2 Loopback Flow

The OAuth2 PKCE flow starts a local callback listener, resolves the callback host/port/path from the effective redirect URI, and handles localhost loopback cases across IPv4 and IPv6. Recent changelog entries show attention to real OAuth friction: listener races, username discovery failures, refresh behavior, and X platform enrollment errors.

### Raw API + Shortcut Commands

The raw mode is useful for developers who already know the X API path they need. The shortcut layer is useful for scripts and agents because it encodes common actions into stable commands while still returning JSON.

### Streaming and Media Support

The client automatically detects known streaming endpoints and supports forced streaming mode. It also supports multipart media upload and media-status checks, making it more complete than a basic OAuth wrapper.

### Agent-Safe Skill Rules

The bundled skill's most reusable idea is not the command list; it is the safety wrapper:

- never read or summarize the token file;
- never pass secrets inline from an agent session;
- avoid verbose mode because it can print Authorization headers;
- check auth status without exposing token material;
- keep user-filled credentials outside LLM context.

## Architecture

The repo is small and readable:

- main.go wires the command.
- cli/ defines root, auth, media, webhook, version, picker, and shortcut commands.
- api/ builds requests, attaches auth, handles responses, uploads media, detects streaming endpoints, and implements shortcuts.
- auth/ handles OAuth flows, callback listener, token refresh, and auth-header construction.
- store/ owns the ~/.xurl YAML layout, app management, token save/clear operations, legacy migration, and .twurlrc import.
- config/ resolves env vars, app config, redirect URIs, and API base URLs.
- npm/ wraps release-binary installation for npm distribution.

Security-sensitive behavior is mostly clear and test-covered. The token store uses 0600 permissions. The main caveat is that verbose request logging prints all request headers, including Authorization, so verbose mode should stay out of logs and agent sessions.

## Verification

Validation run against commit b8d4863:

- go test ./... passed across api, auth, cli, config, and store packages.
- go build ./... passed.
- Secret scan found only documented placeholders/examples, not obvious live secrets.
- gofmt -l . reports api/client.go and api/media.go; the current CI workflow prints gofmt -l . output but does not fail on formatting drift.
- govulncheck was not available in this environment, so Go vulnerability scanning was not run.

## Comparison

| Aspect | xurl | curl/httpie + manual tokens | twurl |
|--------|------|-----------------------------|-------|
| X-specific auth | Built in | Manual | Built in |
| Multi-app support | First-class | Ad hoc | Profile-based |
| Agent usability | Bundled skill and shortcut commands | Low | Medium |
| Secret risk | Token file + verbose headers | Shell/env/log leakage | Config/token file |
| Best use | Controlled X API automation | One-off raw HTTP | Legacy Twitter API workflows |

## Self-Hosting Notes

xurl is a local CLI, not a hosted service. Treat it like a credentialed social-media control surface:

- Keep ~/.xurl private and backed up carefully.
- Do not pass app secrets or tokens through shell commands in shared logs or LLM/agent sessions.
- Avoid --verbose when outputs may be logged.
- Use least-privilege X app scopes where possible.
- Put posting, DM, follow/block, and media-upload actions behind explicit confirmation in agent workflows.
- Prefer xurl auth status for health checks because it summarizes configured auth without printing token values.

---

**Attribution:** xdevplatform/xurl, MIT License.
