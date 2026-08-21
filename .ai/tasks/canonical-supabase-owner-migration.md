# Canonical Supabase Owner Migration

**Status:** SQL drafts authored; review pending; live schema NOT mutated  
**Canonical owner tracker:** #44  
**Related onboarding tracker:** #40 / PR #50

## Outcome

Move Tio-world from mixed/mirrored durable ownership to one canonical owner per concept while keeping the schema usable directly from Supabase today and from a protected backend later.

## Backend-safe database rule

`public.users` is the application/domain user root. New domain tables reference:

```sql
REFERENCES public.users(id) ON DELETE CASCADE
```

not `auth.users(id)` directly.

Supabase Auth remains the current authentication adapter. RLS is an access layer, not the domain model. A future protected backend can read/write the same canonical tables using a server role/connection without changing ownership or table semantics.

## Approved owners

```text
users
user_devices
body_weight_logs
user_body_goals
user_wellness_targets
user_nutrition_profiles
user_nutrition_targets
user_workout_profiles
user_workout_targets
onboarding_drafts
```

`onboarding_drafts` remains temporary/versioned onboarding state only.

## Live audit facts

Latest live `tio-world` Supabase audit:

- affected owner tables currently contain 0 rows;
- `user_nutrition_profiles.target_weight_kg` is nullable;
- existing RLS is enabled but current direct `auth.uid()` expressions are flagged by Supabase performance advisor;
- existing historical owner tables reference `auth.users(id)` directly;
- historical migrations created mixed Profile/Body/Wellness/Nutrition/Workout ownership;
- no applied migration will be edited in place.

The zero-row state lowers current rollout risk, but all draft backfill logic remains conflict-safe for non-empty environments.

## Review artifacts

Drafts are deliberately outside `supabase/migrations/` so they cannot be mistaken for approved live migrations:

```text
supabase/drafts/20260821_canonical_owner_tables.sql
supabase/drafts/20260821_canonical_owner_backfill_and_validation.sql
```

They must be reviewed before an approved version is moved into `supabase/migrations/`.

## Proposed additive schema

### `body_weight_logs`

Canonical weight history/current-weight source.

```text
id UUID PK
user_id UUID FK public.users(id)
weight_kg NUMERIC > 0
measured_at TIMESTAMPTZ
source TEXT
metadata JSONB object
created_at / updated_at
```

Index:

```text
(user_id, measured_at DESC)
```

No second canonical current-weight column is introduced.

### `user_body_goals`

Active/historical Body Goal plans across modes.

```text
id UUID PK
user_id UUID FK public.users(id)
goal_type:
  lose_weight | gain_weight | maintain_weight | recomposition
starting_weight_kg nullable
target_weight_kg nullable
weekly_weight_change_kg nullable
intent_rank nullable 1|2
status:
  active | completed | cancelled | superseded
started_at nullable
ended_at nullable
created_at / updated_at
```

Constraints:

- one active Body Goal per user via partial unique index;
- positive stored weights;
- nonnegative weekly pace;
- Maintain/Recomposition cannot carry canonical Target Weight or Goal Pace;
- `started_at` remains nullable for legacy migration because an unknown historical start date must not be fabricated.

### `user_wellness_targets`

Common cross-mode daily targets:

```text
user_id UUID PK FK public.users(id)
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
created_at / updated_at
```

Only nonnegative structural checks are proposed; tighter medical/product ranges remain domain/input policy.

### `user_nutrition_targets`

Typed Nutrition goals only:

```text
user_id UUID PK FK public.users(id)
calories_kcal
protein_grams
carbohydrate_grams
fat_grams
fiber_grams
customization_state:
  unknown | recommended | custom | mixed
customized_fields TEXT[]
recommendation_metadata JSONB
created_at / updated_at
```

BMR/TDEE are not editable canonical targets and are not typed columns here.

### `user_workout_targets`

Workout-specific goal + plan constraints. Body Goal values are not mirrored here.

```text
user_id UUID PK FK public.users(id)
primary_workout_goal nullable
primary_goal_rank nullable 1|2
supporting_workout_goal nullable
supporting_goal_rank nullable 1|2
training_days
preferred_duration_mins
split_program
special_event
special_event_date
created_at / updated_at
```

Allowed Workout-specific goals:

```text
build_muscle
get_stronger
improve_endurance
stay_fit
```

`lose_weight`, `gain_weight`, `maintain_weight`, `recomposition` remain Body ownership. The optional rank fields preserve overall unified Goal priority across Body/Workout owners when the source semantics are known.

## Existing tables retained during cutover

### `users`

Keep as account + common Profile owner. No `user_profiles` table.

Legacy Body/Goal columns remain physically present temporarily but stop being canonical after repository cutover:

```text
current_weight_kg
target_weight_kg
goals
primary_goal
```

### `user_devices`

Keep separate 1:N device owner.

### `user_nutrition_profiles`

Keep for Nutrition context only after cutover. Existing Body/Wellness/Nutrition-target columns become compatibility-only until later cleanup.

### `user_workout_profiles`

Keep capability/context: location, equipment, experience, focus, injuries/limitations. Training days/duration/split/special event move to `user_workout_targets`.

## RLS + Data API design

All new public tables:

- enable RLS;
- explicitly grant required privileges to `authenticated` and server `service_role` because new Supabase table grants must not be assumed;
- no anon grants;
- use indexed ownership;
- optimized policies use:

```sql
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id)
```

instead of the existing advisor-flagged direct per-row `auth.uid()` pattern.

No `SECURITY DEFINER` helper is needed for ordinary owner CRUD.

## Backfill rules

### Conflict-first invariant

Never silently choose between conflicting duplicated values.

```text
one source non-null  → use it
both equal           → safe
both differ          → raise/block migration
```

The draft also blocks lossy fractional Water/Calories casts instead of silently rounding.

### Common Profile

`users` remains authority. Only missing `height_cm` / `activity_level` may be filled from Nutrition after conflict checks.

General health-condition copy is intentionally NOT automatic yet because legacy Nutrition medical conditions may not be semantically identical to common Profile health conditions.

### Current weight

Resolve `users.current_weight_kg` vs Nutrition current weight only when lossless, then create one `body_weight_logs` migration snapshot. Legacy `updated_at` is explicitly marked as a proxy, not a fabricated measurement timestamp.

### Body Goal

Create a Body Goal only when an exact explicit legacy body goal maps to:

```text
lose_weight
gain_weight
maintain_weight
recomposition
```

No inference from BMI, current/target delta, target presence, or Workout meaning.

Only explicit Lose/Gain may receive backfilled Target Weight / weekly pace. Maintain/Recomposition canonical follow-ups stay null.

### Wellness

Lossless move from old Nutrition columns:

```text
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
```

### Nutrition targets

Extract only numeric macro goal values:

```text
calories
protein
carbs/carbohydrates
fat
fiber
```

Backfilled customization state is `unknown`; do not invent recommended/custom intent. BMR/TDEE are excluded.

### Workout

Stay in Workout Profile:

```text
workout_location
available_equipment
experience_level
focus_areas
injuries/limitations-compatible legacy context
```

Move losslessly to Workout Targets:

```text
training_days
workout_duration_mins
split_program
special_event_goal
```

Only exact new Workout goal strings are eligible for goal backfill. Legacy synonyms such as `keep_fit` and `boost_strength` are not remapped.

## Validation encoded in draft

The backfill/validation draft checks:

- canonical row counts;
- one active Body Goal per user;
- no orphan canonical rows;
- no Target Weight/pace on Maintain/Recomposition;
- new owner FKs point to `public.users`, not directly to `auth.users`;
- RLS is enabled on every new table;
- `user_nutrition_targets` contains no BMR/TDEE columns.

After any live DDL, also run Supabase security + performance advisors and authenticated RLS isolation tests.

## Rollout order

```text
1. owner contract #44                         ✅
2. live schema/RLS/index audit                ✅
3. backend-safe migration/backfill design     ✅
4. review SQL drafts                          NEXT
5. move approved DDL into forward migration
6. apply additive schema
7. validate RLS/grants/advisors
8. run conflict checks + backfill
9. verify counts/null semantics
10. cut repositories/models to owners
11. Onboarding + Settings use same owners
12. stop writes to mirrored legacy columns
13. later cleanup migration drops duplicates
14. rerun PR #50 persistence acceptance/CI
```

## Explicit non-goals before cutover

- no live schema apply before SQL review;
- no legacy column drop;
- no Goal synonym mapping;
- no Target Weight formula change;
- no UI changes;
- no runtime Workout-setting migration;
- no protected backend implementation yet.

## Current next step

**Review the two SQL drafts.** If approved, convert the table draft into the actual forward-only migration, apply the additive schema to `tio-world` Supabase, run RLS/grant/advisor verification, then execute the conflict-safe backfill.