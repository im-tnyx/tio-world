# Product Onboarding O9B — Owner Write Failure + Retry Convergence

**Status:** Completed / validated  
**Tracker:** GitHub Issue #90 ✅ closed  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
d2898b56784fc815a6df893b504673641d20050e
Flutter CI #1627 / run 32636013590 / job 97185796250 ✅
Android Native CI #39 / run 32636013591 / job 97185787171 ✅
```

## Final exact validated checkpoint

```text
e287f5b8d2f1fa0f539cfe98b9f28a36971310e8
Flutter CI #1630 / run 32636442164 / job 97186849452 ✅
Android Native CI #42 / run 32636442150 / job 97186851647 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

Later task/tracker commits are documentation-only and do not replace this runtime/test checkpoint.

## Validated result

Independent canonical owner tables are not one transaction. O9B locks completion atomicity + retry convergence instead of claiming rollback.

The Hybrid `setupNow` fail-once Nutrition Targets acceptance proves:

- upstream successful Profile/Body/Wellness/Nutrition Profile/Workout Profile/Workout Targets upserts remain present after the late failure;
- no confirmed App Mode or remote/local onboarding completion publishes on the failed attempt;
- draft remains recoverable;
- retry safely replays owner upserts;
- recovered Nutrition Targets persists;
- completion publishes only after every required owner succeeds;
- successful retry clears the obsolete draft.

No production source change was required.

## Acceptance

- [x] late owner failure leaves already-successful upstream canonical values present;
- [x] failed attempt does not publish remote/local completion;
- [x] failed attempt does not clear draft;
- [x] retry safely repeats owner upserts and converges;
- [x] successful retry publishes completion only after owner success;
- [x] successful retry clears draft;
- [x] existing mode-specific/per-owner failure tests remain green;
- [x] no transaction/schema/migration rewrite;
- [x] all Flutter/Dart gates green on exact SHA;
- [x] Android native build green on same SHA.

## Exit

O9B is frozen on `e287f5b8d2f1fa0f539cfe98b9f28a36971310e8` / Flutter CI #1630 / Android Native CI #42. Continue O9C plan/recommendation publication + mode-specific semantics.
