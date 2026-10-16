#!/usr/bin/env bash
set -euo pipefail

# #526: deterministic old Data API Rename vs new protected Delete RPC race.
# Disposable Supabase CI Postgres ONLY; never run against hosted production.
database_url="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
test_user="d5261000-0000-4000-8000-000000000001"
program_id="d5261000-0000-4000-8000-000000000002"
routine_id="d5261000-0000-4000-8000-000000000003"

# Fail closed if mistakenly pointed at a hosted database.
# Parse the actual URI host, not substrings in userinfo, query or names
# such as localhost.example.com. Also restrict this fixture-destructive race
# harness to its disposable GitHub CI environment; no hosted DB writes.
if [[ "${GITHUB_ACTIONS:-}" != "true" ]] || ! python3 - "$database_url" <<'PY'
import ipaddress
import sys
from urllib.parse import urlsplit

try:
    parsed = urlsplit(sys.argv[1])
    host = parsed.hostname
    if parsed.scheme not in ("postgres", "postgresql") or not host:
        raise ValueError("not a PostgreSQL URI")
    try:
        allowed = ipaddress.ip_address(host).is_loopback
    except ValueError:
        allowed = host == "localhost"
except (ValueError, AttributeError):
    allowed = False

sys.exit(0 if allowed else 1)
PY
then
  echo "Refusing Routine Delete fixture writes outside disposable loopback CI" >&2
  exit 1
fi

sync_dir="$(mktemp -d)"
fifo="$sync_dir/a.in"
log_a="$sync_dir/a.log"
log_b="$sync_dir/b.log"
pid_a=""
pid_b=""
writer_open=0

cleanup() {
  local code=$?
  trap - EXIT
  if [[ "$writer_open" == 1 ]]; then exec 3>&-; fi
  for id in "$pid_a" "$pid_b"; do
    if [[ -n "$id" ]] && kill -0 "$id" 2>/dev/null; then
      kill "$id" 2>/dev/null || true
      wait "$id" 2>/dev/null || true
    fi
  done
  psql "$database_url" --set=ON_ERROR_STOP=1 --quiet \
    --command="delete from auth.users where id='$test_user'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$code" != 0 ]]; then
    echo "Session A:"; [[ ! -e "$log_a" ]] || cat "$log_a"
    echo "Session B:"; [[ ! -e "$log_b" ]] || cat "$log_b"
  fi
  rm -rf "$sync_dir"
  exit "$code"
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

psql "$database_url" --set=ON_ERROR_STOP=1 --quiet <<SQL
insert into auth.users(id,email) values
 ('$test_user'::uuid,'delete-routine-race@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$program_id'::uuid,'$test_user'::uuid,'Race Program');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$routine_id'::uuid,'$test_user'::uuid,'$program_id'::uuid,'Race Routine');
SQL

mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" --set=routine_id="$routine_id" \
  <"$fifo" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
select composition_revision from public.user_workout_routines
where id=:'routine_id'::uuid for update;
\echo SESSION_A_LOCKED
SQL
wait_log "SESSION_A_LOCKED" "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" --set=program_id="$program_id" \
  --set=routine_id="$routine_id" >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
\echo SESSION_B_DELETE_ATTEMPT
select public.delete_user_workout_routine(
  :'routine_id'::uuid, :'program_id'::uuid, 0
);
commit;
SQL
pid_b=$!
wait_log "SESSION_B_DELETE_ATTEMPT" "$log_b" "$pid_b"

# Require evidence B is actually waiting on A's locked Routine parent.
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align \
    --set=ON_ERROR_STOP=1 --command="select exists(
      select 1 from pg_stat_activity
      where state='active' and wait_event_type='Lock'
      and query like '%delete_user_workout_routine%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "Delete finished without waiting for old Rename lock"; exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo "Delete was never observed waiting on parent lock"; exit 1
fi

cat >&3 <<'SQL'
update public.user_workout_routines
set name='Legacy Wins'
where id=:'routine_id'::uuid;
commit;
\echo SESSION_A_LEGACY_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "SESSION_A_LEGACY_COMMITTED" "$log_a"

if wait "$pid_b"; then
  echo "Stale Routine Delete incorrectly committed"; exit 1
fi
pid_b=""
grep -Fq "routine_delete_revision_conflict" "$log_b"

result="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select name='Legacy Wins'
    and composition_revision=1
    and last_composition_mutation_id is null
    and last_routine_update_request_hash is null
  from public.user_workout_routines where id='$routine_id'::uuid" \
  | tr -d '[:space:]')"
if [[ "$result" != t ]]; then
  echo "The stale Delete changed the legacy Rename winner"; exit 1
fi
echo "TNYX-526 old Rename/new Delete two-session parent-lock CAS race passed."
