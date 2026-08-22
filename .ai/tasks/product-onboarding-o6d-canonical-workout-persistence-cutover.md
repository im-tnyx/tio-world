# Product Onboarding O6D — Canonical Workout Persistence Cutover

**Status:** Active  
**Tracker:** GitHub Issue #73  
**Parent O6:** #69  
**Predecessor O6C:** #72 ✅ / CI #1537  
**O6A contracts:** #70 ✅ / CI #1509  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
e577605a97406ad10b9805a17be5f3474726d718
Flutter CI #1537 / run 32588799581
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Verified current source

`PersistOnboardingOwnerDataUseCase` still requires:

```dart
required workout_owner.WorkoutPreferencesRepository workoutRepository
```

and writes:

```dart
await _workoutRepository.saveWorkoutPreferences(workoutData);
```

Canonical owner contracts and implementations already exist:

```text
WorkoutProfileRepository
  SupabaseWorkoutProfileRepository
  InMemoryWorkoutProfileRepository

WorkoutTargetsRepository
  SupabaseWorkoutTargetsRepository
  InMemoryWorkoutTargetsRepository
```

`apps/app/lib/app/network_providers.dart` still exposes only the legacy `workoutPreferencesRepositoryProvider`; direct canonical Workout providers are not yet composed.

## Objective

Cut Product Onboarding completion to canonical Workout owners only:

```text
Workout Profile → WorkoutProfileRepository.upsert
Workout Targets → WorkoutTargetsRepository.upsert
```

The broad `WorkoutPreferencesRepository` may remain for non-onboarding compatibility, but Product Onboarding must stop depending on or writing through it.

## Strict Workout Profile mapping

Add `WorkoutProfileMapper`:

```text
gymAccess        → workoutLocation
equipment        → availableEquipment
experienceLevel  → experienceLevel
focusAreas       → focusAreas
healthConcerns   → Set<String>?; trim; empty → null
```

No fabricated defaults. Preserve unanswered/null semantics. Empty explicit sets remain empty where the canonical field is explicitly answered as an empty set; do not synthesize full-body/equipment/etc.

## Workout Targets mapping

Reuse O6C `WorkoutTargetsMapper` unchanged unless validation exposes a contract bug:

- training intents only;
- original rank 1/2 preserved;
- Body intents omitted;
- target answers lossless;
- Auto duration → null preferred minutes;
- empty event → null;
- event date null without source evidence.

## Required persistence order

```text
Profile
→ Body
→ Wellness
→ Nutrition Profile (when active)
→ Workout Profile (when active)
→ Workout Targets (when active)
→ Nutrition Targets
```

Any owner failure blocks all later owners and completion publication.

## Implementation slices

1. Add/export `WorkoutProfileMapper` + focused tests.
2. Replace broad Workout constructor/field in `PersistOnboardingOwnerDataUseCase` with canonical Profile + Targets repositories.
3. Persist Workout Profile then Workout Targets for Workout-active flows.
4. Remove Product Onboarding use of `WorkoutPreferencesMapper` and `saveWorkoutPreferences`.
5. Split owner error targets into `workoutProfile` and `workoutTargets`.
6. Add canonical app providers with Supabase/in-memory fallback.
7. Update app router/completion composition to pass both canonical Workout repositories.
8. Update persistence order/failure/provider composition tests.
9. Full exact-head four-gate CI.

## Guardrails

- no UI/navigation/flow/schema-v6/formula/eligibility change;
- no DB schema/migration/applied migration edit;
- no legacy table/column drop;
- no dual write to broad Workout owner;
- no fabricated Workout defaults;
- legacy broad repository retained only for non-onboarding compatibility;
- O6E blocked until exact O6D four-gate green;
- O11/#54 remains blocked until O10;
- PR #50 stays Draft/open/unmerged.

## Acceptance

- [ ] strict Workout Profile mapper preserves explicit/null semantics;
- [ ] existing O6C Workout Targets mapper contract remains intact;
- [ ] Product Onboarding directly requires canonical Workout Profile + Targets repositories;
- [ ] Workout Profile writes before Workout Targets;
- [ ] Workout owner failures block later writes;
- [ ] Product Onboarding no longer calls `saveWorkoutPreferences`;
- [ ] canonical app providers use Supabase + in-memory fallback;
- [ ] Workout/Hybrid setupNow write both owners;
- [ ] Nutrition/Hybrid later write neither;
- [ ] no DB/UI/navigation/formula/schema change;
- [ ] four CI gates green on one exact source SHA.

## Exit

Freeze exact O6D source SHA + CI evidence, close #73, update #69/#40/#44/#50 and durable trackers, then activate O6E integrated Workout acceptance.
