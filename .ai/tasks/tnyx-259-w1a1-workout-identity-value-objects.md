# TNYX-259 W1A1 — Canonical Workout identity value objects

**Status:** In progress — owner-authorized implementation
**Primary owner:** `apps/shared`
**Affected platforms:** Shared pure-Dart package (phone, Wear and later approved consumers); no runtime/UI change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (bounded W1 sub-slice under TNYX-78)
**Approval status:** Approved
**Approval evidence:** Owner approved D1 (root ID set) and D2 (ExerciseRef identity variants) on 2026-09-24 after the read-only W1A1 audit, and authorized tracker/task setup; owner authorized W1A1 implementation (through Draft PR and review-readiness audit) on 2026-09-24. Ready for Review, merge and later slices remain separately gated.
**Approved product/UI/data-shape boundaries:** D1 and D2 below, domain identity value objects only.
**Explicit non-changes:** no `RoutineId`/`ProgramId`; no Exercise/Routine/Program/TrainingPlan/PlannedWorkout/WorkoutSession entities; no `SetPrescription`/`PerformedSet` fields; no repository interfaces, data sources or controllers; no Supabase, schema, migration, RLS or sync; no catalog loader/parser, asset/schema validation or standards logic; no Quick Start, PlannedWorkout→WorkoutSession cardinality or session timezone/local-date rules; no unknown-ID display/fallback; no UI; no ID generation; owner assets `apps/core/assets/exercises/` read-only (never edited, staged, moved, stashed, reset or deleted).

### Approved decisions

- **D1 — root ID set:** W1A1 owns exactly `ExerciseRef`, `TrainingPlanId`, `PlannedWorkoutId`, `WorkoutSessionId`. `RoutineId` → W1A3 and `ProgramId` → W1A4 stay deferred. D1 decides no Routine/Program revision, provenance, persistence, composition or UI.
- **D2 — ExerciseRef variants:** catalog Exercise → stable `ex_*` identity; user-created Exercise → canonical UUID identity; the two are distinct domain variants. No `userId`/`ownerId`/`createdBy`, Custom Exercise entity, persistence, repository, sync or catalog loader.

## Active Handoff

**Planning owner:** current planning agent
**Implementation owner:** current implementation agent
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune`
**Branch:** `tnyx/tnyx-259-w1a1-workout-identity-value-objects` from fresh `origin/main`
**HEAD SHA:** base `origin/main` = `789b0d2f5d6c4f806d3ecc1bb3498a3b52b29155`; live branch tip is authoritative
**Observed working-tree state:** clean except untracked owner assets `apps/core/assets/exercises/`
**Observed uncommitted/dirty files:** none besides the owner assets
**PR / tracker:** Linear TNYX-259 (child of TNYX-78, which stays `In Progress`; blocked-by TNYX-258 `Done`); PR not yet opened
**Current implementation state:** Governance commit first; implementation follows
**Relevant execution surface:** `apps/shared/lib/src/workout/**`, `apps/shared/lib/shared.dart`, `apps/shared/test/workout/**`, D-019 wording (see Decisions)
**Validation completed at SHA:** setup audit only at `789b0d2f`
**Validation remaining:** all implementation validation (section 6)
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Section 5 step 2.

## Global UI / Design-System Guardrail

No Flutter UI work is in scope. Rendered UI must remain unchanged.

## 1. Discovery

### User Outcome

Stable, type-safe Workout identities exist before any canonical Workout entity, so later slices reference Exercises and user-owned Workout records without competing string conventions.

### Success Criteria

- The four approved types exist in `apps/shared` as pure Dart and are exported through `shared.dart`.
- Catalog `ex_*` and user-created UUID `ExerciseRef` variants are distinct and validated.
- Root IDs are distinct UUID-backed types that cannot be substituted for one another.
- Equality, hash and `value` round-trip are tested; invalid input is rejected.
- No new dependency; no persistence/UI/Supabase/asset change; workspace analyze/tests green.

### Scope

The value objects, their tests, one `shared.dart` export line, minimal canonical-doc alignment for D1/D2, and this brief/index.

### Non-Goals

See *Explicit non-changes*.

## 2. Codebase Exploration

### Verified Evidence (at `789b0d2f`)

- W1A0 and W1A7 are archived; TNYX-258 `Done`; TNYX-78 `In Progress`. `apps/shared/lib/workout.dart` and `src/workout/**` are absent; no `TrainingSession`/`WorkoutSet`/`SetType`/`WorkoutRepository` and no existing `ExerciseRef`/root-ID types.
- [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md) §1–5 and D-019 in [DECISIONS.md](../DECISIONS.md): durable Workout IDs/value objects → `apps/shared`; `ex_*` is built-in identity; legacy/slug/title are metadata; built-in rows not mirrored into Supabase; W1A1 "can define `ExerciseRef` and approved root IDs". The approved root-ID list existed nowhere canonically before D1.
- Catalog evidence (read-only): `exercises_data.json` has 101 IDs, all unique and matching `^ex_[a-z0-9]+(?:_[a-z0-9]+)*$` (some with digit segments, e.g. `_v2`); legacy numeric IDs live in `source.legacyExerciseIds`; `exercise_standards.json` is keyed by numeric legacy IDs.
- Shared package convention: `shared.dart` exports one barrel per domain (`src/<domain>/<domain>.dart`); `nutrition/` is flat (no `domain/` subfolder). No `lib/<domain>.dart` public entries.
- Value-object precedent: `MealLogLocalDate` — `final class`, validating public factory throwing `ArgumentError`, private `const` constructor, parse factory throwing `FormatException`, manual `==`/`hashCode`, canonical `toString`. No typed-ID wrapper exists yet (`MealLogEntry` uses raw `String id`); ADR-0011 justifies introducing them for Workout.
- UUID precedent: MealLog `clientMutationId` canonical regex `8-4-4-4-12` hex, version-agnostic, rejects surrounding whitespace, accepts either case and normalizes to lowercase. Supabase user-owned rows use `uuid primary key default gen_random_uuid()`.
- `apps/shared/pubspec.yaml` already depends on `uuid` (unused in `lib/`); `freezed` unused in `lib/`. Tests use `package:test` with `throwsArgumentError`/`throwsFormatException`, one test file per source file.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| D1 root ID set | Approved | See *Approved decisions* | Owner |
| D2 ExerciseRef catalog/user-created variants | Approved | See *Approved decisions* | Owner |
| Catalog regex `^ex_[a-z0-9]+(?:_[a-z0-9]+)*$` | Locked (engineering) | Matches 101/101 IDs; rejects `ex_`, `ex__a`, `ex_a_`, uppercase, hyphen | Planning |
| Namespace safety via distinct Dart types, no prefixes | Locked (engineering) | No canonical/repo support for `tp_`/`pw_`/`ws_`; Supabase uses plain UUID PKs | Planning |
| UUID: version-agnostic, normalize to lowercase, reject whitespace | Locked (engineering) | MealLog canonical precedent; do not require v4 | Planning |
| `final class` wrappers, not `extension type`/`freezed` | Locked (engineering) | Extension types erase at runtime, so cross-type equality leaks; `freezed` unused in shared lib | Planning |
| No new dependency; validate only, never generate | Locked (engineering) | Regex precedent suffices; generation belongs to later owning slices | Planning |
| Public API via `shared.dart`; do not restore `lib/workout.dart` | Locked (engineering) | Current per-domain barrel convention; W1A7-deleted entry must not return mechanically | Planning |
| Record D1/D2 in D-019 during implementation | Planned | D-019/ADR-0011 say only "approved root IDs"; once types land, canonical docs must name them (avoids the W1A7-C1 class of finding). Minimal D-019 wording in the implementation PR; ADR-0011 unchanged | Planning |
| Branch/PR use TNYX-259, never TNYX-78 | Locked | Integration auto-completes the keyed issue on merge | Planning |

## 4. Architecture Design

### Planned Shape (not yet implemented)

```text
apps/shared/lib/src/workout/
  workout.dart                 # barrel: exercise_ref, training_plan_id, planned_workout_id, workout_session_id
  exercise_ref.dart            # sealed ExerciseRef; final CatalogExerciseRef, UserCreatedExerciseRef
  training_plan_id.dart        # final class TrainingPlanId
  planned_workout_id.dart      # final class PlannedWorkoutId
  workout_session_id.dart      # final class WorkoutSessionId
  workout_id_validation.dart   # internal UUID/ex_* checks; not exported by the barrel
apps/shared/lib/shared.dart    # + export 'src/workout/workout.dart';
```

### Behavior Contract

- **Catalog `ExerciseRef`:** accept `ex_barbell_bench_press`, unknown `ex_future_movement`, digit segments; reject empty, whitespace, `1643`, `bench-press`, `Bench Press`, `ex_`, `ex__a`, `ex_a_`, `EX_A`, `ex-a`. No catalog lookup and no lowercase normalization (identity is already canonical lowercase).
- **User-created `ExerciseRef` and root IDs:** canonical UUID syntax, any version; uppercase accepted and normalized to lowercase; surrounding whitespace or malformed UUID rejected.
- **`ExerciseRef.parse(String)`** dispatches by format (a UUID can never begin with `ex_`), alongside explicit catalog/user-created factories. `String get value` is the domain round-trip representation only; it decides no persistence encoding (W1B0).
- **Equality:** same concrete type + same canonical value → equal; different value → unequal; `hashCode` consistent. Different root-ID types are never equal and not substitutable at compile time; catalog and user-created refs are never equal.
- **Errors/constructors:** the implementation owner re-verifies the live `MealLogLocalDate` precedent (validating factory + `ArgumentError`, private `const` ctor, `FormatException` for a parse entry point where appropriate, manual `==`/`hashCode`, canonical `toString`) and follows it rather than this sketch where they differ.

### Alternative Rejected

- Prefixed IDs (`tp_…`): unsupported by canonical docs or repo patterns.
- `extension type` IDs: runtime erasure lets different ID types compare equal.
- Raw `String` IDs (MealLog style): no type safety, contrary to ADR-0011 value-object ownership.
- Single untyped `ExerciseRef` string without variants: loses the approved catalog/user-created distinction.

### Failure and Accessibility States

Not applicable; no UI or runtime flow.

## 5. Implementation Plan

- [ ] 1. Fresh reconstruction (`git fetch origin --prune`, `git status --short --branch`, `origin/main` SHA); preserve owner assets; create `tnyx/tnyx-259-w1a1-workout-identity-value-objects` from fresh `origin/main`; commit this brief + index row first; move TNYX-259 to `In Progress`.
- [ ] 2. Re-verify prerequisites, absence of competing types, and the live value-object/UUID precedents.
- [ ] 3. Implement the planned files and one `shared.dart` export; no other `apps/**` change.
- [ ] 4. Add the four test files (section 6 matrix).
- [ ] 5. Minimal D-019 wording naming the D1 types and D2 variants; ADR-0011 unchanged.
- [ ] 6. Validate (section 6) and review the diff for scope, purity and dependency drift.
- [ ] 7. Push, open Draft PR per `docs/PUSH_TEMPLATE.md` / `.github/PULL_REQUEST_TEMPLATE.md`, run the exact-head review gate; merge needs separate owner authorization.

## 6. Quality Review

### Test Matrix (planned)

- `apps/shared/test/workout/exercise_ref_test.dart`: valid catalog, unknown future `ex_*`, digit segments, lowercase and uppercase-normalized UUID; each invalid value listed above plus malformed UUID and surrounding whitespace; `parse` returns the right variant; equality/hash; catalog ≠ user-created; `value` round-trip.
- `training_plan_id_test.dart`, `planned_workout_id_test.dart`, `workout_session_id_test.dart`: valid UUID (not only v4); blank/whitespace/malformed rejected; lowercase normalization; same value equal, different value unequal, hash consistent; different ID types with identical UUID text are not equal. Compile-time non-substitutability needs no runtime test.

### Validation Plan

`shared.dart` exports change, so every dependent package must be checked. Use the current `.github/workflows/flutter-ci.yml` as authority at implementation time:

```text
git diff --check origin/main...HEAD
bash scripts/check_commit_attribution.sh origin/main HEAD
apps/shared: pub get --enforce-lockfile, dart analyze ., dart test
each dependent Flutter package: pub get --enforce-lockfile, flutter analyze --no-pub, flutter test --no-pub where test/ exists
```

Record exact results with the validated SHA; if a command cannot run, record why.

### Validation Run

```text
Setup audit only at 789b0d2f. Implementation validation not run.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | None | — | — |

## 7. Final Handoff

### Changed Files

Setup: this brief and `.ai/tasks/README.md` only.

### Actual Behavior

No change.

### Known Limitations

- `ex_*` absent from an older client's bundled catalog stays constructible; display/compatibility handling is W1B0/W3.
- Deferred: RoutineId/SetPrescription (W1A3), ProgramId/Saved/Following (W1A4), TrainingPlan provenance/planless scheduling (W1A5), Quick Start/cardinality/session date (W1A6a), persistence (W1B0), catalog loader/standards/licensing (W3).

### Final Status

`REVIEW` — setup complete; awaiting W1A1 implementation authorization.
