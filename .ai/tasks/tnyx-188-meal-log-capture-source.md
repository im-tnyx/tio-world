# TNYX-188 — N20A-1 Canonical MealLog capture-source value contract

**Status:** In progress
**Primary owner:** `apps/shared`
**Affected platforms:** Pure Dart shared contract; future mobile/watch/server consumers

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner instruction of 2026-09-10 authorises the first TNYX-113 slice `N20A-1 — Canonical MealLog capture-source value contract`, with implementation, validation, one focused commit/PR, and no merge.
**Approved product/UI/data-shape boundaries:** One canonical `MealLogCaptureSource` value contract in `apps/shared`, its shared export, and focused pure-Dart tests.
**Explicit non-changes:** No `MealLogEntry`, `MealLogItemSnapshot`, `MealLogProvenance`, `providerKey`, FatSecret IDs, `sourceFoodId`, `sourceServingId`, provider raw snapshot, AI model/confidence metadata, `NutritionSnapshot` change, `mealName`, `note`, serving quantity/unit, `consumedAt`, `consumedLocalDate`, timezone logic, Supabase migration/schema/RLS/mutation, repository/provider, Quick Add save, Food Search, Barcode, Photo/Voice/Text AI integration, Saved/Planned Meal, membership, ads, quotas, UI, or routes.

## Active Handoff

**Planning owner:** TNYX-66 readiness gate
**Implementation owner:** Claude
**Review owner:** GitHub reviewers after publication
**Implementation ownership state:** Complete — published for review
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** `tnyx/tnyx-188-meal-log-capture-source`, branched from `origin/main` `522cf0b657be11c19458075c2f788afa5d60b51d`
**HEAD SHA:** runtime implementation validated at `4c584fdfca90e2972042e4a0fda85a20a5030706`. Governance-only amends since then keep the `apps/shared` runtime and test tree byte-identical (`apps/` tree `5a9d28d1`). **Current published head: see PR #241 — GitHub is authoritative for the post-amend head and its CI state.** The exact head SHA is deliberately not re-embedded here, because each amend would change it again and cause self-referential SHA churn.
**Observed working-tree state:** One focused commit ahead of `origin/main`; protected unrelated work preserved untouched
**Observed uncommitted/dirty files:** Protected modified `pubspec.lock`; protected untracked `.ai/tasks/tnyx-54-nutrition-ia-readiness.md`
**PR / tracker:** TNYX-188, parent TNYX-113, High/P2, Mobile App. PR **#241** is published and open, `MERGEABLE`/`CLEAN`. Merge is not authorised and has not been performed. The only other open PR is #237 and it touches `apps/core` only.
**Current implementation state:** `MealLogCaptureSource`, its shared export and its focused tests are implemented and published. Later amends changed only task briefs to resolve governance findings; no runtime file changed.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`
**Validation completed at SHA:** Two separate records, because runtime and governance were validated at different heads.

```text
Runtime implementation validation — 4c584fdf
  dart format; focused 10 tests; full shared 60 tests; shared analysis
  CI-equivalent Melos workspace analysis and tests, 15 Flutter + 1 Dart package
  green exact-head GitHub CI (Analyze and test)
  runtime/test tree unchanged since that SHA

Governance amend validation — each later amend
  apps/ runtime + test tree byte-identical to 4c584fdf (tree 5a9d28d1)
  git diff --check PASS
  committed-path / machine-local-path audit PASS
  exact changed-file scope audit PASS
  exact-head GitHub CI must be green on the published PR head before merge
  authoritative exact current head and CI state live on PR #241
```

**Validation remaining:** Verify GitHub CI is green for the current published PR #241 head before final merge review.
**Current blocker:** None
**Open review finding IDs:** None open. `REV-P2-1`, `REV-P2-2`, `REV-P2-A` and `REV-P2-B` are resolved; see the Review Findings table.
**Next exact action:** Final review and owner merge decision. Do not merge without owner authorisation and do not start the next TNYX-113 slice from this brief.

## Global UI / Design-System Guardrail

Not applicable. This slice is pure Dart and makes no Flutter UI or Core design-system change.

## 1. Discovery

### User Outcome

One reusable, provider-independent identity for how a meal was captured, so later MealLog slices can record capture intent without inventing competing values or leaking provider identity into meal-level truth.

### Success Criteria

- Nine canonical capture sources exist with stable storage identities.
- Every canonical value round-trips through its storage identity.
- `barcode` is explicitly supported.
- An unknown or future storage identity stays unknown and is never remapped or defaulted.
- Quick Add stays distinct from Food Search; Photo, Voice and Text remain capture modes, not providers.
- No provider or nutrition field enters this contract.

### Scope

`apps/shared` source/export plus focused pure-Dart tests.

### Non-Goals

All explicit non-changes above, plus any speculative wrapper type, provider registry, capture adapter, or persistence encoding.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `apps/shared/lib/shared.dart`, `lib/src/nutrition/nutrition.dart`, `nutrient_id.dart`, `nutrition_snapshot.dart`, their tests, and `lib/src/workout/domain/models/` for durable-entity precedent.
- Existing pattern to follow: `NutrientId` is an enhanced enum carrying a stable `storageValue` decoupled from presentation, with a static `fromStorageValue` that returns `null` for unknown identities rather than remapping or defaulting. `MealLogCaptureSource` mirrors that pattern exactly.
- Ownership evidence: `AGENTS.md` assigns shared Dart entities/value objects to `apps/shared`; `apps/shared/lib/src/workout/domain/models/training_session.dart` already places a durable actual-log entity there; `apps/features/nutrition/lib/src/meal_logging/` holds presentation only. `apps/core` is excluded by rule.
- Tests already present: `test/nutrition/nutrient_id_test.dart`, `test/nutrition/nutrition_snapshot_test.dart`. No capture-source code or test overlap exists.
- Greenfield check: `MealLogCaptureSource`, `MealLogEntry`, `MealLogItemSnapshot`, `captureSource` return zero matches across `apps/` and `supabase/`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Capture source is meal-level; provider identity is item-level | Locked | One detailed meal may mix items from different providers, so `providerKey` cannot live on a meal-level capture contract. | Owner |
| No `MealLogProvenance` wrapper in this slice | Made | A one-field wrapper around a single enum would be speculative; the enum is directly composable by the later aggregate. | Owner instruction plus `AGENTS.md` rule against premature abstraction |
| Provider names are never capture sources | Locked | `fatsecret`, `openai`, `edamam` are adapters. `photo + FatSecret` is still `captureSource = photo`. | Owner |
| Unknown storage identity returns `null` | Made | Matches the current `NutrientId.fromStorageValue` forward-compatibility convention; a `quickAdd` fallback would fabricate capture intent. | Existing shared convention |
| Files stay flat in `lib/src/nutrition/` | Made | Matches the current two-file layout and avoids pre-empting TNYX-153's N1.2 package reorganisation or creating speculative folders. | Repository convention |

## 4. Architecture Design

### Chosen Approach

One enhanced enum with a stable `storageValue` and a static decode helper, exported through the existing Nutrition and shared barrels. Enum identity supplies deterministic equality, hashing and exhaustive `switch` support with no hand-written value semantics.

### Ownership and Data Flow

```text
capture entry point (Quick Add, Food Search, Barcode, Photo, ...)
  -> MealLogCaptureSource
  -> future MealLogEntry (later slice)
```

Provider identity flows separately into future item-level provenance and never through this type.

### Alternative Rejected

A `MealLogProvenance` class wrapping only `captureSource` was rejected: it adds an abstraction with no second field to justify it, and the later item/provenance slice will define the real provenance shape from fresh evidence.

### Failure and Accessibility States

Unknown storage identities decode to `null` so callers decide explicitly. No UI or accessibility surface exists in this slice.

## 5. Implementation Plan

- [x] Add `MealLogCaptureSource` with stable storage identities and a decode helper.
- [x] Export it through the existing Nutrition barrel.
- [x] Add focused canonical-coverage, round-trip, unknown-identity and distinctness tests.
- [x] Run proportional validation and self-review.
- [x] Commit only owned files, push, publish the focused PR, and observe exact-head CI without merging.

## 6. Quality Review

### Validation Run

```text
dart format <three owned Dart files>
PASS — 3 files, 0 changed

dart analyze apps/shared
PASS — no issues

dart test test/nutrition/meal_log_capture_source_test.dart
PASS — 10/10

dart test
PASS — apps/shared 60/60 (50 before this slice, 10 added)

CI-pinned isolated Melos 2.9.0:
melos exec -c 1 --flutter --fail-fast -- "flutter analyze --no-pub"
PASS — 15/15 Flutter packages

melos exec -c 1 --no-flutter --fail-fast -- "dart analyze ."
PASS — 1/1 Dart package

melos exec -c 1 --flutter --dir-exists=test --fail-fast -- "flutter test --no-pub"
PASS — 13/13 Flutter packages with tests

melos exec -c 1 --no-flutter --dir-exists=test --fail-fast -- "dart test"
PASS — 1/1 Dart package

git diff --check
PASS — no whitespace errors
```

The machine-global Melos is 8.6.0 and does not recognize this repository's Melos 2.x `melos.yaml`. No global tool was changed. Melos 2.9.0, matching `.github/workflows/flutter-ci.yml`, was installed into an isolated temporary cache and used for the workspace checks. `melos bootstrap` and workspace `pub get` were deliberately not run so the protected modified root `pubspec.lock` stayed byte-preserved; its SHA-256 was re-verified unchanged after every workspace command. Exact clean-checkout bootstrap remains covered by GitHub CI.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| QA-1 | P3 | Resolved | The markdown brief was accidentally passed to `dart format` in the first format run, which rejected it. | Uncommitted | The three Dart files formatted cleanly; the brief was re-verified intact and unmodified, and the command was rerun on Dart files only. |
| REV-P2-1 | P2 | Resolved | The TNYX-66 gate still named the ready slice as capture-source **and provenance**, and listed a `MealLogProvenance` wrapper plus provider/template/plan fields, contradicting this brief's approved enum-only scope. | `4c584fdf` | Narrowed the gate to `N20A-1 — Canonical MealLog capture-source value contract`, removed the wrapper and provider fields from the Slice A boundary and its test plan, and recorded provider/item provenance as an explicitly deferred later sub-slice with its downstream requirement preserved. |
| REV-P2-2 | P2 | Resolved | This brief's Active Handoff still reported implementation "starting" and validation "Pending" while the same brief recorded completed work, all validations `PASS` and final status `REVIEW`. | `4c584fdf` | Refreshed the handoff to the published state: ownership complete, PR #241 open, validation recorded at `4c584fdf` with green exact-head CI, no validation remaining, and the commit/push/PR checklist item checked. |
| REV-P2-A | P2 | Resolved | The handoff recorded validation and CI only at the historical `4c584fdf` while a later governance amend produced a newer published head, and still claimed no validation remained. | `8489ed2b` | Split the record into runtime validation at `4c584fdf` and per-amend governance validation, pointed the current head at PR #241 as the authoritative source instead of re-embedding a churning SHA, and set `Validation remaining` to verifying exact-head CI on the published PR head before merge review. |
| REV-P2-B | P2 | Resolved | The TNYX-66 gate handoff still described N20A-1 as not started and awaiting authorisation, and called the whole MealLog surface greenfield. | `8489ed2b` | Refreshed that handoff to the implemented-on-PR state and narrowed the greenfield claim to the aggregate, item snapshot, repositories and persistence, noting the capture-source contract exists on PR #241 but not yet on `main`. |

## 7. Downstream Requirements Preserved, Not Implemented

These stay owner-locked requirements for later TNYX-113 slices. This slice must not lose them.

**Provider provenance is a required future item-level capability.** When provider origin is known, durable MealLog item provenance must retain it:

```text
providerKey    = fatsecret
sourceFoodId   = ...
sourceServingId = ...
```

UI visibility is optional. Historical nutrition must always come from the durable `NutritionSnapshot`. An old MealLog must never be re-fetched from a provider and silently recalculated:

```text
old MealLog
→ re-fetch current FatSecret nutrition
→ silently replace history          NEVER
```

Provider provenance is reference and audit metadata, never historical nutrition truth. Provider or catalog deletion must not make old MealLog nutrition unreadable.

**Blank meal name rule.** A blank user meal name persists as `MealLogEntry.mealName = null`, and `Quick Add` may be used only as a UI display fallback. `Quick Add` must never be persisted as a fabricated user-entered `mealName`.

## 8. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-188-meal-log-capture-source.md`
- `.ai/tasks/tnyx-66-nutrition-readiness-gate.md` (the audit artifact that selected this slice)
- `apps/shared/lib/src/nutrition/meal_log_capture_source.dart`
- `apps/shared/lib/src/nutrition/nutrition.dart`
- `apps/shared/test/nutrition/meal_log_capture_source_test.dart`

### Actual Behavior

The public `tio_shared` Nutrition boundary now exposes `MealLogCaptureSource` with nine canonical capture identities and stable snake_case storage values. `fromStorageValue` decodes only currently supported identities and returns `null` for anything else, including case variants, the empty string and `null`, so a future or unrecognized identity is never remapped and never falls back to `quickAdd`. Enum identity supplies deterministic equality and hashing.

The type carries capture intent only. It holds no `providerKey`, no provider or catalog IDs, no AI metadata and no nutrition amounts.

### Known Limitations

No `MealLogEntry`, `MealLogItemSnapshot`, provenance type, repository, persistence, UI or capture adapter exists in this slice. Provider provenance remains a required downstream item-level capability recorded in section 7, not a gap in this contract.

### Final Status

`REVIEW`
