# Canonical Supabase Owner Migration

**Status:** Schema/backfill applied; Body B1 validated; account/profile/preferences split approved and queued  
**Canonical owner tracker:** #44  
**Related trackers:** #11, #40 / PR #50

## Outcome

Keep one durable owner per concept in the live `tio-world` Supabase project while preserving `public.users(id)` as the stable account/domain root for current Supabase and future backend adapters.

## Approved durable owners — current authority

```text
users
→ account/domain root only

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

### Superseded ownership decision

The earlier decision that `users` should permanently own common Profile data is superseded.

Do **not** rename or replace `users`. Existing canonical domain FKs continue to reference `public.users(id)`.

Common Profile moves to `user_profiles`; App Mode/navigation preferences move to `user_app_preferences`.

## Already-applied migrations

```text
supabase/migrations/20260821161923_create_canonical_owner_tables.sql
supabase/migrations/20260821162207_backfill_canonical_owner_data.sql
```

Never edit these applied migrations in place. The approved `user_profiles` / `user_app_preferences` split requires a new forward-only migration.

## Existing live schema/security contract verified

For the already-created Body/Wellness/Nutrition/Workout owner tables:

- domain FKs reference `public.users(id)`, not `auth.users(id)` directly;
- RLS enabled;
- authenticated CRUD grants present;
- optimized `(select auth.uid()) = user_id` owner policies;
- one active Body Goal per user enforced;
- Maintain/Recomposition cannot store Target Weight/Goal Pace;
- no invalid/orphan canonical rows found after migration.

## Current legacy compatibility state

`users` still physically contains common Profile and Body mirror fields. This is transitional, not final ownership.

Do not drop yet:

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

`user_nutrition_profiles` and `user_workout_profiles` also still contain legacy mixed fields pending their repository splits.

No permanent bidirectional synchronization may be introduced.

## Repository cutover evidence

### Body Cutover A — validated ✅

```text
9031dc5e51a71b1bcef905bd93088f36396d3c01
Flutter CI #1135 / run 32505095642 ✅
```

Canonical onboarding Body writes now target `body_weight_logs` + `user_body_goals`.

### Body Cutover B1 — validated ✅

```text
e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413
Analyze Flutter packages  ✅
Analyze Dart packages     ✅
Test Flutter packages     ✅
Test Dart packages        ✅
```

B1 established backend-neutral Body reads/history commands, latest-weight reads, active Body Goal reads, no fabricated `70 kg`, explicit provenance, and separate onboarding-retry vs post-onboarding history semantics.

## New required foundation before Profile/Settings Body cleanup

The approved account/profile/preferences split changes the next order.

Read `.ai/tasks/account-profile-app-preferences-canonical-split.md` before changing Profile or App Mode persistence.

### P1 — additive schema foundation

Create via a new forward migration:

```text
user_profiles
→ user_id PK/FK public.users(id)
→ common Profile fields only

user_app_preferences
→ user_id PK/FK public.users(id)
→ app_mode
→ active_tabs
```

P1 must include RLS, grants, constraints, deterministic backfill, validation SQL and advisors. No legacy columns are dropped.

### P2 — App Mode / navigation cutover

`user_app_preferences` becomes canonical App Mode/navigation owner. SharedPreferences becomes cache/pre-auth staging only.

### P3 — common Profile cutover

Onboarding/Profile Settings common Profile reads/writes move to `user_profiles`. Account fields remain on `users`.

### P4 — resume Body B2/B3

Once P3 is validated, remove Body ownership from Profile models/writes and compose `user_profiles` + Body owner at the app boundary.

## Remaining canonical cutover order

```text
B1 Body read/history contract                     VALIDATED #1153
        ↓
P1 user_profiles + user_app_preferences schema
        ↓
P2 durable App Mode / active_tabs cutover
        ↓
P3 common Profile repository cutover
        ↓
P4 Body B2/B3 Profile/Settings composition + mirror shutdown
        ↓
P5 Wellness/Nutrition split + Nutrition mirror shutdown
        ↓
P6 Workout Profile/Targets split
        ↓
P7 integrated persistence acceptance
        ↓
later forward migration removes obsolete legacy columns
```

## Final ownership boundaries

### `users`

Account/domain root. Keep account/auth-linked identity/status such as username/contact/avatar/timezone/plan/account lifecycle according to repository audit. Do not add health/body/nutrition/workout ownership back for convenience.

### `user_profiles`

Common personal/profile baseline only:

- name;
- gender;
- `date_of_birth` as the single canonical DOB concept;
- height;
- activity level;
- general health conditions;
- unit preferences.

Current Weight, Target Weight, Goal Pace and Body Goal do not belong here.

### `user_app_preferences`

Account-level app experience preferences:

- `app_mode`: workout / nutrition / hybrid;
- ordered `active_tabs`;
- future app-level preferences only when separately approved.

Onboarding draft `selected_mode` is draft/resume state, not final preference authority.

## Future backend rule

A future protected backend must use these same Postgres owners and backend-neutral contracts. `public.users(id)` remains the stable root; do not create a parallel backend schema or re-couple Profile/App Preferences/Body data into `users` for transport convenience.

## Guardrails

- one durable owner per concept;
- no destructive rename of `users`;
- no applied migration edits;
- no fake Goal mappings or BMI/numeric semantic inference;
- no fabricated defaults;
- no permanent dual-write synchronization;
- Settings and Onboarding are entry points, not owners;
- no legacy column drop before verified cutover;
- no UI redesign/picker/recommendation-formula change in persistence work.

## Current next step

**P1 — audit and create the additive `user_profiles` + `user_app_preferences` migration.**
