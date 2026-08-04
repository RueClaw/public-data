# Detached Eval Control Channel

**Source:** Inspect AI
**URL:** https://inspect.aisi.org.uk/control-channel.html
**Repo:** https://github.com/UKGovernmentBEIS/inspect_ai
**License:** MIT
**Reviewed:** 2026-08-03

## Pattern

Launch long-running evaluation jobs as supervised background processes, then expose a local-only control channel for observation and reversible intervention.

The useful shape is:

```text
eval launcher
  -> validates task/config
  -> starts eval process
  -> waits until control endpoint is bound
  -> emits one machine-readable launch record
  -> exits if running detached

control channel
  -> lists live tasks and samples
  -> reports progress, errors, stalls, tokens, and log paths
  -> pages transcript events and conversation snapshots
  -> flushes logs, pauses/resumes, retunes limits, cancels specific work

completion signal
  -> process exits when done
  -> output file ends with machine-readable done record
  -> final logs are read from reported log locations
```

## Why It Works

Long evals should not depend on a terminal session staying alive. They also should not become invisible once detached. The handoff record removes the ambiguous "did it really start?" state: if the launcher exits successfully, it has already seen the control endpoint bind and can tell the caller where to watch.

The local control surface handles the normal failure cases of eval work:

- a sample stalls but the whole eval should continue;
- a provider starts rate-limiting;
- logs need to be flushed before a process dies;
- concurrency or retry limits need retuning;
- a single bad sample should be cancelled rather than killing the whole run;
- a supervising agent needs structured status instead of terminal scraping.

## Implementation Notes

- Bind locally by default. Inspect uses a Unix-domain socket under the current user's data directory rather than a network listener.
- Emit JSON launch records only after the control endpoint is ready.
- Keep stdout machine-readable under `--json`; redirect task stdout/stderr away from the control stream.
- Treat missing `done` as a crash signal, not as success.
- Page transcript/event reads with opaque cursors; do not force pollers to infer state from timestamps.
- Make destructive operations explicit and idempotent, with dry-run support where possible.
- Prefer reversible controls such as pause/resume and config retuning before cancellation.
- Keep final result logs separate from live control state.

## When To Use

Use this for:

- model benchmark suites that run for minutes or hours;
- agent evals with tool calls and sandboxes;
- CI or background workers that need to supervise paid model calls;
- eval orchestrators that may outlive the shell or agent that launched them.

Do not use it as an excuse to expose eval control over the public internet. If remote supervision is needed, put an authenticated control plane in front of a narrow local worker surface.

---

**Attribution:** Inspect AI, UK AI Security Institute / UKGovernmentBEIS, MIT
