-- #526 / TNYX-81: owner-approved anti-resurrection contract for permanent Routine Delete.
-- A deleted Routine UUID must not be re-created by an old atomic Create replay
-- OR the still-supported authenticated metadata-only INSERT path.
-- Private ledger stores no Routine content and is cleared on account deletion.

create table private.deleted_user_workout_routine_ids (
  routine_id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade
);

create index idx_deleted_user_workout_routine_ids_user
  on private.deleted_user_workout_routine_ids(user_id);

alter table private.deleted_user_workout_routine_ids enable row level security;

-- Not a Data API resource; SECDEF trigger and Delete RPC are its only users.
-- Default public-schema grants and client DELETE/INSERT grants remain untouched.
revoke all on table private.deleted_user_workout_routine_ids
  from public, anon, authenticated, service_role;

-- All insert paths and the Delete RPC must serialize by the same Routine UUID.
-- Hash collisions only serialize unrelated UUIDs, never admit a retired UUID.
-- This private helper is not executable by clients.
create function private.lock_user_workout_routine_identity(p_routine_id uuid)
returns void
language sql
set search_path = ''
as $$
  select pg_catalog.pg_advisory_xact_lock(
    1726041618, pg_catalog.hashtext(p_routine_id::text)
  );
$$;

revoke all on function private.lock_user_workout_routine_identity(uuid)
  from public, anon, authenticated, service_role;

-- BEFORE INSERT applies to BOTH direct metadata INSERT and the existing
-- five-argument atomic Create (including its ON CONFLICT DO NOTHING).
-- Read committed is required: after waiting on the identity lock, the
-- tombstone SELECT needs a new statement snapshot to see a committed Delete.
-- Reject other isolation levels instead of accepting a stale snapshot.
create function private.guard_deleted_user_workout_routine_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_create_isolation_unsupported'
      using errcode = '25001';
  end if;

  -- Serialize every Routine creation for this owner, even for different IDs.
  -- A statement-level budget check below then observes a committed,
  -- owner-consistent cumulative count. Acquire owner lock before UUID lock.
  perform pg_catalog.pg_advisory_xact_lock(
    1726041619, pg_catalog.hashtext(new.user_id::text)
  );

  perform private.lock_user_workout_routine_identity(new.id);

  if exists (
    select 1 from private.deleted_user_workout_routine_ids as retired
    where retired.routine_id = new.id
  ) then
    -- Do not disclose which account owned the retired UUID.
    raise exception 'routine_create_identity_conflict' using errcode = 'P0001';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_deleted_user_workout_routine_insert()
  from public, anon, authenticated, service_role;

create trigger trg_user_workout_routines_reject_retired_identity
before insert on public.user_workout_routines
for each row execute function private.guard_deleted_user_workout_routine_insert();

-- P2 / #578: bound permanent retired-ID storage. Since retired UUIDs cannot
-- expire without reopening Create replay, cap the combined number of active
-- and retired Routine identities per owner at 20,000 *for the account's life*.
-- This is a storage-safety ceiling, NOT a per-day rate limit or a visual
-- Routine-card limit. One ID is counted once after its committed Delete.
-- All Create routes (legacy metadata INSERT and atomic Create RPC) pass this
-- table trigger. Retry ON CONFLICT DO NOTHING inserts no row, preserving
-- existing idempotent replays even exactly at the ceiling.
--
-- AFTER STATEMENT + transition rows are essential: a BEFORE ROW count alone
-- could miss earlier rows in a multi-row INSERT. The BEFORE ROW guard above
-- holds the same owner advisory lock for the whole transaction, preventing
-- independent Create statements from both passing a concurrent count.
-- A failed statement rolls back every newly inserted row. No client grants.
create function private.enforce_user_workout_routine_identity_budget()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_total bigint;
begin
  for v_user_id in
    select distinct user_id from newly_inserted_routines
    order by user_id
  loop
    -- This lock is already held by the BEFORE ROW guard. Re-acquisition
    -- is safe and asserts the same owner-scoped serialization contract.
    perform pg_catalog.pg_advisory_xact_lock(
      1726041619, pg_catalog.hashtext(v_user_id::text)
    );

    select
      (select count(*) from public.user_workout_routines
       where user_id = v_user_id)
      + (select count(*) from private.deleted_user_workout_routine_ids
         where user_id = v_user_id)
    into v_total;

    if v_total > 20000 then
      raise exception 'routine_create_lifetime_budget_exhausted'
        using errcode = 'P0001';
    end if;
  end loop;

  return null;
end;
$$;

revoke all on function private.enforce_user_workout_routine_identity_budget()
  from public, anon, authenticated, service_role;

create trigger trg_user_workout_routines_identity_budget
after insert on public.user_workout_routines
referencing new table as newly_inserted_routines
for each statement
execute function private.enforce_user_workout_routine_identity_budget();


-- Same public signature, same narrow grants, same owner/program/revision CAS.
-- Account then Program key-share lock matches existing atomic Create ordering
-- and prevents account deletion from deadlocking with tombstone FK insertion.
-- Lock the UUID BEFORE the Routine parent row, matching the insert trigger.
create or replace function public.delete_user_workout_routine(
  p_routine_id uuid,
  p_program_id uuid,
  p_expected_revision bigint
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_revision bigint;
  v_deleted bigint;
begin
  if v_user_id is null then
    raise exception 'routine_delete_not_authenticated' using errcode = '28000';
  end if;

  if p_routine_id is null
      or p_program_id is null
      or p_expected_revision is null
      or p_expected_revision < 0 then
    raise exception 'invalid_routine_delete_request' using errcode = '22023';
  end if;

  perform 1 from public.users as account
  where account.id = v_user_id
  for key share;

  if not found then
    raise exception 'routine_delete_not_found' using errcode = 'P0002';
  end if;

  perform 1 from public.user_workout_programs as program
  where program.id = p_program_id and program.user_id = v_user_id
  for key share;

  if not found then
    raise exception 'routine_delete_not_found' using errcode = 'P0002';
  end if;

  perform private.lock_user_workout_routine_identity(p_routine_id);

  select routine.composition_revision into v_revision
  from public.user_workout_routines as routine
  where routine.id = p_routine_id
    and routine.program_id = p_program_id
    and routine.user_id = v_user_id
  for update;

  if not found then
    raise exception 'routine_delete_not_found' using errcode = 'P0002';
  end if;

  if v_revision <> p_expected_revision then
    raise exception 'routine_delete_revision_conflict' using errcode = 'P0001';
  end if;

  -- Record retirement atomically BEFORE deleting the parent. An error from
  -- the parent DELETE/FK cascade rolls back this tombstone in the same RPC.
  insert into private.deleted_user_workout_routine_ids (routine_id, user_id)
  values (p_routine_id, v_user_id);

  delete from public.user_workout_routines
  where id = p_routine_id
    and user_id = v_user_id
    and program_id = p_program_id
    and composition_revision = p_expected_revision;
  get diagnostics v_deleted = row_count;

  if v_deleted <> 1 then
    raise exception 'routine_delete_revision_conflict' using errcode = 'P0001';
  end if;

  return true;
end;
$$;

comment on table private.deleted_user_workout_routine_ids
  is 'Owner-bound retired Routine UUID guard only; no composition; cascade with owning account.';

comment on function public.delete_user_workout_routine(uuid,uuid,bigint)
  is 'Owner-scoped revision-CAS hard Delete; atomic private UUID retirement prevents legacy and atomic Create replay. No direct client DELETE.';
