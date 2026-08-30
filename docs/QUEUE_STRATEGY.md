# Initial Queue Strategy

## Status

**Canonical documentation for Tio's first durable asynchronous queue boundary.**

This document completes the planning scope of Linear TNYX-30. It does not enable a Postgres extension, create a queue, expose a queue through the Data API, create `services/worker`, deploy an Edge Function, configure Cron, or start backend runtime work.

Related contracts:

- [Architecture](ARCHITECTURE.md)
- [Supabase Server Access](SUPABASE_SERVER_ACCESS.md)
- [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md)
- [Observability](OBSERVABILITY.md)
- [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md)

Linear ownership remains separate:

- **TNYX-30** — initial queue technology/use-case/message/delivery strategy.
- **TNYX-31** — future `services/worker` process lifecycle and consumption architecture.
- **TNYX-32** — retry classification, idempotency, backoff, dead-letter, and scheduled-job rules.
- **TNYX-121** — production SLOs, queue-delay thresholds, capacity triggers, incidents, and resilience exercises.

## Current Decision

When Tio gets its **first real durable asynchronous workload**, evaluate/enable **Supabase Queues (`pgmq`) as the default first queue** before introducing Redis/Valkey, SQS, Kafka, or another queue platform.

This is a simplicity-first default, not a permanent ban on other systems.

```text
approved async workload
        ↓
Supabase Queues / pgmq first
        ↓
future trusted consumer
        ↓
Supabase / approved provider / internal operation
```

The queue is **not active infrastructure today**. Do not create queue objects merely because this document exists.

## Why Supabase Queues First

Tio already uses Supabase/Postgres as the active data foundation. A Postgres-native durable queue can keep the first async slice operationally small while still providing:

- durable logged message storage;
- pull-based consumption;
- visibility timeouts;
- redelivery when processing does not complete before visibility expires;
- explicit delete/archive after successful processing;
- queue-depth and message-age metrics;
- a path to server-side consumers without adding a second infrastructure provider on day one.

This advantage only matters while the workload remains a good fit for Postgres-backed queues. Queue technology must be re-evaluated when evidence shows otherwise.

## Audit Snapshot — 2026-08-30

Read-only audit of the current hosted Supabase project found:

```text
Postgres       17.6
pgmq available yes
pgmq version   1.5.1 available
pgmq enabled   no
pgmq schema    absent
pgmq_public    absent
queues         none
```

Therefore:

- this document must not claim that Tio currently runs Supabase Queues;
- no queue migration/configuration is required for this planning task;
- implementation must re-check current Supabase Queues docs/changelog and the installed/available `pgmq` version before enabling anything.

Supabase has previously published a `pgmq` compatibility warning around version 1.5.1 and delay-parameter behavior. Do not copy an old function signature from memory or an old design document into production migration code; verify the current API at implementation time.

## Queue Type

For Tio business jobs requiring durability, the default candidate is a **Basic/logged Queue**.

Do not use an Unlogged Queue for jobs where losing pending work could corrupt user state or silently skip required processing. Unlogged queues may trade durability for throughput and therefore require a separately justified workload.

Partitioned/high-throughput queue variants must not be assumed available or necessary before current Supabase support and measured workload justify them.

## Queue Use Cases

A queue is appropriate when work is valid after the initiating request/process has ended and benefits from durable retry/isolation.

Candidate categories include:

- external-provider work that should not extend an interactive HTTP request lifetime;
- expensive AI generation/embedding/summary work after that product slice is separately approved;
- imports, reconciliation, repair, or derived-data jobs;
- notification-delivery/scheduling work after its own architecture is approved;
- subscription/provider reconciliation after billing work is approved;
- periodic insight generation or other independently retryable background work;
- fan-out from an accepted domain event when synchronous completion is not required.

These examples authorize no product feature by themselves.

## Queue Non-Use Cases

Do not use the queue as:

- the canonical source of truth for user/profile/workout/nutrition/progress state;
- a replacement for a normal synchronous database transaction;
- a cache;
- a distributed lock/leader-election system;
- a general event warehouse or analytics stream;
- a blob/media transport;
- a place to persist whole health records, AI conversations, request bodies, or uploaded files;
- a workaround for an API/database authorization problem;
- infrastructure created before a concrete asynchronous workload exists.

If the user must receive the authoritative result before a request succeeds, the work is normally synchronous unless a separately designed asynchronous UX exists.

## Message Contract

Queue messages are **commands/references**, not copies of full domain records.

A future Tio-owned envelope should be versionable and minimal. Conceptually:

```json
{
  "schema_version": 1,
  "job_type": "example_job",
  "job_id": "opaque-id",
  "correlation_id": "opaque-id",
  "resource_type": "example_resource",
  "resource_id": "opaque-id",
  "requested_at": "timestamp"
}
```

Exact fields depend on the first approved workload.

Rules:

- include an explicit payload/schema version;
- include a stable job type;
- prefer resource references over embedding mutable domain payloads;
- keep identifiers opaque and avoid user-facing semantics in IDs;
- include only data needed to locate/authorize/process the job;
- do not place access tokens, refresh tokens, service keys, provider secrets, signed URLs, passwords, OTPs, or credentials in queue messages;
- do not include raw health/nutrition/workout/body/AI text when the consumer can load authorized current data by reference;
- message format changes must remain backward-readable while old messages can still be pending;
- the consumer must reject unsupported versions safely rather than guessing.

## Authorization Boundary

Queue storage does not grant business authorization.

The future producer must already be authorized to request the asynchronous operation. The future trusted consumer must independently execute only the narrow operation represented by the message.

For privileged jobs, follow [Supabase Server Access](SUPABASE_SERVER_ACCESS.md):

```text
trusted trigger
  → explicit privileged reason
  → minimal queue message
  → narrow trusted consumer
  → minimum required privileged operation
```

Never convert an RLS denial into an enqueue-and-bypass pattern.

## Client Exposure

**Default: queues are server-side/internal infrastructure.**

Do not expose `pgmq_public` to Flutter, Wear OS, watchOS, or public clients merely because Supabase supports Data API access to Queues.

If a future use case proposes direct client queue access, it requires a separate security review covering:

- why an ordinary API/RPC boundary is insufficient;
- exposed schema configuration;
- RLS on queue tables;
- exact role/function grants;
- message authorization and data minimization;
- abuse/rate-limit behavior;
- whether users could read, alter, delete, replay, or infer another user's work.

Service-role/postgres credentials must never be distributed to clients.

## Delivery Semantics

Supabase Queues is pull-based. The safe default processing shape for durable work is:

```text
read message
  → message hidden for visibility window
  → process idempotently
  → success: delete or intentionally archive
  → failure/crash: do not acknowledge
  → visibility expires
  → message becomes readable again
```

### Use `read`, not destructive `pop`, for normal durable jobs

`pop()` reads and deletes immediately. If the consumer crashes after the pop but before completing business work, the queue cannot naturally redeliver that message.

Therefore Tio durable business processing should normally use a visibility-timeout read and acknowledge only after success.

`pop()` may be considered only for explicitly at-most-once/non-critical workloads where loss after read is acceptable.

## Visibility Timeout

The visibility timeout must cover the normal processing window with safety margin, but not hide a failed job indefinitely.

At implementation time choose it from measured/provider timeout expectations, not a universal hard-coded value.

Rules:

- visibility timeout > expected maximum normal processing time plus reasonable margin;
- long work should not depend on repeatedly extending visibility without an explicit design;
- if the timeout expires while processing is still active, another consumer may receive the message, so duplicate-safe behavior is mandatory;
- queue delay and repeated reads (`read_ct`) become operational signals.

Exact retry/backoff policy belongs to TNYX-32.

## Success Acknowledgement

A message is removed from the active queue only after the intended durable side effect is confirmed.

Choose between:

- **delete** — normal completed job when long-term message retention is unnecessary;
- **archive** — only where audit/replay/diagnostic retention has a defined purpose and retention/access policy.

Do not archive sensitive payloads indefinitely by default. Queue archives remain data and must follow privacy/retention rules.

## Duplicate Delivery and Exactly-Once Language

Do not interpret queue documentation's "exactly once within a visibility window" as exactly-once business processing.

Crashes, visibility expiry, retries, provider ambiguity, and acknowledgment failure can cause the business operation to be attempted more than once.

Therefore Tio consumers must assume **at-least-once processing risk** unless a specific workflow proves stronger guarantees.

TNYX-32 owns the concrete idempotency-key, deduplication, retryable/permanent error, backoff, and dead-letter rules.

## Failure Boundary

Queueing separates request acceptance from eventual processing; it does not make failures disappear.

Each implemented job must eventually define:

- what constitutes success;
- which failures are retryable;
- which failures are permanent;
- maximum attempt/backoff behavior;
- how poison jobs leave the active queue;
- how operators inspect/replay/reconcile failures;
- how user-visible state represents pending/failed work where relevant.

Those cross-job reliability rules are finalized in TNYX-32 rather than duplicated here.

## Scheduling Boundary

A queue and a scheduler solve different problems.

```text
event-driven job
  event/request → enqueue → consumer

scheduled job
  scheduler/cron → enqueue or invoke bounded job → consumer
```

Do not make every scheduled task a queue job automatically. TNYX-32 owns the final scheduled-vs-event-driven rules.

No Supabase Cron configuration is authorized by this document.

## Future Consumer Boundary

TNYX-30 does not decide that the first consumer must be `services/worker` or an Edge Function.

The first approved workload should choose the smallest trusted runtime that satisfies execution-time, dependency, deployment, security, and operability requirements.

Long-lived/general asynchronous product workloads are expected to align with the future `services/worker` architecture defined by TNYX-31. A narrow Supabase-native task may justify a bounded Edge Function, but that decision belongs to the actual implementation slice.

## Observability

When a queue exists, follow [Observability](OBSERVABILITY.md).

Minimum useful signals include:

- queue depth;
- oldest-message age / queue delay;
- enqueue rate;
- read/start rate;
- success/failure rate;
- processing duration;
- retry/redelivery/read-count signal;
- dead-letter/terminal-failure count when TNYX-32 defines that mechanism;
- consumer concurrency/saturation where applicable.

Do not use raw user IDs, job IDs, request IDs, resource IDs, free-text errors, or message bodies as metric labels.

Correlation metadata may connect an originating request/event to a job, but it must not copy raw sensitive payloads into logs/traces.

TNYX-121 owns numeric SLO/alert/capacity thresholds.

## Retention and Recovery

Queue messages are operational data, not a substitute for canonical domain storage.

Before production use, the implementation slice must decide:

- active-message retention expectations;
- archive retention if archive is used;
- whether queue state is included/restored by the relevant database recovery path;
- what happens when canonical domain state restores to a different point than pending async work;
- whether jobs can be safely regenerated/reconciled after restore.

Database recovery policy remains owned by [Database Backup & Recovery](DATABASE_BACKUP_RECOVERY.md).

## When to Reconsider Supabase Queues

Do not introduce Redis/Valkey/SQS/Kafka merely for architectural fashion. Re-evaluate the queue technology when evidence shows the Postgres-native option no longer meets requirements, for example:

- sustained queue throughput materially harms primary Postgres workload;
- required latency/throughput exceeds demonstrated safe capacity;
- independent failure domain from the primary database becomes necessary;
- cross-region/multi-region delivery becomes a real requirement;
- provider-native integration materially reduces correctness/operational risk;
- advanced streaming/partitioning/consumer-group semantics are genuinely needed;
- queue storage/retention scale is operationally inappropriate for the primary database;
- measured recovery/SLO requirements cannot be met.

A technology migration requires its own evidence and durable decision; it must not silently turn Redis into the system of record.

## Redis / Valkey Boundary

Redis/Valkey is **not selected infrastructure today**.

If introduced later, it must have a separately justified role such as cache/shared ephemeral coordination/queue workload after evidence demands it. Redis must not become the authoritative owner of user health/profile/workout/nutrition/progress state merely because it is fast.

## Implementation Gate

This policy does **not** authorize any runtime/platform mutation.

Until a concrete asynchronous workload and explicit implementation approval exist:

- do not enable `pgmq`;
- do not create `pgmq`/`pgmq_public` schemas or queues;
- do not expose Queues via PostgREST/Data API;
- do not create queue RLS/grants;
- do not configure Cron;
- do not create/deploy a queue-consuming Edge Function;
- do not create `services/worker`;
- do not add Redis/Valkey/SQS/Kafka;
- do not create worker secrets or deployment resources;
- do not mutate production user data.

## Implementation-Time Checklist

When the first real queue workload is explicitly approved:

1. Re-check the current Supabase changelog and Queues/pgmq documentation.
2. Confirm hosted Postgres and available `pgmq` versions.
3. Confirm the workload genuinely benefits from asynchronous durable processing.
4. Select Basic/logged queue unless durability loss is intentionally accepted.
5. Define the queue name and narrow ownership.
6. Define versioned minimal message schema.
7. Define producer authorization.
8. Define trusted consumer/runtime.
9. Define visibility timeout from measured execution limits.
10. Apply TNYX-32 idempotency/retry/dead-letter rules.
11. Define delete/archive and retention policy.
12. Keep client exposure disabled unless separately reviewed.
13. Add safe queue metrics/correlation.
14. Test failure before acknowledgment, visibility expiry, duplicate delivery, unsupported message versions, and consumer restart.
15. Verify no sensitive payloads/secrets appear in messages or telemetry.

## Acceptance for TNYX-30

- [x] Initial first-choice durable queue is documented as Supabase Queues/pgmq, subject to implementation-time verification.
- [x] Queue use cases and explicit non-use cases are documented.
- [x] Basic/logged vs Unlogged durability boundary is documented.
- [x] Versionable, minimal message-envelope rules are documented.
- [x] Visibility/read/delete/archive behavior is documented.
- [x] `pop()` at-most-once risk is explicitly separated from normal durable processing.
- [x] Duplicate-processing risk is acknowledged without duplicating TNYX-32 reliability rules.
- [x] Client-side queue exposure is denied by default and requires separate security review.
- [x] Redis/Valkey/SQS/Kafka remain deferred until measured operational requirements justify them.
- [x] Current Supabase audit records that `pgmq` is available but not enabled; no queue is falsely claimed active.
- [x] No queue, worker, Edge Function, Cron job, extension, schema, migration, or backend runtime is created by this documentation slice.
