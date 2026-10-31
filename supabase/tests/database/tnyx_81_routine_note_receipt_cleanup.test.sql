\set ON_ERROR_STOP on

begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.assert_raises_exact(
  p_sql text, p_state text, p_error text, p_message text
)
returns void language plpgsql as $$
declare
  v_state text;
  v_error text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate,
                            v_error = message_text;
    if v_state = p_state and v_error = p_error then return; end if;
    raise exception 'assertion failed: % expected %/%, got %/%',
      p_message, p_state, p_error, v_state, v_error;
  end;
  raise exception 'assertion failed: % (succeeded)', p_message;
end;
$$;

select pg_temp.assert_true(
  (select extversion = '1.6.4' from pg_extension where extname = 'pg_cron')
  and (select setting = 'off' from pg_settings
       where name = 'cron.use_background_workers')
  and (select rolcanlogin and not rolsuper and not rolcreatedb
              and not rolcreaterole and not rolinherit and not rolbypassrls
       from pg_roles where rolname = 'routine_note_receipt_cleanup_scheduler')
  and (select not rolcanlogin and not rolsuper and not rolcreatedb
              and not rolcreaterole and not rolinherit and not rolbypassrls
       from pg_roles where rolname = 'routine_note_receipt_cleanup_owner'),
  'pg_cron version/mode and cleanup roles match the least-privilege contract'
);

select pg_temp.assert_true(
  (select pg_has_role(
            'postgres', 'routine_note_receipt_cleanup_owner', 'MEMBER'
          )
          and pg_has_role(
            'postgres', 'routine_note_receipt_cleanup_scheduler', 'MEMBER'
          ))
  and pg_has_role(
        'postgres', 'routine_note_receipt_cleanup_owner', 'SET'
      )
  and pg_has_role(
        'postgres', 'routine_note_receipt_cleanup_scheduler', 'SET'
      )
  and not exists (
    select 1
    from pg_auth_members as membership
    join pg_roles as granted_role on granted_role.oid = membership.roleid
    join pg_roles as member_role on member_role.oid = membership.member
    where granted_role.rolname in (
            'routine_note_receipt_cleanup_owner',
            'routine_note_receipt_cleanup_scheduler'
          )
      and member_role.rolname <> 'postgres'
  ),
  'trusted migration principal is the only member of cleanup roles'
);

select pg_temp.assert_true(
  (select pg_get_userbyid(proowner) = 'routine_note_receipt_cleanup_owner'
          and prosecdef
          and proconfig @> array['search_path=""']
   from pg_proc
   where oid = 'private.cleanup_expired_user_workout_routine_note_receipts()'::regprocedure)
  and (select pg_get_userbyid(proowner) = 'routine_note_receipt_cleanup_owner'
          and not prosecdef
          and proconfig @> array['search_path=""']
   from pg_proc
   where oid = 'private.prune_routine_note_cleanup_job_history()'::regprocedure)
  and has_column_privilege(
        'routine_note_receipt_cleanup_owner',
        'private.user_workout_routine_note_mutations',
        'result_snapshot', 'UPDATE'
      )
  and has_column_privilege(
        'routine_note_receipt_cleanup_owner',
        'private.user_workout_routine_note_mutations',
        'user_id', 'SELECT'
      )
  and not has_column_privilege(
        'routine_note_receipt_cleanup_owner',
        'private.user_workout_routine_note_mutations',
        'request_hash', 'SELECT'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_owner',
        'private.user_workout_routine_note_mutations', 'UPDATE'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_owner',
        'private.user_workout_routine_note_mutations', 'SELECT'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_owner',
        'private.user_workout_routine_note_mutations', 'INSERT'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'private.user_workout_routine_note_mutations', 'SELECT'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'private.user_workout_routine_note_mutations', 'UPDATE'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'private.user_workout_routine_note_mutations', 'INSERT'
      )
  and not has_table_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'private.user_workout_routine_note_mutations', 'DELETE'
      )
  and has_function_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'private.cleanup_expired_user_workout_routine_note_receipts()',
        'EXECUTE'
      )
  and has_function_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'private.prune_routine_note_cleanup_job_history()',
        'EXECUTE'
      )
  and has_table_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'cron.job_run_details', 'DELETE'
      )
  and not has_function_privilege(
        'anon',
        'private.cleanup_expired_user_workout_routine_note_receipts()',
        'EXECUTE'
      )
  and not has_function_privilege(
        'authenticated',
        'private.cleanup_expired_user_workout_routine_note_receipts()',
        'EXECUTE'
      )
  and not has_function_privilege(
        'service_role',
        'private.cleanup_expired_user_workout_routine_note_receipts()',
        'EXECUTE'
      )
  and not has_function_privilege(
        'anon',
        'private.prune_routine_note_cleanup_job_history()',
        'EXECUTE'
      )
  and not has_function_privilege(
        'authenticated',
        'private.prune_routine_note_cleanup_job_history()',
        'EXECUTE'
      )
  and not has_function_privilege(
        'service_role',
        'private.prune_routine_note_cleanup_job_history()',
        'EXECUTE'
      )
  and not has_schema_privilege('anon', 'cron', 'USAGE')
  and not has_schema_privilege('authenticated', 'cron', 'USAGE')
  and not has_schema_privilege('service_role', 'cron', 'USAGE')
  and has_function_privilege(
        'anon', 'cron.schedule(text,text,text)', 'EXECUTE'
      )
  and has_function_privilege(
        'routine_note_receipt_cleanup_scheduler',
        'cron.schedule(text,text,text)', 'EXECUTE'
      )
  and not exists (
        select 1
        from pg_proc as function
        join pg_namespace as namespace on namespace.oid = function.pronamespace
        where namespace.nspname = 'cron'
          and function.prosecdef
          and has_function_privilege(
                'routine_note_receipt_cleanup_scheduler',
                function.oid, 'EXECUTE'
              )
      ),
  'cleanup function ownership, fixed search_path and effective ACLs are narrow'
);

select pg_temp.assert_true(
  (select count(*) = 2
          and bool_and(username = 'routine_note_receipt_cleanup_scheduler')
          and bool_and(active)
   from cron.job
   where jobname in (
     'routine-note-receipt-expiry',
     'routine-note-receipt-history'
   ))
  and (select schedule = '*/5 * * * *'
       from cron.job
       where jobname = 'routine-note-receipt-expiry'
         and username = 'routine_note_receipt_cleanup_scheduler')
  and (select schedule = '17 3 * * *'
       from cron.job
       where jobname = 'routine-note-receipt-history'
         and username = 'routine_note_receipt_cleanup_scheduler')
  and (select command =
              'select private.cleanup_expired_user_workout_routine_note_receipts()'
       from cron.job
       where jobname = 'routine-note-receipt-expiry'
         and username = 'routine_note_receipt_cleanup_scheduler')
  and (select command =
              'select private.prune_routine_note_cleanup_job_history()'
       from cron.job
       where jobname = 'routine-note-receipt-history'
         and username = 'routine_note_receipt_cleanup_scheduler')
  and (select pg_get_userbyid(relowner) <> 'routine_note_receipt_cleanup_owner'
       from pg_class
       where oid = 'private.user_workout_routine_note_mutations'::regclass)
  and (select count(*) = 2
       from pg_policies
       where schemaname = 'private'
         and tablename = 'user_workout_routine_note_mutations'
         and policyname like 'routine_note_receipt_cleanup_owner_%'),
  'both scheduled jobs are owned by the restricted scheduler with expected cadence'
);

select cron.schedule(
  'tnyx81_cleanup_visibility_probe', '* * * * *', 'select 1'
);
set local role routine_note_receipt_cleanup_scheduler;
select pg_temp.assert_true(
  not exists (
    select 1 from cron.job
    where jobname = 'tnyx81_cleanup_visibility_probe'
  )
  and not exists (
    select 1 from cron.job_run_details
    where username = 'postgres'
  ),
  'pg_cron RLS hides other roles jobs and run history from the scheduler'
);
reset role;
select cron.unschedule('tnyx81_cleanup_visibility_probe');

set local role routine_note_receipt_cleanup_scheduler;
select pg_temp.assert_true(
  private.prune_routine_note_cleanup_job_history() = 0,
  'history cleanup has no-op behavior when no old successful runs exist'
);
reset role;

insert into auth.users (id, email) values
  ('a8210000-0000-4000-8000-000000000001', 'receipt-cleanup-a@example.test'),
  ('a8210000-0000-4000-8000-000000000002', 'receipt-cleanup-b@example.test');

-- Create real immutable applied snapshots through the authenticated RPC.
set local role authenticated;
select set_config(
  'request.jwt.claim.sub', 'a8210000-0000-4000-8000-000000000001', true
);
select public.mutate_user_workout_routine_note(
  'create', 'a8210000-0000-4000-8000-000000000101', null,
  'ex_receipt_cleanup', 'pinned_exercise',
  'Retain before the cutoff', null,
  'a8210000-0000-4000-8000-000000000201'
);
select public.mutate_user_workout_routine_note(
  'create', 'a8210000-0000-4000-8000-000000000102', null,
  'ex_receipt_cleanup_at', 'pinned_exercise',
  'Redact at the cutoff', null,
  'a8210000-0000-4000-8000-000000000202'
);
select public.mutate_user_workout_routine_note(
  'create', 'a8210000-0000-4000-8000-000000000103', null,
  'ex_receipt_cleanup_after', 'pinned_exercise',
  'Redact after the cutoff', null,
  'a8210000-0000-4000-8000-000000000203'
);
select public.mutate_user_workout_routine_note(
  'create', 'a8210000-0000-4000-8000-000000000104', null,
  'ex_receipt_cleanup_dormant', 'pinned_exercise',
  'Dormant note body', null,
  'a8210000-0000-4000-8000-000000000204'
);
reset role;

-- User B may reuse the UUID because receipts are keyed by owner + mutation ID.
set local role authenticated;
select set_config(
  'request.jwt.claim.sub', 'a8210000-0000-4000-8000-000000000002', true
);
select public.mutate_user_workout_routine_note(
  'create', 'a8210000-0000-4000-8000-000000000201', null,
  'ex_receipt_cleanup_b', 'pinned_exercise',
  'Other owner remains private', null,
  'a8210000-0000-4000-8000-000000000202'
);
reset role;

update private.user_workout_routine_note_mutations
set created_at = case mutation_id
  when 'a8210000-0000-4000-8000-000000000201' then
    transaction_timestamp() - interval '30 days' + interval '1 second'
  when 'a8210000-0000-4000-8000-000000000202' then
    transaction_timestamp() - interval '30 days'
  when 'a8210000-0000-4000-8000-000000000203' then
    transaction_timestamp() - interval '31 days'
  when 'a8210000-0000-4000-8000-000000000204' then
    transaction_timestamp() - interval '31 days'
end
where user_id = 'a8210000-0000-4000-8000-000000000001'
  and mutation_id in (
    'a8210000-0000-4000-8000-000000000201',
    'a8210000-0000-4000-8000-000000000202',
    'a8210000-0000-4000-8000-000000000203',
    'a8210000-0000-4000-8000-000000000204'
  );

create temporary table cleanup_receipt_hashes as
select mutation_id, request_hash
from private.user_workout_routine_note_mutations
where user_id = 'a8210000-0000-4000-8000-000000000001'
  and mutation_id in (
    'a8210000-0000-4000-8000-000000000201',
    'a8210000-0000-4000-8000-000000000202',
    'a8210000-0000-4000-8000-000000000203',
    'a8210000-0000-4000-8000-000000000204'
  );

set local role routine_note_receipt_cleanup_scheduler;
select pg_temp.assert_true(
  private.cleanup_expired_user_workout_routine_note_receipts() = 3,
  'sweep expires exact-cutoff, after-cutoff and dormant receipts'
);
select pg_temp.assert_true(
  private.cleanup_expired_user_workout_routine_note_receipts() = 0,
  'repeated sweep is idempotent'
);
select pg_temp.assert_true(
  private.prune_routine_note_cleanup_job_history() = 0,
  'history cleanup succeeds when no old successful runs exist'
);
reset role;

select pg_temp.assert_true(
  (select result_snapshot->>'status' = 'applied'
          and result_snapshot->'note'->>'body' = 'Retain before the cutoff'
   from private.user_workout_routine_note_mutations
   where user_id = 'a8210000-0000-4000-8000-000000000001'
     and mutation_id = 'a8210000-0000-4000-8000-000000000201')
  and (select result_snapshot->>'status' = 'expired'
          and result_snapshot->'note' is null
          and result_snapshot->>'mutation_id' =
                'a8210000-0000-4000-8000-000000000202'
   from private.user_workout_routine_note_mutations
   where user_id = 'a8210000-0000-4000-8000-000000000001'
     and mutation_id = 'a8210000-0000-4000-8000-000000000202')
  and (select request_hash = (
                 select expected.request_hash
                 from cleanup_receipt_hashes as expected
                 where expected.mutation_id = receipt.mutation_id
               )
          and result_snapshot->>'status' = 'expired'
   from private.user_workout_routine_note_mutations as receipt
   where user_id = 'a8210000-0000-4000-8000-000000000001'
     and mutation_id = 'a8210000-0000-4000-8000-000000000204'),
  'body is removed while mutation ID, request hash and unexpired snapshots remain'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', 'a8210000-0000-4000-8000-000000000001', true
);
select pg_temp.assert_true(
  public.reconcile_user_workout_routine_note_mutation(
    'a8210000-0000-4000-8000-000000000202'
  )->>'status' = 'expired',
  'reconciliation returns explicit expired after dormant cleanup'
);
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
      'create', 'a8210000-0000-4000-8000-000000000105', null,
      'ex_receipt_cleanup_at', 'pinned_exercise',
      'different body cannot replay expired id', null,
      'a8210000-0000-4000-8000-000000000202'
    )$$,
  'P0001', 'routine_note_mutation_conflict',
  'expired mutation ID never executes a different request'
);
select pg_temp.assert_true(
  public.mutate_user_workout_routine_note(
    'create', 'a8210000-0000-4000-8000-000000000102', null,
    'ex_receipt_cleanup_at', 'pinned_exercise',
    'Redact at the cutoff', null,
    'a8210000-0000-4000-8000-000000000202'
  )->>'status' = 'expired',
  'duplicate retry of an expired mutation returns the tombstone'
);
reset role;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', 'a8210000-0000-4000-8000-000000000002', true
);
select pg_temp.assert_true(
  public.reconcile_user_workout_routine_note_mutation(
    'a8210000-0000-4000-8000-000000000202'
  )->'note'->>'body' = 'Other owner remains private',
  'same mutation UUID under another owner is not expired or disclosed'
);
reset role;

-- Null and malformed snapshots fail loudly; repair in the test transaction and
-- verify a later cleanup pass succeeds rather than silently skipping damage.
insert into private.user_workout_routine_note_mutations (
  user_id, mutation_id, operation, request_hash, result_kind, note_id,
  result_revision, created_at
) values
  ('a8210000-0000-4000-8000-000000000001',
   'a8210000-0000-4000-8000-000000000301', 'delete', repeat('1',64),
   'deleted', 'a8210000-0000-4000-8000-000000000401', 0,
   transaction_timestamp() - interval '31 days'),
  ('a8210000-0000-4000-8000-000000000001',
   'a8210000-0000-4000-8000-000000000302', 'delete', repeat('2',64),
   'deleted', 'a8210000-0000-4000-8000-000000000402', 0,
   transaction_timestamp() - interval '31 days');

update private.user_workout_routine_note_mutations
set result_snapshot = null
where user_id = 'a8210000-0000-4000-8000-000000000001'
  and mutation_id = 'a8210000-0000-4000-8000-000000000301';
update private.user_workout_routine_note_mutations
set result_snapshot = '{}'::jsonb
where user_id = 'a8210000-0000-4000-8000-000000000001'
  and mutation_id = 'a8210000-0000-4000-8000-000000000302';

grant routine_note_receipt_cleanup_scheduler to postgres;
set local role routine_note_receipt_cleanup_scheduler;
select pg_temp.assert_raises_exact(
  'select private.cleanup_expired_user_workout_routine_note_receipts()',
  'P0001', 'routine_note_mutation_snapshot_unavailable',
  'null/malformed candidate snapshot raises and rolls back the batch'
);
reset role;
revoke routine_note_receipt_cleanup_scheduler from postgres;

update private.user_workout_routine_note_mutations
set result_snapshot = jsonb_build_object(
  'status', 'deleted', 'note_id', note_id, 'revision', result_revision
)
where user_id = 'a8210000-0000-4000-8000-000000000001'
  and mutation_id in (
    'a8210000-0000-4000-8000-000000000301',
    'a8210000-0000-4000-8000-000000000302'
  );
grant routine_note_receipt_cleanup_scheduler to postgres;
set local role routine_note_receipt_cleanup_scheduler;
select pg_temp.assert_true(
  private.cleanup_expired_user_workout_routine_note_receipts() = 2,
  'repaired malformed candidates are processed on retry'
);
reset role;
revoke routine_note_receipt_cleanup_scheduler from postgres;

-- 511 old receipts exercise the 500-row ceiling and deterministic continuation.
insert into private.user_workout_routine_note_mutations (
  user_id, mutation_id, operation, request_hash, result_kind, note_id,
  result_revision, created_at
)
select 'a8210000-0000-4000-8000-000000000001',
       ('a8220000-0000-4000-8000-' || pg_catalog.lpad(i::text, 12, '0'))::uuid,
       'delete', pg_catalog.md5(i::text) || pg_catalog.md5(i::text), 'deleted',
       ('a8230000-0000-4000-8000-' || pg_catalog.lpad(i::text, 12, '0'))::uuid,
       0, transaction_timestamp() - interval '31 days'
from pg_catalog.generate_series(1, 511) as i;

grant routine_note_receipt_cleanup_scheduler to postgres;
set local role routine_note_receipt_cleanup_scheduler;
select pg_temp.assert_true(
  private.cleanup_expired_user_workout_routine_note_receipts() = 500,
  'cleanup invocation is bounded to 500 receipts'
);
select pg_temp.assert_true(
  private.cleanup_expired_user_workout_routine_note_receipts() = 11,
  'second stable batch completes the backlog without skipped receipts'
);
select pg_temp.assert_true(
  private.cleanup_expired_user_workout_routine_note_receipts() = 0,
  'completed backlog remains idempotent'
);
reset role;

select pg_temp.assert_true(
  (select count(*) = 511
          and bool_and(result_snapshot->>'status' = 'expired')
          and bool_and(result_snapshot->'note' is null)
          and bool_and(request_hash ~ '^[0-9a-f]{64}$')
   from private.user_workout_routine_note_mutations
   where user_id = 'a8210000-0000-4000-8000-000000000001'
     and mutation_id::text like 'a8220000-0000-4000-8000-%'),
  'all batch tombstones retain request hashes and omit Note bodies'
);

rollback;
