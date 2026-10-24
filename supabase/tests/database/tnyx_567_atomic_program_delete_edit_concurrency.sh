#!/usr/bin/env bash
set -euo pipefail
# GitHub #567 D1 / PR #678 P2: real two-session Program Delete vs protected
# Routine Edit, both commit orders. Exact disposable GitHub CI DB only.
# Unlike Create/Move, protected Edit holds a Routine row, NOT Program KEY SHARE.

db="${DATABASE_URL:-}"
expected_db='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='d5672000-0000-4000-8000-000000000001'
default='d5672000-0000-4000-8000-000000000011'
source_delete_first='d5672000-0000-4000-8000-000000000012'
source_edit_first='d5672000-0000-4000-8000-000000000013'
routine_delete_first='d5672000-0000-4000-8000-000000000021'
routine_edit_first='d5672000-0000-4000-8000-000000000022'
exercise_delete_first='d5672000-0000-4000-8000-000000000031'
exercise_edit_first='d5672000-0000-4000-8000-000000000032'
set_delete_first='d5672000-0000-4000-8000-000000000041'
set_edit_first='d5672000-0000-4000-8000-000000000042'
mutation_delete_1='d5672000-0000-4000-8000-000000000101'
mutation_delete_2='d5672000-0000-4000-8000-000000000102'
mutation_edit_1='d5672000-0000-4000-8000-000000000111'
mutation_edit_2='d5672000-0000-4000-8000-000000000112'
signature='public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)'

if [[ "${GITHUB_ACTIONS:-}" != true || "$db" != "$expected_db" || "$#" -ne 0 ]]; then
  echo 'Refuse #567 Delete/Edit races outside exact disposable GitHub CI database' >&2
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
    and not has_function_privilege('authenticated','$signature','EXECUTE')" \
  | tr -d '[:space:]')"
if [[ "$identity" != t ]]; then
  echo 'Wrong disposable DB identity, migration, or dormant RPC baseline' >&2
  exit 1
fi

scratch="$(mktemp -d)"
fifo="$scratch/a.in"
a_log="$scratch/a.log"
b_log="$scratch/b.log"
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
      --command="revoke execute on function $signature from authenticated" \
      || status=1
  fi
  psql "$db" --set=ON_ERROR_STOP=1 -q \
    --command="delete from auth.users where id='$owner'::uuid" \
    >/dev/null 2>&1 || status=1
  if [[ "$status" -ne 0 ]]; then
    echo '#567 Delete/Edit actor A:'; [[ ! -e "$a_log" ]] || cat "$a_log"
    echo '#567 Delete/Edit actor B:'; [[ ! -e "$b_log" ]] || cat "$b_log"
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
      --command="select exists(select 1 from pg_catalog.pg_stat_activity
        where application_name='$name' and state='active'
          and wait_event_type='Lock')" | tr -d '[:space:]')"
    if [[ "$waiting" == t ]]; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  return 1
}

psql "$db" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email)
values ('$owner'::uuid,'program-delete-edit-race@example.test');
insert into public.user_workout_programs(id,user_id,name,is_default) values
 ('$default'::uuid,'$owner'::uuid,'Renamed My Program',true),
 ('$source_delete_first'::uuid,'$owner'::uuid,'Delete wins',false),
 ('$source_edit_first'::uuid,'$owner'::uuid,'Edit wins',false);
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$routine_delete_first'::uuid,'$owner'::uuid,
  '$source_delete_first'::uuid,'Chest'),
 ('$routine_edit_first'::uuid,'$owner'::uuid,
  '$source_edit_first'::uuid,'Back');
insert into public.user_workout_routine_exercises(
 id,user_id,routine_id,position,catalog_exercise_id
) values
 ('$exercise_delete_first'::uuid,'$owner'::uuid,'$routine_delete_first'::uuid,
  0,'ex_squat'),
 ('$exercise_edit_first'::uuid,'$owner'::uuid,'$routine_edit_first'::uuid,
  0,'ex_squat');
insert into public.user_workout_routine_sets(
 id,user_id,routine_exercise_id,position,reps,load_kg,rest_seconds
) values
 ('$set_delete_first'::uuid,'$owner'::uuid,'$exercise_delete_first'::uuid,
  0,10,30,60),
 ('$set_edit_first'::uuid,'$owner'::uuid,'$exercise_edit_first'::uuid,
  0,8,40,90);
SQL

psql "$db" --set=ON_ERROR_STOP=1 -q \
  --command="grant execute on function $signature to authenticated"
grant_open=1

# RACE 1: Delete transaction moves and locks Routine first; stale protected
# Edit must wait, then reject the old source Program after Delete commits.
mkfifo "$fifo"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source_delete_first" \
  --set=routine="$routine_delete_first" --set=mutation="$mutation_delete_1" \
  <"$fifo" >"$a_log" 2>&1 &
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
\echo DELETE_A_UNCOMMITTED
SQL
wait_log 'DELETE_A_UNCOMMITTED' "$a_log" "$pid_a"

psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source_delete_first" \
  --set=routine="$routine_delete_first" --set=mutation="$mutation_edit_1" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_edit_after_delete';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo EDIT_B_ATTEMPT
select public.update_user_workout_routine_with_composition(
  :'routine'::uuid, :'source'::uuid, 0, 'Chest',
  :'mutation'::uuid, 'Stale Chest', null::jsonb
);
commit;
SQL
pid_b=$!
wait_log 'EDIT_B_ATTEMPT' "$b_log" "$pid_b"
wait_blocked 'tnyx_567_edit_after_delete' "$pid_b"

cat >&3 <<'SQL'
commit;
\echo DELETE_A_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=''
grep -Fq 'DELETE_A_COMMITTED' "$a_log"
if wait "$pid_b"; then
  echo 'Stale Edit unexpectedly succeeded after Program Delete' >&2
  exit 1
fi
pid_b=''
grep -Fq 'routine_update_not_found' "$b_log"

check="$(psql "$db" --set=ON_ERROR_STOP=1 -At \
  --command="select
    not exists(select 1 from public.user_workout_programs
      where id='$source_delete_first'::uuid)
    and (select program_id='$default'::uuid and composition_revision=1
       and name='Chest' and last_composition_mutation_id='$mutation_delete_1'::uuid
       from public.user_workout_routines
       where id='$routine_delete_first'::uuid)
    and (select routine_id='$routine_delete_first'::uuid
       from public.user_workout_routine_exercises
       where id='$exercise_delete_first'::uuid)
    and (select routine_exercise_id='$exercise_delete_first'::uuid
         and reps=10 and load_kg=30
       from public.user_workout_routine_sets
       where id='$set_delete_first'::uuid)" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Delete-first race lost Routine identity, revision, or child rows' >&2
  exit 1
fi

# RACE 2: protected Edit first locks the Routine and bumps revision 0 -> 1.
# Delete can lock the source Program but must wait at the Routine row; after
# Edit commits it must preserve edited Name+children and bump 1 -> 2.
rm -f "$fifo"
mkfifo "$fifo"
: >"$a_log"
: >"$b_log"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source_edit_first" \
  --set=routine="$routine_edit_first" --set=mutation="$mutation_edit_2" \
  <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.update_user_workout_routine_with_composition(
  :'routine'::uuid, :'source'::uuid, 0, 'Back',
  :'mutation'::uuid, 'Edited Back', null::jsonb
);
\echo EDIT_A_UNCOMMITTED
SQL
wait_log 'EDIT_A_UNCOMMITTED' "$a_log" "$pid_a"

psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$source_edit_first" \
  --set=routine="$routine_edit_first" --set=mutation="$mutation_delete_2" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_delete_after_edit';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo DELETE_B_ATTEMPT
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, array[:'routine'::uuid], :'mutation'::uuid
);
commit;
\echo DELETE_B_COMMITTED
SQL
pid_b=$!
wait_log 'DELETE_B_ATTEMPT' "$b_log" "$pid_b"
wait_blocked 'tnyx_567_delete_after_edit' "$pid_b"

cat >&3 <<'SQL'
commit;
\echo EDIT_A_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=''
grep -Fq 'EDIT_A_COMMITTED' "$a_log"
wait "$pid_b"
pid_b=''
grep -Fq 'DELETE_B_COMMITTED' "$b_log"

check="$(psql "$db" --set=ON_ERROR_STOP=1 -At \
  --command="select
    not exists(select 1 from public.user_workout_programs
      where id='$source_edit_first'::uuid)
    and (select program_id='$default'::uuid and composition_revision=2
       and name='Edited Back'
       and last_composition_mutation_id='$mutation_delete_2'::uuid
       and pg_catalog.octet_length(last_routine_update_request_hash)=32
       from public.user_workout_routines
       where id='$routine_edit_first'::uuid)
    and (select routine_id='$routine_edit_first'::uuid
       from public.user_workout_routine_exercises
       where id='$exercise_edit_first'::uuid)
    and (select routine_exercise_id='$exercise_edit_first'::uuid
         and reps=8 and load_kg=40
       from public.user_workout_routine_sets
       where id='$set_edit_first'::uuid)" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Edit-first race lost edited data, revision, or child IDs' >&2
  exit 1
fi

echo '#567 P2: real two-session Delete/Edit in both orders, revisions and children preserved.'
