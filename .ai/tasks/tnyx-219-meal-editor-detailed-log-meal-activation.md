# TNYX-219 — Meal Editor Detailed Log Meal Activation

**Status:** In progress
**Primary owner:** Nutrition Meal Editor create flow
**Affected platforms:** Flutter Nutrition feature only; no Supabase schema change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `go with follow agent.md` on 2026-09-17 after TNYX-219 was created from a fresh post-merge audit.
**Approved product/UI/data-shape boundaries:** Activate only the existing detailed Meal Editor create-mode `Log Meal` submission path against the already-merged detailed MealLog repository. Preserve current rendered UI/layout and existing `MealLogActionFooter`.
**Explicit non-changes:** No parser/AI/provider activation, no `What did you eat?` submit flow, no voice/photo/search/saved/recent/barcode, no Add more destination, no detailed edit/delete, no UI redesign, no Supabase table/column/RLS/function shape change, no `services/api`.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT fallback review on the owner-approved slice
**Implementation ownership state:** Active
**Ownership transition:** Review findings returned to the already-recorded implementation owner; no scope transfer.
**Repository state last verified:** `main` = `62efac34cd98294397673ef669a72aade0dd0544`
**Branch:** `tnyx/tnyx-219-n5d-3-meal-editor-detailed-log-meal-activation`
**Source/test checkpoint before this handoff update:** `2d3c39f1012e1857b8d7f112de5c6808d513923f`
**Observed working-tree state:** Connector-backed implementation; local working tree is not available in this execution environment.
**Observed uncommitted/dirty files:** Not observable through connector. Live PR changed-file scope is the six files listed below.
**PR / tracker:** Draft PR #276 open; Linear TNYX-219 = In Progress.
**Current implementation state:** Detailed create controller + existing Meal Editor footer wiring implemented. Two review blockers found at initial HEAD `3ec50ad5...` have source/test fixes applied; exact-head validation remains the gate.
**Relevant execution surface:** `meal_editor_detailed_create_controller.dart`, `meal_editor_create_page.dart`, existing `MealLogActionFooter`, `DetailedMealLogCreateRepository`.
**Validation completed at SHA:** Initial Flutter CI #2611 at `3ec50ad5...` failed in analyzer and skipped tests. Source/test fixes are now applied; no green exact-head validation is claimed yet.
**Validation remaining:** Flutter CI on the final handoff HEAD, exact-head scope audit, review-thread reconciliation.
**Current blocker:** Exact-head Flutter CI must pass before Ready/In Review or completion.
**Open review finding IDs:** `TNYX-219-R1`, `TNYX-219-R2` pending exact-head validation.
**Next exact action:** Run/reconcile exact-head Flutter CI, then resolve review threads and move the task to review only if all required checks are green.

## Global UI / Design-System Guardrail

Read and applied `apps/features/AGENTS.md` and `apps/core/lib/src/theme/README.md`. This slice is behavior/persistence wiring only. Existing geometry, spacing, typography, component sizes and layout remain unchanged. Ambiguous-save locking reuses existing component disabled/loading contracts and the established Quick Add reconciliation pattern.

## 1. Discovery

### User Outcome

A reviewed detailed meal draft can be explicitly committed from the existing Meal Editor `Log Meal` button into canonical durable MealLog history.

### Success Criteria

- Existing Meal Editor composition remains unchanged.
- Valid corrected drafts can submit exactly once through `DetailedMealLogCreateRepository`.
- In-flight duplicate taps are suppressed.
- Known-failure retry keeps the same mutation identity for the unchanged logical create.
- Ambiguous outcome freezes submit-relevant editing and retries the exact frozen payload with the same mutation identity until reconciled.
- Known failure leaves the draft editable; success exposes canonical created `MealLogEntry`.

### Scope

- Detailed create submission state/mapping.
- Existing footer CTA enable/loading/error/reconciliation semantics.
- Focused controller and widget tests.

### Non-Goals

Parser/provider activation, broad navigation flow, new editor body features, schema changes, detailed update/delete.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, current Meal Editor page/controller, existing footer, detailed create repository contract.
- Existing pattern followed: presentation emits actions; controller/coordinator owns persistence mapping, retry identity and failure classification.
- Existing Quick Add create flow provides the repository-local precedent for ambiguous outcome: keep the exact retry action available while locking draft/category/time/dismissal until reconciliation.
- TNYX-218 detailed repository foundation is already merged on current `main`; no new Supabase shape is required for this slice.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Parser remains out of scope | Locked | TNYX-207 requires durable editor confirmation first | Owner / Linear |
| No Supabase schema work | Locked | Detailed atomic create already exists | Audit |
| Preserve existing Meal Editor visuals | Locked | `AGENTS.md` mobile visual safety | Owner / repo governance |
| Stable mutation identity lives with submission session | Implemented | Retry/idempotency contract from TNYX-218 | Architecture |
| Widget does not call repository directly | Implemented | Feature boundary keeps persistence decisions outside widgets | Architecture |
| Ambiguous outcome keeps retry available but locks editing/navigation | Implemented | Prevents a new payload/key from racing an unresolved durable create | Review + existing Quick Add precedent |

## 4. Architecture Design

### Chosen Approach

A dedicated `MealEditorDetailedCreateController` owns validation, `DetailedMealLogCreate` mapping, stable `clientMutationId`, duplicate in-flight suppression, failure state and ambiguous reconciliation. `MealEditorCreatePage` keeps the existing `MealLogActionFooter` and only renders controller state / emits actions.

### Ownership and Data Flow

```text
MealLoggingDraft + meal context
  -> MealEditorDetailedCreateController
  -> DetailedMealLogCreate
  -> DetailedMealLogCreateRepository.createDetailed(...)
  -> canonical MealLogEntry.detailed
  -> caller onCreated handoff
```

### Ambiguous Reconciliation

```text
create attempt
  -> outcome unknown
  -> exact DetailedMealLogCreate remains frozen
  -> draft/category/time/back navigation lock
  -> Log Meal remains available as retry/reconcile action
  -> same clientMutationId + exact payload retried
  -> canonical success unlocks via caller handoff
```

### Alternative Rejected

Calling `createDetailed()` directly from the widget is rejected because it mixes persistence decisions into presentation and makes retry identity/loading/error behavior harder to test.

## 5. Implementation

- [x] Add explicit detailed submission context/state/controller boundary.
- [x] Map corrected `MealLoggingDraft` items into `DetailedMealLogCreateItem` without fabricated facts.
- [x] Retain stable `clientMutationId` across unchanged known-failure retry and ambiguous retry.
- [x] Suppress duplicate in-flight submission.
- [x] Wire existing `MealLogActionFooter` callback/loading/note without layout redesign.
- [x] Expose canonical created `MealLogEntry` through caller-owned success handoff.
- [x] Add focused controller/widget tests.
- [x] Add ambiguous-outcome regression coverage for retry availability + draft/context lock.
- [ ] Pass final exact-head Flutter CI.
- [ ] Resolve review threads and reconcile PR/Linear review state.

## 6. Quality Review

### Validation History

- Flutter CI #2611 at initial implementation HEAD `3ec50ad506bb48d7fe0767cb870a86884a901203`: **FAILED** during `tio_feature_nutrition` analyzer; tests were skipped.
- Failure was caused by `MealLogCreateOutcomeUnknown` being used without importing its defining repository contract.
- Review also found ambiguous outcome was internally frozen but UI disabled the only retry action and left submit-relevant controls editable.
- Fix commits added the correct exception import, made frozen ambiguous retry submit-capable, locked draft/category/time/back while unresolved, and added controller/widget regression coverage.
- Final exact-head Flutter CI: **pending**; do not claim validation until it completes green.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-219-R1 | P1 | Open | `MealLogCreateOutcomeUnknown` catch type missing import; analyzer failed | `3ec50ad5...` | Source fix applied; close only after exact-head CI passes |
| TNYX-219-R2 | P1 | Open | Ambiguous outcome disabled retry while editable UI could diverge from frozen payload | `3ec50ad5...` | Controller/page/test fix applied using existing Quick Add pattern; close only after exact-head CI passes |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-219-meal-editor-detailed-log-meal-activation.md`
- `apps/features/nutrition/lib/src/meal_logging/meal_editor_detailed_create_controller.dart`
- `apps/features/nutrition/lib/src/meal_logging/meal_logging.dart`
- `apps/features/nutrition/lib/src/meal_logging/presentation/pages/meal_editor_create_page.dart`
- `apps/features/nutrition/test/meal_logging/meal_editor_create_page_test.dart`
- `apps/features/nutrition/test/meal_logging/meal_editor_detailed_create_controller_test.dart`

### Actual Behavior

Complete detailed drafts with valid category/time context activate the existing `Log Meal` action and persist through `DetailedMealLogCreateRepository`. Known failures remain editable/retryable with stable identity when unchanged. Ambiguous failures keep the exact create frozen, lock submit-relevant editing/navigation, and expose the existing CTA as the same-operation reconcile retry. Success returns the canonical repository result to the caller.

### Known Limitations

TNYX-207 parser/text capture remains deferred until this slice is merged and post-merge audited. Detailed edit/delete and Add more remain outside this slice.

### Final Status

`PARTIAL` — implementation and review fixes are present; exact-head CI/review reconciliation is still required.
