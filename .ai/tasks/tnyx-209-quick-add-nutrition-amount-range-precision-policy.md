# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** Needs decision
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible validation behavior
**Approval status:** `AWAITING OWNER APPROVAL`
**Approval evidence:** Owner explicitly authorized starting the next TNYX-209 audit after TNYX-204 merged/synced. Exact V1 bounds/precision and validation copy still require owner lock before source changes.
**Approved product/UI/data-shape boundaries:** Audit and freeze one manual/coarse Quick Add + Quick Edit amount policy for Calories, Carbs, Protein and Fat; reuse one policy across create/edit; preserve current editor geometry and interaction structure.
**Explicit non-changes:** No Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit
**Implementation owner:** Not assigned
**Review owner:** Not assigned
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** remote branch created from merged `main` at `0380bc9be82155932562b67674fc913fb9b60de2`; owner-provided post-merge evidence showed local `main...origin/main` clean/synced before this branch was created
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`
**HEAD SHA:** `0380bc9be82155932562b67674fc913fb9b60de2` before this task-brief commit
**Observed working-tree state:** local TNYX-209 checkout not yet verified
**Observed uncommitted/dirty files:** none reported before branch creation; must re-check locally before implementation
**PR / tracker:** Linear `TNYX-209` Backlog at audit start; no PR yet
**Current implementation state:** read-only audit complete; no production source changes
**Relevant execution surface:** `QuickAddEditorSheet` -> `QuickAddMealLogCreateController` / `QuickAddMealLogEditController` -> `MealLogRepository` -> `NutritionSnapshot` / Supabase adapter
**Validation completed at SHA:** none for TNYX-209; audit only
**Validation remaining:** focused policy tests, Quick Add/Quick Edit widget/controller suites, full Nutrition analyze/tests, app consumer checks if touched, `git diff --check`, exact-head CI
**Current blocker:** owner decision on exact V1 bounds/precision and visible validation wording
**Open review finding IDs:** none
**Next exact action:** owner locks the V1 policy below; then assign one Implementation owner, verify local branch/clean tree, and implement without widening scope

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, and `apps/core/lib/src/theme/README.md` were read before this planning pass. TNYX-209 may change validation messages/enabled state only; it does not authorize geometry, spacing, typography, colors, input component geometry, or any other visual redesign.

## 1. Discovery

### User Outcome

A user cannot accidentally save absurdly large or over-precise manual nutrition values in Quick Add or Quick Edit, while legitimate zero values and missing optional nutrients retain their current meaning.

### Success Criteria

- One canonical manual/coarse amount policy is consumed by both create and edit paths.
- UI and controller/mutation validation agree.
- Invalid/non-finite/negative behavior remains blocked.
- Upper bounds prevent catastrophic typos from becoming durable meal truth.
- Precision is explicit and tested instead of accepting arbitrary decimal tails.
- `missing != zero`; optional missing macros stay missing.
- Existing out-of-policy rows may still be read, but Quick Edit cannot re-save them unchanged as new valid input; the user must correct out-of-policy fields before Save Changes.

### Scope

- Calories, Carbs, Protein, Fat in manual/coarse Quick Add + Quick Edit.
- Shared policy owned by Nutrition feature/domain layer, not by widget-only validation.
- Field-specific presentation errors using the existing editor surface.
- Focused boundary/precision tests in widget + controller layers.

### Non-Goals

- Clinical recommendations or target guidance.
- Macro/calorie coherence enforcement for consumed manual meals.
- Changing canonical Nutrition Target limits.
- Changing detailed/provider item normalization rules.
- Generic `NutritionSnapshot` max limits.
- DB snapshot max/precision constraint in V1.
- Quantity/serving units, fiber, micronutrients, or Meal Editor implementation.

## 2. Codebase Exploration

### Verified Evidence

- `quick_add_editor_sheet.dart` currently parses `double`, rejects only non-numeric/non-finite/negative values, requires Calories, leaves Carbs/Protein/Fat optional, and uses the same `_nutritionError` helper for visible field state.
- `QuickAddMealLogCreateController` independently rejects only non-finite/negative amounts before building `ManualMealLogCreate`.
- `QuickAddMealLogEditController` duplicates the same non-finite/non-negative validation before building `ManualMealLogUpdate`.
- `NutritionSnapshot` is intentionally provider-independent: known amounts must only be finite + non-negative; absent means unknown, present zero means known zero. It has no product-specific upper/precision bound.
- `NutritionTargetEditor` has `maxStorableCalories = 2147483647`, explicitly documented as a Postgres storage limit, not a health/product range. Macro slider maxima are explicitly UX ranges, not persistence limits. These must not be reused as Quick Add policy.
- Nutrition Target exact-entry display already normalizes visible non-integer values to one decimal; this is useful consistency evidence but is not itself authority for MealLog policy.
- Future detailed Meal Editor truth is item/source-derived and may include provider-normalized/manual-corrected values; generic/provider snapshots must not inherit Quick Add-specific caps.
- `private.is_valid_nutrition_snapshot_v1(jsonb)` in the current migration validates known nutrient JSON values as numeric + non-negative only. Applying Quick Add caps there would narrow all manual snapshots and future capture sources, so DB hardening is not justified in this V1 slice.
- `SupabaseMealLogRepository` serializes the canonical snapshot directly for create/update; there is no second amount range policy below the controllers.
- TNYX-115 explicitly deferred common numeric range/precision to this P1 follow-up; TNYX-209 blocks TNYX-205 so Daily Summary does not immediately consume newly created absurd manual values.

### Existing pattern to follow

Pure feature-owned domain/use-case policy -> presentation maps validation result to field copy -> create/edit controllers call the same policy before building persistence inputs.

### Tests or validation already present

Current Quick Add tests cover invalid/non-finite/negative values and create/edit persistence semantics. TNYX-209 must extend them with exact min/max/precision boundary cases rather than replacing those checks.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep `0` valid for Calories and macros | Proposed | `NutritionSnapshot` explicitly distinguishes known zero from missing; zero-calorie actual intake can be real, and rejecting it would invent a new semantic rule. | Owner |
| Calories max = `10000 kcal` per Quick Add/Quick Edit meal | Proposed | Product-sanity cap for one actual meal, intentionally far above normal use yet small enough to stop catastrophic typos from dominating Diary/Summary. Not a clinical recommendation. | Owner |
| Carbs/Protein/Fat max = `1000 g` each per meal | Proposed | Same product-sanity goal; deliberately generous and Quick Add-specific, not a universal nutrient invariant. | Owner |
| Precision = at most `1 decimal place` for all four fields | Proposed | Matches current manual-style display conventions, keeps coarse input coarse, and prevents meaningless long floating tails. | Owner |
| Precision violations are rejected, not silently rounded | Proposed | User-entered actual truth should not be changed invisibly. | Owner |
| Missing optional macro remains `null`; explicit `0` remains stored zero | Locked by existing contract | Existing canonical `NutritionSnapshot` semantics. | Existing contract |
| Existing out-of-policy MealLog can be read but must be corrected before a Quick Edit save | Proposed | Avoids destructive migration while preventing the edit path from re-committing invalid manual truth. | Owner |
| No DB migration/constraint in V1 | Proposed | Current DB validator is generic for manual snapshots/capture sources; a Quick Add-specific cap does not belong there without a narrower durable discriminator/contract. | Owner |

### Proposed visible validation copy

- Parse/non-finite: existing `Enter a number.`
- Negative: existing `<Field> cannot be negative.`
- Above maximum: `<Field> must be {max} or less.`
- Too precise: `Use at most 1 decimal place.`

No layout redesign; errors stay in the current field-error area and CTA disabling follows the same current mechanism.

## 4. Architecture Design

### Chosen Approach

Add one pure Nutrition-owned `ManualMealNutritionAmountPolicy` (final name may follow nearby naming conventions) with field identity/spec + reusable validation result. The widget and both controllers call the same policy; controllers remain the bypass-resistant mutation gate for Quick Add/Quick Edit.

### Ownership and Data Flow

```text
Quick Add / Quick Edit numeric text
        ↓ parse
ManualMealNutritionAmountPolicy
        ├─ visible field error mapping
        └─ controller submit validation
                ↓
QuickAdd create/edit controller
        ↓
ManualMealLogCreate / ManualMealLogUpdate
        ↓
MealLogRepository
        ↓
NutritionSnapshot / Supabase adapter
```

### Alternatives Rejected

- **Put maxima in `NutritionSnapshot`:** rejected; it is provider-independent and shared beyond Quick Add.
- **Put policy only in `_nutritionError`:** rejected; direct controller calls would bypass UI validation.
- **Add generic DB snapshot caps now:** rejected; validator currently owns generic snapshot validity across capture sources, not Quick Add product policy.
- **Reuse Nutrition Target storage/slider ranges:** rejected; those are documented storage/UX mechanics, not consumed-meal limits.
- **Silently round excess decimals:** rejected; changes user-entered actual truth without explicit intent.

### Failure and Accessibility States

- Existing inline error semantics remain the presentation mechanism.
- CTA remains disabled for known invalid drafts.
- Direct controller submit returns the existing invalid-meal failure state; no repository call occurs.
- Ambiguous create/update retry behavior must remain unchanged and must continue using the exact frozen already-valid input.
- Existing conflict handling remains unchanged.

## 5. Implementation Plan

- [ ] Owner approves/adjusts exact min/max/precision table and visible copy.
- [ ] Verify local TNYX-209 branch and clean working tree before source edits.
- [ ] Add one pure reusable manual/coarse amount policy under Nutrition ownership.
- [ ] Replace widget-only amount rules with policy-backed field validation while preserving current UI geometry.
- [ ] Make both create and edit controller validation consume the same policy.
- [ ] Preserve `null` optional macros and explicit zero semantics.
- [ ] Add min/max/max+epsilon/precision/non-finite/negative tests for policy + create + edit.
- [ ] Add widget tests for field-specific max/precision errors and disabled Log Meal/Save Changes.
- [ ] Add regression for legacy/out-of-policy edit row requiring correction before save.
- [ ] Confirm no `NutritionSnapshot`, provider/detailed editor, Nutrition Targets, or Supabase schema changes.
- [ ] Run Nutrition analyze/tests, app consumer validation if necessary, `git diff --check`, then exact-head CI.

## 6. Quality Review

### Validation Run

```text
Not run yet. Planning/audit only; no production source changed.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Open | Quick Add/Quick Edit accept any finite non-negative amount; no shared upper-bound or precision policy exists. | `0380bc9be82155932562b67674fc913fb9b60de2` | TNYX-209 implementation after owner policy lock |

## 7. Final Handoff

### Changed Files

Planning branch only: this task brief.

### Actual Behavior

No runtime behavior changed in this audit pass.

### Known Limitations

Exact V1 numeric bounds/precision are proposed, not approved. No implementation should begin until the owner locks or adjusts them.

### Final Status

`BLOCKED` — awaiting owner policy approval before source implementation.
