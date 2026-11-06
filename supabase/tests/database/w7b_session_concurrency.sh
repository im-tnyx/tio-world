#!/usr/bin/env bash
set -euo pipefail
# W7B-1 Workout Session Persistence: two-session concurrent Finish vs Log Set race.
# Proves OCC revision bumping and parent row lock serialization prevents
# logging a performed set into a completing/completed session.

database_url="${DATABASE_URL:-}"
expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='c7340000-0000-4000-8000-000000000001'
program_id='c7340000-0000-4000-8000-000000000002'
routine_id='c7340000-0000-4000-8000-000000000003'
routine_ex_id='c7340000-0000-4000-8000-000000000004'
routine_set_id='c7340000-0000-4000-8000-000000000005'
session_id='c7340000-0000-4000-8000-000000000010'
set_id='c7340000-0000-4000-8000-000000000020'

# Guard-only mode for negative / CI preflight inspection
if [[ "$#" -eq 1 && "$1" == "--guard-only" ]]; then
  exit 0
fi

if [[ "${GITHUB_ACTIONS:-}" != "true" || "$database_url" != "$expected_url" || "$#" -ne 0 ]]; then
  echo "Refusing W7B-1 concurrency race outside disposable GitHub CI database" >&2
  exit 1
fi

for variable in "${!PG@}"; do
  if [[ "$variable" != "PGPASSWORD" ]]; then
    echo "Refusing libpq connection override: $variable" >&2
    exit 1
  fi
done

psql() { command psql --no-psqlrc "$@"; }

identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select current_database()='postgres' and current_user='postgres'" | tr -d '[:space:]')"
if [[ "$identity" != t ]]; then
  echo "Unexpected database identity" >&2
  exit 1
fi

scratch="$(mktemp -d)"
fifo="$scratch/a.in"
a_log="$scratch/a.log"
b_log="$scratch/b.log"
pid_a='' pid_b='' writer_open=0

cleanup() {
  local status=$?
  trap - EXIT
  if [[ "$writer_open" == 1 ]]; then exec 3>&-; fi
  for pid in "$pid_a" "$pid_b"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  psql "$database_url" --set=ON_ERROR_STOP=1 -q \
    --command="delete from auth.users where id='$owner'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$status" -ne 0 ]]; then
    echo 'Actor A log:'; [[ ! -e "$a_log" ]] || cat "$a_log"
    echo 'Actor B log:'; [[ ! -e "$b_log" ]] || cat "$b_log"
  fi
  rm -rf "$scratch"
  exit "$status"
}
trap cleanup EXIT

wait_log() {
  local marker=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$marker" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  return 1
}

# 1. Setup fixtures (owner, program, routine, exercise, set, and active session)
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users (id, email) values ('$owner'::uuid, 'w7b-race@example.test');
insert into public.users (id, email) values ('$owner'::uuid, 'w7b-race@example.test');
insert into public.user_workout_programs (id, user_id, name) values ('$program_id'::uuid, '$owner'::uuid, 'Race Program');
insert into public.user_workout_routines (id, user_id, program_id, name) values ('$routine_id'::uuid, '$owner'::uuid, '$program_id'::uuid, 'Race Routine');
insert into public.user_workout_routine_exercises (id, user_id, routine_id, position, catalog_exercise_id)
  values ('$routine_ex_id'::uuid, '$owner'::uuid, '$routine_id'::uuid, 0, 'ex_barbell_bench_press');
insert into public.user_workout_routine_sets (id, user_id, routine_exercise_id, position, set_type, reps, load_kg, rest_seconds)
  values ('$routine_set_id'::uuid, '$owner'::uuid, '$routine_ex_id'::uuid, 0, 'normal', 10, 100.0, 90);
SQL

valid_snapshot='{"schema_version":1,"routine_id":"'$routine_id'","program_id":"'$program_id'","routine_name":"Race Routine","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'

# Start the session as owner
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
set role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_start_workout_session(
  '$session_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 10:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
SQL

# 2. Race: Session A holds parent row lock while Session B attempts to log a set
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
-- Lock session row in exclusive mode
select revision from public.user_workout_sessions where id = '$session_id'::uuid for update;
\\echo SESSION_A_LOCK_HELD
SQL
wait_log "SESSION_A_LOCK_HELD" "$a_log" "$pid_a"

# Actor B attempts to log a set with expected revision 1 (must block on Actor A's row lock)
psql "$database_url" --set=ON_ERROR_STOP=1 >"$b_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_B_ATTEMPT
select public.rpc_log_workout_performed_set(
  '$set_id'::uuid,
  '$session_id'::uuid,
  1,
  'ex_barbell_bench_press',
  0, 0, 10, 100.0, null, null,
  '2026-11-06 10:05:00+00'::timestamptz,
  false, null
);
commit;
SQL
pid_b=$!
wait_log "SESSION_B_ATTEMPT" "$b_log" "$pid_b"

# Require evidence that Actor B is blocked waiting on the lock held by Actor A
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%rpc_log_workout_performed_set%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "B finished before lock observation"; exit 1
  fi
  sleep 0.1
done

if [[ "$blocked" != 1 ]]; then
  echo "Actor B never blocked on Actor A session row lock" >&2
  exit 1
fi

# Session A completes the session (bumping revision to 2 and setting status to completed)
cat >&3 <<SQL
select public.rpc_complete_workout_session(
  '$session_id'::uuid,
  1,
  '2026-11-06 10:30:00+00'::timestamptz,
  'Finished workout'
);
commit;
\\echo SESSION_A_COMMITTED
\\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "SESSION_A_COMMITTED" "$a_log"

# Actor B must fail because expected revision was 1, but session is now completed with revision 2
if wait "$pid_b"; then
  echo "Actor B unexpectedly logged a set into a completed session" >&2
  exit 1
fi
pid_b=""

# Verify Actor B was rejected with stale_revision_conflict
if ! grep -Eq "stale_revision_conflict|invalid_session_status" "$b_log"; then
  echo "Actor B did not receive expected rejection" >&2
  cat "$b_log"
  exit 1
fi

# Verify database state: session is completed, revision is 2, 0 performed sets
final_state="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select status = 'completed' and revision = 2 and (select count(*) from public.user_workout_performed_sets where session_id = '$session_id'::uuid) = 0
             from public.user_workout_sessions where id = '$session_id'::uuid" | tr -d '[:space:]')"

if [[ "$final_state" != t ]]; then
  echo "Final database state violated invariants after concurrency race" >&2
  exit 1
fi

echo "W7B-1 Finish vs Log Set two-session concurrency race passed cleanly."
