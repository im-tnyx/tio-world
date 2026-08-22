# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3 complete; O4B Wellness runtime ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ✅ closed  
**O3 Body Goal:** #55 ✅ closed / CI #1354  
**O4 Wellness:** #58 ACTIVE  
**O4A:** #59 ✅ closed / CI #1365  
**O4B:** #60 ACTIVE  
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
```

O4A exact source checkpoint:

```text
f244b4913143ba8f76439a8b2554fd095d7e1973
Flutter CI #1365 / run 32563623833
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

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
   O4B runtime Wellness section/resume          ACTIVE #60
   O4C persistence + Nutrition mirror cutoff   BLOCKED
   O4D integrated acceptance                   BLOCKED
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

`tio_feature_progress` now provides `WellnessTargetsData`, `WellnessTargetsRepository`, an in-memory implementation, and a Supabase adapter targeting only `public.user_wellness_targets`. Canonical reads preserve nulls and fail strictly on malformed state; signed-out writes fail closed with no anonymous auth side effect.

## O4B — ACTIVE

Focused task: `.ai/tasks/product-onboarding-o4b-wellness-section-resume.md`  
Tracker: #60.

Target runtime:

```text
wellnessGoals: Bridge → Step Target → Sleep Target → Water Target
targets:        Nutrition Target
```

O4B reuses existing `TargetStepId` and `TargetsOnboardingDraft` compatibility storage while moving top-level runtime/navigation/progress ownership. Legacy actual Targets Wellness cursors migrate to `wellnessGoals`; later checkpoints remain later with dormant Wellness values.

## Guardrails

- preserve existing screens/picker contracts;
- no persistence changes in O4B;
- no Nutrition Wellness mirror cutoff until O4C;
- no fabricated semantic defaults in canonical repositories;
- no permanent dual-write synchronization;
- no applied migration edits or legacy-column drop;
- O4C starts only after exact O4B full CI green;
- O5 stays blocked until O4D.

## Handoff

**Execute O4B only on #60 from validated O4A source `f244b491…` / CI #1365.**
