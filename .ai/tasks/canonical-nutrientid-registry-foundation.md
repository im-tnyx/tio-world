# Canonical NutrientId Registry Foundation

**Status:** Validated
**Primary owner:** Codex
**Affected platforms:** `apps/shared` pure-Dart contract

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner request: “Run a FRESH AUDIT, then implement the smallest canonical Nutrient Registry foundation required by TNYX-140.”
**Approved product/UI/data-shape boundaries:** Introduce only the provider-independent `NutrientId` registry and canonical nutrient-unit lookup for the nine frozen/current IDs. No visible UI or Supabase table/column change is approved or needed.
**Explicit non-changes:** No N15 implementation, Additional Nutrient Goals UI, `NutritionSnapshot`, `NutrientAmount`, provider adapters/aliases, recommendation engine, persistence, migration, schema/RLS/RPC work, or hosted Supabase mutation.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Not assigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-08-31; local `HEAD` and `origin/main` both `ee65dff3782610b62e5a36d5e109a0bb18a12645` before branching.
**Branch:** `codex/nutrient-registry-foundation`
**HEAD SHA:** `ee65dff3782610b62e5a36d5e109a0bb18a12645`
**Observed working-tree state:** Clean before task-brief creation.
**Observed uncommitted/dirty files:** None before task-brief creation.
**PR / tracker:** No open GitHub PRs; Linear `TNYX-140` remains contract-only; child `TNYX-143` owns this implementation.
**Current implementation state:** Registry and focused tests implemented; no dependent consumer was changed.
**Relevant execution surface:** `apps/shared` public pure-Dart contract; `apps/features/nutrition` is a consumer boundary only and remains unchanged.
**Validation completed at SHA:** Fresh Git/tracker/source overlap audit at `ee65dff3782610b62e5a36d5e109a0bb18a12645`; validated uncommitted working tree with focused format, analysis, tests, and `git diff --check`.
**Validation remaining:** No code validation remains. Commit/push/PR publication is not included without separate authorization.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Review or publish the validated change only if separately authorized.

## 1. Discovery

### User Outcome

Provide one typed, provider-independent canonical nutrient identity and unit lookup that future Nutrition consumers can share without creating a snapshot, persistence shape, or UI.

### Success Criteria

- Nine implemented IDs have stable snake_case storage values and exactly one canonical unit.
- `fromStorageValue` round-trips known values and returns `null` for unknown future values without remapping or throwing.
- `energy` remains a nutrient-fact identity, not the `calories` core-target identity.
- No unit is encoded in a nutrient ID.

### Scope

`energy`, `protein`, `carbohydrate`, `fat`, `fiber`, `saturated_fat`, `trans_fat`, `sodium`, and `vitamin_d` only.

### Non-Goals

Exhaustive nutrient coverage, display metadata, provider normalization, `NutritionSnapshot`, storage/migrations, UI, recommendations, and target editing.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `apps/shared` is the repository's pure-Dart cross-feature contract owner; `apps/features/nutrition` currently owns target/profile data and presentation.
- Existing pattern to follow: Dart enums in feature/shared contracts expose explicit `storageValue` and nullable `fromStorageValue` decoding.
- Existing registry overlap: no `NutrientId`, `NutritionSnapshot`, `NutrientAmount`, or `nutrient_id` implementation exists under `apps/`.
- Tracker: `TNYX-140` freezes semantics only; `TNYX-143` is the sole implementation child. `TNYX-141` first subset is four nutrients; no additional-goal implementation is authorized.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Registry owner is `apps/shared` | Made | The contract is pure Dart and crosses future Nutrition, provider, history, and platform boundaries. | Owner-approved scope / Codex implementation |
| Unknown storage values decode to `null` | Made | Preserves future compatibility without silently mapping an identity or crashing unrelated current data. | TNYX-140 contract |
| Canonical unit is a typed registry metadata value | Made | Keeps unit distinct from nutrient identity and from user display-unit preferences. | TNYX-140 contract |

## 4. Architecture Design

### Chosen Approach

Add one `apps/shared` nutrition public boundary containing a typed `NutrientId` enum and a small canonical-unit enum. Each ID owns an explicit `storageValue` and `canonicalUnit`; nullable decoding handles unknown values safely.

### Ownership and Data Flow

```text
future source/provider adapter
→ NutrientId storage value
→ canonical unit lookup
→ future Nutrition-owned consumers
```

### Alternative Rejected

Feature-local registry: rejected because the frozen registry is a cross-feature, platform-neutral domain contract and `apps/shared` owns pure-Dart shared contracts.

### Failure and Accessibility States

Unknown persisted IDs return `null`; no UI is introduced in this slice.

## 5. Implementation Plan

- [x] Add the public shared nutrition boundary and registry types.
- [x] Add focused contract tests.
- [x] Run formatting, analysis, and focused tests.
- [x] Record validation and final handoff.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\flutter.bat dart format apps\shared\lib\shared.dart apps\shared\lib\src\nutrition\nutrition.dart apps\shared\lib\src\nutrition\nutrient_id.dart apps\shared\test\nutrition\nutrient_id_test.dart
PASS

G:\dev\flutter-sdk\bin\flutter.bat analyze
PASS (working directory: apps/shared)

G:\dev\flutter-sdk\bin\flutter.bat pub run test test\nutrition\nutrient_id_test.dart
PASS (working directory: apps/shared)

git diff --check
PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/canonical-nutrientid-registry-foundation.md`
- `apps/shared/lib/shared.dart`
- `apps/shared/lib/src/nutrition/nutrition.dart`
- `apps/shared/lib/src/nutrition/nutrient_id.dart`
- `apps/shared/test/nutrition/nutrient_id_test.dart`

### Actual Behavior

The public `tio_shared` boundary now exposes nine typed nutrient identities with stable snake_case storage values and typed canonical units. Known values round-trip; unknown future values remain `null` rather than being remapped or throwing. No UI, target state, snapshot, provider, persistence, or Supabase behavior changed.

### Known Limitations

`NutritionSnapshot`, provider adapters, persistence, UI, and additional-goal recommendation policies remain intentionally unimplemented.

### Final Status

`PASS`
