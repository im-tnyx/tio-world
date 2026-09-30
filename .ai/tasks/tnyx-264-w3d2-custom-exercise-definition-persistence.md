# TNYX-264 W3D2 — Custom Exercise definition taxonomy & persistence

**Status:** Needs decision
**Primary owner:** Workout Custom Exercises (`apps/shared` canonical Exercise contract + `apps/features/workout` domain/data)
**Affected platforms:** Flutter phone foundation + Supabase Postgres/RLS; no visible UI in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + Supabase table/column shape change
**Approval status:** `AWAITING OWNER APPROVAL` for the exact additive Supabase column shape below; W3D2 planning itself was approved when the owner replied `Go next` on 2026-09-30.
**Approval evidence:** Owner-approved product direction already locks the 11 Exercise Types, single Primary muscle, full 44 Secondary-muscle list, single Equipment, optional Description, and separate later media slice. Exact physical Postgres columns were not previously presented.
**Approved product direction already in force:** one canonical user-owned Exercise identity; legacy numeric IDs are reference-only; Body Part is presentation grouping, not a second durable source of truth; media/Storage and Workout set measurement semantics are separate later slices.
**Explicit non-changes:** No Flutter visible UI/route change; no Library selector work; no media/Storage bucket/reference; no Favorites/Folders; no `SetPrescription`/`PerformedSet` expansion; no Routine/Program builder integration; no hard delete; no new table.

## Active Handoff

**Planning owner:** Current repository agent
**Implementation owner:** Not started
**Review owner:** Unassigned
**Implementation ownership state:** Blocked
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-30, remote `main@aac2f8d50ec650c4f729fce506328d50c04b822a`; no open PRs
**Branch:** `tnyx/tnyx-264-w3d2-custom-exercise-definition-persistence`
**HEAD SHA:** `aac2f8d50ec650c4f729fce506328d50c04b822a` at branch creation
**Observed working-tree state:** Connector-managed remote branch from clean/synced main; no local working-tree state is claimed.
**Observed uncommitted/dirty files:** Not applicable to connector-only repository edits.
**PR / tracker:** Linear TNYX-264 (parent TNYX-80)
**Current implementation state:** Planning only. W3D1 foundation is merged/archived; no W3D2 source or migration implementation yet.
**Relevant execution surface:** `apps/shared/lib/src/workout/exercise.dart`; Workout Exercise domain/data; `public.user_workout_exercises`; focused Dart/repository/SQL matrix; canonical Exercise/Supabase docs
**Validation completed at SHA:** Read-only audit on `main@aac2f8d50...`: current table has only id/user/name/status/lineage/timestamps; current repository reads id/display_name/status only; catalog uses string taxonomy; current SetPrescription remains reps/load/rest.
**Validation remaining:** Owner approval of exact additive column shape; then Supabase changelog/docs check, repository-pinned migration generation, implementation, SQL/RLS/grant matrix, Flutter/Dart tests, PR CI/review.
**Current blocker:** Exact Supabase table/column shape owner approval.
**Open review finding IDs:** None.
**Next exact action:** Obtain owner approval for the exact additive `user_workout_exercises` columns and immutability/grant boundary below. Do not generate or write a migration before that approval.

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

## 3. Clarification

### Proposed Exact Additive Supabase Shape — OWNER APPROVAL REQUIRED

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
| Existing `user_workout_exercises` table is widened; no second table | Proposed | Same user-owned Exercise identity/owner lifecycle | Architecture |
| Five additive columns exactly as listed above | **AWAITING OWNER APPROVAL** | Supabase table/column trigger | Owner |
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

- [ ] Owner approves the exact five-column shape and privilege boundary.
- [ ] Verify current Supabase changelog/docs relevant to additive Postgres/RLS/Data API changes.
- [ ] Generate migration filename with repository-pinned Supabase CLI; never invent timestamp.
- [ ] Add typed Exercise Type + Custom Exercise definition validation.
- [ ] Widen canonical Exercise read model only as approved.
- [ ] Add migration constraints/grants without changing RLS ownership or delete policy.
- [ ] Widen Supabase repository read/create/update-definition contract.
- [ ] Add focused domain/repository tests and SQL grant/RLS/integrity matrix.
- [ ] Update Supabase schema inventory + canonical Exercise screen status.
- [ ] Run exact-head Flutter/Dart + Supabase DB CI and review gates.

## 6. Quality Review

### Validation Run

Planning/read-only audit only. No W3D2 implementation validation has run.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Planning brief/index only until data-shape approval.

### Actual Behavior

No W3D2 runtime/database behavior change yet.

### Known Limitations

Body-part grouping map, media/Storage, visible editor/list, Favorites/Folders, and execution measurement semantics remain later scopes.

### Final Status

`BLOCKED` pending exact Supabase column-shape approval.
