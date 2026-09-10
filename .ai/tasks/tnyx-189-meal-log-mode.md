# TNYX-189 — N20A-2 Canonical MealLog mode value contract

**Status:** In progress
**Primary owner:** `apps/shared`
**Affected platforms:** Pure Dart shared contract; future mobile/watch/server consumers

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice
**Approval status:** Approved
**Approval evidence:** Owner `go` on 2026-09-10 authorised the exact N20A-2 slice after the post-PR-#241 TNYX-66 readiness refresh.
**Approved product/UI/data-shape boundaries:** One canonical `MealLogMode` value contract in `apps/shared`, its shared export, focused pure-Dart tests, validation, one focused PR, and the readiness/handoff docs required to keep the selected slice recoverable. No merge.
**Explicit non-changes:** No `MealLogEntry`, `MealLogItemSnapshot`, provider provenance, serving fields, consumed-time/timezone semantics, Supabase migration/schema/RLS/mutation, repository/provider wiring, Quick Add save, UI/routes, membership, ads, quotas, or branch cleanup.

## Active Handoff

**Planning owner:** TNYX-66 readiness gate
**Implementation owner:** ChatGPT
**Review owner:** GitHub final review
**Implementation ownership state:** Complete for the approved source/test boundary; PR #242 published for validation/review
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** `tnyx/tnyx-189-n20a-2-canonical-meallog-mode-value-contract`, cut from `origin/main` `6089d40676114cf941bc04b7e463986ba59e7467`
**HEAD SHA:** Current published PR #242 head is authoritative on GitHub; exact SHA is deliberately not embedded here to avoid self-referential commit churn.
**Observed working-tree state:** This implementation is written on a remote GitHub branch and does not touch the owner's local working tree.
**Observed uncommitted/dirty files:** Owner-reported protected local `pubspec.lock` modification and untracked `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` are outside this remote write path and remain untouched. The TNYX-66 readiness brief in this PR is intentional committed governance state, not local dirty work.
**PR / tracker:** TNYX-189, parent TNYX-113, High/P2, Mobile App. PR #242 is published and unmerged.
**Current implementation state:** `MealLogMode`, its shared export, and focused tests are the only runtime/test changes. The TNYX-66 brief is refreshed to the post-#241/N20A-2 handoff state.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`
**Validation completed at SHA:** Static scope review against base patterns; runtime validation is delegated to repository CI for the exact published PR head.
**Validation remaining:** Final reviewer must verify exact-head GitHub CI is green on the current PR head before merge readiness.
**Current blocker:** None known
**Open review finding IDs:** See PR #242; GitHub review state is authoritative.
**Next exact action:** Verify exact-head CI and review threads, then perform final review. Do not merge or start the next TNYX-113 slice.

## Global UI / Design-System Guardrail

Not applicable. This slice is pure Dart and changes no Flutter UI or design-system surface.

## 1. Discovery

### User Outcome

A durable MealLog can carry an explicit first-class mode identity instead of inferring `manual` versus `detailed` from whether item rows happen to exist.

### Success Criteria

- Exactly two canonical modes exist: `manual` and `detailed`.
- Each mode has a stable storage identity.
- Every canonical value round-trips through storage identity.
- Unknown/future identities stay unknown and never fall back to a canonical mode.
- The type contains no item, nutrition, provider, time, membership, ad, or persistence fields.

### Scope

`apps/shared` enum + barrel export + focused pure-Dart tests, plus the TNYX-66 readiness refresh that selected this slice and this execution brief.

### Non-Goals

Full MealLog aggregate/item contracts, manual/detailed aggregate invariant enforcement, persistence, provider provenance, time semantics, Quick Add integration, UI, monetisation, or branch cleanup.

## 2. Codebase Exploration

### Verified Evidence

- `origin/main` is `6089d40676114cf941bc04b7e463986ba59e7467`, squash merge of PR #241.
- `MealLogCaptureSource` is merged in `apps/shared` and establishes the stable `storageValue` + null-returning `fromStorageValue` pattern.
- `NutritionSnapshot` is already merged and is not changed here.
- TNYX-113 already freezes `mode: detailed | manual` and manual-vs-detailed semantics.
- Duplicate searches for `N20A-2`, `MealLogMode`, and `Canonical MealLog mode` found no existing focused issue before TNYX-189 was created.
- TNYX-123 keeps provider-neutral provider/provenance decisions in a later audited boundary; this slice does not pre-empt it.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| `MealLogMode` is explicit first-class identity | Locked | Deriving mode from item presence can misclassify valid states and makes durable schema semantics ambiguous. | TNYX-113 + owner-approved readiness |
| Canonical values are `manual`, `detailed` only | Locked | Already frozen by TNYX-113. | TNYX-113 |
| Unknown storage value returns `null` | Locked for this slice | Matches existing shared forward-compatibility convention; no fabricated fallback. | Readiness + existing pattern |
| Provider provenance remains deferred | Locked | TNYX-123/provider architecture is not yet frozen and mixed-provider item provenance belongs later. | Readiness |
| Blank Quick Add record display fallback is `Quick Log` | Locked downstream rule | `mealName` remains `null`; display fallback is presentation-only and not part of this enum. | Owner |

## 4. Architecture Design

### Chosen Approach

Use an enhanced Dart enum mirroring `MealLogCaptureSource`:

```text
MealLogMode.manual   -> "manual"
MealLogMode.detailed -> "detailed"
unknown              -> null
```

No fallback and no ordinal persistence contract.

### Ownership and Data Flow

```text
future MealLogEntry.mode
        ↓
MealLogMode
        ↓
stable storageValue at a later persistence slice
```

### Alternative Rejected

Deriving mode from `detailedItems.isEmpty` is rejected because collection state is not the same fact as the durable logging mode.

### Failure and Accessibility States

Unknown serialized values remain unknown (`null`). Accessibility is not applicable to this pure domain value contract.

## 5. Implementation Plan

- [x] Refresh/carry the TNYX-66 readiness artifact for N20A-2.
- [x] Create `MealLogMode` with `manual` and `detailed`.
- [x] Add stable storage values and null-returning decoder.
- [x] Export through the shared Nutrition barrel.
- [x] Add focused contract tests.
- [x] Publish PR #242.
- [ ] Verify exact-head CI and final review.

## 6. Quality Review

### Validation Run

The exact PR-head GitHub CI is the authoritative clean-checkout validation. Final review must verify it before declaring merge readiness.

Focused tests cover exact values, storage round-trip, uniqueness, unknown/null decoding, no fallback, distinct identities, and deterministic enum semantics.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No implementation finding recorded before publication. | GitHub branch | Final PR review remains authoritative. |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-66-nutrition-readiness-gate.md
.ai/tasks/tnyx-189-meal-log-mode.md
apps/shared/lib/src/nutrition/meal_log_mode.dart
apps/shared/lib/src/nutrition/nutrition.dart
apps/shared/test/nutrition/meal_log_mode_test.dart
```

### Actual Behavior

Two provider-independent MealLog mode identities with stable string storage values and forward-safe unknown decoding.

### Known Limitations

This slice deliberately does not enforce the future aggregate invariant (`manualNutritionSnapshot` versus `detailedItems`). That requires `MealLogEntry` and remains deferred. It also does not define provider provenance or time semantics.

### Final Status

`REVIEW` — implementation boundary complete; exact-head CI/final review required; not merged.
