-- ============================================================================
-- Migration: cleanup_legacy_canonical_mirrors
-- Tracker: #111 / parent #54
-- Forward-only O11E canonical schema cleanup.
--
-- Safety model:
--   * lock candidate tables before final assertions;
--   * fail closed if any meaningful legacy value still exists;
--   * allow only schema-default empty compatibility values;
--   * never use CASCADE;
--   * keep public.users.name because account/bootstrap still owns that constraint.
-- ============================================================================

lock table public.users,
           public.user_nutrition_profiles,
           public.user_workout_profiles
  in share row exclusive mode;

-- public.users cleanup is allowed only when no meaningful common-Profile,
-- Body/goal, or legacy-avatar value remains. The legacy unit_preferences column
-- is NOT NULL/defaulted, so the metric default is treated as empty compatibility
-- state rather than user intent. Any non-default value blocks cleanup.
do $$
declare
  unsafe_count bigint;
begin
  select count(*)
    into unsafe_count
  from public.users
  where gender is not null
     or date_of_birth is not null
     or dob is not null
     or height_cm is not null
     or activity_level is not null
     or coalesce(cardinality(health_conditions), 0) > 0
     or nullif(btrim(other_health_condition), '') is not null
     or unit_preferences <>
        '{"weight":"kg","height":"cm","distance":"km","volume":"ml"}'::jsonb
     or current_weight_kg is not null
     or target_weight_kg is not null
     or coalesce(cardinality(goals), 0) > 0
     or nullif(btrim(primary_goal), '') is not null
     or nullif(btrim(profile_image), '') is not null;

  if unsafe_count > 0 then
    raise exception
      'O11E cleanup blocked: % public.users rows still contain meaningful legacy Profile/Body/avatar values',
      unsafe_count;
  end if;
end;
$$;

-- Transitional Nutrition/Profile/Wellness/Body mirrors must be semantically
-- empty. Historical non-empty compatibility data was already handled by the
-- immutable conflict-first canonical-owner backfill migration.
do $$
declare
  unsafe_count bigint;
begin
  select count(*)
    into unsafe_count
  from public.user_nutrition_profiles
  where height_cm is not null
     or current_weight_kg is not null
     or target_weight_kg is not null
     or weekly_weight_change_kg is not null
     or activity_level is not null
     or steps_target is not null
     or water_target_ml is not null
     or sleep_target_minutes is not null
     or bed_time is not null
     or wake_up_time is not null
     or (macro_targets is not null and macro_targets <> '{}'::jsonb);

  if unsafe_count > 0 then
    raise exception
      'O11E cleanup blocked: % user_nutrition_profiles rows still contain meaningful compatibility values',
      unsafe_count;
  end if;
end;
$$;

-- Target/planning mirrors in user_workout_profiles must be empty before they
-- are removed. Canonical planning belongs to user_workout_targets.
do $$
declare
  unsafe_count bigint;
begin
  select count(*)
    into unsafe_count
  from public.user_workout_profiles
  where coalesce(cardinality(training_days), 0) > 0
     or workout_duration_mins is not null
     or split_program is not null
     or nullif(btrim(special_event_goal), '') is not null;

  if unsafe_count > 0 then
    raise exception
      'O11E cleanup blocked: % user_workout_profiles rows still contain meaningful planning mirrors',
      unsafe_count;
  end if;
end;
$$;

-- Explicitly remove the two local CHECK constraints tied to cleanup columns.
alter table public.users
  drop constraint if exists users_unit_preferences_check;

alter table public.user_nutrition_profiles
  drop constraint if exists user_nutrition_profiles_sleep_target_minutes_check;

-- Common Profile, Body/goal and avatar compatibility mirrors.
-- public.users.name intentionally remains for Account/bootstrap.
alter table public.users
  drop column gender,
  drop column date_of_birth,
  drop column dob,
  drop column height_cm,
  drop column activity_level,
  drop column health_conditions,
  drop column other_health_condition,
  drop column unit_preferences,
  drop column current_weight_kg,
  drop column target_weight_kg,
  drop column goals,
  drop column primary_goal,
  drop column profile_image;

-- Nutrition table keeps Nutrition Profile context only; Wellness, Body and
-- Nutrition Targets remain in their canonical owner tables.
alter table public.user_nutrition_profiles
  drop column height_cm,
  drop column current_weight_kg,
  drop column target_weight_kg,
  drop column weekly_weight_change_kg,
  drop column activity_level,
  drop column steps_target,
  drop column water_target_ml,
  drop column sleep_target_minutes,
  drop column bed_time,
  drop column wake_up_time,
  drop column macro_targets;

-- Workout Profile keeps context/capability only. Planning/schedule/targets live
-- exclusively in public.user_workout_targets.
alter table public.user_workout_profiles
  drop column training_days,
  drop column workout_duration_mins,
  drop column split_program,
  drop column special_event_goal;
