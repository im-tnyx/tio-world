# Product Onboarding O6C — workoutTargets Runtime + Ordered Workout Goals

**Status:** Active  
**Tracker:** GitHub Issue #72  
**Parent O6:** #69  
**Predecessor O6B:** #71 ✅ / CI #1511  
**O6A contracts:** #70 ✅ / CI #1509  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
48f0d1ff562fee7dda5647476ff706d1886dde11
Flutter CI #1511 / run 32585811984
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Objective

Activate canonical `workoutTargets` after `workoutProfile`, partition the existing Workout screens by canonical owner, migrate broad O6B/legacy drafts safely, and map ordered unified Goal intents into O6A `WorkoutTargetsData`.

Canonical runtime order for Workout/Hybrid setupNow:

```text
workoutProfile
  gymAccess
  equipment (home only)
  experienceLevel
  focusAreas
  healthConcerns
→ workoutTargets
  trainingDays
  workoutDuration
  workoutSplit
  specialEvent
```

`healthConcerns` moves immediately after `focusAreas` so Profile-owned context stays contiguous. Screen widget/copy/options/validation values remain unchanged.

Nutrition and Hybrid `Later` contain neither Workout section. Hybrid `Later` preserves existing Workout draft/owner data.

## Ordered Workout-goal mapping

Source: `GoalIntentSelection`.

Only training intents map to canonical Workout Targets:

```text
buildMuscle      → WorkoutTargetGoal.buildMuscle
getStronger      → WorkoutTargetGoal.getStronger
improveEndurance → WorkoutTargetGoal.improveEndurance
stayFit          → WorkoutTargetGoal.stayFit
```

Body-direction intents are omitted. Preserve original unified rank: primary = 1, supporting = 2. If only the supporting unified goal is a training intent, store it as the first canonical Workout goal with rank 2; never relabel it to rank 1. No training intent means null Workout goal fields.

Explicit target answers map losslessly:

```text
trainingDays
workoutDuration: Auto → preferredDurationMins null; explicit durations → minutes
workoutSplit
specialEvent: trim; empty → null
specialEventDate: null (no onboarding source)
```

## Persisted draft schema v6 migration

Source audit corrected the initial task assumption: the durable `schema_version` is owned by `OnboardingDraftSnapshot`, whose current version is already **5**. `OnboardingDraft.currentSchemaVersion` is not the persisted snapshot boundary used by the DTO mapper.

O6B already emits canonical `workoutProfile` while snapshot schema v5 is live, so O6C advances:

```text
OnboardingDraftSnapshot.currentSchemaVersion
5 → 6
```

For persisted snapshot schema v1–v5 only:

- broad current `workoutPreferences`/`workoutProfile` with a Targets-owned child cursor → `workoutTargets`;
- broad completed `workoutPreferences`/`workoutProfile` → completed `workoutProfile` + `workoutTargets`;
- Profile-owned cursors remain `workoutProfile`.

New v6 partial completion must remain exact: completed `workoutProfile` must not auto-complete `workoutTargets`.

Historical `workoutPreferences` stays decode-only; new saves remain canonical.

## Implementation slices

1. Extend Workout flow ownership helpers with canonical Profile/Targets child subsets.
2. Activate `workoutTargets` in eligible top-level flows.
3. Advance persisted snapshot schema to v6 and add pre-v6 broad-Workout migration.
4. Split progress/next/back/completed invalidation/resume checkpoint behavior by active Workout subsection.
5. Render existing Workout screens for both canonical Workout sections.
6. Add `WorkoutTargetsMapper` with strict ordered-goal mapping and no fabricated defaults.
7. Add focused mode/order/schema-migration/navigation/mapper tests.
8. Run exact full four-gate CI.

## Guardrails

- no visual redesign/copy rewrite/field addition or removal;
- only the documented owner-driven `healthConcerns` ordering adjustment;
- no canonical Workout persistence cutover in O6C;
- broad `WorkoutPreferencesRepository` remains completion compatibility until O6D;
- no DB schema/migration change;
- no legacy-column drop;
- no permanent dual write;
- no fabricated Workout goal/duration/event date/default;
- O6D waits for exact O6C four-gate green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Acceptance

- [ ] Workout + Hybrid setupNow use `workoutProfile → workoutTargets`;
- [ ] Nutrition + Hybrid later exclude both Workout sections;
- [ ] child ownership/order matches the canonical split above;
- [ ] pre-v6 broad Workout cursors/completion migrate losslessly;
- [ ] schema v6 partial completion stays partial;
- [ ] ordered training goals preserve original rank and omit Body intents;
- [ ] no Workout goal/default/event date is fabricated;
- [ ] progress/back/next/resume remain continuous;
- [ ] existing broad completion persistence remains unchanged;
- [ ] no DB/UI/formula change;
- [ ] four CI gates green on one exact source SHA.

## Exit

Freeze exact O6C source SHA + CI evidence, close #72, update #69/#40/#44/#50 and durable trackers, then activate O6D canonical Workout persistence cutover.