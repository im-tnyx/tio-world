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
**Review owner:** Independent fallback review at handoff
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main` = `62efac34cd98294397673ef669a72aade0dd0544`
**Branch:** `tnyx/tnyx-219-n5d-3-meal-editor-detailed-log-meal-activation`
**HEAD SHA:** `62efac34cd98294397673ef669a72aade0dd0544` at branch creation
**Observed working-tree state:** Connector-backed branch created from exact current main; local working tree unavailable in this execution environment.
**Observed uncommitted/dirty files:** Not observable through connector; no branch writes existed before this task brief.
**PR / tracker:** Linear TNYX-219 = In Progress; no PR yet.
**Current implementation state:** Readiness reconstructed; source implementation not started.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_logging/meal_editor_create_controller.dart`, `presentation/pages/meal_editor_create_page.dart`, existing `MealLogActionFooter`, `DetailedMealLogCreateRepository`.
**Validation completed at SHA:** Fresh main/Linear/Supabase migration state and UI governance inspected. Source validation not run yet.
**Validation remaining:** Focused controller/widget tests, Flutter CI, exact-head scope/review.
**Current blocker:** None known.
**Open review finding IDs:** None.
**Next exact action:** Implement a controller/coordinator-owned detailed submission boundary and wire existing footer CTA without visual geometry changes.

## Global UI / Design-System Guardrail

Read and applied `apps/features/AGENTS.md` and `apps/core/lib/src/theme/README.md`. This slice is behavior-only/persistence wiring. Existing geometry, spacing, typography, colors, component sizes and layout must remain unchanged.

## 1. Discovery

### User Outcome

A reviewed detailed meal draft can be explicitly committed from the existing Meal Editor `Log Meal` button into canonical durable MealLog history.

### Success Criteria

- Existing Meal Editor appearance remains unchanged.
- Valid corrected drafts can submit exactly once through `DetailedMealLogCreateRepository`.
- In-flight duplicate taps are suppressed.
- Failed/ambiguous retry keeps one stable `clientMutationId`.
- Failure leaves draft editable; success exposes canonical created `MealLogEntry`.

### Scope

- Detailed create submission state/mapping.
- Existing footer CTA enable/loading/error semantics.
- Focused tests.

### Non-Goals

Parser/provider activation, broad navigation flow, new editor body features, schema changes, detailed update/delete.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, current Meal Editor page/controller, existing footer, detailed create repository contract.
- Existing pattern to follow: presentation widget emits actions; controller/coordinator owns business/persistence decisions. `MealLogActionFooter` already exposes null-disabled callback plus `primaryLoading`/`note` state.
- Tests or validation already present: TNYX-215 Meal Editor body tests; TNYX-218 detailed repository tests and green merged CI. Live Supabase migrations `20260917083552`, `20260917083919`, `20260917092920` are applied.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Parser remains out of scope | Locked | TNYX-207 requires durable editor confirmation first | Owner / Linear |
| No Supabase schema work | Locked | Detailed atomic create already exists live | Audit |
| Preserve existing Meal Editor visuals | Locked | `AGENTS.md` mobile visual safety | Owner / repo governance |
| Stable mutation identity lives with submission session | Chosen | Retry/idempotency contract from TNYX-218 | Architecture |
| Widget does not call repository directly | Chosen | Feature boundary requires business logic outside widgets | Architecture |

## 4. Architecture Design

### Chosen Approach

Extend the Meal Editor create controller (or a tightly-owned companion submission controller if needed by separation concerns) with explicit meal context + repository submission state. Build `DetailedMealLogCreate` only when every draft item has positive quantity, nonblank serving unit, and a complete consumed nutrition snapshot.

### Ownership and Data Flow

```text
MealEditorCreatePage
  -> MealEditorCreateController / submission coordinator
  -> DetailedMealLogCreate
  -> DetailedMealLogCreateRepository.createDetailed(...)
  -> canonical MealLogEntry.detailed
  -> caller success callback/result handoff
```

### Alternative Rejected

Calling `createDetailed()` directly from the widget is rejected because it mixes persistence decisions into presentation and makes retry identity/loading/error behavior harder to test.

### Failure and Accessibility States

- Invalid/incomplete draft: CTA remains disabled.
- In flight: existing footer button loading contract used; second submission ignored.
- Failure: concise footer note allowed through existing contract; draft remains editable and retry uses same mutation ID.
- Success: canonical result emitted once to caller.

## 5. Implementation Plan

- [ ] Add explicit detailed submission context/state/controller boundary.
- [ ] Map corrected `MealLoggingDraft` items into `DetailedMealLogCreateItem` without fabricated facts.
- [ ] Retain stable `clientMutationId` across failed/ambiguous retries.
- [ ] Wire existing `MealLogActionFooter` callback/loading/note without visual changes.
- [ ] Expose created canonical `MealLogEntry` via caller-owned success callback/result handoff.
- [ ] Add focused controller and widget tests.
- [ ] Run exact-head CI and scope review.
- [ ] Reconcile task brief, PR, and Linear handoff.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No pre-implementation blocker identified | `62efac34...` | Fresh audit complete |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

TNYX-207 parser/text capture remains deferred until this slice is merged and post-merge audited.

### Final Status

`PARTIAL`
