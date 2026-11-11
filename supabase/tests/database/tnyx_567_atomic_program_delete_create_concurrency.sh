#!/usr/bin/env bash
set -euo pipefail
# #567 D1 / PR #678: real two-session Program Delete versus protected
# atomic Routine Create in BOTH orders, plus old-client metadata INSERT.
# No hosted/test-user mutation: exact GitHub Actions disposable DB only.

db="${DATABASE_URL:-}"
expected_db='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='d5673000-0000-4000-8000-000000000001'
default='d5673000-0000-4000-8000-000000000011'
create_first='d5673000-0000-4000-8000-000000000012'
delete_first='d5673000-0000-4000-8000-000000000013'
legacy_source='d5673000-0000-4000-8000-000000000014'
legacy_create_first='d5673000-0000-4000-8000-000000000015'
created_routine='d5673000-0000-4000-8000-000000000021'
denied_routine='d5673000-0000-4000-8000-000000000022'
legacy_routine='d5673000-0000-4000-8000-000000000023'
legacy_create_routine='d5673000-0000-4000-8000-000000000024'
exercise='d5673000-0000-4000-8000-000000000031'
set_id='d5673000-0000-4000-8000-000000000041'
create_mutation='d5673000-0000-4000-8000-000000000101'
denied_mutation='d5673000-0000-4000-8000-000000000102'
delete_mutation='d5673000-0000-4000-8000-000000000103'
signature='public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)'

if [[ "${GITHUB_ACTIONS:-}" != true || "$db" != "$expected_db" || "$#" -ne 0 ]]; then
  echo 'Refusing #567 Create/Delete fixture outside exact disposable GitHub CI DB' >&2
  exit 1
fi
for pg_variable in "${!PG@}"; do
  if [[ "$pg_variable" != PGPASSWORD ]]; then
    echo "Refusing libpq override: $pg_variable" >&2
    exit 1
  fi
done
psql() { command psql --no-psqlrc "$@"; }
identity="$(psql "$db" --set=ON_ERROR_STOP=1 -At --command="
  select current_database()='postgres' and current_user='postgres'
    and (select count(*)=1 from supabase_migrations.schema_migrations
         where version='20261028110000')
    and has_function_privilege('authenticated','$signature','EXECUTE')
" | tr -d '[:space:]')"
if [[ "$identity" != t ]]; then
  echo 'Wrong disposable database, migration ledger or dormant ACL' >&2
  exit 1
fi

scratch="$(mktemp -d)"
fifo="$scratch/actor_a.in"
a_log="$scratch/a.log"
b_log="$scratch/b.log"
pid_a='' pid_b='' writer_open=0 grant_open=0
cleanup() {
  local status=$?
  trap cleanup EXIT
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
    echo '#567 Create/Delete actor A:'; [[ ! -e "$a_log" ]] || cat "$a_log"
    echo '#567 Create/Delete actor B:'; [[ ! -e "$b_log" ]] || cat "$b_log"
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
open_fifo() {
  rm -f "$fifo"
  mkfifo "$fifo"
  : >"$a_log"
  : >"$b_log"
}
finish_a() {
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
}

psql "$db" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users (id,email)
values ('$owner'::uuid,'program-delete-create-race@example.test');
insert into public.user_workout_programs(id,user_id,name,is_default)
values
 ('$default'::uuid,'$owner'::uuid,'My Program',true),
 ('$create_first'::uuid,'$owner'::uuid,'Create wins',false),
 ('$delete_first'::uuid,'$owner'::uuid,'Delete wins',false),
 ('$legacy_source'::uuid,'$owner'::uuid,'Old client source',false),
 ('$legacy_create_first'::uuid,'$owner'::uuid,'Old client wins',false);
SQL
psql "$db" --set=ON_ERROR_STOP=1 -q \
  --command="grant execute on function $signature to authenticated"
grant_open=0

# Race 1: atomic Create holds source Program KEY SHARE before committing.
# Delete confirms an empty snapshot, waits on source FOR UPDATE, and MUST
# reject stale snapshot after the new Routine/Exercise/Set commit.
open_fifo
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$create_first" \
  --set=routine="$created_routine" --set=mutation="$create_mutation" \
  <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"; writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.create_user_workout_routine_with_composition(
  :'routine'::uuid, :'source'::uuid, 'Created while deleting',
  :'mutation'::uuid,
  '[{"id":"d5673000-0000-4000-8000-000000000031","exercise_ref":"ex_squat",
     "sets":[{"id":"d5673000-0000-4000-8000-000000000041","reps":10}]}]'::jsonb
);
\echo CREATE_A_UNCOMMITTED
SQL
wait_log 'CREATE_A_UNCOMMITTED' "$a_log" "$pid_a"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$create_first" \
  --set=mutation="$delete_mutation" >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_delete_after_create';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo DELETE_B_ATTEMPT
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, '{}'::uuid[], :'mutation'::uuid
);
commit;
SQL
pid_b=$!
wait_log 'DELETE_B_ATTEMPT' "$b_log" "$pid_b"
wait_blocked 'tnyx_567_delete_after_create' "$pid_b"
finish_a
if wait "$pid_b"; then
  echo 'Delete with stale empty snapshot succeeded after Create' >&2
  exit 1
fi
pid_b=''
grep -Fq 'program_delete_membership_conflict' "$b_log"
check="$(psql "$db" --set=ON_ERROR_STOP=1 -At --command="
 select exists(select 1 from public.user_workout_programs
     where id='$create_first'::uuid)
   and (select program_id='$create_first'::uuid
     and composition_revision=1 and name='Created while deleting'
     from public.user_workout_routines where id='$created_routine'::uuid)
   and (select routine_id='$created_routine'::uuid
     from public.user_workout_routine_exercises where id='$exercise'::uuid)
   and (select routine_exercise_id='$exercise'::uuid and reps=10
     from public.user_workout_routine_sets where id='$set_id'::uuid)
" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Create winner was lost or its composition children were changed' >&2
  exit 1
fi

# Race 2: Delete takes the source Program FOR UPDATE and commits first.
# Atomic Create must wait at source Program KEY SHARE, then return opaque
# not-found rather than leaving a partially-created Routine or children.
open_fifo
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$delete_first" \
  --set=mutation="$delete_mutation" <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"; writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, '{}'::uuid[], :'mutation'::uuid
);
\echo DELETE_A_UNCOMMITTED
SQL
wait_log 'DELETE_A_UNCOMMITTED' "$a_log" "$pid_a"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$delete_first" \
  --set=routine="$denied_routine" --set=mutation="$denied_mutation" \
  >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_create_after_delete';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo CREATE_B_ATTEMPT
select public.create_user_workout_routine_with_composition(
  :'routine'::uuid, :'source'::uuid, 'Must not exist',
  :'mutation'::uuid,
  '[{"id":"d5673000-0000-4000-8000-000000000032","exercise_ref":"ex_squat",
     "sets":[{"id":"d5673000-0000-4000-8000-000000000042","reps":8}]}]'::jsonb
);
commit;
SQL
pid_b=$!
wait_log 'CREATE_B_ATTEMPT' "$b_log" "$pid_b"
wait_blocked 'tnyx_567_create_after_delete' "$pid_b"
finish_a
if wait "$pid_b"; then
  echo 'Atomic Create unexpectedly succeeded after deleting source Program' >&2
  exit 1
fi
pid_b=''
grep -Fq 'routine_create_program_not_found' "$b_log"
check="$(psql "$db" --set=ON_ERROR_STOP=1 -At --command="
  select not exists(select 1 from public.user_workout_programs
    where id='$delete_first'::uuid)
    and not exists(select 1 from public.user_workout_routines
    where id='$denied_routine'::uuid)
    and not exists(select 1 from public.user_workout_routine_exercises
    where id='d5673000-0000-4000-8000-000000000032'::uuid)
    and not exists(select 1 from public.user_workout_routine_sets
    where id='d5673000-0000-4000-8000-000000000042'::uuid)
" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Delete winner left forbidden new Routine or orphan children' >&2
  exit 1
fi

# Race 3: deployed old clients may INSERT metadata directly (not via RPC).
# With the source deleted first, the FK validation must wait for the
# parent lock and fail, not allow an orphan via the old client path.
open_fifo
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$legacy_source" \
  --set=mutation="$delete_mutation" <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"; writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, '{}'::uuid[], :'mutation'::uuid
);
\echo LEGACY_DELETE_A_UNCOMMITTED
SQL
wait_log 'LEGACY_DELETE_A_UNCOMMITTED' "$a_log" "$pid_a"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$legacy_source" \
  --set=routine="$legacy_routine" >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_legacy_insert_after_delete';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo LEGACY_INSERT_B_ATTEMPT
insert into public.user_workout_routines(id,user_id,program_id,name)
values (:'routine'::uuid, :'owner'::uuid, :'source'::uuid, 'Legacy metadata');
commit;
SQL
pid_b=$!
wait_log 'LEGACY_INSERT_B_ATTEMPT' "$b_log" "$pid_b"
wait_blocked 'tnyx_567_legacy_insert_after_delete' "$pid_b"
finish_a
if wait "$pid_b"; then
  echo 'Legacy metadata insert unexpectedly succeeded after deleting Program' >&2
  exit 1
fi
pid_b=''
grep -Fq 'user_workout_routines_program_owner_fkey' "$b_log"
check="$(psql "$db" --set=ON_ERROR_STOP=1 -At --command="
 select not exists(select 1 from public.user_workout_programs
    where id='$legacy_source'::uuid)
   and not exists(select 1 from public.user_workout_routines
    where id='$legacy_routine'::uuid)
   and (select count(*)=1 from public.user_workout_routines
    where id='$created_routine'::uuid and program_id='$create_first'::uuid)
" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Legacy metadata race caused data loss, orphan or cross-race corruption' >&2
  exit 1
fi

# Race 4: legacy metadata INSERT commits first and holds Program KEY SHARE.
# Stale Delete expecting no children must block, then reject after seeing
# the newly committed metadata Routine. The old client owns only its row.
open_fifo
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$legacy_create_first" \
  --set=routine="$legacy_create_routine" <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"; writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
insert into public.user_workout_routines(id,user_id,program_id,name)
values (:'routine'::uuid, :'owner'::uuid, :'source'::uuid, 'Legacy first');
\echo LEGACY_INSERT_A_UNCOMMITTED
SQL
wait_log 'LEGACY_INSERT_A_UNCOMMITTED' "$a_log" "$pid_a"
psql "$db" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source="$legacy_create_first" \
  --set=mutation="$delete_mutation" >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_567_delete_after_legacy_insert';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo DELETE_B_ATTEMPT
select public.delete_user_workout_program_preserving_routines(
  :'source'::uuid, '{}'::uuid[], :'mutation'::uuid
);
commit;
SQL
pid_b=$!
wait_log 'DELETE_B_ATTEMPT' "$b_log" "$pid_b"
wait_blocked 'tnyx_567_delete_after_legacy_insert' "$pid_b"
finish_a
if wait "$pid_b"; then
  echo 'Stale Delete succeeded after old-client metadata INSERT' >&2
  exit 1
fi
pid_b=''
grep -Fq 'program_delete_membership_conflict' "$b_log"
check="$(psql "$db" --set=ON_ERROR_STOP=1 -At --command="
  select exists(select 1 from public.user_workout_programs
     where id='$legacy_create_first'::uuid)
    and (select program_id='$legacy_create_first'::uuid and name='Legacy first'
     from public.user_workout_routines where id='$legacy_create_routine'::uuid)
    and (select count(*)=1 from public.user_workout_routines
     where id='$created_routine'::uuid and program_id='$create_first'::uuid)
" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo 'Legacy first winner lost Routine or unrelated source data' >&2
  exit 1
fi

echo '#567 direct Create/Delete and legacy INSERT: both orders, no loss or orphan.'
