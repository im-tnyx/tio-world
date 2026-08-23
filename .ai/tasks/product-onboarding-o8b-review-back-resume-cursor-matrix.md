# Product Onboarding O8B — Review Back + Exact Resume Cursor Matrix

**Status:** Active  
**Tracker:** GitHub Issue #84  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
25fd96e7d43b8cf772a03883d5e9a48e32f8c9ab
Flutter CI #1607 / run 32626635975 / job 97162892798 ✅
Android Native CI #19 / run 32626635977 / job 97162895359 ✅
```

## Audit result

The current mode plans all end with:

```text
Nutrition Goals → Health Connections → Review
```

`OnboardingController.previous()` therefore appears to provide the correct Review back-chain. `_buildInitialState()` also retains valid Review checkpoints and valid active child cursors while reconciling invalid plan positions.

O8B adds explicit acceptance evidence rather than assuming that behavior from implementation shape.

## Scope

- Review → Health Connections Back matrix for Workout/Nutrition/Hybrid setupNow/Hybrid later;
- Health Connections → Nutrition Goals Back matrix with `nutritionTarget` cursor;
- saved Review checkpoint resume for every variant;
- representative exact nested-cursor resume for Wellness, Nutrition Profile and Workout Profile/Targets;
- no production change unless a focused test proves a real defect.

## Acceptance

- [ ] Review Back lands on Health Connections for all active variants;
- [ ] Back again lands on Nutrition Goals and exact `nutritionTarget` cursor;
- [ ] Review resumes at Review for all active variants;
- [ ] Wellness `waterTarget` resumes exactly;
- [ ] Nutrition Profile `allergiesRestrictions` resumes exactly when active;
- [ ] Workout Profile `focusAreas` resumes exactly when active;
- [ ] Workout Targets `specialEvent` resumes exactly when active;
- [ ] inactive branch state does not become a phantom active step;
- [ ] no production source change unless required by failing acceptance;
- [ ] all Flutter/Dart gates green on one exact source SHA.

## Guardrails

- no UI redesign;
- no schema/migration changes;
- no O8C invalidation changes;
- no fabricated defaults;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O8B exact CI evidence, then activate O8C edit-back invalidation + mode reconciliation.
