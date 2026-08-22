# Implementation Status

Use this file to distinguish validated foundation from remaining Product Onboarding work. Runtime source is behavior truth; current sequencing is `.ai/tasks/product-onboarding-canonical-execution.md`.

## Status terms

- **Documented**: approved direction only.
- **Scaffolded**: source/UI contract exists but end-to-end behavior is incomplete.
- **Implemented**: intended source exists but final validation may remain.
- **Validated**: applicable checks/evidence are recorded.
- **Live**: production Supabase schema/migration is applied and verified.

| Capability | Status | Owner | Current boundary / evidence |
|---|---|---|---|
| Product Onboarding section/step identity foundation | Validated | `apps/features/onboarding` | Future migration-safe section IDs + draft codec validated by Flutter CI #945. |
| Unified Goal + Target Weight eligibility | Validated | onboarding + Body | Goal intent is semantic authority; Target Weight direction/dormant semantics validated by CI #1079. |
| Goal Pace cleanup | Validated | onboarding + Body | Weekly body-weight change only; skipped-intent cleanup validated by CI #1090. |
| Integrated Goal/weight local acceptance + Review | Validated | onboarding | Mode/Goal flow and Review source validated by CI #1095. |
| Canonical Body onboarding writes | Validated | `apps/features/progress` + onboarding | Current Weight → `body_weight_logs`; Body Goal/Target/Pace → `user_body_goals`; CI #1135. |
| Canonical Body read/history contract | Validated | `apps/features/progress` | Latest weight + active Body Goal reads/history commands; no fabricated 70kg; CI #1153. |
| Canonical Body/Wellness/Nutrition/Workout schema | Live | Supabase | `20260821161923_create_canonical_owner_tables` + `20260821162207_backfill_canonical_owner_data`. |
| Account/Profile/App Preferences P1 schema | Live | Supabase | `user_profiles`, `user_app_preferences`, `users.email_verified_at`; migrations `20260821180908` + `20260821181005`; RLS/grants verified. |
| App Mode local contract/controller | Validated foundation | `apps/shared`, `apps/app` | `AppMode`, guided mappings, controller and SharedPreferences adapter exist. This is now cache/staging architecture, not final authenticated account authority. |
| Durable App Mode / active_tabs | Not yet implemented | `user_app_preferences`, app, onboarding, Settings | **O1 NEXT.** Runtime still reads/writes confirmed mode through local `SharedPreferencesAppModePreference`; remote table is live but not wired. |
| Common User Profile canonical runtime | Not yet cut over | `user_profiles`, Profile, onboarding, Settings | **O2 after O1.** Legacy `users` Profile mirrors remain active until canonical repository parity. |
| Body/Profile parity + legacy Body mirror shutdown | Partial | Body + Profile + Settings | **O3 after O2.** Body repositories exist, but Profile models/writes still need structural cleanup and Settings weight composition. |
| Wellness onboarding | Decision required | `user_wellness_targets` | **O4.** Decide required vs optional/skippable vs Settings-only before activation. |
| Nutrition Profile + Targets canonical onboarding | Partial / pending cutover | Nutrition + onboarding | **O5.** Canonical tables exist; mixed legacy owner path and recommended/custom semantics remain. |
| Workout Intro/Profile/Targets canonical onboarding | Partial / pending cutover | Workout + onboarding | **O6.** Hybrid Intro behavior exists; final location/equipment/split/event product decisions and true-owner cutover remain. |
| Health Connections onboarding | Documented / undecided | health integration + onboarding entry | **O7.** Requires provider/privacy/permission/release decision; no fake connection success. |
| Review + edit-back + draft/resume final reconciliation | Partial | onboarding | **O8.** Existing Review foundation exists; final canonical section/data and restart/corrupt/account-switch/edit-back acceptance remains. |
| Plan Building / finalization | Not finalized | onboarding orchestration | **O9.** Must be driven by real idempotent finalization operations; 100% only after required success; reuse existing CongratulationsScreen. |
| Full Product Onboarding acceptance | Pending | onboarding + all owners | **O10.** Workout/Nutrition/Hybrid, navigation/back/progress/resume, canonical persistence, failure/retry, fresh install/second device, real-device acceptance. |
| Account email/mobile verification | Pending parallel lane | Account/Settings/Auth | **A1 / #8.** Phone-first→email and email-first→mobile real verification; not a technical blocker for O1–O3. |
| PR #50 | Draft/open/unmerged | Product Onboarding | Latest audited branch validation CI #1175 succeeded. Do not mark Ready/merge until remaining onboarding gates are validated. |

## Current Product Onboarding execution

```text
O1 durable App Mode / active_tabs               NEXT
  O1A domain/repository contract                NEXT
  O1B Supabase adapter
  O1C onboarding completion cutover
  O1D authenticated bootstrap/restore
  O1E Settings mode-change parity
  O1F integrated acceptance/full CI
→ O2 common User Profile owner + section
→ O3 Body Goal section + Body/Profile parity
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review/resume/edit-back
→ O9 truthful finalization + Congratulations
→ O10 final acceptance
```

## Important current-source facts

- `CompleteOnboardingUseCase` validates, persists owner data, optionally finalizes, then calls the injected `AppModePreference.write(selectedMode)` before completion publishing.
- App composition currently injects `SharedPreferencesAppModePreference`, so confirmed App Mode remains local-only.
- `AppModeBootstrap`/`main.dart` currently load the local controller; authenticated bootstrap does not yet restore `user_app_preferences`.
- `onboarding_drafts.payload.selected_mode` remains draft/resume state, never final App Mode authority.
- `user_app_preferences` already exists live and is the canonical owner to wire in O1.

## Product rules already resolved

- Nutrition Goal: Lose/Gain/Maintain/Recomposition, single-select.
- Workout/Hybrid Goal: max two compatible intents; `Build muscle != Gain weight`.
- Lose/Gain → Target Weight + Goal Pace.
- Maintain/Recomposition → skip Target Weight + Goal Pace; never auto-fill target=current weight.
- Current Weight is Body-owned.
- Hybrid Workout Intro `Later` skips Workout Profile/Targets for that run and preserves stored Workout data.
- App Mode visibility never deletes hidden owner data.

## Update rules

- Move a capability forward only after inspecting affected source and recording validation.
- One Product Onboarding implementation slice is active at a time.
- Do not let historical `.ai/tasks/onboarding-flow.md` Firebase/HTTP-blocked language override the current Supabase-backed canonical execution plan.
- No UI redesign is implied by owner/persistence/section changes.
- Do not merge PR #50 until O10-level acceptance and remaining required product gates are resolved.