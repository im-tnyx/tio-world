# TNYX-219 — Meal Editor Detailed Log Meal Activation

**Status:** Validated
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
**Implementation ownership state:** Handoff pending review/merge
**Ownership transition:** Review findings returned to the already-recorded implementation owner and were fixed without broadening scope.
**Repository state last verified:** `main` = `62efac34cd98294397673ef669a72aade0dd0544`
**Branch:** `tnyx/tnyx-219-n5d-3-meal-editor-detailed-log-meal-activation`
**Validated implementation HEAD:** `bfa684ebcf277dfe508473e5ab99198415d59773`
**Observed working-tree state:** Connector-backed implementation; local working tree is not available in this execution environment.
**Observed uncommitted/dirty files:** Not observable through connector. Live PR changed-file scope is the six files listed below.
**PR / tracker:** PR #276 remains Draft only until this handoff-only metadata commit receives its final CI; Linear TNYX-219 remains In Progress until that review gate.
**Current implementation state:** Detailed create activation and both review fixes are implemented and validated at `bfa684eb...`.
**Relevant execution surface:** `meal_editor_detailed_create_controller.dart`, `meal_editor_create_page.dart`, existing `MealLogActionFooter`, `DetailedMealLogCreateRepository`.
**Validation completed at SHA:** Flutter CI #2616 on `bfa684ebcf277dfe508473e5ab99198415d59773` passed bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests.
**Validation remaining:** Final CI on this handoff-only metadata HEAD, then review-thread/PR/Linear state reconciliation. No runtime source changed after the validated implementation HEAD.
**Current blocker:** None in runtime implementation; final metadata-head CI is the remaining governance gate.
**Open review finding IDs:** None. `TNYX-219-R1` and `TNYX-219-R2` are resolved by source fixes plus CI #2616.
**Next exact action:** Confirm final CI green, resolve GitHub review threads, mark PR Ready/In Review and sync Linear to In Review.

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
- [x] Pass implementation-head Flutter CI #2616.
- [ ] Pass final handoff-only metadata-head CI and reconcile PR/Linear review state.

## 6. Quality Review

### Validation History

- Flutter CI #2611 at initial implementation HEAD `3ec50ad506bb48d7fe0767cb870a86884a901203`: **FAILED** during `tio_feature_nutrition` analyzer; tests were skipped.
- `TNYX-219-R1`: `MealLogCreateOutcomeUnknown` was used without importing its defining repository contract.
- `TNYX-219-R2`: ambiguous outcome was internally frozen but UI disabled the only retry action and left submit-relevant controls editable.
- Fixes added the correct exception import, made frozen ambiguous retry submit-capable, locked draft/category/time/back while unresolved, and added controller/widget regression coverage.
- Flutter CI #2616 at implementation HEAD `bfa684ebcf277dfe508473e5ab99198415d59773`: **PASS** — bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all succeeded.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Resolution evidence |
|---|---|---|---|---|---|
| TNYX-219-R1 | P1 | Resolved | `MealLogCreateOutcomeUnknown` catch type missing import; analyzer failed | `3ec50ad5...` | Correct domain import + CI #2616 green |
| TNYX-219-R2 | P1 | Resolved | Ambiguous outcome disabled retry while editable UI could diverge from frozen payload | `3ec50ad5...` | Retry remains available, submit-relevant UI/navigation locks, regression tests + CI #2616 green |

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

`VALIDATED` at implementation HEAD `bfa684ebcf277dfe508473e5ab99198415d59773`; final handoff metadata CI/review-state reconciliation remains before merge.
