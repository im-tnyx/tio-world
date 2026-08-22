# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/README.md`
3. `.ai/tasks/product-onboarding-canonical-execution.md`
4. focused task for the active slice
5. relevant GitHub issue and runtime source

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + target state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

`users` is not renamed. Canonical domain FKs continue to use `public.users(id)`.

## Live Supabase foundation

Applied and validated:

```text
20260821161923_create_canonical_owner_tables
20260821162207_backfill_canonical_owner_data
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

P1 created `user_profiles`, `user_app_preferences`, and `users.email_verified_at` with RLS/grant hardening. Existing legacy mixed columns remain temporarily; no destructive cleanup yet.

## Product Onboarding validated foundation

```text
Section/step identity compatibility             ✅ CI #945
Target Weight draft/eligibility                 ✅ CI #1079
Goal Pace ownership/skipped-intent cleanup      ✅ CI #1090
Integrated Goal/weight local acceptance         ✅ CI #1095
Canonical Body onboarding writes                ✅ CI #1135
Canonical Body read/history contract            ✅ CI #1153
P1 Profile/App Preferences schema               ✅ LIVE
O1A App Preferences contract                    ✅ CI #1183
O1B Supabase App Preferences adapter            ✅ CI #1187
O1C onboarding completion cutover               ✅ CI #1199
O1D authenticated bootstrap/restore             ✅ CI #1210
O1E Settings canonical write parity             ✅ CI #1231
```

Latest validated O1 checkpoint before active O1F:

```text
7210fe7409af9f41f7478096e19d56853e8060d4
Flutter CI #1231 / run 32551614514
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

PR #50 remains Draft/open/unmerged.

## Product Onboarding current sequence

Authoritative task: `.ai/tasks/product-onboarding-canonical-execution.md`

```text
O1 durable App Mode / active_tabs               IN PROGRESS (#11)
   O1A ✅
   O1B ✅
   O1C ✅
   O1D ✅
   O1E ✅
   O1F integrated acceptance/full CI            ACTIVE
→ O2 common User Profile owner + section
→ O3 Body Goal section + Body/Profile parity
→ O4 Wellness placement + owner
→ O5 Nutrition Profile + Nutrition Targets split
→ O6 Workout Intro/Profile/Targets split
→ O7 Health Connections decision/integration
→ O8 Review + edit-back + draft/resume
→ O9 truthful Plan Building/finalization + existing Congratulations
→ O10 full mode/device/persistence acceptance
→ later legacy-column cleanup
```

Independent Account/Settings lane:

```text
A1 real email/mobile add-change-verify (#8)
```

A1 is required before final Account/Settings acceptance but does not technically block O1–O3.

## Active slice — O1F integrated App Mode acceptance

Focused task: `.ai/tasks/app-mode-o1f-integrated-acceptance.md`

Tracker: GitHub Issue #11.

Current durable behavior:

```text
Onboarding completion → canonical user_app_preferences ✅
Authenticated restore → canonical remote wins before Ready ✅
Exact ordered active_tabs → shell/route configuration ✅
SharedPreferences → cache/pre-auth staging ✅
Authenticated Ready Settings change → canonical-first ✅
Canonical Settings failure → current mode preserved ✅
```

O1F adds cross-boundary acceptance rather than a new persistence owner:

```text
CompleteOnboardingUseCase
→ canonical App preferences + remote completion
→ local cache
→ cleared/stale/second-device bootstrap restore
→ exact shell/route destinations
→ Ready Settings canonical mode change
→ another fresh-device restore of changed canonical state
```

Additional scenarios lock mode-only recovery, missing completed-legacy recovery without Hybrid inference, malformed canonical bootstrap failure, Settings failure preservation, authenticated fail-closed behavior, and hidden-domain preservation.

Production behavior should change in O1F only if this integrated matrix exposes a real contract gap.

Do not start O2 until O1F validation evidence is recorded in #11/#40/#44, PR #50 and the canonical onboarding task.

## Important onboarding product rules

- Existing onboarding screen designs are preserved by default.
- Height / Current Weight / Target Weight / DOB wheel/picker contracts are preserved.
- Existing Goal card visual language is preserved.
- `GoalIntentSelection` is semantic authority; `Build muscle != Gain weight`.
- Lose/Gain → Target Weight + Goal Pace.
- Maintain/Recomposition → skip Target Weight + Goal Pace; do not auto-save target=current weight.
- Current Weight is Body-owned through `body_weight_logs`.
- Body Goal/Target/Pace are `user_body_goals`.
- Hybrid Workout Intro `Later` skips Workout Profile + Targets for the current run without deleting stored Workout data.
- App Mode visibility never deletes hidden domain data.

## Later open product decisions

- Wellness placement: required / optional / Settings-only.
- Nutrition Profile requiredness and recommended/custom target semantics.
- Workout Training Location including `Both`, setup/facility labels, equipment taxonomy, split/event lifecycle.
- Health Connections provider/privacy/release inclusion.
- real operations and retry semantics for Plan Building.
- exact Target Weight recommendation numeric policy.
- measurement picker/reference restoration if the active source still requires it.

## Historical task note

`.ai/tasks/onboarding-flow.md` contains useful historical architecture/detail but is no longer the sequencing authority. Its old Firebase/HTTP-blocked language must not override the current Supabase-backed canonical execution plan.

## Guardrails

- one canonical owner per concept;
- no applied migration edits;
- no permanent dual-write synchronization;
- no fabricated defaults or semantic inference;
- no legacy-column drop before repository cutover proof;
- no UI redesign as a side effect of persistence/ownership work;
- future backend consumes the same canonical Postgres owners and backend-neutral repository contracts.
