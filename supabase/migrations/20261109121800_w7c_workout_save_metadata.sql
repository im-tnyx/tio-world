-- W7C: persist reviewed Save Workout metadata on the canonical W7B session.
-- This migration is source-only until separately approved hosted rollout.

alter table public.user_workout_sessions
  add column workout_title text null,
  add column workout_at_utc timestamptz null,
  add column workout_utc_offset_minutes integer null,
  add constraint chk_user_workout_sessions_workout_title
    check (workout_title is null or (char_length(btrim(workout_title)) between 1 and 2000)),
  add constraint chk_user_workout_sessions_workout_time_pair
    check ((workout_at_utc is null) = (workout_utc_offset_minutes is null)),
  add constraint chk_user_workout_sessions_workout_offset
    check (workout_utc_offset_minutes is null or workout_utc_offset_minutes between -840 and 840),
  add constraint chk_user_workout_sessions_workout_metadata_complete
    check (
      (workout_title is null and workout_at_utc is null and workout_utc_offset_minutes is null)
      or (workout_title is not null and workout_at_utc is not null and workout_utc_offset_minutes is not null)
    );

comment on column public.user_workout_sessions.workout_title is
  'Resolved Save Workout title; null for legacy sessions completed before W7C metadata.';
comment on column public.user_workout_sessions.workout_at_utc is
  'Selected workout wall-clock instant represented in UTC, independent of started_at_utc and completed_at_utc.';
comment on column public.user_workout_sessions.workout_utc_offset_minutes is
  'UTC offset captured with workout_at_utc to preserve the selected local wall-clock time without an IANA zone.';

create or replace function public.rpc_complete_workout_session_v2(
  p_session_id uuid,
  p_expected_revision integer,
  p_completed_at_utc timestamptz,
  p_notes text,
  p_workout_title text,
  p_workout_at_utc timestamptz,
  p_workout_utc_offset_minutes integer
)
returns public.user_workout_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.user_workout_sessions;
  v_additional_us bigint := 0;
  v_normalized_notes text;
  v_normalized_title text;
  v_local_date date;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_session_id is null then
    raise exception 'missing_session_id' using errcode = '22023';
  end if;
  if p_expected_revision is null or p_expected_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;
  if p_completed_at_utc is null or p_workout_at_utc is null then
    raise exception 'missing_workout_timestamp' using errcode = '22023';
  end if;
  if p_workout_utc_offset_minutes is null or p_workout_utc_offset_minutes not between -840 and 840 then
    raise exception 'invalid_workout_utc_offset' using errcode = '22023';
  end if;

  v_normalized_title := nullif(btrim(p_workout_title), '');
  if v_normalized_title is null or char_length(v_normalized_title) > 2000 then
    raise exception 'invalid_workout_title' using errcode = '22023';
  end if;
  v_normalized_notes := nullif(btrim(p_notes), '');
  -- Keep the selected wall date independent of the database connection TimeZone.
  v_local_date := ((p_workout_at_utc at time zone 'UTC')
    + make_interval(mins => p_workout_utc_offset_minutes))::date;

  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;
  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  -- Identical terminal replay returns canonical state without a second revision/timing write.
  if v_session.status = 'completed' and v_session.completed_at_utc = p_completed_at_utc then
    if p_expected_revision not in (v_session.revision, v_session.revision - 1) then
      raise exception 'stale_revision_conflict' using errcode = 'P0003';
    end if;
    if v_session.notes is distinct from v_normalized_notes
      or v_session.workout_title is distinct from v_normalized_title
      or v_session.workout_at_utc is distinct from p_workout_at_utc
      or v_session.workout_utc_offset_minutes is distinct from p_workout_utc_offset_minutes
      or v_session.local_date is distinct from v_local_date then
      raise exception 'terminal_payload_conflict' using errcode = '23505';
    end if;
    return v_session;
  end if;

  if v_session.status in ('completed', 'discarded') then
    raise exception 'session_already_terminal' using errcode = 'P0002';
  end if;
  if v_session.revision <> p_expected_revision then
    raise exception 'stale_revision_conflict' using errcode = 'P0003';
  end if;
  if p_completed_at_utc < v_session.last_transition_at_utc then
    raise exception 'backdated_transition' using errcode = '22023';
  end if;
  if p_workout_at_utc > p_completed_at_utc then
    raise exception 'future_workout_timestamp' using errcode = '22023';
  end if;
  if v_session.status = 'paused' then
    v_additional_us := (extract(epoch from (p_completed_at_utc - v_session.paused_at_utc)) * 1000000)::bigint;
  end if;

  update public.user_workout_sessions
  set status = 'completed',
      paused_at_utc = null,
      completed_at_utc = p_completed_at_utc,
      last_transition_at_utc = p_completed_at_utc,
      accumulated_paused_microseconds = accumulated_paused_microseconds + v_additional_us,
      notes = v_normalized_notes,
      workout_title = v_normalized_title,
      workout_at_utc = p_workout_at_utc,
      workout_utc_offset_minutes = p_workout_utc_offset_minutes,
      local_date = v_local_date,
      revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id
  returning * into v_session;

  return v_session;
end;
$$;

revoke all on function public.rpc_complete_workout_session_v2(
  uuid, integer, timestamptz, text, text, timestamptz, integer
) from public, anon;
grant execute on function public.rpc_complete_workout_session_v2(
  uuid, integer, timestamptz, text, text, timestamptz, integer
) to authenticated;
