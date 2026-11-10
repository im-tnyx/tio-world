-- W7C Save-only: one authenticated, atomic commit from an owner-bound local draft.
-- Source-only until the ordered W7B -> W7C metadata -> Save-only hosted rollout
-- receives separate authorization. Existing W7B RPC signatures stay unchanged.

alter table public.user_workout_sessions
  alter column program_id drop not null,
  alter column routine_id drop not null,
  add column save_request_id uuid,
  add column workout_activity_type text,
  add column gym_name text,
  add column workout_rpe numeric,
  add column workout_duration_seconds integer,
  add constraint chk_user_workout_sessions_origin_pair
    check ((program_id is null) = (routine_id is null)),
  add constraint uq_user_workout_sessions_save_request
    unique (user_id, save_request_id),
  add constraint chk_user_workout_sessions_activity_type
    check (workout_activity_type is null or char_length(btrim(workout_activity_type)) between 1 and 100),
  add constraint chk_user_workout_sessions_gym_name
    check (gym_name is null or char_length(btrim(gym_name)) between 1 and 200),
  add constraint chk_user_workout_sessions_rpe
    check (workout_rpe is null or workout_rpe between 0 and 10),
  add constraint chk_user_workout_sessions_selected_duration
    check (workout_duration_seconds is null or workout_duration_seconds between 0 and 2592000);

comment on column public.user_workout_sessions.save_request_id is
  'Owner-scoped stable idempotency identity for a Save-only workout.';
comment on column public.user_workout_sessions.workout_duration_seconds is
  'User-selected Save duration; canonical active elapsed time remains derived from session transitions.';

create or replace function private.is_valid_workout_session_snapshot_v2(p_snapshot jsonb)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare
  v_ex jsonb;
  v_set jsonb;
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
             where k <> all(array['schema_version','origin','captured_at_utc','exercises']))
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
                  where k <> all(array['exercise_ref','display_name','exercise_type','occurrence_index','prescribed_sets']))
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
            'weight_reps','distance_duration','duration',
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
  return true;
exception when others then
  return false;
end;
$$;
revoke all on function private.is_valid_workout_session_snapshot_v2(jsonb)
  from public, anon, authenticated;

-- Preserve the v1 routine-start contract while allowing validated ad-hoc v2.
create or replace function public.trg_fn_validate_workout_session_snapshot()
returns trigger
language plpgsql
as $$
begin
  if not (
    (new.routine_snapshot->>'schema_version' = '1'
      and private.is_valid_workout_session_snapshot_v1(new.routine_snapshot))
    or (new.routine_snapshot->>'schema_version' = '2'
      and private.is_valid_workout_session_snapshot_v2(new.routine_snapshot)
      and ((new.routine_snapshot->>'origin' = 'ad_hoc' and new.program_id is null and new.routine_id is null)
        or (new.routine_snapshot->>'origin' = 'routine' and new.program_id is not null and new.routine_id is not null)))
  ) then
    raise exception 'invalid_routine_snapshot' using errcode = '22023';
  end if;
  return new;
end;
$$;

create or replace function private.workout_save_replay_matches(
  p_session public.user_workout_sessions,
  p_payload jsonb
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_set jsonb;
  v_existing public.user_workout_performed_sets;
begin
  if p_session.status <> 'completed'
     or p_session.started_at_utc is distinct from (p_payload->>'started_at_utc')::timestamptz
     or p_session.completed_at_utc is distinct from (p_payload->>'completed_at_utc')::timestamptz
     or p_session.routine_snapshot is distinct from p_payload->'routine_snapshot'
     or p_session.notes is distinct from nullif(btrim(p_payload->>'description'), '')
     or p_session.workout_title is distinct from btrim(p_payload->>'workout_title')
     or p_session.workout_at_utc is distinct from (p_payload->>'workout_at_utc')::timestamptz
     or p_session.workout_utc_offset_minutes is distinct from (p_payload->>'workout_utc_offset_minutes')::integer
     or p_session.workout_activity_type is distinct from nullif(btrim(p_payload->>'activity_type'), '')
     or p_session.gym_name is distinct from nullif(btrim(p_payload->>'gym_name'), '')
     or p_session.workout_rpe is distinct from (p_payload->>'overall_rpe')::numeric
     or p_session.workout_duration_seconds is distinct from (p_payload->>'selected_duration_seconds')::integer
     or (p_session.program_id is null and p_session.accumulated_paused_microseconds
           is distinct from (p_payload->>'accumulated_paused_microseconds')::bigint)
     or (select count(*) from public.user_workout_performed_sets
         where session_id = p_session.id) <> jsonb_array_length(p_payload->'performed_sets') then
    return false;
  end if;
  for v_set in select value from jsonb_array_elements(p_payload->'performed_sets') loop
    select * into v_existing from public.user_workout_performed_sets
    where session_id = p_session.id and user_id = p_session.user_id
      and session_exercise_index = (v_set->>'exercise_index')::integer
      and set_index = (v_set->>'set_index')::integer;
    if not found
       or v_existing.exercise_ref is distinct from v_set->>'exercise_ref'
       or v_existing.reps is distinct from (v_set->>'reps')::integer
       or v_existing.load_kg is distinct from (v_set->>'load_kg')::double precision
       or v_existing.duration_seconds is distinct from (v_set->>'duration_seconds')::integer
       or v_existing.distance_meters is distinct from (v_set->>'distance_meters')::double precision
       or v_existing.completed_at_utc is distinct from (v_set->>'completed_at_utc')::timestamptz
       or v_existing.is_skipped is distinct from coalesce((v_set->>'is_skipped')::boolean, false) then
      return false;
    end if;
  end loop;
  return true;
exception when others then
  return false;
end;
$$;
revoke all on function private.workout_save_replay_matches(public.user_workout_sessions,jsonb)
  from public, anon, authenticated;

create or replace function public.rpc_save_workout_session_v1(
  p_save_request_id uuid,
  p_existing_session_id uuid,
  p_expected_revision integer,
  p_payload jsonb
)
returns public.user_workout_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner uuid := auth.uid();
  v_session public.user_workout_sessions;
  v_saved public.user_workout_sessions;
  v_snapshot jsonb;
  v_set jsonb;
  v_ex jsonb;
  v_started timestamptz;
  v_completed timestamptz;
  v_selected timestamptz;
  v_offset integer;
  v_paused_us bigint;
  v_ex_index integer;
  v_set_index integer;
  v_ref text;
begin
  if v_owner is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_save_request_id is null or p_payload is null or jsonb_typeof(p_payload) <> 'object'
     or octet_length(p_payload::text) > 524288
     or exists (select 1 from jsonb_object_keys(p_payload) k
                where k <> all(array[
                  'started_at_utc','completed_at_utc','accumulated_paused_microseconds',
                  'workout_title','workout_at_utc','workout_utc_offset_minutes',
                  'description','activity_type','gym_name','overall_rpe',
                  'selected_duration_seconds','routine_snapshot','performed_sets'])) then
    raise exception 'invalid_save_payload' using errcode = '22023';
  end if;
  if (p_payload->>'started_at_utc') !~
       '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$'
     or (p_payload->>'completed_at_utc') !~
       '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$'
     or (p_payload->>'workout_at_utc') !~
       '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$' then
    raise exception 'invalid_save_timestamp' using errcode = '22023';
  end if;
  v_snapshot := p_payload->'routine_snapshot';
  v_started := (p_payload->>'started_at_utc')::timestamptz;
  v_completed := (p_payload->>'completed_at_utc')::timestamptz;
  v_selected := (p_payload->>'workout_at_utc')::timestamptz;
  v_offset := (p_payload->>'workout_utc_offset_minutes')::integer;
  v_paused_us := (p_payload->>'accumulated_paused_microseconds')::bigint;
  if v_started is null or v_completed is null or v_selected is null
     or v_completed < v_started or v_selected > v_completed
     or v_completed > now() + interval '1 day'
     or v_completed - v_started > interval '30 days'
     or v_offset is null or v_offset not between -840 and 840
     or nullif(btrim(p_payload->>'workout_title'), '') is null
     or char_length(btrim(p_payload->>'workout_title')) > 2000
     or octet_length(coalesce(p_payload->>'description','')) > 65536
     or (p_payload->>'activity_type') is not null and
        char_length(btrim(p_payload->>'activity_type')) not between 1 and 100
     or nullif(btrim(p_payload->>'activity_type'), '') is null
     or (p_payload->>'gym_name') is not null and
        char_length(btrim(p_payload->>'gym_name')) not between 1 and 200
     or (p_payload->>'overall_rpe')::numeric not between 0 and 10
     or p_payload->>'selected_duration_seconds' is null
     or (p_payload->>'selected_duration_seconds')::integer not between 0 and 2592000
     or jsonb_typeof(p_payload->'performed_sets') is distinct from 'array'
     or jsonb_array_length(p_payload->'performed_sets') not between 1 and 500 then
    raise exception 'invalid_save_payload' using errcode = '22023';
  end if;
  if p_existing_session_id is null then
    if p_expected_revision is not null
       or v_paused_us is null or v_paused_us < 0
       or v_paused_us > (extract(epoch from (v_completed - v_started)) * 1000000)::bigint
       or not private.is_valid_workout_session_snapshot_v2(v_snapshot)
       or v_snapshot->>'origin' <> 'ad_hoc' then
      raise exception 'invalid_new_workout_payload' using errcode = '22023';
    end if;
  else
    if p_expected_revision is null or p_expected_revision < 1
       or v_paused_us is not null or
       not (private.is_valid_workout_session_snapshot_v1(v_snapshot)
            or private.is_valid_workout_session_snapshot_v2(v_snapshot)) then
      raise exception 'invalid_existing_workout_payload' using errcode = '22023';
    end if;
  end if;

  -- Validate all slots and custom Exercise ownership before any write.
  if v_snapshot->>'origin' = 'ad_hoc' then
    for v_ex in select value from jsonb_array_elements(v_snapshot->'exercises') loop
      v_ref := v_ex->>'exercise_ref';
      if v_ref ~ '^[0-9a-f]{8}-' and not exists (
        select 1 from public.user_workout_exercises
        where id = v_ref::uuid and user_id = v_owner and status = 'active'
      ) then
        raise exception 'exercise_not_owned' using errcode = '42501';
      end if;
    end loop;
  end if;
  for v_set in select value from jsonb_array_elements(p_payload->'performed_sets') loop
    if jsonb_typeof(v_set) <> 'object'
       or exists (select 1 from jsonb_object_keys(v_set) k
                  where k <> all(array['exercise_ref','exercise_index','set_index',
                    'reps','load_kg','duration_seconds','distance_meters','completed_at_utc','is_skipped'])) then
      raise exception 'invalid_performed_set' using errcode = '22023';
    end if;
    v_ex_index := (v_set->>'exercise_index')::integer;
    v_set_index := (v_set->>'set_index')::integer;
    if v_ex_index is null or v_ex_index < 0
       or v_ex_index >= jsonb_array_length(v_snapshot->'exercises')
       or v_set_index is null or v_set_index < 0 or v_set_index > 999 then
      raise exception 'invalid_performed_slot' using errcode = '22023';
    end if;
    v_ex := (v_snapshot->'exercises')->v_ex_index;
    if v_set_index >= jsonb_array_length(v_ex->'prescribed_sets')
       or v_set->>'exercise_ref' is distinct from v_ex->>'exercise_ref'
       or (v_set->>'completed_at_utc') !~
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z$'
       or (v_set->>'completed_at_utc')::timestamptz not between v_started and v_completed
       or (v_set->>'reps')::integer < 0
       or (v_set->>'reps')::integer > 999
       or (v_set->>'load_kg')::double precision < 0
       or (v_set->>'duration_seconds')::integer < 0
       or (v_set->>'distance_meters')::double precision < 0 then
      raise exception 'invalid_performed_set' using errcode = '22023';
    end if;
    if coalesce((v_set->>'is_skipped')::boolean, false) then
      if v_set->>'reps' is not null or v_set->>'load_kg' is not null
         or v_set->>'duration_seconds' is not null
         or v_set->>'distance_meters' is not null then
        raise exception 'skipped_set_has_measurement' using errcode = '22023';
      end if;
    elsif v_ex->>'exercise_type' = 'duration' then
      if v_set->>'duration_seconds' is null or v_set->>'reps' is not null
         or v_set->>'load_kg' is not null or v_set->>'distance_meters' is not null then
        raise exception 'invalid_duration_measurement' using errcode = '22023';
      end if;
    elsif v_ex->>'exercise_type' = 'distance_duration' then
      if v_set->>'duration_seconds' is null or v_set->>'distance_meters' is null
         or v_set->>'reps' is not null or v_set->>'load_kg' is not null then
        raise exception 'invalid_distance_measurement' using errcode = '22023';
      end if;
    elsif v_set->>'duration_seconds' is not null
       or v_set->>'distance_meters' is not null
       or (v_set->>'reps' is null and v_set->>'load_kg' is null) then
      raise exception 'invalid_weight_reps_measurement' using errcode = '22023';
    end if;
  end loop;

  -- The unique (owner, request) key serializes concurrent retries.
  select * into v_session from public.user_workout_sessions
  where user_id = v_owner and save_request_id = p_save_request_id for update;
  if found then
    if (p_existing_session_id is not null and v_session.id <> p_existing_session_id)
       or (p_existing_session_id is null and v_session.program_id is not null)
       or (p_expected_revision is not null and v_session.revision not in
           (p_expected_revision, p_expected_revision + 1))
       or not private.workout_save_replay_matches(v_session, p_payload) then
      raise exception 'save_request_payload_conflict' using errcode = '23505';
    end if;
    return v_session;
  end if;

  if p_existing_session_id is null then
    insert into public.user_workout_sessions (
      user_id, program_id, routine_id, status, started_at_utc,
      last_transition_at_utc, accumulated_paused_microseconds, local_date,
      routine_snapshot, revision, save_request_id, workout_activity_type,
      gym_name, workout_rpe, workout_duration_seconds
    ) values (
      v_owner, null, null, 'active', v_started, v_started, v_paused_us,
      ((v_selected at time zone 'UTC') + make_interval(mins => v_offset))::date,
      v_snapshot, 1, p_save_request_id,
      nullif(btrim(p_payload->>'activity_type'), ''),
      nullif(btrim(p_payload->>'gym_name'), ''),
      (p_payload->>'overall_rpe')::numeric,
      (p_payload->>'selected_duration_seconds')::integer
    ) on conflict (user_id, save_request_id) do nothing returning * into v_session;
    if not found then
      select * into v_session from public.user_workout_sessions
      where user_id = v_owner and save_request_id = p_save_request_id for update;
      if not found or not private.workout_save_replay_matches(v_session, p_payload) then
        raise exception 'save_request_payload_conflict' using errcode = '23505';
      end if;
      return v_session;
    end if;
  else
    select * into v_session from public.user_workout_sessions
    where id = p_existing_session_id and user_id = v_owner for update;
    if not found then
      raise exception 'session_not_found' using errcode = 'P0002';
    end if;
    if v_session.save_request_id = p_save_request_id then
      if not private.workout_save_replay_matches(v_session, p_payload) then
        raise exception 'save_request_payload_conflict' using errcode = '23505';
      end if;
      return v_session;
    end if;
    if v_session.status in ('completed','discarded') or v_session.save_request_id is not null
       or v_session.revision <> p_expected_revision
       or v_session.started_at_utc <> v_started
       or v_session.routine_snapshot <> v_snapshot then
      raise exception 'stale_or_terminal_session' using errcode = 'P0003';
    end if;
    update public.user_workout_sessions set
      save_request_id = p_save_request_id,
      workout_activity_type = nullif(btrim(p_payload->>'activity_type'), ''),
      gym_name = nullif(btrim(p_payload->>'gym_name'), ''),
      workout_rpe = (p_payload->>'overall_rpe')::numeric,
      workout_duration_seconds = (p_payload->>'selected_duration_seconds')::integer
    where id = v_session.id and user_id = v_owner;
    delete from public.user_workout_performed_sets
    where session_id = v_session.id and user_id = v_owner;
  end if;

  for v_set in select value from jsonb_array_elements(p_payload->'performed_sets') loop
    insert into public.user_workout_performed_sets (
      session_id,user_id,exercise_ref,session_exercise_index,set_index,
      reps,load_kg,duration_seconds,distance_meters,completed_at_utc,is_skipped,notes
    ) values (
      v_session.id,v_owner,v_set->>'exercise_ref',
      (v_set->>'exercise_index')::integer,(v_set->>'set_index')::integer,
      (v_set->>'reps')::integer,(v_set->>'load_kg')::double precision,
      (v_set->>'duration_seconds')::integer,(v_set->>'distance_meters')::double precision,
      (v_set->>'completed_at_utc')::timestamptz,
      coalesce((v_set->>'is_skipped')::boolean,false),null
    );
  end loop;

  -- Existing V2 completion owns title/time normalization, pause accounting,
  -- revision CAS, timezone-independent local_date, and terminal transition.
  v_saved := public.rpc_complete_workout_session_v2(
    v_session.id, v_session.revision, v_completed,
    p_payload->>'description', p_payload->>'workout_title', v_selected, v_offset
  );
  return v_saved;
end;
$$;
revoke all on function public.rpc_save_workout_session_v1(uuid,uuid,integer,jsonb)
  from public, anon;
grant execute on function public.rpc_save_workout_session_v1(uuid,uuid,integer,jsonb)
  to authenticated;
