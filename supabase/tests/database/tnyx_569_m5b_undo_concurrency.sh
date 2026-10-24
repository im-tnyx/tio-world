#!/usr/bin/env bash
set -euo pipefail
# #569 M5B: concurrent identical Undo calls must serialize on the stable
# Routine/Program lock hierarchy and converge on one committed reversal.
database_url="${DATABASE_URL:-}"
expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='b569b200-0000-4000-8000-000000000001'
source='b569b200-0000-4000-8000-000000000011'
routine='b569b200-0000-4000-8000-000000000021'
created='b569b200-0000-4000-8000-000000000031'
move_mutation='b569b200-0000-4000-8000-000000000101'
undo_mutation='b569b200-0000-4000-8000-000000000102'

if [[ "${GITHUB_ACTIONS:-}" != true || "$database_url" != "$expected_url" || "$#" -ne 0 ]]; then
  echo 'Refusing M5B Undo race outside disposable GitHub CI Postgres' >&2
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
    echo 'Undo actor A:'; [[ ! -e "$a_log" ]] || cat "$a_log"
    echo 'Undo actor B:'; [[ ! -e "$b_log" ]] || cat "$b_log"
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
 ('$owner'::uuid,'m5b-undo-race@example.test');
insert into public.user_workout_programs(id,user_id,name,is_default)
values ('$source'::uuid,'$owner'::uuid,'Race Source',true);
insert into public.user_workout_routines(id,user_id,program_id,name)
values ('$routine'::uuid,'$owner'::uuid,'$source'::uuid,'Race Routine');
SQL

psql "$database_url" --set=ON_ERROR_STOP=1 -q \
  --set=owner="$owner" --set=source="$source" --set=routine="$routine" \
  --set=created="$created" --set=move_mutation="$move_mutation" \
  >"$a_log" 2>&1 <<'SQL'
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.create_user_workout_program_and_move_routine(
  :'routine'::uuid, :'source'::uuid, :'created'::uuid,
  'Race Created Program', 0, :'move_mutation'::uuid
);
SQL

mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source" --set=routine="$routine" \
  --set=created="$created" --set=move_mutation="$move_mutation" \
  --set=undo_mutation="$undo_mutation" \
  <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1
cat >&3 <<'SQL'
begin;
set local application_name='tnyx_569_m5b_undo_a';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.undo_create_user_workout_program_and_move_routine(
  :'routine'::uuid, :'source'::uuid, :'created'::uuid,
  :'move_mutation'::uuid, 1, :'undo_mutation'::uuid
);
\echo ACTOR_A_UNDO_UNCOMMITTED
SQL
wait_log 'ACTOR_A_UNDO_UNCOMMITTED' "$a_log" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source" --set=routine="$routine" \
  --set=created="$created" --set=move_mutation="$move_mutation" \
  --set=undo_mutation="$undo_mutation" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_569_m5b_undo_b';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo ACTOR_B_UNDO_ATTEMPT
select public.undo_create_user_workout_program_and_move_routine(
  :'routine'::uuid, :'source'::uuid, :'created'::uuid,
  :'move_mutation'::uuid, 1, :'undo_mutation'::uuid
);
commit;
\echo ACTOR_B_UNDO_COMMITTED
SQL
pid_b=$!
wait_log 'ACTOR_B_UNDO_ATTEMPT' "$b_log" "$pid_b"

blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(select 1 from pg_stat_activity
      where application_name='tnyx_569_m5b_undo_b'
        and state='active' and wait_event_type='Lock')" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo 'Identical Undo finished before first commit, expected lock wait' >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo 'Concurrent identical Undo did not wait on the protected lock hierarchy' >&2
  exit 1
fi

cat >&3 <<'SQL'
commit;
\echo ACTOR_A_UNDO_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=''
grep -Fq 'ACTOR_A_UNDO_COMMITTED' "$a_log"
if ! wait "$pid_b"; then
  echo 'Identical Undo failed after the first Undo committed' >&2
  exit 1
fi
pid_b=''
grep -Fq 'ACTOR_B_UNDO_COMMITTED' "$b_log"

preserved="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select
    not exists(select 1 from public.user_workout_programs where id='$created'::uuid)
    and (select program_id='$source'::uuid and composition_revision=2
           and last_composition_mutation_id='$undo_mutation'::uuid
         from public.user_workout_routines where id='$routine'::uuid)
  " | tr -d '[:space:]')"
if [[ "$preserved" != t ]]; then
  echo 'Concurrent Undo did not converge on one B deletion and one Routine restore' >&2
  exit 1
fi
echo '#569 concurrent identical Undo serialized and replayed safely after B deletion.'
