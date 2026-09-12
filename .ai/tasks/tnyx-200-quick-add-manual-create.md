# TNYX-200 — Quick Add manual MealLog create / Log Meal activation

**Status:** In review
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
**Implementation owner:** None — implementation is complete and awaiting review
**Review owner:** PR / owner review
**Implementation ownership state:** Released after validation
**Ownership transition:** Planning → Implementation after owner `go` → Review after exact-source validation
**Repository state last verified:** 2026-09-12
**Branch:** `tnyx/tnyx-200-n20c-1-quick-add-manual-meallog-create-log-meal-activation`
**Base / current main:** `22ab43cbc613078fd98713ddfd4e0ff6a0a5c9b6`
**Validated source HEAD:** `0c61a3c67cbcfed504fd94123e3d9f4d72085bb5`
**PR / tracker:** GitHub PR #259; Linear TNYX-200 moves to `In Review` with this handoff.
**Current implementation state:** Bounded Quick Add manual create is implemented through the canonical MealLog repository, including validation, stable idempotency identity, retry/reconciliation, pending/error state, confirmed-result dismissal, and targeted Diary history invalidation.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_logging`, `apps/features/nutrition/lib/src/meal_diary`, focused Nutrition tests, `docs/screens/meal-diary.md`.
**Validation:** Flutter CI #2426, run `34674939574`, job `103503019617`, passed bootstrap, Flutter/Dart analyze, and Flutter/Dart tests at validated source `0c61a3c67cbcfed504fd94123e3d9f4d72085bb5`. No separate local validation is claimed for this API-authored session.
**Final scope audit:** `main` remains the exact merge base; validated source is 31 ahead / 0 behind with 9 changed files, all inside TNYX-200 scope.
**Current blocker:** None.
**Open review findings:** None.
**Next exact action:** Review PR #259. Merge requires explicit owner authorization.

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

- Fresh `main` remains `22ab43cb...`; no overlapping source work entered the branch.
- TNYX-67, 114, 158, 195, 196, 198 and 199 are Done.
- `MealLogRepository` exposes `createManual`, `readById`, `listByLocalDate`; update/delete remain intentionally absent.
- `ManualMealLogCreate` carries `clientMutationId`, category id, optional meal name/note/capture source, consumed instant/local date/time context, and `NutritionSnapshot`.
- Supabase adapter already pre-reconciles same mutation id and may throw `MealLogCreateOutcomeUnknown` when create outcome remains ambiguous.
- Live `public.meal_log_entries` is RLS-enabled with own-row CRUD policies/grants and `UNIQUE (user_id, client_mutation_id)`; no schema work was required.
- Nutrition already depends on `uuid` and has an injectable UUID-v4 pattern.
- Quick Add owns route-local field controllers, numeric validation, Meal Category selection/suggestion and one-shot current-local DateTime draft.
- `TioButton` owns loading/disabled/progress semantics.
- `mealDiaryHistoryProvider` is request-keyed; confirmed create uses targeted invalidation rather than a parallel cache.

### Stale docs noted, not followed

`.ai/CURRENT.md`, old DateTime-wheel handoff, `docs/DEVELOPMENT_SETUP.md`, and older backend wording in Supabase/module docs are stale against runtime/root architecture. They did not block this slice and did not authorise backend/schema work.

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
blank meal name         -> null
Calories                -> NutrientId.energy
Carbs                   -> NutrientId.carbohydrate
Protein                 -> NutrientId.protein
Fat                     -> NutrientId.fat
blank optional macro    -> absent
note                     -> null
captureSource            -> quickAdd
consumedAt               -> draft.toUtc()
consumedLocalDate        -> draft calendar date
consumedTimezoneId       -> null unless trusted source already exists
consumedUtcOffsetMinutes -> draft.timeZoneOffset.inMinutes
```

### Retry state

```text
idle
→ submitting(frozen input + mutation id)
→ success
→ known failure: preserve draft; unchanged retry reuses the same logical operation; editing starts a fresh operation
→ outcome unknown: preserve exact frozen input/id; only reconciliation retry is allowed
```

Presentation does not call Supabase directly or own repository idempotency rules.

## 5. Implementation Plan

- [x] Freshly verify main/branch/overlap and move TNYX-200 to `In Progress`.
- [x] Transfer implementation ownership in this brief before source edits.
- [x] Add create controller/state + deterministic UUID/clock seams.
- [x] Map validated Quick Add draft to canonical `NutritionSnapshot`/`ManualMealLogCreate`.
- [x] Wire canonical MealLog repository into Quick Add without adding a second persistence owner.
- [x] Activate existing `Log Meal` CTA only for valid draft; use existing loading semantics.
- [x] Preserve stable input/id through known-failure retry and ambiguous-outcome reconciliation.
- [x] On confirmed success dismiss and refresh affected Diary history without changing selected date.
- [x] Add focused controller/widget/integration regressions.
- [x] Reconcile current Quick Add docs/comments that said persistence was unavailable.
- [x] Run exact scope + Flutter/Dart validation and hand off for review.

## 6. Quality Review

### Validation run

Validated source: `0c61a3c67cbcfed504fd94123e3d9f4d72085bb5`

GitHub Actions Flutter CI #2426:

- run ID `34674939574`
- job ID `103503019617`
- Set up job: PASS
- Checkout: PASS
- Install Flutter stable: PASS
- Toolchain info: PASS
- Install Melos: PASS
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
- Post Checkout: PASS

### Review findings

One safety issue was found during implementation review and resolved before final validation: a malformed `MealLogCreateOutcomeUnknown` carrying a mismatched mutation id previously downgraded the operation to an ordinary failure and unlocked the draft. The controller now treats every ambiguous repository outcome fail-closed as the original frozen operation, so no new logical create can start until that exact payload/id is reconciled. Regression coverage verifies the lock and exact retry identity.

No open review findings remain. Fresh PR thread audit returned zero unresolved threads.

## 7. Final Handoff

- Implementation: complete for TNYX-200 create-only scope.
- Source validation: green at `0c61a3c67cbcfed504fd94123e3d9f4d72085bb5`.
- Scope: 31 ahead / 0 behind from exact `main` merge base, 9 scoped changed files.
- Review state: ready for PR review.
- Merge: not authorised by this handoff; explicit owner authorization is still required.
- Broad TNYX-115 remains open for later edit/delete/note-preservation lifecycle work.

### Final Status

`REVIEW`
