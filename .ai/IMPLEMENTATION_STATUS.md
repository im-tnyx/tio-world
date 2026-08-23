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
| Workout canonical onboarding | Validated | Workout + onboarding + app | O6 #69 / source `d56e8226f8631bc81d3dd309cbb22c631ca636f5` / CI #1555. Canonical Profile/Targets runtime + persistence cutover + integrated acceptance complete. |
| Health Connections runtime/UI | Validated | onboarding orchestration | O7B #77 / source `371fafb8cf8a27b6f7922733b071277accf4af98` / CI #1575. Optional/non-blocking step active before Review; fallback never fabricates connection. |
| Android Health Connect platform adapter | Active | app/platform + onboarding boundary | O7C #78. Availability/provider detection may proceed; health-data permission scope remains gated until exact product record types/use case are source-backed. |
| Health connection durability/review integration | Pending | unresolved until O7D | No imported health records in `onboarding_drafts`. |
| Integrated Health Connections acceptance | Pending | onboarding + platform | O7E after O7D. |
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
O6 Workout                                       ✅ #69 / CI #1555
→ O7 Health Connections                          ACTIVE #75
   O7A contract/readiness                        ✅ #76
   O7B runtime/UI                                ✅ #77 / CI #1575
   → O7C Android Health Connect adapter          ACTIVE #78
   O7D persistence/resume/review integration
   O7E integrated acceptance
→ O8 Review/resume/edit-back
→ O9 finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

## Latest exact validated source checkpoint

```text
371fafb8cf8a27b6f7922733b071277accf4af98
Flutter CI #1575 / run 32607322748 / job 97114316589
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Important current-source facts

- O7B activates Health Connections in Workout/Nutrition/Hybrid after Nutrition Targets and before Review.
- Health Connections is optional, non-blocking and retryable later.
- `HealthConnectionGateway` is the narrow orchestration/platform boundary; only a real platform adapter may return `connected`.
- Live Health authorization status is not serialized in `OnboardingDraft`.
- Pre-O7B unfinished Review checkpoints reconcile through Health Connections.
- O7C must keep platform implementation/composition outside onboarding business logic.
- Current app source has no health plugin and no health-data permissions.
- Repository roadmap defers health permissions/wearable-data sync pending Recovery/data-source/privacy approval; do not invent broad Health Connect scopes.
- Applied migrations are immutable; duplicate physical cleanup belongs only to O11 after O10.

## Update rules

- Move capability state only with exact source + CI evidence.
- One Product Onboarding implementation slice is active at a time.
- Do not turn platform availability into fake authorization success.
- No health-data permission without an exact source-backed record-type/use-case scope.
- Do not merge PR #50 until O10-level acceptance and remaining required gates are resolved.
