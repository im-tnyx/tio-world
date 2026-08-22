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
| Canonical Body/Wellness/Nutrition/Workout schema | Live | Supabase | Canonical owner tables live; legacy duplicate/mixed columns stay until O11/#54 after O10. |
| Durable App Mode / active_tabs | Validated | App preferences | O1 #11 / CI #1240. |
| Common User Profile canonical runtime | Validated | Profile + onboarding | O2 #53 / CI #1279. |
| Body Goal ownership | Validated | Body + onboarding | O3 #55 / CI #1354. |
| Wellness canonical onboarding | Validated | Wellness + onboarding | O4 #58 / CI #1441. |
| Nutrition canonical onboarding | Validated | Nutrition + onboarding | O5 #63 / source `b017f6c31c9c89a6df1ba6b670ea0ea04d635941` / CI #1507. |
| Canonical Workout Profile + Targets contracts | Validated | Workout | O6A #70 / source `cd764653146d4514fb4e56ef893e92846327ae2e` / CI #1509. |
| Canonical workoutProfile runtime + legacy resume | Validated | Workout + onboarding | O6B #71 / source `48f0d1ff562fee7dda5647476ff706d1886dde11` / CI #1511. Historical `workoutPreferences` reads forward; new writes are canonical. |
| workoutTargets runtime + ordered training goals | Active | Workout + onboarding | O6C #72. Split runtime ownership, schema-v4 migration and ordered goal mapping; persistence stays broad until O6D. |
| Canonical Workout persistence cutover | Pending | Workout + onboarding + app | O6D after O6C exact full CI green. |
| Integrated Workout acceptance | Pending | Workout + onboarding | O6E after O6D. |
| Health Connections onboarding | Documented / undecided | health integration + onboarding | O7 after O6. No fake connection success. |
| Review + edit-back + draft/resume reconciliation | Partial | onboarding | O8 after O7. |
| Plan Building / finalization | Pending | onboarding orchestration | O9. Truthful/idempotent finalization only. |
| Full Product Onboarding acceptance | Pending | onboarding + owners | O10. All modes/navigation/resume/persistence/failure/device acceptance. |
| Canonical Schema Cleanup | Blocked | Supabase + owners | O11/#54 blocked until O10. |
| Account email/mobile verification | Pending parallel lane | Account/Settings/Auth | #8 parallel. |
| PR #50 | Draft/open/unmerged | Product Onboarding | Keep Draft until O10-level acceptance. |

## Current Product Onboarding execution

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition                                     ✅ #63 / CI #1507
→ O6 Workout                                     ACTIVE #69
   O6A canonical owner contracts                 ✅ #70 / CI #1509
   O6B workoutProfile runtime                    ✅ #71 / CI #1511
   → O6C workoutTargets runtime + ordered goals  ACTIVE #72
   O6D canonical persistence cutover
   O6E integrated acceptance
→ O7 Health Connections
→ O8 Review/resume/edit-back
→ O9 finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

## Latest exact validated source checkpoint

```text
48f0d1ff562fee7dda5647476ff706d1886dde11
Flutter CI #1511 / run 32585811984
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Important current-source facts

- O6A canonical Workout repositories exist and are signed-out fail-closed without anonymous-auth mutation.
- O6B active top-level identity is canonical `workoutProfile`; historical `workoutPreferences` remains source/storage compatibility only.
- O6C will activate a distinct `workoutTargets` top-level section and move the existing Health Concerns screen next to Profile-owned context.
- O6C must bump onboarding draft schema to v4 because O6B already emits `workoutProfile`, so storage key alone cannot identify broad pre-split completion.
- Only training intents Build Muscle/Get Stronger/Improve Endurance/Stay Fit belong in canonical Workout Targets; preserve original unified rank.
- Current broad `WorkoutPreferencesRepository` remains completion writer until O6D.
- Hybrid `Later` skips Workout Profile/Targets for the run and preserves stored data.
- Applied migrations are immutable; duplicate physical cleanup belongs only to O11 after O10.

## Update rules

- Move capability state only with exact source + CI evidence.
- One Product Onboarding implementation slice is active at a time.
- No UI redesign is implied by owner/persistence/section migration unless explicitly approved.
- Do not merge PR #50 until O10-level acceptance and remaining required gates are resolved.