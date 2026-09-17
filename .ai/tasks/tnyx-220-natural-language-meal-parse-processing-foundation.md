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
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** Remote `main` remains `0359a35aad54dbbd29c1c9311b6677dfcebc6614`; connector-only execution cannot inspect a local working tree.
**Branch:** `tnyx/tnyx-220-n5d-4-natural-language-meal-parse-contract-processing`
**HEAD SHA:** `9a0a466dccbc03b9d9417288bfa596788df38fe0` implementation head validated by CI #2619; this handoff update creates one later task-metadata-only head.
**Observed working-tree state:** Unavailable in connector-only session; no local-cleanliness claim is made.
**Observed uncommitted/dirty files:** Unavailable in connector-only session; repository writes in this session are committed directly through GitHub.
**PR / tracker:** Draft PR #277; Linear TNYX-220 In Progress; parent TNYX-207 remains the broader natural-language flow.
**Current implementation state:** Repository/failure contract, controller/state, exports and focused tests are implemented. No production UI/network/backend/schema/persistence code changed.
**Relevant execution surface:** Nutrition feature domain repository contracts and meal-logging controller/tests.
**Validation completed at SHA:** Flutter CI #2619 PASS at `9a0a466dccbc03b9d9417288bfa596788df38fe0`: workspace bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all succeeded.
**Validation remaining:** Exact-head CI for this task-handoff-only commit, then Ready-for-Review reconciliation.
**Current blocker:** None.
**Open review finding IDs:** None after implementation diff review.
**Next exact action:** Wait for exact-head CI on the handoff-only head; if green, mark PR #277 Ready for Review and move TNYX-220 to In Review. Do not start provider/UI work in this slice.

## Global UI / Design-System Guardrail

This slice makes no Flutter production UI change. `apps/features/AGENTS.md` was read and remains binding. Any later visible Add Food or Meal Editor change must return to the UI approval/theme-governance gate before editing presentation.

## 1. Discovery

### User Outcome

Prepare the safe Tio-owned processing boundary behind future `What did you eat?` submission so text can later be parsed without coupling Add Food presentation to any AI/food provider and without creating durable history before Meal Editor confirmation.

### Success Criteria

- nonblank text enters one explicit processing operation;
- blank/whitespace input never invokes parsing;
- duplicate submit while processing is suppressed;
- recoverable failure preserves normalized submitted text for retry;
- success exposes only canonical provider-neutral `MealLoggingDraft` with `MealLogCaptureSource.text`;
- provider/internal errors cannot leak raw payloads into presentation state;
- no visible UI/network/backend/schema/persistence scope is introduced.

### Scope

- `MealTextParseRepository` contract owned by Nutrition;
- provider-neutral typed failure taxonomy;
- `MealTextParseController` + immutable state;
- input trimming/blank guard and retry behavior;
- capture-source contract validation;
- focused controller tests;
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
- Existing pattern followed: feature-owned repository interfaces under `apps/features/nutrition/lib/src/domain/repositories`; stateful controllers under `apps/features/nutrition/lib/src/meal_logging`; canonical draft types from `tio_shared`.
- Current Add Food natural-language surface remains disabled/inert.
- Current detailed save requires quantity + serving unit + nutrition snapshot for every item. The current Meal Editor cannot fully repair all missing parse facts, so a later live adapter must return a sufficiently complete draft or map insufficient normalization to recoverable failure until broader ingredient correction exists.
- `services/api` is not implemented; `supabase/functions` currently has no Nutrition parser function.
- Historical `backend/` wording in `docs/SUPABASE_STRATEGY.md` is stale against root `AGENTS.md`, `docs/ARCHITECTURE.md` and ADR-0007, which are the current canonical server-boundary truth.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep this slice provider-neutral | Locked | No provider is selected and provider credentials must remain server-side. | TNYX-207 + root architecture |
| Trim outer whitespace before repository call | Locked | Normalizes the logical text request without rewriting its internal content. | Implementation |
| Blank input is a no-op, not a parse failure | Locked | Future UI disables blank submission; an impossible action should not create error state. | Implementation |
| Use `unrecognized`, `incomplete`, `unavailable` safe failure reasons | Locked | Future adapters can map recoverable outcomes without leaking provider payloads. | Implementation |
| Reject successful drafts whose capture source is not `text` | Locked | Natural-language provenance must remain correct. | Implementation |
| Do not add generic item-completeness validation here | Locked | `MealLoggingDraft` deliberately permits partial facts; first live adapter/handoff policy owns the current editor-readiness restriction. | Existing domain contract + audit |

## 4. Architecture Design

### Chosen Approach

`MealTextParseRepository` returns canonical `MealLoggingDraft` and exposes only a small Tio-owned failure reason. `MealTextParseController` owns input normalization, processing state, duplicate suppression, safe failure mapping, retry text and capture-source validation.

### Ownership and Data Flow

```text
future Add Food UI
  -> MealTextParseController
  -> MealTextParseRepository
  -> future protected adapter
  -> MealLoggingDraft
  -> future Meal Editor navigation/handoff
```

### Alternative Rejected

Direct provider/Supabase/network calls from `AddFoodSheet` were rejected because they would leak infrastructure into presentation and select a provider before a stable Tio-owned seam exists.

### Failure and Accessibility States

No production accessibility surface changes. State supports idle, processing, failed and succeeded. Typed failures expose only stable Tio-owned messages/reasons; unexpected errors are sanitized to unavailable; failed state retains the normalized submitted text for retry.

## 5. Implementation Plan

- [x] Add provider-neutral parser repository + safe failure contract.
- [x] Add immutable processing state + controller with blank guard, duplicate suppression, retry and text-source validation.
- [x] Export the new contract/controller through Nutrition public barrels.
- [x] Add focused tests for normalization, blank guard, loading/duplicate submit, recoverable failure/retry, safe messages, unexpected-error sanitization and invalid capture source.
- [x] Audit exact implementation delta against the approved scope.
- [ ] Final exact-head CI and Ready-for-Review reconciliation.

## 6. Quality Review

### Validation Run

```text
Flutter CI #2619 @ 9a0a466dccbc03b9d9417288bfa596788df38fe0
PASS — workspace bootstrap
PASS — Flutter package analyze
PASS — Dart package analyze
PASS — Flutter package tests
PASS — Dart package tests
```

Implementation scope audit at the validated head: base `0359a35aad54dbbd29c1c9311b6677dfcebc6614`, `6 ahead / 0 behind`, 6 changed files, all within the TNYX-220 task/Nutrition boundary.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No blocking finding found in the implementation diff review. | `9a0a466d` | CI #2619 green; scope audit clean. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-220-natural-language-meal-parse-processing-foundation.md`
- `apps/features/nutrition/lib/src/domain/repositories/meal_text_parse_repository.dart`
- `apps/features/nutrition/lib/src/domain/repositories/repositories.dart`
- `apps/features/nutrition/lib/src/meal_logging/meal_text_parse_controller.dart`
- `apps/features/nutrition/lib/src/meal_logging/meal_logging.dart`
- `apps/features/nutrition/test/meal_logging/meal_text_parse_controller_test.dart`

### Actual Behavior

- natural-language text is normalized with outer trim and blank input is ignored;
- one processing operation runs at a time and duplicate in-flight submission is suppressed;
- recoverable parser failures map to stable Tio-owned messages and retain retry text;
- unexpected failures are sanitized and never expose raw provider details through controller state;
- retry reuses the normalized failed text;
- successful repository output must carry `MealLogCaptureSource.text` and is exposed as canonical `MealLoggingDraft`;
- no history is persisted and no provider/network/backend/UI code is active.

### Known Limitations

No live parser adapter or Add Food presentation wiring exists yet. Provider choice remains deliberately open. The current Meal Editor cannot fully repair all partial parse facts, so the next live adapter slice must enforce the recorded completeness/readiness rule or first land the necessary correction capability as a separate approved slice.

### Final Status

`REVIEW` — implementation-head validation passed; final handoff-only exact-head CI is the remaining gate before Ready for Review.
