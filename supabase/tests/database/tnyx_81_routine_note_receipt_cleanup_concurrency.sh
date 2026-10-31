#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL must point at the disposable local Supabase database}"
: "${TNYX_81_DISPOSABLE_DB:?Set TNYX_81_DISPOSABLE_DB=1 only in disposable CI/local validation}"
if [[ "$TNYX_81_DISPOSABLE_DB" != "1" ]]; then
  echo 'Refusing receipt-cleanup concurrency tests outside an explicitly disposable database.' >&2
  exit 1
fi

psql_local() {
  command psql --no-psqlrc --set=ON_ERROR_STOP=1 "$DATABASE_URL" "$@"
}

identity="$(psql_local --tuples-only --no-align --command="
  select current_database() = 'postgres'
    and current_user = 'postgres'
    and exists (select 1 from pg_extension where extname = 'pg_cron')
" | tr -d '[:space:]')"
if [[ "$identity" != "t" ]]; then
  echo 'Refusing to run outside the disposable Supabase Postgres database.' >&2
  exit 1
fi

owner='a8240000-0000-4000-8000-000000000001'
note_mutation_reconcile='a8240000-0000-4000-8000-000000000201'
note_mutation_duplicate='a8240000-0000-4000-8000-000000000202'
note_id_reconcile='a8240000-0000-4000-8000-000000000101'
note_id_duplicate='a8240000-0000-4000-8000-000000000102'
scratch="$(mktemp -d)"
lock_fifo="$scratch/lock.in"
lock_log="$scratch/lock.log"
lock_pid=''
worker_a_pid=''
worker_b_pid=''
reconcile_pid=''
mutation_pid=''
expiry_job_paused=0

cleanup() {
  local status=$?
  trap - EXIT
  set +e
  for pid in "$lock_pid" "$worker_a_pid" "$worker_b_pid" "$reconcile_pid" "$mutation_pid"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
    fi
  done
  psql_local --quiet --command="
    do \$cleanup\$
    begin
      if exists (select 1 from cron.job
                 where username='routine_note_receipt_cleanup_scheduler'
                   and jobname='routine-note-receipt-test-probe') then
        perform cron.unschedule('routine-note-receipt-test-probe');
      end if;
    end
    \$cleanup\$;
    drop trigger if exists tnyx81_test_delay_receipt_cleanup
      on private.user_workout_routine_note_mutations;
    drop function if exists public.tnyx81_test_delay_receipt_cleanup();
    delete from auth.users where id='$owner'::uuid;
  " >/dev/null 2>&1
  if [[ "$expiry_job_paused" == 1 ]]; then
    if ! psql_local --quiet --command="
      set role routine_note_receipt_cleanup_scheduler;
      select cron.schedule(
        'routine-note-receipt-expiry', '*/5 * * * *',
        'select private.cleanup_expired_user_workout_routine_note_receipts()'
      );
      reset role;
    " >/dev/null 2>&1; then
      echo 'Failed to restore the scheduled receipt cleanup job.' >&2
      status=1
    fi
    restored="$(psql_local --tuples-only --no-align --command="
      set role routine_note_receipt_cleanup_scheduler;
      select exists(select 1 from cron.job
        where jobname='routine-note-receipt-expiry' and active
          and schedule='*/5 * * * *'
          and command='select private.cleanup_expired_user_workout_routine_note_receipts()');
      reset role;
    " | grep -E '^(t|true)$' | tail -n 1 | tr -d '[:space:]')"
    if [[ "$restored" != t ]]; then
      echo 'Scheduled receipt cleanup was not active after fixture cleanup.' >&2
      status=1
    fi
  fi
  rm -rf -- "$scratch"
  exit "$status"
}
trap cleanup EXIT

# The active cron job may otherwise consume the expired fixture between manual
# workers, invalidating the exact batch-size assertion. Restore it in cleanup.
psql_local --quiet --command="
  set role routine_note_receipt_cleanup_scheduler;
  select cron.unschedule('routine-note-receipt-expiry');
  reset role;
" >/dev/null
expiry_job_paused=1
paused_state="$(psql_local --tuples-only --no-align --command="
  set role routine_note_receipt_cleanup_scheduler;
  select not exists(select 1 from cron.job
    where jobname='routine-note-receipt-expiry');
  reset role;
" | grep -E '^(t|true)$' | tail -n 1 | tr -d '[:space:]')"
if [[ "$paused_state" != t ]]; then
  echo 'Could not isolate deterministic cleanup fixtures from the cron job.' >&2
  exit 1
fi

psql_local --quiet --command="
  insert into auth.users (id, email)
  values ('$owner'::uuid, 'receipt-cleanup-concurrency@example.test');
  create function public.tnyx81_test_delay_receipt_cleanup()
  returns trigger
  language plpgsql
  set search_path = ''
  as \$trigger\$
  begin
    if current_user = 'routine_note_receipt_cleanup_owner'
       and new.result_snapshot->>'status' = 'expired' then
      perform pg_catalog.pg_sleep(0.005);
    end if;
    return new;
  end;
  \$trigger\$;
  create trigger tnyx81_test_delay_receipt_cleanup
  before update of result_snapshot
  on private.user_workout_routine_note_mutations
  for each row execute function public.tnyx81_test_delay_receipt_cleanup();
  insert into private.user_workout_routine_note_mutations (
    user_id, mutation_id, operation, request_hash, result_kind, note_id,
    result_revision, created_at
  )
  select '$owner'::uuid,
         ('a8250000-0000-4000-8000-' || lpad(i::text,12,'0'))::uuid,
         'delete', md5(i::text) || md5(i::text), 'deleted',
         ('a8260000-0000-4000-8000-' || lpad(i::text,12,'0'))::uuid,
         0, transaction_timestamp() - interval '31 days'
  from generate_series(1,1001) as i;
"

wait_for_marker() {
  local marker="$1" log="$2" attempt
  for attempt in $(seq 1 150); do
    if grep -Fq "$marker" "$log"; then return 0; fi
    sleep 0.1
  done
  echo "Timed out waiting for $marker" >&2
  cat "$log" >&2
  return 1
}

start_receipt_lock() {
  local mutation_id="$1"
  rm -f -- "$lock_fifo" "$lock_log"
  mkfifo "$lock_fifo"
  psql_local --quiet --tuples-only --no-align \
    --set=owner="$owner" --set=mutation_id="$mutation_id" \
    <"$lock_fifo" >"$lock_log" 2>&1 &
  lock_pid=$!
  exec 3>"$lock_fifo"
  cat >&3 <<'SQL'
begin;
set local application_name = 'tnyx_81_receipt_cleanup_lock_holder';
select mutation_id
from private.user_workout_routine_note_mutations
where user_id = :'owner'::uuid and mutation_id = :'mutation_id'::uuid
for update;
\echo RECEIPT_ROW_LOCKED
SQL
  wait_for_marker RECEIPT_ROW_LOCKED "$lock_log"
}

release_receipt_lock() {
  cat >&3 <<'SQL'
commit;
\echo RECEIPT_ROW_LOCK_RELEASED
\quit
SQL
  exec 3>&-
  wait_for_marker RECEIPT_ROW_LOCK_RELEASED "$lock_log"
  wait "$lock_pid"
  lock_pid=''
}

start_receipt_lock 'a8250000-0000-4000-8000-000000000001'

psql_local --quiet --tuples-only --no-align \
  --command="begin; set local role routine_note_receipt_cleanup_scheduler; set local application_name='tnyx_81_cleanup_worker_a'; select private.cleanup_expired_user_workout_routine_note_receipts(); commit" \
  >"$scratch/worker-a.log" 2>&1 &
worker_a_pid=$!
psql_local --quiet --tuples-only --no-align \
  --command="begin; set local role routine_note_receipt_cleanup_scheduler; set local application_name='tnyx_81_cleanup_worker_b'; select private.cleanup_expired_user_workout_routine_note_receipts(); commit" \
  >"$scratch/worker-b.log" 2>&1 &
worker_b_pid=$!

overlap=0
for _ in $(seq 1 100); do
  active="$(psql_local --tuples-only --no-align --command="
    select count(*) from pg_stat_activity
    where application_name in (
      'tnyx_81_cleanup_worker_a','tnyx_81_cleanup_worker_b'
    ) and state='active' and query like '%cleanup_expired_user_workout_routine_note_receipts%'
  " | tr -d '[:space:]')"
  if [[ "$active" -ge 2 ]]; then overlap=1; break; fi
  if ! kill -0 "$worker_a_pid" 2>/dev/null && ! kill -0 "$worker_b_pid" 2>/dev/null; then
    break
  fi
  sleep 0.1
done
if [[ "$overlap" != 1 ]]; then
  echo 'Two cleanup workers were not observed active concurrently.' >&2
  cat "$scratch/worker-a.log" "$scratch/worker-b.log" >&2
  exit 1
fi
wait "$worker_a_pid"
worker_a_pid=''
wait "$worker_b_pid"
worker_b_pid=''

worker_a_count="$(tr -d '[:space:]' <"$scratch/worker-a.log")"
worker_b_count="$(tr -d '[:space:]' <"$scratch/worker-b.log")"
if [[ "$worker_a_count" != 500 || "$worker_b_count" != 500 ]]; then
  echo "Expected two distinct 500-row batches; got $worker_a_count and $worker_b_count." >&2
  cat "$scratch/worker-a.log" "$scratch/worker-b.log" >&2
  exit 1
fi
release_receipt_lock

remaining="$(psql_local --tuples-only --no-align \
  --command="set role routine_note_receipt_cleanup_scheduler; select private.cleanup_expired_user_workout_routine_note_receipts(); reset role" \
  | grep -E '^[0-9]+$' | tail -n 1 | tr -d '[:space:]')"
if [[ "$remaining" != 1 ]]; then
  echo "Expected the locked row to remain for one later sweep; got $remaining." >&2
  exit 1
fi

race_fixture_state="$(psql_local --tuples-only --no-align --command="
  select count(*) = 1001 and bool_and(result_snapshot->>'status'='expired')
      and bool_and(request_hash ~ '^[0-9a-f]{64}$')
  from private.user_workout_routine_note_mutations
  where user_id='$owner'::uuid
    and mutation_id::text like 'a8250000-0000-4000-8000-%'
" | tr -d '[:space:]')"
if [[ "$race_fixture_state" != t ]]; then
  echo 'Concurrent cleanup workers lost or duplicated a receipt.' >&2
  exit 1
fi
echo 'TNYX-81 concurrent cleanup workers produced disjoint batches and preserved all tombstones.'

create_note() {
  local note_id="$1" mutation_id="$2" exercise_ref="$3" body="$4"
  psql_local --quiet --command="
    begin;
    set local role authenticated;
    select set_config('request.jwt.claim.sub','$owner',true);
    select public.mutate_user_workout_routine_note(
      'create','$note_id'::uuid,null,'$exercise_ref','pinned_exercise',
      '$body',null,'$mutation_id'::uuid
    );
    commit;
  " >/dev/null
}

wait_for_lock_waiter() {
  local application_name="$1" attempt waiting
  for attempt in $(seq 1 100); do
    waiting="$(psql_local --tuples-only --no-align --command="
      select exists(select 1 from pg_stat_activity
        where application_name='$application_name'
          and state='active' and wait_event_type='Lock')
    " | tr -d '[:space:]')"
    if [[ "$waiting" == t ]]; then return 0; fi
    sleep 0.1
  done
  echo "Session $application_name did not wait on the locked receipt." >&2
  return 1
}

create_note "$note_id_reconcile" "$note_mutation_reconcile" \
  'ex_receipt_reconcile_race' 'Concurrent reconciliation body'
psql_local --quiet --command="update private.user_workout_routine_note_mutations
  set created_at=transaction_timestamp()-interval '31 days'
  where user_id='$owner'::uuid and mutation_id='$note_mutation_reconcile'::uuid"
start_receipt_lock "$note_mutation_reconcile"
psql_local --quiet --tuples-only --no-align --command="
  begin; set local role authenticated;
  set local application_name='tnyx_81_reconcile_cleanup_waiter';
  select set_config('request.jwt.claim.sub','$owner',true);
  select public.reconcile_user_workout_routine_note_mutation('$note_mutation_reconcile'::uuid);
  commit
" >"$scratch/reconcile.log" 2>&1 &
reconcile_pid=$!
wait_for_lock_waiter 'tnyx_81_reconcile_cleanup_waiter'
skip_count="$(psql_local --tuples-only --no-align \
  --command="set role routine_note_receipt_cleanup_scheduler; select private.cleanup_expired_user_workout_routine_note_receipts(); reset role" \
  | grep -E '^[0-9]+$' | tail -n 1 | tr -d '[:space:]')"
if [[ "$skip_count" != 0 ]]; then
  echo "Cleanup should skip the receipt locked by reconciliation; got $skip_count." >&2
  exit 1
fi
release_receipt_lock
wait "$reconcile_pid"
reconcile_pid=''
grep -Fq '"status": "expired"' "$scratch/reconcile.log"
echo 'TNYX-81 reconciliation and cleanup serialized safely on the receipt row.'

create_note "$note_id_duplicate" "$note_mutation_duplicate" \
  'ex_receipt_mutation_race' 'Concurrent mutation body'
psql_local --quiet --command="update private.user_workout_routine_note_mutations
  set created_at=transaction_timestamp()-interval '31 days'
  where user_id='$owner'::uuid and mutation_id='$note_mutation_duplicate'::uuid"
start_receipt_lock "$note_mutation_duplicate"
psql_local --quiet --tuples-only --no-align --command="
  begin; set local role authenticated;
  set local application_name='tnyx_81_mutation_cleanup_waiter';
  select set_config('request.jwt.claim.sub','$owner',true);
  select public.mutate_user_workout_routine_note(
    'create','$note_id_duplicate'::uuid,null,'ex_receipt_mutation_race',
    'pinned_exercise','Concurrent mutation body',null,
    '$note_mutation_duplicate'::uuid
  );
  commit
" >"$scratch/mutation.log" 2>&1 &
mutation_pid=$!
wait_for_lock_waiter 'tnyx_81_mutation_cleanup_waiter'
skip_count="$(psql_local --tuples-only --no-align \
  --command="set role routine_note_receipt_cleanup_scheduler; select private.cleanup_expired_user_workout_routine_note_receipts(); reset role" \
  | grep -E '^[0-9]+$' | tail -n 1 | tr -d '[:space:]')"
if [[ "$skip_count" != 0 ]]; then
  echo "Cleanup should skip the receipt locked by mutation replay; got $skip_count." >&2
  exit 1
fi
release_receipt_lock
wait "$mutation_pid"
mutation_pid=''
grep -Fq '"status": "expired"' "$scratch/mutation.log"
mutation_race_state="$(psql_local --tuples-only --no-align --command="
  select count(*)=1
     and bool_and(note.body='Concurrent mutation body')
     and bool_and(receipt.result_snapshot->>'status'='expired')
  from public.user_workout_routine_notes as note
  join private.user_workout_routine_note_mutations as receipt
    on receipt.user_id=note.user_id
   and receipt.mutation_id=note.last_mutation_id
  where note.user_id='$owner'::uuid
    and note.id='$note_id_duplicate'::uuid
    and note.last_mutation_id='$note_mutation_duplicate'::uuid
" | tr -d '[:space:]')"
if [[ "$mutation_race_state" != t ]]; then
  echo 'Expired concurrent mutation replay changed the Note or receipt unexpectedly.' >&2
  exit 1
fi
echo 'TNYX-81 mutation replay and cleanup serialized safely without re-execution.'

# Exercise pg_cron failure observability and recovery using a dedicated test job.
probe_job_id="$(psql_local --tuples-only --no-align --command="
  set role routine_note_receipt_cleanup_scheduler;
  select cron.schedule('routine-note-receipt-test-probe','* * * * *','select 1/0');
  reset role
" | grep -E '^[0-9]+$' | tail -n 1 | tr -d '[:space:]')"
if [[ -z "$probe_job_id" ]]; then
  echo 'Could not register disposable scheduler failure probe.' >&2
  exit 1
fi

wait_for_job_status() {
  local job_id="$1" status="$2" attempt found
  for attempt in $(seq 1 125); do
    found="$(psql_local --tuples-only --no-align --command="
      select exists(select 1 from cron.job_run_details
        where jobid=$job_id and username='routine_note_receipt_cleanup_scheduler'
          and status='$status')
    " | tr -d '[:space:]')"
    if [[ "$found" == t ]]; then return 0; fi
    sleep 1
  done
  echo "Timed out waiting for pg_cron status $status for job $job_id." >&2
  psql_local --command="select * from cron.job_run_details where jobid=$job_id" >&2
  return 1
}

wait_for_job_status "$probe_job_id" failed
psql_local --quiet --command="
  set role routine_note_receipt_cleanup_scheduler;
  select cron.schedule('routine-note-receipt-test-probe','* * * * *','select 1');
  reset role
" >/dev/null
wait_for_job_status "$probe_job_id" succeeded

psql_local --quiet --command="update cron.job_run_details
  set end_time=transaction_timestamp()-interval '91 days'
  where jobid=$probe_job_id
    and username='routine_note_receipt_cleanup_scheduler'"
psql_local --quiet --command="
  set role routine_note_receipt_cleanup_scheduler;
  select private.prune_routine_note_cleanup_job_history();
  select cron.unschedule('routine-note-receipt-test-probe');
  reset role
" >/dev/null
history_state="$(psql_local --tuples-only --no-align --command="
  select exists(select 1 from cron.job_run_details
      where jobid=$probe_job_id and status='failed')
     and not exists(select 1 from cron.job_run_details
      where jobid=$probe_job_id and status='succeeded')
" | tr -d '[:space:]')"
if [[ "$history_state" != t ]]; then
  echo 'History maintenance did not prune old success while retaining failure evidence.' >&2
  exit 1
fi
echo 'TNYX-81 pg_cron failures are visible, recovery succeeds, and failures are retained.'
