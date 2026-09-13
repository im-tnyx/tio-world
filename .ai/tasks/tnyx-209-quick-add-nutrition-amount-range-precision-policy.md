# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** Validated  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible validation behavior  
**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13 and explicitly authorized implementation after TNYX-210 merged.  
**Approved product/UI/data-shape boundaries:** One shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat while preserving current editor geometry and interaction structure.  
**Explicit non-changes:** No Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, TNYX-211 work, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Previous implementation owner:** Codex (local repository), source edits not started  
**Implementation owner:** ChatGPT — remote GitHub execution  
**Review owner:** Unassigned  
**Implementation ownership state:** Handoff pending — source implementation is validated and no further source edits are planned before review  
**Ownership transition:** Codex local handoff -> ChatGPT remote GitHub execution, owner-directed on 2026-09-13  
**Repository anchors:** `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch started at `7f893e9909332a72f8a26ef347721cf40d0aa84e`; validated source head `1b1dd59222442333b6b6d984851c10cf874ce195`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** Draft PR #265 — `fix(nutrition): enforce Quick Add amount range and precision policy`  
**Tracker:** Linear `TNYX-209`; move to `In Review` after this final reconciliation  
**Current implementation state:** Complete within the approved TNYX-209 scope  
**Relevant execution surface:** `QuickAddEditorSheet` -> `ManualNutritionAmountPolicy` -> `QuickAddMealLogCreateController` / `QuickAddMealLogEditController` -> `MealLogRepository`  
**Validation completed:** exact-source-head GitHub Actions run `34746471295` / check `Analyze and test` succeeded on `1b1dd59222442333b6b6d984851c10cf874ce195`; final scope audit remains limited to 9 expected files  
**Current blocker:** none  
**Open review finding IDs:** none  
**Next exact action:** external review of Draft PR #265; do not merge without explicit owner instruction

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` apply. TNYX-209 changes validation messages/enabled state only; it does not authorize geometry, spacing, typography, colors, input component geometry, or visual redesign.

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

- Calories, Carbs, Protein and Fat in manual/coarse Quick Add + Quick Edit.
- Shared policy owned by Nutrition feature/domain use-case layer, not widget-only validation.
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

### Baseline Gap

Before implementation, Quick Add presentation and both mutation controllers accepted any finite non-negative Calories/macros. The generic `NutritionSnapshot` and DB snapshot validator intentionally had no product-specific manual/coarse maximum or precision policy.

### Regression Contracts Preserved

- create idempotency / exact frozen ambiguous retry;
- edit expectedRevision, conflict reload and ambiguous retry;
- missing optional macro remains `null`;
- explicit zero remains zero;
- hidden/unexposed snapshot nutrients survive edit;
- unchanged historical meal time is not re-rejected against current device clock;
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
- parse/non-finite copy: `Enter a number.`;
- negative copy: `<Field> cannot be negative.`;
- no DB/schema/RLS change in V1.

## 4. Architecture Design

One pure Nutrition-owned reusable manual/coarse amount policy lives under `domain/usecases`. It owns field identity/spec plus typed validation errors. Presentation maps typed errors to the locked copy. Create and edit controllers call the same numeric policy before persistence inputs are constructed.

```text
Quick Add / Quick Edit numeric text
        ↓ parse
ManualNutritionAmountPolicy
        ├─ presentation error mapping
        └─ create/edit mutation validation
                ↓
ManualMealLogCreate / ManualMealLogUpdate
        ↓
MealLogRepository
```

Precision validation checks whether `value * 10` is within a small floating-point tolerance of an integer. No quantization or silent rounding is applied before persistence.

Rejected alternatives remain: generic `NutritionSnapshot` caps, widget-only enforcement, generic DB snapshot caps, Nutrition Target ranges, and silent rounding.

## 5. Implementation Checklist

- [x] Audit current create/edit/widget/domain boundaries.
- [x] Owner approves exact V1 min/max/precision and copy.
- [x] Verify remote branch HEAD, ancestry, task-only pre-implementation diff and Linear state.
- [x] Transfer single implementation ownership before source edits.
- [x] Add one pure reusable manual/coarse amount policy under Nutrition ownership.
- [x] Make `QuickAddEditorSheet` field validation use the policy while preserving geometry.
- [x] Make both create and edit controller validation consume the same policy.
- [x] Preserve optional `null`, explicit zero, hidden nutrients and frozen retry semantics.
- [x] Add pure policy boundary/precision tests including floating-point edge behavior.
- [x] Add create/edit controller bypass tests for upper bound + precision and zero/null semantics.
- [x] Add widget tests for max/precision copy, disabled CTA, valid boundary and blank macro.
- [x] Add legacy/out-of-policy Quick Edit regression requiring correction before save.
- [x] Confirm no `NutritionSnapshot`, provider/detailed editor, Nutrition Targets, TNYX-211, Core or Supabase/schema changes.
- [x] Collect exact-source-head CI and final 9-file scope audit.

## 6. Quality Review

### Validation Run

```text
Remote preflight:
- branch start HEAD = 7f893e9909332a72f8a26ef347721cf40d0aa84e
- main = 91b4eca3e3afae11c6f992179ce0555532f8c75c
- merge base = main
- pre-implementation diff = task brief only

Implementation source validation:
- first CI run found one prefer_const_declarations lint in the new test
- lint fixed without production behavior change
- exact source SHA = 1b1dd59222442333b6b6d984851c10cf874ce195
- GitHub Actions run = 34746471295
- check = Analyze and test
- conclusion = success
- annotations = 0

Final scope audit before handoff:
- PR #265 remains open, draft and mergeable
- 9 changed files total
- changed paths are only this task brief and apps/features/nutrition/**
- no PR discussion comments
- no inline review threads
- no Core, Supabase/schema/RLS, lockfile/generated, Nutrition Targets or TNYX-211 changes
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence / resolution |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit accepted any finite non-negative amount; no shared upper-bound or precision policy existed. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Shared policy + widget/create/edit enforcement and focused tests; exact-source-head CI green at `1b1dd59222442333b6b6d984851c10cf874ce195` |

## 7. Final Handoff

TNYX-209 implementation is complete and validated within the approved scope. The Draft PR is ready for review. This handoff does not authorize merge.

Sequencing remains:

```text
TNYX-209 review / merge
→ post-merge sync per docs/POST_MERGE_SYNC.md
→ only then begin TNYX-205 when owner sequencing permits
```

### Final Status

`TNYX-209 READY FOR REVIEW`
