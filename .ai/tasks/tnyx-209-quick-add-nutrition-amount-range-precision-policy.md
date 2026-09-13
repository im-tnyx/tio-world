# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** Implementation authorized — branch reconciled, source work pending  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible validation behavior  
**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13 and then explicitly said `next go` after TNYX-210 merged and local `main` was fast-forwarded/verified clean.  
**Approved product/UI/data-shape boundaries:** One shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat. Preserve current editor geometry and interaction structure.  
**Explicit non-changes:** No Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Implementation owner:** Codex (local repository)  
**Review owner:** Unassigned  
**Implementation ownership state:** Authorized; source edits not started in this reconciliation pass  
**Ownership transition:** Planning -> Codex implementation after local branch checkout/state verification  
**Repository state last verified:** owner-provided local evidence on 2026-09-13 showed `main == origin/main == 91b4eca3e3afae11c6f992179ce0555532f8c75c` and `git status -sb` = `## main...origin/main`; remote GitHub `main` independently matches that SHA  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**Branch history note:** original planning commit `b17ad7a72df35094d23c572f046dd62ec1a7408d` was based on pre-TNYX-210 `main@0380bc9b`; branch is being reconciled non-destructively with current `main@91b4eca3` before implementation  
**Observed working-tree state:** local `main` clean/synced; local TNYX-209 branch checkout must still be verified with `git status --short --branch` before source edits  
**Observed uncommitted/dirty files:** none on local `main` per owner evidence  
**PR / tracker:** Linear `TNYX-209`; no PR yet  
**Current implementation state:** audit complete, V1 policy locked, source implementation pending  
**Relevant execution surface:** `QuickAddEditorSheet` -> shared manual/coarse amount policy -> `QuickAddMealLogCreateController` / `QuickAddMealLogEditController` -> `MealLogRepository`  
**Validation completed:** planning/source audit only; TNYX-210 is merged/synced and no longer blocks this slice  
**Validation remaining:** focused policy/controller/widget tests, full Nutrition analyze/tests, app consumer validation, `git diff --check`, exact-head CI  
**Current blocker:** none; local branch cleanliness must be verified as the normal pre-edit gate  
**Open review finding IDs:** `TNYX-209-A1`  
**Next exact action:** local Codex checks out this branch, verifies clean state/current ancestry, then implements the locked policy without widening scope

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` were re-read against current `main@91b4eca3` before this handoff. TNYX-209 may change validation messages/enabled state only; it does not authorize geometry, spacing, typography, colors, input component geometry, or any other visual redesign.

## 1. Discovery

### User Outcome

A user cannot save absurdly large or over-precise manual nutrition values in Quick Add or Quick Edit, while legitimate zero values and missing optional nutrients retain their current meaning.

### Success Criteria

- One canonical manual/coarse amount policy is consumed by both create and edit paths.
- UI and controller/mutation validation agree.
- Invalid/non-finite/negative behavior remains blocked.
- Upper bounds prevent catastrophic typos from becoming durable meal truth.
- Precision is explicit and tested instead of accepting arbitrary decimal tails.
- `missing != zero`; optional missing macros stay missing.
- Existing out-of-policy rows remain readable but Quick Edit requires correction before a new save.

### Scope

- Calories, Carbs, Protein, Fat in manual/coarse Quick Add + Quick Edit.
- Shared policy owned by Nutrition feature/domain/use-case layer, not widget-only validation.
- Field-specific presentation errors in the existing editor surface.
- Focused boundary/precision tests in policy + widget + create/edit controller layers.

### Non-Goals

- Clinical recommendations or target guidance.
- Macro/calorie coherence enforcement.
- Nutrition Target limit changes.
- Detailed/provider item normalization changes.
- Generic `NutritionSnapshot` upper/precision limits.
- DB snapshot max/precision constraint in V1.
- Quantity/serving units, fiber, micronutrients, Meal Editor or AI parsing.
- TNYX-211 card text-scale layout work.

## 2. Codebase Exploration

### Fresh Current-Main Evidence

- `quick_add_editor_sheet.dart` on `main@91b4eca3` still parses `double`, rejects only parse/non-finite/negative amounts through `_nutritionError`, requires Calories and leaves Carbs/Protein/Fat optional.
- `_currentDraft()` uses that widget helper as its only field-level amount validation and disables the CTA when the draft is invalid.
- `QuickAddMealLogCreateController._validateDraft()` still accepts any finite non-negative Calories/macros before building `ManualMealLogCreate`.
- `QuickAddMealLogEditController._validateDraft()` still duplicates the same finite/non-negative-only rule. TNYX-210 changed future-time validation but did not change nutrition amount policy.
- `QuickAddMealLogEditController` preserves unexposed nutrients by cloning the canonical snapshot and replacing only the four Quick Add fields; this behavior must remain intact.
- `NutritionSnapshot` remains provider-independent: known amounts are finite + non-negative; absent means unknown and present zero means known zero. Do not narrow it for this Quick Add-specific policy.
- The current DB snapshot validator remains generic; V1 has no approved Supabase/schema/RLS change.
- TNYX-210 is Done/merged/synced. TNYX-211 is a separate non-blocking accessibility follow-up and must not widen this slice.

### Existing Pattern To Follow

Pure feature-owned policy -> presentation maps policy result to field copy -> create/edit controllers call the same policy before constructing persistence inputs.

### Existing Regression Contracts To Preserve

- create idempotency / exact frozen ambiguous retry;
- edit expectedRevision, conflict reload and ambiguous retry;
- missing optional macro remains `null`;
- explicit zero remains zero;
- hidden/unexposed snapshot nutrients survive edit;
- TNYX-210 unchanged-time future validation fix remains intact;
- current Quick Add geometry and accessibility semantics remain unchanged.

## 3. Clarification — Owner-Locked V1 Policy

```text
Calories   min 0   max 10,000 kcal   precision <= 1 decimal
Carbs      min 0   max 1,000 g       precision <= 1 decimal
Protein    min 0   max 1,000 g       precision <= 1 decimal
Fat        min 0   max 1,000 g       precision <= 1 decimal
```

Locked behavior:

- explicit `0` is valid known zero;
- blank optional macros remain `null` / missing;
- excess precision is rejected, never silently rounded;
- existing out-of-policy rows remain readable but must be corrected before Quick Edit can save;
- above-max copy: `<Field> must be {max} or less.`;
- precision copy: `Use at most 1 decimal place.`;
- existing parse/non-finite copy remains `Enter a number.`;
- existing negative copy remains `<Field> cannot be negative.`;
- no DB/schema/RLS change in V1.

## 4. Architecture Design

### Chosen Approach

Add one pure Nutrition-owned reusable manual/coarse nutrition amount policy. Exact file/class naming should follow nearby code conventions, but there must be one authority for field identity/spec and validation. Presentation and both mutation controllers consume it.

```text
Quick Add / Quick Edit numeric text
        ↓ parse
Manual/coarse nutrition amount policy
        ├─ presentation error mapping
        └─ controller submit validation
                ↓
QuickAdd create/edit controller
        ↓
ManualMealLogCreate / ManualMealLogUpdate
        ↓
MealLogRepository
```

### Alternatives Rejected

- `NutritionSnapshot` caps: too broad/provider-independent.
- widget-only rules: bypassable by direct controller call.
- generic DB snapshot caps: wrong durable ownership for a Quick Add-specific V1 policy.
- Nutrition Target ranges: storage/UX mechanics, not consumed-meal limits.
- silent rounding: changes user-entered actual truth invisibly.

## 5. Implementation Plan

- [x] Audit current create/edit/widget/domain/DB boundaries.
- [x] Owner approves exact V1 min/max/precision and copy.
- [x] Reconcile TNYX-210 merge/local-sync state and current `main` before source work.
- [ ] Verify local TNYX-209 branch + clean working tree.
- [ ] Add one pure reusable manual/coarse amount policy under Nutrition ownership.
- [ ] Make `QuickAddEditorSheet` field validation use the policy while preserving geometry.
- [ ] Make both create and edit controller validation consume the same policy.
- [ ] Preserve optional `null`, explicit zero, hidden nutrients and frozen retry semantics.
- [ ] Add policy tests: min, max, max+epsilon, one decimal accepted, excess precision rejected, negative/non-finite rejected.
- [ ] Add create/edit controller bypass tests for all policy boundaries.
- [ ] Add widget tests for field-specific max/precision errors and disabled `Log Meal` / `Save Changes`.
- [ ] Add legacy/out-of-policy Quick Edit regression requiring correction before save.
- [ ] Confirm no `NutritionSnapshot`, provider/detailed editor, Nutrition Targets, TNYX-211, Core or Supabase/schema changes.
- [ ] Run Nutrition/App validation, `git diff --check`, push Draft PR, exact-head CI, then quality review.

## 6. Quality Review

### Validation Run

```text
Not run yet for implementation. Planning/audit only.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Open | Quick Add/Quick Edit still accept any finite non-negative amount; no shared upper-bound or precision policy exists. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Implement locked TNYX-209 policy |

## 7. Final Handoff

### Changed Files In This Reconciliation Pass

- `.ai/tasks/tnyx-209-quick-add-nutrition-amount-range-precision-policy.md` only.

### Actual Behavior

No runtime behavior changed in this reconciliation pass.

### Known Limitations

- TNYX-211 tracks the separate Meal Diary card text-scale overflow and remains outside this slice.
- Exact implementation validation has not run yet.

### Final Status

`READY FOR IMPLEMENTATION` — owner policy is locked, TNYX-210 is merged/synced, and the next implementation action belongs to the single assigned local Codex owner after branch-state verification.
