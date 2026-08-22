# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3 complete; O4C Wellness persistence NEXT  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ✅ closed  
**O3 Body Goal:** #55 ✅ closed / CI #1354  
**O4 Wellness:** #58 ACTIVE  
**O4A:** #59 ✅ closed / CI #1365  
**O4B:** #60 ✅ validated / CI #1405  
**O4C:** NEXT  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Current validated foundation

```text
O1 durable App Mode / active_tabs                ✅ CI #1240
O2 common User Profile end-to-end                ✅ CI #1279
O3 canonical Body Goal end-to-end                ✅ CI #1354
O4A canonical Wellness repository contract       ✅ CI #1365
O4B Wellness runtime/navigation/resume            ✅ CI #1405
```

O4B exact validated source checkpoint:

```text
fc795e6411fe303d6381441c3ba872f99d522977
Flutter CI #1405 / run 32567404925
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

A later docs-only checkpoint records O4B closure; runtime validation remains anchored to the exact source SHA above.

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context
user_nutrition_targets     → nutrition targets
user_workout_profiles      → workout context
user_workout_targets       → workout targets
onboarding_drafts          → draft/resume orchestration only
```

Applied migrations are immutable. Legacy duplicate columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
O2 common User Profile owner + section         ✅ #53 / CI #1279
O3 Body Goal section + Profile/Body parity     ✅ #55 / CI #1354
→ O4 Wellness placement + owner                ACTIVE #58
   O4A canonical repository contract           ✅ #59 / CI #1365
   O4B runtime Wellness section/resume          ✅ #60 / CI #1405
   O4C persistence + Nutrition mirror cutoff   NEXT
   O4D integrated acceptance                   BLOCKED by O4C
→ O5 Nutrition Profile + Targets               BLOCKED by O4
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                 BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O4A — VALIDATED

`tio_feature_progress` provides `WellnessTargetsData`, `WellnessTargetsRepository`, an in-memory implementation, and a Supabase adapter targeting only `public.user_wellness_targets`. Canonical reads preserve nulls and fail strictly on malformed state; signed-out writes fail closed with no anonymous auth side effect.

## O4B — VALIDATED

Focused task: `.ai/tasks/product-onboarding-o4b-wellness-section-resume.md`  
Tracker: #60.

Validated runtime:

```text
wellnessGoals: Bridge → Step Target → Sleep Target → Water Target
targets:        Nutrition Target
```

Existing `TargetStepId` and `TargetsOnboardingDraft` remain compatibility storage while semantic runtime/navigation/progress ownership is Wellness. Legacy actual Targets Wellness cursors migrate to `wellnessGoals`; later checkpoints remain later with dormant Wellness values.

## O4C — NEXT

O4C must cut durable Wellness writes to the canonical owner without redesigning screens or dropping legacy columns.

Verified starting gap:

```text
PersistOnboardingOwnerDataUseCase
  currently writes Profile → Body → Workout(if active) → Targets
  does not receive WellnessTargetsRepository yet

TargetsSetupMapper
  still carries dailySteps / sleep / water / bed / wake into Nutrition TargetsSetupData

SupabaseTargetsSetupRepository
  still writes those Wellness fields to user_nutrition_profiles
  and can fall back to legacy user_targets

SupabaseWellnessTargetsRepository
  already targets only user_wellness_targets
  and supports explicit nullable clears
```

Required O4C direction:

```text
Onboarding Wellness draft values
        ↓ dedicated Wellness mapper
WellnessTargetsRepository.upsert
        ↓
public.user_wellness_targets

Nutrition persistence
        ↓
may consume Wellness values for recommendation inputs
but must stop durable Wellness mirror writes
```

O4C must preserve safe compatibility reads required by current downstream code; physical column removal is O11 only.

## Guardrails

- preserve existing screens/picker contracts;
- no fabricated semantic defaults in canonical repositories;
- no permanent dual-write synchronization;
- no applied migration edits or legacy-column drop;
- legacy reads may remain compatibility-only until later cutovers/O11;
- O5 stays blocked until O4D integrated acceptance;
- PR #50 remains Draft/open/unmerged through O4.

## Handoff

**Start one focused O4C issue/task from the validated O4B runtime checkpoint. Do not begin O5 or schema cleanup.**