-- W8C: owner-scoped, atomic edits of completed workouts. No direct table DML.
-- The transaction-local gate is set only after owner, status, revision and
-- payload validation. Existing client table grants remain SELECT-only.

create or replace function private.trg_enforce_workout_session_immutability()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' then
    if old.status = 'completed' and
       current_setting('tio_w8c.edit_session_id', true) = old.id::text and
       auth.uid() = old.user_id and
       new.id = old.id and new.user_id = old.user_id and
       new.program_id is not distinct from old.program_id and
       new.routine_id is not distinct from old.routine_id and
       new.status = 'completed' and
       new.started_at_utc = old.started_at_utc and
       new.paused_at_utc is not distinct from old.paused_at_utc and
       new.completed_at_utc = old.completed_at_utc and
       new.last_transition_at_utc = old.last_transition_at_utc and
       new.accumulated_paused_microseconds = old.accumulated_paused_microseconds and
       new.save_request_id is not distinct from old.save_request_id and
       new.discard_reason is not distinct from old.discard_reason and
       new.created_at = old.created_at and
       new.revision = old.revision + 1 then
      new.updated_at := now();
      return new;
    end if;
    if old.status in ('completed', 'discarded') then
      raise exception 'terminal_workout_session_immutable' using errcode = 'P0001';
    end if;
    if new.id is distinct from old.id or new.user_id is distinct from old.user_id or
       new.program_id is distinct from old.program_id or
       new.routine_id is distinct from old.routine_id or
       new.started_at_utc is distinct from old.started_at_utc or
       new.routine_snapshot is distinct from old.routine_snapshot or
       new.created_at is distinct from old.created_at then
      raise exception 'workout_session_immutable_fields_modified' using errcode = 'P0001';
    end if;
    new.updated_at := now();
    return new;
  elsif tg_op = 'DELETE' then
    if exists (select 1 from public.users where id = old.user_id) then
      raise exception 'workout_session_direct_delete_forbidden' using errcode = 'P0001';
    end if;
    return old;
  end if;
  return new;
end;
$$;

create or replace function private.trg_enforce_performed_set_parent_status()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_session_status text;
  v_session_id uuid := case when tg_op = 'DELETE' then old.session_id else new.session_id end;
  v_owner uuid := case when tg_op = 'DELETE' then old.user_id else new.user_id end;
begin
  select status into v_session_status from public.user_workout_sessions where id = v_session_id;
  if v_session_status is null then
    if tg_op = 'DELETE' then return old; end if;
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;
  if v_session_status = 'completed' and
     current_setting('tio_w8c.edit_session_id', true) = v_session_id::text and
     auth.uid() = v_owner and
     (tg_op <> 'UPDATE' or
       (new.session_id = old.session_id and new.user_id = old.user_id)) then
    if tg_op = 'DELETE' then return old; end if;
    if tg_op = 'UPDATE' then new.updated_at := now(); end if;
    return new;
  end if;
  if v_session_status in ('completed', 'discarded') then
    raise exception 'terminal_session_sets_immutable' using errcode = 'P0001';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  if tg_op = 'UPDATE' then new.updated_at := now(); end if;
  return new;
end;
$$;

create or replace function private.completed_workout_edit_matches(
  p_session public.user_workout_sessions, p_payload jsonb
) returns boolean language plpgsql stable security definer set search_path = '' as $$
declare
  v_set jsonb;
  v_existing public.user_workout_performed_sets;
begin
  if p_session.status <> 'completed' or
     p_session.workout_title is distinct from btrim(p_payload->>'workout_title') or
     p_session.notes is distinct from nullif(btrim(p_payload->>'description'), '') or
     p_session.workout_at_utc is distinct from (p_payload->>'workout_at_utc')::timestamptz or
     p_session.workout_utc_offset_minutes is distinct from (p_payload->>'workout_utc_offset_minutes')::integer or
     p_session.workout_duration_seconds is distinct from (p_payload->>'selected_duration_seconds')::integer or
     p_session.gym_name is distinct from nullif(btrim(p_payload->>'gym_name'), '') or
     p_session.workout_activity_type is distinct from nullif(btrim(p_payload->>'activity_type'), '') or
     p_session.workout_rpe is distinct from (p_payload->>'overall_rpe')::numeric or
     p_session.routine_snapshot is distinct from p_payload->'routine_snapshot' or
     (select count(*) from public.user_workout_performed_sets where session_id = p_session.id)
       <> jsonb_array_length(p_payload->'performed_sets') then
    return false;
  end if;
  for v_set in select value from jsonb_array_elements(p_payload->'performed_sets') loop
    select * into v_existing from public.user_workout_performed_sets
      where session_id = p_session.id and user_id = p_session.user_id and
        session_exercise_index = (v_set->>'exercise_index')::integer and
        set_index = (v_set->>'set_index')::integer;
    if not found or
       (v_set->>'id' is not null and v_existing.id is distinct from (v_set->>'id')::uuid) or
       v_existing.exercise_ref is distinct from v_set->>'exercise_ref' or
       v_existing.reps is distinct from (v_set->>'reps')::integer or
       v_existing.load_kg is distinct from (v_set->>'load_kg')::double precision or
       v_existing.duration_seconds is distinct from (v_set->>'duration_seconds')::integer or
       v_existing.distance_meters is distinct from (v_set->>'distance_meters')::double precision or
       v_existing.completed_at_utc is distinct from (v_set->>'completed_at_utc')::timestamptz or
       v_existing.is_skipped is distinct from coalesce((v_set->>'is_skipped')::boolean, false) then
      return false;
    end if;
  end loop;
  return true;
exception when others then return false;
end;
$$;
revoke all on function private.completed_workout_edit_matches(public.user_workout_sessions,jsonb)
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
     v_snapshot - 'exercises' is distinct from v_session.routine_snapshot - 'exercises' or
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
