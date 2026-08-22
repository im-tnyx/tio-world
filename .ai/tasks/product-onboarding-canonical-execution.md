# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1–O6 complete; O7 Health Connections ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O6 Workout:** #69 ✅ / CI #1555  
**O7 Health Connections:** #75 ACTIVE  
**O7A:** #76 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest exact validated source checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6 source/runtime checkpoint. O7A docs/tracker commits do not replace it.

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

Health Connections durable authorization/connection ownership is intentionally unresolved until O7A/O7D prove the correct boundary. Imported sensitive health records do not belong in `onboarding_drafts`.

Applied migrations are immutable. Legacy duplicate/mixed columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                            ✅ #11 / CI #1240
O2 common User Profile owner + section            ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity        ✅ #55 / CI #1354
O4 Wellness placement + canonical owner           ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                    ✅ #63 / CI #1507
O6 Workout Profile + Targets                      ✅ #69 / CI #1555
→ O7 Health Connections                           ACTIVE #75
   → O7A capability + product contract readiness ACTIVE #76
   O7B runtime section + approved UI/content
   O7C Android Health Connect adapter
   O7D persistence/resume/review integration
   O7E integrated acceptance
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                    BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Validated through O6

Canonical Workout runtime:

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

Canonical completion writes:

```text
WorkoutProfileRepository → user_workout_profiles
WorkoutTargetsRepository → user_workout_targets
```

O6E #74 / CI #1555 validated Workout/Hybrid setupNow, Hybrid later preservation, Nutrition exclusion, schema-v6/pre-v6 resume compatibility, fail-closed owner ordering, retry/idempotency, and no Product Onboarding broad Workout writer fallback.

## O7 source readiness audit

The reserved identities already exist:

```text
OnboardingStepId.healthConnections
OnboardingSectionId.healthConnections
```

but runtime activation is intentionally absent:

- `BuildOnboardingFlowUseCase` schedules no Health Connections step;
- `OnboardingCompatibilitySection` rejects it through the future-step guard;
- `OnboardingDraft` stores no Health Connections state;
- `apps/app/pubspec.yaml` has no Health Connect/HealthKit integration package;
- Android app manifest has no Health Connect health-data permission/configuration;
- the current phone app tree on this branch has no iOS Runner scaffold for HealthKit.

## O7A — ACTIVE #76

Focused task: `.ai/tasks/product-onboarding-o7a-health-connections-contract.md`.

O7A is non-visual and permission-side-effect free. Proposed minimum product-safe capability vocabulary:

```text
unavailable
notRequested
denied
connected
```

Only a real platform adapter result may establish `connected`. Onboarding orchestration choice must remain separate from live OS authorization truth.

Ownership proposal:

```text
Product Onboarding
  → step eligibility / skip-or-attempt orchestration / resume checkpoint only

Platform health adapter
  → live capability + authorization truth

Durable per-device connection metadata
  → unresolved until O7D proves the correct owner

Imported health / biometric records
  → future dedicated health/sync domain, never onboarding draft payload
```

## O7B blockers

Do not activate `healthConnections` in the planner until all are resolved:

- product confirms whether skip/denial/unavailable are completion-blocking or non-blocking;
- visible screen content/actions/options are approved;
- exact placement relative to Nutrition Targets / Review is confirmed;
- platform-unavailable presentation is defined;
- explicit Connect action semantics are defined;
- real renderer/section exists before scheduling.

Architecture recommendation: Health Connections should be optional/non-blocking because OS support or permission may be unavailable/denied. This remains a product decision and must not be silently encoded.

## Guardrails

- no fake health connection success;
- no health permission request in O7A;
- no new visible screen/copy/options without approval;
- no health plugin/manifest/schema mutation in O7A;
- no sensitive health-data duplication/logging;
- no applied migration edits or legacy-column drops;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**Execute/freeze O7A #76 only. Frozen predecessor source checkpoint: `d56e8226f8631bc81d3dd309cbb22c631ca636f5` / Flutter CI #1555. O7B remains blocked on the explicit product/UI decisions above.**
