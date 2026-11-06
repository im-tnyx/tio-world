-- ============================================================================
-- Migration: user_workout_sessions (W7B-1 Workout Session Persistence)
--
-- Author: Antigravity
-- Ticket: Linear TNYX-84 (W7 Active Workout)
-- Precedent: ADR-0011, ADR-0015, SUPABASE_STRATEGY.md
--
-- Provides:
-- 1. Two-table owner-scoped persistence: user_workout_sessions & user_workout_performed_sets.
-- 2. Database-enforced single active or paused session per user (partial unique index).
-- 3. Composite (session_id, user_id) foreign key on child sets to prevent cross-tenant spoofing.
-- 4. Microsecond pause accounting and monotonic resume watermark (WorkoutTime parity).
-- 5. Deterministic snapshot validation (private.is_valid_workout_session_snapshot_v1).
-- 6. Terminal session immutability and legitimate account deletion cascade compatibility.
-- 7. 7 protected SECURITY DEFINER RPCs for all session lifecycle and set mutations.
-- 8. Direct table DML denied; authenticated owner-only SELECT via RLS.
-- ============================================================================

-- Ensure schema 'private' exists
create schema if not exists private;

-- ----------------------------------------------------------------------------
-- 1. Snapshot Validation Function
-- ----------------------------------------------------------------------------
create or replace function private.is_valid_workout_session_snapshot_v1(p_snapshot jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  v_ex jsonb;
  v_set jsonb;
  v_ex_type text;
  v_set_type text;
begin
  if p_snapshot is null or jsonb_typeof(p_snapshot) <> 'object' then
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
     (p_snapshot->>'routine_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
     not (p_snapshot ? 'program_id') or
     jsonb_typeof(p_snapshot->'program_id') is distinct from 'string' or
     (p_snapshot->>'program_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
     not (p_snapshot ? 'routine_name') or
     jsonb_typeof(p_snapshot->'routine_name') is distinct from 'string' or
     length(btrim(p_snapshot->>'routine_name')) = 0 or
     not (p_snapshot ? 'captured_at_utc') or
     jsonb_typeof(p_snapshot->'captured_at_utc') is distinct from 'string' or
     length(btrim(p_snapshot->>'captured_at_utc')) = 0 or
     not (p_snapshot ? 'exercises') or
     jsonb_typeof(p_snapshot->'exercises') is distinct from 'array' or
     jsonb_array_length(p_snapshot->'exercises') = 0 then
    return false;
  end if;

  -- Verify captured_at_utc is a valid timestamptz
  begin
    perform (p_snapshot->>'captured_at_utc')::timestamptz;
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

    -- exercise_ref format check
    if (v_ex->>'exercise_ref') !~ '^ex_[a-z0-9_]+$' and
       (v_ex->>'exercise_ref') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
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
    end loop;
  end loop;

  return true;
exception
  when others then
    return false;
end;
$$;

revoke all on function private.is_valid_workout_session_snapshot_v1(jsonb) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. Table: public.user_workout_sessions
-- ----------------------------------------------------------------------------
create table public.user_workout_sessions (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  program_id uuid not null,
  routine_id uuid not null,
  status text not null default 'active',
  started_at_utc timestamptz not null,
  paused_at_utc timestamptz null,
  completed_at_utc timestamptz null,
  last_transition_at_utc timestamptz not null,
  accumulated_paused_microseconds bigint not null default 0,
  local_date date not null,
  routine_snapshot jsonb not null,
  notes text null,
  discard_reason text null,
  revision integer not null default 1,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),

  constraint pk_user_workout_sessions primary key (id),
  constraint uq_user_workout_sessions_composite unique (id, user_id),
  constraint fk_user_workout_sessions_user foreign key (user_id)
    references public.users(id) on delete cascade,

  constraint chk_user_workout_sessions_status check (
    status in ('active', 'paused', 'completed', 'discarded')
  ),
  constraint chk_user_workout_sessions_accumulated_paused check (
    accumulated_paused_microseconds >= 0
  ),
  constraint chk_user_workout_sessions_revision check (
    revision >= 1
  ),
  constraint chk_user_workout_sessions_timing check (
    last_transition_at_utc >= started_at_utc and
    (
      (status = 'active' and paused_at_utc is null and completed_at_utc is null) or
      (status = 'paused' and paused_at_utc is not null and completed_at_utc is null and last_transition_at_utc = paused_at_utc and paused_at_utc >= started_at_utc) or
      (status in ('completed', 'discarded') and paused_at_utc is null and completed_at_utc is not null and last_transition_at_utc = completed_at_utc and completed_at_utc >= started_at_utc)
    )
  ),
  constraint chk_user_workout_sessions_discard_reason check (
    (status = 'discarded' and discard_reason is not null and length(btrim(discard_reason)) > 0) or
    (status <> 'discarded' and discard_reason is null)
  ),
  constraint chk_user_workout_sessions_snapshot_valid check (
    private.is_valid_workout_session_snapshot_v1(routine_snapshot)
  )
);

-- Partial unique index: at most one active or paused session per user at any given time
create unique index uq_user_workout_sessions_single_active
  on public.user_workout_sessions (user_id)
  where (status in ('active', 'paused'));

create index idx_user_workout_sessions_user_date
  on public.user_workout_sessions (user_id, local_date desc);

create index idx_user_workout_sessions_user_routine
  on public.user_workout_sessions (user_id, routine_id, created_at desc);

-- ----------------------------------------------------------------------------
-- 3. Table: public.user_workout_performed_sets
-- ----------------------------------------------------------------------------
create table public.user_workout_performed_sets (
  id uuid not null default gen_random_uuid(),
  session_id uuid not null,
  user_id uuid not null,
  exercise_ref text not null,
  session_exercise_index integer not null,
  set_index integer not null,
  reps integer null,
  load_kg double precision null,
  duration_seconds integer null,
  distance_meters double precision null,
  completed_at_utc timestamptz null,
  is_skipped boolean not null default false,
  notes text null,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),

  constraint pk_user_workout_performed_sets primary key (id),
  constraint fk_user_workout_performed_sets_session_composite
    foreign key (session_id, user_id)
    references public.user_workout_sessions(id, user_id)
    on delete cascade,
  constraint uq_user_workout_performed_sets_slot
    unique (session_id, session_exercise_index, set_index),
  constraint chk_user_workout_performed_sets_exercise_ref check (
    exercise_ref ~ '^ex_[a-z0-9_]+$' or
    exercise_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  ),
  constraint chk_user_workout_performed_sets_indices check (
    session_exercise_index >= 0 and set_index >= 0
  ),
  constraint chk_user_workout_performed_sets_reps check (
    reps is null or (reps >= 0 and reps <= 2147483647)
  ),
  constraint chk_user_workout_performed_sets_load check (
    load_kg is null or (
      load_kg >= 0 and
      load_kg < 'Infinity'::double precision and
      load_kg <> 'NaN'::double precision
    )
  ),
  constraint chk_user_workout_performed_sets_duration check (
    duration_seconds is null or (duration_seconds >= 0 and duration_seconds <= 2147483647)
  ),
  constraint chk_user_workout_performed_sets_distance check (
    distance_meters is null or (
      distance_meters >= 0 and
      distance_meters < 'Infinity'::double precision and
      distance_meters <> 'NaN'::double precision
    )
  )
);

create index idx_user_workout_performed_sets_session_order
  on public.user_workout_performed_sets (session_id, session_exercise_index, set_index);

-- ----------------------------------------------------------------------------
-- 4. Triggers: Immutability and Account Deletion Cascade Safety
-- ----------------------------------------------------------------------------
create or replace function private.trg_enforce_workout_session_immutability()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if old.status in ('completed', 'discarded') then
      raise exception 'terminal_workout_session_immutable'
        using errcode = 'P0001',
              detail = 'Completed or discarded workout sessions cannot be modified.';
    end if;

    if new.id is distinct from old.id or
       new.user_id is distinct from old.user_id or
       new.program_id is distinct from old.program_id or
       new.routine_id is distinct from old.routine_id or
       new.started_at_utc is distinct from old.started_at_utc or
       new.routine_snapshot is distinct from old.routine_snapshot or
       new.created_at is distinct from old.created_at then
      raise exception 'workout_session_immutable_fields_modified'
        using errcode = 'P0001',
              detail = 'Core session identification and snapshot fields are immutable.';
    end if;

    new.updated_at := timezone('utc'::text, now());
    return new;

  elsif tg_op = 'DELETE' then
    -- If the parent user still exists in public.users, this is an unauthorized direct delete attempt
    -- When full account deletion runs (public.delete_user_account -> auth.users cascade),
    -- the public.users row is already deleted in the cascade, so this check evaluates to false.
    if exists (select 1 from public.users where id = old.user_id) then
      raise exception 'workout_session_direct_delete_forbidden'
        using errcode = 'P0001',
              detail = 'Workout sessions cannot be deleted directly. Request full account deletion.';
    end if;

    return old;
  end if;

  return new;
end;
$$;

create or replace function private.trg_enforce_performed_set_parent_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_status text;
  v_session_id uuid;
begin
  if tg_op = 'DELETE' then
    v_session_id := old.session_id;
  else
    v_session_id := new.session_id;
  end if;

  select status into v_session_status
  from public.user_workout_sessions
  where id = v_session_id;

  -- If parent session is already deleted in cascade, allow delete
  if v_session_status is null then
    if tg_op = 'DELETE' then
      return old;
    else
      raise exception 'session_not_found' using errcode = 'P0002';
    end if;
  end if;

  if v_session_status in ('completed', 'discarded') then
    raise exception 'terminal_session_sets_immutable'
      using errcode = 'P0001',
            detail = 'Cannot insert, update, or delete sets on a completed or discarded workout session.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  elsif tg_op = 'UPDATE' then
    new.updated_at := timezone('utc'::text, now());
    return new;
  else
    return new;
  end if;
end;
$$;

create trigger trg_user_workout_sessions_immutability
before update or delete on public.user_workout_sessions
for each row execute function private.trg_enforce_workout_session_immutability();

create trigger trg_user_workout_performed_sets_status
before insert or update or delete on public.user_workout_performed_sets
for each row execute function private.trg_enforce_performed_set_parent_status();

-- ----------------------------------------------------------------------------
-- 5. Row Level Security & Explicit Grants
-- ----------------------------------------------------------------------------
alter table public.user_workout_sessions enable row level security;
alter table public.user_workout_performed_sets enable row level security;

revoke all on table public.user_workout_sessions from anon, authenticated, public;
revoke all on table public.user_workout_performed_sets from anon, authenticated, public;

grant select on table public.user_workout_sessions to authenticated;
grant select on table public.user_workout_performed_sets to authenticated;

create policy user_workout_sessions_select_own on public.user_workout_sessions
  for select to authenticated
  using (user_id = auth.uid());

create policy user_workout_performed_sets_select_own on public.user_workout_performed_sets
  for select to authenticated
  using (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 6. RPC: rpc_start_workout_session
-- ----------------------------------------------------------------------------
create or replace function public.rpc_start_workout_session(
  p_session_id uuid,
  p_program_id uuid,
  p_routine_id uuid,
  p_started_at_utc timestamptz,
  p_local_date date,
  p_routine_snapshot jsonb
)
returns public.user_workout_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.user_workout_sessions;
  v_inserted public.user_workout_sessions;
  v_db_ex_count integer;
  v_ex_record record;
  v_snap_ex jsonb;
  v_idx integer := 0;
  v_db_set_count integer;
  v_set_record record;
  v_snap_set jsonb;
  v_set_idx integer;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_session_id is null then
    raise exception 'missing_session_id' using errcode = '22023';
  end if;

  -- 1. Finding 4490473120: Detect existing session before validating mutable source routine
  select * into v_existing
  from public.user_workout_sessions
  where id = p_session_id
  for update;

  if found then
    if v_existing.user_id <> v_user_id then
      raise exception 'session_ownership_mismatch' using errcode = '42501';
    end if;

    -- Verify exact matching replay parameters
    if v_existing.program_id is distinct from p_program_id or
       v_existing.routine_id is distinct from p_routine_id or
       v_existing.started_at_utc is distinct from p_started_at_utc or
       v_existing.local_date is distinct from p_local_date or
       v_existing.routine_snapshot is distinct from p_routine_snapshot then
      raise exception 'duplicate_session_conflict' using errcode = '23505';
    end if;

    return v_existing;
  end if;

  -- 2. Validate snapshot structure
  if not private.is_valid_workout_session_snapshot_v1(p_routine_snapshot) then
    raise exception 'invalid_snapshot_structure' using errcode = '22023';
  end if;

  -- Cross-validate snapshot routine and program identity
  if (p_routine_snapshot->>'routine_id')::uuid <> p_routine_id or
     (p_routine_snapshot->>'program_id')::uuid <> p_program_id then
    raise exception 'snapshot_identity_mismatch' using errcode = '22023';
  end if;

  -- 3. Verify source Routine and Program ownership
  if not exists (
    select 1 from public.user_workout_routines r
    where r.id = p_routine_id and r.user_id = v_user_id and r.program_id = p_program_id
  ) then
    raise exception 'invalid_routine_or_unauthorized' using errcode = '42501';
  end if;

  -- Acquire shared lock on source routine during snapshot validation
  perform 1 from public.user_workout_routines r
  where r.id = p_routine_id and r.user_id = v_user_id
  for share;

  -- 4. Cross-validate exercise composition count
  select count(*)::integer into v_db_ex_count
  from public.user_workout_routine_exercises
  where routine_id = p_routine_id and user_id = v_user_id;

  if jsonb_array_length(p_routine_snapshot->'exercises') <> v_db_ex_count then
    raise exception 'snapshot_exercise_count_mismatch' using errcode = '22023';
  end if;

  -- 5. Cross-validate each exercise occurrence order, custom metadata, and prescribed sets (Finding 4490473113)
  for v_ex_record in
    select id, position, catalog_exercise_id, user_exercise_id
    from public.user_workout_routine_exercises
    where routine_id = p_routine_id and user_id = v_user_id
    order by position asc
  loop
    v_snap_ex := (p_routine_snapshot->'exercises')->v_idx;

    if (v_snap_ex->>'occurrence_index')::integer <> v_idx then
      raise exception 'snapshot_occurrence_order_mismatch' using errcode = '22023';
    end if;

    if v_ex_record.catalog_exercise_id is not null then
      if (v_snap_ex->>'exercise_ref') <> v_ex_record.catalog_exercise_id then
        raise exception 'snapshot_exercise_ref_mismatch' using errcode = '22023';
      end if;
    elsif v_ex_record.user_exercise_id is not null then
      if (v_snap_ex->>'exercise_ref')::uuid <> v_ex_record.user_exercise_id then
        raise exception 'snapshot_exercise_ref_mismatch' using errcode = '22023';
      end if;

      -- Cross-validate custom exercise display name and type from database truth
      if not exists (
        select 1 from public.user_workout_exercises ue
        where ue.id = v_ex_record.user_exercise_id and ue.user_id = v_user_id and
              ue.display_name = (v_snap_ex->>'display_name') and
              coalesce(ue.exercise_type::text, '') = coalesce(v_snap_ex->>'exercise_type', '')
      ) then
        raise exception 'snapshot_custom_exercise_metadata_mismatch' using errcode = '22023';
      end if;
    end if;

    -- Cross-validate prescribed sets against user_workout_routine_sets
    select count(*)::integer into v_db_set_count
    from public.user_workout_routine_sets
    where routine_exercise_id = v_ex_record.id and user_id = v_user_id;

    if jsonb_array_length(v_snap_ex->'prescribed_sets') <> v_db_set_count then
      raise exception 'snapshot_prescription_count_mismatch' using errcode = '22023';
    end if;

    v_set_idx := 0;
    for v_set_record in
      select position, set_type, reps, reps_max, load_kg, distance_meters, duration_seconds, rest_seconds
      from public.user_workout_routine_sets
      where routine_exercise_id = v_ex_record.id and user_id = v_user_id
      order by position asc
    loop
      v_snap_set := (v_snap_ex->'prescribed_sets')->v_set_idx;

      if (v_snap_set->>'set_type') is distinct from v_set_record.set_type or
         (case when v_snap_set ? 'reps' and jsonb_typeof(v_snap_set->'reps') <> 'null'
               then (v_snap_set->>'reps')::integer else null end) is distinct from v_set_record.reps or
         (case when v_snap_set ? 'reps_max' and jsonb_typeof(v_snap_set->'reps_max') <> 'null'
               then (v_snap_set->>'reps_max')::integer else null end) is distinct from v_set_record.reps_max or
         (case when v_snap_set ? 'load_kg' and jsonb_typeof(v_snap_set->'load_kg') <> 'null'
               then (v_snap_set->>'load_kg')::double precision else null end) is distinct from v_set_record.load_kg or
         (case when v_snap_set ? 'distance_meters' and jsonb_typeof(v_snap_set->'distance_meters') <> 'null'
               then (v_snap_set->>'distance_meters')::double precision else null end) is distinct from v_set_record.distance_meters or
         (case when v_snap_set ? 'duration_seconds' and jsonb_typeof(v_snap_set->'duration_seconds') <> 'null'
               then (v_snap_set->>'duration_seconds')::integer else null end) is distinct from v_set_record.duration_seconds or
         (case when v_snap_set ? 'rest_seconds' and jsonb_typeof(v_snap_set->'rest_seconds') <> 'null'
               then (v_snap_set->>'rest_seconds')::integer else null end) is distinct from v_set_record.rest_seconds then
        raise exception 'snapshot_prescription_mismatch' using errcode = '22023';
      end if;

      v_set_idx := v_set_idx + 1;
    end loop;

    v_idx := v_idx + 1;
  end loop;

  -- 6. Insert new active session
  insert into public.user_workout_sessions (
    id, user_id, program_id, routine_id, status, started_at_utc,
    last_transition_at_utc, accumulated_paused_microseconds, local_date,
    routine_snapshot, revision
  ) values (
    p_session_id, v_user_id, p_program_id, p_routine_id, 'active', p_started_at_utc,
    p_started_at_utc, 0, p_local_date, p_routine_snapshot, 1
  )
  returning * into v_inserted;

  return v_inserted;
end;
$$;

revoke all on function public.rpc_start_workout_session from public, anon;
grant execute on function public.rpc_start_workout_session to authenticated;

-- ----------------------------------------------------------------------------
-- 7. RPC: rpc_pause_workout_session
-- ----------------------------------------------------------------------------
create or replace function public.rpc_pause_workout_session(
  p_session_id uuid,
  p_expected_revision integer,
  p_paused_at_utc timestamptz
)
returns public.user_workout_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.user_workout_sessions;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_revision is null or p_expected_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;

  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  -- Idempotency: if already paused at identical timestamp
  if v_session.status = 'paused' and v_session.paused_at_utc = p_paused_at_utc then
    if p_expected_revision in (v_session.revision, v_session.revision - 1) then
      return v_session;
    else
      raise exception 'stale_revision_conflict' using errcode = 'P0003';
    end if;
  end if;

  if v_session.status <> 'active' then
    raise exception 'invalid_transition_from_status' using errcode = 'P0001';
  end if;

  if v_session.revision <> p_expected_revision then
    raise exception 'stale_revision_conflict' using errcode = 'P0003';
  end if;

  if p_paused_at_utc < v_session.last_transition_at_utc then
    raise exception 'backdated_transition' using errcode = '22023';
  end if;

  update public.user_workout_sessions
  set status = 'paused',
      paused_at_utc = p_paused_at_utc,
      last_transition_at_utc = p_paused_at_utc,
      revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id
  returning * into v_session;

  return v_session;
end;
$$;

revoke all on function public.rpc_pause_workout_session from public, anon;
grant execute on function public.rpc_pause_workout_session to authenticated;

-- ----------------------------------------------------------------------------
-- 8. RPC: rpc_resume_workout_session
-- ----------------------------------------------------------------------------
create or replace function public.rpc_resume_workout_session(
  p_session_id uuid,
  p_expected_revision integer,
  p_resumed_at_utc timestamptz
)
returns public.user_workout_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.user_workout_sessions;
  v_additional_us bigint;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_revision is null or p_expected_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;

  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  -- Idempotency: if already active at identical resume instant
  if v_session.status = 'active' and v_session.last_transition_at_utc = p_resumed_at_utc then
    if p_expected_revision in (v_session.revision, v_session.revision - 1) then
      return v_session;
    else
      raise exception 'stale_revision_conflict' using errcode = 'P0003';
    end if;
  end if;

  if v_session.status <> 'paused' then
    raise exception 'invalid_transition_from_status' using errcode = 'P0001';
  end if;

  if v_session.revision <> p_expected_revision then
    raise exception 'stale_revision_conflict' using errcode = 'P0003';
  end if;

  if p_resumed_at_utc < v_session.paused_at_utc then
    raise exception 'backdated_transition' using errcode = '22023';
  end if;

  -- Microsecond duration calculation
  v_additional_us := (extract(epoch from (p_resumed_at_utc - v_session.paused_at_utc)) * 1000000)::bigint;

  update public.user_workout_sessions
  set status = 'active',
      paused_at_utc = null,
      accumulated_paused_microseconds = accumulated_paused_microseconds + v_additional_us,
      last_transition_at_utc = p_resumed_at_utc,
      revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id
  returning * into v_session;

  return v_session;
end;
$$;

revoke all on function public.rpc_resume_workout_session from public, anon;
grant execute on function public.rpc_resume_workout_session to authenticated;

-- ----------------------------------------------------------------------------
-- 9. RPC: rpc_log_workout_performed_set
-- ----------------------------------------------------------------------------
create or replace function public.rpc_log_workout_performed_set(
  p_set_id uuid,
  p_session_id uuid,
  p_expected_session_revision integer,
  p_exercise_ref text,
  p_session_exercise_index integer,
  p_set_index integer,
  p_reps integer default null,
  p_load_kg double precision default null,
  p_duration_seconds integer default null,
  p_distance_meters double precision default null,
  p_completed_at_utc timestamptz default null,
  p_is_skipped boolean default false,
  p_notes text default null
)
returns public.user_workout_performed_sets
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.user_workout_sessions;
  v_set public.user_workout_performed_sets;
  v_existing_set public.user_workout_performed_sets;
  v_snap_ex jsonb;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_set_id is null then
    raise exception 'missing_set_id' using errcode = '22023';
  end if;

  -- Finding 4490473109: Reject NULL or invalid expected revision
  if p_expected_session_revision is null or p_expected_session_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;

  -- Finding 4490473095: Enforce existing-set ownership and session identity before upsert
  select * into v_existing_set
  from public.user_workout_performed_sets
  where id = p_set_id
  for update;

  if found then
    if v_existing_set.user_id <> v_user_id or v_existing_set.session_id <> p_session_id then
      raise exception 'set_ownership_mismatch' using errcode = '42501';
    end if;
  end if;

  -- Parent row lock: guarantees serialization and blocks sets on finished sessions
  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  if v_session.status in ('completed', 'discarded') then
    raise exception 'session_already_terminal' using errcode = 'P0002';
  end if;

  if v_session.revision <> p_expected_session_revision then
    raise exception 'stale_revision_conflict' using errcode = 'P0003';
  end if;

  -- Validate set against session snapshot exercise occurrence
  if p_session_exercise_index < 0 or
     p_session_exercise_index >= jsonb_array_length(v_session.routine_snapshot->'exercises') then
    raise exception 'snapshot_exercise_index_out_of_bounds' using errcode = '22023';
  end if;

  v_snap_ex := (v_session.routine_snapshot->'exercises')->p_session_exercise_index;
  if (v_snap_ex->>'exercise_ref') <> p_exercise_ref then
    raise exception 'snapshot_exercise_ref_mismatch' using errcode = '22023';
  end if;

  -- Upsert performed set with strict ownership and session scoping on conflict update
  insert into public.user_workout_performed_sets (
    id, session_id, user_id, exercise_ref, session_exercise_index, set_index,
    reps, load_kg, duration_seconds, distance_meters, completed_at_utc, is_skipped, notes
  ) values (
    p_set_id, p_session_id, v_user_id, p_exercise_ref, p_session_exercise_index, p_set_index,
    p_reps, p_load_kg, p_duration_seconds, p_distance_meters, p_completed_at_utc, p_is_skipped, p_notes
  )
  on conflict (id) do update set
    exercise_ref = excluded.exercise_ref,
    session_exercise_index = excluded.session_exercise_index,
    set_index = excluded.set_index,
    reps = excluded.reps,
    load_kg = excluded.load_kg,
    duration_seconds = excluded.duration_seconds,
    distance_meters = excluded.distance_meters,
    completed_at_utc = excluded.completed_at_utc,
    is_skipped = excluded.is_skipped,
    notes = excluded.notes,
    updated_at = timezone('utc'::text, now())
  where public.user_workout_performed_sets.user_id = v_user_id
    and public.user_workout_performed_sets.session_id = p_session_id
  returning * into v_set;

  if v_set.id is null then
    raise exception 'set_ownership_mismatch' using errcode = '42501';
  end if;

  -- Advance parent session revision
  update public.user_workout_sessions
  set revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id;

  return v_set;
end;
$$;

revoke all on function public.rpc_log_workout_performed_set from public, anon;
grant execute on function public.rpc_log_workout_performed_set to authenticated;

-- ----------------------------------------------------------------------------
-- 10. RPC: rpc_remove_workout_performed_set
-- ----------------------------------------------------------------------------
create or replace function public.rpc_remove_workout_performed_set(
  p_set_id uuid,
  p_session_id uuid,
  p_expected_session_revision integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.user_workout_sessions;
  v_deleted_count integer;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_session_revision is null or p_expected_session_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;

  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  if v_session.status in ('completed', 'discarded') then
    raise exception 'session_already_terminal' using errcode = 'P0002';
  end if;

  if v_session.revision <> p_expected_session_revision then
    raise exception 'stale_revision_conflict' using errcode = 'P0003';
  end if;

  delete from public.user_workout_performed_sets
  where id = p_set_id and session_id = p_session_id and user_id = v_user_id;
  get diagnostics v_deleted_count = row_count;

  if v_deleted_count = 0 then
    raise exception 'set_not_found' using errcode = 'P0002';
  end if;

  update public.user_workout_sessions
  set revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id;
end;
$$;

revoke all on function public.rpc_remove_workout_performed_set from public, anon;
grant execute on function public.rpc_remove_workout_performed_set to authenticated;

-- ----------------------------------------------------------------------------
-- 11. RPC: rpc_complete_workout_session
-- ----------------------------------------------------------------------------
create or replace function public.rpc_complete_workout_session(
  p_session_id uuid,
  p_expected_revision integer,
  p_completed_at_utc timestamptz,
  p_notes text default null
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
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_revision is null or p_expected_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;

  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  -- Idempotency check: if already completed at identical timestamp
  if v_session.status = 'completed' and v_session.completed_at_utc = p_completed_at_utc then
    if p_expected_revision in (v_session.revision, v_session.revision - 1) then
      return v_session;
    else
      raise exception 'stale_revision_conflict' using errcode = 'P0003';
    end if;
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

  if v_session.status = 'paused' then
    v_additional_us := (extract(epoch from (p_completed_at_utc - v_session.paused_at_utc)) * 1000000)::bigint;
  end if;

  update public.user_workout_sessions
  set status = 'completed',
      paused_at_utc = null,
      completed_at_utc = p_completed_at_utc,
      last_transition_at_utc = p_completed_at_utc,
      accumulated_paused_microseconds = accumulated_paused_microseconds + v_additional_us,
      notes = coalesce(p_notes, notes),
      revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id
  returning * into v_session;

  return v_session;
end;
$$;

revoke all on function public.rpc_complete_workout_session from public, anon;
grant execute on function public.rpc_complete_workout_session to authenticated;

-- ----------------------------------------------------------------------------
-- 12. RPC: rpc_discard_workout_session
-- ----------------------------------------------------------------------------
create or replace function public.rpc_discard_workout_session(
  p_session_id uuid,
  p_expected_revision integer,
  p_discarded_at_utc timestamptz,
  p_discard_reason text
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
  v_trimmed_reason text;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_expected_revision is null or p_expected_revision < 1 then
    raise exception 'invalid_expected_revision' using errcode = '22023';
  end if;

  v_trimmed_reason := btrim(coalesce(p_discard_reason, ''));
  if length(v_trimmed_reason) = 0 then
    raise exception 'discard_reason_required' using errcode = '22023';
  end if;

  select * into v_session
  from public.user_workout_sessions
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  -- Idempotency check: if already discarded at identical timestamp
  if v_session.status = 'discarded' and v_session.completed_at_utc = p_discarded_at_utc then
    if p_expected_revision in (v_session.revision, v_session.revision - 1) then
      return v_session;
    else
      raise exception 'stale_revision_conflict' using errcode = 'P0003';
    end if;
  end if;

  if v_session.status in ('completed', 'discarded') then
    raise exception 'session_already_terminal' using errcode = 'P0002';
  end if;

  if v_session.revision <> p_expected_revision then
    raise exception 'stale_revision_conflict' using errcode = 'P0003';
  end if;

  if p_discarded_at_utc < v_session.last_transition_at_utc then
    raise exception 'backdated_transition' using errcode = '22023';
  end if;

  if v_session.status = 'paused' then
    v_additional_us := (extract(epoch from (p_discarded_at_utc - v_session.paused_at_utc)) * 1000000)::bigint;
  end if;

  update public.user_workout_sessions
  set status = 'discarded',
      paused_at_utc = null,
      completed_at_utc = p_discarded_at_utc,
      last_transition_at_utc = p_discarded_at_utc,
      accumulated_paused_microseconds = accumulated_paused_microseconds + v_additional_us,
      discard_reason = v_trimmed_reason,
      revision = revision + 1,
      updated_at = timezone('utc'::text, now())
  where id = p_session_id and user_id = v_user_id
  returning * into v_session;

  return v_session;
end;
$$;

revoke all on function public.rpc_discard_workout_session from public, anon;
grant execute on function public.rpc_discard_workout_session to authenticated;
