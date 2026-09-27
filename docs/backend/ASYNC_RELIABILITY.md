# Async Reliability Rules

## Status

**Canonical reliability policy for future Tio asynchronous jobs.**

This document completes the planning scope of Linear TNYX-32. It defines retry, idempotency, backoff, terminal-failure/dead-letter, duplicate-execution, and scheduled-job rules before a worker or queue consumer exists.

It does **not** create `services/worker`, enable Supabase Queues, configure Cron, create a dead-letter queue/table, add a scheduler, or start backend runtime work.

Related contracts:

- [Initial Queue Strategy](QUEUE_STRATEGY.md)
- [Observability](OBSERVABILITY.md)
- [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md)
- [Database Backup & Recovery](DATABASE_BACKUP_RECOVERY.md)
- [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md)

Linear ownership remains separate:

- **TNYX-30** — initial queue technology/use-case/message/delivery strategy.
- **TNYX-31** — future `services/worker` process lifecycle and consumption architecture.
- **TNYX-32** — this retry/idempotency/backoff/dead-letter/scheduling policy.
- **TNYX-121** — production SLOs, queue-delay thresholds, alerts, capacity triggers, incidents, and resilience exercises.
- **TNYX-134** — HTTP mutation idempotency/concurrency rules; queue/job deduplication remains here.

## Core Principle

A durable queue may redeliver work. Correctness must therefore come from the **business operation being duplicate-safe**, not from assuming one delivery means one execution.

```text
logical job
  -> one stable job identity
  -> one stable idempotency identity where needed
  -> one or more delivery attempts
  -> at most one intended durable business effect
```

The system must distinguish:

- **logical job identity** — the business operation being requested;
- **delivery/attempt identity** — one execution attempt of that logical job;
- **idempotency identity** — the key or equivalent durable guard that prevents duplicate business effects.

Retries create new attempts. They do not silently create a new logical operation.

## Delivery Assumption

Future Tio queue consumers must assume **at-least-once processing risk** unless a specific workflow proves stronger guarantees.

Duplicate attempts can occur because of:

- visibility timeout expiry;
- consumer crash after performing a side effect but before acknowledging the queue message;
- network loss after a provider completed an operation but before Tio received the response;
- acknowledgment/delete failure;
- scheduler duplication or catch-up behavior;
- manual replay;
- deployment/restart races;
- provider retries or webhook redelivery in future integrations.

Do not use "exactly once" language for end-to-end business effects unless the complete workflow, including external providers, actually proves it.

## Job Identity

Every implemented durable job must define a stable logical identity.

A future message may carry separate fields conceptually like:

```json
{
  "schema_version": 1,
  "job_type": "example_job",
  "job_id": "stable-logical-job-id",
  "attempt_context": "not-the-business-identity",
  "resource_id": "opaque-reference",
  "correlation_id": "opaque-reference"
}
```

Exact fields belong to the first approved workload.

Rules:

- `job_id` identifies the logical work, not one retry attempt;
- a retry must not generate a fresh job identity merely to bypass deduplication;
- attempt count/timestamps are operational metadata, not part of the business identity;
- identifiers must remain opaque and must not encode email, phone, health data, secrets, or unrestricted user text.

## Idempotency Requirement

A job requires an idempotency strategy when duplicate execution could:

- create duplicate records;
- double-charge or double-refund;
- send duplicate notifications with material user impact;
- apply the same entitlement/subscription transition twice;
- increment/decrement balances/counters twice;
- create duplicate provider resources;
- overwrite newer user state with stale derived output;
- repeat destructive or irreversible work;
- otherwise corrupt canonical state.

Read-only work or naturally idempotent replacement operations may not require a separate deduplication record, but that decision must be explicit.

## Idempotency Identity

The idempotency identity must represent the **semantic operation**, not a random execution attempt.

Typical inputs may include a stable combination of:

```text
job_type
+ business/resource identity
+ source event or requested operation identity
+ logical schedule occurrence/window when scheduled
+ operation version where semantics materially differ
```

Do not use wall-clock execution time as the only key for a retryable logical operation.

Do not include raw sensitive payloads in idempotency keys. If a derived representation is needed, use a bounded non-sensitive identifier or an implementation-approved digest rather than copying the original content.

## Idempotency Retention

There is no universal idempotency TTL.

Each implemented job must retain its deduplication/outcome evidence long enough to cover the realistic duplicate/replay window, including:

- maximum queue redelivery period;
- retry/backoff budget;
- scheduler catch-up window;
- delayed provider/webhook duplicate window where applicable;
- manual replay/reconciliation window where replay is supported.

Do not expire deduplication evidence before the system can still legitimately redeliver the same logical job.

Exact retention must be documented with the workload and must follow privacy/retention policy.

## Safe State-Mutation Patterns

Implementation may use one or more of these patterns depending on the workload:

- database uniqueness constraint keyed by semantic operation;
- transactional processed-job/outcome record;
- compare-and-set / expected-state transition;
- immutable event/source identifier already unique in canonical storage;
- provider-supported idempotency key;
- reconciliation before retry when provider outcome is uncertain.

This policy does not mandate one universal table or schema.

### Database-only side effects

When possible, the deduplication guard and canonical state mutation should commit atomically in one database transaction.

Unsafe shape:

```text
check "not processed"
  -> separate gap/race
  -> mutate canonical state
  -> record "processed"
```

Preferred conceptual shape:

```text
transaction
  -> establish unique/valid operation guard
  -> apply intended canonical mutation
  -> record stable outcome if needed
commit
```

A pre-check alone is not sufficient under concurrency unless the database also enforces the invariant.

## External Provider Side Effects

Provider calls require special handling because Tio may not know whether an operation succeeded when a timeout/network failure occurs.

If the provider supports idempotency keys:

- send the same stable semantic key on every retry of the same logical operation;
- do not generate a fresh provider idempotency key per attempt;
- confirm provider retention/replay semantics at implementation time.

If the provider does **not** support idempotency:

- prefer a provider status/read-back/reconciliation operation before repeating an ambiguous side effect;
- keep an explicit local state machine where needed;
- do not classify "request timed out after send" as automatically safe to retry.

Examples of ambiguous outcomes:

```text
Tio sends operation
provider may complete it
response is lost / connection times out
Tio outcome = unknown
```

`unknown` is not the same as `failed`.

## Retry Classification

Every job type must classify failures into at least these categories:

### Retryable

A failure may be retryable when another attempt has a reasonable chance of succeeding without changing the logical request, for example:

- transient network/connectivity failure where provider outcome is known not to have committed;
- temporary dependency unavailability;
- `429`/rate-limit response with safe retry guidance;
- bounded `5xx` dependency failure;
- temporary resource contention;
- a dependency explicitly reports a retryable condition.

### Permanent

A failure should normally be terminal when retrying the same logical request cannot make it valid, for example:

- malformed/unsupported job schema version;
- invalid canonical resource reference;
- authentication/authorization failure that is not a transient credential-rotation race;
- permanent domain validation failure;
- deleted/canceled resource where the operation is no longer applicable;
- unsupported operation/configuration;
- provider rejection that explicitly requires user/operator/business input rather than time.

### Unknown / ambiguous outcome

A third category is required where a side effect may have completed but Tio cannot confirm it.

The job must reconcile/check before deciding whether to retry. Blind repetition is prohibited for non-idempotent side effects.

## Retry Budget

Retries must be **bounded**.

Each job type must define:

- maximum number of attempts and/or total retry time budget;
- maximum age/deadline after which the work is stale;
- retryable failure categories;
- permanent failure categories;
- ambiguous-outcome reconciliation behavior;
- terminal action when the budget is exhausted.

Do not create infinite retry loops.

A user-visible workflow must not remain "pending" forever solely because a background job keeps retrying.

## Backoff

Retry delay should increase for repeated transient failures and include jitter where concurrent retries could create a thundering herd.

Conceptually:

```text
attempt fails transiently
  -> bounded increasing delay
  -> optional provider Retry-After / equivalent respected when safe
  -> jitter where useful
  -> next attempt
```

Rules:

- no tight retry loops;
- respect safe provider retry guidance such as `Retry-After` where applicable;
- cap delays so stale work eventually reaches a defined terminal/reconciliation state;
- choose exact attempt counts/delay values from workload/provider/SLO evidence rather than one repository-wide magic number;
- resetting attempt count by re-enqueueing the same poisoned logical job is not a valid recovery strategy.

## Visibility Timeout and Retry Delay

Queue visibility timeout and retry backoff are related but different.

- **visibility timeout** protects an in-flight attempt from normal concurrent redelivery;
- **retry/backoff delay** controls when the next attempt should become eligible after a known failure.

Do not use an excessively long visibility timeout as a substitute for a real retry policy.

If processing can exceed the visibility window, either redesign/bound the work or define a safe visibility-extension strategy at implementation time. Duplicate-safe processing remains mandatory either way.

## Terminal Failure / Dead-Letter Policy

A dead-letter mechanism is a **terminal-failure boundary**, not a second infinite retry loop.

A job moves to terminal/dead-letter handling when:

- a permanent failure is identified;
- retry budget is exhausted;
- message schema is unsupported/malformed;
- repeated processing proves the job is poisoned;
- operator/business intervention is required before safe continuation.

The implementation may use a dedicated dead-letter queue, terminal-failure table, provider feature, or another durable mechanism. TNYX-32 does not preselect the physical storage.

Minimum terminal record should be sufficient to diagnose/reconcile without copying unnecessary sensitive payloads. Conceptually retain:

```text
job_type
job_id / opaque reference
schema_version
terminal_failure_category
attempt_count
first_enqueued_at
last_attempt_at
safe error code/category
correlation/trace reference when useful
```

Do not store raw secrets, tokens, health payloads, provider responses, or unrestricted exception dumps in dead-letter records.

## Dead-Letter Replay

Replay must be deliberate.

Before replay:

1. identify why the job failed;
2. confirm the cause is fixed or no longer applies;
3. confirm the operation is still relevant;
4. preserve the original logical/idempotency identity when it is still the same business operation;
5. do not manufacture a new key solely to force duplicate side effects;
6. re-check current canonical state before performing stale mutations.

Bulk replay requires bounded batches and observable progress; do not release an unbounded backlog into providers/database at once.

## Stale Work and Cancellation

A queued message is not authority to apply an obsolete operation forever.

Consumers should load current canonical state where practical and verify that the requested operation still applies.

Examples:

- resource deleted after enqueue -> terminate/no-op according to job contract;
- user changed settings before notification generation -> use current approved preference rules;
- newer generation/version supersedes an older derived-data job -> old job should no-op or terminate safely;
- account deletion/cancellation boundary -> pending work must not recreate deleted state.

Whether a stale job is a successful no-op or terminal failure must be defined per job type.

## Event-Driven Jobs

An event-driven job originates from a concrete event/request/state transition.

Conceptual flow:

```text
authorized event
  -> enqueue logical job
  -> one or more delivery attempts
  -> one intended business effect
```

Where the source event has a durable unique identity, it is a strong candidate input to the idempotency identity.

Repeated delivery of the same source event must not create a new business operation unless the product contract explicitly defines it as one.

## Scheduled Jobs

A scheduled job originates from a time rule rather than a domain event.

Conceptual flow:

```text
scheduler
  -> logical occurrence/window
  -> enqueue/invoke job
  -> duplicate-safe processing
```

A scheduled job must define:

- schedule owner and timezone semantics;
- logical occurrence/window identity;
- whether overlapping executions are allowed;
- missed-run behavior;
- catch-up/coalescing behavior;
- maximum staleness/deadline;
- idempotency identity for one logical occurrence.

### Scheduled occurrence identity

Deduplication should normally derive from the **logical scheduled occurrence**, not the exact timestamp when infrastructure happened to fire.

For example, a daily job should conceptually identify "the intended daily occurrence/window" rather than creating a new business identity every time Cron retries or starts a few seconds late.

Exact timezone/local-day semantics belong to the domain owning the schedule and must not be guessed by infrastructure.

## Missed-Run Policy

Every recurring scheduled job must choose one behavior rather than accidentally replaying everything:

- **skip** — old occurrence is no longer useful;
- **coalesce** — process one current job covering the missed period;
- **bounded catch-up** — process selected missed occurrences up to a defined limit;
- **strict replay** — process every missed occurrence only where business correctness actually requires it.

Unbounded catch-up after an outage is prohibited.

## Overlap and Concurrency

Scheduled or event-driven duplicates can execute concurrently.

State-mutating jobs must not assume "the scheduler only fires once" or "one worker reads this message" is enough concurrency protection.

If concurrent attempts could conflict, use a durable invariant such as:

- unique operation guard;
- expected-state/version transition;
- transactional claim/lease where appropriate;
- domain-specific serialization.

Idempotency is not a substitute for all concurrency control, and concurrency control is not a substitute for idempotency.

HTTP optimistic-concurrency/ETag policy belongs to TNYX-134; queue/job duplicate safety remains here.

## Ordering

Do not assume global FIFO business correctness merely because a queue offers FIFO-style reads.

If job B must not apply before job A, the domain must encode/enforce that invariant through current state/version/precondition logic or a deliberately serialized job design.

A retry of an older job must not overwrite a newer canonical state transition.

## Side-Effect Ordering

For workflows that both mutate Tio state and call an external provider, implementation must define the failure boundary explicitly.

Do not casually use this unsafe shape:

```text
mutate local DB
call provider
crash between steps
retry entire workflow blindly
```

or the reverse without a reconciliation plan.

The real implementation may require transactional state, an outbox-like handoff, provider idempotency, or a compensating/reconciliation workflow. This policy does not preselect one architecture; it requires the partial-failure state to be explicit and recoverable.

## Retry and User-Visible State

Where background work affects UX, the owning product contract should distinguish states such as:

```text
pending
processing (optional)
succeeded
failed / needs attention
canceled / superseded (when applicable)
```

Do not return synchronous success for an eventual side effect and then hide a permanent background failure forever.

Exact UI is product-owned, not defined here.

## Observability

Follow [Observability](OBSERVABILITY.md).

Minimum async reliability signals once implemented should cover:

- attempts by job type/outcome;
- retry count/rate;
- retry delay/backoff age where useful;
- terminal/dead-letter count;
- dead-letter age;
- duplicate/idempotency rejection/no-op count where measurable;
- ambiguous-provider-outcome count;
- scheduled missed/coalesced/catch-up occurrences where relevant;
- job processing duration and queue delay;
- replay/reconciliation success/failure.

Do not use raw user IDs, job IDs, resource IDs, message bodies, provider payloads, or free-text exception strings as metric labels.

TNYX-121 owns numeric alert/SLO thresholds.

## Privacy and Security

Retry infrastructure must not multiply sensitive data unnecessarily.

Rules:

- minimal queue payload remains the source message contract;
- retries should reuse references, not append growing copies of request/provider payloads;
- dead-letter storage follows the same data-classification/retention controls as other operational data;
- secrets/tokens/OTP/password/Auth headers never enter queue/dead-letter records;
- logs/traces expose safe error categories, not sensitive payloads;
- privileged retry/replay must preserve the original authorization/business boundary and must not become an RLS-bypass escape hatch.

## Restore and Recovery Boundary

A database restore can move canonical state and pending/processed job evidence to an earlier point in time.

Before a real queue goes production, recovery testing must verify how the system handles:

- a canonical mutation restored but its acknowledgement lost;
- a job restored to pending after its side effect already occurred externally;
- deduplication/outcome evidence restored to a different point than provider state;
- dead-letter/replay state after recovery.

This is why provider idempotency/reconciliation and durable local operation identities remain necessary even when the queue itself is durable.

Database recovery policy remains owned by [Database Backup & Recovery](DATABASE_BACKUP_RECOVERY.md).

## Implementation Gate

This document authorizes **no runtime/platform mutation**.

Until a concrete asynchronous workload and explicit implementation approval exist:

- do not enable `pgmq`;
- do not create queues, retry tables, idempotency tables, dead-letter tables/queues, or scheduler tables;
- do not configure Supabase Cron;
- do not create/deploy queue-consuming Edge Functions;
- do not create `services/worker`;
- do not add Redis/Valkey/SQS/Kafka;
- do not add provider-side idempotency integrations;
- do not add worker deployment or secrets;
- do not mutate protected user data to test retry behavior.

## Implementation-Time Checklist

For every newly approved async job:

1. Define the logical job identity.
2. Define whether duplicate effects are possible and the idempotency strategy.
3. Define the idempotency identity and retention window.
4. Define canonical success outcome.
5. Classify retryable, permanent, and ambiguous failures.
6. Define bounded attempts/total retry budget.
7. Define bounded increasing backoff/jitter and provider retry guidance.
8. Define visibility timeout separately from retry delay.
9. Define terminal/dead-letter behavior.
10. Define manual replay/reconciliation rules.
11. Define stale/canceled/superseded behavior.
12. If external provider side effects exist, verify provider idempotency/read-back semantics.
13. If scheduled, define timezone, occurrence identity, overlap, missed-run and catch-up rules.
14. Add safe retry/dead-letter/idempotency observability.
15. Test crash after side effect but before acknowledgement.
16. Test visibility expiry/concurrent duplicate attempts.
17. Test ambiguous provider timeout.
18. Test permanent poison message.
19. Test replay after the underlying fault is fixed.
20. Test stale job against newer/deleted canonical state.
21. Verify no secret/sensitive payload leaks into messages, retry records, dead-letter records, logs, traces, or alerts.

## Acceptance for TNYX-32

- [x] Idempotency keys/equivalent deduplication are required where duplicate execution could corrupt or duplicate state.
- [x] Logical job identity is separated from delivery/attempt identity.
- [x] Retryable, permanent, and ambiguous provider outcomes are explicitly separated.
- [x] Retries are bounded and use a workload-specific increasing backoff policy rather than tight/infinite loops.
- [x] Dead-letter/terminal-failure handling and deliberate replay rules are defined without preselecting a storage implementation.
- [x] Scheduled jobs are explicitly separated from event-driven jobs.
- [x] Scheduled occurrence identity, missed-run, overlap, catch-up, staleness, and timezone semantics are required per scheduled job.
- [x] Duplicate/concurrent execution must not corrupt canonical user state.
- [x] HTTP idempotency remains separate under TNYX-134.
- [x] No queue/worker/Cron/runtime/platform implementation is authorized by this documentation slice.
