# Product Onboarding O6D — Canonical Workout Persistence Cutover

**Status:** Completed  
**Tracker:** GitHub Issue #73 ✅  
**Parent O6:** #69  
**Predecessor O6C:** #72 ✅ / CI #1537  
**O6A contracts:** #70 ✅ / CI #1509  
**Successor O6E:** #74 ACTIVE  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Exact validated O6D source checkpoint

```text
01b3c36a13e2a40cdc55e25c544f66af8c39d7bb
Flutter CI #1552 / run 32590392127
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Tracker/docs commits after this SHA do not replace the exact validated O6D runtime/source checkpoint.

## Validated result

Product Onboarding completion now writes canonical Workout owners only:

```text
WorkoutOnboardingDraft → WorkoutProfileMapper → WorkoutProfileRepository.upsert
OnboardingDraft        → WorkoutTargetsMapper → WorkoutTargetsRepository.upsert
```

The broad `WorkoutPreferencesRepository` remains compatibility-only outside Product Onboarding. Product Onboarding no longer depends on or calls `saveWorkoutPreferences`.

### Workout Profile

```text
gymAccess        → workoutLocation
equipment        → availableEquipment
experienceLevel  → experienceLevel
focusAreas       → focusAreas
healthConcerns   → Set<String>?; trim; empty → null
```

No legacy gym/experience/focus/schedule defaults are fabricated. Explicit/null semantics are preserved.

### Workout Targets

The O6C mapper contract remains intact:

- training intents only;
- original unified rank 1/2 preserved;
- Body intents omitted;
- target answers lossless;
- Auto duration → null preferred minutes;
- empty event → null;
- event date null without source evidence.

## Validated persistence order

```text
Profile
→ Body
→ Wellness
→ Nutrition Profile (when active)
→ Workout Profile (when active)
→ Workout Targets (when active)
→ Nutrition Targets
→ confirmed App Mode / active_tabs
→ completion publication
```

Any Workout owner failure blocks all later owners and completion publication.

## Acceptance

- [x] strict Workout Profile mapper preserves explicit/null semantics;
- [x] existing O6C Workout Targets mapper contract remains intact;
- [x] Product Onboarding directly requires canonical Workout Profile + Targets repositories;
- [x] Workout Profile writes before Workout Targets;
- [x] Workout owner failures block later writes;
- [x] Product Onboarding no longer calls `saveWorkoutPreferences`;
- [x] canonical app providers use Supabase + in-memory fallback;
- [x] Workout/Hybrid setupNow write both owners;
- [x] Nutrition/Hybrid later write neither;
- [x] no DB/UI/navigation/formula/schema change;
- [x] four CI gates green on one exact source SHA.

## Exit

O6D is frozen at `01b3c36a13e2a40cdc55e25c544f66af8c39d7bb` / CI #1552. O6E integrated canonical Workout acceptance is ACTIVE on #74.