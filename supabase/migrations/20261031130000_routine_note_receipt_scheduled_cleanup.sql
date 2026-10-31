-- TNYX-81 / PR #717
-- Sweep dormant expired Routine Note mutation snapshots while preserving the
-- permanent idempotency receipt. Hosted extension/schedule activation remains
-- subject to the separate production approval gate.

create extension if not exists pg_cron;

do $$
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname = 'routine_note_receipt_cleanup_owner'
  ) then
    create role routine_note_receipt_cleanup_owner
      nologin nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
  end if;
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname = 'routine_note_receipt_cleanup_scheduler'
  ) then
    create role routine_note_receipt_cleanup_scheduler
      login nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
  end if;
end;
$$;

do $$
begin
  if exists (
       select 1 from pg_catalog.pg_roles
       where rolname = 'routine_note_receipt_cleanup_owner'
         and (rolcanlogin or rolsuper or rolcreatedb or rolcreaterole
              or rolinherit or rolbypassrls)
     )
     or exists (
       select 1 from pg_catalog.pg_roles
       where rolname = 'routine_note_receipt_cleanup_scheduler'
         and (not rolcanlogin or rolsuper or rolcreatedb or rolcreaterole
              or rolinherit or rolbypassrls)
     )
     or exists (
       select 1
       from pg_catalog.pg_auth_members as membership
       join pg_catalog.pg_roles as granted_role
         on granted_role.oid = membership.roleid
       join pg_catalog.pg_roles as member_role
         on member_role.oid = membership.member
       where granted_role.rolname in (
               'routine_note_receipt_cleanup_owner',
               'routine_note_receipt_cleanup_scheduler'
             )
         and member_role.rolname <> 'postgres'
     ) then
    raise exception 'routine_note_cleanup_role_incompatible'
      using errcode = 'P0001';
  end if;
end;
$$;

grant usage on schema private to routine_note_receipt_cleanup_owner;
grant create on schema private to routine_note_receipt_cleanup_owner;
grant select (
  user_id, mutation_id, operation, result_kind, note_id, result_revision,
  created_at, result_snapshot
) on private.user_workout_routine_note_mutations
  to routine_note_receipt_cleanup_owner;
grant update (result_snapshot)
  on private.user_workout_routine_note_mutations
  to routine_note_receipt_cleanup_owner;

create policy routine_note_receipt_cleanup_owner_select
  on private.user_workout_routine_note_mutations
  for select to routine_note_receipt_cleanup_owner
  using (true);

create policy routine_note_receipt_cleanup_owner_update
  on private.user_workout_routine_note_mutations
  for update to routine_note_receipt_cleanup_owner
  using (true)
  with check (true);

create index idx_user_workout_routine_note_receipts_expiry
  on private.user_workout_routine_note_mutations
    (created_at, user_id, mutation_id)
  where result_snapshot->>'status' is distinct from 'expired'
     or result_snapshot ? 'note';

create function private.cleanup_expired_user_workout_routine_note_receipts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_receipt record;
  v_snapshot jsonb;
  v_redacted integer := 0;
begin
  for v_receipt in
    select receipt.user_id,
           receipt.mutation_id,
           receipt.operation,
           receipt.result_kind,
           receipt.note_id,
           receipt.result_revision,
           receipt.created_at,
           receipt.result_snapshot
    from private.user_workout_routine_note_mutations as receipt
    where receipt.created_at <=
            pg_catalog.transaction_timestamp() - interval '30 days'
      and (
        receipt.result_snapshot->>'status' is distinct from 'expired'
        or receipt.result_snapshot ? 'note'
      )
    order by receipt.created_at, receipt.user_id, receipt.mutation_id
    limit 500
    for update of receipt skip locked
  loop
    v_snapshot := v_receipt.result_snapshot;

    if v_snapshot is null
       or pg_catalog.jsonb_typeof(v_snapshot) is distinct from 'object'
       or v_snapshot->>'status' is distinct from v_receipt.result_kind
       or v_snapshot->>'note_id' is distinct from v_receipt.note_id::text
       or (v_receipt.result_kind = 'applied' and (
             pg_catalog.jsonb_typeof(v_snapshot->'note') is distinct from 'object'
             or v_snapshot->'note'->>'id'
                  is distinct from v_receipt.note_id::text
             or pg_catalog.jsonb_typeof(v_snapshot->'note'->'body')
                  is distinct from 'string'
           ))
       or (v_receipt.result_kind not in ('applied', 'deleted')) then
      raise exception 'routine_note_mutation_snapshot_unavailable'
        using errcode = 'P0001',
              detail = pg_catalog.format(
                'Expired mutation receipt %s has a malformed immutable result snapshot.',
                v_receipt.mutation_id
              );
    end if;

    update private.user_workout_routine_note_mutations as receipt
       set result_snapshot = pg_catalog.jsonb_build_object(
         'status', 'expired',
         'mutation_id', receipt.mutation_id,
         'operation', receipt.operation,
         'result_kind', receipt.result_kind,
         'note_id', receipt.note_id,
         'revision', receipt.result_revision,
         'created_at', receipt.created_at
       )
     where receipt.user_id = v_receipt.user_id
       and receipt.mutation_id = v_receipt.mutation_id
       and receipt.result_snapshot->>'status' is distinct from 'expired';

    if found then
      v_redacted := v_redacted + 1;
    end if;
  end loop;

  return v_redacted;
end;
$$;

-- In Supabase, the migration role is not a member of supabase_admin; role
-- administration is delegated by supabase_admin. PostgreSQL records this
-- membership under that grantor, so the migration role cannot revoke it.
-- Keep postgres as the only member of these private execution roles; it is the
-- trusted migration principal, not an application/client role.
grant routine_note_receipt_cleanup_owner to postgres with set true;
alter function private.cleanup_expired_user_workout_routine_note_receipts()
  owner to routine_note_receipt_cleanup_owner;
set role routine_note_receipt_cleanup_owner;
revoke all on function
  private.cleanup_expired_user_workout_routine_note_receipts()
  from public, anon, authenticated, service_role;
grant execute on function
  private.cleanup_expired_user_workout_routine_note_receipts()
  to routine_note_receipt_cleanup_scheduler;
comment on function
  private.cleanup_expired_user_workout_routine_note_receipts() is
  'Redacts at most 500 expired Routine Note receipt snapshots per call; preserves permanent mutation tombstones.';
reset role;

set role routine_note_receipt_cleanup_owner;
create function private.prune_routine_note_cleanup_job_history()
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_pruned integer;
begin
  with cleanup_jobs as (
    select job.jobid
    from cron.job as job
    where job.username = current_user
      and job.jobname like 'routine-note-receipt-%'
  ), stale_runs as (
    select details.runid
    from cron.job_run_details as details
    join cleanup_jobs on cleanup_jobs.jobid = details.jobid
    where details.status = 'succeeded'
      and details.end_time <
            pg_catalog.transaction_timestamp() - interval '90 days'
    order by details.end_time, details.runid
    limit 500
  )
  delete from cron.job_run_details as details
  using stale_runs
  where details.runid = stale_runs.runid;

  get diagnostics v_pruned = row_count;
  return v_pruned;
end;
$$;

comment on function private.prune_routine_note_cleanup_job_history() is
  'Deletes at most 500 successful cleanup-job history rows older than 90 days; retains failures and recent runs.';

revoke all on function private.prune_routine_note_cleanup_job_history()
  from public, anon, authenticated, service_role;
grant execute on function private.prune_routine_note_cleanup_job_history()
  to routine_note_receipt_cleanup_scheduler;
reset role;
grant routine_note_receipt_cleanup_scheduler to postgres with set true;
revoke create on schema private from routine_note_receipt_cleanup_owner;

grant usage on schema private to routine_note_receipt_cleanup_scheduler;

-- The scheduler only executes narrowly scoped private functions. It has no
-- receipt-table privileges and cannot bypass RLS. LOGIN is required by the
-- currently configured libpq pg_cron mode; production connection/auth mode
-- must be independently verified before hosted schedule activation.
grant usage on schema cron to routine_note_receipt_cleanup_scheduler;
grant execute on function cron.schedule(text, text, text)
  to routine_note_receipt_cleanup_scheduler;
grant execute on function cron.unschedule(text)
  to routine_note_receipt_cleanup_scheduler;

-- pg_cron records jobs under current_user. The trusted Supabase migration
-- principal must be able to SET ROLE to create these scheduler-owned jobs.
set role routine_note_receipt_cleanup_scheduler;
select cron.schedule(
  'routine-note-receipt-expiry',
  '*/5 * * * *',
  'select private.cleanup_expired_user_workout_routine_note_receipts()'
);
select cron.schedule(
  'routine-note-receipt-history',
  '17 3 * * *',
  'select private.prune_routine_note_cleanup_job_history()'
);
reset role;
