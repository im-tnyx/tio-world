# Implementation Status

Use this file to distinguish validated runtime from remaining Product Onboarding work. Runtime source is behavior truth; current sequencing is `.ai/tasks/product-onboarding-canonical-execution.md`.

## Status terms

- **Documented**: approved direction only.
- **Scaffolded**: source/UI contract exists but end-to-end behavior is incomplete.
- **Implemented**: intended source exists but final validation may remain.
- **Validated**: applicable checks/evidence are recorded on an exact source SHA.
- **Live**: production Supabase schema/migration is applied and verified.

| Capability | Status | Owner | Current boundary / evidence |
|---|---|---|---|
| Canonical Body/Wellness/Nutrition/Workout schema | Live | Supabase | Canonical owner tables are live; legacy duplicate/mixed columns remain until O11/#54 after O10. |
| Durable App Mode / active_tabs | Validated | `user_app_preferences`, app, onboarding | O1 #11 / Flutter CI #1240. |
| Common User Profile canonical runtime | Validated | `user_profiles`, Profile, onboarding | O2 #53 / Flutter CI #1279. |
| Body Goal + Target Weight + Goal Pace ownership | Validated | Body + onboarding | O3 #55 / Flutter CI #1354. |
| Wellness canonical onboarding | Validated | `user_wellness_targets`, onboarding | O4 #58 / Flutter CI #1441. |
| Nutrition canonical repository contracts | Validated | Nutrition | O5A #64 / Flutter CI #1449. |
| Nutrition Profile runtime/draft/resume | Validated | Nutrition + onboarding | O5B #65 / Flutter CI #1460. |
| Nutrition Goals runtime + legacy resume identity | Validated | Nutrition + onboarding | O5C #66 / Flutter CI #1481. |
| Canonical Nutrition persistence cutover | Validated | Nutrition + onboarding + app composition | O5D #67 / source `7af5ab0cb1bc37a84af568763a2214977dd57c0c` / Flutter CI #1505. Product Onboarding completion now injects `NutritionProfileRepository` + `NutritionTargetsRepository` directly and no longer depends on `TargetsSetupRepository`. |
| Integrated Nutrition acceptance | Active | Nutrition + onboarding | O5E #68. Must prove mode matrix, canonical round-trip, legacy resume compatibility, failure/retry ordering and customization-state preservation. |
| Workout Intro/Profile/Targets canonical onboarding | Pending | Workout + onboarding | O6 begins only after O5E exact full CI green. |
| Health Connections onboarding | Documented / undecided | health integration + onboarding | O7 requires provider/privacy/permission/release decisions; no fake connection success. |
| Review + edit-back + draft/resume final reconciliation | Partial | onboarding | O8 follows O7. Existing Review foundation remains, final canonical cross-owner acceptance is pending. |
| Plan Building / finalization | Pending | onboarding orchestration | O9 must remain idempotent and truthfully publish completion only after required success. |
| Full Product Onboarding acceptance | Pending | onboarding + all owners | O10 covers all modes, navigation/back/progress/resume, canonical persistence, failure/retry, fresh install/second device and real-device acceptance. |
| Canonical Schema Cleanup | Blocked | Supabase + domain owners | O11/#54 destructive cleanup remains blocked until O10. |
| Account email/mobile verification | Pending parallel lane | Account/Settings/Auth | #8 remains parallel and does not redefine Product Onboarding owner sequencing. |
| PR #50 | Draft/open/unmerged | Product Onboarding | O5D exact source checkpoint is CI #1505 green. Keep Draft until remaining O5E→O10 gates are validated. |

## Current Product Onboarding execution

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
→ O5 Nutrition                                   ACTIVE #63
   O5A contracts                                 ✅ #64 / CI #1449
   O5B Nutrition Profile runtime                 ✅ #65 / CI #1460
   O5C Nutrition Goals runtime                   ✅ #66 / CI #1481
   O5D canonical persistence                     ✅ #67 / CI #1505
   → O5E integrated acceptance                   ACTIVE #68
→ O6 Workout
→ O7 Health Connections
→ O8 Review/resume/edit-back
→ O9 finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

Only one Product Onboarding implementation sub-slice is active at a time.

## Latest exact validated source checkpoint

```text
7af5ab0cb1bc37a84af568763a2214977dd57c0c
Flutter CI #1505 / run 32582725736
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the O5D runtime/source checkpoint. Tracker/docs commits after it do not replace source validation.

## Important current-source facts

- `PersistOnboardingOwnerDataUseCase` persists Profile → Body → Wellness → Nutrition Profile when active → Workout when active → Nutrition Targets.
- Product Onboarding completion requires canonical `NutritionProfileRepository` and `NutritionTargetsRepository` directly.
- App router composition injects `nutritionProfileRepositoryProvider` and `nutritionTargetsRepositoryProvider` directly.
- `TargetsSetupRepository` remains compatibility-only outside Product Onboarding completion; O5D does not delete it or its legacy schema.
- `nutritionProfile` is active only for Nutrition/Hybrid; `nutritionGoals` remains active for Workout/Nutrition/Hybrid.
- Unanswered Nutrition allergies remain canonical `null`; explicit None remains canonical empty set.
- Applied migrations are immutable; legacy physical cleanup belongs only to O11 after O10.

## Product rules already resolved

- Nutrition Goal: Lose/Gain/Maintain/Recomposition, single-select.
- Workout/Hybrid Goal: max two compatible intents; `Build muscle != Gain weight`.
- Lose/Gain → Target Weight + Goal Pace.
- Maintain/Recomposition → skip Target Weight + Goal Pace; never auto-fill target=current weight.
- Current Weight is Body-owned.
- Hybrid Workout Intro `Later` skips Workout Profile/Targets for that run and preserves stored Workout data.
- App Mode visibility never deletes hidden owner data.

## Update rules

- Move a capability forward only after inspecting affected source and recording exact validation.
- One Product Onboarding implementation slice is active at a time.
- Do not let historical Firebase/HTTP-blocked task language override the current Supabase-backed canonical execution plan.
- No UI redesign is implied by owner/persistence/section changes.
- Do not merge PR #50 until O10-level acceptance and remaining required product gates are resolved.