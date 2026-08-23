# Product Onboarding O8C — Edit-back Invalidation + Mode Reconciliation

**Status:** Active  
**Tracker:** GitHub Issue #85  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**O8B:** #84 ✅ / CI #1610  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
edadb3dcd3058e5b22fd54205e16fd0a9c79d3a2
Flutter CI #1610 / run 32627021475 / job 97163818826 ✅
Android Native CI #22 / run 32627021473 / job 97163818370 ✅
```

Later task/tracker-only commits do not replace this runtime checkpoint.

## Audit result

O8C must distinguish semantic invalidation from harmless review edits.

Current controller contract:

- Goal selection changes invalidate Body Goal + Workout Targets because both derive meaning from unified Goal intent;
- inactive Target Weight/Pace may remain dormant for a later compatible return but must not act as active truth;
- App Mode changes filter completed steps to the destination active plan;
- mode-induced Goal reconciliation rewinds a post-Goal cursor to `bodyGoal / goal` when the previous Goal selection is no longer meaning-preserving;
- Hybrid setupNow/later toggles remove/add active Workout branches without deleting Workout draft answers;
- reactivating a branch must not fabricate completed steps;
- ordinary common Profile edits invalidate Profile ownership only; canonical Nutrition Targets recalculate from current inputs at persistence time.

## Scope

Add focused controller acceptance tests for semantic invalidation, Hybrid branch toggles, App Mode reconciliation and harmless edit behavior. Change production source only if a focused acceptance case proves a defect.

## Acceptance

- [ ] Goal semantic change removes `bodyGoal` + `workoutTargets` completion checkpoints;
- [ ] dormant Target Weight remains stored when inactive but no active weight direction is claimed;
- [ ] Hybrid setupNow → later removes Workout Profile/Targets from active plan/completions while preserving Workout draft data;
- [ ] Hybrid later → setupNow restores Workout steps without inventing completion;
- [ ] Hybrid → Nutrition filters ineligible Workout checkpoints and preserves dormant Workout data;
- [ ] mode-induced Goal reconciliation rewinds to `bodyGoal / goal` when required;
- [ ] harmless Profile edit invalidates Profile only and preserves unrelated later completed checkpoints;
- [ ] no production change unless acceptance exposes a real mismatch;
- [ ] all Flutter/Dart gates green on one exact source SHA.

## Guardrails

- no destructive dormant-data clearing;
- no broad navigation/resume rewrite;
- no schema/migration changes;
- no O8D/O9 work;
- no fabricated defaults;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O8C exact CI evidence, then activate O8D historical snapshots + autosave/failure acceptance.
