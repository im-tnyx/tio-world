#!/usr/bin/env bash
set -euo pipefail
# #569: two sessions try Create+Move the same Routine to distinct new Programs.
# Restrict fixture writes to exact disposable CI database.
database_url="${DATABASE_URL:-}"
expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='b5691000-0000-4000-8000-000000000001'
source='b5691000-0000-4000-8000-000000000011'
routine='b5691000-0000-4000-8000-000000000021'
program_a='b5691000-0000-4000-8000-000000000031'
program_b='b5691000-0000-4000-8000-000000000032'
mutation_a='b5691000-0000-4000-8000-000000000101'
mutation_b='b5691000-0000-4000-8000-000000000102'
if [[ "${GITHUB_ACTIONS:-}" != true || "$database_url" != "$expected_url" || "$#" -ne 0 ]]; then
  echo 'Refusing atomic Move race outside disposable GitHub CI Postgres' >&2
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
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email) values
 ('$owner'::uuid,'atomic-newmove-race@example.test');
insert into public.user_workout_programs(id,user_id,name)
values ('$source'::uuid,'$owner'::uuid,'Race Source');
insert into public.user_workout_routines(id,user_id,program_id,name)
values ('$routine'::uuid,'$owner'::uuid,'$source'::uuid,'Race Routine');
SQL
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source" --set=routine="$routine" \
  --set=new_id="$program_a" --set=mutation="$mutation_a" \
  <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.create_user_workout_program_and_move_routine(
  :'routine'::uuid, :'source'::uuid, :'new_id'::uuid,
  'Race Program A', 0, :'mutation'::uuid
);
\echo ACTOR_A_CREATED_MOVED_UNCOMMITTED
SQL
wait_log 'ACTOR_A_CREATED_MOVED_UNCOMMITTED' "$a_log" "$pid_a"
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source" --set=routine="$routine" \
  --set=new_id="$program_b" --set=mutation="$mutation_b" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_569_atomic_race_b';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo ACTOR_B_CREATE_MOVE_ATTEMPT
select public.create_user_workout_program_and_move_routine(
  :'routine'::uuid, :'source'::uuid, :'new_id'::uuid,
  'Race Program B', 0, :'mutation'::uuid
);
commit;
SQL
pid_b=$!
wait_log 'ACTOR_B_CREATE_MOVE_ATTEMPT' "$b_log" "$pid_b"
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(select 1 from pg_stat_activity
      where application_name='tnyx_569_atomic_race_b'
        and state='active' and wait_event_type='Lock')" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo 'Losing Create+Move finished before first commit' >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo 'Second Create+Move did not wait on first Routine lock' >&2
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
if wait "$pid_b"; then
  echo 'Second stale Create+Move incorrectly succeeded' >&2
  exit 1
fi
pid_b=''
grep -Fq 'routine_create_move_not_found' "$b_log"
preserved="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select
    (select count(*)=2 from public.user_workout_programs where user_id='$owner'::uuid)
    and (select count(*)=0 from public.user_workout_programs where id='$program_b'::uuid)
    and (select program_id='$program_a'::uuid and composition_revision=1
         from public.user_workout_routines where id='$routine'::uuid)
  " | tr -d '[:space:]')"
if [[ "$preserved" != t ]]; then
  echo 'Concurrent Create+Move left an orphan or wrong Routine ownership' >&2
  exit 1
fi
echo '#569 Create+Move two-session lock, single winner and zero-orphan passed.'
