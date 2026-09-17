# TNYX-220 — Natural-language meal parse contract + processing controller foundation

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter phone Nutrition feature contract/state only; no production UI change in this slice

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** TNYX-220 is a bounded internal implementation subtask required to complete the already owner-approved TNYX-207 natural-language meal flow. The owner explicitly said `go follow with root agent.md` after PR #276 merged. This slice introduces no new product-visible UI/UX and no Supabase table/column shape.
**Approved product/UI/data-shape boundaries:** Provider-neutral text-parse repository contract, processing controller/state, safe failure mapping, focused tests/exports/task handoff only.
**Explicit non-changes:** No Add Food UI activation; no keyboard/mic/send behavior; no processing screen; no provider/SDK/network adapter; no Supabase Edge Function; no `services/api`; no secrets/config; no schema/RLS/RPC; no Meal Editor UI or persistence change; no voice/photo/search/saved/recent/barcode work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Independent review fallback after implementation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Remote `main` after PR #276 merge; connector-only execution cannot inspect a local working tree.
**Branch:** `tnyx/tnyx-220-n5d-4-natural-language-meal-parse-contract-processing`
**HEAD SHA:** `0359a35aad54dbbd29c1c9311b6677dfcebc6614` at branch creation
**Observed working-tree state:** Unavailable in connector-only session; no local-cleanliness claim is made.
**Observed uncommitted/dirty files:** Unavailable in connector-only session; repository writes in this session are committed directly through GitHub.
**PR / tracker:** Linear TNYX-220 child of TNYX-207; GitHub PR not created yet.
**Current implementation state:** Readiness reconstructed; task brief created; source implementation not started.
**Relevant execution surface:** Nutrition feature domain repository contracts and meal-logging controller/tests.
**Validation completed at SHA:** None for this slice yet.
**Validation remaining:** Focused Nutrition tests plus repository CI/analyze/test gate after source implementation.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Add the provider-neutral repository/failure contract, processing controller, exports and focused tests without touching production UI/network/backend.

## Global UI / Design-System Guardrail

This slice intentionally makes no Flutter production UI change. `apps/features/AGENTS.md` was read and remains binding. If a visible change becomes necessary, stop and return to the UI approval/theme-governance gate before editing presentation.

## 1. Discovery

### User Outcome

Prepare the safe Tio-owned processing boundary behind future `What did you eat?` submission so text can later be parsed without coupling Add Food presentation to any AI/food provider and without creating durable history before Meal Editor confirmation.

### Success Criteria

- nonblank text can enter one explicit processing operation;
- blank/whitespace input never invokes parsing;
- duplicate submit while processing is suppressed;
- recoverable failure preserves the normalized submitted text for retry;
- success exposes only canonical provider-neutral `MealLoggingDraft` with `MealLogCaptureSource.text`;
- provider/internal errors cannot leak raw payloads into presentation state;
- no visible UI/network/backend/schema/persistence scope is introduced.

### Scope

- `MealTextParseRepository` contract owned by Nutrition;
- small provider-neutral typed failure taxonomy;
- `MealTextParseController` + immutable state;
- input trimming/blank guard and retry behavior;
- capture-source contract validation;
- focused controller/repository-contract tests;
- Nutrition public exports and handoff records.

### Non-Goals

- Add Food UI activation or processing UI;
- provider choice or integration;
- HTTP/Supabase/Edge Function/`services/api` implementation;
- parser prompt/schema/provider DTO design;
- Meal Editor correction redesign;
- final MealLog persistence changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`; `.ai/workflow.md`; `.ai/FEATURE_DEVELOPMENT.md`; `.ai/tasks/README.md`; `apps/features/AGENTS.md`; TNYX-207/TNYX-58/TNYX-215/TNYX-219; GitHub #269; `add_food_sheet.dart`; `MealLoggingDraft` / `MealLoggingDraftItem`; `MealEditorCreateController`; `MealEditorDetailedCreateController`; current repository/controller patterns; `docs/ARCHITECTURE.md`; ADR-0007; Supabase server/access strategy; current `supabase/functions` tree; backend Linear planning TNYX-26/TNYX-27/TNYX-33.
- Existing pattern to follow: feature-owned repository interfaces under `apps/features/nutrition/lib/src/domain/repositories`; stateful mutation controllers under `apps/features/nutrition/lib/src/meal_logging`; widgets render state and emit actions; canonical domain types come from `tio_shared`.
- Tests or validation already present: `MealLoggingDraft` shared tests and multiple Nutrition controller tests establish immutable state/repository fakes and duplicate-submit patterns. No production meal-text parse contract/controller exists today.

Fresh readiness facts:

- `main` is `0359a35aad54dbbd29c1c9311b6677dfcebc6614` after merged PR #276.
- Meal Editor create body and durable detailed `Log Meal` path now exist.
- Add Food natural-language surface remains intentionally disabled/inert.
- Current Meal Editor can correct known same-unit quantity and delete items, but cannot fill unknown quantity, switch serving unit, or repair missing nutrition.
- Detailed save requires each item to have quantity, serving unit and nutrition snapshot. A later live adapter therefore must return a sufficiently complete normalized draft or map insufficient normalization to recoverable parse failure until broader ingredient correction exists.
- `services/api` does not exist yet; current canonical architecture keeps it future/deferred. `supabase/functions` has only `google-login-admission` and no Nutrition parser function.
- `docs/SUPABASE_STRATEGY.md` still contains historical `backend/` wording; root `AGENTS.md`, `docs/ARCHITECTURE.md` and ADR-0007 are the current canonical server-boundary truth.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep this slice provider-neutral | Locked | No provider is selected and provider credentials must remain server-side. | TNYX-207 + root architecture |
| Controller trims outer whitespace before repository call | Locked | Prevent duplicate input semantics and keep the later UI submit path simple. | Implementation |
| Blank input is a no-op, not a parse failure | Locked | Future UI already disables submission for blank input; impossible user action should not create an error state. | Implementation |
| Use a small typed safe failure taxonomy | Locked | Allows future adapters to map unrecognized/incomplete/unavailable outcomes without exposing provider payloads. | Implementation |
| Reject repository results whose capture source is not `text` | Locked | The contract is specifically natural-language capture; silently accepting another source would corrupt provenance. | Implementation |
| Do not enforce item completeness in the generic repository contract | Locked | `MealLoggingDraft` intentionally permits partial facts; completeness for the first live adapter is a later adapter/handoff policy because current editor correction is incomplete. | Existing shared contract + audit |

## 4. Architecture Design

### Chosen Approach

Create a small feature-domain `MealTextParseRepository` returning canonical `MealLoggingDraft`, with a provider-neutral failure object. Add `MealTextParseController` that owns input normalization, processing state, duplicate suppression, failure sanitization, retry text and capture-source validation.

### Ownership and Data Flow

```text
future Add Food UI
  -> MealTextParseController
  -> MealTextParseRepository
  -> future protected adapter
  -> MealLoggingDraft
  -> future Meal Editor navigation/handoff
```

This slice stops before the protected adapter and before presentation wiring.

### Alternative Rejected

Calling Gemini/FatSecret/Edamam or a Supabase function directly from `AddFoodSheet` is rejected because it leaks provider/network assumptions into presentation, violates the existing feature boundary, and prematurely selects infrastructure before a tested Tio-owned contract exists.

### Failure and Accessibility States

No production accessibility surface changes here. State contract supports idle, processing, failed and succeeded. Failures expose only Tio-owned messages/reasons; the normalized submitted text remains available for retry. Unexpected repository errors are sanitized to the generic unavailable failure.

## 5. Implementation Plan

- [ ] Add provider-neutral parser repository + safe failure contract.
- [ ] Add immutable processing state + controller with blank guard, duplicate suppression, retry and text-source validation.
- [ ] Export the new contract/controller through Nutrition public barrels.
- [ ] Add focused unit tests covering normalization, blank guard, loading/duplicate submit, recoverable failure/retry, unexpected error sanitization and invalid capture source.
- [ ] Run proportional validation and review the exact diff against scope.
- [ ] Reconcile Linear/PR/task handoff.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No review yet. | — | — |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

No live provider/network adapter or Add Food presentation wiring belongs to this slice. Current Meal Editor cannot fully repair all partial parser facts; the later live adapter must account for that readiness rule.

### Final Status

`PARTIAL`
