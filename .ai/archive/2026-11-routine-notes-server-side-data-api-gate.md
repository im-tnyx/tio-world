# Routine Notes Server-Side Data API Gate

**Status:** Validated
**Completed:** 2026-11-01
**Primary owner:** Product owner / Supabase database owner
**Implementation owner:** Codex
**Independent security reviewer:** `im-tio`
**Affected surfaces:** Supabase Postgres, PostgREST Data API, disposable database security tests and deployment governance

## Scope and approval

Product Owner approval authorizes repository-only implementation, disposable
validation and focused PR review for Linear `TNYX-81`. Hosted Supabase writes,
production migration apply, production hook activation, Notes enablement, PR
merge and deployment remain unauthorized.

The approved narrow historical-migration exception is recorded here: the first
previously merged Notes migration may be edited only to close the independently
confirmed staged-migration exposure. The other seven previously merged Notes
migrations remain unchanged.

The current local database is owner-attested synthetic development/testing data
only. This does not authorize reset, deletion or migration-history repair. No
local persistent database reset or hosted write was performed.

## Final architecture — current source of truth

The implemented design has two coordinated controls:

1. `20261028120000_install_routine_notes_data_api_gate.sql` runs before the
   first Notes migration. It creates the private
   `routine_notes_data_api_gate_state` table with default state `disabled`,
   installs the private `SECURITY DEFINER`
   `private.routine_notes_data_api_gate()` hook with fixed
   `search_path=pg_catalog`, grants only the required private schema usage and
   function execution, and configures `authenticator.pgrst.db_pre_request`.
2. `20261029120000_create_user_workout_routine_notes.sql` creates the Notes
   table, preserves the existing owner-scoped RLS policy and authenticated
   table grant, then creates
   `private.routine_notes_data_api_gate_is_enabled()` and the restrictive
   `routine_notes_data_api_gate_enabled_select` policy in the same migration.
   The policy always requires the explicit `enabled` state and therefore also
   fails closed for authenticated SQL sessions and Realtime-style RLS
   evaluation where `request.path` is absent.

The unmerged
`20261101081122_routine_notes_data_api_embedding_gate.sql` was removed. It is
not part of the final migration order and must not be recreated or applied.
The remaining seven previously merged Notes migrations are unchanged.

The pre-request hook exact-matches the Notes table and the three public Notes
RPC paths. Disabled, missing, null, malformed, unknown or unreadable gate state
returns the deterministic valid PostgREST `403` denial. Non-Notes PostgREST
paths pass through the hook. The restrictive SELECT policy protects embedded
Notes rows without broadening the hook to all Data API requests.

This gate covers PostgREST only. Realtime, Storage, GraphQL, Edge Functions and
direct database connections remain separate boundaries and require their own
controls or explicit release evidence. No Notes publication, Storage object,
Edge Function route or GraphQL exposure is introduced by this slice.

## Migration order and committed-state safety

The supported rollout order is:

1. Replay the existing 72-migration prefix through `20261028110000`.
2. Apply the pre-Notes gate migration
   `20261028120000_install_routine_notes_data_api_gate.sql`.
3. Apply the first Notes migration
   `20261029120000_create_user_workout_routine_notes.sql`; the table,
   authenticated grant, owner RLS and restrictive enabled-state policy are
   committed together.
4. Apply each subsequent Notes migration while the gate remains disabled.
5. Verify direct Notes/RPC denial, empty embedded Notes relations, owner
   isolation and non-Notes availability at every checkpoint.
6. Enable Notes only through a separately authorized production operation.

There is no separate post-Notes embedding-policy migration in the final design.
The earlier design that placed the policy in
`20261101081122_routine_notes_data_api_embedding_gate.sql` and described all
eight Notes migrations as unchanged is superseded historical material, not an
operator instruction.

## Owner approval and implementation ownership

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** `im-tio` as independent security reviewer
**Implementation state:** Complete and merged in PR #720; independent security
approval and five review-thread dispositions completed. This brief is ready for
archive after this closure update.

The Product Owner approved the exact atomic remediation scope before the
historical migration exception was used. Hosted and local persistent migration
history was inspected read-only before the exception: the first Notes migration
was unapplied in the known local and hosted environments. The existing local
database was preserved.

## Repository and tracker handoff

**Implementation branch:** `codex/routine-notes-data-api-gate` (historical)
**Base SHA:** `cd81393598b5f82606c10c38058296b9052e57f4`
**Final PR head:** `4008494063af25c238923810039ee5124d9b3d1e`
**Merge commit:** `b1b7722cf2cbcf45f90cca0a72da56669bb8e455`
**PR:** [#720](https://github.com/im-tnyx/tio-world/pull/720) — merged;
production deployment and Notes activation remain unauthorized
**Linear:** `TNYX-81` remains the bounded planning scope; no tracker status
mutation was authorized
**GitHub #716:** closed after the related validation work
**PR #719:** merged; it is historical context, not deployment evidence

The pre-existing `.ai/tasks/README.md` modification was preserved and its exact
pre-closure text is retained below as historical context. Its two stale Routine
Notes lines were reconciled in the separate documentation-closure slice.

## Disposable validation evidence

Validation used a fresh isolated disposable PostgreSQL/PostgREST runtime with
synthetic fixtures. The existing local persistent database and hosted Supabase
were not used for qualification.

The staged harness validated these ten checkpoints:

- `baseline` — through `20261028110000`
- `pre_notes_gate` — through `20261028120000`
- `first_notes` — through `20261029120000`
- `after_20261030065649`
- `after_20261030074635`
- `after_20261030081321`
- `after_20261031100000`
- `after_20261031110000`
- `after_20261031130000`
- `after_20261031142025` — final schema

The final replay contained 81 migrations and reached
`20261031142025`. All ten staged checkpoints passed SQL and HTTP checks for:

- disabled direct Notes access;
- disabled all three Notes RPC paths;
- disabled parent-resource Notes embedding with an empty relation;
- authenticated SQL fail-closed SELECT behavior without `request.path`;
- owner and cross-owner isolation;
- Nutrition, Workout and Profile availability; and
- migration grant persistence and restrictive policy presence.

The final HTTP matrix also passed enabled owner access, anonymous denial,
malformed/null/missing state denial, exact-path behavior, hook failure,
configuration reload and recovery. Disabled direct Notes/RPC requests returned
HTTP `403` with `routine_notes_data_api_disabled`; disabled embedded Notes
returned HTTP `200` with an empty relation.

Additional validation passed:

- final catalog/security SQL assertions;
- existing Routine Notes persistence SQL;
- `supabase db lint --local --schema public,private --level error`;
- `supabase db advisors --local --type security --level error`;
- `git diff --check`; and
- executable exact-head GitHub Supabase Database CI run `41305474738` passed on
  final PR head `4008494063af25c238923810039ee5124d9b3d1e`; Docs Hygiene CI
  `41305474867` and required attribution checks also passed. Cursor checks were
  neutral/skipped because of external usage limits.

At final PR head `4008494063af25c238923810039ee5124d9b3d1e`, the required checks
were successful and PR #720 received independent `im-tio` approval. The five
review threads were verified and resolved before merge.

Because this documentation-only correction does not change executable behavior,
the disposable database suite is not rerun solely for this file change. The
existing exact-head executable evidence remains valid; documentation hygiene
will rerun after the documentation commit is pushed.

## Security findings and dispositions

Five GitHub review threads were present at the reconciliation point and are now
verified resolved:

1. `4434807726` — Advanced Security embedding bypass. Fixed by the restrictive
   policy in the first Notes migration; disabled embedding was reproduced as
   an empty relation and the thread was resolved after independent reviewer
   disposition.
2. `4435025534` — `im-tio` P1 staged-migration exposure. Fixed by making the
   first Notes migration atomic and validating all ten checkpoints; the thread
   was resolved after staged-checkpoint evidence and independent reviewer
   disposition.
3. `4434897849` — Advanced Security `request.path IS NULL` fail-open policy.
   Fixed by removing the null bypass; the outdated thread was resolved after
   verified reviewer disposition.
4. `4434897857` — Advanced Security ineffective GraphQL table assertion.
   Fixed with extension-aware `graphql.resolve` verification and a separate
   Realtime publication assertion; the outdated thread was resolved after
   verified reviewer disposition.
5. `4435421515` — `im-tio` P2 documentation contradiction. This update
   reconciled the architecture, migration candidates, handoff, validation,
   historical review descriptions and deployment sequence with the final
   source state; the thread was resolved after independent review.

No review thread was resolved solely by the implementation owner. Independent
review from `im-tio` approved the final PR head; implementation-owner comments
remain evidence, not independent approval.

## Historical review record

The original security qualification found that exact-path hook protection alone
allowed parent-resource embedding to reach Notes while disabled. A subsequent
correction removed the `request.path IS NULL` fail-open branch and replaced the
ineffective GraphQL schema-table assertion. The independent P1 review then
confirmed that final-schema security was insufficient because the first Notes
grant preceded the later embedding policy. The approved atomic remediation
closed that committed intermediate-state window.

These findings and superseded designs are retained as history so they are not
lost. They must not be interpreted as the current migration order.

## Deployment and recovery boundaries

No hosted migration, `ALTER ROLE`, production `NOTIFY`, hook activation, Notes
feature enablement, merge or deployment has occurred.

Before any future hosted apply, the owner must separately authorize the
production deployment packet, verify the target migration history, apply the
atomic sequence, reload PostgREST where required, verify disabled direct/RPC
and embedded behavior, verify non-Notes recovery, and only then consider a
separate Notes activation decision.

If the hook or configuration reload fails, deployment stops. Recovery requires
a trusted operator to restore the hook/configuration, reload PostgREST and
verify both Notes denial and ordinary non-Notes availability. No client role may
modify gate state.

## Final handoff

**Current status:** `VALIDATED / ARCHIVED`
**Security status:** P1 remediation independently confirmed by `im-tio`; P2
documentation correction completed; five review threads resolved.
**Merge status:** PR #720 merged at
`b1b7722cf2cbcf45f90cca0a72da56669bb8e455` after exact-head CI and independent
approval.
**Remaining deployment blockers:** hosted migration approval and execution,
PostgREST hook activation, scheduler/backup/recovery gates and separate
production Notes activation approval. TNYX-81 remains broader W4 scope and is
not complete.

### Preserved historical index wording

The following exact text was present in `.ai/tasks/README.md` before this
documentation-closure authorization. It is retained only as historical context
for the pre-merge blocked state and is not current operational guidance:

```md
[Routine Notes Server-Side Data API Gate](routine-notes-server-side-data-api-gate.md) is **BLOCKED**. Design qualification found a default-deny PostgREST `pgrst.db_pre_request` hook to be the narrowest viable candidate, but the authorized disposable Postgres/PostgREST runtime is inaccessible. No migration, hosted write, Notes enablement, or disposable runtime validation has occurred.

[Routine Notes production deployment approval packet](routine-notes-production-deployment-approval.md) is ready for owner review only. Production deployment remains unauthorized pending CLI/credential approval, hosted scheduler authentication, backup/recovery readiness, deployment window and post-deploy monitoring ownership. No tracker status changes are authorized by the packet.
```
