# Product Onboarding O8 — Review, Resume + Edit-back

**Status:** Active / audit  
**Tracker:** GitHub Issue #82  
**O7 Health Connections:** #75 ✅ / CI #1603  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
e4d8eadc90b20745a89e894cbfe0cec92cdcb740
Flutter CI #1603 / run 32612660375 / job 97128035652 ✅
```

## Goal

Validate that Review, unfinished-draft resume and edit-back/reconciliation work correctly across the canonical O1–O7 flow before O9 finalization.

## Discovery / success criteria

- Review summarizes only active owner-backed data and never dormant/skipped branch state.
- Back from Review reaches the correct last visible screen for every App Mode variant.
- Editing earlier answers invalidates only dependent completion state and preserves safe dormant data.
- Resume reconstructs the exact mode-specific top-level and child cursor.
- Historical snapshots reconcile safely without fabricated defaults.
- Autosave/failure does not silently discard entered answers.
- O8 adds no new durable owner unless audit proves an actual missing concept.

## Audit targets

- `review_screen.dart` / `review_section.dart`
- `onboarding_controller.dart` previous/next/reconcile logic
- `BuildOnboardingFlowUseCase`
- draft snapshot mapper + schema migration tests
- `review_section_test.dart`
- `onboarding_controller_test.dart`
- `onboarding_controller_draft_persistence_test.dart`
- O3/O5/O6/O7 resume/compatibility tests

## Guardrails

- preserve existing mobile visuals by default;
- no fabricated defaults;
- no applied migration edits or legacy drops;
- no Health Connect permission/data-sync expansion;
- no O9/O10/O11 work;
- PR #50 remains Draft/open/unmerged.

## Execution approach

Audit current behavior first, then split O8 into focused sub-slices. Only one sub-slice may be active at a time. Prefer acceptance tests over production changes when current source already satisfies the contract.

## Validation

Not run yet for O8.

## Exit

Close O8 only after Review, resume and edit-back acceptance is frozen on exact CI evidence, then activate O9.