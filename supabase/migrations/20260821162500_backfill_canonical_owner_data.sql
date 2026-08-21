-- ============================================================================
-- Migration: backfill_canonical_owner_data
-- Tracker: #44
--
-- Conflict-first, non-destructive backfill from legacy/mirrored owner columns
-- into the canonical owner tables. Ambiguous or lossy data blocks migration;
-- no semantic intent is fabricated.
-- ============================================================================

-- Block conflicting duplicate Profile/Body values.
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
    or (u.current_weight_kg is not null and n.current_weight_kg is not null and u.current_weight_kg <> n.current_weight_kg)
    or (u.target_weight_kg is not null and n.target_weight_kg is not null and u.target_weight_kg <> n.target_weight_kg)
    or (
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

-- Refuse to truncate fractional legacy water millilitres.
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

-- Refuse to round fractional calorie targets.
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

-- Refuse ambiguous multiple Body Goal candidates.
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

-- Common Profile authority remains public.users. Fill only missing values.
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

-- Current weight snapshot -> body_weight_logs.
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
  coalesce(
    greatest(u.updated_at, n.updated_at),
    u.updated_at,
    n.updated_at,
    timezone('utc'::text, now())
  ),
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

-- Explicit Body Goal only. Never infer from BMI, target/current delta, or target presence.
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

-- Common Wellness targets.
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

-- Typed Nutrition targets only. BMR/TDEE deliberately excluded.
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

-- Workout goal + plan constraints. Body Goal values are not mirrored here.
-- Exact new Workout strings only; legacy synonyms are intentionally unmapped.
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
  u.id,
  g.primary_workout_goal,
  g.primary_goal_rank,
  g.supporting_workout_goal,
  g.supporting_goal_rank,
  coalesce(w.training_days, '{}'::text[]),
  w.workout_duration_mins,
  w.split_program,
  w.special_event_goal,
  null
from public.users u
left join public.user_workout_profiles w on w.user_id = u.id
left join resolved_goals g on g.user_id = u.id
where g.primary_workout_goal is not null
   or (w.training_days is not null and cardinality(w.training_days) > 0)
   or w.workout_duration_mins is not null
   or w.split_program is not null
   or nullif(btrim(w.special_event_goal), '') is not null
on conflict (user_id) do nothing;
