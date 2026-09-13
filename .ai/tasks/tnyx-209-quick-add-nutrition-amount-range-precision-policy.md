# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** In progress — implementation authorized  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible validation behavior  
**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13 and explicitly authorized this TNYX-209 implementation slice after TNYX-210 merged.  
**Approved product/UI/data-shape boundaries:** One shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat. Preserve current editor geometry and interaction structure.  
**Explicit non-changes:** No Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, TNYX-211 work, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Previous implementation owner:** Codex (local repository), source edits not started  
**Implementation owner:** ChatGPT — remote GitHub execution  
**Review owner:** Unassigned  
**Implementation ownership state:** Active; single implementation owner for this slice  
**Ownership transition:** Codex local handoff -> ChatGPT remote GitHub execution, owner-directed on 2026-09-13  
**Repository state verified remotely:** `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch starting `HEAD@7f893e9909332a72f8a26ef347721cf40d0aa84e`; main is exact merge base; ahead 2 / behind 0; pre-implementation diff contains only this task brief  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR / tracker:** Linear `TNYX-209` is `In Progress`; no PR existed at takeover  
**Current implementation state:** source implementation pending after remote reconstruction  
**Relevant execution surface:** `QuickAddEditorSheet` -> shared manual/coarse amount policy -> `QuickAddMealLogCreateController` / `QuickAddMealLogEditController` -> `MealLogRepository`  
**Validation remaining:** focused policy/controller/widget tests, Nutrition analyze/tests, app consumer validation, diff audit, exact-head CI  
**Current blocker:** none  
**Open review finding IDs:** `TNYX-209-A1`  
**Next exact action:** implement the locked policy on this existing branch without widening scope

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` apply. TNYX-209 may change validation messages/enabled state only; it does not authorize geometry, spacing, typography, colors, input component geometry, or any other visual redesign.

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

### Fresh Current Runtime Evidence

- `quick_add_editor_sheet.dart` parses `double` and currently rejects only parse/non-finite/negative amounts through `_nutritionError`; Calories are required while Carbs/Protein/Fat are optional.
- `_currentDraft()` disables the CTA when the presentation draft is invalid.
- `QuickAddMealLogCreateController._validateDraft()` currently accepts any finite non-negative Calories/macros.
- `QuickAddMealLogEditController._validateDraft()` duplicates the same finite/non-negative-only rule.
- Edit preserves unexposed nutrients by cloning the canonical snapshot and replacing only the four Quick Add fields.
- `NutritionSnapshot` remains provider-independent and must not be narrowed by this slice.
- TNYX-210 unchanged-time future validation remains a required regression contract.

### Existing Regression Contracts To Preserve

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

### Chosen Approach

Add one pure Nutrition-owned reusable manual/coarse nutrition amount policy under `domain/usecases`. It owns field identity/spec plus typed validation errors. Presentation maps typed errors to locked field copy. Create and edit controllers call the same numeric policy before constructing persistence inputs.

```text
Quick Add / Quick Edit numeric text
        ↓ parse
shared manual/coarse nutrition amount policy
        ├─ presentation error mapping
        └─ create/edit mutation validation
                ↓
ManualMealLogCreate / ManualMealLogUpdate
        ↓
MealLogRepository
```

### Precision Approach

Numeric validation checks whether `value * 10` is within a small floating-point tolerance of an integer. This accepts normal parsed one-decimal values without exact-binary-float fragility while still rejecting genuine extra precision. No quantization or rounding is applied before persistence.

### Alternatives Rejected

- `NutritionSnapshot` caps: too broad/provider-independent.
- widget-only rules: bypassable by direct controller call.
- generic DB snapshot caps: wrong durable ownership for this V1.
- Nutrition Target ranges: different product semantics.
- silent rounding: invisibly changes user-entered truth.

## 5. Implementation Checklist

- [x] Audit current create/edit/widget/domain boundaries.
- [x] Owner approves exact V1 min/max/precision and copy.
- [x] Verify remote branch HEAD, ancestry, task-only pre-implementation diff and Linear state.
- [x] Transfer single implementation ownership before source edits.
- [ ] Add one pure reusable manual/coarse amount policy under Nutrition ownership.
- [ ] Make `QuickAddEditorSheet` field validation use the policy while preserving geometry.
- [ ] Make both create and edit controller validation consume the same policy.
- [ ] Preserve optional `null`, explicit zero, hidden nutrients and frozen retry semantics.
- [ ] Add pure policy boundary/precision tests including floating-point edge behavior.
- [ ] Add create/edit controller bypass tests for upper bound + precision and zero/null semantics.
- [ ] Add widget tests for max/precision copy, disabled CTA, valid boundary and blank macro.
- [ ] Add legacy/out-of-policy Quick Edit regression requiring correction before save.
- [ ] Confirm no `NutritionSnapshot`, provider/detailed editor, Nutrition Targets, TNYX-211, Core or Supabase/schema changes.
- [ ] Run/collect Nutrition/App validation, diff audit, Draft PR and exact-head CI.

## 6. Quality Review

### Validation Run

```text
Implementation validation not run yet.
Remote API preflight passed:
- branch start HEAD = 7f893e9909332a72f8a26ef347721cf40d0aa84e
- main = 91b4eca3e3afae11c6f992179ce0555532f8c75c
- merge base = main
- ahead 2 / behind 0
- pre-implementation changed files = this task brief only
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Open | Quick Add/Quick Edit accept any finite non-negative amount; no shared upper-bound or precision policy exists. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Implement locked TNYX-209 policy |

## 7. Final Handoff

Pending implementation, validation, Draft PR, exact-head CI and review reconciliation.

### Final Status

`IN PROGRESS`
