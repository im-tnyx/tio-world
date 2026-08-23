# Product Onboarding O8E — Integrated Review / Resume / Edit-back Acceptance

**Status:** Active  
**Tracker:** GitHub Issue #87  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**O8B:** #84 ✅ / CI #1610  
**O8C:** #85 ✅ / CI #1614  
**O8D:** #86 ✅ / CI #1618  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
8f9ea1f2d4400cba7e22ec717e0cd0e88d555536
Flutter CI #1618 / run 32629448497 / job 97169828504 ✅
Android Native CI #30 / run 32629448489 / job 97169850346 ✅
```

## Scope

Final cross-slice O8 acceptance only. Do not introduce O9 behavior.

Integrated scenario:

1. hydrate a valid Hybrid setupNow draft at Review;
2. Back navigation moves visibly to Health Connections while durable resume remains at the furthest valid Review checkpoint;
3. a new session resumes Review;
4. switch Hybrid setupNow → later;
5. active Workout Profile/Targets steps and completion checkpoints disappear;
6. Workout owner answers remain dormant/preserved;
7. persist and rehydrate again;
8. inactive Workout steps remain inactive and dormant answers remain preserved.

The full CI suite on this exact checkpoint must also keep O8A–O8D focused acceptance green, including Review truth, historical provenance and autosave recovery.

## Acceptance

- [ ] visible Back does not regress durable Review resume;
- [ ] new session resumes Review;
- [ ] Hybrid later removes active Workout branch/completions;
- [ ] Workout owner answers remain preserved;
- [ ] rehydration does not resurrect inactive Workout steps;
- [ ] O8A–O8D focused tests remain green together;
- [ ] no O9/O10/O11 source work;
- [ ] all Flutter/Dart gates green on exact SHA;
- [ ] Android native debug build green on same SHA.

## Guardrails

- no schema/owner expansion;
- no Health Connect permission/data-sync expansion;
- no destructive dormant-data clearing;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Exit

Freeze exact O8E CI evidence, close #87 and parent #82, align #40/#44/PR #50 to O8 complete, then activate O9 Plan Building / Finalization.
