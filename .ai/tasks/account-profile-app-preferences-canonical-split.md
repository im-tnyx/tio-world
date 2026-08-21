# Account / Profile / App Preferences Canonical Split

**Status:** P1 validated live; P1A account contact verification is NEXT  
**Canonical owner tracker:** #44  
**App Mode tracker:** #11  
**Account/contact persistence tracker:** #8  
**Related onboarding tracker:** #40 / PR #50

## Canonical ownership

```text
users
→ stable account/domain root
→ username/contact/avatar/timezone/plan/account lifecycle
→ email + email_verified_at
→ mobile + mobile_verified_at

user_profiles
→ 1:1 common personal/profile baseline
→ name
→ gender
→ date_of_birth
→ height_cm
→ activity_level
→ general health conditions
→ unit_preferences

user_app_preferences
→ 1:1 app-experience preference owner
→ app_mode
→ ordered active_tabs

user_devices
→ 1:N device/runtime identity

body_weight_logs
user_body_goals
user_wellness_targets
user_nutrition_profiles
user_nutrition_targets
user_workout_profiles
user_workout_targets
onboarding_drafts
```

The earlier `users = account + common Profile` decision is superseded. Do not rename `users`; all canonical owner FKs continue to use `public.users(id)` as the future-backend-safe application user root.

## Latest validated checkpoint — P1 ✅ LIVE

Live Supabase project: `tio-world` (`oykupyiitspujzpwwvuj`)

Applied migrations:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

Repo migration files:

```text
supabase/migrations/20260821180908_split_account_profile_app_preferences.sql
supabase/migrations/20260821181005_harden_profile_app_preference_grants.sql
```

### P1 live result

```text
public.users
├─ email
├─ email_verified_at      ✅ added
├─ mobile
└─ mobile_verified_at     ✅ existing

public.user_profiles      ✅ created
public.user_app_preferences ✅ created
```

Live affected row counts at migration time:

```text
users                 0
user_profiles         0
user_app_preferences  0
```

Backfill was therefore a live no-op, but the migration contains conflict-first validation for legacy Profile values and deterministic backfill for non-empty environments.

### `user_profiles` live contract

```text
user_id uuid PK/FK → public.users(id) ON DELETE CASCADE
name text not null
gender text nullable
date_of_birth date nullable
height_cm numeric nullable
activity_level text nullable
health_conditions text[] not null
other_health_condition text nullable
unit_preferences jsonb not null
created_at timestamptz not null
updated_at timestamptz not null
```

Validated constraints cover current Profile storage vocabulary:

- gender: `male | female | other`;
- activity: `sedentary | light | active | very_active | dynamic`;
- health conditions: `none | diabetes | hypertension | low_blood_pressure | other` with `none` exclusivity;
- positive height when present;
- existing measurement-unit JSON contract;
- canonical DOB is `date_of_birth`; legacy `users.dob` is not copied as a second Profile column.

### `user_app_preferences` live contract

```text
user_id uuid PK/FK → public.users(id) ON DELETE CASCADE
app_mode text nullable
active_tabs text[] nullable
created_at timestamptz not null
updated_at timestamptz not null
```

`app_mode` is constrained to:

```text
workout | nutrition | hybrid
```

`active_tabs` is an ordered stable destination-ID array. It remains nullable for legacy/recovery compatibility. P1 intentionally does not create preference rows from `onboarding_drafts.payload.selected_mode`; drafts are not canonical preference authority.

### RLS / grants validation

Both new tables:

- RLS enabled;
- authenticated SELECT/INSERT/UPDATE policies use `(select auth.uid()) = user_id`;
- UPDATE has both `USING` and `WITH CHECK`;
- FK target is `public.users(id)`, not `auth.users(id)`.

During validation the existing project auto-granted broad new-table privileges, including `TRUNCATE`, to `anon/authenticated`. Because TRUNCATE is not protected by RLS, P1 immediately added the second hardening migration.

Final grants:

```text
anon          → no table privileges
authenticated → SELECT, INSERT, UPDATE only
service_role  → backend/service privileges
```

### Contact verification database guardrail

P1 added `users.email_verified_at` and a provider-neutral client-write guard.

For normal `authenticated` / `anon` database roles:

- verification timestamps cannot be arbitrarily promoted by direct row updates;
- changing email clears email verification;
- changing mobile clears mobile verification;
- client insert cannot seed verified timestamps.

Trusted backend/service roles can reconcile verified timestamps after real auth/provider verification. This does not make Supabase Auth a permanent domain dependency; the stored timestamps remain provider-neutral application account state.

P1 backfill copies Supabase Auth confirmation timestamps only when the current stored contact exactly corresponds to the confirmed Auth identity. It never infers verification from contact presence.

### Advisor result

No new security/performance advisor warning was introduced for `user_profiles`, `user_app_preferences`, or the verification-protection trigger.

Pre-existing unrelated warnings remain:

- authenticated-executable username `SECURITY DEFINER` RPCs;
- leaked-password protection disabled;
- historical `auth.uid()` init-plan warnings on older tables/policies;
- unused-index INFO notices on empty/low-use tables.

## Previous validated Body checkpoint

```text
Body A  → CI #1135 ✅
Body B1 → e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
          Flutter CI #1153 / run 32508150413 ✅
```

Body B1 established canonical Body reads/history commands with no fabricated `70 kg` fallback.

## Execution protocol

Only one implementation slice is active at a time. Do not begin the next slice until the current slice has validation evidence and tracker updates.

```text
P1 schema foundation                         ✅ LIVE / VALIDATED
        ↓
P1A account contact identity + verification  ⏳ NEXT (#8)
        ↓
P2 durable App Mode / active_tabs            ⏳ AFTER P1A (#11)
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
later verified legacy-column cleanup
```

## Slice P1A — Account contact identity + verification — NEXT

**Tracker:** #8

Goal: make email/mobile add-change-verify behavior truthful and symmetric for phone-first and email-first accounts.

```text
Phone-first signup
→ verified phone
→ email may remain null
→ Account Settings: Add email
→ real Supabase Auth email verification
→ trusted reconciliation to users.email + email_verified_at

Email-first signup
→ verified email
→ mobile may remain null
→ Account Settings: Add mobile
→ real Supabase Auth phone verification
→ trusted reconciliation to users.mobile + mobile_verified_at
```

P1A requirements:

- [ ] add/read provider-neutral account contact + verification state at the account repository boundary;
- [ ] remove `AccountSettingsPage.isEmailVerified = true` as an unknown-state default;
- [ ] router passes actual verified state;
- [ ] phone-first account can add/change and verify email;
- [ ] email-first account can add/change and verify mobile;
- [ ] use real Supabase Auth verification, not local fake OTP success;
- [ ] reconcile application timestamps only from trusted confirmed auth state;
- [ ] failed/expired verification remains unverified;
- [ ] contact change invalidates only that contact's verification;
- [ ] bootstrap/sign-in can repair stale application verification state;
- [ ] no false success Snackbar/pop;
- [ ] focused tests + full relevant Flutter/Dart CI;
- [ ] update #8/#44 and this task with exact validated commit/CI before P2 starts.

No unrelated Account Settings visual redesign in P1A.

## Slice P2 — durable App Mode / navigation preference

**Tracker:** #11

Canonical owner is now live: `user_app_preferences`.

Semantics:

```text
app_mode
→ workout | nutrition | hybrid
→ semantic product experience

active_tabs
→ effective ordered stable navigation IDs
→ initially derived from app_mode
→ later may reflect separately approved customization
```

P2 requirements:

- [ ] backend-neutral App Preferences repository/domain contract;
- [ ] Supabase adapter reads/writes `user_app_preferences`;
- [ ] onboarding completion writes app_mode + derived active_tabs before completion publication;
- [ ] Settings App Mode writes the same row;
- [ ] authenticated bootstrap restores remote preference before final shell configuration;
- [ ] valid remote state wins over stale local cache;
- [ ] SharedPreferences becomes cache/pre-auth staging, not account authority;
- [ ] completed legacy user with no canonical mode never silently becomes Hybrid;
- [ ] fresh-install / second-device / cleared-local-data tests;
- [ ] no custom-tab UI expansion in this slice.

## Slice P3 — common Profile repository cutover

- [ ] create/read/update common Profile through `user_profiles`;
- [ ] onboarding common Profile writes `user_profiles`;
- [ ] Profile Settings common Profile writes `user_profiles`;
- [ ] account fields stay on `users`;
- [ ] remove fabricated Profile defaults when canonical data is absent;
- [ ] canonical `user_profiles` values win over legacy `users` mirrors;
- [ ] stop legacy Profile mirror writes only after parity is proven;
- [ ] no legacy column drop yet.

Current Weight, Target Weight, Body Goal and Goal Pace never move into `user_profiles`.

## Slice P4 — resume Body B2/B3

```text
current weight → body_weight_logs
Body Goal / Target Weight / Goal Pace → user_body_goals
common Profile → user_profiles
account identity/contact → users
```

- [ ] remove Body fields from Profile-owned models/mappers;
- [ ] Profile Settings composes Profile + Body owners at app boundary;
- [ ] current-weight edit appends `body_weight_logs` with `profile_settings` provenance;
- [ ] stop `users.current_weight_kg`, `target_weight_kg`, `goals`, `primary_goal` writes;
- [ ] prove no fabricated 70 kg fallback;
- [ ] full Body/Profile persistence acceptance.

## P5–P7

P5:
```text
Wellness → user_wellness_targets
Nutrition context → user_nutrition_profiles
Nutrition numeric targets → user_nutrition_targets
```

P6:
```text
Workout Profile → user_workout_profiles
Workout Targets → user_workout_targets
```

P7 integrated acceptance:

- Onboarding and Settings use the same canonical owners;
- contacts/verification, Profile and App Mode restore on fresh install/second device;
- Body/Wellness/Nutrition/Workout state survives resume and Settings edits;
- no active legacy mirrored writes remain;
- obsolete columns are removed only in a later forward migration after proof.

## Future backend rule

A future protected backend must use the same canonical Postgres owners and backend-neutral contracts. Do not create a parallel backend schema or re-couple Profile/App Mode/Body into `users` for transport convenience.

Auth providers may change later, but Tio-world's application account verification contract remains `email_verified_at` / `mobile_verified_at`.

## Guardrails

- no destructive rename of `users`;
- no applied migration edits;
- no permanent dual-write synchronization;
- no client-authoritative verification timestamp;
- no fabricated defaults or silent semantic inference;
- App Mode visibility never deletes hidden owner data;
- no UI redesign as part of ownership migration;
- no legacy column drop before repository cutover + validation;
- PR #50 remains Draft/unmerged until persistence gates are complete.

## Handoff

**Current validated slice:** P1 live schema foundation.  
**Next implementation slice:** P1A account contact verification (#8).  
**After P1A:** P2 durable App Mode (#11).  
**Do not jump to P2/P3/P4 before P1A is validated.**
