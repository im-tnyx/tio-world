#!/usr/bin/env bash
set -euo pipefail

# #526 P1: both orderings of concurrent Create/Delete by one Routine UUID.
# Only the disposable GitHub Actions database, never hosted Supabase.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/tnyx_526_owner_routine_delete_concurrency.sh" --guard-only

database_url="$DATABASE_URL"
test_user="d5271000-0000-4000-8000-000000000001"
program_id="d5271000-0000-4000-8000-000000000011"
delete_first="d5271000-0000-4000-8000-000000000021"
create_first="d5271000-0000-4000-8000-000000000022"
scratch="$(mktemp -d)"
fifo="$scratch/a.in"
log_a="$scratch/a.log"
log_b="$scratch/b.log"
pid_a=""
pid_b=""
writer_open=0

# The referenced guard rejects all PG* overrides other than PGPASSWORD.
# Ignore ~/.psqlrc and independently verify disposable DB identity before DML.
psql() { command psql --no-psqlrc "$@"; }
db_identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 --no-align   --tuples-only --command="select (current_database()='postgres' and current_user='postgres')::text"   | tr -d '[:space:]')"
if [[ "$db_identity" != true ]]; then
  echo "Refusing anti-resurrection fixtures on unexpected database" >&2
  exit 1
fi

cleanup() {
  local code=$?
  trap - EXIT
  if [[ "$writer_open" == 1 ]]; then exec 3>&-; fi
  for pid in "$pid_a" "$pid_b"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  psql "$database_url" --quiet --set=ON_ERROR_STOP=1     --command="delete from auth.users where id='$test_user'::uuid"     >/dev/null 2>&1 || true
  if [[ "$code" != 0 ]]; then
    echo "Session A log:"; [[ ! -f "$log_a" ]] || cat "$log_a"
    echo "Session B log:"; [[ ! -f "$log_b" ]] || cat "$log_b"
  fi
  rm -rf -- "$scratch"
  exit "$code"
}
trap cleanup EXIT

wait_log() {
  local needle=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$needle" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  echo "Never saw expected session marker: $needle" >&2
  return 1
}

wait_blocked() {
  local needle=$1 pid=$2
  for _ in $(seq 1 100); do
    local waiting
    waiting="$(psql "$database_url" --tuples-only --no-align       --set=ON_ERROR_STOP=1 --command="select exists (
       select 1 from pg_stat_activity
       where state='active' and wait_event_type='Lock'
         and query like '%$needle%'
      )" | tr -d '[:space:]')"
    if [[ "$waiting" == t ]]; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "Concurrent session exited before waiting on identity lock" >&2
      return 1
    fi
    sleep 0.1
  done
  echo "Concurrent session did not wait on identity lock" >&2
  return 1
}

start_a() {
  rm -f "$fifo"
  mkfifo "$fifo"
  : >"$log_a"
  : >"$log_b"
  psql "$database_url" --set=ON_ERROR_STOP=1     --set=user_id="$test_user" --set=program_id="$program_id"     --set=delete_first="$delete_first" --set=create_first="$create_first"     <"$fifo" >"$log_a" 2>&1 &
  pid_a=$!
  exec 3>"$fifo"
  writer_open=1
}

release_a() {
  cat >&3 <<'SQL'
commit;
\echo SESSION_A_COMMITTED
\quit
SQL
  exec 3>&-
  writer_open=0
  wait "$pid_a"
  pid_a=""
  grep -Fq "SESSION_A_COMMITTED" "$log_a"
}

psql "$database_url" --set=ON_ERROR_STOP=1 --quiet <<SQL
insert into auth.users(id,email) values
 ('$test_user'::uuid,'anti-resurrection-race@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$program_id'::uuid,'$test_user'::uuid,'Anti-resurrection Race Program');
SQL

# A Delete holds its uncommitted tombstone/UUID advisory lock.
# The exact old atomic Create retry must block, then fail after A commits.
psql "$database_url" --set=ON_ERROR_STOP=1 --quiet   --set=user_id="$test_user" --set=program_id="$program_id"   --set=routine_id="$delete_first" <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
select public.create_user_workout_routine_with_composition(
  :'routine_id'::uuid, :'program_id'::uuid, 'To retire',
  'd5271000-0000-4000-8000-000000000091'::uuid,
  '[{"id":"d5271000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
       {"id":"d5271000-0000-4000-8000-000000000051","reps":9}]}]'::jsonb
);
commit;
SQL

start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
select public.delete_user_workout_routine(
  :'delete_first'::uuid, :'program_id'::uuid, 1
);
\echo SESSION_A_DELETE_UNCOMMITTED
SQL
wait_log SESSION_A_DELETE_UNCOMMITTED "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1   --set=user_id="$test_user" --set=program_id="$program_id"   --set=routine_id="$delete_first" >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
\echo SESSION_B_STALE_CREATE_START
select public.create_user_workout_routine_with_composition(
  :'routine_id'::uuid, :'program_id'::uuid, 'To retire',
  'd5271000-0000-4000-8000-000000000091'::uuid,
  '[{"id":"d5271000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
       {"id":"d5271000-0000-4000-8000-000000000051","reps":9}]}]'::jsonb
);
commit;
SQL
pid_b=$!
wait_log SESSION_B_STALE_CREATE_START "$log_b" "$pid_b"
wait_blocked create_user_workout_routine_with_composition "$pid_b"
release_a
if wait "$pid_b"; then
  echo "Stale Create resurrected a committed Delete" >&2
  exit 1
fi
pid_b=""
grep -Fq "routine_create_identity_conflict" "$log_b"

# Inverse order: an uncommitted atomic Create holds the identity lock;
# Delete waits for Create to commit, then deletes revision 1 and retires it.
start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
select public.create_user_workout_routine_with_composition(
  :'create_first'::uuid, :'program_id'::uuid, 'Created first',
  'd5271000-0000-4000-8000-000000000092'::uuid,
  '[{"id":"d5271000-0000-4000-8000-000000000042",
     "exercise_ref":"ex_squat","sets":[
       {"id":"d5271000-0000-4000-8000-000000000052","reps":9}]}]'::jsonb
);
\echo SESSION_A_CREATE_UNCOMMITTED
SQL
wait_log SESSION_A_CREATE_UNCOMMITTED "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1   --set=user_id="$test_user" --set=program_id="$program_id"   --set=routine_id="$create_first" >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
\echo SESSION_B_DELETE_START
select public.delete_user_workout_routine(
  :'routine_id'::uuid, :'program_id'::uuid, 1
);
commit;
\echo SESSION_B_DELETE_COMMITTED
SQL
pid_b=$!
wait_log SESSION_B_DELETE_START "$log_b" "$pid_b"
wait_blocked delete_user_workout_routine "$pid_b"
release_a
wait "$pid_b"
pid_b=""
grep -Fq "SESSION_B_DELETE_COMMITTED" "$log_b"

result="$(psql "$database_url" --tuples-only --no-align   --set=ON_ERROR_STOP=1 --command="select
    not exists(select 1 from public.user_workout_routines
               where id in ('$delete_first'::uuid,'$create_first'::uuid))
    and (select count(*)=2 from private.deleted_user_workout_routine_ids
         where routine_id in ('$delete_first'::uuid,'$create_first'::uuid))
    and not exists(select 1 from public.user_workout_routine_exercises
                   where routine_id in ('$delete_first'::uuid,'$create_first'::uuid))
    and exists(select 1 from public.user_workout_programs
               where id='$program_id'::uuid)" | tr -d '[:space:]')"
if [[ "$result" != t ]]; then
  echo "Create/Delete race left resurrected, unretired or orphaned data" >&2
  exit 1
fi
echo "TNYX-526 two-session Delete-first and Create-first anti-resurrection races passed."
