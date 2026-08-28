# Product Onboarding O8C — Edit-back Invalidation + Mode Reconciliation

**Status:** Complete ✅  
**Tracker:** GitHub Issue #85 ✅  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**O8B:** #84 ✅ / CI #1610  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated checkpoint

```text
1591b37649a8e1d7913bf7322b200522db5773d1
Flutter CI #1614 / run 32628899085 / job 97168479612 ✅
Android Native CI #26 / run 32628899057 / job 97168479439 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

The initial O8C acceptance commit failed analyze only because two test-only `const ProfileOnboardingDraft(...)` invocations called a non-const constructor. The exact accepted checkpoint removes those invalid `const` keywords. No production source change was required.

## Validated contract

- Goal selection semantic changes invalidate Body Goal + dependent Workout Targets;
- inactive Target Weight may remain dormant but no active weight direction is claimed;
- App Mode changes filter completion checkpoints against the destination active plan;
- mode-induced Goal reconciliation rewinds a post-Goal cursor to `bodyGoal / goal` when needed;
- Hybrid setupNow/later toggles remove/add active Workout branches without deleting Workout draft answers;
- reactivating Workout never fabricates completed Workout steps;
- ordinary common Profile edits invalidate Profile ownership only rather than blindly clearing later valid progress.

## Acceptance

- [x] Goal semantic change removes `bodyGoal` + `workoutTargets` completion checkpoints;
- [x] dormant Target Weight remains stored when inactive but no active weight direction is claimed;
- [x] Hybrid setupNow → later removes Workout Profile/Targets from active plan/completions while preserving Workout draft data;
- [x] Hybrid later → setupNow restores Workout steps without inventing completion;
- [x] Hybrid → Nutrition filters ineligible Workout checkpoints and preserves dormant Workout data;
- [x] mode-induced Goal reconciliation rewinds to `bodyGoal / goal` when required;
- [x] harmless Profile edit invalidates Profile only and preserves unrelated later completed checkpoints;
- [x] no production source change required;
- [x] all Flutter/Dart gates green on one exact source SHA;
- [x] Android native debug build green on the same SHA.

## Guardrails preserved

- no destructive dormant-data clearing;
- no broad navigation/resume rewrite;
- no schema/migration changes;
- no fabricated defaults;
- PR #50 remains Draft/open/unmerged.

## Exit

O8C is frozen complete. Activate O8D historical snapshots + autosave/failure acceptance.
