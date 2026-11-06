#!/usr/bin/env bash
set -euo pipefail
# W7B-1 Workout Session Persistence: Two-session Concurrency Regression Harness.
# Exercises:
# 1. Race 1: Finish (rpc_complete_workout_session) vs concurrent Log Set (rpc_log_workout_performed_set).
# 2. Race 2A: Update Set (rpc_log_workout_performed_set) vs Remove Set (rpc_remove_workout_performed_set) for the same set UUID.
# 3. Race 2B: Remove Set vs Update Set for the same set UUID.
# Proves parent session -> performed set lock hierarchy prevents PostgreSQL 40P01 deadlock
# and guarantees serialization via OCC revision checks.

database_url="${DATABASE_URL:-}"
expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='c7340000-0000-4000-8000-000000000001'
program_id='c7340000-0000-4000-8000-000000000002'
routine_id='c7340000-0000-4000-8000-000000000003'
routine_ex_id='c7340000-0000-4000-8000-000000000004'
routine_set_id='c7340000-0000-4000-8000-000000000005'

owner_b='c7340000-0000-4000-8000-000000000002'
program_b_id='c7340000-0000-4000-8000-000000000006'
routine_b_id='c7340000-0000-4000-8000-000000000007'
routine_b_ex_id='c7340000-0000-4000-8000-000000000008'
routine_b_set_id='c7340000-0000-4000-8000-000000000009'

session_1_id='c7340000-0000-4000-8000-000000000010'
set_1_id='c7340000-0000-4000-8000-000000000020'

session_2_id='c7340000-0000-4000-8000-000000000011'
set_2_id='c7340000-0000-4000-8000-000000000021'

session_3_id='c7340000-0000-4000-8000-000000000030'
session_4_id='c7340000-0000-4000-8000-000000000040'
session_5_id='c7340000-0000-4000-8000-000000000050'

# Guard-only mode for negative / CI preflight inspection
if [[ "$#" -eq 1 && "$1" == "--guard-only" ]]; then
  exit 0
fi

is_local=0
if [[ "$#" -eq 1 && "$1" == "--local" ]]; then
  is_local=1
  database_url="${DATABASE_URL:-$expected_url}"
elif [[ "${GITHUB_ACTIONS:-}" != "true" || "$database_url" != "$expected_url" || "$#" -ne 0 ]]; then
  echo "Refusing W7B-1 concurrency race outside disposable GitHub CI database" >&2
  exit 1
fi

for variable in "${!PG@}"; do
  if [[ "$variable" != "PGPASSWORD" && "$variable" != "PGDATA" && "$variable" != "PG_VERSION" ]]; then
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
    --command="delete from auth.users where id in ('$owner'::uuid, '$owner_b'::uuid)" \
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

# 1. Setup fixtures (owner, program, routine, exercise, set for both users)
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users (id, email) values
  ('$owner'::uuid, 'w7b-race@example.test'),
  ('$owner_b'::uuid, 'w7b-race-b@example.test');
insert into public.user_workout_programs (id, user_id, name) values
  ('$program_id'::uuid, '$owner'::uuid, 'Race Program'),
  ('$program_b_id'::uuid, '$owner_b'::uuid, 'Race Program B');
insert into public.user_workout_routines (id, user_id, program_id, name) values
  ('$routine_id'::uuid, '$owner'::uuid, '$program_id'::uuid, 'Race Routine'),
  ('$routine_b_id'::uuid, '$owner_b'::uuid, '$program_b_id'::uuid, 'Race Routine B');
insert into public.user_workout_routine_exercises (id, user_id, routine_id, position, catalog_exercise_id) values
  ('$routine_ex_id'::uuid, '$owner'::uuid, '$routine_id'::uuid, 0, 'ex_barbell_bench_press'),
  ('$routine_b_ex_id'::uuid, '$owner_b'::uuid, '$routine_b_id'::uuid, 0, 'ex_barbell_bench_press');
insert into public.user_workout_routine_sets (id, user_id, routine_exercise_id, position, set_type, reps, load_kg, rest_seconds) values
  ('$routine_set_id'::uuid, '$owner'::uuid, '$routine_ex_id'::uuid, 0, 'normal', 10, 100.0, 90),
  ('$routine_b_set_id'::uuid, '$owner_b'::uuid, '$routine_b_ex_id'::uuid, 0, 'normal', 10, 100.0, 90);
SQL

valid_snapshot='{"schema_version":1,"routine_id":"'$routine_id'","program_id":"'$program_id'","routine_name":"Race Routine","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'
valid_snapshot_b='{"schema_version":1,"routine_id":"'$routine_b_id'","program_id":"'$program_b_id'","routine_name":"Race Routine B","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'

# ==============================================================================
# RACE 1: Finish vs Log Set Race
# ==============================================================================
echo "Starting Race 1: Finish vs Log Set..."

# Start session 1
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_start_workout_session(
  '$session_1_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 10:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
commit;
SQL

# Actor A holds parent row lock on session 1
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<SQL
begin;
select revision from public.user_workout_sessions where id = '$session_1_id'::uuid for update;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_A_LOCK_HELD
SQL
wait_log "SESSION_A_LOCK_HELD" "$a_log" "$pid_a"

# Actor B attempts to log a set with expected revision 1 (blocks on session lock)
psql "$database_url" --set=ON_ERROR_STOP=1 >"$b_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_B_ATTEMPT
select public.rpc_log_workout_performed_set(
  '$set_1_id'::uuid,
  '$session_1_id'::uuid,
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

# Assert Actor B is blocked waiting on lock
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

# Session A completes session (bumping revision to 2, status completed)
cat >&3 <<SQL
select public.rpc_complete_workout_session(
  '$session_1_id'::uuid,
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

# Actor B must fail with stale_revision_conflict or session_already_terminal
if wait "$pid_b"; then
  echo "Actor B unexpectedly logged a set into a completed session" >&2
  exit 1
fi
pid_b=""

if ! grep -Eq "stale_revision_conflict|session_already_terminal" "$b_log"; then
  echo "Actor B did not receive expected OCC rejection" >&2
  cat "$b_log"
  exit 1
fi

# Verify no sets logged, status completed, revision 2
final_race1="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select status = 'completed' and revision = 2 and (select count(*) from public.user_workout_performed_sets where session_id = '$session_1_id'::uuid) = 0
             from public.user_workout_sessions where id = '$session_1_id'::uuid" | tr -d '[:space:]')"

if [[ "$final_race1" != t ]]; then
  echo "Race 1 final database state violated invariants" >&2
  exit 1
fi
echo "Race 1 (Finish vs Log Set) passed cleanly."

# ==============================================================================
# RACE 2A: Simultaneous Log/Update vs Remove (Update Wins)
# ==============================================================================
echo "Starting Race 2A: Log/Update vs Remove (Update Wins)..."

# Start session 2 and log initial set (revision becomes 2)
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_start_workout_session(
  '$session_2_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 11:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
select public.rpc_log_workout_performed_set(
  '$set_2_id'::uuid,
  '$session_2_id'::uuid,
  1,
  'ex_barbell_bench_press',
  0, 0, 10, 100.0, null, null,
  '2026-11-06 11:02:00+00'::timestamptz,
  false, 'Initial set'
);
commit;
SQL

# Actor A holds parent row lock on session 2
rm -f "$fifo" "$a_log" "$b_log"
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<SQL
begin;
select revision from public.user_workout_sessions where id = '$session_2_id'::uuid for update;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_A_LOCK_HELD
SQL
wait_log "SESSION_A_LOCK_HELD" "$a_log" "$pid_a"

# Actor B attempts to remove set_2 with expected revision 2 (must block on parent session lock)
psql "$database_url" --set=ON_ERROR_STOP=1 >"$b_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_B_ATTEMPT
select public.rpc_remove_workout_performed_set(
  '$set_2_id'::uuid,
  '$session_2_id'::uuid,
  2
);
commit;
SQL
pid_b=$!
wait_log "SESSION_B_ATTEMPT" "$b_log" "$pid_b"

# Assert Actor B is blocked waiting on lock
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%rpc_remove_workout_performed_set%'
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

# Session A updates set_2 with reps 12 (expected revision 2 -> advances revision to 3)
cat >&3 <<SQL
select public.rpc_log_workout_performed_set(
  '$set_2_id'::uuid,
  '$session_2_id'::uuid,
  2,
  'ex_barbell_bench_press',
  0, 0, 12, 105.0, null, null,
  '2026-11-06 11:05:00+00'::timestamptz,
  false, 'Updated set'
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

# Actor B must fail with stale_revision_conflict (P0003), NOT 40P01 deadlock!
if wait "$pid_b"; then
  echo "Actor B unexpectedly removed set after concurrent update" >&2
  exit 1
fi
pid_b=""

if grep -Fq "40P01" "$b_log" || grep -Fq "deadlock detected" "$b_log"; then
  echo "Deadlock 40P01 detected in Race 2A!" >&2
  cat "$b_log"
  exit 1
fi

if ! grep -Fq "stale_revision_conflict" "$b_log"; then
  echo "Actor B did not receive stale_revision_conflict in Race 2A" >&2
  cat "$b_log"
  exit 1
fi

# Verify set_2 has reps = 12 and revision = 3
final_race2a="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select s.revision = 3 and p.reps = 12 and p.load_kg = 105.0
             from public.user_workout_sessions s
             join public.user_workout_performed_sets p on p.session_id = s.id
             where s.id = '$session_2_id'::uuid and p.id = '$set_2_id'::uuid" | tr -d '[:space:]')"

if [[ "$final_race2a" != t ]]; then
  echo "Race 2A final database state violated invariants" >&2
  exit 1
fi
echo "Race 2A (Log/Update vs Remove, Update wins) passed cleanly without 40P01 deadlock."

# ==============================================================================
# RACE 2B: Simultaneous Remove vs Log/Update (Remove Wins)
# ==============================================================================
echo "Starting Race 2B: Remove vs Log/Update (Remove Wins)..."

# Session 2 is currently at revision 3 with set_2 (reps 12).
# Actor B holds parent row lock on session 2
rm -f "$fifo" "$a_log" "$b_log"
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$b_log" 2>&1 &
pid_b=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<SQL
begin;
select revision from public.user_workout_sessions where id = '$session_2_id'::uuid for update;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_B_LOCK_HELD
SQL
wait_log "SESSION_B_LOCK_HELD" "$b_log" "$pid_b"

# Actor A attempts to update set_2 with expected revision 3 (must block on parent session lock)
psql "$database_url" --set=ON_ERROR_STOP=1 >"$a_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\\echo SESSION_A_ATTEMPT
select public.rpc_log_workout_performed_set(
  '$set_2_id'::uuid,
  '$session_2_id'::uuid,
  3,
  'ex_barbell_bench_press',
  0, 0, 15, 110.0, null, null,
  '2026-11-06 11:10:00+00'::timestamptz,
  false, 'Stale update'
);
commit;
SQL
pid_a=$!
wait_log "SESSION_A_ATTEMPT" "$a_log" "$pid_a"

# Assert Actor A is blocked waiting on lock
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%rpc_log_workout_performed_set%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_a" 2>/dev/null; then
    echo "A finished before lock observation"; exit 1
  fi
  sleep 0.1
done

if [[ "$blocked" != 1 ]]; then
  echo "Actor A never blocked on Actor B session row lock" >&2
  exit 1
fi

# Session B removes set_2 (expected revision 3 -> advances revision to 4)
cat >&3 <<SQL
select public.rpc_remove_workout_performed_set(
  '$set_2_id'::uuid,
  '$session_2_id'::uuid,
  3
);
commit;
\\echo SESSION_B_COMMITTED
\\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_b"
pid_b=""
grep -Fq "SESSION_B_COMMITTED" "$b_log"

# Actor A must fail with stale_revision_conflict (P0003), NOT 40P01 deadlock!
if wait "$pid_a"; then
  echo "Actor A unexpectedly logged set after concurrent remove" >&2
  exit 1
fi
pid_a=""

if grep -Fq "40P01" "$a_log" || grep -Fq "deadlock detected" "$a_log"; then
  echo "Deadlock 40P01 detected in Race 2B!" >&2
  cat "$a_log"
  exit 1
fi

if ! grep -Fq "stale_revision_conflict" "$a_log"; then
  echo "Actor A did not receive stale_revision_conflict in Race 2B" >&2
  cat "$a_log"
  exit 1
fi

# Verify set_2 is removed and revision is 4
final_race2b="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select s.revision = 4 and (select count(*) from public.user_workout_performed_sets where session_id = '$session_2_id'::uuid) = 0
             from public.user_workout_sessions s
             where s.id = '$session_2_id'::uuid" | tr -d '[:space:]')"

if [[ "$final_race2b" != t ]]; then
  echo "Race 2B final database state violated invariants" >&2
  exit 1
fi
echo "Race 2B (Remove vs Log/Update, Remove wins) passed cleanly without 40P01 deadlock."

# Complete session 2 so owner has no active session
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_complete_workout_session(
  '$session_2_id'::uuid,
  4,
  '2026-11-06 11:30:00+00'::timestamptz
);
commit;
SQL

# ==============================================================================
# RACE 3: Concurrent Identical Start Replay Race (Serializes & Recovers)
# ==============================================================================
echo "Starting Race 3: Concurrent Identical Start Replay..."

rm -f "$fifo" "$a_log" "$b_log"
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

# Actor A executes rpc_start_workout_session inside an uncommitted transaction
cat >&3 <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\echo ACTOR_A_START_HELD
select public.rpc_start_workout_session(
  '$session_3_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 12:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
\echo ACTOR_A_START_EXECUTED
SQL
wait_log "ACTOR_A_START_EXECUTED" "$a_log" "$pid_a"

# Actor B concurrently attempts to start the exact same session ID with identical parameters
psql "$database_url" --set=ON_ERROR_STOP=1 >"$b_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\echo ACTOR_B_START_ATTEMPT
select public.rpc_start_workout_session(
  '$session_3_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 12:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
commit;
\echo ACTOR_B_START_COMMITTED
SQL
pid_b=$!
wait_log "ACTOR_B_START_ATTEMPT" "$b_log" "$pid_b"

# Assert Actor B is blocked waiting for lock held by Actor A
blocked_start=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%rpc_start_workout_session%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked_start=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "Actor B finished before lock observation in Race 3"; exit 1
  fi
  sleep 0.1
done

if [[ "$blocked_start" != 1 ]]; then
  echo "Actor B never blocked on Actor A Start lock in Race 3" >&2
  exit 1
fi

# Actor A commits the newly started session
cat >&3 <<SQL
commit;
\echo ACTOR_A_START_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "ACTOR_A_START_COMMITTED" "$a_log"

# Actor B must now unblock and commit successfully
wait "$pid_b"
pid_b=''

if ! grep -Fq "ACTOR_B_START_COMMITTED" "$b_log"; then
  echo "Actor B did not commit cleanly in Race 3" >&2
  cat "$b_log"
  exit 1
fi

# Verify database state: exactly 1 session persisted, active, revision 1
final_race3="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select (select count(*) from public.user_workout_sessions where id = '$session_3_id'::uuid) = 1
                and status = 'active'
                and revision = 1
                and (select count(*) from public.user_workout_sessions where user_id = '$owner'::uuid and status in ('active', 'paused')) = 1
             from public.user_workout_sessions
             where id = '$session_3_id'::uuid" | tr -d '[:space:]')"

if [[ "$final_race3" != t ]]; then
  echo "Race 3 final database state violated invariants" >&2
  exit 1
fi
echo "Race 3 (Concurrent Identical Start Replay) passed cleanly."

# Complete session 3 so owner can start session 4
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_complete_workout_session(
  '$session_3_id'::uuid,
  1,
  '2026-11-06 12:30:00+00'::timestamptz
);
commit;
SQL

# ==============================================================================
# RACE 4: Concurrent Conflicting Start Race (Rejected via 23505)
# ==============================================================================
echo "Starting Race 4: Concurrent Conflicting Start Replay..."

rm -f "$fifo" "$a_log" "$b_log"
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

# Actor A starts session 4 in open transaction
cat >&3 <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\echo ACTOR_A_START4_HELD
select public.rpc_start_workout_session(
  '$session_4_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 13:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
\echo ACTOR_A_START4_EXECUTED
SQL
wait_log "ACTOR_A_START4_EXECUTED" "$a_log" "$pid_a"

# Actor B attempts to start session 4 with CONFLICTING local_date (2026-11-07)
psql "$database_url" --set=ON_ERROR_STOP=1 >"$b_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\echo ACTOR_B_START4_ATTEMPT
select public.rpc_start_workout_session(
  '$session_4_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 13:00:00+00'::timestamptz,
  '2026-11-07'::date,
  '$valid_snapshot'::jsonb
);
commit;
\echo ACTOR_B_START4_COMMITTED
SQL
pid_b=$!
wait_log "ACTOR_B_START4_ATTEMPT" "$b_log" "$pid_b"

# Assert Actor B is blocked waiting for lock
blocked_start4=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%rpc_start_workout_session%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked_start4=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "Actor B finished before lock observation in Race 4"; exit 1
  fi
  sleep 0.1
done

if [[ "$blocked_start4" != 1 ]]; then
  echo "Actor B never blocked on Actor A in Race 4" >&2
  exit 1
fi

# Actor A commits session 4
cat >&3 <<SQL
commit;
\echo ACTOR_A_START4_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "ACTOR_A_START4_COMMITTED" "$a_log"

# Actor B must unblock and fail with duplicate_session_conflict (23505)
set +e
wait "$pid_b"
pid_b=''
set -e

if ! grep -Fq "duplicate_session_conflict" "$b_log"; then
  echo "Actor B did not receive duplicate_session_conflict in Race 4" >&2
  cat "$b_log"
  exit 1
fi
echo "Race 4 (Concurrent Conflicting Start) passed cleanly with 23505."

# Complete session 4 so owner can start session 5
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_complete_workout_session(
  '$session_4_id'::uuid,
  1,
  '2026-11-06 13:30:00+00'::timestamptz
);
commit;
SQL

# ==============================================================================
# RACE 5: Concurrent Cross-User Start Race (Rejected via 42501)
# ==============================================================================
echo "Starting Race 5: Concurrent Cross-User Start Race..."

rm -f "$fifo" "$a_log" "$b_log"
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

# Actor A ($owner) starts session 5 in open transaction
cat >&3 <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
\echo ACTOR_A_START5_HELD
select public.rpc_start_workout_session(
  '$session_5_id'::uuid,
  '$program_id'::uuid,
  '$routine_id'::uuid,
  '2026-11-06 14:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot'::jsonb
);
\echo ACTOR_A_START5_EXECUTED
SQL
wait_log "ACTOR_A_START5_EXECUTED" "$a_log" "$pid_a"

# Actor B ($owner_b) attempts to claim session 5 UUID for Owner B
psql "$database_url" --set=ON_ERROR_STOP=1 >"$b_log" 2>&1 <<SQL &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner_b', true);
\echo ACTOR_B_START5_ATTEMPT
select public.rpc_start_workout_session(
  '$session_5_id'::uuid,
  '$program_b_id'::uuid,
  '$routine_b_id'::uuid,
  '2026-11-06 14:00:00+00'::timestamptz,
  '2026-11-06'::date,
  '$valid_snapshot_b'::jsonb
);
commit;
\echo ACTOR_B_START5_COMMITTED
SQL
pid_b=$!
wait_log "ACTOR_B_START5_ATTEMPT" "$b_log" "$pid_b"

# Assert Actor B is blocked waiting for lock
blocked_start5=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%rpc_start_workout_session%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked_start5=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "Actor B finished before lock observation in Race 5"; exit 1
  fi
  sleep 0.1
done

if [[ "$blocked_start5" != 1 ]]; then
  echo "Actor B never blocked on Actor A in Race 5" >&2
  exit 1
fi

# Actor A commits session 5
cat >&3 <<SQL
commit;
\echo ACTOR_A_START5_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "ACTOR_A_START5_COMMITTED" "$a_log"

# Actor B must unblock and fail with session_ownership_mismatch (42501)
set +e
wait "$pid_b"
pid_b=''
set -e

if ! grep -Fq "session_ownership_mismatch" "$b_log"; then
  echo "Actor B did not receive session_ownership_mismatch in Race 5" >&2
  cat "$b_log"
  exit 1
fi
echo "Race 5 (Concurrent Cross-User Start) passed cleanly with 42501."

# Complete session 5
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.rpc_complete_workout_session(
  '$session_5_id'::uuid,
  1,
  '2026-11-06 14:30:00+00'::timestamptz
);
commit;
SQL

echo "=============================================================================="
echo "All W7B-1 two-session concurrency regression races passed cleanly."
echo "=============================================================================="
