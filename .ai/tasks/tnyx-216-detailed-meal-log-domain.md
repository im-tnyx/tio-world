# TNYX-216 — Detailed MealLogItemSnapshot + MealLogEntry domain foundation

**Status:** Validated
**Primary owner:** Shared Nutrition domain
**Affected platforms:** Pure Dart shared contract; consumed by Flutter Android/iOS later

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `go` on 2026-09-17 after the fresh Linear + GitHub + live Supabase readiness audit and asked to follow root `AGENTS.md`.
**Approved product/UI/data-shape boundaries:** Pure-Dart `apps/shared` detailed MealLog domain foundation only: durable item snapshot consumed facts plus `MealLogEntry.detailed(...)` invariants and tests.
**Explicit non-changes:** No Flutter UI, routing, repository create API, Supabase table/column/constraint/RLS/index/function/RPC changes, parser/API/provider wiring, Meal Editor `Log Meal` activation, Quick Add change, item provider provenance, serving conversion or catalog identity.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** Connector-only session; GitHub `main` = `363754242477f2b4b9e5d8ac5a2cc71e69c43f98` and remains the merge base. Source/test head was `7 ahead / 0 behind` with exactly six intended files before this handoff-only reconciliation.
**Branch:** `tnyx/tnyx-216-n20a-7-detailed-meallog-domain-foundation`
**Validated source/test HEAD SHA:** `becf4ce07af4e7d536363770701d6812e302da95`
**Observed working-tree state:** Connector-only session; local `git status` unavailable. GitHub branch/commit/diff evidence is used instead.
**Observed uncommitted/dirty files:** Not observable through connector-only execution; repository writes are committed directly to this branch.
**PR / tracker:** Draft GitHub PR #271; Linear TNYX-216, parent TNYX-113; related TNYX-207, TNYX-215, TNYX-188.
**Current implementation state:** Bounded shared detailed MealLog domain contract implemented and source/test head validated.
**Relevant execution surface:** `apps/shared/lib/src/nutrition/meal_log_entry.dart`, `meal_log_item_snapshot.dart`, Nutrition shared export, focused shared tests.
**Validation completed at SHA:** `becf4ce07af4e7d536363770701d6812e302da95` via Flutter CI #2600 / run `35178984501` — bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed.
**Validation remaining:** Verify exact-head CI after this handoff-only metadata commit, refresh PR/thread/scope audit, then move PR/tracker to review state.
**Current blocker:** None for TNYX-216. Detailed Supabase physical shape remains a separate owner-approval gate after merge.
**Open review finding IDs:** None.
**Next exact action:** Validate this metadata-only head, perform final scope/thread audit, mark PR #271 ready for review when supported, and reconcile TNYX-216 to `In Review`.

## Global UI / Design-System Guardrail

No Flutter UI is in scope. Current rendered UI remains unchanged.

## 1. Discovery

### User Outcome

Establish the durable detailed-meal domain truth needed so the existing `MealLoggingDraft`/Meal Editor can later save real item-backed MealLogs without pretending they are Quick Add/manual entries.

### Success Criteria

- provider-independent durable item snapshot exists;
- detailed `MealLogEntry` can represent one or more durable consumed items;
- manual and detailed truth are mutually exclusive;
- incomplete temporary draft semantics remain separate from final durable item requirements;
- existing manual behavior remains source-compatible;
- no persistence/UI/API behavior changes.

### Scope

One shared item model, detailed aggregate construction/invariants, public export, focused pure-Dart tests.

### Non-Goals

Repository/Supabase persistence, schema, detailed create idempotency, parser/provider provenance, UI activation, edit/delete, unit conversion and external APIs.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, task template, TNYX-113/TNYX-188/TNYX-189/TNYX-207/TNYX-215, current shared Nutrition contracts/tests, current manual MealLog repository, and live Supabase manual-only schema.
- Existing pattern followed: `apps/shared` owns pure-Dart cross-feature contracts; `NutritionSnapshot` owns immutable canonical nutrient truth; `MealLogEntry.manual` already owns time/name/note/revision normalization; `MealLoggingDraftItem` intentionally permits incomplete pre-confirmation facts.
- Live persistence remained unchanged: `public.meal_log_entries` is still manual-only and no detailed item table/function was created.
- Tests/validation: existing shared MealLog tests plus new focused item/detailed aggregate tests; governed workspace CI passed at the source/test head.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Durable detailed item requires positive finite quantity, nonblank serving unit and a required consumed `NutritionSnapshot` | Locked for this slice | Final actual-history item carries confirmed amount/unit plus canonical snapshot ownership; the snapshot may contain zero currently-known nutrients so unknown future nutrient identities remain forward-compatible instead of making old clients reject valid future rows. | TNYX-113 + TNYX-187 + architecture |
| First durable item slice stores only provider-independent consumed facts | Locked | Provider provenance is explicitly item-level but remains additive later without making provider data historical nutrition truth. | TNYX-188/TNYX-113 |
| Detailed aggregate carries no manual nutrition snapshot | Locked | Prevents competing truth between meal-level manual values and item snapshots. | TNYX-113 |
| Manual aggregate exposes an empty detailed-item list | Locked | Preserves one canonical aggregate without fabricating detailed items for Quick Add. | TNYX-113/TNYX-115 |
| Detailed items must reference their parent MealLog identity and have unique item IDs within the aggregate | Locked | Prevents cross-aggregate child attachment and ambiguous durable child identity before physical persistence is introduced. | Architecture |
| `captureSource` remains orthogonal to `mode` at this shared value boundary | Locked | Existing capture-source and mode contracts are explicit independent identities; workflow adapters decide which combinations they create rather than the aggregate inferring one identity from the other. | TNYX-188/TNYX-189 |
| No detailed meal-level total field is added | Locked | Detailed totals derive from durable item snapshots; a second authoritative total would duplicate truth. | TNYX-113 |

## 4. Architecture Design

### Chosen Approach

Added immutable `MealLogItemSnapshot` under `apps/shared/lib/src/nutrition/`. Extended the existing canonical `MealLogEntry` with immutable `detailedItems` and a `MealLogEntry.detailed(...)` factory. Existing `MealLogEntry.manual(...)` behavior remains the manual/coarse truth owner and now explicitly exposes an empty detailed-item list.

### Ownership and Data Flow

```text
future MealLoggingDraft
→ future detailed create input / persistence adapter
→ durable MealLogEntry.detailed
   └─ one or more MealLogItemSnapshot
      └─ consumed NutritionSnapshot
```

### Alternative Rejected

- Persisting parsed items as `manualNutritionSnapshot` to reuse Quick Add.
- Putting provider IDs/raw AI output into the first canonical item snapshot.
- Rejecting an otherwise-valid `NutritionSnapshot` only because the current registry sees zero known nutrients; that would break the existing future-identity compatibility rule.
- Adding a denormalized authoritative meal total beside item snapshots.
- Widening Supabase before the shared durable contract is frozen.

### Failure and Accessibility States

No UI/accessibility behavior changes. Invalid durable construction fails synchronously with argument errors; malformed or incomplete temporary parse facts stay in the draft layer until corrected.

## 5. Implementation Plan

- [x] Add immutable provider-independent `MealLogItemSnapshot`.
- [x] Export it through the shared Nutrition public barrel.
- [x] Extend `MealLogEntry` with detailed-mode construction/invariants while preserving manual behavior.
- [x] Add focused item-snapshot and detailed aggregate tests.
- [x] Run governed workspace analyze/test validation at source/test head.
- [x] Perform source-head scope and architecture review; no P1/P2 findings remain.
- [ ] Validate final metadata-only head and complete PR/tracker review handoff.

## 6. Quality Review

### Validation Run

Flutter CI #2600 / run `35178984501` at source/test SHA `becf4ce07af4e7d536363770701d6812e302da95`:

```text
Bootstrap workspace       PASS
Analyze Flutter packages  PASS
Analyze Dart packages     PASS
Test Flutter packages     PASS
Test Dart packages        PASS
```

The auxiliary GitHub `Code scanning AI findings` dynamic automation failed inside its external `Processing Request` step and emitted no PR review, inline comments, or code finding. It is recorded as tooling evidence, not represented as a successful code scan. Repository Flutter/Dart validation and the independent exact-head code review remain the quality gates for this slice.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| T216-RF1 | P3 | Resolved before source implementation | Initial task wording considered requiring at least one currently-known nutrient in an item snapshot. | task-planning checkpoint | Reconciled with `NutritionSnapshot` forward compatibility: the snapshot is required, but an empty current-registry view remains valid. Task brief and Linear acceptance were corrected before source changes. |

Final source-head review found no open P1/P2 finding, no provider/API/persistence leakage, no Flutter dependency in `apps/shared`, and no Supabase/UI scope widening.

## 7. Final Handoff

### Changed Files

Six intended files at the validated source/test head:

1. `.ai/tasks/tnyx-216-detailed-meal-log-domain.md`
2. `apps/shared/lib/src/nutrition/meal_log_entry.dart`
3. `apps/shared/lib/src/nutrition/meal_log_item_snapshot.dart`
4. `apps/shared/lib/src/nutrition/nutrition.dart`
5. `apps/shared/test/nutrition/meal_log_detailed_entry_test.dart`
6. `apps/shared/test/nutrition/meal_log_item_snapshot_test.dart`

### Actual Behavior

The shared domain can now represent a durable detailed actual MealLog with one or more immutable consumed item snapshots. Each item has durable child/parent identity, display facts, confirmed positive quantity/unit and canonical consumed nutrition. Detailed entries contain no manual nutrition snapshot and manual entries contain no fabricated detailed items. This does not yet persist detailed rows or activate any UI action.

### Known Limitations

Detailed repository/Supabase persistence, parent+item atomic create/idempotency, item provider provenance, detailed edit/delete, parser/API wiring and Meal Editor `Log Meal` activation remain intentionally deferred. The next persistence slice requires a fresh live-schema audit and explicit owner approval for the exact Supabase table/column shape before implementation.

### Final Status

`REVIEW` — source/test behavior validated; final metadata-head CI/review handoff pending.
