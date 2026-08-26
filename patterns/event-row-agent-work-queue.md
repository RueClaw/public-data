# Event-Row Agent Work Queue

**Source:** trycompai/crm  
**Repo:** https://github.com/trycompai/crm  
**License:** MIT  
**Extracted:** 2026-08-01  

## Pattern

Let ordinary application services report events by writing durable database rows, then let an autonomous agent lease those rows and decide what the event means.

The API does not call enrichment vendors, run model logic, or synchronously wait on the agent. It only records that something happened: a company was created, a contact arrived from email sync, a meeting is coming soon, or a user requested research.

## Core Structure

Each work row carries:

- subject identifiers, such as `contactId`, `companyId`, or `dealId`;
- a `kind`, such as `identify`, `profile`, `meeting-prep`, or `company-profile`;
- a human-readable `reason`;
- `dueAt`;
- `priority`;
- a per-run budget;
- `leasedUntil`;
- `attempts`;
- `finishedAt`;
- optional outcome/session fields.

The dispatcher is intentionally small:

1. retire exhausted rows whose leases expired too many times;
2. claim due rows with `FOR UPDATE SKIP LOCKED`;
3. start or resume one durable agent session per row;
4. write the session id back to the row;
5. let the agent/session hook mark completion when the work actually settles.

## Why It Works

It keeps agent work off the request path. A user action or sync job can enqueue durable work quickly, then return. If the agent is down, slow, redeploying, or rate limited, the row waits.

It also keeps scheduling intent close to the work. "Recheck this person in fourteen days because a job change would affect an active deal" is richer than "run the oldest ten contacts every hour." The reason, priority, due date, and budget become inspectable state.

`FOR UPDATE SKIP LOCKED` gives safe multi-dispatcher concurrency without a separate broker. A lease deadline makes crashed runs recoverable. An attempt cap prevents poison rows from waking up forever.

## Design Rules

Keep decision-making out of the API. If an app service starts deciding who is worth researching, which source is credible, or what a person probably means, the boundary has drifted.

Make rows idempotent by subject and kind. A record saved three times in a minute should usually produce one outstanding task, not three copies of the same agent run.

Store the reason in human language. Operators and users should be able to see why the agent is coming back later.

Carry budget on the row. Different task kinds deserve different spend limits, and retries should not become invisible blank checks.

Mark handoff separately from completion. Starting a durable session means the agent accepted the work; it does not mean the research finished.

Do not let cleanup block work. Retirement of exhausted rows should be guarded so a cleanup failure does not stop the dispatcher from claiming current work.

## Caveats

This pattern assumes the database is already a reliable system of record. For high-volume queues, cross-region workers, or strict delivery guarantees, a real job queue or message broker may still be a better fit.

Database-row queues need indexes, bounded batch sizes, and clear retention policy. They can become slow or opaque if every background concern piles into one table without ownership.

The agent still needs its own safety boundaries. A durable queue solves scheduling and recovery; it does not solve credential isolation, egress policy, authorization, or evidence quality.

---

**Attribution:** Based on trycompai/crm, MIT License.
