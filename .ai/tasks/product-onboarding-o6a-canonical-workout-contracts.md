# Product Onboarding O6A — Canonical Workout Owner Contracts

**Status:** Completed / Validated  
**Tracker:** GitHub Issue #70 ✅  
**Parent O6:** #69  
**Successor O6B:** #71 ✅ / CI #1511  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10

## Exact validated O6A checkpoint

```text
cd764653146d4514fb4e56ef893e92846327ae2e
Flutter CI #1509 / run 32584462360
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O6A established explicit canonical contracts and signed-out fail-closed Supabase adapters:

```text
WorkoutProfileRepository → user_workout_profiles
WorkoutTargetsRepository → user_workout_targets
```

Workout Profile owns location/equipment/experience/focus/health context. Workout Targets owns ordered training goals/ranks, training days, duration, split and special-event target fields. Canonical adapters do not perform anonymous auth or legacy fallback writes.

The existing broad `WorkoutPreferencesRepository` remains compatibility-only until O6D. No onboarding runtime/UI/schema change occurred in O6A.

**Frozen:** `cd764653146d4514fb4e56ef893e92846327ae2e` / CI #1509.