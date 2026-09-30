# TNYX-264 W3D2 — Custom Exercise definition taxonomy & persistence

**Status:** Validated
**Completed:** 2026-10-01
**Primary owner:** Workout Custom Exercises (`apps/shared` canonical Exercise contract + `apps/features/workout` domain/data)
**Affected platforms:** Flutter phone foundation + Supabase Postgres/RLS; no visible UI in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + Supabase table/column shape change
**Approval status:** Approved. On 2026-09-30, after the exact five-column shape and least-privilege boundary were presented and the `equipment` vs `primary_equipment` naming mismatch was called out, the owner replied `Next go`. Canonical DB naming is `primary_equipment`, aligned with `Exercise.primaryEquipment` and the latest Linear proposal.
**Approval evidence:** Owner-approved product direction already locks the 11 Exercise Types, single Primary muscle, full 44 Secondary-muscle list, single Equipment, optional Description, and separate later media slice. Exact physical Postgres columns were not previously presented.
**Approved product direction already in force:** one canonical user-owned Exercise identity; legacy numeric IDs are reference-only; Body Part is presentation grouping, not a second durable source of truth; media/Storage and Workout set measurement semantics are separate later slices.
**Explicit non-changes:** No Flutter visible UI/route change; no Library selector work; no media/Storage bucket/reference; no Favorites/Folders; no `SetPrescription`/`PerformedSet` expansion; no Routine/Program builder integration; no hard delete; no new table.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Complete
**Review owner:** Codex GitHub review + repository/hosted verification
**Implementation ownership state:** Complete
**Repository state last verified:** 2026-10-01, PR #495 squash-merged to `main` as `d09e4b3571a13a8fb3b02751dd430d59ec0eac1d`.
**PR / tracker:** GitHub PR #495 merged; Linear TNYX-264 remains In Progress because W3D is broader than this persistence slice.
**Current implementation state:** Validated and live. The five approved structured-definition columns are deployed on `public.user_workout_exercises`; hosted schema has 12 columns. Owner-scoped RLS remains enabled, authenticated DELETE remains denied, authenticated immutable columns remain non-updatable, and `service_role` retains full CRUD.
**Validation completed:** Final PR head `f18c182eef9009837829946a9edd88f0e95e2f0d` passed Flutter CI `36767197919`, Supabase DB CI `36767197865`, required attribution guard, and Codex review with zero unresolved threads. Hosted deployment verified the 12-column schema, approved constraints/grants/RLS and SECURITY INVOKER muscle validator. Security Advisor remained at the six pre-existing warnings (five authenticated SECURITY DEFINER RPC warnings plus leaked-password protection disabled), with no new W3D2-specific finding.
**Migration history:** Canonical repository migration `20260930180700_add_custom_exercise_definition_fields.sql` is applied. The connector initially recorded the same SQL under generated version `20260930202102`; after exact SQL equivalence was verified, the hosted ledger version key was reconciled transactionally to canonical `20260930180700` without rerunning DDL. Remote migration history now matches the repository version.
**Validation remaining:** A local linked-checkout `supabase db push --dry-run` is optional confirmation and was not run from the connector-only closure session. It is not a blocker because hosted ledger identity, live schema and security boundary were directly verified.
**Current blocker:** None for W3D2.
**Open review finding IDs:** None.
**Next exact action:** Start a new bounded TNYX-264 slice only after fresh source/tracker audit and the applicable Owner Approval. Visible Custom Exercise editor/list UX, media/Storage and execution-measurement semantics remain outside W3D2.

## Global UI / Design-System Guardrail

This slice intentionally makes no production UI change. The later visible editor remains separately governed by `apps/core` reusable UI rules and the owner-approved screen interaction.

## 1. Discovery

### User Outcome

Make Custom Exercise definition data durable before the visible editor ships, so the editor does not collect Exercise Type/muscle/equipment/description values that are silently lost after save.

### Success Criteria

- Existing W1B1 user Exercise rows remain valid without fake backfilled definition values.
- Owner-approved 11 Exercise Types have stable storage tokens separate from display labels/tags.
- Owner-approved 44-muscle selection has stable canonical tokens; legacy numeric IDs are never persisted.
- Equipment selection has stable canonical tokens; legacy numeric IDs are never persisted.
- Body Part is not persisted; later UI derives grouping from taxonomy mapping.
- User Exercise read model can round-trip optional description/type/primary/secondary/equipment definition data.
- Authenticated owner can insert/update only approved mutable definition columns and status/name; lineage/identity/owner/timestamps remain immutable.
- RLS remains owner-scoped SELECT/INSERT/UPDATE with no authenticated DELETE.
- No media or Workout set measurement semantics are introduced.

### Scope

- Additive columns on existing `public.user_workout_exercises` only.
- Domain storage-token/value validation for Custom Exercise definition.
- Canonical `Exercise` read-model widening only where needed to return persisted description/type while reusing existing muscle/equipment fields.
- Repository create/read/update-definition support.
- Focused SQL/grant/RLS/repository/domain tests.
- Canonical docs/schema inventory update after implementation is validated.

### Non-Goals

Visible editor/list UI; body-map assets; Body Part persistence; media/Storage; Favorites/Folders; catalog taxonomy rewrite; SetPrescription/PerformedSet changes; Routine/Program/Active Workout execution.

## 2. Codebase Exploration

### Verified Evidence

- W3D1 merged via PR #493 and is archived; production composition + CustomExercisesController + durable list/create/rename/archive exist.
- `public.user_workout_exercises` currently has exactly 7 columns: `id`, `user_id`, `display_name`, `status`, `based_on_catalog_exercise_id`, `created_at`, `updated_at`.
- Authenticated currently has SELECT, INSERT(id/user_id/display_name/lineage), UPDATE(display_name/status), no DELETE; owner RLS applies.
- `SupabaseUserExerciseRepository.list()` currently selects only `id, display_name, status`, so richer editor state would be lost today.
- Canonical `Exercise` already carries `primaryMuscles`, `secondaryMuscles`, `primaryEquipment`; it does not currently carry Description or Exercise Type.
- Bundled catalog currently uses stable string taxonomy, not legacy numeric IDs.
- Reference `tnyx-hub` confirms the supplied legacy muscle/equipment/body-part names and prior editor concept, but is reference-only; current tio-world architecture remains authoritative.
- Current `SetPrescription` is still reps + optional loadKg + optional restSeconds.
- Current repo has no approved Workout Storage bucket for Custom Exercise media.
- Live Supabase project `tio-world` confirms W1B1 schema/RLS/grants match repository migrations; no drift was found in the user Exercise owner boundary.
- Current Supabase guidance distinguishes RLS from Data API grants; the 2026 breaking change moves public-schema exposure toward explicit grants, so W3D2 must explicitly grant the new authenticated INSERT/UPDATE columns rather than assume defaults.
- Supabase column-level privilege guidance confirms that revoking table-wide UPDATE and granting selected update columns is the supported Postgres pattern; W3D2 preserves the existing least-privilege model.

## 3. Clarification

### Approved Exact Additive Supabase Shape

Add these **five** columns to existing `public.user_workout_exercises`:

```text
description         text      NULL
exercise_type       text      NULL
primary_muscle      text      NULL
secondary_muscles   text[]    NOT NULL DEFAULT '{}'
primary_equipment   text      NULL
```

Why nullable/default-compatible:

- existing W1B1 rows have no trustworthy richer definition and must not be backfilled with guessed values;
- later UI may default a new draft to Weight & Reps, but the database must not claim old rows are Weight & Reps;
- name remains the only already-required persisted definition field from W1B1.

Do **not** add:

```text
body_part / muscle_group     // derived presentation grouping, not durable second truth
media/media_url/storage key  // W3D3 later
distance/duration/steps      // Workout measurement-profile slice later
dumbbell multiplier/side     // encoded only by exercise_type identity for now; execution semantics later
category/levels              // not part of approved Custom Exercise editor
```

### Proposed Authenticated Column Privileges

Keep existing owner RLS policies unchanged. Widen column privileges only:

```text
INSERT:
  id
  user_id
  display_name
  based_on_catalog_exercise_id
  description
  exercise_type
  primary_muscle
  secondary_muscles
  primary_equipment

UPDATE:
  display_name
  status
  description
  exercise_type
  primary_muscle
  secondary_muscles
  primary_equipment
```

Remain immutable to authenticated clients:

```text
id
user_id
based_on_catalog_exercise_id
created_at
updated_at
```

Authenticated DELETE remains unavailable; archive remains the lifecycle action. `service_role` retains full CRUD.

### Proposed Stable Exercise Type Tokens (11)

```text
weight_reps
distance_duration
duration
dumbbell_x2_simultaneous
dumbbell_x1_alternating_sides
dumbbell_x1_simultaneous
dumbbell_x2_alternating_legs
dumbbell_x1_alternating_legs
full_bodyweight
assisted_bodyweight
steps_duration
```

These are definition/type identities only. They do not yet expand prescribed/performed set measurements.

### Proposed Stable Muscle Tokens (44)

```text
sternocleidomastoid
pectoralis_major_sternal_head
pectoralis_major_clavicular_head
deltoid_anterior
deltoid_lateral
brachioradialis
rectus_abdominis
sartorius
serratus_anterior
pectineus
transverse_abdominis
tensor_fasciae_latae
iliopsoas
wrist_extensors
wrist_flexors
deltoid_posterior
trapezius_lower_fibers
trapezius_upper_fibers
trapezius_middle_fibers
infraspinatus
teres_major
teres_minor
latissimus_dorsi
erector_spinae
adductor_longus
adductor_magnus
gluteus_maximus
gluteus_medius
hamstrings
gracilis
levator_scapulae
popliteus
splenius
triceps_brachii
biceps_brachii
brachialis
obliques
quadriceps
gastrocnemius
tibialis_anterior
soleus
gluteus_minimus
deep_hip_external_rotators
serratus_anterior_alternate
```

`primary_muscle` is single-select. `secondary_muscles` is multi-select from the same set; primary must not also appear in secondary. Body-part grouping will be a later derived UI taxonomy map, not a persisted field.

### Proposed Stable Equipment Tokens (18)

```text
barbell
bodyweight
cable
dumbbell
ez_bar
lever_machine
sled_machine
smith_machine
weighted
band
kettlebell
medicine_ball
power_sled
resistance_band
stability_ball
suspension
trap_bar
wheel_roller
```

Visible labels remain the owner-approved names (`Body weight`, `EZ Barbell`, `Medicine Ball`, etc.). Existing tio-world-compatible tokens are reused where they already match.

### Proposed Integrity Rules

- `description`: null or nonblank after trim; empty editor text normalizes to null.
- `exercise_type`: null or one of the 11 tokens.
- `primary_muscle`: null or one of the 44 tokens.
- `secondary_muscles`: one-dimensional, contains no nulls, contains only the 44 tokens, contains no duplicate token, and never contains `primary_muscle`.
- `primary_equipment`: null or one of the 18 tokens.
- no constraint requires the optional definition fields for legacy rows.
- Body Part is not stored and therefore cannot drift out of sync with Primary muscle.

### Domain/Repository Direction

- Add a typed Custom Exercise definition/write value in Workout domain; it is a command/value object, **not** a competing `CustomExercise` entity.
- Add a stable typed Exercise Type contract with the 11 storage values.
- Widen canonical `Exercise` only with optional `description` and optional Exercise Type; reuse its existing primary/secondary/equipment fields.
- Map DB scalar `primary_muscle` to canonical `Exercise.primaryMuscles` as zero-or-one element.
- Repository gains create/update-definition round-trip support while preserving rename/archive and immutable source lineage.
- Current W3D1 name-only create remains representable as all optional definition fields null/empty.

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| W3D2 is non-UI structured-definition persistence | Planning approved | Prevent visible editor data loss | Owner |
| Existing `user_workout_exercises` table is widened; no second table | Approved | Same user-owned Exercise identity/owner lifecycle | Architecture |
| Five additive columns exactly as listed above | **Approved 2026-09-30** | Supabase table/column trigger; owner replied `Next go` after exact-shape/naming reconciliation | Owner |
| Live Supabase verification | Complete | Production schema/RLS/grants match W1B1 and require explicit new-column grants | Supabase audit |
| Body Part is not persisted | Locked by existing owner direction | It is grouping/navigation, not second truth | Owner |
| Legacy numeric IDs are not persisted | Locked | Current canonical architecture uses stable string tokens | Owner |
| Media/Storage stays out | Locked | Separate security/storage lifecycle required | Owner |
| Set measurement semantics stay out | Locked | TNYX-76 explicitly defers them | Owner |

## 4. Architecture Design

### Chosen Approach

```text
future editor
  -> Custom Exercise definition value
  -> CustomExercisesController
  -> UserExerciseRepository
  -> SupabaseUserExerciseRepository
  -> public.user_workout_exercises (same owner row)
```

Body Part grouping is derived later:

```text
selected Primary muscle token
  -> presentation taxonomy grouping map
  -> Chest / Back / Shoulders / ... UI
```

### Alternative Rejected

- Persist legacy numeric IDs: creates a second obsolete taxonomy and couples Tio-world to source IDs.
- Persist Body Part plus Primary muscle: duplicates derivable truth and permits drift.
- JSONB definition blob: makes the exact filterable/type/muscle/equipment contract less enforceable and less queryable than five stable columns.
- New child definition table: unnecessary extra identity/lifecycle for a one-to-one owner row.
- Backfill old rows as Weight & Reps: fabricates definition truth.
- Add media now: requires separate private Workout Storage design.
- Expand SetPrescription now: mixes Exercise definition with execution measurement semantics.

### Failure/Security States

- signed-out writes remain fail-closed through existing repository boundary;
- owner RLS continues preventing cross-user reads/writes;
- column grants prevent authenticated mutation of identity/owner/lineage/timestamps;
- malformed taxonomy values fail at domain/repository boundary and DB constraints;
- zero-row updates remain detected by the W3D1 affected-row gateway contract;
- no authenticated hard delete.

## 5. Implementation Plan

- [x] Owner approves the exact five-column shape and privilege boundary.
- [x] Verify current Supabase changelog/docs relevant to additive Postgres/RLS/Data API changes.
- [x] Generate migration filename with repository-pinned Supabase CLI; never invent timestamp.
- [x] Add typed Exercise Type + Custom Exercise definition validation.
- [x] Widen canonical Exercise read model only as approved.
- [x] Add migration constraints/grants without changing RLS ownership or delete policy.
- [x] Widen Supabase repository read/create/update-definition contract.
- [x] Add focused domain/repository tests and SQL grant/RLS/integrity matrix.
- [x] Update Supabase schema inventory + canonical Exercise screen status.
- [ ] Run exact-head Flutter/Dart + Supabase DB CI and review gates.

## 6. Quality Review

### Validation Run

Local implementation validation completed before PR creation:

- `git diff --check`: PASS.
- Supabase CLI `2.116.0` (same version as DB CI) generated `20260930180700_add_custom_exercise_definition_fields.sql`.
- `flutter pub get` in Workout: PASS.
- `flutter analyze --no-pub` in Workout and app: PASS; `dart analyze .` in shared: PASS.
- Workout full `flutter test --no-pub`: 221 PASS; shared full `dart test`: 199 PASS; app `test/app/network_providers_test.dart`: 10 PASS.
- `melos bootstrap` via installed 8.6.0: unavailable for this workspace (`Your current directory does not appear to be within a Melos workspace`). No claim that `melos analyze`/`melos test` ran; direct affected-package commands used. CI retains pinned Melos 2.9.0.
- Local Postgres container had an older `20260909131518` baseline. Pending repository migrations through W1B1 and W3D2 were replayed inside one transaction, followed by the existing W1B1 and new W3D2 SQL matrices. PASS for exact types/defaults/nullability, CHECK rules, pre-migration legacy row preservation, owner SELECT/INSERT/UPDATE, cross-owner denial, exact column privileges, immutable-column/DELETE denial, service-role CRUD and anonymous denial. Entire transaction rolled back; baseline ledger and absence of the Workout table were verified afterward. This is local rollback-based validation, not hosted deployment or a from-zero replay; full replay is delegated to DB CI.
- Current Supabase changelog and column-privilege docs verified. Relevant Data API exposure change requires explicit grants. The Postgres 15.19/17.11 breaking changes concern ltree/crypto/GiST/custom operators that W3D2 does not introduce.
- Live Security Advisor completed after local DB validation: six pre-existing WARN findings (five existing public authenticated SECURITY DEFINER RPCs and disabled leaked-password protection). No unrelated fix. Advisor observes the undeployed baseline and cannot certify W3D2 post-deployment state.
- Live branch protection + branch rules inspected: only `Commit attribution guard` is required; branch rules API returns no extra rules. Flutter, DB and scanner outcomes must still be recorded independently; supplemental concrete findings remain real findings.
- Non-failing existing Workout test warning: core `uses-material-design: true` versus package primary setting. No unrelated pubspec edit.
- Implementation-anchor exact-head CI: [Flutter 36759161040](https://github.com/im-tnyx/tio-world/actions/runs/36759161040) PASS; [Supabase DB 36759160893](https://github.com/im-tnyx/tio-world/actions/runs/36759160893) PASS, including full migration replay, the W3D2 SQL matrix, existing matrices/concurrency and no newly introduced lint errors. Required attribution guard PASS.
- [Codex review](https://github.com/im-tnyx/tio-world/pull/495#issuecomment-5917353173) explicitly reviewed `065d789a9b` and found no major issues. Review-thread query returned zero threads.
- [GitHub Advanced Security 36758982112](https://github.com/im-tnyx/tio-world/actions/runs/36758982112): supplemental + infrastructure failure before meaningful analysis, `CAPIError: 400 The requested model is not supported`. Not a security pass; no product vulnerability is inferred. No rules/check suppression or scanner configuration change.

Pre-deployment baseline verification against Supabase project `tio-world` confirmed the W1B1 seven-column table, owner SELECT/INSERT/UPDATE RLS, least-privilege authenticated grants, no authenticated DELETE and full service-role CRUD. Post-deployment verification on 2026-10-01 confirmed migration `20260930180700_add_custom_exercise_definition_fields`, the 12-column table, the widened approved definition-column grants, unchanged owner RLS/no-DELETE boundary and full service-role CRUD.

Current Supabase docs/changelog were checked. The 2026 Data API exposure change reinforces explicit grants, and column-level privilege guidance supports keeping authenticated UPDATE restricted to approved mutable columns.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W3D2-01 | P1 | Resolved locally | Missing definition imports and incomplete controller fake interface | `c5df1fb7` | Focused analyze and complete Workout tests pass |
| W3D2-02 | P1 | Resolved locally | Controller rename discarded description/type metadata | `c5df1fb7` | Preservation regression and Workout suite pass |
| W3D2-03 | P2 | Resolved locally | Record comparison did not deeply compare the nested definition map | `c5df1fb7` | Compare call identity and map separately; repository tests pass |

## 7. Final Handoff

### Changed Files

Complete parent-to-head scope: 21 W3D2-owned files, including the existing connector-created source and local corrections:

- `.ai/IMPLEMENTATION_STATUS.md`
- `.ai/tasks/README.md`
- `.ai/archive/2026-10-tnyx-264-w3d2-custom-exercise-definition-persistence.md`
- `.github/workflows/supabase-db-ci.yml`
- `apps/features/workout/lib/src/data/exercises/supabase_user_exercise_repository.dart`
- `apps/features/workout/lib/src/domain/exercises/exercises.dart`
- `apps/features/workout/lib/src/domain/exercises/user_exercise_definition.dart`
- `apps/features/workout/lib/src/domain/exercises/user_exercise_repository.dart`
- `apps/features/workout/lib/src/presentation/library/exercises/custom_exercises_controller.dart`
- `apps/features/workout/test/data/supabase_user_exercise_repository_test.dart`
- `apps/features/workout/test/domain/user_exercise_definition_test.dart`
- `apps/features/workout/test/presentation/custom_exercises_controller_test.dart`
- `apps/shared/lib/src/workout/exercise.dart`
- `apps/shared/lib/src/workout/exercise_type.dart`
- `apps/shared/lib/src/workout/workout.dart`
- `apps/shared/test/workout/exercise_test.dart`
- `docs/data/SUPABASE_SCHEMA.md`
- `docs/data/SUPABASE_STRATEGY.md`
- `docs/screens/exercise-search.md`
- `supabase/migrations/20260930180700_add_custom_exercise_definition_fields.sql`
- `supabase/tests/database/tnyx_264_user_exercise_definition.test.sql`

### Actual Behavior

User-owned definitions round-trip description/type/muscle/equipment; malformed rows fail closed; rename preserves canonical definition data. Existing name-only creation is compatible. Migration adds only the approved five fields and integrity/grant enforcement without changing owner RLS or lifecycle. The migration is deployed and hosted-verified; repository/live migration identity is reconciled.

### Known Limitations

Body-part grouping map, media/Storage, visible editor/list, Favorites/Folders, and execution measurement semantics remain later scopes.

### Final Status

VALIDATED — merged, deployed, hosted-verified, and migration-history parity reconciled. Broader TNYX-264 remains In Progress.
