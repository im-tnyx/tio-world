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
| S0-B2 Default Glass Size | Implemented; local validation PASS, CI/device pending | Settings | Device-local `SharedPreferencesAsync` preference with a real 250 ml default and explicit account-boundary reset. No Supabase table/migration, hydration logging or Water Goal coupling. [Execution evidence](tasks/settings-s0b2-default-glass-size.md). |
| Canonical Body/Wellness/Nutrition/Workout schema | Live | Supabase | Canonical owner tables live; legacy duplicate/mixed columns stay until O11/#54 after O10. |
| Durable App Mode / active_tabs | Validated | App preferences | O1 #11 / CI #1240. |
| Common User Profile canonical runtime | Validated | Profile + onboarding | O2 #53 / CI #1279. |
| Body Goal ownership | Validated | Body + onboarding | O3 #55 / CI #1354. |
| Wellness canonical onboarding | Validated | Wellness + onboarding | O4 #58 / CI #1441. |
| Nutrition canonical onboarding | Validated | Nutrition + onboarding | O5 #63 / source `b017f6c31c9c89a6df1ba6b670ea0ea04d635941` / CI #1507. |
| Workout canonical onboarding | Validated | Workout + onboarding + app | O6 #69 / source `d56e8226f8631bc81d3dd309cbb22c631ca636f5` / CI #1555. |
| Health Connections runtime/UI | Validated | onboarding orchestration | O7B #77 / source `371fafb8cf8a27b6f7922733b071277accf4af98` / CI #1575. Optional/non-blocking step active before Review. |
| Android Health Connect surface presence | Validated | app/platform | O7C1 / #78 / source `f95ddf7cef05e658566e5d9493efd6099edded76` / Flutter CI #1593 + Android Native CI #5. Presence only; no readiness/authorization claim. |
| Android Health Connect SDK readiness + authorization | Blocked | app/platform + product data owner | O7C2 blocked by #79 until first product capability, exact record types/access, owner, retention and privacy scope are approved. |
| Health connection durability/review integration | Blocked | unresolved until O7D | O7D waits for O7C2. No imported health records in `onboarding_drafts`. |
| Integrated Health Connections acceptance | Blocked | onboarding + platform | O7E waits for O7C2/O7D. |
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
→ O7 Health Connections                          ACTIVE/BLOCKED #75
   O7A contract/readiness                        ✅ #76
   O7B runtime/UI                                ✅ #77 / CI #1575
   O7C Android Health Connect adapter            PARTIAL #78
      O7C1 surface presence                      ✅ f95ddf7c / CI #1593 + Native #5
      O7C2 readiness + authorization             BLOCKED #79
   O7D durability/review integration             BLOCKED
   O7E integrated acceptance                    BLOCKED
→ O8 Review/resume/edit-back
→ O9 finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

## Latest exact validated source/platform checkpoint

```text
f95ddf7cef05e658566e5d9493efd6099edded76
Flutter CI #1593 / run 32611022666 / job 97124041663
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅

Android Native CI #5 / run 32611022667 / job 97124042275
Android debug APK/native compile ✅
```

## Important current-source facts

- O7B activates Health Connections in Workout/Nutrition/Hybrid after Nutrition Targets and before Review.
- Health Connections remains optional, non-blocking and retryable later.
- `HealthConnectionGateway` is the narrow onboarding/platform boundary; only a real authorized adapter may return `connected`.
- Live Health authorization status is not serialized in `OnboardingDraft`.
- O7C1 is app-owned platform infrastructure only and reports `present/absent` Health Connect surface presence.
- O7C1 adds only provider package visibility; it adds no health-data permissions, record access, client SDK dependency or minSdk change.
- Production still uses the O7B unavailable gateway because authorization is not yet implemented.
- O7C2 is blocked by #79; existing wellness step/sleep targets are not permission-scope evidence.
- Applied migrations are immutable; duplicate physical cleanup belongs only to O11 after O10.

## Update rules

- Move capability state only with exact source + CI evidence.
- One Product Onboarding implementation slice is active at a time.
- Surface presence is not SDK readiness; SDK readiness is not authorization.
- No health-data permission without an exact source-backed record-type/use-case scope.
- Do not start O7D/O7E while O7C2 is blocked.
- Do not merge PR #50 until O10-level acceptance and remaining required gates are resolved.
