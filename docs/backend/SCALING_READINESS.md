# Scaling Readiness

## Status

**Canonical capacity and scaling-trigger baseline for Tio's future protected API, database, queue, worker, Storage, and provider dependencies.**

This document is the first bounded documentation slice of Linear TNYX-121. It defines **when scaling work becomes justified** and the order in which Tio should investigate capacity pressure. It does not complete the full TNYX-121 SLO, incident-response, runbook, or resilience-exercise scope.

It is documentation only. It does **not** create `services/api`, `services/worker`, a load balancer, Redis/Valkey, read replicas, multi-region infrastructure, sharding, Kubernetes, queue workers, dashboards, alerts, or Supabase configuration.

Related contracts:

- [Architecture](ARCHITECTURE.md)
- [Observability](OBSERVABILITY.md)
- [Initial Queue Strategy](QUEUE_STRATEGY.md)
- [Async Reliability](ASYNC_RELIABILITY.md)
- [Database Backup & Recovery](DATABASE_BACKUP_RECOVERY.md)
- [Feature Rollout](FEATURE_ROLLOUT.md)

Linear ownership remains separate:

- **TNYX-37** owns the telemetry signals needed to measure latency, errors, saturation, queue delay, dependency health, and release context.
- **TNYX-30** owns first-choice queue technology and queue escalation criteria.
- **TNYX-31** owns future `services/worker` process architecture.
- **TNYX-32** owns retry/idempotency/backoff/dead-letter/scheduling correctness.
- **TNYX-39** owns deployment, rollback, health/readiness gates, and reproducible infrastructure/configuration policy.
- **TNYX-49** owns database/Storage recovery, RPO/RTO, restore verification, and migration safety.
- **TNYX-121** owns this capacity/scaling baseline plus later SLO, alert, incident, runbook, and resilience-exercise completion.

## Current Architecture Truth

Today the canonical platform shape is:

```text
Flutter / Wear clients
        ↓
Supabase Auth
        ↓
Supabase Postgres + RLS
        ↓
approved Storage / Edge Function paths where required
```

Future protected server destinations are documented but not implemented:

```text
future services/api      # Node.js + TypeScript + Fastify modular monolith
future durable queue     # Supabase Queues/pgmq first candidate when approved
future services/worker   # only after a real async workload requires it
```

Therefore this document must not claim current API-instance capacity, worker throughput, Redis hit rate, queue drain rate, or multi-region behavior. Those metrics do not exist yet.

## Core Principle

**Scale from measured user-facing pressure, not architecture fashion.**

A high CPU number by itself is not the scaling decision, and a slow user workflow is not automatically solved by adding servers.

The expected reasoning order is:

```text
user-facing degradation or capacity evidence
        ↓
identify actual bottleneck
        ↓
correct inefficient work / query / concurrency first where practical
        ↓
scale the constrained component
        ↓
measure again
        ↓
introduce a new infrastructure class only when simpler steps no longer meet the target
```

No component should be scaled because a diagram says it is the "next layer."

## Required Scaling Invariants

### Request-serving API must remain horizontally replicable

When `services/api` exists, one request-serving instance must not become the only durable owner of business state required by later requests.

Process-local memory may hold bounded ephemeral data such as:

- in-flight request context;
- short-lived computed values;
- local connection pools;
- local caches whose loss is safe;
- telemetry buffers where loss semantics are acceptable.

It must not become the canonical owner of:

- authenticated sessions that cannot survive instance replacement;
- user/domain records;
- durable job state;
- entitlement/billing truth;
- irreplaceable workflow progress;
- locks/coordination whose loss would corrupt business state.

If a request must be routable to another healthy API instance without losing canonical state, horizontal replication remains possible.

This is a scaling invariant, not authorization to create multiple API instances now.

### Durable truth stays in an approved durable owner

Current canonical durable user/domain truth remains Supabase/Postgres/Storage according to each domain contract.

Future cache/queue/search infrastructure must not silently become authoritative merely because it improves latency or throughput.

### Cache is an optimization, not the first fix

Do not add a distributed cache until evidence identifies a repeatable read/computation bottleneck that caching can materially improve and the workload has explicit freshness/invalidation/privacy rules.

### Scaling must preserve correctness

More replicas/workers increase concurrency. Scaling is not accepted if it breaks:

- RLS/authorization boundaries;
- API compatibility;
- HTTP concurrency/idempotency rules;
- async idempotency and ordering;
- migration compatibility;
- privacy/redaction;
- recovery expectations.

## Capacity Evidence Before a Scaling Decision

Before adding a new infrastructure layer, record enough evidence to answer:

1. **What user-facing workflow is degraded or approaching its limit?**
2. **Which component is actually constrained?**
3. **Is the pressure sustained/repeatable or a one-off incident?**
4. **Can an inefficient query, payload, algorithm, retry pattern, or provider call be fixed first?**
5. **What measurable improvement is expected from the proposed scale action?**
6. **What new failure/cost/consistency burden does the action introduce?**
7. **How will success and rollback be verified?**

Useful evidence may include:

```text
request rate / concurrency
p50 / p95 / p99 workflow latency
error / timeout rate
CPU / memory / event-loop/runtime lag
connection-pool utilization
DB slow-query latency and lock/contention signals
DB CPU / IO / connection saturation
queue depth and oldest-message age
queue arrival rate vs drain rate
worker concurrency / utilization / processing duration
Storage latency / error / throughput / quota pressure
provider latency / throttle / quota / availability
regional user latency and failure distribution
release/version correlation
cost trend where material
```

TNYX-37 defines safe telemetry shape. TNYX-121 later owns accepted numeric SLO/alert thresholds.

## Threshold Rule

This document intentionally does **not** invent one repository-wide number such as "CPU > 70% means scale."

Before a production capability is declared capacity-ready, its owner must record a threshold with:

```text
component / workflow
metric or SLI
baseline load
threshold
sustained evaluation window
user-facing symptom/risk
planned action
success evidence
rollback/fallback
owner
```

Host/resource thresholds must be correlated with real workflow latency, errors, queue delay, or capacity risk. A resource percentage without workload context is not enough.

## Initial Capacity Test Scenarios

When the relevant runtime exists, capacity evidence should include representative production-critical flows rather than a single synthetic endpoint.

Candidate scenario families:

### API / user-facing

- authenticated owner-scoped read;
- authenticated bounded list/pagination read;
- representative validated mutation;
- burst of concurrent ordinary requests;
- dependency latency increase;
- rate-limit/rejection behavior after TNYX-29 implementation;
- rolling instance replacement once deployment architecture exists.

### Database

- common indexed reads at expected concurrency;
- write/update contention on representative owned resources;
- connection-pool saturation test;
- slow-query/index regression detection;
- migration/backfill impact assessed separately from ordinary request load.

### Queue / worker

Only after a queue/consumer exists:

- normal enqueue and drain;
- burst backlog then recovery;
- duplicate/redelivery path;
- provider throttling causing slower drain;
- one unhealthy consumer/worker removed;
- terminal/dead-letter growth and bounded replay.

### Storage

Only for implemented Storage-backed capabilities:

- representative upload/download metadata flow;
- provider quota/error behavior;
- signed/private access path where applicable;
- recovery remains independently governed by TNYX-49.

### Provider dependencies

- ordinary provider latency;
- throttling/quota response;
- timeout/outage behavior;
- degraded optional capability without taking down unrelated core workflows.

Exact load quantities come from expected product traffic and measured behavior, not arbitrary architecture numbers.

## Scaling Ladder

The ladder is a **decision order**, not a deployment checklist.

```text
0. Current direct Supabase foundation
        ↓ when a protected API is genuinely required
1. One simple horizontally-replicable services/api deployment
        ↓ when measured API capacity/failure isolation requires more instances
2. Multiple API instances behind provider-native routing/load balancing
        ↓ only for measured repeatable read/computation pressure
3. Bounded cache where correctness + invalidation are explicit
        ↓ when async backlog exists and workers are the bottleneck
4. Scale queue consumers/workers
        ↓ when database is the measured constraint
5. Query/index/pool/compute optimization; read replicas for proven read pressure
        ↓ only after single-region/single-primary strategies cannot meet approved targets
6. Regional isolation / multi-region evaluation
        ↓ only after simpler DB scaling and data-model options are insufficient
7. Partitioning/sharding evaluation last
```

Steps may be skipped when they do not match the bottleneck. Do not add every layer merely because an earlier one exists.

## API Capacity Trigger

A second/more API instance becomes justified when evidence shows one healthy instance cannot safely meet the approved user-facing capacity/availability target, for example:

- sustained latency/error/timeout degradation while downstream dependencies remain healthy;
- runtime CPU/memory/event-loop saturation correlated with workflow degradation;
- one instance cannot meet expected concurrent request load with safe headroom;
- deployment/maintenance availability requirements require instance replacement without full service interruption;
- a failure-isolation requirement needs unhealthy instance removal.

Before scaling out:

- remove obvious blocking/inefficient code;
- verify dependency/database pressure is not the real bottleneck;
- confirm request-serving state is horizontally replicable;
- confirm rate limits/idempotency/concurrency rules work across replicas;
- define health/readiness behavior under TNYX-29/TNYX-39.

Do not invent a standalone self-managed load-balancer stack if the selected deployment platform later provides appropriate routing. Provider choice remains deferred to deployment architecture.

## Database Capacity Trigger

Database scaling starts with evidence, not replicas by default.

Investigate in this order where applicable:

1. query shape and missing/ineffective indexes;
2. unbounded reads or payload over-fetching;
3. N+1/repeated application requests;
4. lock contention / transaction scope;
5. connection-pool misuse/exhaustion;
6. database compute/IO/memory constraints;
7. read-heavy workload that remains constrained after query/compute optimization.

### Read replicas

Evaluate read replicas only when:

- read traffic is a proven database bottleneck;
- candidate reads can tolerate replica consistency/lag semantics;
- routing reads away from primary materially improves the approved target;
- failover/recovery/operational behavior is understood.

Do not route authorization-sensitive or consistency-critical reads to replicas without proving their semantics are acceptable.

### Sharding is last

Do **not** choose a shard key today.

Sharding becomes an evaluation only after evidence shows that the approved workload cannot be met safely through simpler options such as:

- query/index/data-model improvement;
- bounded pagination;
- connection/pool tuning;
- appropriate database compute scaling;
- workload separation where justified;
- read replicas for eligible read pressure;
- partitioning where it solves a demonstrated table/query problem.

A future sharding proposal must document:

```text
measured limit that current topology cannot meet
candidate shard key and distribution evidence
hot-key / skew analysis
cross-shard transaction/query impact
RLS/auth implications
migration/backfill plan
rebalancing strategy
backup/restore implications
operational ownership/cost
```

No sharding ticket/implementation is authorized by this document.

## Cache / Redis Boundary

Redis/Valkey is **not selected infrastructure today**.

A distributed cache becomes worth evaluating only when there is measured evidence of repeated expensive reads/computation or shared ephemeral coordination needs that cannot be handled safely/simply by the existing platform.

Before adding one, define:

- exact cacheable object/result;
- source of truth;
- key scope/cardinality;
- TTL/freshness requirements;
- invalidation strategy;
- privacy/authorization behavior;
- cache-miss behavior;
- stampede protection where needed;
- failure behavior when the cache is unavailable;
- memory/cost bound;
- telemetry proving the cache helps.

### Never-truth rule

If Redis/Valkey is introduced later as cache/ephemeral coordination, losing it must not permanently delete canonical user/domain state.

```text
cache unavailable / flushed
→ performance may degrade
→ canonical durable state remains valid
→ service can recover/repopulate safely
```

This does not preclude Redis/Valkey from being evaluated later for a separately approved queue/coordination workload; that would require its own correctness/recovery review. It is not selected by this document.

## Queue and Worker Capacity Trigger

Queue scaling is driven primarily by **delay/backlog relative to the user/business target**, not queue depth alone.

Investigate when:

- oldest-message age approaches/exceeds the approved queue-delay target;
- arrival rate persistently exceeds drain rate;
- workers/consumers are saturated;
- retry storms/provider throttling create sustained backlog;
- one job class starves another critical class;
- Postgres-backed queue load begins harming primary database workloads.

Possible actions, chosen from evidence:

1. remove slow/duplicate work;
2. fix retry storms/idempotency failures;
3. adjust bounded worker concurrency;
4. add worker replicas/consumers if the dependency/database can safely absorb them;
5. isolate workload classes when justified;
6. reconsider queue technology under the escalation rules in `QUEUE_STRATEGY.md`.

Adding consumers while the database/provider is already saturated can worsen the incident. Worker scaling must respect downstream capacity.

## Storage Capacity Trigger

Storage scaling/readiness concerns include:

- request latency/error rates;
- provider quota/capacity limits;
- object-count/throughput growth;
- egress/cost pressure where material;
- media transformation/processing bottlenecks;
- regional latency requirements.

Do not solve Storage pressure by moving private durable objects into an unreviewed cache/CDN/public bucket. Privacy/access and independent recovery requirements continue to apply.

## External Provider Capacity Trigger

A provider quota/latency problem is not automatically solved by scaling Tio API/worker instances.

When provider pressure is the bottleneck, investigate:

- quota/rate limit;
- request batching where contract-safe;
- concurrency limits;
- caching of safe provider-independent results where justified;
- backoff/retry behavior;
- degraded/kill-switch behavior;
- provider-plan/capability changes;
- alternate provider only when product/architecture evidence justifies it.

Do not scale worker concurrency through a provider throttle ceiling.

## Regional Isolation / Multi-Region Trigger

Multi-region is **not selected today**.

Evaluate regional isolation only when evidence shows a single-region topology cannot meet approved requirements, such as:

- material sustained latency for an important user population;
- required availability/failure-domain target that one region cannot satisfy;
- legal/data-residency requirement;
- provider architecture forces a regional design change.

A regional proposal must account for Auth, Postgres consistency, Storage, queues, caches, provider affinity, migrations, failover, and recovery. Do not treat "deploy API in two regions" as a complete multi-region architecture.

## Failure-Domain Awareness

Scaling one component can create correlated failure elsewhere.

Examples:

```text
more API replicas
→ more DB connections / provider concurrency

more workers
→ faster queue drain
→ more DB writes/provider calls

cache added
→ cache outage/stampede may increase DB load

read replicas
→ consistency/routing/failover complexity
```

Every scale action must identify the new downstream load and failure modes before rollout.

## Capacity Headroom

Production capacity should not be planned to run continuously at the measured cliff.

For each critical component, the owner must define enough headroom to absorb expected bursts, deploy/restart effects, dependency slowdown, and normal growth without immediate SLO failure.

The exact percentage/headroom target is workload-specific and must be recorded from load-test/production evidence rather than hardcoded globally here.

## Scale-Up vs Scale-Out

Prefer the simplest action that meets the target with acceptable cost and failure behavior.

Possible options include:

- eliminate inefficient work;
- optimize queries/indexes;
- increase existing provider compute/plan capacity;
- scale out stateless API instances;
- scale worker consumers;
- introduce cache/read replicas only when the workload proves value.

Vertical scaling is not inherently bad, and horizontal scaling is not inherently mature. The decision is evidence + operability + cost.

## Capacity Decision Record

For each material scaling change, retain a lightweight evidence record in the owning PR/Linear issue/runbook:

```text
date/environment
affected capability/workflow
observed load
baseline latency/error/queue delay
constrained component
root cause evidence
options considered
chosen change
expected improvement
measured post-change result
cost/operational impact
rollback/fallback
owner
```

If a new durable architecture class is selected—such as Redis as an accepted shared platform, a new queue provider, multi-region data topology, or sharding—apply the ADR threshold in `docs/adr/README.md` at that time.

## What Does Not Justify Scaling Work

Do not create infrastructure merely because:

- a generic architecture diagram includes it;
- another large company uses it;
- future user count is unknown;
- a single host metric briefly spikes;
- a framework/library supports clustering;
- a future feature might someday need it;
- an AI-generated review proposes a standard "web-scale" stack.

Require a concrete capacity, latency, availability, recovery, ownership, or provider constraint.

## Relationship to Recovery

Capacity readiness does not replace recovery readiness.

Examples:

- a read replica is not a backup;
- more API instances do not restore corrupted data;
- a cache does not improve PostgreSQL RPO;
- multi-region deployment does not automatically make Storage/Auth/data recovery correct;
- queue replicas/consumers do not define dead-letter recovery.

Use [Database Backup & Recovery](DATABASE_BACKUP_RECOVERY.md) for RPO/RTO/restore policy.

## Relationship to Deployment

This document defines **when** capacity topology may need to change. TNYX-39 owns how API/worker deployments, readiness gates, rollback, and reproducible infrastructure/configuration are represented and operated.

A scaling topology is not operational until deployment/recovery/observability evidence exists.

## Relationship to SLO and Incidents

This first slice intentionally does not finalize:

- numerical API availability/latency SLOs;
- error budgets;
- alert severity thresholds;
- incident severity definitions;
- escalation/communication rules;
- complete runbooks;
- game-day/resilience drill success criteria.

Those remain open under TNYX-121 and are required before the issue can be marked Done.

## Current Readiness State

```text
scaling policy / decision ladder        documented by this slice
services/api runtime capacity           NOT MEASURED — runtime not implemented
queue runtime capacity                  NOT MEASURED — queue not enabled
services/worker capacity                NOT MEASURED — worker not implemented
Redis/cache platform                    NOT SELECTED
read replica topology                   NOT SELECTED
multi-region                            NOT SELECTED
sharding                                NOT SELECTED
full TNYX-121 SLO/incident baseline     STILL PENDING
```

## Implementation Gate

This policy does **not** authorize:

- `services/api` or `services/worker` scaffold;
- load balancer or replica deployment;
- Supabase compute/plan changes;
- read replicas;
- Redis/Valkey;
- queue enablement or worker scaling;
- multi-region deployment;
- sharding/partition migration;
- Kubernetes/service mesh;
- load tests against protected production user data;
- alert/dashboard/provider configuration.

Any future implementation requires an explicitly authorized bounded slice and safe test data/environment.

## Acceptance for This TNYX-121 Slice

- [x] Current vs future topology is explicit.
- [x] Scaling decisions require user-facing + component-level evidence.
- [x] API horizontal-replication invariant is documented without creating replicas.
- [x] Capacity evidence/template and representative test scenarios are documented.
- [x] API, database, queue/worker, Storage, provider, and regional triggers are documented.
- [x] Cache/Redis is deferred; if introduced as cache/ephemeral coordination it cannot become canonical user/domain truth.
- [x] Read replicas are conditional on proven read pressure and acceptable consistency semantics.
- [x] Multi-region and sharding remain evidence-gated; no shard key is selected.
- [x] Scaling is explicitly separated from backup/recovery and deployment implementation.
- [x] Full TNYX-121 SLO/incident/runbook/resilience scope remains open and is not falsely marked complete.
- [x] No runtime/platform/configuration change is introduced by this documentation slice.
