# Deployment & Rollback Architecture

## Status

**Canonical provider-neutral deployment, rollback, and reproducible-infrastructure policy for Tio's future protected API and worker runtimes.**

This document completes the planning scope of Linear TNYX-39. It defines how future `services/api` and `services/worker` releases must be built, promoted, health-gated, rolled back, and reconciled with database migrations and declared infrastructure configuration.

It is documentation only. It does **not** create `services/api`, `services/worker`, a deployment workflow, hosting account, load balancer, container registry, infrastructure stack, production environment, secret, Supabase migration, queue, health endpoint, or runtime resource.

Related contracts:

- [Architecture](ARCHITECTURE.md)
- [Worker Architecture](WORKER_ARCHITECTURE.md)
- [Scaling Readiness](SCALING_READINESS.md)
- [Observability](OBSERVABILITY.md)
- [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md)
- [Database Backup & Recovery](DATABASE_BACKUP_RECOVERY.md)
- [API Lifecycle](API_LIFECYCLE.md)
- [Feature Rollout](FEATURE_ROLLOUT.md)

Linear ownership remains separate:

- **TNYX-39** — this deployment/rollback/reproducible-infrastructure contract.
- **TNYX-29** — future API health endpoint, rate-limit, structured-logging, timeout, and related runtime implementation details.
- **TNYX-31** — worker process lifecycle, readiness, graceful shutdown, and independent process boundary.
- **TNYX-49** — database/Storage recovery, forward-only migration safety, RPO/RTO, and restore ownership.
- **TNYX-120** — capability rollout and emergency kill-switch policy.
- **TNYX-121** — SLO/alert thresholds, incident severity, runbooks, and resilience exercises.

## Audit Snapshot — 2026-08-30

Current repository truth:

```text
services/api       absent
services/worker    absent
production deploy provider selected    no
production API/worker workflow         no
versioned server IaC/config contract    no
```

Current `.github/workflows/` contains mobile/native CI workflows only:

```text
android-native-ci.yml
flutter-ci.yml
```

They are not evidence of a production API/worker deployment system.

Current Supabase state is separately managed through the active `supabase/` workspace and repository-owned migration history. This document must not imply that a future server deploy owns Supabase schema history.

## Core Principles

### 1. Deployable processes are independent

Once they exist:

```text
services/api       = independently buildable/deployable process
services/worker    = independently buildable/deployable process
```

A worker change must not require an API redeploy when their contracts remain compatible. An API rollback must not require restarting the worker merely because both live in one repository.

Shared repository history does not mean shared release lifecycle.

### 2. Application deployment is not database recovery

Keep these actions separate:

```text
application deploy / rollback
!=
database migration / forward correction
!=
database restore / PITR recovery
```

A bad application release is normally corrected by application rollback/redeploy while the database remains at its current compatible schema.

A bad applied migration is normally corrected with a new forward migration.

A historical database restore is reserved for accepted recovery incidents such as destructive corruption/data loss where forward repair is not the safe solution.

### 3. Deployment provider remains replaceable

This policy does not select Render, Fly.io, AWS, GCP, Azure, Kubernetes, or another hosting/deployment platform.

The selected provider may supply routing, health checks, rollout controls, secret injection, autoscaling, logs, or artifact build facilities. Tio's architectural contract must remain expressible independently of that provider.

If a provider selection becomes durable/cross-cutting enough to cross the ADR threshold, record it through the ADR policy at that time.

### 4. Declared configuration beats undocumented click-ops

Production infrastructure and non-secret configuration required to recreate a workload must be represented by a versioned, reviewable declaration or an equivalent reproducible configuration contract.

Emergency dashboard changes may be necessary during an incident, but they must not silently become permanent source of truth.

### 5. Unready releases do not receive production work

A process must not receive user traffic or new queue work until its required startup/readiness contract passes.

Readiness is a traffic/work-admission decision, not merely "the process exists."

## Deployment Units

### Future `services/api`

The API deployment unit owns the future request-serving process:

- Node.js + TypeScript + Fastify modular monolith;
- HTTP request handling;
- auth/token verification and authorization boundaries;
- synchronous protected operations;
- approved async enqueueing;
- request telemetry;
- readiness/liveness behavior once implemented.

Its release lifecycle must not depend on process-local durable business state.

### Future `services/worker`

The worker deployment unit owns background queue consumption and job execution.

Its deployment lifecycle follows `WORKER_ARCHITECTURE.md`:

- independently deployable from API;
- restart-safe;
- bounded concurrency;
- readiness before accepting new work;
- graceful shutdown/drain;
- unacknowledged incomplete work remains safe for redelivery;
- queue/message compatibility must survive mixed release versions.

### Supabase platform

Supabase is not bundled into either application deployment unit.

Canonical migration ownership remains:

```text
supabase/migrations/
```

Auth/project configuration, RLS, Storage, database schema, functions, and other Supabase platform changes follow their own reviewed configuration/migration paths.

Do not hide database DDL inside API startup or worker startup.

## Release Identity & Provenance

Every production application release must be traceable to immutable source/build evidence.

At minimum retain:

```text
environment
process: api | worker
source commit SHA
release/artifact identifier
build timestamp or build record
configuration declaration revision
expected database/migration compatibility
release initiator/automation identity
deploy start/end
final result
```

Where the platform exposes an immutable artifact digest/image digest/package revision, record it rather than relying only on a mutable tag such as `latest`.

The exact packaging format is not selected here. Container images are allowed but not mandated by this policy.

## Build Once / Promote Safely

Prefer a release model where the artifact evaluated for production is traceable to the same source/build output that passed the required verification.

Avoid rebuilding materially different source between approval and production without producing a new release identity.

A provider that performs builds during deployment may still satisfy this rule if the resulting artifact is tied deterministically to the approved commit/configuration and the release evidence records that artifact.

## Environment Boundaries

Follow `SECRETS_AND_ENVIRONMENTS.md`:

```text
local / development
preview / staging
production
```

Production remains a separate trust boundary.

Rules:

- production secrets are not reused in lower environments;
- a staging/preview deployment must not silently target production dependencies because its own dependency is missing;
- environment identity comes from trusted deployment configuration;
- production infrastructure credentials are not exposed to ordinary PR/test jobs;
- deployment evidence names the environment explicitly;
- the same semantic configuration names may exist across environments while values/references remain environment-scoped.

## Reproducible Infrastructure / Configuration Contract

Before a future production API or worker is considered deployable, enough non-secret infrastructure/configuration must be declared to reconstruct its intended operating shape.

The exact mechanism may be Terraform, Pulumi, provider-native declarative files, versioned platform configuration, or another reviewable reproducible contract. This policy does not preselect the tool.

The declaration should cover applicable properties such as:

```text
process/service identity
runtime/artifact reference
region/location
resource class / CPU / memory intent
minimum/maximum instance or worker count where applicable
network exposure / routing intent
health/readiness configuration
graceful-termination/drain settings
non-secret environment/config values
secret reference names (not values)
queue/consumer attachment where applicable
scaling configuration where accepted
provider dependency identifiers
```

Do not commit real secret values merely because an IaC tool can represent them.

## Secret References

Repository/deployment declarations may contain semantic secret references, for example conceptually:

```text
SUPABASE_SERVER_CREDENTIAL -> production secret reference
PROVIDER_API_SECRET        -> production secret reference
```

They must not contain actual secret material.

Secret values follow `SECRETS_AND_ENVIRONMENTS.md` and remain rotatable/revocable outside source-code changes.

A deployment should fail safely when a required secret reference cannot be resolved rather than silently falling back to a lower environment or a more privileged credential.

## Deployment Provider Replaceability

Provider-specific implementation details should remain at the deployment/configuration edge.

Avoid making application/domain code depend on concepts such as a specific provider's deployment ID, autoscaler API, dashboard state, or health-check payload unless a real requirement justifies that coupling.

Application code may expose generic operational contracts such as readiness/liveness signals. The provider maps those contracts into its own routing/deployment model.

Conceptually:

```text
Tio process contract
  -> readiness/liveness/shutdown/config semantics
  -> provider adapter/configuration
  -> provider-specific deployment mechanics
```

## Release Sequence

A normal future production release should conceptually follow this order, adjusted for the actual change:

```text
1. identify exact source/release
2. verify tests/static checks/security gates required for that slice
3. validate configuration + required secret references
4. confirm database/API/queue mixed-version compatibility
5. apply any separately approved compatible database expansion if required
6. deploy candidate application process
7. wait for startup/readiness gate
8. admit traffic or queue work only after readiness
9. observe release-specific telemetry
10. complete promotion when acceptance signals remain healthy
11. record release evidence
```

Not every release has a database change. Do not create a migration merely because an application deploy occurs.

## Pre-Deployment Compatibility Check

Before production deployment, answer the applicable compatibility questions:

### API

- Can the new API serve currently supported mobile/watch clients?
- Does `/v1` remain compatible under `API_LIFECYCLE.md`?
- Are any feature/capability changes safely controlled by `FEATURE_ROLLOUT.md`?
- Does the release require a schema that already exists or can coexist with the previous release?
- Can the previous API release still run against the post-migration schema if rollback is needed?

### Worker

- Can new workers process message versions still present in the queue?
- Can old workers safely coexist during rollout?
- Will a new producer emit a message version unsupported by currently active workers?
- If worker rollback is needed, can the old worker understand messages already produced by the new release?

### Database

- Is the migration additive/mixed-version-safe where a rolling deployment needs overlap?
- Is a destructive contract step deferred until old supported code no longer needs it?
- Is recovery posture known for any risky migration?

## Database Migration Ordering

Use the expand/migrate/contract pattern from `DATABASE_BACKUP_RECOVERY.md`.

### Expand

Create compatible schema capability first when the new application needs it.

Examples:

- add new nullable column/table/index/function;
- add compatibility path;
- preserve old reads/writes while mixed releases exist.

### Deploy / Migrate behavior

Deploy code that can use the expanded shape. Run bounded backfills or data transitions separately when needed and observable.

### Contract later

Remove old schema only after evidence shows no supported client/process/release depends on it.

Do not combine an application rollout with immediate destructive cleanup when rollback or older clients/processes still require the old shape.

## No Hidden Migration-on-Boot

Production schema ownership must not depend on "first API instance starts and silently runs whatever migration is pending."

Reasons:

- concurrent instance startup can race;
- application rollback becomes coupled to schema history;
- migration authorization becomes implicit;
- failure timing becomes difficult to control/observe;
- worker/API processes may start with different assumptions.

Database migrations must remain an explicit reviewed operation owned by `supabase/migrations/` and deployment procedure/evidence.

## Health, Liveness & Readiness

### Liveness

Liveness indicates whether a process is alive enough that restart may be appropriate if it is irrecoverably stuck.

It should not perform broad expensive dependency checks on every probe merely to prove every external integration is healthy.

### Readiness

Readiness answers whether this instance should receive **new** production work.

Examples that can make an instance unready:

- required configuration is invalid/missing;
- process initialization is incomplete;
- required core dependency cannot support the process's intended work;
- the process is shutting down/draining;
- the deployed release is internally unhealthy.

An optional provider outage should not automatically make unrelated core API capability unready when the product can safely degrade that feature. Feature/dependency degradation remains explicit rather than pretending the entire process is dead.

TNYX-29 owns the concrete API health endpoint implementation. `WORKER_ARCHITECTURE.md` owns worker process readiness semantics. TNYX-39 owns the deployment rule: **do not admit production work before readiness passes.**

## Safe Probe Output

Health/readiness responses and deployment diagnostics must not expose:

- secrets/tokens;
- database connection strings;
- private hostnames unless operationally required and access-controlled;
- raw user identifiers or health data;
- stack traces/provider payloads to public callers;
- complete environment dumps.

Public health surfaces should be minimal. Detailed diagnostics belong in protected operational telemetry.

## API Rollout

Exact rollout mechanism depends on the selected provider and production topology. The invariant is:

```text
new API release starts
  -> validates config
  -> becomes ready
  -> receives production traffic
  -> old release drains/remains fallback while strategy allows
```

When multiple instances exist, removing/replacing an instance should stop new traffic before termination and allow bounded in-flight requests to complete where practical.

A one-instance early topology may have different availability characteristics. The production readiness evidence must reflect those actual characteristics rather than claiming zero-downtime merely because the policy supports rolling releases.

## Worker Rollout

Worker releases have different admission semantics from HTTP traffic.

Conceptually:

```text
new worker starts
  -> validates config + handlers + queue access
  -> becomes ready
  -> begins receiving new work

old worker
  -> stops receiving new work
  -> drains bounded in-flight jobs
  -> acknowledges only confirmed success
  -> exits
```

Mixed worker versions require compatible versioned queue messages.

If message format changes:

```text
consumers understand new version first
  -> then producers may emit new version
  -> old messages remain readable until drained/expired
```

Do not emit a new incompatible job version first and hope workers upgrade before receiving it.

## Release Strategies

This policy does not mandate one strategy for every deployment.

Possible provider-supported strategies include:

- replacement deployment;
- rolling update;
- canary/staged traffic;
- blue/green style promotion.

Choose the smallest strategy that meets the approved availability/risk target.

The selected strategy must still satisfy:

- release identity/provenance;
- readiness before work admission;
- compatibility during overlap;
- observable promotion criteria;
- defined rollback/fallback.

Do not introduce complex deployment topology solely for architectural appearance.

## Rollback Decision Tree

Rollback begins with identifying **what actually failed**.

```text
bad application release, schema compatible
  -> rollback/redeploy previous application artifact

bad non-secret configuration change
  -> restore previous declared configuration
  -> redeploy/reconcile as required

feature behavior unsafe but runtime otherwise healthy
  -> use approved feature kill switch when appropriate
  -> then fix/rollback code or configuration deliberately

applied migration defective but data/schema can be repaired forward
  -> new forward corrective migration
  -> do not edit/remove applied history

destructive corruption/data loss requiring historical recovery
  -> TNYX-49 database recovery/restore procedure
```

Do not use database restore as the default application rollback button.

## Application Rollback

Application rollback is appropriate when:

- a known previous artifact exists;
- current database/schema remains compatible with it;
- current queue/message contracts remain compatible for worker rollback;
- reverting code does not itself recreate an already-completed irreversible side effect.

Rollback evidence should identify the exact target artifact/release, not "whatever was deployed before" without provenance.

After rollback, verify the same readiness and critical smoke signals used for normal promotion.

## Configuration Rollback

Non-secret configuration must be versioned/reviewable enough to restore a known previous state.

A configuration rollback must not:

- restore an expired/revoked credential value;
- silently point production at staging/dev;
- re-enable a security-sensitive feature contrary to a current emergency decision;
- overwrite a newer database migration history.

Secret rotation/revocation follows the secret incident/rotation procedure rather than treating old credential values as ordinary rollback artifacts.

## Database Migration Failure

If a migration fails before being applied/committed, stop and diagnose according to the migration tool/provider's actual state.

If a migration is recorded/applied and the resulting schema is wrong:

```text
preserve applied history
  -> create a new corrective migration
  -> verify data/RLS/constraints/application compatibility
```

Never edit a historical applied migration to make repository history look as though the bad migration never existed.

A database restore is only for an explicitly accepted recovery incident under TNYX-49.

## Rollback Is Not Side-Effect Reversal

Rolling code back does not automatically undo external actions already completed by the newer release.

Examples:

- provider request already completed;
- notification already sent;
- payment/refund already performed in a future billing flow;
- database mutation committed;
- queue job already acknowledged.

Such cases require idempotency, reconciliation, compensating action, or domain-specific repair. Do not assume redeploying old code rewinds the world.

## Rollback Triggers

TNYX-121 will own numeric SLO/alert thresholds. Until those are accepted, a release must still have explicit abort/rollback criteria appropriate to its risk.

Examples of evidence that may require stopping/promotion rollback:

- readiness repeatedly fails;
- material increase in API error/timeout rate attributable to release;
- authentication/authorization regression;
- data-integrity or RLS regression;
- critical workflow latency regression;
- worker poison/crash loop;
- queue oldest-age/backlog growth attributable to new worker;
- provider calls become uncontrolled/retry-stormed;
- memory/CPU/connection saturation caused by release;
- new release cannot coexist with current schema/message/client versions.

Do not roll back automatically based on one noisy host metric without confirming the release relationship and user/system impact where practical.

## Rollback Verification

After rollback/fallback:

- target release becomes ready;
- affected critical workflow returns to expected behavior;
- auth/authorization remains correct;
- database migration head remains understood;
- queue workers/message versions remain compatible;
- no continuing retry/backlog storm remains;
- release-specific error signal returns toward baseline;
- follow-up/corrective action is recorded.

If rollback does not restore service, escalate as an incident rather than repeatedly flipping releases.

## Feature Kill Switch vs Deployment Rollback

A kill switch can be faster and narrower than a full deploy rollback for a risky capability.

Use it when:

- the feature can be safely disabled independently;
- disabling new work reduces harm;
- the underlying process can remain healthy.

A kill switch is not authorization, entitlement, database recovery, or code repair. The underlying defect still requires a durable fix/rollback.

Follow `FEATURE_ROLLOUT.md`.

## Emergency Dashboard / Click-Ops Rule

Emergency provider-console changes may be necessary when the normal declaration/deploy path is unavailable or too slow for immediate containment.

When an emergency change occurs, record at minimum:

```text
time/environment
operator
incident/reason
resource/config changed
previous intended state
new emergency state
expected effect
verification
follow-up owner
```

Then reconcile the accepted state back into the versioned infrastructure/configuration declaration as soon as operationally safe.

Do not let undocumented dashboard state become the permanent production source of truth.

If the emergency state should be temporary, explicitly restore/reconcile it after the incident.

## Drift

Production configuration can drift when console/API changes differ from declared repository state.

Before production readiness, the chosen deployment/configuration mechanism should provide a practical way to detect or audit material drift.

At minimum, operators must be able to answer:

- what state is declared;
- what state is deployed;
- why they differ;
- who owns reconciliation.

Do not blindly overwrite unknown production drift if doing so could destroy an emergency safety control; inspect and reconcile deliberately.

## Scaling & Deployment

Scaling configuration is a deployment concern only after `SCALING_READINESS.md` evidence approves the capacity action.

Examples:

- API replica count;
- worker replica/concurrency shape;
- resource class;
- provider routing/load-balancing configuration.

TNYX-39 defines how accepted configuration is declared/reproducible. It does not authorize adding replicas, Redis, read replicas, multi-region, sharding, or Kubernetes.

## Observability During Releases

Every production deploy/rollback must be correlated with operational telemetry without exposing sensitive payloads.

Useful release context includes:

```text
service/process
release/artifact identifier
commit SHA
environment
deploy phase
start/end time
result
rollback target when applicable
```

Operators should be able to compare pre/post release signals such as:

- request error/timeout rate;
- latency;
- readiness/restarts;
- DB/provider latency/failures;
- queue delay/backlog/worker failures;
- resource saturation where useful.

Do not add raw user IDs, request bodies, health data, tokens, secrets, or unrestricted provider payloads to deployment telemetry.

## Deployment Evidence Record

Every production release should retain a lightweight record, either through the deployment platform plus repository/Linear/PR evidence or another accepted system.

Conceptual record:

```text
environment
process
commit SHA
artifact/release ID
configuration revision
migration head / schema compatibility note
release strategy
deploy start/end
readiness result
smoke/verification result
observed regression signals
final state: promoted | rolled back | failed
rollback target/reason if applicable
operator/automation identity
follow-up links
```

The record must not include secret values or sensitive user payloads.

## Minimum Production Deployment Checklist

Before first production API/worker rollout, the relevant process must have:

- [ ] exact artifact/release provenance;
- [ ] environment-specific non-secret config declaration;
- [ ] server secrets referenced through protected runtime facilities;
- [ ] startup config validation;
- [ ] liveness/readiness semantics appropriate to the process;
- [ ] safe sanitized health output;
- [ ] graceful shutdown/drain behavior where applicable;
- [ ] deployment and rollback operator/automation ownership;
- [ ] database migration compatibility plan;
- [ ] old/new API or queue-message compatibility for rolling overlap;
- [ ] observable release markers and core telemetry;
- [ ] explicit rollback/fallback target;
- [ ] documented reconciliation path for emergency click-ops;
- [ ] reproducible infrastructure/configuration mechanism selected and reviewed;
- [ ] production readiness/SLO/runbook gates required by TNYX-121 before launch.

## Implementation Boundary

This TNYX-39 documentation does **not** authorize:

- creating `services/api` or `services/worker`;
- selecting or provisioning a hosting provider;
- creating GitHub Actions deployment workflows;
- creating a container registry/image;
- creating a load balancer or DNS route;
- provisioning API/worker replicas;
- creating Terraform/Pulumi/provider IaC resources;
- configuring production secrets;
- applying Supabase migrations;
- enabling queues/Cron/Edge Functions;
- changing Supabase compute/plan/region;
- executing a production deployment or rollback;
- performing a database restore;
- creating Redis, read replicas, multi-region, sharding, or Kubernetes infrastructure.

Those require separately authorized implementation/operations slices.

## Acceptance for TNYX-39

- [x] API and worker are defined as independently deployable processes.
- [x] Startup/readiness gates are mandatory before new traffic/work admission.
- [x] Database migrations remain forward-only and owned by `supabase/migrations/`.
- [x] Application rollback, configuration rollback, forward database correction, and database restore are distinct actions.
- [x] Deployment provider remains replaceable at the architecture boundary.
- [x] Production non-secret infrastructure/configuration must be versioned and reproducible through IaC or an equivalent declared contract.
- [x] Secret values remain outside source control while semantic secret references remain reproducible.
- [x] Emergency click-ops require evidence and reconciliation back into declared state.
- [x] API/worker mixed-version compatibility and worker message rollout ordering are documented.
- [x] Release provenance and deployment evidence requirements are explicit.
- [x] No runtime, provider, CI/CD, IaC, Supabase, migration, or production mutation is introduced by this documentation slice.
