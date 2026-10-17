#!/usr/bin/env bash
set -euo pipefail

# #569 M1: real two-session Move vs permanent Delete race.
# DESCTRUCTIVE FIXTURES: exact GitHub Actions disposable Supabase instance ONLY.
database_url="${DATABASE_URL:-}"
expected_url="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
test_user="a5691000-0000-4000-8000-000000000001"
source_id="a5691000-0000-4000-8000-000000000011"
destination_id="a5691000-0000-4000-8000-000000000012"
routine_id="a5691000-0000-4000-8000-000000000021"
mutation_id="a5691000-0000-4000-8000-000000000101"

if [[ "${GITHUB_ACTIONS:-}" != true || "$database_url" != "$expected_url" ]]; then
  echo "Refusing Move fixture writes outside exact disposable GitHub CI database" >&2
  exit 1
fi
for pg_variable in "${!PG@}"; do
  if [[ "$pg_variable" != PGPASSWORD ]]; then
    echo "Refusing libpq override: $pg_variable" >&2
    exit 1
  fi
done
if [[ "$#" -ne 0 ]]; then
  echo "Unsupported Move race test arguments" >&2
  exit 1
fi
psql() { command psql --no-psqlrc "$@"; }
identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select current_database()='postgres' and current_user='postgres'" \
  | tr -d '[:space:]')"
if [[ "$identity" != t ]]; then
  echo "Unexpected disposable DB identity" >&2
  exit 1
fi

work_dir="$(mktemp -d)"
in_a="$work_dir/in_a"
out_a="$work_dir/out_a"
out_b="$work_dir/out_b"
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
  psql "$database_url" --set=ON_ERROR_STOP=1 -q \
    --command="delete from auth.users where id='$test_user'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$status" != 0 ]]; then
    echo "Session A:"; [[ ! -e "$out_a" ]] || cat "$out_a"
    echo "Session B:"; [[ ! -e "$out_b" ]] || cat "$out_b"
  fi
  rm -rf "$work_dir"
  exit "$status"
}
trap cleanup EXIT
wait_log() {
  local needle=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$needle" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  return 1
}

psql "$database_url" --set=ON_ERROR_STOP=1 -q <<SQL
insert into auth.users(id,email) values
 ('$test_user'::uuid,'routine-move-race@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$source_id'::uuid,'$test_user'::uuid,'Move Race Source'),
 ('$destination_id'::uuid,'$test_user'::uuid,'Move Race Destination');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$routine_id'::uuid,'$test_user'::uuid,'Move Race Routine');
SQL

mkfifo "$in_a"
psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=test_user="$test_user" --set=source_id="$source_id" \
 --set=destination_id="$destination_id" --set=routine_id="$routine_id" \
 --set=mutation_id="$mutation_id" <"$in_a" >"$out_a" 2>&1 &
pid_a=$!
exec 3>"$in_a"
writer_open=1

cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
select public.move_user_workout_routine(
  :'routine_id'::uuid, :'source_id'::uuid, :'destination_id'::uuid,
  0, :'mutation_id'::uuid
);
\echo SESSION_A_MOVED_NOT_COMMITTED
SQL
wait_log "SESSION_A_MOVED_NOT_COMMITTED" "$out_a" "$pid_a"

# Delete uses the same UUID advisory lock. It must wait for Move's commit,
# then observe that the expected original Program no longer owns the Routine.
psql "$database_url" --set=ON_ERROR_STOP=1 \
 --set=test_user="$test_user" --set=source_id="$source_id" \
 --set=routine_id="$routine_id" >"$out_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
\echo SESSION_B_DELETE_ATTEMPT
select public.delete_user_workout_routine(
  :'routine_id'::uuid, :'source_id'::uuid, 0
);
commit;
SQL
pid_b=$!
wait_log "SESSION_B_DELETE_ATTEMPT" "$out_b" "$pid_b"
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(select 1 from pg_stat_activity
      where state='active' and wait_event_type='Lock'
        and query like '%delete_user_workout_routine%')" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "Delete unexpectedly completed before Move commit" >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo "Delete was not observed waiting on Move's UUID lock" >&2
  exit 1
fi

cat >&3 <<'SQL'
commit;
\echo SESSION_A_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "SESSION_A_COMMITTED" "$out_a"
if wait "$pid_b"; then
  echo "Stale Delete unexpectedly succeeded" >&2
  exit 1
fi
pid_b=""
grep -Fq "routine_delete_not_found" "$out_b"

# No retired identity, no cascade: both the moved Routine and its destination
# remain reachable. Source Program can now be deleted without touching it.
result="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select program_id='$destination_id'::uuid and composition_revision=1
  from public.user_workout_routines where id='$routine_id'::uuid" \
  | tr -d '[:space:]')"
if [[ "$result" != t ]]; then
  echo "Move winner was not preserved" >&2
  exit 1
fi
tombstones="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select count(*) from private.deleted_user_workout_routine_ids
    where routine_id='$routine_id'::uuid" | tr -d '[:space:]')"
if [[ "$tombstones" != 0 ]]; then
  echo "Stale Delete incorrectly retired moved Routine" >&2
  exit 1
fi
psql "$database_url" --set=ON_ERROR_STOP=1 -q \
  --command="delete from public.user_workout_programs
    where id='$source_id'::uuid"
result="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select program_id='$destination_id'::uuid
    from public.user_workout_routines where id='$routine_id'::uuid" \
  | tr -d '[:space:]')"
if [[ "$result" != t ]]; then
  echo "Source Program deletion cascaded to moved Routine" >&2
  exit 1
fi
echo "#569 Move vs stale Delete two-session lock + Program-delete survival passed."
