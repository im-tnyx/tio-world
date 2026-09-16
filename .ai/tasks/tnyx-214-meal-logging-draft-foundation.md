# TNYX-214 — MealLoggingDraft + detailed-item domain foundation

**Status:** Validated
**Primary owner:** `apps/shared/lib/src/nutrition`
**Affected platforms:** shared Dart domain only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner approved the prerequisite after the read-only TNYX-207 readiness audit and explicitly authorized the current review correction with `go follow root agent.md` on 2026-09-16.
**Approved boundary:** Pure shared-domain foundation for `MealLoggingDraft` and `MealLoggingDraftItem`, focused tests, public exports, and task/review handoff updates.
**Explicit non-changes:** No UI, parser/provider call, Supabase Edge Function, table/column/RLS/migration, detailed durable MealLog widening, Meal Editor implementation, or voice/photo/search/saved/recent/barcode flow.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT fallback Codex-style review on PR #268
**Implementation ownership state:** Complete; review finding corrected and source/test validation green
**Branch:** `tnyx/tnyx-214-meal-logging-draft-foundation`
**Base / merge-base:** `main@5d149ee37c97a36454bfcda17901ecacc8075989`
**Validated source/test HEAD:** `fb29304b72224c5e6edff12767be009197bfa6d8`
**Observed working-tree state:** Unavailable in connector-only session; no local cleanliness claim is made.
**PR / tracker:** PR #268 Ready for review; Linear TNYX-214 In Review; parent TNYX-207 remains Backlog.
**Current implementation state:** Provider-neutral draft contracts are implemented. `MealLoggingDraftItem.consumedNutritionSnapshot` is explicitly the consumed-total nutrition for the item's current amount/serving, never a per-serving value.
**Validation completed:** Flutter CI #2592 / run `35102680283` on `fb29304b72224c5e6edff12767be009197bfa6d8` passed bootstrap, Flutter analyze, Dart analyze, Flutter tests, and Dart tests.
**Validation remaining:** This handoff update is metadata-only and creates a later PR head; confirm its exact-head CI before merge handoff.
**Current blocker:** None at source level. Merge remains owner-gated.
**Open review finding IDs:** None after T214-R1 source correction and CI #2592.
**Next exact action:** Confirm exact metadata-head CI, resolve/reconcile the PR review thread, refresh PR/Linear handoff, then stop for owner merge decision. Do not start TNYX-207 parser/Edge Function work before TNYX-214 merge and a fresh readiness audit.

## 1. Discovery

### User Outcome

Provide one canonical Tio-owned editable meal draft that future parser/provider normalization can populate and a future Meal Editor can review without turning provider output into durable history.

### Success Criteria

- `MealLoggingDraft` and `MealLoggingDraftItem` exist in shared Nutrition domain.
- Draft/item contracts remain provider-neutral.
- Missing nutrition remains unknown rather than fabricated zero.
- Text capture intent uses canonical `MealLogCaptureSource.text`.
- Quantity/serving and nutrition semantics are unambiguous enough for parser → editor handoff.
- Focused pure-Dart tests lock invariants and defensive behavior.
- No UI/backend/persistence scope is introduced.

## 2. Codebase Exploration

Verified before the review correction:

- root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, root/canonical architecture and module-ownership docs, `docs/PUSH_TEMPLATE.md`, and `.github/PULL_REQUEST_TEMPLATE.md`;
- current Linear TNYX-214 and related TNYX-113 durable consumed-snapshot semantics;
- current PR #268, its one P2 review thread, branch ancestry/scope, `NutritionSnapshot`, `MealLoggingDraftItem`, and focused tests;
- `apps/shared` has no nested `AGENTS.md`, so root instructions apply.

Runtime/source truth:

- `apps/shared` is the correct pure-Dart owner for the draft contracts;
- `NutritionSnapshot` carries canonical nutrient amounts and missing-vs-zero truth but does not define serving basis itself;
- TNYX-113 defines future durable detailed item nutrition as consumed snapshot truth after serving normalization/user correction;
- before T214-R1, `quantity` and the generic `nutritionSnapshot` name could coexist without stating whether nutrition was per-serving or consumed-total.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Draft is discardable, not durable history | Locked | Explicit confirmation remains required before actual history exists. |
| Provider payloads stay outside canonical draft state | Locked | Provider schemas are not Tio domain truth. |
| Optional finite-positive `quantity` + optional nonblank `servingUnit` | Locked | Supports incomplete editable parses without freezing provider catalog IDs. |
| Nutrition basis | Locked by T214-R1 | `consumedNutritionSnapshot` is the total nutrition for the current item quantity/serving, never per-serving nutrition. |
| Amount/serving correction rule | Locked by T214-R1 | A changed amount/serving must replace/recompute the consumed snapshot, or clear it when the corrected total is unknown; stale nutrition must not be carried blindly. |
| Empty parser result is not a valid successful draft | Locked | Zero-item parse belongs to parse/recovery handling. |

## 4. Architecture Design

```text
future natural-language text
→ future protected parser/provider adapter
→ provider-normalization boundary
→ MealLoggingDraft / MealLoggingDraftItem
→ future Meal Editor review/correction
→ explicit Log Meal
→ future detailed MealLog persistence
```

### Chosen review fix

Rename the ambiguous item field from `nutritionSnapshot` to `consumedNutritionSnapshot` and document its amount-relative invariant directly on the public contract. This keeps the model minimal while making the parser/editor handoff semantics explicit.

### Rejected alternatives

- Keep the ambiguous field name and rely only on tribal knowledge/comments elsewhere: rejected because consumers could encode the same meal incompatibly.
- Add a provider/per-serving nutrition-basis enum now: rejected because TNYX-214 does not need provider serving normalization/catalog semantics and such a type would prematurely widen the domain.
- Reuse coarse/manual `MealLogEntry` as parser output: rejected because it bypasses the review-first detailed draft boundary.

## 5. Implementation

- [x] Implement immutable provider-neutral `MealLoggingDraftItem` and `MealLoggingDraft`.
- [x] Reuse canonical `NutritionSnapshot` and `MealLogCaptureSource`.
- [x] Preserve independently unknown quantity/unit/nutrition facts.
- [x] Publicly export the draft contracts.
- [x] T214-R1: rename item nutrition to `consumedNutritionSnapshot`.
- [x] T214-R1: state consumed-total basis and amount/serving correction rule.
- [x] T214-R1: add a focused regression covering 2-roti total, corrected 1-roti total, and clear-to-unknown after amount correction.
- [x] Review exact source/test diff for scope creep.

## 6. Quality Review

### Validation

Initial source/test checkpoint:

```text
49b73601a7a95a1801e6658bf1e80d4c45654053
Flutter CI #2588 / run 35093491667 — SUCCESS
```

Pre-review metadata head:

```text
c13f0255626a4fdfc04d15d744ad569f6b7a10cb
Flutter CI #2591 / run 35098266059 — SUCCESS
```

T214-R1 corrected source/test head:

```text
fb29304b72224c5e6edff12767be009197bfa6d8
Flutter CI #2592 / run 35102680283 — SUCCESS
- Bootstrap workspace: SUCCESS
- Analyze Flutter packages: SUCCESS
- Analyze Dart packages: SUCCESS
- Test Flutter packages: SUCCESS
- Test Dart packages: SUCCESS
```

### Review Findings

| ID | Severity | Status | Finding | Observed at SHA | Resolution evidence |
|---|---|---|---|---|---|
| T214-R1 | P2 | Resolved | `quantity` + generic nutrition snapshot did not define per-serving vs consumed-total basis | `c13f0255` | `fb29304b`: `consumedNutritionSnapshot` consumed-total invariant + focused regression; CI #2592 green |

## 7. Final Handoff

### Changed-file scope

- `.ai/tasks/tnyx-214-meal-logging-draft-foundation.md`
- `apps/shared/lib/src/nutrition/meal_logging_draft.dart`
- `apps/shared/lib/src/nutrition/meal_logging_draft_item.dart`
- `apps/shared/lib/src/nutrition/nutrition.dart`
- `apps/shared/test/nutrition/meal_logging_draft_test.dart`

Fresh source-head branch audit before this metadata update: `11 ahead / 0 behind main`, exact merge base `5d149ee37c97a36454bfcda17901ecacc8075989`, exactly the five intended files above.

### Actual behavior

- Shared Nutrition exposes provider-neutral, discardable meal draft contracts.
- Item amount/unit may remain partially unknown.
- `consumedNutritionSnapshot` is optional and represents the current consumed total, not per-serving nutrition.
- Missing nutrients remain unknown; explicit zero remains known zero.
- Amount/serving changes must recompute/replace nutrition or clear it until a corrected total is known.
- No phone UI, provider invocation, Edge Function, Supabase schema/RLS, or durable detailed MealLog behavior changed.

### Known limitations / next boundary

- No parser/provider integration or processing UX.
- No Meal Editor implementation.
- No detailed durable persistence or provider/catalog serving identity.
- TNYX-207 must receive a fresh readiness audit after TNYX-214 merges rather than assuming this draft foundation authorizes parser/Edge Function implementation.
- Connector-only session cannot verify local `git status`.

### Final Status

`PASS` for source/test implementation at `fb29304b72224c5e6edff12767be009197bfa6d8`; exact CI for this later metadata-only handoff head remains the final PR gate before merge handoff.
