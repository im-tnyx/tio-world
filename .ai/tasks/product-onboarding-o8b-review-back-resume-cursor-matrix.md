# Product Onboarding O8B — Review Back + Exact Resume Cursor Matrix

**Status:** Completed / validated  
**Tracker:** GitHub Issue #84 ✅  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated checkpoint

```text
edadb3dcd3058e5b22fd54205e16fd0a9c79d3a2
Flutter CI #1610 / run 32627021475 / job 97163818826 ✅
Android Native CI #22 / run 32627021473 / job 97163818370 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

## Validated result

For Workout, Nutrition, Hybrid setupNow and Hybrid later:

```text
Review
→ Back → Health Connections
→ Back → Nutrition Goals / nutritionTarget
```

Exact resume behavior is also frozen:

- Review resumes at Review for all active variants;
- Wellness `waterTarget` resumes exactly;
- Nutrition Profile `allergiesRestrictions` resumes exactly when active;
- Workout Profile `focusAreas` resumes exactly when active;
- Workout Targets `specialEvent` resumes exactly when active;
- Hybrid `later` never resurrects dormant Workout Profile/Targets as active steps;
- dormant Workout data remains preserved.

## Source result

O8B required no production source change. Added acceptance evidence only:

```text
apps/features/onboarding/test/presentation/o8b_review_back_resume_acceptance_test.dart
```

## Acceptance

- [x] Review Back lands on Health Connections for all active variants;
- [x] Back again lands on Nutrition Goals and exact `nutritionTarget` cursor;
- [x] Review resumes at Review for all active variants;
- [x] Wellness `waterTarget` resumes exactly;
- [x] Nutrition Profile `allergiesRestrictions` resumes exactly when active;
- [x] Workout Profile `focusAreas` resumes exactly when active;
- [x] Workout Targets `specialEvent` resumes exactly when active;
- [x] inactive branch state does not become a phantom active step;
- [x] no production source change required;
- [x] all Flutter/Dart gates green on one exact SHA;
- [x] Android native debug build green on the same SHA.

## Exit

O8B is frozen complete. Next slice: O8C edit-back invalidation + mode reconciliation.
