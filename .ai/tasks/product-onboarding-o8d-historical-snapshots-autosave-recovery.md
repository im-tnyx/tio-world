# Product Onboarding O8D — Historical Snapshots + Autosave Recovery

**Status:** Complete ✅  
**Tracker:** GitHub Issue #86 ✅  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**O8B:** #84 ✅ / CI #1610  
**O8C:** #85 ✅ / CI #1614  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated checkpoint

```text
8f9ea1f2d4400cba7e22ec717e0cd0e88d555536
Flutter CI #1618 / run 32629448497 / job 97169828504 ✅
Android Native CI #30 / run 32629448489 / job 97169850346 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

## Validated outcome

Existing O4 compatibility remains intact: later historical top-level checkpoints stay later, and missing Wellness values keep numeric UI compatibility storage plus `has*Value=false` provenance. Canonical `WellnessTargetsMapper` continues mapping those historically absent values to `null`.

O8D fixed one narrow Review truth gap: historical unknown Steps/Hydration/Sleep now render `Not set` instead of displaying compatibility defaults as explicit user answers. Fresh/current drafts are unchanged because their starting Wellness values are already marked known.

Hydration/load failure preserves the safe seed state, failed autosave preserves active in-memory answers, and the next edit after repository recovery retries persistence successfully.

## Acceptance

- [x] historical unknown Steps/Hydration/Sleep are not fabricated in Review;
- [x] no forced rewind of otherwise-valid historical Review checkpoint;
- [x] all unknown Wellness provenance flags survive autosave/reload;
- [x] canonical Wellness mapper emits null for those unknown fields;
- [x] hydration failure leaves seed/in-memory state intact and `isHydrated=true`;
- [x] failed autosave does not erase active answer;
- [x] later recovered autosave persists newest answer;
- [x] no schema-version bump or migration edit;
- [x] all Flutter/Dart gates green on one exact SHA;
- [x] Android native debug build green on same SHA.

## Source/evidence

```text
apps/features/onboarding/lib/src/presentation/screens/review/review_screen.dart
apps/features/onboarding/test/presentation/o8d_historical_snapshot_autosave_acceptance_test.dart
```

## Guardrails preserved

- no compatibility default promotion to canonical truth;
- no historical checkpoint rewind solely because provenance is unknown;
- no broad resume/navigation rewrite;
- no schema/migration change;
- PR #50 remains Draft/open/unmerged.

## Exit

O8D frozen complete. Activate O8E integrated O8 acceptance.
