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
| Canonical Nutrition persistence cutover | Validated | Nutrition + onboarding + app composition | O5D #67 / Flutter CI #1505. Product Onboarding completion injects `NutritionProfileRepository` + `NutritionTargetsRepository` directly. |
| Integrated Nutrition acceptance | Validated | Nutrition + onboarding | O5E #68 / source `b017f6c31c9c89a6df1ba6b670ea0ea04d635941` / Flutter CI #1507. Mode matrix, provenance, recommendation/customization round-trip, legacy resume and failure/retry/idempotence are covered. |
| Canonical Workout Profile + Targets contracts | Active | Workout | O6A #70. Split broad Workout preferences into explicit canonical owner contracts/adapters; no runtime cutover yet. |
| Workout Intro/Profile/Targets canonical onboarding | Active | Workout + onboarding | O6 #69. O6B-E follow O6A validation. |
| Health Connections onboarding | Documented / undecided | health integration + onboarding | O7 requires provider/privacy/permission/release decisions; no fake connection success. |
| Review + edit-back + draft/resume final reconciliation | Partial | onboarding | O8 follows O7. Existing Review foundation remains; final canonical cross-owner acceptance is pending. |
| Plan Building / finalization | Pending | onboarding orchestration | O9 must remain idempotent and truthfully publish completion only after required success. |
| Full Product Onboarding acceptance | Pending | onboarding + all owners | O10 covers all modes, navigation/back/progress/resume, canonical persistence, failure/retry, fresh install/second device and real-device acceptance. |
| Canonical Schema Cleanup | Blocked | Supabase + domain owners | O11/#54 destructive cleanup remains blocked until O10. |
| Account email/mobile verification | Pending parallel lane | Account/Settings/Auth | #8 remains parallel and does not redefine Product Onboarding owner sequencing. |
| PR #50 | Draft/open/unmerged | Product Onboarding | Latest exact validated Product Onboarding source is O5E CI #1507. Keep Draft until remaining O6→O10 gates are validated. |

## Current Product Onboarding execution

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition                                     ✅ #63 / CI #1507
→ O6 Workout                                     ACTIVE #69
   → O6A canonical owner contracts               ACTIVE #70
   O6B workoutProfile runtime/draft/resume
   O6C workoutTargets runtime + ordered goals
   O6D canonical persistence cutover
   O6E integrated acceptance
→ O7 Health Connections
→ O8 Review/resume/edit-back
→ O9 finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

Only one Product Onboarding implementation sub-slice is active at a time.

## Latest exact validated source checkpoint

```text
b017f6c31c9c89a6df1ba6b670ea0ea04d635941
Flutter CI #1507 / run 32583620248
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the O5E runtime/source checkpoint. Tracker/docs commits after it do not replace source validation.

## Important current-source facts

- O5 canonical Nutrition is complete and validated on CI #1507.
- Current Workout persistence still uses broad `WorkoutPreferencesRepository`/`WorkoutPreferencesData`.
- Broad Workout data mixes context (`workout_location`, equipment, experience, focus, health concerns) with target/planning fields (training days, duration, split, special event).
- `user_workout_targets` is already live and owns ordered Workout goals, training days, duration, split and special-event target fields.
- Current broad `SupabaseWorkoutPreferencesRepository` may attempt anonymous auth and legacy fallback; new canonical O6 adapters must not copy that behavior.
- Hybrid Workout Intro `Later` skips Workout Profile/Targets for the run and preserves stored Workout data.
- Applied migrations are immutable; physical duplicate cleanup belongs only to O11 after O10.

## Product rules already resolved

- Nutrition Goal: Lose/Gain/Maintain/Recomposition, single-select.
- Workout/Hybrid Goal: max two compatible intents; `Build muscle != Gain weight`.
- Lose/Gain → Target Weight + Goal Pace.
- Maintain/Recomposition → skip Target Weight + Goal Pace; never auto-fill target=current weight.
- Current Weight is Body-owned.
- Workout Targets may persist only training intents: Build Muscle, Get Stronger, Improve Endurance, Stay Fit, preserving original rank.
- Hybrid Workout Intro `Later` skips Workout Profile/Targets for that run and preserves stored Workout data.
- App Mode visibility never deletes hidden owner data.

## Update rules

- Move a capability forward only after inspecting affected source and recording exact validation.
- One Product Onboarding implementation slice is active at a time.
- Do not let historical Firebase/HTTP-blocked task language override the current Supabase-backed canonical execution plan.
- No UI redesign is implied by owner/persistence/section changes.
- Do not merge PR #50 until O10-level acceptance and remaining required product gates are resolved.