#!/usr/bin/env bash
set -euo pipefail
# #567 D1: two actual PostgreSQL sessions; atomic Program Delete versus
# concurrent Move. Fixtures and short-lived grant in exact disposable CI ONLY.

db="${DATABASE_URL:-}"
expected_db='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='d5671000-0000-4000-8000-000000000001'
default='d5671000-0000-4000-8000-000000000011'
other='d5671000-0000-4000-8000-000000000012'
source1='d5671000-0000-4000-8000-000000000013'
source2='d5671000-0000-4000-8000-000000000014'
routine1='d5671000-0000-4000-8000-000000000021'
routine2='d5671000-0000-4000-8000-000000000022'
mut_delete='d5671000-0000-4000-8000-000000000101'
mut_move1='d5671000-0000-4000-8000-000000000102'
mut_move2='d5671000-0000-4000-8000-000000000103'
signature='public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)'

if [[ "${GITHUB_ACTIONS:-}" != true || "$db" != "$expected_db" || "$#" -ne 0 ]]; then
  echo 'Refuse #567 Program Delete races outside exact disposable GitHub CI database' >&2
  exit 1
fi
for pg_variable in "${!PG@}"; do
  if [[ "$pg_variable" != PGPASSWORD ]]; then
    echo "Refusing libpq connection override: $pg_variable" >&2
    exit 1
  fi
done
psql() { command psql --no-psqlrc "$@"; }
identity="$(psql "$db" --set=ON_ERROR_STOP=1 -At \
  --command="select current_database()='postgres' and current_user='postgres'
    and (select count(*)=1 from supabase_migrations.schema_migrations
         where version='20261025100000')
    and not has_function_privilege('authenticated','$signature','EXECUTE')" |
    tr -d '[:space:]')"
if [[ "$identity" != t ]]; then
  echo 'Wrong disposable database identity, migration, or staged EXECUTE baseline' >&2
  exit 1
fi

scratch="$(mktemp -d)"
fifo="$scratch/actor_a.in"
log_a="$scratch/a.log"
log_b="$scratch/b.log"
pid_a='' pid_b='' writer_open=0 grant_open=0
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
  if [[ "$grant_open" == 1 ]]; then
    psql "$db" --set=ON_ERROR_STOP=1 -q \
      --command="revoke execute on function $signature from authenticated" ||
      status=1
  fi
  psql "$db" --set=ON_ERROR_STOP=1 -q \
    --command="delete from auth.users where id='$owner'::uuid" \
    >/dev/null 2>&1 || status=1
  if [[ "$status" != 0 ]]; then
    echo '#567 actor A log:'; [[ ! -e "$log_a" ]] || cat "$log_a"
    echo '#567 actor B log:'; [[ ! -e "$log_b" ]] || cat "$log_b"
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
wait_blocked() {
  local name=$1 pid=$2
  for _ in $(seq 1 100); do
    local waiting
    waiting="$(psql "$db" --set=ON_ERROR_STOP=1 -At \
      --command="select exists(select 1 from pg_stat_activity
        where application_name='$name' and state='active'
          and wait_event_type='Lock')" | tr -d '[:space:]')"
    if [[ "$waiting" == t ]]; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  return 1
}

psql "$db" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email) values ('$owner'::uuid,'program-delete-race@example.test');
insert into public.user_workout_programs(id,user_id,name,is_default) values
 ('$default'::uuid,'$owner'::uuid,'Existing My Program',true),
 ('$other'::uuid,'$owner'::uuid,'Other',false),
 ('$source1'::uuid,'$owner'::uuid,'Source first',false),
 ('$source2'::uuid,'$owner'::uuid,'Source second',false);
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$routine1'::uuid,'$owner'::uuid,'$source1'::uuid,'Routine one'),
 ('$routine2'::uuid,'$owner'::uuid,'$source2'::uuid,'Routine two');
SQL

psql "$db" --set=ON_ERROR_STOP=1 -q \
  --command="grant execute on function $signature to authenticated"
grant_open=1

# Race 1: Program Delete starts and holds protected Program locks; Move
# cannot escape the source concurrently and must fail after Delete commits.
mkfifo "$fifo"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source1" --set=routine="$routine1" \
  --set=mutation="$mut_delete" <"$fifo" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, array[:'routine'::uuid], :'mutation'::uuid
);
\echo DELETE_UNCOMMITTED
SQL
wait_log 'DELETE_UNCOMMITTED' "$log_a" "$pid_a"

psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source1" --set=routine="$routine1" \
  --set=destination="$other" --set=mutation="$mut_move1" \
  >"$log_b" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_move_after_delete';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo MOVE_AFTER_DELETE_ATTEMPT
select public.move_user_workout_routine(
  :'routine'::uuid, :'source'::uuid, :'destination'::uuid,
  0, :'mutation'::uuid
);
commit;
SQL
pid_b=$!
wait_log 'MOVE_AFTER_DELETE_ATTEMPT' "$log_b" "$pid_b"
wait_blocked 'tnyx_567_move_after_delete' "$pid_b"

cat >&3 <<'SQL'
commit;
\echo DELETE_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=''
grep -Fq 'DELETE_COMMITTED' "$log_a"
if wait "$pid_b"; then
  echo 'Move unexpectedly succeeded after deleting its source Program' >&2
  exit 1
fi
pid_b=''
grep -Fq 'routine_move_not_found' "$log_b"

check="$(psql "$db" --set=ON_ERROR_STOP=1 -At \
  --command="select
    not exists(select 1 from public.user_workout_programs
       where id='$source1'::uuid)
    and (select program_id='$default'::uuid and composition_revision=1
         from public.user_workout_routines where id='$routine1'::uuid)" |
      tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Delete-winner did not preserve Routine in canonical default' >&2
  exit 1
fi

# Race 2: Move commits first; Delete's stale confirmed membership must not
# remove the now-empty source or the moved Routine after waiting.
rm -f "$fifo"
mkfifo "$fifo"
: >"$log_a"
: >"$log_b"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source2" --set=routine="$routine2" \
  --set=destination="$other" --set=mutation="$mut_move2" \
  <"$fifo" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.move_user_workout_routine(
  :'routine'::uuid, :'source'::uuid, :'destination'::uuid,
  0, :'mutation'::uuid
);
\echo MOVE_UNCOMMITTED
SQL
wait_log 'MOVE_UNCOMMITTED' "$log_a" "$pid_a"

psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source2" --set=routine="$routine2" \
  --set=mutation="$mut_delete" >"$log_b" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_delete_after_move';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo DELETE_AFTER_MOVE_ATTEMPT
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, array[:'routine'::uuid], :'mutation'::uuid
);
commit;
SQL
pid_b=$!
wait_log 'DELETE_AFTER_MOVE_ATTEMPT' "$log_b" "$pid_b"
wait_blocked 'tnyx_567_delete_after_move' "$pid_b"
cat >&3 <<'SQL'
commit;
\echo MOVE_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=''
grep -Fq 'MOVE_COMMITTED' "$log_a"
if wait "$pid_b"; then
  echo 'Stale Delete unexpectedly succeeded after a Move' >&2
  exit 1
fi
pid_b=''
grep -Fq 'program_delete_membership_conflict' "$log_b"

check="$(psql "$db" --set=ON_ERROR_STOP=1 -At \
  --command="select
    exists(select 1 from public.user_workout_programs
      where id='$source2'::uuid)
    and (select program_id='$other'::uuid and composition_revision=1
         from public.user_workout_routines where id='$routine2'::uuid)" |
      tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Move-winner was not preserved after stale Delete denial' >&2
  exit 1
fi

echo '#567 two-session races: Delete-first and Move-first both preserved owner data.'
