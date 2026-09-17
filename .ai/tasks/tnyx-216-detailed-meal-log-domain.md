# TNYX-216 — Detailed MealLogItemSnapshot + MealLogEntry domain foundation

**Status:** In progress
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
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Connector-only session; GitHub `main` = `363754242477f2b4b9e5d8ac5a2cc71e69c43f98` (merged PR #270). No `apps/shared/AGENTS.md` exists; root `AGENTS.md` applies. No overlapping N20A-7 branch/task existed before this branch.
**Branch:** `tnyx/tnyx-216-n20a-7-detailed-meallog-domain-foundation`
**HEAD SHA:** task-brief reconciliation commit pending at this checkpoint
**Observed working-tree state:** Connector-only session; local `git status` unavailable. GitHub branch/commit/diff evidence is used instead.
**Observed uncommitted/dirty files:** Not observable through connector-only execution; repository writes are committed directly to this branch.
**PR / tracker:** Linear TNYX-216, parent TNYX-113; related TNYX-207, TNYX-215, TNYX-188. PR not created yet.
**Current implementation state:** Readiness complete; task brief created before source changes.
**Relevant execution surface:** `apps/shared/lib/src/nutrition/meal_log_entry.dart`, new durable item-snapshot contract, Nutrition shared exports, `apps/shared/test/nutrition/**`.
**Validation completed at SHA:** Not run yet.
**Validation remaining:** focused `apps/shared` tests, analyze, proportional workspace CI, final diff/review.
**Current blocker:** None for this domain-only slice. Detailed Supabase physical shape remains a separate owner-approval gate after merge.
**Open review finding IDs:** None.
**Next exact action:** Implement the bounded shared domain contract and focused tests only.

## Global UI / Design-System Guardrail

No Flutter UI is in scope. Current rendered UI must remain unchanged.

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

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, task template, TNYX-113/TNYX-188/TNYX-207/TNYX-215, current shared Nutrition contracts/tests, current manual MealLog repository, and live Supabase manual-only schema.
- Existing pattern to follow: `apps/shared` owns pure-Dart cross-feature contracts; `NutritionSnapshot` owns immutable canonical nutrient truth; `MealLogEntry.manual` already owns time/name/note/revision normalization; `MealLoggingDraftItem` intentionally permits incomplete pre-confirmation facts.
- Tests or validation already present: `apps/shared/test/nutrition/meal_log_entry_test.dart` and existing shared package tests.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Durable detailed item requires positive finite quantity, nonblank serving unit and a required consumed `NutritionSnapshot` | Locked for this slice | Final actual-history item must carry confirmed amount/unit plus canonical snapshot ownership; the snapshot may contain zero currently-known nutrients so unknown future nutrient identities remain forward-compatible instead of making old clients reject valid future rows. | TNYX-113 + TNYX-187 + architecture |
| First durable item slice stores only provider-independent consumed facts | Locked | Provider provenance is explicitly item-level but can be added later without making provider data historical nutrition truth. | TNYX-188/TNYX-113 |
| Detailed aggregate carries no manual nutrition snapshot | Locked | Prevents competing truth between meal-level manual values and item snapshots. | TNYX-113 |
| Manual aggregate exposes an empty detailed-item list | Locked | Preserves one canonical aggregate without fabricating detailed items for Quick Add. | TNYX-113/TNYX-115 |
| Detailed items must reference their parent MealLog identity and have unique item IDs within the aggregate | Locked | Prevents cross-aggregate attachment and ambiguous durable child identity before physical persistence is introduced. | Architecture |
| `captureSource` remains orthogonal to `mode` | Locked | TNYX-188 defines capture intent separately from persistence mode; this shared aggregate must not infer or remap one from the other. | TNYX-188 |
| No detailed meal-level total field is added | Locked | Detailed totals derive from durable item snapshots; a second authoritative total would duplicate truth. | TNYX-113 |

## 4. Architecture Design

### Chosen Approach

Add immutable `MealLogItemSnapshot` under `apps/shared/lib/src/nutrition/`. Extend the existing canonical `MealLogEntry` with a `detailedItems` field and a `MealLogEntry.detailed(...)` factory. Preserve `MealLogEntry.manual(...)` behavior and make it always expose an empty detailed-item collection.

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

No UI/accessibility behavior changes. Invalid durable construction fails synchronously with argument errors; malformed temporary parse facts stay in the draft layer until corrected.

## 5. Implementation Plan

- [ ] Add immutable provider-independent `MealLogItemSnapshot`.
- [ ] Export it through the shared Nutrition public barrel.
- [ ] Extend `MealLogEntry` with detailed-mode construction/invariants while preserving manual behavior.
- [ ] Add focused item-snapshot and detailed aggregate tests.
- [ ] Run focused shared validation and proportional repository CI.
- [ ] Perform exact-head scope/review audit and handoff.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Detailed repository/Supabase persistence, final save/idempotency, item provider provenance, parser/API wiring and Meal Editor activation remain intentionally deferred.

### Final Status

`REVIEW`
