-- Superset metadata remains optional on schema-v2 snapshots. The strict v1
-- validator stays unchanged so historical snapshots keep their exact contract.

create function private.workout_snapshot_superset_groups_match(
  p_original jsonb,
  p_updated jsonb
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  with old_snapshot as (
    select case
      when pg_catalog.jsonb_typeof(p_original -> 'exercises') = 'array'
        then p_original -> 'exercises'
      else '[]'::jsonb
    end as exercises,
      case
        when pg_catalog.jsonb_typeof(p_original -> 'superset_groups') = 'array'
          then p_original -> 'superset_groups'
        else '[]'::jsonb
      end as groups
  ), new_snapshot as (
    select case
      when pg_catalog.jsonb_typeof(p_updated -> 'exercises') = 'array'
        then p_updated -> 'exercises'
      else '[]'::jsonb
    end as exercises,
      case
        when pg_catalog.jsonb_typeof(p_updated -> 'superset_groups') = 'array'
          then p_updated -> 'superset_groups'
        else '[]'::jsonb
      end as groups
  ), expected_groups as (
    select coalesce(pg_catalog.jsonb_agg(g.value order by lower(g.value ->> 'id')),
                    '[]'::jsonb) as value
    from old_snapshot as old
    cross join lateral pg_catalog.jsonb_array_elements(old.groups) as g(value)
    where exists (
      select 1
      from new_snapshot as updated
      cross join lateral pg_catalog.jsonb_array_elements(updated.exercises) as e(value)
      where lower(e.value ->> 'superset_id') = lower(g.value ->> 'id')
    )
  ), requested_groups as (
    select coalesce(pg_catalog.jsonb_agg(g.value order by lower(g.value ->> 'id')),
                    '[]'::jsonb) as value
    from new_snapshot as updated
    cross join lateral pg_catalog.jsonb_array_elements(updated.groups) as g(value)
  )
  select p_original is not null and p_updated is not null
     and expected_groups.value = requested_groups.value
  from expected_groups, requested_groups;
$$;

revoke all on function private.workout_snapshot_superset_groups_match(jsonb, jsonb)
  from public, anon, authenticated, service_role;


create or replace function private.is_valid_workout_session_snapshot_v2(p_snapshot jsonb)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare
  v_ex jsonb;
  v_set jsonb;
  v_group jsonb;
  v_group_id text;
  v_group_count bigint;
  v_group_first bigint;
  v_group_last bigint;
  v_index integer := 0;
  v_as_v1 jsonb;
begin
  if p_snapshot is null or jsonb_typeof(p_snapshot) <> 'object'
     or octet_length(p_snapshot::text) > 262144
     or p_snapshot->>'schema_version' is distinct from '2'
     or p_snapshot->>'origin' is null
     or p_snapshot->>'origin' not in ('routine', 'ad_hoc') then
    return false;
  end if;

  if p_snapshot->>'origin' = 'routine' then
    v_as_v1 := (p_snapshot - 'origin') || '{"schema_version":1}'::jsonb;
    return private.is_valid_workout_session_snapshot_v1(v_as_v1);
  end if;

  if exists (select 1 from jsonb_object_keys(p_snapshot) k
             where k <> all(array['schema_version','origin','captured_at_utc','exercises','superset_groups']))
     or (p_snapshot->>'captured_at_utc') !~
       '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$'
     or jsonb_typeof(p_snapshot->'exercises') is distinct from 'array'
     or jsonb_array_length(p_snapshot->'exercises') not between 1 and 100 then
    return false;
  end if;
  perform (p_snapshot->>'captured_at_utc')::timestamptz;

  for v_ex in select value from jsonb_array_elements(p_snapshot->'exercises') loop
    if jsonb_typeof(v_ex) <> 'object'
       or exists (select 1 from jsonb_object_keys(v_ex) k
                  where k <> all(array['exercise_ref','display_name','exercise_type','occurrence_index','prescribed_sets','superset_id']))
       or (v_ex ? 'superset_id' and jsonb_typeof(v_ex->'superset_id') not in ('null','string'))
       or ((v_ex->>'superset_id') is not null and (v_ex->>'superset_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
       or v_ex->>'exercise_ref' is null
       or ((v_ex->>'exercise_ref') !~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'
           and (v_ex->>'exercise_ref') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
       or v_ex->>'display_name' is null
       or char_length(btrim(v_ex->>'display_name')) not between 1 and 200
       or v_ex->>'occurrence_index' is null
       or (v_ex->>'occurrence_index')::integer <> v_index
       or jsonb_typeof(v_ex->'prescribed_sets') is distinct from 'array'
       or jsonb_array_length(v_ex->'prescribed_sets') not between 1 and 8
       or (v_ex->>'exercise_type') is not null and
          (v_ex->>'exercise_type') not in (
            'weight_reps','distance_duration','duration','steps_duration',
            'dumbbell_x2_simultaneous','dumbbell_x1_alternating_sides',
            'dumbbell_x1_simultaneous','dumbbell_x2_alternating_legs',
            'dumbbell_x1_alternating_legs','full_bodyweight','assisted_bodyweight'
          ) then
      return false;
    end if;
    for v_set in select value from jsonb_array_elements(v_ex->'prescribed_sets') loop
      if jsonb_typeof(v_set) <> 'object'
         or exists (select 1 from jsonb_object_keys(v_set) k
                    where k <> all(array['set_type','reps','reps_max','load_kg','distance_meters','duration_seconds','rest_seconds','performed_rpe']))
         or v_set->>'set_type' is null
         or v_set->>'set_type' not in ('normal','warm_up','failure','drop')
         or (v_set->>'reps')::numeric < 0
         or (v_set->>'reps_max')::numeric < coalesce((v_set->>'reps')::numeric, 0)
         or (v_set->>'load_kg')::numeric < 0
         or (v_set->>'distance_meters')::numeric < 0
         or (v_set->>'duration_seconds')::numeric < 0
         or (v_set->>'rest_seconds')::numeric < 0
         or (v_set->>'performed_rpe')::numeric not between 0 and 10 then
        return false;
      end if;
    end loop;
    v_index := v_index + 1;
  end loop;
  if p_snapshot ? 'superset_groups' then
    if jsonb_typeof(p_snapshot->'superset_groups') is distinct from 'array' then
      return false;
    end if;
    if exists (
      select 1 from jsonb_array_elements(p_snapshot->'superset_groups') as g(value)
      where jsonb_typeof(g.value) <> 'object'
         or g.value - 'id' - 'normal_rest_seconds' - 'warm_up_rest_seconds' <> '{}'::jsonb
         or jsonb_typeof(g.value->'id') is distinct from 'string'
         or (g.value->>'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
         or not (g.value ? 'normal_rest_seconds')
         or not (g.value ? 'warm_up_rest_seconds')
         or not private.is_valid_routine_superset_rest_value(g.value->'normal_rest_seconds')
         or not private.is_valid_routine_superset_rest_value(g.value->'warm_up_rest_seconds')
    ) then
      return false;
    end if;
    if exists (
      select lower(g.value->>'id')
      from jsonb_array_elements(p_snapshot->'superset_groups') as g(value)
      group by lower(g.value->>'id')
      having count(*) > 1
    ) then
      return false;
    end if;
    for v_group in
      select g.value
      from jsonb_array_elements(p_snapshot->'superset_groups') as g(value)
    loop
      v_group_id := lower(v_group->>'id');
      select count(*), min(e.ordinality), max(e.ordinality)
        into v_group_count, v_group_first, v_group_last
      from jsonb_array_elements(p_snapshot->'exercises')
        with ordinality as e(value, ordinality)
      where lower(e.value->>'superset_id') = v_group_id;
      if v_group_count < 2 or v_group_count > 3 or
         v_group_last - v_group_first + 1 <> v_group_count then
        return false;
      end if;
    end loop;
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_snapshot->'exercises') as e(value)
    where e.value->>'superset_id' is not null
      and not exists (
        select 1
        from jsonb_array_elements(coalesce(p_snapshot->'superset_groups','[]'::jsonb)) as g(value)
        where lower(g.value->>'id') = lower(e.value->>'superset_id')
      )
  ) then
    return false;
  end if;
  return true;
exception when others then
  return false;
end;
$$;
revoke all on function private.is_valid_workout_session_snapshot_v2(jsonb)
  from public, anon, authenticated;

create or replace function public.rpc_update_completed_workout_v1(
  p_session_id uuid, p_expected_revision integer, p_payload jsonb
) returns public.user_workout_sessions language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_session public.user_workout_sessions;
  v_snapshot jsonb;
  v_new_ex jsonb;
  v_set jsonb;
  v_old_sets jsonb;
  v_id uuid;
  v_index integer;
  v_set_index integer;
  v_selected timestamptz;
  v_offset integer;
begin
  if v_owner is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_session_id is null or p_expected_revision is null or p_expected_revision < 1 or
     p_payload is null or jsonb_typeof(p_payload) <> 'object' or
     octet_length(p_payload::text) > 524288 or
     exists (select 1 from jsonb_object_keys(p_payload) k where k <> all(array[
       'workout_title','description','workout_at_utc','workout_utc_offset_minutes',
       'selected_duration_seconds','gym_name','activity_type','overall_rpe',
       'routine_snapshot','performed_sets'])) then
    raise exception 'invalid_edit_payload' using errcode = '22023';
  end if;
  select * into v_session from public.user_workout_sessions
    where id = p_session_id and user_id = v_owner for update;
  if not found then raise exception 'session_not_found' using errcode = 'P0002'; end if;
  if v_session.status <> 'completed' then
    raise exception 'session_not_completed' using errcode = 'P0003';
  end if;
  if v_session.revision <> p_expected_revision then
    if v_session.revision = p_expected_revision + 1 and
       private.completed_workout_edit_matches(v_session, p_payload) then
      return v_session;
    end if;
    raise exception 'stale_workout_edit' using errcode = 'P0003';
  end if;
  if (p_payload->>'workout_at_utc') !~
       '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$' or
     nullif(btrim(p_payload->>'workout_title'), '') is null or
     char_length(btrim(p_payload->>'workout_title')) > 2000 or
     octet_length(coalesce(p_payload->>'description', '')) > 65536 or
     (nullif(btrim(p_payload->>'gym_name'), '') is not null and
       char_length(btrim(p_payload->>'gym_name')) > 200) or
     (nullif(btrim(p_payload->>'activity_type'), '') is not null and
       char_length(btrim(p_payload->>'activity_type')) > 100) or
     (p_payload->>'overall_rpe')::numeric not between 0 and 10 or
     (p_payload->>'selected_duration_seconds')::integer not between 0 and 2592000 or
     (p_payload->>'workout_utc_offset_minutes')::integer not between -840 and 840 or
     jsonb_typeof(p_payload->'performed_sets') is distinct from 'array' or
     jsonb_array_length(p_payload->'performed_sets') not between 1 and 500 then
    raise exception 'invalid_edit_payload' using errcode = '22023';
  end if;
  v_selected := (p_payload->>'workout_at_utc')::timestamptz;
  v_offset := (p_payload->>'workout_utc_offset_minutes')::integer;
  if v_selected is null or v_selected > v_session.completed_at_utc or
     v_offset is null or p_payload->>'selected_duration_seconds' is null then
    raise exception 'invalid_edit_time' using errcode = '22023';
  end if;
  v_snapshot := p_payload->'routine_snapshot';
  if v_snapshot->>'schema_version' is distinct from v_session.routine_snapshot->>'schema_version' or
     v_snapshot - 'exercises' - 'superset_groups' is distinct from v_session.routine_snapshot - 'exercises' - 'superset_groups' or
     not private.workout_snapshot_superset_groups_match(v_session.routine_snapshot, v_snapshot) or
     not (private.is_valid_workout_session_snapshot_v1(v_snapshot) or
          private.is_valid_workout_session_snapshot_v2(v_snapshot)) then
    raise exception 'invalid_edit_snapshot' using errcode = '22023';
  end if;
  -- Newly selected custom Exercises must still be active and owned. Historical
  -- archived custom refs already in the old snapshot remain usable.
  for v_new_ex in select value from jsonb_array_elements(v_snapshot->'exercises') loop
    if (v_new_ex->>'exercise_ref') ~ '^[0-9a-f]{8}-' and
       not exists (select 1 from jsonb_array_elements(v_session.routine_snapshot->'exercises') o
                   where o->>'exercise_ref' = v_new_ex->>'exercise_ref') and
       not exists (select 1 from public.user_workout_exercises
                   where id = (v_new_ex->>'exercise_ref')::uuid and
                     user_id = v_owner and status = 'active') then
      raise exception 'exercise_not_owned' using errcode = '42501';
    end if;
  end loop;
  if exists (select 1 from jsonb_array_elements(p_payload->'performed_sets') s
             group by s->>'exercise_index', s->>'set_index' having count(*) > 1) or
     exists (select 1 from jsonb_array_elements(p_payload->'performed_sets') s
             where s->>'id' is not null
             group by s->>'id' having count(*) > 1) then
    raise exception 'duplicate_edit_set' using errcode = '22023';
  end if;
  for v_set in select value from jsonb_array_elements(p_payload->'performed_sets') loop
    if jsonb_typeof(v_set) <> 'object' or
       exists (select 1 from jsonb_object_keys(v_set) k where k <> all(array[
         'id','exercise_ref','exercise_index','set_index','reps','load_kg',
         'duration_seconds','distance_meters','completed_at_utc','is_skipped'])) or
       (v_set->>'completed_at_utc' is not null and (v_set->>'completed_at_utc') !~
         '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$') then
      raise exception 'invalid_edit_set' using errcode = '22023';
    end if;
    v_index := (v_set->>'exercise_index')::integer;
    v_set_index := (v_set->>'set_index')::integer;
    if v_index is null or v_index < 0 or v_index >= jsonb_array_length(v_snapshot->'exercises') or
       v_set_index is null or v_set_index < 0 or v_set_index > 7 then
      raise exception 'invalid_edit_slot' using errcode = '22023';
    end if;
    v_new_ex := (v_snapshot->'exercises')->v_index;
    if v_set_index >= jsonb_array_length(v_new_ex->'prescribed_sets') or
       v_set->>'exercise_ref' is distinct from v_new_ex->>'exercise_ref' or
       (v_set->>'completed_at_utc')::timestamptz not between
         v_session.started_at_utc and v_session.completed_at_utc or
       (v_set->>'reps')::integer not between 0 and 999 or
       (v_set->>'load_kg')::double precision < 0 or
       (v_set->>'duration_seconds')::integer < 0 or
       (v_set->>'distance_meters')::double precision < 0 then
      raise exception 'invalid_edit_set' using errcode = '22023';
    end if;
    if coalesce((v_set->>'is_skipped')::boolean, false) then
      if v_set->>'reps' is not null or v_set->>'load_kg' is not null or
         v_set->>'duration_seconds' is not null or v_set->>'distance_meters' is not null then
        raise exception 'skipped_set_has_measurement' using errcode = '22023';
      end if;
    elsif v_new_ex->>'exercise_type' in ('duration','steps_duration') then
      if v_set->>'completed_at_utc' is null then
        raise exception 'missing_performed_time' using errcode = '22023';
      end if;
      if v_set->>'duration_seconds' is null or v_set->>'reps' is not null or
         v_set->>'load_kg' is not null or v_set->>'distance_meters' is not null then
        raise exception 'invalid_duration_measurement' using errcode = '22023';
      end if;
    elsif v_new_ex->>'exercise_type' = 'distance_duration' then
      if v_set->>'completed_at_utc' is null then
        raise exception 'missing_performed_time' using errcode = '22023';
      end if;
      if v_set->>'duration_seconds' is null or v_set->>'distance_meters' is null or
         v_set->>'reps' is not null or v_set->>'load_kg' is not null then
        raise exception 'invalid_distance_measurement' using errcode = '22023';
      end if;
    elsif v_set->>'completed_at_utc' is null or
          v_set->>'duration_seconds' is not null or
          v_set->>'distance_meters' is not null or
          (v_set->>'reps' is null and v_set->>'load_kg' is null) then
      raise exception 'invalid_weight_reps_measurement' using errcode = '22023';
    end if;
    if v_set->>'id' is not null and not exists (
      select 1 from public.user_workout_performed_sets
      where id = (v_set->>'id')::uuid and session_id = p_session_id and user_id = v_owner
    ) then raise exception 'set_not_owned' using errcode = '42501'; end if;
  end loop;
  if not exists (select 1 from jsonb_array_elements(p_payload->'performed_sets') s
                 where coalesce((s->>'is_skipped')::boolean, false) = false) or
     exists (select 1 from jsonb_array_elements(v_snapshot->'exercises') with ordinality ex(value, n)
             where not exists (
               select 1 from jsonb_array_elements(p_payload->'performed_sets') s
               where (s->>'exercise_index')::integer = ex.n - 1 and
                     coalesce((s->>'is_skipped')::boolean, false) = false
             )) then
    raise exception 'exercise_without_performed_set' using errcode = '22023';
  end if;
  select coalesce(jsonb_object_agg(id::text, to_jsonb(s)), '{}'::jsonb)
    into v_old_sets from public.user_workout_performed_sets s
    where session_id = p_session_id and user_id = v_owner;
  perform set_config('tio_w8c.edit_session_id', p_session_id::text, true);
  update public.user_workout_sessions set
    workout_title = btrim(p_payload->>'workout_title'),
    notes = nullif(btrim(p_payload->>'description'), ''),
    workout_at_utc = v_selected,
    workout_utc_offset_minutes = v_offset,
    local_date = ((v_selected at time zone 'UTC') + make_interval(mins => v_offset))::date,
    workout_duration_seconds = (p_payload->>'selected_duration_seconds')::integer,
    gym_name = nullif(btrim(p_payload->>'gym_name'), ''),
    workout_activity_type = nullif(btrim(p_payload->>'activity_type'), ''),
    workout_rpe = (p_payload->>'overall_rpe')::numeric,
    routine_snapshot = v_snapshot,
    revision = revision + 1
  where id = p_session_id and user_id = v_owner;
  delete from public.user_workout_performed_sets
    where session_id = p_session_id and user_id = v_owner;
  for v_set in select value from jsonb_array_elements(p_payload->'performed_sets') loop
    v_id := coalesce((v_set->>'id')::uuid, gen_random_uuid());
    insert into public.user_workout_performed_sets (
      id,session_id,user_id,exercise_ref,session_exercise_index,set_index,
      reps,load_kg,duration_seconds,distance_meters,completed_at_utc,
      is_skipped,notes,created_at
    ) values (
      v_id,p_session_id,v_owner,v_set->>'exercise_ref',
      (v_set->>'exercise_index')::integer,(v_set->>'set_index')::integer,
      (v_set->>'reps')::integer,(v_set->>'load_kg')::double precision,
      (v_set->>'duration_seconds')::integer,(v_set->>'distance_meters')::double precision,
      (v_set->>'completed_at_utc')::timestamptz,
      coalesce((v_set->>'is_skipped')::boolean,false),
      v_old_sets -> (v_id::text) ->> 'notes',
      coalesce((v_old_sets -> (v_id::text) ->> 'created_at')::timestamptz,now())
    );
  end loop;
  perform set_config('tio_w8c.edit_session_id', '', true);
  select * into v_session from public.user_workout_sessions where id = p_session_id;
  return v_session;
end;
$$;
revoke all on function public.rpc_update_completed_workout_v1(uuid,integer,jsonb)
  from public, anon;
grant execute on function public.rpc_update_completed_workout_v1(uuid,integer,jsonb)
  to authenticated;
