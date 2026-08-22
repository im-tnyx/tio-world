# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3 complete; O4 Wellness ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ✅ closed  
**O3 Body Goal:** #55 ✅ closed / CI #1354  
**O4 Wellness:** #58 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Current validated foundation

```text
Section/step identity foundation                 ✅ CI #945
Target Weight eligibility/draft                  ✅ CI #1079
Goal Pace ownership/skipped cleanup              ✅ CI #1090
Integrated Goal/weight acceptance                ✅ CI #1095
Canonical Body onboarding writes                 ✅ CI #1135
Canonical Body read/history                      ✅ CI #1153
Canonical owner schema + P1 Profile/App Prefs    ✅ LIVE
O1 durable App Mode / active_tabs                ✅ CI #1240
O2 common User Profile end-to-end                ✅ CI #1279
O3A Body Goal typed child-flow                   ✅ CI #1290
O3B bodyGoal runtime section + legacy resume     ✅ CI #1319
O3C Goal Pace placement/parity                   ✅ CI #1345
O3D integrated canonical Body acceptance         ✅ CI #1354
```

O3 final exact source checkpoint:

```text
75237e6c31222f4b08f3cdd41353121aa1ca3afc
Flutter CI #1354 / run 32562632629
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

Onboarding orchestrates; it does not own durable domain data. Applied migrations are immutable and legacy duplicate columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
O2 common User Profile owner + section         ✅ #53 / CI #1279
O3 Body Goal section + Profile/Body parity     ✅ #55 / CI #1354
→ O4 Wellness placement + owner                ACTIVE #58
→ O5 Nutrition Profile + Targets               BLOCKED by O4
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                 BLOCKED #54
```

Only one Product Onboarding slice/sub-slice is active at a time.

## O3 — COMPLETE

Final Body boundary:

```text
body_weight_logs → Current Weight/history
user_body_goals  → Body Goal + Target Weight + Goal Pace
```

O3D integrated acceptance also removed ongoing Body mirrors from Nutrition persistence while leaving legacy stored mirrors read-compatible until O11.

## O4 — Wellness placement + canonical owner

Parent task: `.ai/tasks/product-onboarding-o4-wellness.md`  
Tracker: #58.

Canonical durable target:

```text
user_wellness_targets
→ steps_target
→ water_target_ml
→ sleep_target_minutes
→ bed_time
→ wake_up_time
```

O4 starts with an audit of the current Targets child flow, serialized draft, validators/screens, persistence adapters and Nutrition calculation dependencies. The audit must produce one focused O4A sub-slice before source edits.

Expected end state:
- Wellness has a distinct runtime semantic boundary;
- Wellness writes go through the canonical Wellness owner only;
- Nutrition can consume Wellness values as calculation inputs without durable ownership;
- legacy serialized resume remains safe;
- legacy schema mirrors remain until O11 rather than being dropped during O4;
- integrated Wellness read/write/resume/failure acceptance is green before O5.

## Guardrails

- preserve existing onboarding UI/picker contracts where possible;
- one canonical durable owner per concept;
- no fabricated semantic defaults;
- no anonymous-auth side effects for canonical owner writes;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drop before O10/O11;
- do not start O5 until O4 integrated acceptance is recorded.

## Handoff

**O4 is ACTIVE on #58 from validated O3 source `75237e6c…` / CI #1354. Audit first, then create one focused O4A task/issue before source changes.**
