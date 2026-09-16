# TNYX-215 — Meal Editor create-mode body foundation

**Status:** Validated
**Primary owner:** Nutrition feature
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner said `next go` on 2026-09-16 after the fresh TNYX-207/TNYX-58/runtime readiness audit.
**Approved product/UI/data-shape boundaries:** Build only the create-mode Meal Editor body above the existing `MealLogActionFooter`, driven by `MealLoggingDraft`, using the owner-provided visual references as direction and Tio design-system contracts as implementation truth.
**Explicit non-changes:** No Add Food text activation, processing state, parser/provider/API/Edge Function, Supabase shape/RLS/migration, detailed durable MealLog persistence, Add more destination, voice/photo/search/saved/recent/barcode, ingredient-detail editor, existing-log edit-mode persistence, or duplicate footer.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main` base `5685394e8857b2e60bb25fab91b412b14d39f460`; branch remains directly ahead with only the bounded TNYX-215 paths.
**Branch:** `tnyx/tnyx-215-n5d-2-meal-editor-create-mode-body-foundation`
**Validated source/test HEAD SHA:** `ae7eec2b79c806a085c4163212105770f9623365`
**Observed working-tree state:** Connector-only session; local `git status` unavailable. API-equivalent branch/diff evidence is used instead.
**Observed uncommitted/dirty files:** Not observable through connector-only execution; all repository writes are committed directly to this branch.
**PR / tracker:** GitHub PR #270; Linear TNYX-215, parent TNYX-207; related TNYX-58 and TNYX-113; GitHub issue #269 tracks the broader N5D handoff.
**Current implementation state:** Bounded Meal Editor create-mode body/controller/exports/tests implemented and source/test head validated.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_logging/**`, canonical `MealLoggingDraft`, existing `MealLogActionFooter`, Tio Core inputs/cards/theme contracts.
**Validation completed at SHA:** `ae7eec2b79c806a085c4163212105770f9623365` via Flutter CI #2597 / run `35130356043` — bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed.
**Validation remaining:** Verify exact-head CI after this handoff-only task-brief reconciliation commit, then move PR/tracker to review state.
**Current blocker:** None for TNYX-215. Detailed durable persistence remains intentionally out of scope and is the next readiness audit after merge.
**Open review finding IDs:** None.
**Next exact action:** Verify final metadata-head CI, perform final scope/thread audit, mark PR #270 ready for review and reconcile TNYX-215 to `In Review`.

## Global UI / Design-System Guardrail

Read and reconciled before implementation:

- root `AGENTS.md`;
- `apps/features/AGENTS.md`;
- `apps/core/lib/src/theme/README.md`;
- `.ai/tasks/design-system-token-consolidation.md`;
- `.ai/workflow.md` and `.ai/FEATURE_DEVELOPMENT.md`.

The slice reuses existing `TioInput`, `TioCard`, `MealLogActionFooter`, runtime `context.tioColors`, governed typography/spacing, and the established Nutrition full-screen `Scaffold`/`AppBar` pattern. It does not create feature-local design tokens or a duplicate editor/footer component.

## 1. Discovery

### User Outcome

A `MealLoggingDraft` can open in the Tio detailed Meal Editor create mode so the user can review and locally correct meal name/items while seeing live calories/macros before any durable write exists.

### Canonical Shared-Editor Product Rule

Verified against current Linear TNYX-58 and owner clarification on 2026-09-16:

```text
Detailed create sources (text/AI/photo/search/saved/recent/barcode as they are implemented)
→ MealLoggingDraft
→ shared detailed Meal Editor
→ review/edit
→ Log Meal

Existing detailed/source-based MealLogEntry
→ same detailed Meal Editor product surface in edit mode
→ Save Changes

Manual/coarse Quick Add MealLogEntry
→ Quick Add editor in edit mode
→ Save Changes
```

TNYX-215 implements only the first create-mode foundation. `MealEditorCreatePage` is not permission to create a second future detailed editor product surface. Future detailed edit mode must reuse/refactor the same Meal Editor composition and contracts. Quick Add/manual remains the explicit separate exception.

### Success Criteria

- body renders from `MealLoggingDraft`;
- meal name is editable;
- calories/protein/carbs/fat totals derive from item consumed snapshots and preserve unknown-vs-zero semantics;
- valid same-unit quantity increments/decrements keep consumed nutrition consistent by proportional rescaling;
- unknown quantity is never fabricated;
- delete updates local draft and cannot produce an empty valid meal;
- existing `MealLogActionFooter` is the fixed action area;
- CTA is non-durable/inert in this slice;
- no parser/network/schema/persistence widening;
- visible contract is safe under light/dark theme, compact width and larger text scale.

### Scope

One Nutrition-owned create-mode controller + one full-screen Meal Editor page/body composition + focused tests + exports.

### Non-Goals

Parser, processing, provider, persistence, Search/Add more, photo/voice, ingredient-detail and existing-log edit-mode persistence remain outside this slice.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `MealLoggingDraft`, `MealLoggingDraftItem`, `NutritionSnapshot`, `MealLogEntry`, `MealLogRepository`, `AddFoodSheet`, `QuickAddEditorSheet`, `MealLogActionFooter`, Nutrition full-screen page patterns and public barrels.
- Linear TNYX-58 confirms one shared detailed Meal Editor contract and the manual/Quick Add edit-surface exception.
- Existing pattern followed: feature state/business rules live outside widgets; full-screen Nutrition surfaces use `Scaffold`/`AppBar`; `MealLogActionFooter` is reusable by Quick Add and detailed Meal Editor.
- Current durable runtime remains manual-only; detailed final save is not available in this slice.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse `MealLogActionFooter` | Locked | Existing widget was explicitly built for Quick Add + full Meal Editor reuse. | Owner/TNYX-207 |
| Full-screen detailed Meal Editor rather than Quick Add-style sheet | Locked | Owner reference/TNYX-58 define scrollable body + fixed footer. | Owner/TNYX-58 |
| Shared detailed editor across detailed create + future detailed edit | Locked | TNYX-58 explicitly converges detailed flows; current create page is only the first mode foundation. | Owner/TNYX-58 |
| Quick Add/manual remains separate | Locked | Coarse/manual MealLogs reopen in Quick Add edit mode rather than detailed Meal Editor. | Owner/TNYX-58 |
| Keep CTA non-durable in this slice | Locked | Canonical runtime currently exposes only manual durable MealLog create. | Audit |
| Same-unit quantity change proportionally rescales known consumed snapshot | Locked for this slice | `consumedNutritionSnapshot` is total for current quantity; ratio scaling preserves that invariant without provider coupling. | Architecture |
| Unknown quantity gets no fabricated default/stepper | Locked | Draft contract preserves incomplete parse truth. | Shared-domain contract |
| Unit is displayed but not freely converted in this slice | Locked | No provider/base serving conversion contract exists yet. | Architecture |
| Meal nutrient total is unknown when any retained item lacks that nutrient | Locked | Summing only known items would falsely imply completeness. | Architecture |

## 4. Architecture Design

### Chosen Approach

`MealEditorCreateController` owns discardable create-mode state. It copies canonical `MealLoggingDraft`, derives meal totals, handles meal-name edits, bounded same-unit quantity stepping and item removal. `MealEditorCreatePage` renders the first full-screen mode of the canonical detailed Meal Editor with a scrolling body and existing fixed `MealLogActionFooter`.

The current class names are mode-specific because only create behavior is implemented. They must not be interpreted as a product decision to duplicate the body for edit mode; when detailed edit mode lands, the audited implementation should reuse/refactor shared Meal Editor composition rather than fork visible behavior.

### Ownership and Data Flow

```text
MealLoggingDraft (shared, discardable)
        ↓
MealEditorCreateController (Nutrition workflow state)
        ↓
MealEditorCreatePage (first mode of detailed Meal Editor)
        ↓
existing MealLogActionFooter (fixed, non-durable CTA in this slice)
```

### Alternative Rejected

- Mutating draft business invariants directly in widgets.
- Reusing Quick Add sheet chrome for detailed Meal Editor.
- Adding speculative edit-mode persistence/API before its audited slice.
- Adding provider serving/base fields or unit conversion without a real contract.
- Creating a duplicate footer/Core component.

### Failure and Accessibility States

- Unknown nutrient shows `—`, never fabricated `0`.
- Unknown quantity renders as unknown and no +/- controls are shown.
- Decrement stops before a non-positive quantity.
- Final item cannot be deleted into an invalid empty draft.
- Long lists scroll while footer remains fixed and safe-area aware.
- Controls use semantic labels/tooltips and compact-width wrapping.
- Focused tests cover larger text scale and both light/dark theme modes.

## 5. Implementation Plan

- [x] Add `MealEditorCreateController` + derived nutrition summary.
- [x] Add full-screen create-mode Meal Editor page/body using Core components and existing footer.
- [x] Export the controller/page through meal-logging barrels.
- [x] Add controller tests for totals, unknown semantics, proportional quantity scaling, deletion and meal-name edits.
- [x] Add widget tests for body/footer, quantity/delete interaction, unknown states, compact width/larger text and dark theme.
- [x] Run exact source/test-head CI.
- [x] Perform bounded source/scope review; no P1/P2 findings remain.

## 6. Quality Review

### Validation Run

- Flutter CI #2595: production analyze stages passed; one widget test failed because the test attempted to tap an off-screen item behind the fixed footer.
- Scoped test-only fix added `ensureVisible` before the delete interaction.
- Flutter CI #2596 at `d3cf7c2569fa5a26e7a33fda43e4ff1b10bffb62`: all analyze/test stages passed.
- Final UI-governance review found light/dark acceptance lacked explicit dark-theme coverage; added focused dark-theme widget test without changing production behavior.
- Flutter CI #2597 / run `35130356043` at `ae7eec2b79c806a085c4163212105770f9623365`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| T215-RF1 | P3 | Resolved | Delete widget test tapped an off-screen control instead of scrolling it into view. | `cf729dae...` | Fixed test interaction; CI #2596 green. |
| T215-RF2 | P3 | Resolved | Owner/Linear acceptance asked for light/dark safety but focused tests covered light only. | `d3cf7c25...` | Added dark-theme coverage; CI #2597 green. |

Final source review found no open P1/P2 finding, no unresolved review thread, and no scope widening into parser/network/persistence/schema/app shell/wearables.

## 7. Final Handoff

### Changed Files

Eight intended files only: this task brief, Nutrition Meal Editor create controller/page/public exports and focused Nutrition tests.

### Actual Behavior

A caller can render the detailed Meal Editor in create mode from a provider-neutral `MealLoggingDraft`; meal name, same-unit quantity corrections and item deletion stay in discardable local state, and calories/macros derive live from current consumed item snapshots. The existing footer is reused. `Log Meal` remains intentionally disabled until detailed persistence exists.

### Known Limitations

Detailed persistence, final save/idempotency, processing/parser activation, unit conversion/serving options, ingredient-detail editing, Add more, photo/voice/search activation, and existing detailed-log edit persistence remain deferred. The canonical product contract nevertheless remains one shared detailed Meal Editor for those detailed flows, with Quick Add/manual as the explicit separate path.

### Final Status

`VALIDATED — ready for PR review; merge still requires explicit owner authorization.`
