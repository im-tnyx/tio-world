# Canonical Supabase Owner Migration

**Status:** Canonical owner schema + P1 Account/Profile/App Preferences foundation are LIVE and validated  
**Canonical owner tracker:** #44  
**Product Onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Related trackers:** #11, #8, #40 / PR #50

## Outcome

Keep one durable owner per concept in live `tio-world` Supabase while preserving `public.users(id)` as the stable application account/domain root for current Supabase and future backend adapters.

## Approved durable owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
user_devices               → devices
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + recommended/custom state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Do not rename or replace `users`. Canonical domain FKs continue to target `public.users(id)`.

## Applied canonical migrations

Body / Wellness / Nutrition / Workout foundation:

```text
20260821161923_create_canonical_owner_tables
20260821162207_backfill_canonical_owner_data
```

Account / Profile / App Preferences foundation:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

Repo files:

```text
supabase/migrations/20260821161923_create_canonical_owner_tables.sql
supabase/migrations/20260821162207_backfill_canonical_owner_data.sql
supabase/migrations/20260821180908_split_account_profile_app_preferences.sql
supabase/migrations/20260821181005_harden_profile_app_preference_grants.sql
```

Never edit applied migrations in place.

## Live P1 result — VALIDATED ✅

### Account root

```text
users.email
users.email_verified_at
users.mobile
users.mobile_verified_at
```

Normal client roles cannot directly promote verification timestamps. Contact change invalidates only that contact's verification state. Trusted backend/auth-provider reconciliation marks verified state after real confirmation.

### `user_profiles`

```text
user_id PK/FK → public.users(id) ON DELETE CASCADE
name
gender
date_of_birth
height_cm
activity_level
health_conditions
other_health_condition
unit_preferences
created_at
updated_at
```

No duplicate `dob` exists in the new canonical Profile table.

### `user_app_preferences`

```text
user_id PK/FK → public.users(id) ON DELETE CASCADE
app_mode       → workout | nutrition | hybrid | null
active_tabs    → ordered text[] | null
created_at
updated_at
```

No final preference was fabricated from `onboarding_drafts.payload.selected_mode`.

### RLS / grants

Both P1 tables:
- RLS enabled;
- own-row policies use `(select auth.uid()) = user_id`;
- UPDATE has `USING` + `WITH CHECK`;
- authenticated final privileges are SELECT/INSERT/UPDATE;
- anon has no table privileges.

Validation discovered existing-project automatic broad new-table grants including TRUNCATE. The hardening migration removed them because TRUNCATE bypasses RLS.

Live affected rows were zero, so current backfill was a no-op. Migration logic remains conflict-first/deterministic for non-empty environments.

No new advisor warning was introduced by P1. Existing unrelated username SECURITY DEFINER, leaked-password protection, old RLS init-plan and unused-index notices remain separate work.

## Body repository evidence

```text
Body Cutover A  → CI #1135 ✅
Body Cutover B1 → CI #1153 ✅
```

Current Weight canonical owner is `body_weight_logs`; Body Goal/Target Weight/Goal Pace canonical owner is `user_body_goals`.

## Transitional legacy columns

Legacy mixed columns remain physically present during repository cutover. Do not drop yet:

```text
users.name
users.gender
users.date_of_birth / users.dob
users.height_cm
users.activity_level
users.health_conditions
users.other_health_condition
users.unit_preferences
users.current_weight_kg
users.target_weight_kg
users.goals
users.primary_goal
```

Mixed legacy fields also remain in Nutrition/Workout profiles until their owning slices migrate them.

No permanent bidirectional synchronization may be introduced.

## Current execution model — two lanes

### Product Onboarding lane

Authoritative task:

`.ai/tasks/product-onboarding-canonical-execution.md`

```text
Foundation / P1 schema                         ✅ LIVE
        ↓
O1 durable App Mode / active_tabs              NEXT (#11)
        ↓
O2 common Profile owner + section
        ↓
O3 Body Goal section + Profile/Body parity
        ↓
O4 Wellness
        ↓
O5 Nutrition Profile/Targets
        ↓
O6 Workout Intro/Profile/Targets
        ↓
O7 Health Connections
        ↓
O8 Review + draft/resume
        ↓
O9 truthful finalization + existing Congratulations
        ↓
O10 integrated mode/device/persistence acceptance
        ↓
later legacy-column cleanup
```

### Account / Settings lane

```text
A1 real email/mobile verification (#8)
```

A1 is required for final account/settings acceptance but is not a technical prerequisite for O1 Product Onboarding App Mode persistence.

## Immediate next schema/repository work

No new table is required before O1. `user_app_preferences` already exists live.

O1 is primarily repository/runtime cutover:
- backend-neutral App Preferences contract;
- Supabase reads/writes of `user_app_preferences`;
- onboarding completion persists mode/tabs before completion publishes;
- Settings writes same owner;
- authenticated bootstrap restores remote state;
- SharedPreferences becomes cache/pre-auth staging;
- remote canonical state wins stale local cache;
- second-device/fresh-install tests.

After O1, O2 cuts common Profile persistence to existing live `user_profiles`; no new Profile table migration is needed.

## Future backend rule

A future protected backend must use these same Postgres owners and backend-neutral contracts. Do not create a parallel backend schema or re-couple Profile/App Preferences/Body into `users` for transport convenience.

Auth providers may change, but provider-neutral application verification fields remain `email_verified_at` / `mobile_verified_at` on the account root.

## Guardrails

- one durable owner per concept;
- no destructive rename of `users`;
- no applied migration edits;
- no client-authoritative verification timestamp;
- no permanent dual-write synchronization;
- no fabricated defaults or semantic guessing;
- Onboarding/Settings are entry points, not owners;
- no legacy column drop before verified repository cutover;
- no UI redesign/picker/recommendation-formula change as a side effect of persistence work.

## Handoff

**Product Onboarding next:** O1 durable App Mode / active-tabs (#11).  
**Parallel account work:** A1 contact verification (#8).  
**Read `product-onboarding-canonical-execution.md` before implementing any later onboarding owner slice.**