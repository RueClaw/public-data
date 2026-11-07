# Agent access

The Assistant sidebar view (`/#agent`) and direct CLI share `scripts/library_agent.py`. Search and
age-based freshness checks always work. AI answers can use server-side OpenAI-compatible connections managed in Settings. Maintenance and optional command-based answers require operator-owned adapters. The existing queue remains a list
of suggestions; submissions never launch an agent.

```sh
uv run --no-project scripts/library.py search 'worktree sandbox'
uv run --no-project scripts/library.py stale --days 90
uv run --no-project scripts/library.py stale --github --target reviews/worktrunk.md
uv run --no-project scripts/library.py ask 'Which tools help with isolated coding?' --config /private/agent.json
uv run --no-project scripts/library.py refresh 'Check architecture and license changes' --target reviews/worktrunk.md --config /private/agent.json
uv run --no-project scripts/library.py guide 'Explain hooks with a diagram' --target reviews/worktrunk.md --config /private/agent.json
uv run --no-project scripts/review-web.py --agent-config /private/agent.json
```

Example private configuration (absolute adapter paths recommended):

```json
{
  "commands": {
    "ask": ["/opt/library-adapters/answer"],
    "refresh": ["/opt/library-adapters/maintain", "refresh"],
    "guide": ["/opt/library-adapters/maintain", "guide"]
  },
  "timeout": 120,
  "github": false
}
```

Omit any command to disable that operation. Configuration is read at startup, never
accepted from the browser. `github: true` permits explicit UI checks against public
GitHub APIs; the CLI `--github` is itself an opt-in. At most 20 GitHub repositories
are compared per call, each with a ten-second timeout. Target a review for a
focused check. Public rate limits apply; no token is required or sent. Age checks
include undated entries. GitHub checks include every checked repo (including unknown
and identical outcomes); commit counts measure activity, not change significance.

## Adapter protocol

Each command receives one UTF-8 JSON object on stdin and runs with the repository
as working directory. Stdout is a plain text response; stderr is discarded (the
adapter can manage private logs). Exit zero for success, nonzero for failure.
The request contains `version: 1`, `action`, `query`, `target` (catalog entry or
null), `context` (up to 20 search hits for ask), and `instructions`. Read the full
referenced review as needed. Do not execute queries as shell commands. Return
citations, changed file paths, verification and limitations. Translate the JSON
request into your chosen agent runtime's supported invocation inside the adapter.
No model, provider, credential format or CLI-specific permission flag is assumed.

The server executes argv without a shell, serializes adapter invocations per
process, caps runtime at 300 seconds (120 default) and output at 1 MiB, and kills
the process group on timeout, failure or completion. There is no background queue,
auto-retry or durable job recovery. A timeout may leave partial edits; inspect the
diff before retrying. Successful maintenance invalidates the catalog cache.

**Adapters are trusted programs running with the service account's authority.**
The action names and instructions do not sandbox an agent or enforce read-only
access. Configure the ask adapter with an actual read-only filesystem/tool policy;
configure maintenance in an isolated writable worktree with no push credentials,
network/tool restrictions and runtime approval rules appropriate to your agent.
Do not enable a writable runtime against a production checkout. A read-only
service deployment needs a separate writable worktree and deliberate promotion of
reviewed artifacts. The stock deployment remains read-only; maintenance is opt-in.

Local users can search, check freshness and ask through enabled AI connections. Only administrators can manage users/connections or invoke command adapters (including maintenance). Local sessions, gateway authentication, Host validation, same-origin checks, request body limits and rate limits apply to agent routes. Keep adapters, config, secrets and logs outside served collections and the public repository. See [local settings and secret storage](README.md#local-accounts-and-settings). Provider charges and data egress are controlled by the configured connection or adapter.

## HTTP contract

`GET /api/agent` returns `{actions: [...], github: false, configurations: [{id, name, enabled}]}` without command details.
`POST /api/agent` accepts `{action, query, configuration?, target?, days?, github?}` and returns
`{action, results: [...]}` for search/stale or `{action, answer: "..."}` for adapters.
Use `Content-Type: application/json` and `X-Public-Data: 1`; deployed callers also
need the authenticated gateway. Invalid or disabled actions return 400. Raw agent
responses are rendered as text. Results open the existing safe review reader.

Validation uses temporary repositories and fake adapters; it does not call real
models, incur provider costs, or change actual reviews.
