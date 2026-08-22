# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1–O6 complete; O7 ACTIVE with O7B blocked on explicit approval  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O6 Workout:** #69 ✅ / CI #1555  
**O7 Health Connections:** #75 ACTIVE  
**O7A:** #76 ✅  
**O7B:** #77 BLOCKED  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged

## Latest exact validated source checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O7A is contract/tracker-only; this remains the exact runtime checkpoint.

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context only
user_nutrition_targets     → calories/macros/fiber + customization state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Health Connections authorization/connection ownership is intentionally unresolved until O7D proves the correct durable boundary. Imported sensitive health records do not belong in `onboarding_drafts`.

## Execution order

```text
O1 App Mode durability                            ✅ #11 / CI #1240
O2 common User Profile owner + section            ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity        ✅ #55 / CI #1354
O4 Wellness placement + canonical owner           ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                    ✅ #63 / CI #1507
O6 Workout Profile + Targets                      ✅ #69 / CI #1555
→ O7 Health Connections                           ACTIVE #75
   O7A capability + product contract readiness    ✅ #76
   O7B runtime section + approved UI/content       BLOCKED #77
   O7C Android Health Connect adapter
   O7D persistence/resume/review integration
   O7E integrated acceptance
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                    BLOCKED #54
```

Only one Product Onboarding implementation slice may be active at a time. Because O7B is blocked, no later O7 slice starts early.

## Validated through O6

Canonical Workout runtime/persistence is frozen:

```text
runtime:     workoutProfile → workoutTargets
persistence: WorkoutProfileRepository → WorkoutTargetsRepository
```

O6E #74 / CI #1555 validated mode matrix, Hybrid later preservation, resume compatibility, fail-closed owner order, retry/idempotency and no broad Workout completion writes.

## O7A completed contract — #76

Current source only reserves Health Connections identity. No real Health Connect/HealthKit plugin, Android health permission configuration, Health Connections draft state, active adapter or iOS Runner scaffold exists in this branch.

Minimum safe capability proposal:

```text
unavailable
notRequested
denied
connected
```

Only a live platform adapter may establish `connected`.

Ownership:

```text
Product Onboarding
  → orchestration only
Platform health adapter
  → live capability + authorization truth
Durable connection metadata
  → unresolved until O7D
Imported health records
  → dedicated future health/sync domain
```

## O7B blocked contract — #77

Before planner/renderer/UI source changes, explicit approval is required for:

- whether Skip / unavailable / denied-cancelled are non-blocking;
- title/copy/actions and Connect/Skip behavior;
- connected/unavailable/denied/retry presentation;
- exact flow placement.

Architecture recommendation:

```text
Health Connections = optional / non-blocking / retryable later
Placement = Nutrition Targets → Health Connections → Review
```

These are recommendations only and are not encoded until approved.

## Guardrails

- no fake health connection success;
- no passive OS health permission request;
- no new visible Health Connections screen/content without approval;
- no plugin/manifest/schema mutation outside its focused slice;
- no sensitive health-data duplication/logging;
- no applied migration edits or legacy-column drops;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**O7A #76 is complete. O7B #77 is the next implementation slice but remains blocked pending the explicit approvals above. Do not start O7C/O7D/O7E early.**
