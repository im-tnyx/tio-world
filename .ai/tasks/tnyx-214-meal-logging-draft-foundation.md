# TNYX-214 — MealLoggingDraft + detailed-item domain foundation

**Status:** Validated
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
**Review owner:** ChatGPT self-review; external PR review still available before merge
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** source/test candidate `49b73601a7a95a1801e6658bf1e80d4c45654053` descended from `main`/merge-base `5d149ee37c97a36454bfcda17901ecacc8075989`; connector-only session cannot inspect local working-tree state.
**Branch:** `tnyx/tnyx-214-meal-logging-draft-foundation`
**HEAD SHA:** source/test candidate `49b73601a7a95a1801e6658bf1e80d4c45654053`; this handoff update creates a later metadata-only head that requires its own CI check.
**Observed working-tree state:** Unavailable in connector-only session; do not infer local cleanliness.
**Observed uncommitted/dirty files:** Unavailable in connector-only session.
**PR / tracker:** Draft PR #268; Linear TNYX-214 In Progress at source validation checkpoint, parent TNYX-207.
**Current implementation state:** Canonical provider-neutral `MealLoggingDraft` and `MealLoggingDraftItem` are implemented and publicly exported. Draft items preserve partial quantity/unit/nutrition truth without provider payload coupling. No runtime UI/persistence/backend behavior was activated.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, shared exports.
**Validation completed at SHA:** `49b73601a7a95a1801e6658bf1e80d4c45654053` — Flutter CI #2588 / run `35093491667`: bootstrap, Flutter analyze, Dart analyze, Flutter tests, Dart tests all SUCCESS.
**Validation remaining:** confirm CI on the final metadata-only head; no new source validation is otherwise required unless source moves.
**Current blocker:** None.
**Open review finding IDs:** None from implementation self-review.
**Next exact action:** Confirm exact-head metadata CI, mark PR Ready for review and Linear TNYX-214 In Review, then stop for review/merge decision. Do not start parser/Edge Function work from this task.

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
- Existing pattern followed: immutable shared Nutrition contracts such as `NutritionSnapshot`, `MealLogEntry`, `MealLogMode`, `MealLogCaptureSource`.
- Source implementation: `MealLoggingDraftItem` validates nonblank item identity, finite positive known quantity, optional nonblank unit, optional canonical nutrition; `MealLoggingDraft` normalizes blank optional meal name, requires capture source plus at least one item, and defensively copies its item list.
- Tests cover provider-neutral construction, independently unknown quantity/unit/nutrition, missing nutrient versus explicit zero, invalid structural values, value semantics and defensive list copying.
- Current runtime fact remains unchanged: `MealLogEntry` construction/persistence is manual-only; detailed item snapshots and detailed persistence remain deferred.
- Current UI fact remains unchanged: Add Food `What did you eat?` is still intentionally disabled.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Draft is not durable history | Locked | Parser result must remain editable/discardable until explicit confirmation | TNYX-207 / owner |
| Reuse `NutritionSnapshot` for known nutrition facts | Locked | Avoid parallel nutrient representation and preserve missing-vs-zero truth | Existing Nutrition domain |
| Provider raw payloads stay outside draft domain | Locked | Keeps OpenAI/Gemini/provider schemas from becoming Tio truth | TNYX-207 / root architecture |
| `MealLogCaptureSource.text` represents capture intent | Locked | Existing canonical identity already models text capture independently of provider | Existing shared domain |
| Quantity/serving model | Locked | Optional finite positive `quantity` plus optional nonblank `servingUnit` is enough for parser/editor handoff; each may be absent independently so partial parses remain editable, while provider serving IDs/catalog semantics stay deferred | ChatGPT implementation owner |
| Empty parser result is not a successful draft | Locked | A zero-item result belongs to parse/recovery handling; it must not look like a valid meal moving toward persistence | ChatGPT implementation owner |

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

No UI/accessibility state is implemented here. Domain construction rejects invalid structural values while allowing incomplete nutrition facts to remain explicitly unknown so future UI can present/recover them truthfully.

## 5. Implementation Plan

- [x] Re-read nearby shared Nutrition source/tests immediately before source mutation.
- [x] Define minimal provider-neutral quantity/serving semantics without importing provider concepts.
- [x] Implement immutable `MealLoggingDraftItem`.
- [x] Implement immutable `MealLoggingDraft`.
- [x] Reuse `NutritionSnapshot` and `MealLogCaptureSource.text` where applicable.
- [x] Add focused pure-Dart tests for invariants, missing nutrition, defensive copying/immutability, and provider-neutral construction.
- [x] Update shared Nutrition exports.
- [x] Run repository CI covering Flutter/Dart analyze and tests on exact source candidate.
- [x] Review exact branch diff for scope creep; no UI/Supabase/provider files.

## 6. Quality Review

### Validation Run

```text
Source/test SHA: 49b73601a7a95a1801e6658bf1e80d4c45654053
Flutter CI #2588 / run 35093491667: SUCCESS
- Bootstrap workspace: SUCCESS
- Analyze Flutter packages: SUCCESS
- Analyze Dart packages: SUCCESS
- Test Flutter packages: SUCCESS
- Test Dart packages: SUCCESS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | — | Self-review found no P1/P2 scope, ownership, truth-semantics, or provider-coupling issue | `49b73601` | PR #268 diff + CI #2588 |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-214-meal-logging-draft-foundation.md`
- `apps/shared/lib/src/nutrition/meal_logging_draft.dart`
- `apps/shared/lib/src/nutrition/meal_logging_draft_item.dart`
- `apps/shared/lib/src/nutrition/nutrition.dart`
- `apps/shared/test/nutrition/meal_logging_draft_test.dart`

### Actual Behavior

- Shared Nutrition now exposes a provider-neutral discardable meal draft aggregate and item contract.
- A valid draft carries capture intent plus at least one item; optional meal name blanks normalize to unknown.
- Item display name is required; quantity is optional but must be finite and greater than zero when known; serving unit may remain unknown independently.
- Item nutrition is optional and reuses canonical `NutritionSnapshot`, preserving absent nutrient versus explicit zero.
- Draft item lists are defensively copied/unmodifiable and both contracts have deterministic value semantics.
- No app UI, parser call, provider integration, Edge Function, Supabase schema, or durable detailed MealLog behavior changed.

### Known Limitations

- No parser or AI provider integration.
- No processing bottom sheet.
- No Meal Editor UI.
- No meal-category/date/time draft context yet; TNYX-207 readiness must decide the smallest next context/editor/parser prerequisite rather than silently widening this validated slice.
- No detailed durable persistence or item-level provider/catalog provenance.
- Local git/worktree state is unavailable from this connector-only session.

### Final Status

`PASS`
