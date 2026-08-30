# Worker Process Architecture

## Status

**Canonical process-architecture policy for the future `services/worker` runtime.**

This document completes the planning scope of Linear TNYX-31. It defines the lifecycle, queue-consumption, concurrency, shutdown, failure, and ownership boundaries for a future asynchronous worker without creating the worker folder, deployment, queue, scheduler, or runtime code.

Related contracts:

- [Architecture](ARCHITECTURE.md)
- [Initial Queue Strategy](QUEUE_STRATEGY.md)
- [Async Reliability](ASYNC_RELIABILITY.md)
- [Observability](OBSERVABILITY.md)
- [Scaling Readiness](SCALING_READINESS.md)
- [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md)
- [Supabase Server Access](SUPABASE_SERVER_ACCESS.md)

Linear ownership remains separate:

- **TNYX-30** — queue technology, message, visibility, acknowledgement, and queue-use boundaries.
- **TNYX-31** — this worker process/lifecycle/consumption architecture.
- **TNYX-32** — retry, idempotency, backoff, dead-letter, replay, and scheduling reliability rules.
- **TNYX-39** — deployment provider, rollout/rollback, readiness gates, and IaC/reproducible deployment contract.
- **TNYX-121** — production SLOs, capacity thresholds, incidents, runbooks, and resilience exercises.

## Current Truth

`services/worker` does **not** exist today.

Current repository/platform state is:

```text
Flutter / Wear clients
        ↓
Supabase Auth + Postgres/RLS

future protected API: services/api     # not implemented
future async worker:   services/worker  # not implemented
future first queue candidate: Supabase Queues / pgmq # not enabled today
```

This document is not authorization to create any of those future runtime resources.

## Why a Separate Worker Process

Long-running/background work should not depend on HTTP request lifetime, client connectivity, or API-process request/response assumptions.

When a real durable asynchronous workload is approved, the target long-lived relationship is:

```text
producer / services/api / approved trigger
        ↓
durable queue
        ↓
services/worker
        ↓
Supabase / approved providers / internal operations
```

The worker is a **separate runnable process**, not a second HTTP API and not a copy of API business logic.

A narrow one-off Supabase-native task may still justify an Edge Function or another bounded runtime when the owning implementation slice proves it is the smaller correct boundary. TNYX-31 defines the architecture of `services/worker` when that general worker process is actually needed; it does not force every async task into it.

## Worker Creation Gate

Do not create `services/worker` merely because:

- TNYX-31 is documented;
- `services/api` is planned;
- a conceptual repository tree contains `services/worker`;
- a feature might someday need AI, notifications, imports, or reconciliation;
- queue infrastructure exists or becomes available.

Create/scaffold `services/worker` only when all are true:

1. a concrete approved asynchronous workload exists;
2. that workload benefits from execution beyond client/HTTP request lifetime;
3. the selected queue/trigger contract is explicit;
4. the worker runtime is the smallest appropriate trusted execution boundary;
5. implementation is separately authorized.

Typical candidate workloads include daily/weekly derived insights, notification scheduling/delivery orchestration, AI embeddings/summaries, imports/reconciliation, or subscription/provider reconciliation. These examples do not authorize those product features.

## Process Boundary

`services/worker` is one independently runnable process boundary.

Conceptually:

```text
process startup
  → load + validate non-secret config references
  → establish required trusted clients/adapters
  → initialize telemetry
  → establish queue consumer(s)
  → declare ready only when required dependencies are usable
  → consume bounded work
  → handle shutdown signal
  → stop accepting new work
  → drain/cancel according to job contract
  → close resources
  → exit
```

The worker must not require an inbound public HTTP request to perform its normal work.

A private liveness/readiness/admin surface may be added only when deployment/operations architecture requires it; TNYX-31 does not preselect an HTTP server just for health checks.

## API vs Worker Responsibilities

### `services/api`

The future API owns synchronous request/response concerns such as:

- request parsing/validation;
- authentication and authorization at the HTTP boundary;
- HTTP error/status contracts;
- synchronous use-case execution;
- enqueueing an authorized async operation where appropriate;
- returning an accepted/pending resource contract when the product flow is asynchronous.

### `services/worker`

The future worker owns background execution concerns such as:

- polling/receiving durable jobs;
- validating supported job/message versions;
- loading current canonical state by reference where appropriate;
- enforcing the narrow job authorization/trust boundary;
- executing the async use case;
- applying TNYX-32 idempotency/retry/terminal-failure rules;
- acknowledging only confirmed successful work;
- producing safe operational telemetry;
- graceful shutdown and restart-safe execution.

The worker must not inherit HTTP assumptions such as status codes, response-body envelopes, request sockets, or client timeouts as its internal business contract.

## Business Logic Ownership

The worker is not a second copy of API business logic.

Avoid this shape:

```text
services/api/src/modules/foo/duplicate-business-rule.ts
services/worker/src/jobs/foo/another-copy-of-same-rule.ts
```

Business rules should remain behind stable application/domain boundaries. Worker-specific code should adapt queue messages into those use cases rather than reimplementing them.

However, do **not** create a shared TypeScript package preemptively.

Shared code may move into `packages/ts/*` only when both API and worker genuinely exist and a real stable reuse boundary is demonstrated. Until then, avoid speculative package extraction and keep the owning code with the first real process/module.

## Job Handler Boundary

A worker handler should be narrow and explicit.

Conceptually:

```text
queue message
  → validate envelope + schema version
  → map to supported job type
  → load/validate current canonical state
  → enforce job preconditions
  → execute application operation
  → record/confirm durable outcome
  → acknowledge queue message
```

Handlers should not receive unrestricted queue payload objects deep into domain code. Parse and normalize at the consumer boundary.

Each job type must define:

```text
job_type
supported schema version(s)
required references
success condition
idempotency strategy
retryable failures
permanent failures
ambiguous-outcome reconciliation
stale/canceled behavior
concurrency/ordering rule
acknowledgement condition
terminal/dead-letter behavior
```

TNYX-32 owns the cross-job reliability policy; the first workload fills in the workload-specific values.

## Queue Consumption Pattern

For durable business jobs, follow the queue strategy:

```text
read / receive
  → message becomes temporarily unavailable to other consumers
  → validate + process duplicate-safely
  → confirmed success
  → delete/archive/acknowledge

failure/crash before acknowledgement
  → do not claim success
  → queue visibility/redelivery semantics apply
```

Do not destructively remove a durable job before its intended side effect is confirmed.

If future queue technology differs from Supabase Queues, preserve the same logical acknowledgement boundary unless the newly approved architecture explicitly changes the semantics.

## Polling / Receive Loop

The worker loop must be bounded and stoppable.

Conceptual loop:

```text
while accepting_work:
    receive bounded batch
    if empty:
        wait/back off without busy-spin
    else:
        process within concurrency limit
```

Rules:

- no tight empty-queue polling loop;
- batch size and polling interval are configuration/capacity decisions, not hard-coded repository-wide constants;
- polling must be interruptible for graceful shutdown;
- failure to reach the queue/dependency must not create an uncontrolled retry storm;
- dependency retry/backoff follows the relevant reliability policy;
- consumer telemetry must distinguish queue empty/idle from dependency failure.

## Concurrency

Worker concurrency must be **bounded**.

Do not use unbounded `Promise.all`, unbounded goroutine/task spawning, or one-process-per-message assumptions.

Each deployed worker/job type must define the concurrency ceiling from:

- provider limits/rate limits;
- database connection/pool limits;
- queue throughput/visibility behavior;
- CPU/memory profile;
- job latency and SLO;
- duplicate/concurrency safety;
- cost constraints.

Conceptually:

```text
consumer capacity
= process replicas
× per-process concurrency
```

Increasing both at once can multiply provider/database load unexpectedly. Scaling decisions must use `SCALING_READINESS.md` evidence.

### Per-job concurrency

Different job types may need different limits.

Examples:

- CPU-heavy generation may require low per-process concurrency;
- provider-limited jobs may be capped below local CPU capacity;
- independent lightweight reconciliation jobs may tolerate higher concurrency;
- jobs with domain serialization requirements may need per-resource locking/version preconditions rather than more workers.

Do not assume FIFO queue ordering alone provides domain serialization.

## Stateless Process Rule

The worker process must remain restart-safe and horizontally replicable where the workload permits.

Do not keep authoritative job completion, deduplication state, schedule state, or user/domain truth only in process memory.

Process-local memory may hold ephemeral items such as:

- loaded configuration;
- SDK/client instances;
- bounded in-flight task bookkeeping;
- short-lived non-authoritative caches;
- telemetry buffers.

A process restart must not make the system forget whether a durable business side effect already happened when that knowledge is required for correctness.

Canonical durable truth remains in the approved durable system (currently Supabase/Postgres for Tio-owned domain state, plus approved external provider truth where relevant).

## Startup

Worker startup must fail clearly when required configuration is invalid or mandatory dependencies cannot be established safely.

Startup sequence should conceptually:

1. load environment/configuration references;
2. validate required configuration shape;
3. initialize telemetry/logging;
4. establish minimum required trusted clients;
5. register supported job handlers;
6. initialize queue consumer;
7. become ready to receive work.

Do not log complete environment dumps or secret values during startup failure.

Optional provider degradation may allow partial worker capability only when the job-routing architecture explicitly supports it; do not silently mark the whole worker ready while every job type is guaranteed to fail.

## Readiness and Liveness

Operational semantics:

- **liveness** asks whether the worker process/runtime is alive and not irrecoverably stuck;
- **readiness** asks whether this instance should receive new work.

Readiness should become false during shutdown before the process exits.

If queue/provider dependencies are required for all supported work and are unavailable, the worker should not falsely advertise full readiness. Exact probes/endpoints belong to TNYX-39/TNYX-29/deployment implementation rather than this document.

## Graceful Shutdown

Graceful shutdown is mandatory before the worker is production-ready.

On termination signal or deployment drain:

```text
signal received
  → mark instance not-ready / stop accepting new messages
  → stop polling/receiving new work
  → allow bounded in-flight work to finish when safe
  → acknowledge only work whose durable success is confirmed
  → close queue/provider/database/telemetry resources
  → exit
```

Rules:

- receiving new work must stop promptly after shutdown begins;
- shutdown has a bounded grace period set by deployment/job needs;
- do not acknowledge incomplete work merely to exit cleanly;
- if force termination occurs, unacknowledged work must remain/reappear under queue semantics;
- idempotency must protect against the case where a side effect succeeded but acknowledgement did not complete;
- long-running jobs that cannot finish inside the grace period need an explicit checkpoint/cancellation/reconciliation design rather than an indefinitely long shutdown timeout.

Exact operating-system signal names and hosting termination windows are selected at implementation/deployment time.

## In-Flight Cancellation

Not every job is safely cancelable.

A handler must distinguish:

- work not yet started — may remain/unlock for another consumer;
- local compute with no durable side effect yet — may be cancelable if the library supports safe cancellation;
- transactional database mutation in progress — transaction semantics determine outcome;
- external provider operation already sent — outcome may be ambiguous and require reconciliation;
- irreversible provider side effect confirmed — do not pretend cancellation undoes it.

Do not abort an external request merely to satisfy shutdown timing if doing so creates an unknown business outcome without a reconciliation path.

## Failure Boundaries

The worker process must separate:

1. **message validation failure** — unsupported/malformed job contract;
2. **domain/permanent failure** — same job will not become valid with time;
3. **transient dependency failure** — may retry within policy;
4. **ambiguous provider outcome** — reconcile before blind repetition;
5. **process/runtime failure** — crash/OOM/termination; job safety comes from durable queue + idempotency;
6. **systemic dependency outage** — avoid retry storms and surface degraded state/alerts.

A single poisoned message must not crash-loop the entire worker fleet indefinitely.

A systemic dependency outage should not be treated as millions of unrelated business failures; operational telemetry should make the shared dependency cause visible.

## Restart Behavior

Worker restart is expected operational behavior.

After restart:

- no correctness-critical state should depend solely on previous process memory;
- unacknowledged visible-again jobs may be received again;
- idempotency/reconciliation must make duplicate attempts safe;
- unsupported old queue message versions must fail safely rather than being guessed;
- current canonical state must be reloaded when stale queued data could cause incorrect mutation;
- the worker must not assume it owns a job forever because it once received it.

## Scaling

Scale worker capacity only from evidence.

Signals may include:

- sustained oldest-message age / queue delay;
- queue depth growth with known arrival rate;
- drain time exceeding the accepted objective;
- worker saturation while dependencies still have safe headroom;
- provider/database throttling that shows the opposite: concurrency should decrease rather than replicas increase.

Before increasing replicas or per-process concurrency, identify the bottleneck. More workers can make a database/provider bottleneck worse.

`SCALING_READINESS.md` owns the scaling decision ladder and evidence record.

## Observability

Every future worker instance must follow `OBSERVABILITY.md`.

At minimum, operators should be able to observe safely:

- process start/stop/restart;
- readiness state;
- queue receive/idle/error behavior;
- jobs started/succeeded/failed/terminal by bounded job type/outcome;
- processing duration;
- queue delay/oldest age where available;
- retry/redelivery count/rate;
- dead-letter/terminal count;
- current bounded concurrency / in-flight count;
- shutdown start, drain completion, forced-timeout outcome;
- provider/database latency/failure/saturation categories.

Do not metric-label raw job IDs, resource IDs, user IDs, emails, health data, prompts, message bodies, or unrestricted error strings.

## Secrets and Privilege

The worker is a trusted server process, but trust does not mean unrestricted privilege.

Rules:

- secrets remain runtime-injected and environment-scoped;
- no service-role/provider secret enters queue messages;
- use the narrowest credential/role required by each job;
- privileged Supabase access follows `SUPABASE_SERVER_ACCESS.md`;
- never use privileged credentials as automatic fallback after an RLS denial;
- logs/errors never emit secret values or full environment dumps.

If different job families require materially different privilege/security boundaries, consider separate worker process/deployment boundaries only when evidence justifies the isolation. Do not create micro-worker services preemptively.

## Data and Privacy

Queue messages and worker telemetry must minimize sensitive data.

Prefer:

```text
opaque resource reference
→ worker loads current authorized/canonical state
```

over copying complete mutable health/nutrition/workout/profile/AI payloads into queue infrastructure.

A job must respect account deletion/cancellation/current-user-state boundaries. Pending work must not recreate deleted or superseded state merely because an old message exists.

## Deployment Independence

Once `services/worker` exists, it must be independently deployable from `services/api`.

This means conceptually:

- API release does not require worker release when contracts remain compatible;
- worker restart/rollback must not require restarting the API;
- worker capacity may scale independently;
- queue/message contracts must support mixed versions while old messages/process versions can coexist;
- database schema changes remain owned by `supabase/migrations/`, not by either process.

TNYX-39 owns the actual deployment provider, rollout/rollback sequence, health/readiness gates, and reproducible infrastructure/configuration contract.

## API/Worker Compatibility

API producer and worker consumer may run different releases during rolling deployment.

Therefore:

- queue messages are explicitly versioned;
- producers must not emit a message version unsupported by every intended active consumer unless rollout ordering guarantees compatibility;
- consumers should remain backward-readable for message versions that can still be pending;
- destructive message-contract changes require drain/migration/version strategy;
- a worker rollback must not be assumed safe if newer incompatible messages are already in the queue.

This is the async equivalent of mixed-version client/server compatibility; do not couple correctness to simultaneous deployment.

## Shared Package Extraction Rule

`packages/ts/*` is an extraction destination, not a starting requirement.

Extract only when:

1. both real processes need the same stable code;
2. ownership is clear;
3. the dependency direction remains healthy;
4. extraction reduces duplication rather than creating a generic dumping ground.

Good future candidates might include stable pure schemas/contracts or narrow provider-independent primitives. Fastify-specific request types and worker queue adapters should not be pushed into a generic shared package merely to share folders.

## Physical Folder — When Authorized

When the first real worker implementation is separately approved, a minimal shape may start conceptually as:

```text
services/worker/
├─ src/
│  ├─ app/            # process composition / handler registration
│  ├─ jobs/           # queue adapters/handlers by approved workload
│  ├─ infrastructure/ # queue, Supabase, provider, telemetry adapters
│  ├─ config/
│  └─ worker.ts       # startup/shutdown only
├─ test/
├─ package.json
├─ tsconfig.json
└─ README.md
```

This is a future starting shape, not an instruction to create the folder now.

Keep business/domain logic outside `worker.ts`; it should remain process lifecycle/composition only.

## Implementation-Time Checklist

Before creating the first real worker deployment:

- [ ] a concrete async workload is approved;
- [ ] queue/trigger choice is current and verified;
- [ ] minimal versioned job message is defined;
- [ ] handler success and acknowledgement condition are explicit;
- [ ] idempotency identity/equivalent deduplication is defined where needed;
- [ ] retryable/permanent/ambiguous outcomes are classified;
- [ ] retry budget/backoff/terminal handling is defined;
- [ ] stale/canceled/current-state behavior is defined;
- [ ] per-job/process concurrency is bounded;
- [ ] queue polling/receive behavior is stoppable and non-busy;
- [ ] graceful shutdown/drain behavior is tested;
- [ ] forced termination preserves duplicate-safe recovery;
- [ ] secrets/privilege are least-privilege and server-only;
- [ ] logs/metrics/traces follow the safe telemetry policy;
- [ ] worker and API can deploy independently with compatible message versions;
- [ ] scaling/alert/runbook criteria are linked before production launch;
- [ ] no user/domain truth exists only in process memory or cache.

## No-Runtime Authorization

TNYX-31 documentation does **not** authorize:

- creating `services/worker`;
- adding Node/TypeScript dependencies;
- enabling `pgmq` or creating a queue;
- adding Cron/scheduler configuration;
- deploying an Edge Function or worker service;
- creating provider credentials/secrets;
- provisioning Redis/Valkey/SQS/Kafka;
- adding load balancers/replicas;
- creating database/idempotency/dead-letter schema;
- running production background jobs.

Those actions require their owning implementation slices and explicit authorization.

## Acceptance for TNYX-31

- [x] Worker is defined as a separate runnable process for approved long-running/background work.
- [x] Worker creation gate prevents speculative folder/deployment creation.
- [x] Worker lifecycle from startup through queue consumption and graceful shutdown is explicit.
- [x] Worker does not share HTTP request/response assumptions with the API.
- [x] Queue consumption/acknowledgement follows the accepted durable queue boundary.
- [x] Retry, idempotency, terminal failure, and scheduling rules remain owned by TNYX-32 and are integrated rather than duplicated.
- [x] Concurrency is bounded and capacity-driven.
- [x] Graceful shutdown, drain, forced termination, and restart behavior are explicit.
- [x] API and worker remain independently deployable once the worker exists.
- [x] `packages/ts/*` extraction is deferred until genuine shared-code evidence exists.
- [x] No `services/worker` scaffold, queue, scheduler, runtime dependency, deployment, or backend implementation is introduced by this documentation slice.
