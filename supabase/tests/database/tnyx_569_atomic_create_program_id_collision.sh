#!/usr/bin/env bash
set -euo pipefail
# Competing Create+Move RPCs with DIFFERENT Routines and SAME new ProgramId.
# Destructive fixtures only on exact disposable GitHub CI Postgres.
database_url="${DATABASE_URL:-}"
expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
owner='b5691100-0000-4000-8000-000000000001'
source='b5691100-0000-4000-8000-000000000011'
routine_a='b5691100-0000-4000-8000-000000000021'
routine_b='b5691100-0000-4000-8000-000000000022'
new_program='b5691100-0000-4000-8000-000000000031'
mutation_a='b5691100-0000-4000-8000-000000000101'
mutation_b='b5691100-0000-4000-8000-000000000102'
if [[ "${GITHUB_ACTIONS:-}" != true || "$database_url" != "$expected_url" || "$#" -ne 0 ]]; then
 echo 'Refusing Program collision test outside exact disposable database' >&2; exit 1
fi
for variable in "${!PG@}"; do
 if [[ "$variable" != PGPASSWORD ]]; then echo "Refusing PG override: $variable" >&2; exit 1; fi
done
psql() { command psql --no-psqlrc "$@"; }
identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select current_database()='postgres' and current_user='postgres'" | tr -d '[:space:]')"
if [[ "$identity" != t ]]; then echo 'Unexpected connection identity' >&2; exit 1; fi
tmp="$(mktemp -d)"
fifo="$tmp/actor-a"
a_log="$tmp/a.log"
b_log="$tmp/b.log"
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
  --command="delete from auth.users where id='$owner'::uuid" >/dev/null 2>&1 || true
 if [[ "$status" != 0 ]]; then
  echo 'Actor A:'; [[ ! -e "$a_log" ]] || cat "$a_log"
  echo 'Actor B:'; [[ ! -e "$b_log" ]] || cat "$b_log"
 fi
 rm -rf "$tmp"
 exit "$status"
}
trap cleanup EXIT
wait_log() {
 local marker=$1 path=$2 pid=$3
 for _ in $(seq 1 150); do
  if grep -Fq "$marker" "$path" 2>/dev/null; then return 0; fi
  if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
  sleep 0.1
 done
 return 1
}
psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email) values
 ('$owner'::uuid,'atomic-id-race@example.test');
insert into public.user_workout_programs(id,user_id,name)
values ('$source'::uuid,'$owner'::uuid,'Collision Source');
insert into public.user_workout_routines(id,user_id,program_id,name)
values
 ('$routine_a'::uuid,'$owner'::uuid,'$source'::uuid,'First Routine'),
 ('$routine_b'::uuid,'$owner'::uuid,'$source'::uuid,'Second Routine');
SQL
mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=owner="$owner" --set=source="$source" --set=routine="$routine_a" \
 --set=destination="$new_program" --set=mutation="$mutation_a" \
 <"$fifo" >"$a_log" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select public.create_user_workout_program_and_move_routine(
 :'routine'::uuid, :'source'::uuid, :'destination'::uuid,
 'Owner Program A', 0, :'mutation'::uuid
);
\echo COLLISION_A_UNCOMMITTED
SQL
wait_log 'COLLISION_A_UNCOMMITTED' "$a_log" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=owner="$owner" --set=source="$source" --set=routine="$routine_b" \
 --set=destination="$new_program" --set=mutation="$mutation_b" \
 >"$b_log" 2>&1 <<'SQL' &
begin;
set local application_name='tnyx_569_atomic_collision_b';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
\echo COLLISION_B_ATTEMPT
select public.create_user_workout_program_and_move_routine(
 :'routine'::uuid, :'source'::uuid, :'destination'::uuid,
 'Owner Program B', 0, :'mutation'::uuid
);
commit;
SQL
pid_b=$!
wait_log 'COLLISION_B_ATTEMPT' "$b_log" "$pid_b"
blocked=0
for _ in $(seq 1 100); do
 waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select exists(select 1 from pg_stat_activity
    where application_name='tnyx_569_atomic_collision_b'
      and state='active' and wait_event_type='Lock')" | tr -d '[:space:]')"
 if [[ "$waiting" == t ]]; then blocked=1; break; fi
 if ! kill -0 "$pid_b" 2>/dev/null; then
  echo 'Second request did not wait for uncommitted duplicate Program UUID' >&2; exit 1
 fi
 sleep 0.1
done
if [[ "$blocked" != 1 ]]; then echo 'No real duplicate UUID lock observed' >&2; exit 1; fi
cat >&3 <<'SQL'
commit;
\echo COLLISION_A_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=''
grep -Fq 'COLLISION_A_COMMITTED' "$a_log"
if wait "$pid_b"; then echo 'Duplicate ProgramId was incorrectly accepted' >&2; exit 1; fi
pid_b=''
grep -Fq 'routine_create_move_program_conflict' "$b_log"
ok="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
 --command="select
   (select count(*)=2 from public.user_workout_programs where user_id='$owner'::uuid)
   and (select program_id='$new_program'::uuid and composition_revision=1
        from public.user_workout_routines where id='$routine_a'::uuid)
   and (select program_id='$source'::uuid and composition_revision=0
        from public.user_workout_routines where id='$routine_b'::uuid)" \
 | tr -d '[:space:]')"
if [[ "$ok" != t ]]; then echo 'Collision corrupted Program/Routine state' >&2; exit 1; fi
echo '#569 same Program UUID concurrent requests allow one commit and no orphan.'
