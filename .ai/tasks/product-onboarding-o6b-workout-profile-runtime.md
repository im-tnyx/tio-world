# Product Onboarding O6B — workoutProfile Runtime + Legacy Resume

**Status:** Completed / Validated  
**Tracker:** GitHub Issue #71 ✅  
**Parent O6:** #69  
**Predecessor O6A:** #70 ✅ / CI #1509  
**Successor O6C:** #72 ACTIVE  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10

## Exact validated O6B checkpoint

```text
48f0d1ff562fee7dda5647476ff706d1886dde11
Flutter CI #1511 / run 32585811984
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O6B activated `OnboardingStepId.workoutProfile` / `OnboardingSectionId.workoutProfile` for Workout and Hybrid setupNow while Nutrition/Hybrid later exclude it. The existing Workout child screens/order/validation were preserved.

Historical storage key `workoutPreferences` now decodes to canonical `workoutProfile`; new writes emit only `workoutProfile`. A source-compatibility alias keeps existing controller/resume/persistence callers on the same canonical enum value without duplicating active identities.

Hybrid `Later` continues to preserve Workout draft/owner data. `workoutTargets` stayed inactive in O6B. Broad `WorkoutPreferencesRepository` persistence remains until O6D.

**Frozen:** `48f0d1ff562fee7dda5647476ff706d1886dde11` / CI #1511.