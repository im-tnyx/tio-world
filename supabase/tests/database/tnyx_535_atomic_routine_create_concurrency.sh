#!/usr/bin/env bash
set -euo pipefail

# GitHub #535: disposable real-session atomic create races.
database_url="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
user_id="a5351000-0000-4000-8000-000000000001"
program_id="a5351000-0000-4000-8000-000000000011"
custom_id="a5351000-0000-4000-8000-000000000031"
race_custom="a5351000-0000-4000-8000-000000000032"
scratch="$(mktemp -d)"
fifo="$scratch/a.stdin"
log_a="$scratch/a.log"
log_b="$scratch/b.log"
pid_a=""
pid_b=""
writer_open=0

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
  psql "$database_url" --set=ON_ERROR_STOP=1 --quiet \
    --command="delete from auth.users where id='$user_id'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$status" != 0 ]]; then
    echo "A log:"; [[ ! -f "$log_a" ]] || cat "$log_a"
    echo "B log:"; [[ ! -f "$log_b" ]] || cat "$log_b"
  fi
  rm -rf -- "$scratch"
  exit "$status"
}
trap cleanup EXIT

wait_for_log() {
  local expected=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$expected" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "Session exited before $expected"; return 1
    fi
    sleep 0.1
  done
  echo "Timed out awaiting $expected"; return 1
}

wait_for_lock() {
  local pattern=$1 pid=$2
  for _ in $(seq 1 100); do
    local waiting
    waiting="$(psql "$database_url" --tuples-only --no-align \
      --set=ON_ERROR_STOP=1 \
      --command="select exists (
        select 1 from pg_stat_activity where state='active'
        and wait_event_type='Lock' and query ilike '%$pattern%'
      )" | tr -d '[:space:]')"
    if [[ "$waiting" == t ]]; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "Concurrent session exited before waiting"; return 1
    fi
    sleep 0.1
  done
  echo "Concurrent session never blocked"; return 1
}

start_a() {
  rm -f "$fifo"
  mkfifo "$fifo"
  : > "$log_a"; : > "$log_b"
  psql "$database_url" --set=ON_ERROR_STOP=1 \
    --set=user_id="$user_id" --set=program_id="$program_id" \
    --set=custom_id="$custom_id" --set=race_custom="$race_custom" \
    <"$fifo" >"$log_a" 2>&1 &
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
  grep -Fq SESSION_A_COMMITTED "$log_a"
}

psql "$database_url" --set=ON_ERROR_STOP=1 --quiet <<SQL
insert into auth.users(id,email) values
 ('$user_id'::uuid,'issue535-two-session@example.test');
insert into public.user_workout_programs(id,user_id,name)
values ('$program_id'::uuid,'$user_id'::uuid,'Concurrency Program');
insert into public.user_workout_exercises(id,user_id,display_name,status)
values
 ('$custom_id'::uuid,'$user_id'::uuid,'Create-first','active'),
 ('$race_custom'::uuid,'$user_id'::uuid,'Archive-first','active');
SQL

# First Create holds uncommitted Routine UUID; exact second retry waits
# for the insert, then must return revision 1 with no duplicated children.
start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
select public.create_user_workout_routine_with_composition(
  'a5351000-0000-4000-8000-000000000021'::uuid, :'program_id'::uuid,
  'Race', 'a5351000-0000-4000-8000-000000000091'::uuid,
  '[{"id":"a5351000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[]}]'::jsonb
);
\echo SESSION_A_CREATED_HELD
SQL
wait_for_log SESSION_A_CREATED_HELD "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=user_id="$user_id" --set=program_id="$program_id" \
 >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
\echo SESSION_B_RETRY_START
select public.create_user_workout_routine_with_composition(
  'a5351000-0000-4000-8000-000000000021'::uuid, :'program_id'::uuid,
  'Race', 'a5351000-0000-4000-8000-000000000091'::uuid,
  '[{"id":"a5351000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[]}]'::jsonb
);
commit;
\echo SESSION_B_REPLAY_CONFIRMED
SQL
pid_b=$!
wait_for_log SESSION_B_RETRY_START "$log_b" "$pid_b"
wait_for_lock create_user_workout_routine_with_composition "$pid_b"
release_a
wait "$pid_b"
pid_b=""
grep -Fq SESSION_B_REPLAY_CONFIRMED "$log_b"

# Archive holds the Custom row lock first. Creation must wait and fail
# after archive commits, leaving no empty metadata row.
start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
update public.user_workout_exercises set status='archived'
where id=:'race_custom'::uuid;
\echo SESSION_A_ARCHIVE_HELD
SQL
wait_for_log SESSION_A_ARCHIVE_HELD "$log_a" "$pid_a"
psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=user_id="$user_id" --set=program_id="$program_id" \
 --set=race_custom="$race_custom" >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
\echo SESSION_B_CREATE_START
select public.create_user_workout_routine_with_composition(
  'a5351000-0000-4000-8000-000000000022'::uuid, :'program_id'::uuid,
  'Rejected', 'a5351000-0000-4000-8000-000000000092'::uuid,
  jsonb_build_array(jsonb_build_object(
    'id','a5351000-0000-4000-8000-000000000042',
    'exercise_ref', :'race_custom', 'sets','[]'::jsonb
  ))
);
commit;
SQL
pid_b=$!
wait_for_log SESSION_B_CREATE_START "$log_b" "$pid_b"
wait_for_lock create_user_workout_routine_with_composition "$pid_b"
release_a
if wait "$pid_b"; then
  echo "Archived Custom unexpectedly accepted"; exit 1
fi
pid_b=""
grep -Fq routine_create_exercise_unavailable "$log_b"

# Inverse race: new Create locks the active Custom until commit;
# the later archive cannot overtake it.
start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
select public.create_user_workout_routine_with_composition(
  'a5351000-0000-4000-8000-000000000023'::uuid, :'program_id'::uuid,
  'Create first', 'a5351000-0000-4000-8000-000000000093'::uuid,
  jsonb_build_array(jsonb_build_object(
    'id','a5351000-0000-4000-8000-000000000043',
    'exercise_ref', :'custom_id', 'sets','[]'::jsonb
  ))
);
\echo SESSION_A_CREATE_FIRST_HELD
SQL
wait_for_log SESSION_A_CREATE_FIRST_HELD "$log_a" "$pid_a"
psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=user_id="$user_id" --set=custom_id="$custom_id" \
 >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'user_id', true);
\echo SESSION_B_ARCHIVE_START
update public.user_workout_exercises set status='archived'
where id=:'custom_id'::uuid;
commit;
\echo SESSION_B_ARCHIVED_AFTER_CREATE
SQL
pid_b=$!
wait_for_log SESSION_B_ARCHIVE_START "$log_b" "$pid_b"
wait_for_lock update "$pid_b"
release_a
wait "$pid_b"
pid_b=""
grep -Fq SESSION_B_ARCHIVED_AFTER_CREATE "$log_b"

result="$(psql "$database_url" --tuples-only --no-align \
 --set=ON_ERROR_STOP=1 --command="select
 (select count(*)=1 from public.user_workout_routines
  where id='a5351000-0000-4000-8000-000000000021'::uuid
    and composition_revision=1)
 and (select count(*)=1 from public.user_workout_routine_exercises
  where routine_id='a5351000-0000-4000-8000-000000000021'::uuid)
 and (select count(*)=0 from public.user_workout_routines
  where id='a5351000-0000-4000-8000-000000000022'::uuid)
 and (select count(*)=1 from public.user_workout_routines
  where id='a5351000-0000-4000-8000-000000000023'::uuid
    and composition_revision=1)
 and (select count(*)=1 from public.user_workout_routine_exercises
  where routine_id='a5351000-0000-4000-8000-000000000023'::uuid)
 and (select status='archived' from public.user_workout_exercises
  where id='$custom_id'::uuid)" | tr -d '[:space:]')"
if [[ "$result" != t ]]; then
 echo "Concurrency left an invalid or duplicated Routine"; exit 1
fi
echo "GitHub #535 atomic Routine Create two-session races passed."
