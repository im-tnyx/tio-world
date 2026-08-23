# Product Onboarding O8A — Review Active-data Mode Matrix

**Status:** Active  
**Tracker:** GitHub Issue #83  
**Parent O8:** #82  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**O11 cleanup:** #54 BLOCKED until O10

## Starting checkpoint

```text
3d039cfeab32a8c0a812929ad8bdddfa6fda09d0
Flutter CI #1605 ✅
Android Native CI #17 ✅
```

This checkpoint defines O8 only; it is not O8A acceptance.

## Audit result

`ReviewScreen` currently derives Workout visibility from active Product Onboarding state:

```text
Workout             → eligible when Workout data exists
Nutrition           → Workout summary hidden
Hybrid setupNow     → eligible when Workout data exists
Hybrid later        → Workout summary hidden while dormant data is preserved
```

Existing tests cover Hybrid-later and dormant Target Weight / Goal Pace behavior, and O7D covers no fabricated Health `connected` state. The missing evidence is one explicit mode matrix that locks these rules together.

## Scope

Add focused widget acceptance tests only unless they expose a real source mismatch.

Required matrix:

```text
Workout             → active Workout Plan visible
Nutrition           → seeded dormant Workout data hidden
Hybrid setupNow     → active Workout Plan visible
Hybrid later        → seeded dormant Workout data hidden
```

## Acceptance

- [ ] all four App Mode / Hybrid branch variants are explicitly tested;
- [ ] inactive Workout data remains preserved in the draft but absent from Review UI;
- [ ] active Workout data is visible in Review;
- [ ] existing weight-direction dormant-data tests remain green;
- [ ] O7 Health Review truth tests remain green;
- [ ] no production source change unless the focused tests expose a real contract violation;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests green on one exact source SHA.

## Guardrails

- no Review redesign or new product fields;
- no persistence/schema changes;
- no Health permission/data-sync expansion;
- no fabricated defaults;
- no O8B/O9 work;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O8A exact CI evidence in #83/#82/task, then activate O8B Review Back + exact resume cursor matrix.
