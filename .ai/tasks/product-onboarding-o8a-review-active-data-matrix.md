# Product Onboarding O8A — Review Active-data Mode Matrix

**Status:** Completed / validated  
**Tracker:** GitHub Issue #83 ✅  
**Parent O8:** #82  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**O11 cleanup:** #54 BLOCKED until O10

## Exact validated checkpoint

```text
25fd96e7d43b8cf772a03883d5e9a48e32f8c9ab
Flutter CI #1607 / run 32626635975 / job 97162892798 ✅
Android Native CI #19 / run 32626635977 / job 97162895359 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

## Validated result

Review active/dormant behavior is frozen as:

```text
Workout             → active Workout Plan visible ✅
Nutrition           → seeded dormant Workout data hidden ✅
Hybrid setupNow     → active Workout Plan visible ✅
Hybrid later        → seeded dormant Workout data hidden ✅
```

The focused acceptance test intentionally retains Workout draft data in inactive branches and proves Review hides it without deleting it.

Existing protections remain green:

- dormant/incompatible Target Weight stays hidden;
- inactive Goal Pace stays hidden;
- O7 Health Review never fabricates `connected`;
- no Review visual/copy change.

## Source result

O8A required no production source change. Added evidence only:

```text
apps/features/onboarding/test/presentation/o8a_review_active_data_acceptance_test.dart
```

## Acceptance

- [x] all four App Mode / Hybrid branch variants explicitly tested;
- [x] inactive Workout data remains preserved but absent from Review UI;
- [x] active Workout data is visible in Review;
- [x] existing weight-direction dormant-data tests remain green;
- [x] O7 Health Review truth tests remain green;
- [x] no production source change required;
- [x] all Flutter/Dart gates green on one exact SHA;
- [x] Android native debug build green on the same SHA.

## Exit

O8A is frozen complete. Next slice: O8B Review Back + exact resume cursor matrix.
