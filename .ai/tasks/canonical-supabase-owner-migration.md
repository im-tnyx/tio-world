# Canonical Supabase Owner Migration

**Status:** Design approved enough to draft; live schema NOT mutated yet  
**Canonical owner tracker:** #44  
**Related onboarding tracker:** #40 / PR #50

## Outcome

Move Tio-world from mixed/mirrored durable ownership to one canonical owner per concept while keeping the schema usable directly from Supabase today and from a protected backend later.

## Backend-safe database rule

`public.users` is the application/domain user root. New domain tables should reference:

```sql
REFERENCES public.users(id) ON DELETE CASCADE
```

not `auth.users(id)` directly.

Supabase Auth remains the current authentication adapter. `public.users.id` is currently linked to `auth.users(id)`, but Body/Wellness/Nutrition/Workout tables should depend on the application user contract rather than the authentication provider contract.

RLS is a Supabase access layer, not the data model. A future backend may access the same canonical tables using an appropriate server role/connection without changing table semantics.

## Approved canonical owners

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

At the latest migration-design audit:

- live project: `tio-world`;
- affected canonical owner tables currently contain zero rows;
- `user_nutrition_profiles.target_weight_kg` is nullable;
- current RLS is enabled but uses direct `auth.uid()` expressions that Supabase's advisor flags for per-row reevaluation;
- current owner tables reference `auth.users(id)` directly;
- historical migrations created mixed Profile/Body/Wellness/Nutrition/Workout ownership;
- no existing migration should be edited in place.

The zero-row state makes current rollout low-risk, but the migration/backfill must remain safe and idempotent for non-empty environments.

## Migration A — additive canonical schema only

The first forward migration must NOT drop old columns.

### `body_weight_logs`

Purpose: canonical weight history; latest applicable row is current weight.

Recommended shape:

```text
id UUID PK default gen_random_uuid()
user_id UUID NOT NULL FK public.users(id) ON DELETE CASCADE
weight_kg NUMERIC NOT NULL CHECK weight_kg > 0
measured_at TIMESTAMPTZ NOT NULL DEFAULT now()
source TEXT NULL
metadata JSONB NOT NULL DEFAULT '{}'
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

Indexes:

```text
(user_id, measured_at DESC)
```

Do not duplicate current weight into another canonical table.

### `user_body_goals`

Purpose: active/historical Body Goal plans shared across modes.

Recommended shape:

```text
id UUID PK default gen_random_uuid()
user_id UUID NOT NULL FK public.users(id) ON DELETE CASCADE
goal_type TEXT NOT NULL CHECK in:
  lose_weight | gain_weight | maintain_weight | recomposition
starting_weight_kg NUMERIC NULL CHECK > 0 when present
target_weight_kg NUMERIC NULL CHECK > 0 when present
weekly_weight_change_kg NUMERIC NULL CHECK >= 0 when present
intent_rank SMALLINT NULL CHECK in (1,2)
status TEXT NOT NULL CHECK in:
  active | completed | cancelled | superseded
started_at TIMESTAMPTZ NULL
ended_at TIMESTAMPTZ NULL
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

Indexes/constraints:

```text
(user_id, created_at DESC)
UNIQUE(user_id) WHERE status = 'active'
```

`started_at` is nullable because legacy data does not provide a trustworthy historical goal-start timestamp. Do not fabricate one during backfill.

### `user_wellness_targets`

Purpose: common daily Wellness targets, independent of Nutrition mode.

Recommended shape:

```text
user_id UUID PK FK public.users(id) ON DELETE CASCADE
steps_target INTEGER NULL CHECK >= 0
water_target_ml INTEGER NULL CHECK >= 0
sleep_target_minutes INTEGER NULL CHECK >= 0
bed_time TIME NULL
wake_up_time TIME NULL
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

Avoid medical/product range constraints unless separately approved; repository/input validation may apply tighter UX ranges.

### `user_nutrition_targets`

Purpose: typed numeric Nutrition goals only.

Recommended shape:

```text
user_id UUID PK FK public.users(id) ON DELETE CASCADE
calories_kcal INTEGER NULL CHECK > 0 when present
protein_grams NUMERIC NULL CHECK >= 0 when present
carbohydrate_grams NUMERIC NULL CHECK >= 0 when present
fat_grams NUMERIC NULL CHECK >= 0 when present
fiber_grams NUMERIC NULL CHECK >= 0 when present
customized_fields TEXT[] NOT NULL DEFAULT '{}'
recommendation_metadata JSONB NOT NULL DEFAULT '{}'
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

BMR/TDEE are not canonical editable targets. Legacy BMR/TDEE values must not be backfilled into typed goal columns.

### `user_workout_targets`

Purpose: current Workout objective/plan constraints; Workout Profile remains capability/context.

Recommended shape:

```text
user_id UUID PK FK public.users(id) ON DELETE CASCADE
workout_goals TEXT[] NOT NULL DEFAULT '{}'
training_days TEXT[] NOT NULL DEFAULT '{}'
preferred_duration_mins INTEGER NULL CHECK > 0 when present
split_program TEXT NULL
special_event TEXT NULL
special_event_date DATE NULL
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

Only lossless Workout goal values may be persisted. Body goals stay in `user_body_goals`; do not mirror `lose_weight`/`recomposition` into Workout ownership merely for convenience.

Exact cross-owner primary/supporting priority handling must preserve user intent during repository cutover; `intent_rank` on Body Goal leaves room for this without making Onboarding the owner.

## Existing canonical tables retained

### `users`

Keep as account + common Profile owner. No `user_profiles` table.

Canonical fields include name, gender, date of birth, height, activity level, general health conditions, unit preferences, timezone/profile/account fields.

Legacy Body/Goal columns remain physically present during compatibility but stop being canonical after cutover:

```text
current_weight_kg
target_weight_kg
goals
primary_goal
```

### `user_devices`

Keep separate 1:N device owner.

### `user_nutrition_profiles`

Keep existing table but canonical writes after cutover are limited to Nutrition context such as diet/allergies/preferences. Mixed Body/Wellness/target columns remain compatibility-only until later cleanup.

### `user_workout_profiles`

Keep existing table for location/equipment/experience/focus/injuries/limitations. Training days/duration/split/special-event move to `user_workout_targets`.

## RLS and grants for new tables

All new public tables:

1. enable RLS;
2. explicitly grant required Data API privileges because new Supabase behavior no longer guarantees automatic grants;
3. expose only authenticated user CRUD needed by the product;
4. use indexed `user_id` ownership;
5. use optimized policies:

```sql
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id)
```

rather than direct per-row `auth.uid()` evaluation.

For UPDATE, both SELECT policy and UPDATE `USING` + `WITH CHECK` are required.

No `SECURITY DEFINER` helper is needed for ordinary owner CRUD.

## Backfill safety rules

Never silently choose between conflicting duplicate legacy values.

For duplicate fields such as height/current weight/target weight/activity:

```text
only one source non-null   → use it
both sources equal         → safe
both sources differ        → report conflict and block that row from automatic migration
```

Current live audit found no overlapping conflicts.

### Current weight → `body_weight_logs`

Sources:

```text
users.current_weight_kg
user_nutrition_profiles.current_weight_kg
```

If losslessly resolvable, insert one migration snapshot row. Use legacy update timestamps only as migration provenance; do not pretend they are a precise physical measurement time when unknown. Mark source/metadata as legacy migration.

### Body Goal → `user_body_goals`

Sources may include:

```text
users.goals
users.primary_goal
users.target_weight_kg
user_nutrition_profiles.target_weight_kg
user_nutrition_profiles.weekly_weight_change_kg
```

Create a Body Goal only when an explicit legacy goal maps losslessly to one of:

```text
lose_weight
gain_weight
maintain_weight
recomposition
```

Do not infer Body Goal from BMI, target/current delta, Target Weight presence, or Workout-only meanings.

Target Weight / weekly pace without a trustworthy explicit Body Goal remain unmapped compatibility data; do not fabricate intent.

### Wellness → `user_wellness_targets`

Lossless fields:

```text
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
```

### Nutrition targets → `user_nutrition_targets`

Extract only typed Nutrition goal values from legacy `macro_targets` when numeric and valid:

```text
calories
protein
carbs/carbohydrates
fat
fiber
```

Legacy origin/custom-vs-recommended meaning is unknown unless explicitly stored, so backfilled metadata must say legacy/unknown rather than inventing `custom` or `recommended` intent.

Do not migrate BMR/TDEE as editable Nutrition targets.

### Workout → split existing row

Stay in `user_workout_profiles`:

```text
workout_location
available_equipment
experience_level
focus_areas
injuries/limitations-compatible legacy data
```

Move losslessly to `user_workout_targets`:

```text
training_days
workout_duration_mins
split_program
special_event_goal
```

Do not invent a Workout Goal from focus areas, body goal, or other context.

### Common Profile duplicate reconciliation

`users` remains authority for common Profile data after conflict audit. Nutrition copies of height/activity/general medical context must stop receiving canonical writes after repository cutover.

Do not delete old columns in Migration A.

## Rollout order

```text
A. additive canonical tables + grants/RLS/indexes
B. dry-run conflict queries
C. idempotent backfill
D. verify row counts / null semantics / active-goal uniqueness
E. repository/model cutover
F. Onboarding + Settings use same owners
G. stop writes to mirrored legacy columns
H. compatibility reads only if deliberately required
I. production verification + advisors
J. later cleanup migration drops legacy duplicate columns
```

The future backend can be introduced between E and I without changing canonical table ownership: it reads/writes the same `public.users`-rooted model.

## Validation after any live DDL

- inspect tables/columns/constraints/indexes;
- test authenticated RLS owner isolation;
- test insert/select/update/delete where allowed;
- run security advisors;
- run performance advisors;
- verify Data API grants;
- run backfill conflict/count queries;
- verify one-active-Body-Goal constraint;
- verify latest Weight lookup index;
- verify app repository tests and full Flutter/Dart CI.

## Explicit non-goals of Migration A

- dropping old columns;
- changing Target Weight recommendation formula;
- inventing Goal mappings;
- changing UI;
- moving runtime Workout settings;
- introducing a protected backend now;
- making Supabase-specific auth tables the domain FK boundary for new owner tables.

## Current next step

Review this migration design, then author the actual forward-only SQL migration and validation SQL. Do not apply live DDL until the SQL is reviewed.