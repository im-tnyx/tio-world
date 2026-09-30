-- W3D2: optional structured definitions on existing user-owned Exercises.
-- Legacy rows keep NULL scalars and an empty array; no guessed backfill.
-- RLS, identity, immutable lineage and archive lifecycle remain unchanged.

create function private.valid_user_exercise_muscles(
  p_primary text,
  p_secondary text[]
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  with taxonomy as (
    -- W3D2 muscle tokens (kept equal to UserExerciseDefinition by parity test).
    select array[
    'sternocleidomastoid',
    'pectoralis_major_sternal_head',
    'pectoralis_major_clavicular_head',
    'deltoid_anterior',
    'deltoid_lateral',
    'brachioradialis',
    'rectus_abdominis',
    'sartorius',
    'serratus_anterior',
    'pectineus',
    'transverse_abdominis',
    'tensor_fasciae_latae',
    'iliopsoas',
    'wrist_extensors',
    'wrist_flexors',
    'deltoid_posterior',
    'trapezius_lower_fibers',
    'trapezius_upper_fibers',
    'trapezius_middle_fibers',
    'infraspinatus',
    'teres_major',
    'teres_minor',
    'latissimus_dorsi',
    'erector_spinae',
    'adductor_longus',
    'adductor_magnus',
    'gluteus_maximus',
    'gluteus_medius',
    'hamstrings',
    'gracilis',
    'levator_scapulae',
    'popliteus',
    'splenius',
    'triceps_brachii',
    'biceps_brachii',
    'brachialis',
    'obliques',
    'quadriceps',
    'gastrocnemius',
    'tibialis_anterior',
    'soleus',
    'gluteus_minimus',
    'deep_hip_external_rotators',
    'serratus_anterior_alternate'
  ]::text[] as allowed
  )
  select case when coalesce(array_ndims(p_secondary), 1) <> 1 then false else
    (p_primary is null or p_primary = any(allowed))
    and p_secondary is not null
    and (cardinality(p_secondary) = 0 or (
      array_ndims(p_secondary) = 1 and array_lower(p_secondary, 1) = 1
    ))
    and array_position(p_secondary, null) is null
    and p_secondary <@ allowed
    and cardinality(p_secondary) = (
      select count(distinct token) from unnest(p_secondary) as tokens(token)
    )
    and (p_primary is null or not (p_primary = any(p_secondary)))
  end
  from taxonomy;
$$;

revoke all on function private.valid_user_exercise_muscles(text, text[])
  from public, anon;
grant execute on function private.valid_user_exercise_muscles(text, text[])
  to authenticated, service_role;

alter table public.user_workout_exercises
  add column description text,
  add column exercise_type text,
  add column primary_muscle text,
  add column secondary_muscles text[] not null default '{}',
  add column primary_equipment text,
  add constraint user_workout_exercises_description_nonblank
    check (description is null or description ~ '[^[:space:]]'),
  add constraint user_workout_exercises_type_check
    -- W3D2 type tokens.
    check (exercise_type is null or exercise_type = any(array[
    'weight_reps',
    'distance_duration',
    'duration',
    'dumbbell_x2_simultaneous',
    'dumbbell_x1_alternating_sides',
    'dumbbell_x1_simultaneous',
    'dumbbell_x2_alternating_legs',
    'dumbbell_x1_alternating_legs',
    'full_bodyweight',
    'assisted_bodyweight',
    'steps_duration'
  ]::text[])),
  add constraint user_workout_exercises_muscles_check
    check (private.valid_user_exercise_muscles(primary_muscle, secondary_muscles)),
  add constraint user_workout_exercises_equipment_check
    -- W3D2 equipment tokens.
    check (primary_equipment is null or primary_equipment = any(array[
    'barbell',
    'bodyweight',
    'cable',
    'dumbbell',
    'ez_bar',
    'lever_machine',
    'sled_machine',
    'smith_machine',
    'weighted',
    'band',
    'kettlebell',
    'medicine_ball',
    'power_sled',
    'resistance_band',
    'stability_ball',
    'suspension',
    'trap_bar',
    'wheel_roller'
  ]::text[]));

-- Preserve table SELECT and existing column grants. No table-wide write grant.
grant insert (
  description, exercise_type, primary_muscle, secondary_muscles, primary_equipment
) on public.user_workout_exercises to authenticated;
grant update (
  description, exercise_type, primary_muscle, secondary_muscles, primary_equipment
) on public.user_workout_exercises to authenticated;
