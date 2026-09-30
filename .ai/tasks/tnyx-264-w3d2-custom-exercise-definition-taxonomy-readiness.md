# TNYX-264 W3D2 — Custom Exercise definition/taxonomy persistence readiness

**Status:** Needs decision
**Primary owner:** Workout Custom Exercises (`apps/features/workout` + `apps/shared` + `supabase`)
**Affected platforms:** Flutter phone domain/data foundation + Supabase schema; no visible UI in this slice

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice + Supabase table/column shape change
**Approval status:** `AWAITING OWNER APPROVAL` for the exact Supabase column shape below
**Approval evidence:** Owner said `Go next` / `Go` after the read-only audit selected W3D2 as the next bounded slice. That authorizes W3D2 planning/readiness. It does not implicitly approve a table/column shape that had not yet been stated.
**Approved planning boundary:** Define canonical Custom Exercise type/muscle/equipment tokens and the smallest backward-compatible user-owned Exercise definition persistence needed before visible editor work.
**Explicit non-changes:** No visible Custom Exercise UI, no Library UI, no media/Storage, no Body Part persistence, no Favorites/Folders, no SetPrescription/PerformedSet expansion, no Active Workout execution semantics, no new backend/service.

### Proposed exact additive Supabase shape — OWNER APPROVAL REQUIRED

Target table remains `public.user_workout_exercises`. Add exactly:

- `description text null` — optional user-entered description; null means absent.
- `exercise_type text null` — stable token for one of the 11 owner-approved editor types; nullable for backward compatibility with existing W1B1 rows/old clients.
- `primary_muscle text null` — one canonical anatomy token; nullable because taxonomy is optional at persistence level until the visible editor enforces its product rules.
- `secondary_muscles text[] not null default '{}'::text[]` — ordered canonical anatomy tokens; full 44-choice editor taxonomy; must not contain null and must not contain the selected primary token.
- `primary_equipment text null` — one canonical equipment token.

Do **not** add:

- `body_part` / `body_parts` — grouping is derived presentation taxonomy and must not become a second persisted truth;
- media/path/url columns — Storage/media is a separate later slice;
- distance/time/steps/+KG/-KG/x1/x2 execution fields — those belong to a later Workout measurement-profile domain slice;
- category/level duplication solely for Custom Exercises.

Backward compatibility:

- all new scalar fields are nullable;
- `secondary_muscles` defaults to empty;
- current W3D1 create calls that send only id/user/name/lineage continue to succeed;
- existing rows remain valid without inferred Exercise Type or anatomy.

Authenticated Data API privilege proposal:

- keep owner-scoped SELECT policy unchanged;
- keep owner-scoped INSERT/UPDATE RLS policies unchanged;
- extend authenticated INSERT column grant with the five new columns;
- extend authenticated UPDATE column grant with the five new columns;
- keep `id`, `user_id`, `based_on_catalog_exercise_id`, `created_at`, `updated_at` immutable to authenticated clients;
- keep authenticated DELETE unavailable; archive remains lifecycle authority;
- keep service_role full CRUD server-side only.

Database integrity proposal:

- `exercise_type` null or one of the exact 11 stable tokens;
- `description` null or nonblank after trim;
- `primary_muscle` / `primary_equipment` null or canonical snake_case token shape;
- `secondary_muscles` one-dimensional, null-free, and must not contain `primary_muscle`;
- duplicate secondary values remain rejected by the canonical Dart model/repository boundary unless a simple audited DB invariant can enforce uniqueness without adding unnecessary privileged helper surface.

## 1. Discovery

### User Outcome

Prepare durable Custom Exercise definition data so the later editor can save Exercise Type, description, one primary muscle, multiple secondary muscles and one equipment choice without losing data or inventing temporary local state.

### Success Criteria

- Canonical stable tokens exist for the 11 approved Exercise Types.
- Canonical string anatomy/equipment tokens replace legacy numeric IDs.
- Body Part grouping remains derived UI taxonomy, not persisted.
- User-owned Exercise repository can round-trip the richer definition through the existing canonical `Exercise` read model plus a typed Exercise Type contract.
- Existing W1B1 rows and clients remain compatible.
- RLS/owner isolation/lineage immutability/archive-only lifecycle remain unchanged.
- No media or workout-set measurement semantics are introduced.

## 2. Codebase Exploration

### Verified Evidence

- Fresh start point: `main@aac2f8d50ec650c4f729fce506328d50c04b822a`; no open PRs at W3D2 start.
- W3D1 is validated and archived; its repository/controller foundation is live.
- Live `tio-world` Supabase project is healthy and hosted `user_workout_exercises` matches the checked-in W1B1 shape.
- Hosted grants: authenticated has table SELECT plus column-level INSERT/UPDATE; no authenticated DELETE.
- Hosted RLS: owner SELECT/INSERT/UPDATE only; no DELETE policy.
- Current table has only id/user/display_name/status/catalog lineage/timestamps.
- Current canonical `Exercise` already carries muscleGroup, primaryMuscles, secondaryMuscles, primaryEquipment, category, levels and status, but no description or Exercise Type.
- Current bundled catalog has 101 Exercises, 10 broad muscle groups, 46 string muscle tokens and 11 equipment tokens.
- Owner reference anatomy map has 44 muscle choices and 18 explicitly supplied equipment choices; legacy numeric IDs are reference-only.
- Old TNYX Flutter reference confirms the intended selector/list direction but is not architecture/source-of-truth for tio-world.
- Supabase current guidance still treats grants and RLS as separate authorization layers; the existing table already follows explicit column grants.

### Exercise Type stable-token proposal

| UI title | Stable token |
|---|---|
| Weight & Reps | `weight_reps` |
| Distance & Duration | `distance_duration` |
| Duration | `duration` |
| Dumbbell x2 Simultaneous | `dumbbell_x2_simultaneous` |
| Dumbbell x1 Alt Sides | `dumbbell_x1_alternating_sides` |
| Dumbbell x1 Simultaneous | `dumbbell_x1_simultaneous` |
| Dumbbell x2 Alt Legs | `dumbbell_x2_alternating_legs` |
| Dumbbell x1 Alt Legs | `dumbbell_x1_alternating_legs` |
| Full Bodyweight | `full_bodyweight` |
| Assisted Bodyweight | `assisted_bodyweight` |
| Steps & Duration | `steps_duration` |

These tokens classify the Exercise definition only. They do not implement the corresponding set-entry measurements.

### Taxonomy reconciliation note

The owner-approved 44 anatomy labels do not map one-to-one to all 46 current catalog muscle tokens. W3D2 must therefore introduce one canonical Custom Exercise anatomy registry with stable string tokens and explicit labels; it must not collapse distinct owner choices (for example separate anatomical heads) into one broad catalog token merely to avoid adding canonical taxonomy values. Catalog-wide token migration is outside W3D2.

Equipment uses the owner-supplied choices only for this slice; five additional items visible in the historical TNYX selector are reference-only unless separately approved.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Persist Body Part | Rejected | It is derived grouping/navigation, not independent truth | Architecture + owner direction |
| Persist Exercise Type | Proposed | Required to preserve the explicit 11-type editor choice | Owner approval pending |
| Persist description | Proposed | Owner-approved optional field; no current durable owner | Owner approval pending |
| Persist primary muscle singularly | Proposed | UI is single-select; avoids list semantics for one value | Owner approval pending |
| Persist secondary muscles as text[] | Proposed | UI is multi-select and canonical Exercise already uses ordered list semantics | Owner approval pending |
| Persist primary equipment singularly | Proposed | UI is single-select | Owner approval pending |
| Media in W3D2 | Rejected/deferred | Requires separate Storage/privacy lifecycle | Existing plan |
| Measurement semantics in W3D2 | Rejected/deferred | Current SetPrescription remains reps/load/rest only | TNYX-76 |

## 4. Architecture Design

```text
future Custom Exercise editor
  -> CustomExercisesController
  -> UserExerciseRepository
  -> SupabaseUserExerciseRepository
  -> public.user_workout_exercises

shared taxonomy/type contracts
  -> stable string tokens + labels/grouping
  -> no legacy numeric IDs persisted
```

Body Part grouping is computed from the canonical anatomy registry and selected primary muscle. It is never stored in Postgres.

## 5. Implementation Plan

- [ ] Obtain owner approval for the exact five-column additive shape above.
- [ ] Reconcile active Linear W3D2 status/decision evidence.
- [ ] Create the migration using the repository-pinned Supabase CLI; never invent the timestamp.
- [ ] Add focused SQL matrix for columns, constraints, grants, owner isolation, immutable lineage/identity, archive-only lifecycle and cross-owner denial.
- [ ] Add stable Exercise Type/anatomy/equipment domain taxonomy contracts.
- [ ] Widen canonical Exercise/read mapping only as required by the approved definition contract.
- [ ] Widen UserExerciseRepository create/update/round-trip behavior while preserving W3D1 retry and affected-row guarantees.
- [ ] Update app/controller tests for richer definitions without visible UI.
- [ ] Run Flutter CI + Supabase database CI/security validation.
- [ ] Open PR and stop at review/merge gate.

## 6. Quality Review

### Validation Run

Planning/readiness only. No migration or production source change has been implemented yet.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W3D2-001 | Medium | Open | Exact five-column Supabase shape requires owner approval before implementation | `aac2f8d50...` | This brief |

## 7. Final Handoff

### Changed Files

Planning brief/index only until owner approval.

### Actual Behavior

No runtime or database behavior change.

### Known Limitations

Media, visible editor/list UI, Library integration, Favorites/Folders and Workout measurement-profile execution remain separate slices.

### Final Status

`BLOCKED` — exact Supabase table/column shape awaits owner approval.