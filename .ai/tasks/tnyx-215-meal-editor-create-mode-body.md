# TNYX-215 — Meal Editor create-mode body foundation

**Status:** In progress
**Primary owner:** Nutrition feature
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner said `next go` on 2026-09-16 after the fresh TNYX-207/TNYX-58/runtime readiness audit.
**Approved product/UI/data-shape boundaries:** Build only the create-mode Meal Editor body above the existing `MealLogActionFooter`, driven by `MealLoggingDraft`, using the owner-provided visual references as direction and Tio design-system contracts as implementation truth.
**Explicit non-changes:** No Add Food text activation, processing state, parser/provider/API/Edge Function, Supabase shape/RLS/migration, detailed durable MealLog persistence, Add more destination, voice/photo/search/saved/recent/barcode, ingredient-detail editor, existing-log edit mode, or duplicate footer.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned until implementation checkpoint
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main` at `5685394e8857b2e60bb25fab91b412b14d39f460` after PR #268 merge; no open PR overlap found.
**Branch:** `tnyx/tnyx-215-n5d-2-meal-editor-create-mode-body-foundation`
**HEAD SHA:** `5685394e8857b2e60bb25fab91b412b14d39f460` before this brief commit
**Observed working-tree state:** Connector-only session; local `git status` unavailable. GitHub branch was created directly from verified `main` SHA.
**Observed uncommitted/dirty files:** Not observable through connector-only execution; no repository writes existed on this new branch before this brief.
**PR / tracker:** Linear TNYX-215, parent TNYX-207; related TNYX-58 and TNYX-113; GitHub issue #269 tracks the broader N5D handoff.
**Current implementation state:** Ready to implement one bounded UI/controller slice.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_logging/**`, `apps/shared/lib/src/nutrition/meal_logging_draft*.dart`, existing `MealLogActionFooter` and `TioEditorSheet`.
**Validation completed at SHA:** Not run yet.
**Validation remaining:** Focused controller/widget tests, Flutter analyze/tests through CI, scope review.
**Current blocker:** None for the bounded body foundation. Detailed durable persistence remains intentionally out of scope and must be audited next.
**Open review finding IDs:** None.
**Next exact action:** Add in-memory create controller, Meal Editor body/sheet composition, exports and focused tests without wiring Add Food or persistence.

## Global UI / Design-System Guardrail

Read and reconciled before implementation:

- root `AGENTS.md`;
- `apps/features/AGENTS.md`;
- `apps/core/lib/src/theme/README.md`;
- `.ai/tasks/design-system-token-consolidation.md`;
- `.ai/workflow.md` and `.ai/FEATURE_DEVELOPMENT.md`.

The slice will prefer existing `TioEditorSheet`, `TioInput`, `TioCard`, `TioButton`/shared control patterns and runtime `context.tioColors` rather than creating feature-local design tokens.

## 1. Discovery

### User Outcome

A parsed `MealLoggingDraft` can be opened in a Tio-owned create-mode Meal Editor that lets the user review and locally correct meal name/items while seeing live calories/macros before any durable write exists.

### Success Criteria

- body renders from `MealLoggingDraft`;
- meal name is editable;
- calories/protein/carbs/fat totals derive from item consumed snapshots and preserve unknown-vs-zero semantics;
- valid quantity increments/decrements keep same-unit nutrition consistent by proportional rescaling;
- unknown quantity is never fabricated;
- delete updates local draft and cannot produce a valid empty meal;
- existing `MealLogActionFooter` is the fixed action area;
- CTA is non-durable/inert in this slice;
- no parser/network/schema/persistence widening.

### Scope

One Nutrition-owned create-mode controller + one editor surface/body composition + focused tests + exports.

### Non-Goals

All parser, processing, provider, persistence, search/add-more, photo/voice, ingredient-detail and existing-log edit flows.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `MealLoggingDraft`, `MealLoggingDraftItem`, `NutritionSnapshot`, `MealLogEntry`, `MealLogRepository`, `AddFoodSheet`, `QuickAddEditorSheet`, `MealLogActionFooter`, `TioEditorSheet`, current meal-logging barrels.
- Existing pattern to follow: `QuickAddEditorSheet` uses `TioEditorSheet` with scrollable content and fixed `MealLogActionFooter`; feature logic stays outside reusable Core UI.
- Tests or validation already present: existing Nutrition meal-logging widget/controller tests and workspace Flutter CI; PR #268 exact-head CI was green before merge.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse `MealLogActionFooter` | Locked | Existing widget was explicitly built for Quick Add + full Meal Editor reuse. | Owner/TNYX-207 |
| Keep CTA non-durable in this slice | Locked | Current canonical runtime exposes only manual durable MealLog create. | Audit |
| Same-unit quantity change proportionally rescales known consumed snapshot | Locked for this slice | `consumedNutritionSnapshot` is total for current quantity; ratio scaling preserves that invariant without provider coupling. | Architecture |
| Unknown quantity gets no fabricated default/stepper | Locked | Draft contract preserves incomplete parse truth. | Shared-domain contract |
| Unit is displayed but not freely converted in this slice | Locked | Draft has only a provider-neutral label and no conversion/serving-option basis; inventing conversion would violate truth semantics. | Architecture |
| Meal nutrient total is unknown when any retained item lacks that nutrient | Locked | Summing only known items would understate the meal and fabricate completeness. | Architecture |

## 4. Architecture Design

### Chosen Approach

Add `MealEditorCreateController` as presentation/workflow state owner. It copies the approved `MealLoggingDraft` into immutable local state, derives meal totals on demand, handles meal-name edits, bounded same-unit quantity stepping, and item removal. The Flutter sheet renders that state and emits actions only.

### Ownership and Data Flow

```text
MealLoggingDraft (shared, discardable)
        ↓
MealEditorCreateController (Nutrition workflow state)
        ↓
MealEditorCreateSheet / body (Nutrition UI)
        ↓
existing MealLogActionFooter (fixed, non-durable CTA in this slice)
```

### Alternative Rejected

- Mutating `MealLoggingDraft` in widgets: rejected because business invariants would leak into `build()`/callbacks.
- Adding provider serving/base nutrition fields now: rejected because TNYX-215 is provider-neutral UI foundation only.
- Clearing known nutrition on every same-unit quantity step: safe but unnecessarily degrades editable draft quality when proportional rescaling is deterministic.
- Creating a new footer/Core component: rejected because reusable footer/editor primitives already exist.

### Failure and Accessibility States

- Unknown nutrient shows `—`, never `0` unless explicit zero is known.
- Unknown quantity renders as unknown and no +/- controls are enabled.
- Decrement stops before non-positive quantity.
- Only item cannot be deleted into an empty valid draft; UI explains/disabled semantics.
- Long item lists rely on `TioEditorSheet` scroll region and fixed actions.
- Controls use semantic labels/tooltips and compact-width wrapping rather than fixed row overflow assumptions.

## 5. Implementation Plan

- [ ] Add `MealEditorCreateController` + derived summary state.
- [ ] Add create-mode Meal Editor sheet/body using existing Core components and `MealLogActionFooter`.
- [ ] Export the new controller/widget from existing meal-logging barrels.
- [ ] Add focused controller tests for unknown semantics, proportional quantity scaling, deletion and meal-name changes.
- [ ] Add focused widget tests for body, footer reuse, unknown states, quantity/delete interaction and compact width.
- [ ] Run exact-head CI and perform final scope/review audit.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Detailed persistence and parser activation remain intentionally deferred.

### Final Status

`REVIEW`
