# TNYX-200 — Quick Add manual MealLog create / Log Meal activation

**Status:** In progress
**Primary owner:** `apps/features/nutrition`; `apps/app` remains composition-only
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice
**Approval status:** Approved
**Approval evidence:** Owner `go` on 2026-09-12 authorised the bounded create-only TNYX-200 implementation after its fresh N0 readiness audit.
**Approved boundary:** Activate the existing owner-approved Quick Add `Log Meal` flow through canonical `MealLogRepository.createManual`, with stable idempotency identity, pending/retry semantics, consumed-time mapping, and affected Diary refresh.
**Explicit non-changes:** No edit/delete/move/card-tap flow, note field, Fiber/micronutrient expansion, detailed Meal Editor/item snapshots, offline queue, new schema/RLS/grants/index/function, new Core visual contract, or Quick Add redesign.

`READY` applies only to TNYX-200; broad TNYX-115 remains open for later lifecycle work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT — one active implementation owner
**Review owner:** Owner / later review session
**Implementation ownership state:** Active
**Ownership transition:** Planning → Implementation after owner `go`
**Repository state last verified:** 2026-09-12
**Branch:** `tnyx/tnyx-200-n20c-1-quick-add-manual-meallog-create-log-meal-activation`
**Base / current main:** `22ab43cbc613078fd98713ddfd4e0ff6a0a5c9b6`
**Pre-source scope audit:** exact merge base at current main; readiness branch was 1 ahead / 0 behind with only this task brief changed; no open GitHub PRs.
**PR / tracker:** Linear TNYX-200 is `In Progress`; no PR yet.
**Current implementation state:** Quick Add shell/date/category validation exists; canonical MealLog create/idempotency/read/render foundations exist; production Quick Add save wiring does not yet exist.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_logging`, `apps/features/nutrition/lib/src/meal_diary`, `apps/app` provider composition, focused Nutrition/app tests, `docs/screens/meal-diary.md`.
**Validation remaining:** focused tests, complete base-to-head scope audit, repository-required Flutter/Dart analyze/tests and exact-head CI before review.
**Current blocker:** None.
**Open review findings:** None.
**Next exact action:** Implement the bounded create controller/state and existing Quick Add wiring, then tests and validation.

## 1. Discovery

### User outcome

```text
Meal Diary [+]
→ Add Food
→ Quick Add
→ valid manual nutrition draft
→ Log Meal
→ canonical manual MealLogEntry
→ durable confirmation
→ editor closes
→ affected Diary history refreshes
```

### Success criteria

- Calories required; optional Carbs/Protein/Fat blank means absent, not zero.
- Optional blank meal name persists as null; visual fallback remains presentation-only.
- Submit uses `MealLogCaptureSource.quickAdd` and no fake item/catalog identity.
- One logical create owns one stable UUID mutation id; ambiguous retry reuses the exact same frozen input/id.
- Pending blocks duplicate submit; failure preserves draft and never claims success.
- Defensive submit validation rejects a future actual datetime.
- Confirmed success refreshes the created local-date Diary model without changing the Diary selected date.
- Existing Quick Add geometry is preserved; only current CTA behavior/error/loading capability changes.

## 2. Verified Evidence

- Fresh `main` is `22ab43cb...`; no open PR overlaps this slice.
- TNYX-67, 114, 158, 195, 196, 198 and 199 are Done.
- `MealLogRepository` exposes `createManual`, `readById`, `listByLocalDate`; update/delete are intentionally absent.
- `ManualMealLogCreate` already carries `clientMutationId`, active category id, optional meal name/note/capture source, consumed instant/local date/time context, and `NutritionSnapshot`.
- Supabase adapter already pre-reconciles same mutation id and may throw `MealLogCreateOutcomeUnknown` when create outcome remains ambiguous.
- Live `public.meal_log_entries` is RLS-enabled with own-row CRUD policies/grants and `UNIQUE (user_id, client_mutation_id)`; no schema work is required.
- Nutrition already depends on `uuid` and has an injectable UUID-v4 pattern.
- Quick Add already owns field controllers, numeric validation, Meal Category selection/suggestion and a one-shot current-local DateTime draft.
- `TioButton` already owns loading/disabled/progress semantics.
- `mealDiaryHistoryProvider` is request-keyed; successful create needs explicit targeted invalidation/reload rather than a parallel cache.

### Stale docs noted, not followed

`.ai/CURRENT.md`, old DateTime-wheel handoff, `docs/DEVELOPMENT_SETUP.md`, and older backend wording in Supabase/module docs are stale against runtime/root architecture. They do not block this slice and do not authorise backend/schema work.

## 3. Decisions

| Decision | Status |
|---|---|
| Implement create only; leave edit/delete for parent TNYX-115 | Approved |
| Preserve current Quick Add field/layout contract | Approved |
| Notes remain out; create writes `note = null` | Approved boundary |
| Calories required; blank optional macros remain absent | Locked |
| Final save is online-required; no offline-success queue | Locked |
| Ambiguous retry uses same mutation id and frozen input | Locked |
| Quick Add does not move the Diary selected date | Locked |
| Persist exact local UTC offset; do not fabricate IANA zone id | Locked application of TNYX-114 |

## 4. Architecture Design

### Chosen approach

Use a Nutrition-owned create controller/state boundary between presentation and `MealLogRepository`. The widget keeps its route-local draft; submit snapshots and validates it once. The controller owns pending/failure/ambiguous-retry/success and stable mutation identity.

```text
QuickAddEditorSheet
  -> validated immutable create draft
  -> QuickAdd create controller
       -> stable UUID-v4 per logical attempt
       -> ManualMealLogCreate
       -> MealLogRepository.createManual

confirmed MealLogEntry
  -> dismiss editor with result
  -> MealDiaryPage
  -> targeted invalidate matching MealDiaryHistoryRequest
```

Create mapping:

```text
blank meal name        -> null
Calories               -> NutrientId.energy
Carbs                  -> NutrientId.carbohydrate
Protein                -> NutrientId.protein
Fat                    -> NutrientId.fat
blank optional macro   -> absent
note                    -> null
captureSource           -> quickAdd
consumedAt              -> draft.toUtc()
consumedLocalDate       -> draft calendar date
consumedTimezoneId      -> null unless trusted source already exists
consumedUtcOffsetMinutes -> draft.timeZoneOffset.inMinutes
```

### Retry state

```text
idle
→ submitting(frozen input + mutation id)
→ success
→ known failure: preserve draft; retry may start a new attempt only after known rejection
→ outcome unknown: preserve exact frozen input/id; only reconciliation retry allowed
```

Presentation must not call Supabase directly or own repository idempotency rules.

## 5. Implementation Plan

- [x] Freshly verify main/branch/overlap and move TNYX-200 to `In Progress`.
- [x] Transfer implementation ownership in this brief before source edits.
- [ ] Add create controller/state + deterministic UUID/clock seams.
- [ ] Map validated Quick Add draft to canonical `NutritionSnapshot`/`ManualMealLogCreate`.
- [ ] Wire canonical MealLog repository into Quick Add without adding a second persistence owner.
- [ ] Activate existing `Log Meal` CTA only for valid draft; use existing loading semantics.
- [ ] Preserve stable input/id through ambiguous-outcome reconciliation.
- [ ] On confirmed success dismiss and refresh affected Diary history without changing selected date.
- [ ] Add focused controller/widget/integration regressions.
- [ ] Reconcile current Quick Add docs/comments that still say persistence is unavailable.
- [ ] Run exact scope + Flutter/Dart validation and hand off for review.

## 6. Quality Review

### Validation run

Not run yet; implementation has just started.

### Review findings

None yet.

## 7. Final Handoff

Not reached.
