# Database Backup, Recovery & Migration Safety

## Status

**Canonical recovery and production migration-safety baseline for Tio World.**

This document defines the operational contract for PostgreSQL recovery, Supabase Storage recovery, schema/data migrations, restore verification, and recovery ownership. It is a planning and readiness policy; it does not enable backups, PITR, Storage replication, or any runtime/backend service.

It complements [Supabase Strategy](SUPABASE_STRATEGY.md), [Security](SECURITY.md), [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md), and the repository-owned `supabase/migrations/` history.

## Current Audited Posture — 2026-08-28

Canonical Supabase project:

```text
project      tio-world
region       ap-south-1
Postgres     17.6
org plan     Free
status       ACTIVE_HEALTHY
```

Current live migration history contains 24 applied migrations. Canonical schema/function/RLS change ownership remains `supabase/migrations/`; applied migrations are historical records and must not be edited in place.

Current recovery posture is **not production-ready**:

- the organization is on the Supabase Free plan;
- Supabase currently documents managed daily backup access for Pro, Team, and Enterprise projects;
- Supabase recommends Free projects regularly create logical dumps and maintain off-site copies;
- Point-in-Time Recovery (PITR) is a paid-plan add-on and is not part of the current project posture;
- no accepted Tio restore exercise currently proves PostgreSQL RTO;
- PostgreSQL backup/restore does **not** restore Storage objects;
- current Storage contains an `avatars` bucket, so Storage durability must be treated as a separate recovery path rather than assumed from database backup coverage.

Official Supabase references used for this baseline:

- <https://supabase.com/docs/guides/platform/backups>
- <https://supabase.com/docs/guides/platform/clone-project>

This document must be re-audited against current Supabase documentation before production backup/PITR configuration is purchased or changed.

## Recovery Objectives

### Initial production launch floor

Unless a later product, legal, or business requirement sets a stricter target, Tio's initial engineering recovery floor is:

| Durable state | RPO target | RTO target | Current status |
| --- | ---: | ---: | --- |
| PostgreSQL/Auth database state | <= 24 hours | <= 8 hours | Not yet proven; launch gate open |
| Supabase Storage user-owned durable objects | <= 24 hours | <= 8 hours | Recovery mechanism/evidence not yet established |
| Repository-controlled migrations/config docs | effectively 0 for committed source | <= 2 hours to retrieve/redeploy source | Covered by Git history, but runtime reconciliation still required |

Definitions:

- **RPO (Recovery Point Objective):** maximum acceptable committed data loss after a recoverable incident.
- **RTO (Recovery Time Objective):** target time to restore the capability to an accepted usable state, including validation rather than merely completing a provider restore action.

These are Tio operational targets, not claims about a provider SLA. A restore exercise must measure actual performance. If the measured result exceeds the target, production readiness remains blocked until the recovery mechanism is improved or the target is explicitly re-approved.

### PITR decision rule

PITR is not selected merely because it exists.

```text
approved PostgreSQL RPO >= 24h
→ managed daily backup or equivalent verified off-site backup may satisfy the target

approved PostgreSQL RPO < 24h
→ PITR or another proven sub-day recovery mechanism becomes required
```

Supabase currently documents PITR with up-to-seconds restore selection and a worst-case WAL backup RPO of about two minutes. PITR availability, compute requirements, retention options, and cost must be rechecked at the time of configuration.

Current decision:

```text
PITR configured: NO
Production PITR requirement: CONDITIONAL on final approved RPO
Production launch on current Free recovery posture: NOT ACCEPTED
```

## Backup Retention

Do not hardcode a retention duration without tying it to recovery needs, provider capability, data-governance requirements, and cost.

For every production environment, record:

```text
environment
backup mechanism
configured retention
PITR enabled/disabled
PITR retention, if enabled
earliest/latest recoverable point where applicable
off-site backup location/owner where applicable
last successful backup verification
last restore exercise
next restore exercise
```

Current project record:

```text
environment: current canonical project / pre-production
managed backup retention accepted by Tio: none recorded
PITR: not enabled
manual off-site dump cadence: not yet accepted as an operational control
production readiness: blocked on recovery configuration + restore evidence
```

A future upgrade to Pro/Team/Enterprise does not itself complete this control. The actual backup/PITR configuration and retention must be recorded after the upgrade.

## Recovery Ownership & Exercise Cadence

### Named operational owner

Primary recovery owner: **Backend & Platform**.

The recovery owner is responsible for:

- confirming the current provider backup/PITR configuration;
- keeping restore access limited to authorized operators;
- scheduling and recording restore exercises;
- coordinating application, database, Storage, and Auth/config validation;
- recording measured RPO/RTO evidence;
- escalating when a target cannot be met.

A specific human operator/on-call owner must be named in the production runbook before launch; this architecture baseline does not invent an on-call rotation before one exists.

### Restore exercise cadence

For each production environment:

1. **Before first production launch** — one successful end-to-end recovery exercise is mandatory.
2. **Quarterly after launch** — repeat recovery verification at least once per quarter.
3. **After material recovery changes** — repeat after changing backup provider/mode, PITR configuration, retention, major database version, Storage recovery mechanism, or restore procedure.
4. **After a real recovery incident** — review evidence and run a follow-up exercise after corrective actions.
5. **Before/after exceptional destructive migrations** — require explicit recovery evidence appropriate to the risk rather than relying only on the quarterly cadence.

A restore exercise is not complete when a restore button reports success. Post-restore application/security invariants must pass.

## PostgreSQL Backup & Restore Boundary

Supabase database backup covers database state, including PostgreSQL schemas/data and Auth database records according to the provider's supported restore mechanism.

It does **not** mean the whole project configuration is automatically recoverable.

Recovery inventory must separately consider:

- PostgreSQL schemas and rows;
- `auth` schema records;
- RLS policies, grants, functions, triggers, and constraints;
- migration-history alignment;
- database extensions/settings;
- Auth project settings/provider configuration;
- Edge Functions and their deployment/configuration;
- API/project configuration;
- Storage buckets, policies, metadata, and physical objects;
- any future external queue/cache/search/vector/provider state.

Supabase's restore-to-new-project documentation explicitly notes that Storage objects/settings, Edge Functions, Auth settings/API keys, Realtime settings, extensions/settings, and replicas may require separate reconfiguration. Therefore Tio must never equate "database restored" with "full platform recovered."

## Storage Recovery Is Independent

Supabase database backups contain Storage metadata but do not include the physical objects stored through the Storage API. Restoring an old database backup does not recreate a Storage object that was deleted after that backup.

Therefore every durable user-media implementation must define a separate Storage recovery strategy before production readiness is claimed.

Current audit:

```text
existing bucket: avatars
physical-object recovery evidence: NOT VERIFIED
```

The current public/private access model of `avatars` is owned by the relevant profile/media architecture work and is not changed by this recovery policy. Future private personal media is separately tracked by the Progress/private-media architecture. TNYX-49 owns only the recovery rule: **database backup is never evidence of object recovery.**

Before any Storage-backed feature is considered recovery-ready, record:

- which objects are durable vs replaceable;
- backup/replication/export mechanism;
- recovery point/cadence;
- restore procedure;
- object-to-database reconciliation procedure;
- how missing/orphan objects are detected;
- measured Storage RPO/RTO;
- account-deletion/privacy interaction with retained recovery copies.

## Application Rollback != Database Rollback

These are separate operational actions.

### Application rollback

Use when application code is bad but persisted data/schema remains compatible.

```text
bad app deploy
→ rollback/redeploy application version
→ database remains at current schema
```

Application rollback is preferred over database rollback when data is valid and schema is compatible.

### Forward database fix

Use when a migration has shipped and the safest correction is a new migration.

```text
migration defect
→ preserve applied history
→ add new forward-only corrective migration
→ verify invariants
```

This is the default Tio database correction strategy.

### Database restore/rollback

Use only for incidents where restoring historical database state is the accepted recovery action, such as destructive corruption/data loss that cannot be safely repaired forward.

A database restore can discard writes after the restore point and causes service disruption. It therefore requires explicit incident/recovery authorization, a selected restore point, understood data-loss window, and post-restore reconciliation.

Never restore the production database merely to undo an inconvenient schema change that can be repaired safely with a forward migration.

## Migration Ownership

Canonical Supabase migration ownership:

```text
supabase/migrations/
```

Rules:

- never edit an already applied migration to change production history;
- add a new forward migration for corrections;
- do not create a second schema owner under a future backend service;
- migration ordering must remain deterministic;
- every production DDL change must have source control evidence;
- every production migration requires post-apply verification;
- repository and live migration history must be reconciled when drift is suspected.

The current project already has a live migration history, so historical files are evidence, not templates to rewrite.

## Expand / Contract Strategy

Prefer mixed-version-safe schema evolution.

### Expand

Add new compatible capability first:

- nullable/new columns where appropriate;
- new tables/indexes/functions/policies;
- compatibility reads/writes when both old and new application versions may coexist.

### Migrate

Move reads/writes/data gradually and verify:

- backfill status;
- old/new read agreement where relevant;
- authorization semantics;
- index/query behavior;
- retry/idempotency behavior.

### Contract

Remove old schema only after evidence shows no supported client/service still depends on it.

Do not couple an app release to immediate destructive schema removal when older installed mobile clients may still exist.

## Destructive Migration Gate

The following require explicit destructive-change review before production execution:

- `DROP TABLE`, `DROP COLUMN`, destructive type conversion;
- broad `DELETE`/`UPDATE` backfill with irreversible meaning;
- constraint changes that can invalidate existing data;
- FK/cascade changes affecting deletion behavior;
- RLS/grant changes that can expose or lock user data;
- identity/Auth ownership rewrites;
- media/storage metadata rewrites that may orphan physical objects.

Required review evidence:

```text
why destructive change is needed
rows/objects affected
precondition queries/counts
mixed-version compatibility impact
backup/recovery state
forward-fix or restore decision
expected data-loss window, if any
execution owner
verification queries/tests
abort criteria
```

`CASCADE` DDL is not a shortcut for uncertain dependency cleanup. Dependencies must be reviewed explicitly.

## Backfill Safety

Large or sensitive backfills must be bounded and observable.

Prefer:

- idempotent/re-runnable logic;
- stable batching key/cursor;
- bounded batch size;
- explicit progress counts;
- restartability after partial failure;
- separation from latency-sensitive request paths;
- pre/post invariant checks;
- no assumption that an application deploy and large data rewrite must complete in one transaction/window.

For small backfills, simplicity is acceptable, but the expected row count and verification still need to be known before production execution.

Never manufacture production user data just to satisfy a migration test.

## Production Migration Execution Checklist

Before apply:

- [ ] source migration exists under `supabase/migrations/`;
- [ ] current live migration head is known;
- [ ] migration has been reviewed for destructive behavior;
- [ ] compatibility with currently supported clients is understood;
- [ ] RLS/grant/Auth implications are reviewed;
- [ ] affected row/object counts are known when meaningful;
- [ ] recovery posture is known for the affected durable state;
- [ ] verification queries/tests are prepared;
- [ ] execution owner is explicit.

After apply:

- [ ] migration appears in live migration history;
- [ ] expected schema/functions/policies/grants exist;
- [ ] data invariants pass;
- [ ] security/performance advisors are reviewed when applicable;
- [ ] relevant app/runtime path is smoke-tested when the change affects one;
- [ ] no unexpected orphan/missing rows or Storage references are introduced;
- [ ] tracker/PR records the accepted production evidence.

## Post-Restore Verification

After a PostgreSQL restore, validate at minimum:

1. project/database is reachable;
2. expected migration history/schema version is present;
3. core table/row-count sanity checks match the selected restore point;
4. required PK/FK/unique/check constraints exist;
5. RLS is enabled where expected;
6. expected RLS policies and role grants exist;
7. SECURITY DEFINER/function boundaries and `search_path` expectations remain safe;
8. Auth identities and canonical public roots reconcile;
9. canonical Email/Phone ownership/projection invariants remain clean;
10. Edge Functions/Auth/project configuration needed by the application is revalidated separately;
11. Storage bucket configuration is revalidated separately;
12. physical Storage objects are checked using the independent Storage recovery evidence;
13. application sign-in and one representative owner-scoped read/write path pass;
14. security advisors are reviewed before declaring recovery accepted.

Provider restore completion is only an intermediate milestone. Tio recovery is accepted after these application/security checks pass.

## Recovery Evidence Record

Every restore exercise should record:

```text
environment
incident/exercise ID
date/time
operator
backup/PITR mechanism
selected restore point
expected RPO loss window
actual observed data loss or recovery point
restore start/end
measured RTO
Postgres verification result
Auth/RLS verification result
Storage verification result
external durable-state verification result
issues discovered
follow-up owner/actions
```

Do not put user Emails, tokens, UUIDs, health records, private media, or other sensitive payloads into the recovery evidence record. Use aggregate/invariant evidence.

## Production Launch Gate

Database/storage recovery is **NOT READY** for production while any of these are unresolved:

- production backup mechanism not selected/configured;
- configured retention not recorded;
- final approved RPO/RTO not recorded;
- current project remains on a plan/posture that cannot satisfy the approved target;
- no successful pre-launch PostgreSQL restore exercise;
- Storage contains durable user objects but has no independent recovery evidence;
- restore ownership/runbook access is unclear;
- post-restore Auth/RLS/security verification has not been demonstrated.

This gate is intentionally separate from feature completion. A feature can be code-complete while production recovery readiness remains incomplete.

## Implementation Boundary

TNYX-49 defines policy only. It does **not** authorize:

- a Supabase plan upgrade;
- enabling PITR;
- changing backup retention;
- creating scheduled dump jobs;
- restoring/cloning the current project;
- creating/deleting Storage buckets;
- applying migrations;
- creating a backend service/worker;
- destructive recovery testing against current user data.

Those actions require their own explicit execution authorization and cost review where applicable.

## Acceptance for TNYX-49

- [x] Initial measurable production RPO/RTO engineering floor is defined.
- [x] Current Free-plan recovery posture and launch gap are recorded truthfully.
- [x] PITR requirement is derived from the approved RPO rather than assumed.
- [x] Backup/PITR retention must be recorded from actual configuration rather than invented.
- [x] Backend & Platform owns restore readiness; human operator is required in the production runbook.
- [x] Pre-launch + quarterly restore-exercise cadence is defined.
- [x] PostgreSQL and Storage recovery are explicitly independent.
- [x] Application rollback, forward database fix, and database restore are separate decisions.
- [x] Expand/migrate/contract is the default mixed-version-safe migration pattern.
- [x] Destructive migrations require explicit recovery and verification evidence.
- [x] Backfills must be bounded/observable/restartable where risk/size warrants it.
- [x] `supabase/migrations/` remains the canonical migration owner.
- [x] Post-restore RLS/Auth/security validation is mandatory.
- [x] No backup/PITR/runtime/schema/Storage mutation is introduced by this documentation slice.
