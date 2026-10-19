#!/usr/bin/env bash
set -euo pipefail
# GitHub #568 / Linear TNYX-78: two-session concurrent first Create Routine in My Program.
# Restrict fixture execution to exact disposable CI database.
database_url="${DATABASE_URL:-}"
expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='b5680000-0000-4000-8000-000000000001'
routine_a='b5680000-0000-4000-8000-000000000021'
routine_b='b5680000-0000-4000-8000-000000000022'
routine_c='b5680000-0000-4000-8000-000000000023'
mutation_a='b5680000-0000-4000-8000-000000000101'
mutation_b='b5680000-0000-4000-8000-000000000102'
mutation_c='b5680000-0000-4000-8000-000000000103'

if [[ "${GITHUB_ACTIONS:-}" != true || "$database_url" != "$expected_url" || "$#" -ne 0 ]]; then
  echo 'Refusing atomic default Create race outside disposable GitHub CI Postgres' >&2
  exit 1
fi
for variable in "${!PG@}"; do
  if [[ "$variable" != PGPASSWORD ]]; then
    echo "Refusing libpq connection override: $variable" >&2
    exit 1
  fi
done

psql() { command psql --no-psqlrc "$@"; }
identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select current_database()='postgres' and current_user='postgres'" | tr -d '[:space:]')"
if [[ "$identity" != t ]]; then echo 'Unexpected database identity' >&2; exit 1; fi

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
    echo 'Actor A:'; [[ ! -e "$a_log" ]] || cat "$a_log"
    echo 'Actor B:'; [[ ! -e "$b_log" ]] || cat "$b_log"
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

# Setup user fixture with ZERO programs
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email) values
 ('$owner'::uuid,'atomic-default-race@example.test');
SQL

# ==============================================================================
# RACE 1: Two concurrent first-time creates for the same user with distinct routines
# ==============================================================================
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=routine="$routine_a" \
  --set=mutation="$mutation_a" \
  <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.create_user_workout_routine_in_my_program(
  :'routine'::uuid, 'Race Routine A', :'mutation'::uuid,
  '[{"exercise_ref": "bench_press", "exercise_type": "standard", "sets": [{"position": 0, "reps": 10, "set_type": "regular"}]}]'::jsonb
);
\echo ACTOR_A_CREATED_UNCOMMITTED
SQL

wait_log 'ACTOR_A_CREATED_UNCOMMITTED' "$a_log" "$pid_a"

# Actor B attempts first-create concurrently
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=routine="$routine_b" \
  --set=mutation="$mutation_b" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_568_atomic_default_race_b';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo ACTOR_B_ATTEMPT
select public.create_user_workout_routine_in_my_program(
  :'routine'::uuid, 'Race Routine B', :'mutation'::uuid,
  '[{"exercise_ref": "bench_press", "exercise_type": "standard", "sets": [{"position": 0, "reps": 10, "set_type": "regular"}]}]'::jsonb
);
commit;
\echo ACTOR_B_COMMITTED
SQL
pid_b=$!

wait_log 'ACTOR_B_ATTEMPT' "$b_log" "$pid_b"

blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(select 1 from pg_stat_activity
      where application_name='tnyx_568_atomic_default_race_b'
        and state='active' and wait_event_type='Lock')" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo 'Actor B finished before Actor A committed' >&2
    exit 1
  fi
  sleep 0.1
done

if [[ "$blocked" != 1 ]]; then
  echo 'Actor B did not serialize on Actor A user row lock' >&2
  exit 1
fi

cat >&3 <<'SQL'
commit;
\echo ACTOR_A_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0

wait "$pid_a"
pid_a=''
grep -Fq 'ACTOR_A_COMMITTED' "$a_log"

wait "$pid_b"
pid_b=''
grep -Fq 'ACTOR_B_COMMITTED' "$b_log"

# Assert exact outcomes: exactly 1 default Program, both routines under it
race_check="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select
    (select count(*)=1 from public.user_workout_programs where user_id='$owner'::uuid and is_default=true)
    and (select count(*)=1 from public.user_workout_programs where user_id='$owner'::uuid)
    and (select count(*)=2 from public.user_workout_routines where user_id='$owner'::uuid)
    and (select count(distinct program_id)=1 from public.user_workout_routines where user_id='$owner'::uuid)
  " | tr -d '[:space:]')"

if [[ "$race_check" != t ]]; then
  echo 'Concurrent first-time Create left multiple defaults or split routine ownership' >&2
  exit 1
fi

# ==============================================================================
# RACE 2: Concurrent identical retry race
# ==============================================================================
rm -f "$fifo"
mkfifo "$fifo"
: > "$a_log"; : > "$b_log"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=routine="$routine_c" \
  --set=mutation="$mutation_c" \
  <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.create_user_workout_routine_in_my_program(
  :'routine'::uuid, 'Race Routine C', :'mutation'::uuid,
  '[{"exercise_ref": "bench_press", "exercise_type": "standard", "sets": [{"position": 0, "reps": 10, "set_type": "regular"}]}]'::jsonb
);
\echo ACTOR_A_C_UNCOMMITTED
SQL

wait_log 'ACTOR_A_C_UNCOMMITTED' "$a_log" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=routine="$routine_c" \
  --set=mutation="$mutation_c" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_568_atomic_default_replay_b';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo ACTOR_B_REPLAY_ATTEMPT
select public.create_user_workout_routine_in_my_program(
  :'routine'::uuid, 'Race Routine C', :'mutation'::uuid,
  '[{"exercise_ref": "bench_press", "exercise_type": "standard", "sets": [{"position": 0, "reps": 10, "set_type": "regular"}]}]'::jsonb
);
commit;
\echo ACTOR_B_REPLAY_COMMITTED
SQL
pid_b=$!

wait_log 'ACTOR_B_REPLAY_ATTEMPT' "$b_log" "$pid_b"

blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(select 1 from pg_stat_activity
      where application_name='tnyx_568_atomic_default_replay_b'
        and state='active' and wait_event_type='Lock')" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo 'Replay session finished before primary commit' >&2
    exit 1
  fi
  sleep 0.1
done

if [[ "$blocked" != 1 ]]; then
  echo 'Replay session did not wait on primary transaction lock' >&2
  exit 1
fi

cat >&3 <<'SQL'
commit;
\echo ACTOR_A_C_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0

wait "$pid_a"
pid_a=''
grep -Fq 'ACTOR_A_C_COMMITTED' "$a_log"

wait "$pid_b"
pid_b=''
grep -Fq 'ACTOR_B_REPLAY_COMMITTED' "$b_log"

replay_check="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select
    (select count(*)=3 from public.user_workout_routines where user_id='$owner'::uuid)
    and (select count(*)=1 from public.user_workout_routines where id='$routine_c'::uuid and composition_revision=1)
  " | tr -d '[:space:]')"

if [[ "$replay_check" != t ]]; then
  echo 'Concurrent identical replay failed to resolve idempotently' >&2
  exit 1
fi

echo '#568 W1 atomic default create two-session lock, single winner and idempotent replay passed.'
