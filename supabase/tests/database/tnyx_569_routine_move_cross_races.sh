#!/usr/bin/env bash
set -euo pipefail

# #569 M1: Edit -> Move, Move -> Edit, Move -> Move, and deleting destination.
# Destructive fixture writes ONLY on exact GitHub CI disposable Postgres.
database_url="${DATABASE_URL:-}"
expected_url="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
test_user="a5692000-0000-4000-8000-000000000001"
source_id="a5692000-0000-4000-8000-000000000011"
destination_b="a5692000-0000-4000-8000-000000000012"
destination_c="a5692000-0000-4000-8000-000000000013"
destination_d="a5692000-0000-4000-8000-000000000014"

if [[ "${GITHUB_ACTIONS:-}" != "true" || "$database_url" != "$expected_url" ]]; then
  echo "Refusing #569 race writes outside exact disposable CI Postgres" >&2
  exit 1
fi
for pg_variable in "${!PG@}"; do
  if [[ "$pg_variable" != "PGPASSWORD" ]]; then
    echo "Refusing #569 race with libpq override: $pg_variable" >&2
    exit 1
  fi
done
if [[ "$#" -ne 0 ]]; then
  echo "Unsupported #569 race fixture arguments" >&2
  exit 1
fi
psql() { command psql --no-psqlrc "$@"; }
db_identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
 --command="select current_database()='postgres' and current_user='postgres'" \
 | tr -d '[:space:]')"
if [[ "$db_identity" != t ]]; then
  echo "Refusing fixtures on unexpected Postgres instance" >&2
  exit 1
fi

scratch="$(mktemp -d)"
pid_a=""
pid_b=""
writer_open=0
log_a="$scratch/a.log"
log_b="$scratch/b.log"

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
    --command="delete from auth.users where id='$test_user'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$status" != 0 ]]; then
    echo "Actor A log:"; [[ ! -e "$log_a" ]] || cat "$log_a"
    echo "Actor B log:"; [[ ! -e "$log_b" ]] || cat "$log_b"
  fi
  rm -rf "$scratch"
  exit "$status"
}
trap cleanup EXIT

wait_marker() {
  local marker=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$marker" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  return 1
}

psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email) values
 ('$test_user'::uuid,'routine-move-cross-races@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$source_id'::uuid,'$test_user'::uuid,'Move Races Source'),
 ('$destination_b'::uuid,'$test_user'::uuid,'Move Races B'),
 ('$destination_c'::uuid,'$test_user'::uuid,'Move Races C'),
 ('$destination_d'::uuid,'$test_user'::uuid,'Move Races Deleting Target');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('a5692000-0000-4000-8000-000000000021'::uuid,'$test_user'::uuid,'$source_id'::uuid,'Routine One'),
 ('a5692000-0000-4000-8000-000000000022'::uuid,'$test_user'::uuid,'$source_id'::uuid,'Routine Two'),
 ('a5692000-0000-4000-8000-000000000023'::uuid,'$test_user'::uuid,'$source_id'::uuid,'Routine Three'),
 ('a5692000-0000-4000-8000-000000000024'::uuid,'$test_user'::uuid,'$source_id'::uuid,'Routine Four');
SQL

# Each actor A leaves a successful mutation uncommitted; actor B must block
# on the same Routine row/UUID or the target Program key-share lock.
# Only after observing a real PostgreSQL lock wait is A committed.
run_race() {
  local label=$1 a_role=$2 a_sql=$3 b_sql=$4 expected_error=$5 check_sql=$6
  local fifo="$scratch/in"
  : > "$log_a"
  : > "$log_b"
  mkfifo "$fifo"

  psql "$database_url" --set=ON_ERROR_STOP=1 <"$fifo" >"$log_a" 2>&1 &
  pid_a=$!
  exec 3>"$fifo"
  writer_open=1
  printf 'begin;\n' >&3
  if [[ "$a_role" == "authenticated" ]]; then
    printf "set local role authenticated;\nselect set_config('request.jwt.claim.sub','%s',true);\n" "$test_user" >&3
  fi
  printf '%s\n' "$a_sql" >&3
  printf '\\echo ACTOR_A_MUTATED_NOT_COMMITTED\n' >&3
  wait_marker 'ACTOR_A_MUTATED_NOT_COMMITTED' "$log_a" "$pid_a"

  {
    printf 'begin;\nset local application_name = '\''tnyx_569_race_b'\'';\n'
    printf "set local role authenticated;\nselect set_config('request.jwt.claim.sub','%s',true);\n" "$test_user"
    printf '\\echo ACTOR_B_ATTEMPT\n'
    printf '%s\ncommit;\n' "$b_sql"
  } | psql "$database_url" --set=ON_ERROR_STOP=1 >"$log_b" 2>&1 &
  pid_b=$!
  wait_marker 'ACTOR_B_ATTEMPT' "$log_b" "$pid_b"
  local blocked=0
  for _ in $(seq 1 100); do
    local wait_state
    wait_state="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
      --command="select exists(select 1 from pg_stat_activity where
        application_name='tnyx_569_race_b' and state='active'
        and wait_event_type='Lock')" | tr -d '[:space:]')"
    if [[ "$wait_state" == t ]]; then blocked=1; break; fi
    if ! kill -0 "$pid_b" 2>/dev/null; then
      echo "$label: B finished without serializing behind A" >&2
      return 1
    fi
    sleep 0.1
  done
  if [[ "$blocked" != 1 ]]; then
    echo "$label: B never observed waiting on PostgreSQL lock" >&2
    return 1
  fi

  printf 'commit;\n\\echo ACTOR_A_COMMITTED\n\\quit\n' >&3
  exec 3>&-
  writer_open=0
  wait "$pid_a"
  pid_a=""
  grep -Fq ACTOR_A_COMMITTED "$log_a"

  if wait "$pid_b"; then
    echo "$label: stale B mutation unexpectedly committed" >&2
    return 1
  fi
  pid_b=""
  if ! grep -Fq "$expected_error" "$log_b"; then
    echo "$label: incorrect SQL failure, expected $expected_error" >&2
    return 1
  fi

  local verified
  verified="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="$check_sql" | tr -d '[:space:]')"
  if [[ "$verified" != t ]]; then
    echo "$label: authoritative persisted result did not match" >&2
    return 1
  fi
  rm "$fifo"
  echo "#569 $label race passed."
}

run_race \
 "Edit-first versus stale Move" authenticated \
 "select public.update_user_workout_routine_with_composition(
    'a5692000-0000-4000-8000-000000000021', '$source_id', 0,
    'Routine One', 'a5692000-0000-4000-8000-000000000101',
    'Edit Wins', null);" \
 "select public.move_user_workout_routine(
    'a5692000-0000-4000-8000-000000000021', '$source_id',
    '$destination_b', 0, 'a5692000-0000-4000-8000-000000000102');" \
 "routine_move_revision_conflict" \
 "select program_id='$source_id'::uuid and composition_revision=1 and name='Edit Wins'
  from public.user_workout_routines
  where id='a5692000-0000-4000-8000-000000000021'::uuid;"

run_race \
 "Move-first versus stale Edit" authenticated \
 "select public.move_user_workout_routine(
    'a5692000-0000-4000-8000-000000000022', '$source_id',
    '$destination_b', 0, 'a5692000-0000-4000-8000-000000000103');" \
 "select public.update_user_workout_routine_with_composition(
    'a5692000-0000-4000-8000-000000000022', '$source_id', 0,
    'Routine Two', 'a5692000-0000-4000-8000-000000000104',
    'Stale Edit', null);" \
 "routine_update_not_found" \
 "select program_id='$destination_b'::uuid and composition_revision=1 and name='Routine Two'
  from public.user_workout_routines
  where id='a5692000-0000-4000-8000-000000000022'::uuid;"

run_race \
 "Move-first versus competing Move" authenticated \
 "select public.move_user_workout_routine(
    'a5692000-0000-4000-8000-000000000023', '$source_id',
    '$destination_b', 0, 'a5692000-0000-4000-8000-000000000105');" \
 "select public.move_user_workout_routine(
    'a5692000-0000-4000-8000-000000000023', '$source_id',
    '$destination_c', 0, 'a5692000-0000-4000-8000-000000000106');" \
 "routine_move_not_found" \
 "select program_id='$destination_b'::uuid and composition_revision=1
  from public.user_workout_routines
  where id='a5692000-0000-4000-8000-000000000023'::uuid;"

# Privileged destination deletion models a future server-side Program-delete
# race without granting direct DELETE to authenticated clients. A removes D
# but does not commit until Move is verifiably blocked on D's KEY SHARE.
run_race \
 "Deleted target cannot accept in-flight Move" postgres \
 "delete from public.user_workout_programs where id='$destination_d'::uuid;" \
 "select public.move_user_workout_routine(
    'a5692000-0000-4000-8000-000000000024', '$source_id',
    '$destination_d', 0, 'a5692000-0000-4000-8000-000000000107');" \
 "routine_move_not_found" \
 "select program_id='$source_id'::uuid and composition_revision=0
  from public.user_workout_routines
  where id='a5692000-0000-4000-8000-000000000024'::uuid;"

echo "#569 M1 four additional deterministic two-session races passed."
