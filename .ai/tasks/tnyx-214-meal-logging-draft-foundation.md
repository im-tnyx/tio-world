# TNYX-214 — MealLoggingDraft + detailed-item domain foundation

**Status:** In progress
**Primary owner:** `apps/shared/lib/src/nutrition`
**Affected platforms:** shared Dart domain only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `go next` on 2026-09-16 after the read-only TNYX-207 readiness audit identified this as the smallest prerequisite.
**Approved product/UI/data-shape boundaries:** Pure shared-domain foundation for `MealLoggingDraft` and `MealLoggingDraftItem`, focused tests, public exports, and task/docs required for handoff. No UI, Supabase schema, Edge Function, provider SDK/call, or durable detailed MealLog persistence.
**Explicit non-changes:** No activation of `What did you eat?`; no processing/progress bottom sheet; no OpenAI/Gemini invocation; no Supabase Edge Function; no Supabase table/column/RLS/migration; no detailed `MealLogEntry` persistence widening; no Meal Editor UI; no voice/photo/search/saved/recent/barcode flows; no raw AI/provider payload as domain truth.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub branch was 1 commit ahead / 0 behind `main` at `883e43389ae326a3c8f594aa5cc42a26717b0526`, with `main`/merge-base `5d149ee37c97a36454bfcda17901ecacc8075989`; connector-only session cannot inspect local working-tree state.
**Branch:** `tnyx/tnyx-214-meal-logging-draft-foundation`
**HEAD SHA:** `883e43389ae326a3c8f594aa5cc42a26717b0526` before this ownership checkpoint
**Observed working-tree state:** Unavailable in connector-only session; do not infer local cleanliness.
**Observed uncommitted/dirty files:** Unavailable in connector-only session.
**PR / tracker:** Linear TNYX-214 is In Progress, parent TNYX-207; no PR yet.
**Current implementation state:** Shared Nutrition patterns re-read. Quantity/serving is locked to a minimal provider-neutral optional `quantity` + optional nonblank `servingUnit`; provider serving IDs, confidence and normalization math remain deferred.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, shared exports.
**Validation completed at SHA:** Read-only/source exploration only; no implementation validation yet.
**Validation remaining:** focused pure-Dart tests plus applicable shared/package analysis after implementation.
**Current blocker:** None for the approved domain slice.
**Open review finding IDs:** None.
**Next exact action:** Implement immutable provider-neutral draft contracts and focused tests; do not cross into UI/provider/Supabase scope.

## Global UI / Design-System Guardrail

No Flutter UI is in scope. If implementation discovers a need for visible UI changes, stop and create/approve a separate UI slice rather than broadening TNYX-214.

## 1. Discovery

### User Outcome

Provide one canonical Tio-owned editable draft representation that a future natural-language parser can populate and a future Meal Editor can review without treating parser/provider output as durable nutrition history.

### Success Criteria

- Canonical `MealLoggingDraft` exists in shared Nutrition domain.
- Canonical `MealLoggingDraftItem` exists.
- Draft and item contracts are provider-neutral.
- Missing nutrition facts remain missing rather than fabricated as zero.
- Natural-language capture intent can be represented using the existing `MealLogCaptureSource.text` identity.
- Focused tests lock invariants, immutability/defensive behavior, and unknown-value semantics.
- Shared public exports expose the contracts.

### Scope

Pure Dart domain contracts + tests + exports only.

### Non-Goals

UI activation, processing UX, parser network contract, OpenAI/Gemini integration, Edge Functions, Supabase schema/persistence, full Meal Editor, detailed final MealLog persistence, provider catalog/search, voice/photo/barcode/repeat/saved flows.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, `.ai/tasks/TEMPLATE.md`, current shared Nutrition models, Add Food runtime, Quick Add editor, MealLog persistence, TNYX-207/TNYX-58/TNYX-113 tracker scope.
- Existing pattern to follow: immutable shared Nutrition contracts such as `NutritionSnapshot`, `MealLogEntry`, `MealLogMode`, `MealLogCaptureSource`.
- Tests or validation already present: pure-Dart Nutrition tests exist for current shared value contracts; no draft contract tests exist yet.
- Current runtime fact: `MealLogEntry` construction is manual-only; detailed item snapshots and detailed persistence remain deferred.
- Current UI fact: Add Food `What did you eat?` is intentionally disabled until parser/draft/editor readiness exists.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Draft is not durable history | Locked | Parser result must remain editable/discardable until explicit confirmation | TNYX-207 / owner |
| Reuse `NutritionSnapshot` for known nutrition facts | Locked | Avoid parallel nutrient representation and preserve missing-vs-zero truth | Existing Nutrition domain |
| Provider raw payloads stay outside draft domain | Locked | Keeps OpenAI/Gemini/provider schemas from becoming Tio truth | TNYX-207 / root architecture |
| `MealLogCaptureSource.text` represents capture intent | Locked | Existing canonical identity already models text capture independently of provider | Existing shared domain |
| Quantity/serving model | Locked | Optional finite positive `quantity` plus optional nonblank `servingUnit` is enough for parser/editor handoff; each may be absent independently so partial parses remain editable, while provider serving IDs/catalog semantics stay deferred | ChatGPT implementation owner |

## 4. Architecture Design

### Chosen Approach

Add the smallest immutable shared-domain draft aggregate and item value/entity using existing Nutrition primitives. Keep parser/provider/network DTOs outside these contracts.

### Ownership and Data Flow

```text
future natural-language text
→ future protected parser/provider adapter
→ provider-normalization boundary
→ MealLoggingDraft / MealLoggingDraftItem
→ future Meal Editor review/correction
→ explicit Log Meal
→ future detailed MealLog persistence
```

`apps/shared` owns the provider-neutral draft contracts. Flutter presentation will consume them later but must not own provider parsing or persistence truth.

### Alternative Rejected

- Reusing Quick Add/manual `MealLogEntry` as parser output: rejected because it would bypass the review-first detailed-draft boundary and fabricate coarse durable truth.
- Storing raw OpenAI/Gemini JSON in the draft: rejected because provider schemas are not canonical Tio domain state.
- Building full detailed persistence in this slice: rejected because TNYX-214 is intentionally the smallest prerequisite and current database shape is manual-only.
- Freezing provider serving IDs or conversion rules now: rejected because TNYX-214 only needs an editable parser handoff and provider/catalog normalization has not been audited yet.

### Failure and Accessibility States

No UI/accessibility state is implemented here. Domain construction must reject invalid structural values while allowing incomplete nutrition facts to remain explicitly unknown so future UI can present/recover them truthfully.

## 5. Implementation Plan

- [x] Re-read nearby shared Nutrition source/tests immediately before source mutation.
- [x] Define minimal provider-neutral quantity/serving semantics without importing provider concepts.
- [ ] Implement immutable `MealLoggingDraftItem`.
- [ ] Implement immutable `MealLoggingDraft`.
- [ ] Reuse `NutritionSnapshot` and `MealLogCaptureSource.text` where applicable.
- [ ] Add focused pure-Dart tests for invariants, missing nutrition, defensive copying/immutability, and provider-neutral construction.
- [ ] Update shared Nutrition exports.
- [ ] Run focused tests/analyze appropriate to changed shared package.
- [ ] Review exact branch diff for scope creep; no UI/Supabase/provider files.

## 6. Quality Review

### Validation Run

```text
Not run yet — implementation source changes are next.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | — | No implementation review yet | — | — |

## 7. Final Handoff

### Changed Files

Task brief only at current checkpoint. Implementation files are next.

### Actual Behavior

No runtime behavior change yet.

### Known Limitations

- No parser or AI provider integration.
- No processing bottom sheet.
- No Meal Editor UI.
- No detailed durable persistence.
- Local git/worktree state is unavailable from this connector-only session.

### Final Status

`REVIEW`
