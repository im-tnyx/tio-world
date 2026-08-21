-- DRAFT ONLY — DO NOT APPLY YET
-- Backfill + validation design for Issue #44 canonical owners.
-- Run only after the approved canonical owner table migration exists.
-- This file is intentionally conflict-first and non-destructive.

begin;

-- ---------------------------------------------------------------------------
-- 0. BLOCK ON DUPLICATE / LOSSY LEGACY CONDITIONS
-- ---------------------------------------------------------------------------

do $$
declare
  conflict_count bigint;
begin
  select count(*)
  into conflict_count
  from public.users u
  join public.user_nutrition_profiles n on n.user_id = u.id
  where
    (u.height_cm is not null and n.height_cm is not null and u.height_cm <> n.height_cm)
    or
    (u.current_weight_kg is not null and n.current_weight_kg is not null and u.current_weight_kg <> n.current_weight_kg)
    or
    (u.target_weight_kg is not null and n.target_weight_kg is not null and u.target_weight_kg <> n.target_weight_kg)
    or
    (
      u.activity_level is not null and
      n.activity_level is not null and
      u.activity_level::text <> n.activity_level::text
    );

  if conflict_count > 0 then
    raise exception
      'Canonical owner migration blocked: % user rows have conflicting duplicated Profile/Body values',
      conflict_count;
  end if;
end;
$$;

-- The canonical Wellness schema stores water millilitres as whole units.
-- Refuse to round/truncate unexpected fractional legacy values.
do $$
declare
  fractional_count bigint;
begin
  select count(*)
  into fractional_count
  from public.user_nutrition_profiles
  where water_target_ml is not null
    and water_target_ml <> trunc(water_target_ml);

  if fractional_count > 0 then
    raise exception
      'Canonical owner migration blocked: % rows have fractional water_target_ml values',
      fractional_count;
  end if;
end;
$$;

-- Calories are canonical whole-kcal targets. Refuse to round a fractional
-- legacy JSON value if one exists.
do $$
declare
  fractional_count bigint;
begin
  select count(*)
  into fractional_count
  from public.user_nutrition_profiles
  where macro_targets is not null
    and jsonb_typeof(macro_targets -> 'calories') = 'number'
    and (macro_targets ->> 'calories')::numeric <> trunc((macro_targets ->> 'calories')::numeric);

  if fractional_count > 0 then
    raise exception
      'Canonical owner migration blocked: % rows have fractional calorie target values',
      fractional_count;
  end if;
end;
$$;

-- A user may have at most one losslessly recognized Body Goal candidate in
-- legacy fields. More than one is ambiguous and must be reviewed manually.
do $$
declare
  ambiguous_count bigint;
begin
  with candidates as (
    select
      u.id,
      array(
        select distinct g
        from unnest(
          coalesce(u.goals, '{}'::text[])
          || array_remove(array[u.primary_goal]::text[], null)
        ) as g
        where g in ('lose_weight', 'gain_weight', 'maintain_weight', 'recomposition')
      ) as body_goals
    from public.users u
  )
  select count(*)
  into ambiguous_count
  from candidates
  where cardinality(body_goals) > 1;

  if ambiguous_count > 0 then
    raise exception
      'Canonical owner migration blocked: % user rows have multiple legacy Body Goal candidates',
      ambiguous_count;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 1. RECONCILE COMMON PROFILE FIELDS INTO public.users
-- users is the approved common Profile authority.
-- Only fill missing values; never overwrite a non-null users value.
-- ---------------------------------------------------------------------------

update public.users u
set height_cm = n.height_cm
from public.user_nutrition_profiles n
where n.user_id = u.id
  and u.height_cm is null
  and n.height_cm is not null;

update public.users u
set activity_level = n.activity_level
from public.user_nutrition_profiles n
where n.user_id = u.id
  and u.activity_level is null
  and n.activity_level is not null;

-- General health-condition reconciliation is intentionally NOT automatic in
-- this draft because legacy Nutrition medical_conditions and users health_conditions
-- may have different semantic scopes. Audit explicitly before adding a backfill.

-- ---------------------------------------------------------------------------
-- 2. CURRENT WEIGHT SNAPSHOT -> body_weight_logs
-- ---------------------------------------------------------------------------

insert into public.body_weight_logs (
  user_id,
  weight_kg,
  measured_at,
  source,
  metadata
)
select
  u.id,
  coalesce(u.current_weight_kg, n.current_weight_kg),
  coalesce(greatest(u.updated_at, n.updated_at), u.updated_at, n.updated_at, timezone('utc'::text, now())),
  'legacy_owner_migration_v1',
  jsonb_build_object(
    'migration', 'canonical_owner_v1',
    'measurement_time_semantics', 'legacy_updated_at_proxy'
  )
from public.users u
left join public.user_nutrition_profiles n on n.user_id = u.id
where coalesce(u.current_weight_kg, n.current_weight_kg) is not null
  and not exists (
    select 1
    from public.body_weight_logs b
    where b.user_id = u.id
      and b.source = 'legacy_owner_migration_v1'
  );

-- ---------------------------------------------------------------------------
-- 3. EXPLICIT BODY GOAL -> user_body_goals
-- No inference from weight delta, BMI, target presence, or Workout meaning.
-- Target Weight / pace are activated only for explicit lose/gain goals.
-- ---------------------------------------------------------------------------

with candidates as (
  select
    u.id,
    u.primary_goal,
    array(
      select distinct g
      from unnest(
        coalesce(u.goals, '{}'::text[])
        || array_remove(array[u.primary_goal]::text[], null)
      ) as g
      where g in ('lose_weight', 'gain_weight', 'maintain_weight', 'recomposition')
    ) as body_goals
  from public.users u
), resolved as (
  select
    c.id,
    c.primary_goal,
    c.body_goals[1] as goal_type
  from candidates c
  where cardinality(c.body_goals) = 1
), source_data as (
  select
    r.id as user_id,
    r.goal_type,
    case
      when r.primary_goal = r.goal_type then 1
      when r.primary_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit') then 2
      else null
    end::smallint as intent_rank,
    coalesce(u.current_weight_kg, n.current_weight_kg) as starting_weight_kg,
    case
      when r.goal_type in ('lose_weight', 'gain_weight')
        then coalesce(u.target_weight_kg, n.target_weight_kg)
      else null
    end as target_weight_kg,
    case
      when r.goal_type in ('lose_weight', 'gain_weight')
        then n.weekly_weight_change_kg
      else null
    end as weekly_weight_change_kg
  from resolved r
  join public.users u on u.id = r.id
  left join public.user_nutrition_profiles n on n.user_id = r.id
)
insert into public.user_body_goals (
  user_id,
  goal_type,
  starting_weight_kg,
  target_weight_kg,
  weekly_weight_change_kg,
  intent_rank,
  status,
  started_at
)
select
  s.user_id,
  s.goal_type,
  s.starting_weight_kg,
  s.target_weight_kg,
  s.weekly_weight_change_kg,
  s.intent_rank,
  'active',
  null
from source_data s
where not exists (
  select 1
  from public.user_body_goals g
  where g.user_id = s.user_id
    and g.status = 'active'
);

-- ---------------------------------------------------------------------------
-- 4. WELLNESS TARGETS -> user_wellness_targets
-- ---------------------------------------------------------------------------

insert into public.user_wellness_targets (
  user_id,
  steps_target,
  water_target_ml,
  sleep_target_minutes,
  bed_time,
  wake_up_time
)
select
  n.user_id,
  n.steps_target,
  case when n.water_target_ml is null then null else n.water_target_ml::integer end,
  n.sleep_target_minutes,
  n.bed_time,
  n.wake_up_time
from public.user_nutrition_profiles n
where n.steps_target is not null
   or n.water_target_ml is not null
   or n.sleep_target_minutes is not null
   or n.bed_time is not null
   or n.wake_up_time is not null
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- 5. TYPED NUTRITION TARGETS -> user_nutrition_targets
-- Only numeric goals migrate. BMR/TDEE are intentionally excluded.
-- Legacy recommended-vs-custom meaning is unknown, so state remains unknown.
-- ---------------------------------------------------------------------------

insert into public.user_nutrition_targets (
  user_id,
  calories_kcal,
  protein_grams,
  carbohydrate_grams,
  fat_grams,
  fiber_grams,
  customization_state,
  customized_fields,
  recommendation_metadata
)
select
  n.user_id,
  case
    when jsonb_typeof(n.macro_targets -> 'calories') = 'number'
      then (n.macro_targets ->> 'calories')::integer
    else null
  end,
  case
    when jsonb_typeof(n.macro_targets -> 'protein') = 'number'
      then (n.macro_targets ->> 'protein')::numeric
    else null
  end,
  case
    when jsonb_typeof(n.macro_targets -> 'carbs') = 'number'
      then (n.macro_targets ->> 'carbs')::numeric
    when jsonb_typeof(n.macro_targets -> 'carbohydrates') = 'number'
      then (n.macro_targets ->> 'carbohydrates')::numeric
    else null
  end,
  case
    when jsonb_typeof(n.macro_targets -> 'fat') = 'number'
      then (n.macro_targets ->> 'fat')::numeric
    else null
  end,
  case
    when jsonb_typeof(n.macro_targets -> 'fiber') = 'number'
      then (n.macro_targets ->> 'fiber')::numeric
    else null
  end,
  'unknown',
  '{}'::text[],
  jsonb_build_object(
    'source', 'legacy_macro_targets',
    'customization_semantics', 'unknown'
  )
from public.user_nutrition_profiles n
where n.macro_targets is not null
  and n.macro_targets <> '{}'::jsonb
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- 6. WORKOUT TARGET/PLAN FIELDS -> user_workout_targets
-- Workout capability/context stays in user_workout_profiles.
-- Only exact new Workout goal strings may be migrated; legacy synonyms are not
-- translated (e.g. keep_fit != stay_fit, boost_strength != get_stronger).
-- ---------------------------------------------------------------------------

with exact_goals as (
  select
    u.id as user_id,
    u.primary_goal,
    array(
      select distinct g
      from unnest(
        coalesce(u.goals, '{}'::text[])
        || array_remove(array[u.primary_goal]::text[], null)
      ) as g
      where g in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
    ) as workout_goals
  from public.users u
), resolved_goals as (
  select
    e.user_id,
    case
      when e.primary_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
        then e.primary_goal
      when cardinality(e.workout_goals) = 1
        then e.workout_goals[1]
      else null
    end as primary_workout_goal,
    case
      when e.primary_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
        then 1
      when e.primary_goal in ('lose_weight', 'gain_weight', 'maintain_weight', 'recomposition')
           and cardinality(e.workout_goals) = 1
        then 2
      else null
    end::smallint as primary_goal_rank,
    case
      when e.primary_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
           and cardinality(e.workout_goals) = 2
        then (
          select g
          from unnest(e.workout_goals) as g
          where g <> e.primary_goal
          limit 1
        )
      else null
    end as supporting_workout_goal,
    case
      when e.primary_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
           and cardinality(e.workout_goals) = 2
        then 2
      else null
    end::smallint as supporting_goal_rank
  from exact_goals e
)
insert into public.user_workout_targets (
  user_id,
  primary_workout_goal,
  primary_goal_rank,
  supporting_workout_goal,
  supporting_goal_rank,
  training_days,
  preferred_duration_mins,
  split_program,
  special_event,
  special_event_date
)
select
  w.user_id,
  g.primary_workout_goal,
  g.primary_goal_rank,
  g.supporting_workout_goal,
  g.supporting_goal_rank,
  coalesce(w.training_days, '{}'::text[]),
  w.workout_duration_mins,
  w.split_program,
  w.special_event_goal,
  null
from public.user_workout_profiles w
left join resolved_goals g on g.user_id = w.user_id
where g.primary_workout_goal is not null
   or (w.training_days is not null and cardinality(w.training_days) > 0)
   or w.workout_duration_mins is not null
   or w.split_program is not null
   or nullif(btrim(w.special_event_goal), '') is not null
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- 7. VALIDATION QUERIES
-- These return evidence; review before committing the transaction in a real run.
-- ---------------------------------------------------------------------------

-- Canonical row counts.
select
  (select count(*) from public.body_weight_logs) as body_weight_log_rows,
  (select count(*) from public.user_body_goals) as body_goal_rows,
  (select count(*) from public.user_wellness_targets) as wellness_rows,
  (select count(*) from public.user_nutrition_targets) as nutrition_target_rows,
  (select count(*) from public.user_workout_targets) as workout_target_rows;

-- Must return zero rows: duplicate active Body Goals.
select user_id, count(*) as active_count
from public.user_body_goals
where status = 'active'
group by user_id
having count(*) > 1;

-- Must return zero rows: orphan canonical owner rows.
select 'body_weight_logs' as table_name, b.user_id
from public.body_weight_logs b
left join public.users u on u.id = b.user_id
where u.id is null
union all
select 'user_body_goals', g.user_id
from public.user_body_goals g
left join public.users u on u.id = g.user_id
where u.id is null
union all
select 'user_wellness_targets', w.user_id
from public.user_wellness_targets w
left join public.users u on u.id = w.user_id
where u.id is null
union all
select 'user_nutrition_targets', n.user_id
from public.user_nutrition_targets n
left join public.users u on u.id = n.user_id
where u.id is null
union all
select 'user_workout_targets', wt.user_id
from public.user_workout_targets wt
left join public.users u on u.id = wt.user_id
where u.id is null;

-- Must return zero rows: hidden Target Weight/Pace on non-directional Body Goals.
select user_id, goal_type, target_weight_kg, weekly_weight_change_kg
from public.user_body_goals
where goal_type in ('maintain_weight', 'recomposition')
  and (target_weight_kg is not null or weekly_weight_change_kg is not null);

-- Must return zero rows: canonical domain FKs that point directly to auth.users.
-- New owners should depend on public.users; Supabase Auth remains an adapter layer.
select
  conrelid::regclass as child_table,
  confrelid::regclass as referenced_table,
  conname
from pg_constraint
where contype = 'f'
  and conrelid in (
    'public.body_weight_logs'::regclass,
    'public.user_body_goals'::regclass,
    'public.user_wellness_targets'::regclass,
    'public.user_nutrition_targets'::regclass,
    'public.user_workout_targets'::regclass
  )
  and confrelid <> 'public.users'::regclass;

-- All new owner tables must have RLS enabled.
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'body_weight_logs',
    'user_body_goals',
    'user_wellness_targets',
    'user_nutrition_targets',
    'user_workout_targets'
  )
order by c.relname;

-- Check that typed Nutrition target backfill did not persist BMR/TDEE columns.
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_nutrition_targets'
  and column_name in ('bmr', 'tdee');

-- In a reviewed live migration, COMMIT only after all evidence is accepted.
-- Keep ROLLBACK while this remains a review/dry-run draft.
rollback;
