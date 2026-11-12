-- W8C: allow the edit flow's optional performed RPE on legacy routine snapshots.
-- Keep the v1 shape/version and all existing field constraints unchanged.
create or replace function private.is_valid_workout_session_snapshot_v1(p_snapshot jsonb)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare
  v_ex jsonb;
  v_set jsonb;
  v_ex_type text;
  v_set_type text;
  v_root_keys text[];
  v_ex_keys text[];
  v_set_keys text[];
  v_routine_name text;
  v_captured_at text;
begin
  if p_snapshot is null or jsonb_typeof(p_snapshot) <> 'object' then
    return false;
  end if;

  -- Technical size ceiling (256 KiB)
  if octet_length(p_snapshot::text) > 262144 then
    return false;
  end if;

  -- Root keys whitelist
  select array_agg(k) into v_root_keys from jsonb_object_keys(p_snapshot) k;
  if not (v_root_keys <@ array['schema_version', 'routine_id', 'routine_name', 'program_id', 'captured_at_utc', 'exercises']) then
    return false;
  end if;

  -- 1. schema_version must be present, number, and equal 1
  if not (p_snapshot ? 'schema_version') or
     jsonb_typeof(p_snapshot->'schema_version') is distinct from 'number' or
     (p_snapshot->>'schema_version') is distinct from '1' then
    return false;
  end if;

  -- 2. Required root fields
  if not (p_snapshot ? 'routine_id') or
     jsonb_typeof(p_snapshot->'routine_id') is distinct from 'string' or
     (p_snapshot->>'routine_id') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
     not (p_snapshot ? 'program_id') or
     jsonb_typeof(p_snapshot->'program_id') is distinct from 'string' or
     (p_snapshot->>'program_id') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
     not (p_snapshot ? 'routine_name') or
     jsonb_typeof(p_snapshot->'routine_name') is distinct from 'string' or
     not (p_snapshot ? 'captured_at_utc') or
     jsonb_typeof(p_snapshot->'captured_at_utc') is distinct from 'string' or
     not (p_snapshot ? 'exercises') or
     jsonb_typeof(p_snapshot->'exercises') is distinct from 'array' or
     jsonb_array_length(p_snapshot->'exercises') = 0 then
    return false;
  end if;

  -- routine_name nonblank check
  v_routine_name := p_snapshot->>'routine_name';
  if length(btrim(v_routine_name)) = 0 then
    return false;
  end if;

  -- Strict parseable ISO-8601 UTC timestamp check
  v_captured_at := p_snapshot->>'captured_at_utc';
  if v_captured_at is null or v_captured_at !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$' then
    return false;
  end if;

  begin
    perform v_captured_at::timestamptz;
  exception when others then
    return false;
  end;

  -- 3. Validate exercise occurrence array
  for v_ex in select jsonb_array_elements(p_snapshot->'exercises') loop
    if v_ex is null or jsonb_typeof(v_ex) <> 'object' or
       not (v_ex ? 'exercise_ref') or
       jsonb_typeof(v_ex->'exercise_ref') is distinct from 'string' or
       length(btrim(v_ex->>'exercise_ref')) = 0 or
       not (v_ex ? 'display_name') or
       jsonb_typeof(v_ex->'display_name') is distinct from 'string' or
       length(btrim(v_ex->>'display_name')) = 0 or
       not (v_ex ? 'occurrence_index') or
       jsonb_typeof(v_ex->'occurrence_index') is distinct from 'number' or
       (v_ex->>'occurrence_index')::numeric < 0 or
       (v_ex->>'occurrence_index')::numeric <> (v_ex->>'occurrence_index')::integer or
       not (v_ex ? 'prescribed_sets') or
       jsonb_typeof(v_ex->'prescribed_sets') is distinct from 'array' then
      return false;
    end if;

    -- Exercise keys whitelist
    select array_agg(k) into v_ex_keys from jsonb_object_keys(v_ex) k;
    if not (v_ex_keys <@ array['exercise_ref', 'display_name', 'exercise_type', 'occurrence_index', 'prescribed_sets']) then
      return false;
    end if;

    -- Canonical exercise_ref format check
    if (v_ex->>'exercise_ref') !~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$' and
       (v_ex->>'exercise_ref') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      return false;
    end if;

    -- exercise_type check (nullable enum matching canonical ExerciseType storage values)
    if v_ex ? 'exercise_type' and jsonb_typeof(v_ex->'exercise_type') is distinct from 'null' then
      if jsonb_typeof(v_ex->'exercise_type') is distinct from 'string' then
        return false;
      end if;
      v_ex_type := v_ex->>'exercise_type';
      if v_ex_type not in (
        'weight_reps', 'distance_duration', 'duration',
        'dumbbell_x2_simultaneous', 'dumbbell_x1_alternating_sides',
        'dumbbell_x1_simultaneous', 'dumbbell_x2_alternating_legs',
        'dumbbell_x1_alternating_legs', 'full_bodyweight',
        'assisted_bodyweight', 'steps_duration'
      ) then
        return false;
      end if;
    end if;

    -- 4. Prescribed sets array check (SetPrescription)
    for v_set in select jsonb_array_elements(v_ex->'prescribed_sets') loop
      if v_set is null or jsonb_typeof(v_set) <> 'object' or
         not (v_set ? 'set_type') or
         jsonb_typeof(v_set->'set_type') is distinct from 'string' then
        return false;
      end if;

      -- `performed_rpe` is an optional W8C edit value; this is an additive v1
      -- extension and does not alter the prescribed set's historical fields.
      select array_agg(k) into v_set_keys from jsonb_object_keys(v_set) k;
      if not (v_set_keys <@ array['set_type', 'reps', 'reps_max', 'load_kg', 'distance_meters', 'duration_seconds', 'rest_seconds', 'performed_rpe']) then
        return false;
      end if;

      v_set_type := v_set->>'set_type';
      if v_set_type not in ('normal', 'warm_up', 'failure', 'drop') then
        return false;
      end if;

      if v_set ? 'reps' and jsonb_typeof(v_set->'reps') is distinct from 'null' then
        if jsonb_typeof(v_set->'reps') is distinct from 'number' or
           (v_set->>'reps')::numeric <= 0 or
           (v_set->>'reps')::numeric <> (v_set->>'reps')::integer then
          return false;
        end if;
      end if;

      if v_set ? 'reps_max' and jsonb_typeof(v_set->'reps_max') is distinct from 'null' then
        if jsonb_typeof(v_set->'reps_max') is distinct from 'number' or
           (v_set->>'reps_max')::numeric < coalesce((v_set->>'reps')::numeric, 1) or
           (v_set->>'reps_max')::numeric <> (v_set->>'reps_max')::integer then
          return false;
        end if;
      end if;

      if v_set ? 'load_kg' and jsonb_typeof(v_set->'load_kg') is distinct from 'null' then
        if jsonb_typeof(v_set->'load_kg') is distinct from 'number' or
           (v_set->>'load_kg')::numeric < 0 then
          return false;
        end if;
      end if;

      if v_set ? 'distance_meters' and jsonb_typeof(v_set->'distance_meters') is distinct from 'null' then
        if jsonb_typeof(v_set->'distance_meters') is distinct from 'number' or
           (v_set->>'distance_meters')::numeric < 0 then
          return false;
        end if;
      end if;

      if v_set ? 'duration_seconds' and jsonb_typeof(v_set->'duration_seconds') is distinct from 'null' then
        if jsonb_typeof(v_set->'duration_seconds') is distinct from 'number' or
           (v_set->>'duration_seconds')::numeric < 0 or
           (v_set->>'duration_seconds')::numeric <> (v_set->>'duration_seconds')::integer then
          return false;
        end if;
      end if;

      if v_set ? 'rest_seconds' and jsonb_typeof(v_set->'rest_seconds') is distinct from 'null' then
        if jsonb_typeof(v_set->'rest_seconds') is distinct from 'number' or
           (v_set->>'rest_seconds')::numeric < 0 or
           (v_set->>'rest_seconds')::numeric <> (v_set->>'rest_seconds')::integer then
          return false;
        end if;
      end if;

      if v_set ? 'performed_rpe' and jsonb_typeof(v_set->'performed_rpe') is distinct from 'null' then
        if jsonb_typeof(v_set->'performed_rpe') is distinct from 'number' or
           (v_set->>'performed_rpe')::numeric not between 0 and 10 then
          return false;
        end if;
      end if;
    end loop;
  end loop;

  return true;
exception
  when others then
    return false;
end;
$$;

revoke all on function private.is_valid_workout_session_snapshot_v1(jsonb)
  from public, anon, authenticated;

comment on function private.is_valid_workout_session_snapshot_v1(jsonb) is
  'Validates v1 workout routine snapshots; W8C adds optional bounded performed_rpe while preserving all prior v1 fields and constraints.';
