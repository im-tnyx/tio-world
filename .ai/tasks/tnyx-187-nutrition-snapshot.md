# TNYX-187 — N1.1b Canonical NutritionSnapshot Shared Value Object

**Status:** In review — published, merge not authorized
**Primary owner:** `apps/shared`
**Affected platforms:** Pure Dart shared contract; future mobile/watch/server consumers

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner instruction of 2026-09-10 explicitly authorises N1.1b implementation, validation, one focused commit/PR, and no merge.
**Approved product/UI/data-shape boundaries:** Implement canonical `NutritionSnapshot`, required current `NutrientId` integration, shared exports, and pure-Dart contract tests in `apps/shared`.
**Explicit non-changes:** No `MealLogEntry`, `MealLogItemSnapshot`, provenance/capture-source type, repository/provider, Quick Add save, Food Search, Barcode, AI/Voice/Photo, FatSecret adapter, Supabase schema/migration/RLS/function/mutation, Flutter UI/route, Saved/Planned Meal, membership, entitlement, ads, or daily aggregation.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Codex self-review; GitHub reviewers after publication
**Implementation ownership state:** Implementation complete; published for review
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** `tnyx/tnyx-187-nutrition-snapshot`
**HEAD SHA:** `81b1c32309c4a8f9ca6b9f3957b825880d2aae2a` — the runtime-validated, exact-head-CI-green commit. This governance-only refresh is amended onto that same single commit and keeps `apps/` byte-identical, so PR #240 carries the exact published head.
**Observed working-tree state:** Branch is one focused commit ahead of `origin/main`; protected unrelated work remains present and excluded.
**Observed uncommitted/dirty files:** Protected modified `pubspec.lock`; protected untracked `.ai/tasks/tnyx-54-nutrition-ia-readiness.md`. The TNYX-66 readiness brief and this brief are now committed.
**PR / tracker:** TNYX-187, parent TNYX-140, High/P2, Mobile App; blocks TNYX-113. PR #240 is published and open, `MERGEABLE`/`CLEAN`, with no unresolved review threads. Merge is not authorized and has not been performed.
**Current implementation state:** Runtime value object, registry metadata integration, shared export, and focused tests are implemented, published, and validated.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, `apps/shared/lib/shared.dart`
**Validation completed at SHA:** `81b1c323`: format; focused 12 tests; full shared 50 tests; shared analysis; CI-equivalent Melos workspace analysis and tests; `git diff --check`; committed-diff scope audit; and green exact-head GitHub CI (`Analyze and test`).
**Validation remaining:** None for this slice. Only the owner merge decision is outstanding.
**Current blocker:** None.
**Open review finding IDs:** None open. `REV-P1` is resolved; see the Review Findings table.
**Next exact action:** Final review and owner merge decision. Do not merge without owner authorization and do not start TNYX-113 from this brief.

## Global UI / Design-System Guardrail

Not applicable. This slice is pure Dart and makes no Flutter UI or Core design-system change.

## 1. Discovery

### User Outcome

Publish one reusable, provider-independent, immutable Nutrition value object that preserves canonical nutrient amounts without collapsing unknown values into zero.

### Success Criteria

- `NutritionSnapshot` exposes a schema version and canonical `NutrientId` keyed values.
- Creation and serialization preserve absent versus explicitly zero values.
- Negative and non-finite amounts are rejected; zero is allowed; no arbitrary upper limit is added.
- Input collection mutation cannot alter a created snapshot.
- Equality and hash semantics are deterministic and map-order independent.
- Unknown future storage identities remain unknown and are never remapped.
- No provenance or downstream MealLog behavior enters the value object.

### Scope

`apps/shared` source/export and focused pure-Dart tests only.

### Non-Goals

All explicit non-changes above, plus speculative registry expansion, provider aliases/conversions, database encoding, and aggregation APIs.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `apps/shared/lib/shared.dart`, Nutrition barrel, current `NutrientId` implementation/tests, package manifest, shared value-object conventions, TNYX-66 readiness brief, TNYX-140/TNYX-143/TNYX-153 Linear state.
- Existing pattern to follow: small manually implemented pure-Dart value types with explicit validation/equality and public barrel exports; generated code is unnecessary for one map-backed contract.
- Tests or validation already present: `apps/shared/test/nutrition/nutrient_id_test.dart`; no existing snapshot code/test overlap.
- Fresh GitHub evidence: PR #237 changes only `apps/core`; no active NutritionSnapshot PR.
- Duplicate search: no existing NutritionSnapshot implementation issue; TNYX-187 was created as the sole focused implementation child.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Slice name is N1.1b, never N1.2 | Locked | TNYX-153 already owns N1.2 package organization. | Owner |
| TNYX-140 remains semantic owner; TNYX-187 implements runtime only | Locked | Keeps contract governance separate from the small implementation child. | Owner |
| `NutritionSnapshot` lives in `apps/shared` | Locked | It is a cross-feature/platform pure-Dart value object. | Owner / repository ownership |
| Unknown serialized nutrient keys are ignored, never remapped | Made | Matches current `NutrientId.fromStorageValue` forward-compatibility contract without failing unrelated known values. | Existing registry contract |
| Serialization uses `schemaVersion` plus a nested `nutrients` map keyed by `NutrientId.storageValue` | Made | Mirrors the frozen conceptual contract without coupling to a Supabase table or provider payload. | TNYX-140 / implementation |
| Caller input is defensively copied and exposed unmodifiable | Made | Prevents mutation from changing durable value semantics. | Implementation invariant |
| Blank MealLog name persists absent and display may derive `Quick Add` | Locked downstream only | It belongs to TNYX-113/Quick Add, not this value object. | Owner |

## 4. Architecture Design

### Chosen Approach

Add one final immutable class with a validated `Map<NutrientId, num>`, explicit JSON-compatible `toJson`/`fromJson`, typed lookup helpers, order-independent equality/hash semantics, and defensive copying. Extend registry metadata only as required to expose the frozen `derivedOnly` flag; all currently implemented NutrientIds remain source facts.

### Ownership and Data Flow

```text
future normalized source values
  -> Map<NutrientId, num>
  -> NutritionSnapshot validation + immutable copy
  -> future owning domain entity
```

Provider/capture provenance remains beside the future owning entity and never enters the snapshot.

### Alternative Rejected

Generated Freezed/JSON code adds build artifacts and complexity without evidence. A string-keyed domain map would leak storage/provider identifiers and weaken compile-time ownership.

### Failure and Accessibility States

Invalid known amounts throw argument errors; malformed serialized shapes throw format errors. Unknown future nutrient storage keys are skipped without remapping. No UI/accessibility surface exists.

## 5. Implementation Plan

- [x] Add `NutritionSnapshot` and required registry metadata integration.
- [x] Export it through the existing Nutrition/shared barrels.
- [x] Add focused creation, validation, serialization, immutability, equality, and unknown-key tests.
- [x] Run proportional validation and self-review.
- [x] Commit only owned files, push, create the focused PR, and observe exact-head CI without merging.

## 6. Quality Review

### Validation Run

```text
dart format <four owned Dart files>
PASS — 4 files checked; 2 initially changed, then the registry follow-up formatted

dart test test/nutrition/nutrition_snapshot_test.dart
PASS — 12/12

dart analyze apps/shared
PASS — no issues

dart test
PASS — apps/shared 50/50

CI-pinned isolated Melos 2.9.0:
melos exec -c 1 --flutter --fail-fast -- "flutter analyze --no-pub"
PASS — 15/15 Flutter packages

melos exec -c 1 --no-flutter --fail-fast -- "dart analyze ."
PASS — 1/1 Dart package

melos exec -c 1 --flutter --dir-exists=test --fail-fast -- "flutter test --no-pub"
PASS — 13/13 Flutter packages with tests

melos exec -c 1 --no-flutter --dir-exists=test --fail-fast -- "dart test"
PASS — 1/1 Dart package, 50/50 tests
```

The machine-global Melos 8.6.0 first reported that the legacy `melos.yaml` was not a recognized workspace. No global tool was changed. Melos 2.9.0, matching `.github/workflows/flutter-ci.yml`, was installed into an isolated temporary cache and used for the successful workspace checks. `melos bootstrap` and workspace `pub get` were not rerun so the protected modified root `pubspec.lock` remained byte-preserved; exact clean-checkout bootstrap remains covered by GitHub CI.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| QA-1 | P2 | Resolved | Optional `derivedOnly` enum constructor parameter produced an analyzer warning because all current IDs are source facts. | Uncommitted | Made source-fact metadata explicit on every current registry entry; shared and workspace analysis then passed. |
| TOOL-1 | P3 | Resolved | Global Melos 8.6.0 did not recognize the repository's Melos 2.x workspace configuration. | Uncommitted | Used isolated CI-pinned Melos 2.9.0 without changing the global installation. |
| REV-P1 | P1 | Resolved | The Validation Run block committed workstation-specific SDK paths, which repository governance prohibits. | `70c76abb` | Normalized the four commands to portable `dart format` / `dart test` / `dart analyze` in `81b1c323`; `apps/` stayed byte-identical and the review thread is resolved. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-187-nutrition-snapshot.md`
- `.ai/tasks/tnyx-66-nutrition-readiness-gate.md`
- `apps/shared/lib/src/nutrition/nutrient_id.dart`
- `apps/shared/lib/src/nutrition/nutrition.dart`
- `apps/shared/lib/src/nutrition/nutrition_snapshot.dart`
- `apps/shared/test/nutrition/nutrition_snapshot_test.dart`

### Actual Behavior

The public `tio_shared` Nutrition boundary now exposes an immutable `NutritionSnapshot` with explicit `schemaVersion`, validated canonical `NutrientId` amounts, missing-versus-zero preservation, JSON-compatible round-trip behavior, forward-unknown key handling, deterministic value semantics, and defensive collection copying. Current NutrientIds explicitly declare that they are source facts rather than derived-only values.

### Known Limitations

No aggregation, provider normalization, provenance, MealLog, UI, repository, or Supabase persistence exists in this slice. Unknown future nutrient keys are intentionally ignored rather than remapped; the typed current snapshot therefore retains only identities known to the current registry.

### Final Status

`REVIEW — PR #240 published as one focused commit, exact-head CI green, all review findings resolved, awaiting owner merge decision. Not merged.`
