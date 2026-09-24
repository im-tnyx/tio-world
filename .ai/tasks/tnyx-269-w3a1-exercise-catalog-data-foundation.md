# TNYX-269 W3A1 — Exercise catalog data foundation

**Status:** In progress
**Primary owner:** `apps/features/workout` (domain/data only)
**Affected platforms:** Workout feature package; no runtime UI, routing or rendered change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-24 the owner approved the W3A split (after the W3A readiness audit returned `READY_FOR_OWNER_APPROVAL`) and authorized W3A1 only, through Draft PR and exact-head review. W3A2 is not authorized.
**Approved product/UI/data-shape boundaries:** Workout-owned catalog row DTO/validation, mapping to canonical `Exercise`, `ExerciseCatalog`, repository contract, pure search/filter query and tests with synthetic fixtures.
**Explicit non-changes:** no real asset loading/`AssetBundle` source, asset move/registration or pubspec asset change; no catalog version/envelope; no UI, presentation controller, router/route contract, Library or Workout Home entry; no media, standards, Supabase/persistence, Favorites/Custom/Folders or Exercise Detail; no `apps/core`, `apps/app` or `apps/shared` change.

### Protected owner work (read-only, never staged)

`apps/core/assets/exercises/`, `apps/core/assets/ic_body_part/`, `apps/core/assets/ic_equipment/`, `apps/core/assets/musclemap/` (untracked owner work). Tests use invented synthetic fixtures only; no owner rows, titles, instructions, media URLs or legacy IDs. Licensing was audited as `LICENSING_EVIDENCE_MISSING`; W3A1 ships no catalog content.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune` and `git pull --ff-only origin main`
**Branch:** `tnyx/tnyx-269-w3a1-exercise-catalog-data-foundation`
**HEAD SHA:** base `origin/main` = `74032ddb7a8ffceec367c79ec9e9e4464be4ba97`; live branch tip is authoritative
**Observed working-tree state:** clean except the protected untracked owner assets above
**Observed uncommitted/dirty files:** protected owner assets only
**PR / tracker:** Linear TNYX-269 (W3A1, `In Progress`) under parent TNYX-261 (`In Progress`); W3A2 = TNYX-270 (`Backlog`, blocked by TNYX-269)
**Current implementation state:** Not started
**Relevant execution surface:** `apps/features/workout/lib/src/{domain,data}/exercises/**`, `apps/features/workout/test/{domain,data}/exercises/**`, barrels, this brief/index
**Validation completed at SHA:** None yet
**Validation remaining:** All (section 6)
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Implement the domain/data foundation and tests.

## Global UI / Design-System Guardrail

No Flutter UI work is in scope.

## 1. Discovery

### User Outcome

W3A2 and later consumers (Exercises screen, builder picker, Exercise Detail) get one validated, reusable path from decoded catalog rows to canonical `Exercise` values, without a competing Exercise model and without shipping unlicensed content.

### Scope

```text
decoded rows (List<Object?>)
→ Workout-owned row DTO + strict validation (data boundary)
→ canonical Exercise (apps/shared)
→ ExerciseCatalog (ordered all + byRef)
→ ExerciseCatalogRepository + pure ExerciseCatalogQuery
```

### Non-Goals

See *Explicit non-changes*.

## 2. Codebase Exploration

### Verified Evidence (at `74032ddb`)

- `Exercise`, `ExerciseRef`, `ExerciseStatus` are on `main` in `apps/shared` (W1A1/W1A2); `ExerciseRef.catalog` throws `ArgumentError` for non-`ex_*` values; `Exercise` rejects blank/duplicate taxonomy with `ArgumentError`.
- Workout package is layer-first (`domain/models`, `domain/repositories`, `data/…`), repository interfaces are `abstract interface class`; tests use `flutter_test` and `package:tio_feature_workout/workout.dart`. TNYX-78 folder map targets `domain/exercises` and `data/exercises`.
- Readiness audit (owner file, read-only): bare array of 101 rows; consumed fields always present; no duplicate/invalid IDs; no licence/attribution evidence.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Split W3A into W3A1 (TNYX-269) and W3A2 (TNYX-270) | Approved | Data foundation can land without shipping content | Owner |
| Parser accepts decoded rows, not a document | Approved | Bare-array vs versioned envelope is a W3A2 owner decision | Owner |
| Consumed required fields: `id`, `title`, `muscleGroup`, `primaryMuscles`, `secondaryMuscles`, `equipment.primary`, `category`, `levels`, `isArchived`, `isCustom`; unknown keys ignored | Approved | Audit evidence | Owner |
| Bundled row with `isCustom: true` is invalid | Approved | Catalog rows are never user-created | Owner |
| One invalid row fails the whole catalog, with row/field diagnostics; duplicate refs fail | Approved | Bundled content must not silently lose stable IDs | Owner |
| Search: `displayName` only, case-insensitive substring, trimmed/collapsed whitespace; order by name then id; archived hidden | Approved | Audit search contract | Owner |
| Filters: nullable single-select `muscleGroup`, `primaryEquipment`, `category` | Approved | `levels`/`exerciseType` do not discriminate | Owner |
| Value rules (blank/duplicate) reuse canonical `Exercise` validation; DTO checks presence/types | Locked (engineering) | One rule source | Planning |

## 4. Architecture Design

Expected files:

```text
apps/features/workout/lib/src/domain/exercises/{exercises,exercise_catalog,exercise_catalog_query,exercise_catalog_repository,invalid_exercise_catalog_exception}.dart
apps/features/workout/lib/src/data/exercises/{exercises,exercise_catalog_row_dto,exercise_catalog_parser,decoded_rows_exercise_catalog_repository}.dart
apps/features/workout/lib/src/{domain/domain.dart,data/data.dart}   (barrel exports; DTO not exported)
apps/features/workout/test/{domain,data}/exercises/*_test.dart
```

## 5. Implementation Plan

- [ ] Domain: `ExerciseCatalog`, `ExerciseCatalogQuery`, repository interface, invalid-catalog exception + issues.
- [ ] Data: row DTO, parser, decoded-rows repository.
- [ ] Tests with synthetic fixtures.
- [ ] Validate, audit scope, commit, push, Draft PR, exact-head review.

## 6. Quality Review

### Validation Commands

```text
dart format --set-exit-if-changed <changed Dart files>
cd apps/features/workout && flutter pub get && flutter analyze && flutter test
git diff --check origin/main...HEAD
bash scripts/check_commit_attribution.sh origin/main HEAD
```

### Validation Evidence

Pending.

## 7. Final Handoff

Pending. W3A1 success does not make W3A2 licensing-ready.
