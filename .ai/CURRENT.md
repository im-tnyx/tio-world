# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-23.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o7a-health-connections-contract.md`
4. GitHub Issues #76/#75/#40/#44 and Draft PR #50
5. `.ai/tasks/product-onboarding-o6e-integrated-workout-acceptance.md` for the frozen predecessor acceptance context

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
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

Legacy mixed columns remain temporarily. Destructive cleanup is O11/#54 and stays blocked until O10 acceptance.

Health Connections durable ownership is intentionally not assigned yet. O7A separates onboarding orchestration from live platform authorization and imported sensitive health records before any schema choice.

## Latest exact validated Product Onboarding checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6 runtime/source checkpoint. O7A tracker/task-only commits do not replace exact runtime validation.

## Current sequence

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                   ✅ #63 / CI #1507
O6 Workout Profile + Targets                     ✅ #69 / CI #1555
→ O7 Health Connections                          ACTIVE #75
   → O7A capability + product contract readiness ACTIVE #76
   O7B runtime section + approved UI/content
   O7C Android Health Connect adapter
   O7D persistence/resume/review integration
   O7E integrated acceptance
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Validated through O6

Canonical Workout is fully split and validated:

```text
runtime:     workoutProfile → workoutTargets
persistence: WorkoutProfileRepository → WorkoutTargetsRepository
```

O6E #74 / CI #1555 validated Workout first-run behavior, Hybrid setupNow, Hybrid later preservation, Nutrition exclusion, resume compatibility, fail-closed owner ordering, retry/idempotency, and continued absence of Product Onboarding writes through the broad Workout preferences repository.

## Current O7A objective

Health Connections is only a reserved identity today:

- it is not scheduled by `BuildOnboardingFlowUseCase`;
- the compatibility renderer intentionally rejects it as a future step;
- no Health Connections state exists in `OnboardingDraft`;
- the phone app has no Health Connect/HealthKit integration package;
- Android has no Health Connect health-data permission configuration;
- this branch has no iOS Runner scaffold for HealthKit wiring.

O7A is therefore non-visual and permission-side-effect free. The focused task `.ai/tasks/product-onboarding-o7a-health-connections-contract.md` defines:

```text
capability: unavailable / notRequested / denied / connected
onboarding choice: separate from live OS authorization truth
platform adapter: live capability/authorization owner
durable connection metadata: unresolved until O7D
imported health records: never onboarding-draft data
```

The recommended Product Onboarding behavior is optional/non-blocking Health Connections, but this remains a product decision and must not be encoded in O7B until explicitly approved.

## O7B blockers

Before `healthConnections` can be scheduled or rendered as a real visible step:

- product must confirm skip/deny/unavailable completion behavior;
- visible screen content/actions/options must be approved;
- placement relative to Nutrition Targets / Review must be confirmed;
- platform-unavailable presentation and explicit Connect action semantics must be defined;
- a real renderer/section must exist before flow planner activation.

## Guardrails

- no fake health connection success;
- no OS health permission request in O7A;
- no new visible Health Connections screen/content without approval;
- no plugin/manifest/schema mutation in O7A;
- no sensitive health-data duplication/logging;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
