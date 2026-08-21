# Canonical Supabase Owner Migration

**Status:** Body foundation + account/Profile/App Preferences P1 schema applied and validated; P1A runtime verification is NEXT  
**Canonical owner tracker:** #44  
**Related trackers:** #8, #11, #40 / PR #50

## Outcome

Keep one durable owner per concept in live `tio-world` Supabase while preserving `public.users(id)` as the stable application account/domain root for current Supabase and future backend adapters.

## Approved durable owners

```text
users
→ account/domain root + contacts/verification

user_profiles
→ 1:1 common Profile

user_app_preferences
→ 1:1 App Mode + active navigation preferences

user_devices
→ 1:N device owner

body_weight_logs
user_body_goals
user_wellness_targets
user_nutrition_profiles
user_nutrition_targets
user_workout_profiles
user_workout_targets

onboarding_drafts
→ draft/resume orchestration only
```

Do not rename/replace `users`. Existing and new canonical domain FKs continue to reference `public.users(id)`.

## Applied canonical migrations

Body/Wellness/Nutrition/Workout foundation:

```text
20260821161923_create_canonical_owner_tables
20260821162207_backfill_canonical_owner_data
```

Account/Profile/App Preferences P1:

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

## P1 live result — VALIDATED ✅

### `users`

P1 added:

```text
email_verified_at timestamptz null
```

Account contact projection is now:

```text
email
email_verified_at
mobile
mobile_verified_at
```

Normal client roles cannot directly promote verified timestamps. Contact changes invalidate the corresponding verification timestamp. Trusted backend/service reconciliation may set verification after real provider confirmation.

P1 backfill copied Supabase Auth confirmation timestamps only for exact current contact matches. It did not infer verification from a non-null contact string.

### `user_profiles`

Live canonical 1:1 Profile owner:

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

Constraints reflect the current app storage vocabulary and positive height. No duplicate `dob` column exists in `user_profiles`.

### `user_app_preferences`

Live canonical 1:1 App Preferences owner:

```text
user_id PK/FK → public.users(id) ON DELETE CASCADE
app_mode       → workout | nutrition | hybrid | null
active_tabs    → ordered text[] | null
created_at
updated_at
```

No row was fabricated from onboarding draft `selected_mode`; drafts are not final preference authority.

### RLS / grants

Both P1 tables:

- RLS enabled;
- authenticated SELECT/INSERT/UPDATE ownership policies use `(select auth.uid()) = user_id`;
- UPDATE includes `USING` + `WITH CHECK`;
- FKs target `public.users(id)`.

Validation detected this existing project's automatic broad grants for new tables, including `TRUNCATE` on `anon/authenticated`. Because TRUNCATE bypasses RLS, the second P1 migration hardened grants immediately.

Final privileges:

```text
anon          → none
authenticated → SELECT, INSERT, UPDATE
service_role  → backend/service privileges
```

### P1 data/advisor validation

Live rows at migration time:

```text
users                 0
user_profiles         0
user_app_preferences  0
```

Current live backfill was therefore a no-op. Migration SQL still contains conflict-first validation and deterministic non-empty-environment Profile backfill.

No new security/performance advisor warning was introduced by P1 objects. Existing unrelated warnings remain:

- username SECURITY DEFINER RPC exposure;
- leaked-password protection disabled;
- older-table `auth.uid()` init-plan warnings;
- unused-index INFO notices.

## Existing Body repository evidence

```text
Body Cutover A  → CI #1135 ✅
Body Cutover B1 → CI #1153 ✅
```

B1 established canonical Body reads/history commands and removed fabricated current-weight fallback semantics at the Body boundary.

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

Mixed legacy fields also remain in Nutrition/Workout profiles until their own cutovers.

No permanent bidirectional synchronization may be introduced.

## Canonical execution order

Authoritative sequencing task:

`.ai/tasks/account-profile-app-preferences-canonical-split.md`

```text
Body B1 canonical read/history contract        ✅ #1153
P1 schema foundation                           ✅ LIVE / VALIDATED
        ↓
P1A account contact verification               NEXT (#8)
        ↓
P2 durable App Mode / active_tabs              (#11)
        ↓
P3 common Profile repository cutover
        ↓
P4 Body B2/B3 Profile/Settings composition
        ↓
P5 Wellness/Nutrition split
        ↓
P6 Workout Profile/Targets split
        ↓
P7 integrated persistence acceptance
        ↓
later legacy-column cleanup migration
```

## Next slices

### P1A — Account contact verification

- real phone-first→email and email-first→phone add/change/verify flows;
- no fake OTP verification success;
- remove default `isEmailVerified = true` assumption;
- trusted Auth/provider evidence reconciles provider-neutral `users.*_verified_at`;
- bootstrap/sign-in can repair stale contact projection;
- focused tests + full relevant CI.

### P2 — App Mode

`user_app_preferences` is live, but Flutter still uses SharedPreferences as current authority. P2 moves onboarding completion, Settings writes and authenticated bootstrap reads to the canonical remote owner; local storage becomes cache/staging only.

### P3 — Profile

Onboarding/Profile Settings common Profile reads/writes move to `user_profiles`; account fields stay on `users`.

### P4 — Body/Profile composition

After P3, remove Body fields from Profile models/writes and compose `user_profiles` + Body owner at app boundary.

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
- no UI redesign/picker/recommendation-formula change in persistence work.

## Current next step

**P1A — implement real account contact verification and trusted reconciliation (#8).**
