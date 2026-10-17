#!/usr/bin/env bash
set -euo pipefail

# #564 / TNYX-81: deterministic protected Rename versus stale atomic Update race.
# Disposable Supabase CI Postgres ONLY; never run against hosted production.
database_url="${DATABASE_URL:-}"
ci_database_url="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
test_user="a5751000-0000-4000-8000-000000000001"
program_id="a5751000-0000-4000-8000-000000000002"
routine_id="a5751000-0000-4000-8000-000000000003"

if [[ "${GITHUB_ACTIONS:-}" != "true" || "$database_url" != "$ci_database_url" ]]; then
  echo "Refusing Routine Delete fixture writes outside the exact disposable CI connection" >&2
  exit 1
fi

# These environment variables can change libpq's effective connection or
# session behavior. PGPASSWORD is the workflow's only allowed PG* variable.
for pg_variable in "${!PG@}"; do
  if [[ "$pg_variable" != "PGPASSWORD" ]]; then
    echo "Refusing Routine Delete fixture writes with libpq override: $pg_variable" >&2
    exit 1
  fi
done

# The guard-only mode is used by negative tests; absolutely no connection,
# fixture creation, or cleanup occurs in this mode.
if [[ "$#" -eq 1 && "$1" == "--guard-only" ]]; then
  exit 0
fi
if [[ "$#" -ne 0 ]]; then
  echo "Unsupported Routine Delete race harness argument" >&2
  exit 1
fi

# Never read ~/.psqlrc (it can contain \\connect or other unsafe commands).
psql() { command psql --no-psqlrc "$@"; }

# Docker port forwarding means inet_server_addr() may be a bridge address,
# not 127.0.0.1. The exact literal loopback URI and refusal of libpq
# overrides enforce the connection destination; this read-only preflight
# additionally checks the identity of the disposable target before writes.
database_identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 \
  --tuples-only --no-align \
  --command="select (current_database() = 'postgres' and current_user = 'postgres')::text" \
  | tr -d '[:space:]')"
if [[ "$database_identity" != "true" ]]; then
  echo "Refusing Routine Delete fixture writes: unexpected database identity" >&2
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
 ('$test_user'::uuid,'atomic-routine-race@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$program_id'::uuid,'$test_user'::uuid,'Race Program');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$routine_id'::uuid,'$test_user'::uuid,'$program_id'::uuid,'Race Routine');
SQL

mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" --set=program_id="$program_id" --set=routine_id="$routine_id" \
  <"$fifo" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<'SQL'
begin;
-- Only the disposable test administrator acquires FOR UPDATE; the real
-- protected winner RPC below runs as authenticated without direct UPDATE.
select composition_revision from public.user_workout_routines
where id=:'routine_id'::uuid for update;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
\echo SESSION_A_LOCKED
SQL
wait_log "SESSION_A_LOCKED" "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" --set=program_id="$program_id" \
  --set=routine_id="$routine_id" >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
\echo SESSION_B_ATOMIC_ATTEMPT
select public.update_user_workout_routine_with_composition(
  :'routine_id'::uuid, :'program_id'::uuid, 0, 'Race Routine',
  'a5751000-0000-4000-8000-000000000091'::uuid,
  'New Routine', null
);
commit;
SQL
pid_b=$!
wait_log "SESSION_B_ATOMIC_ATTEMPT" "$log_b" "$pid_b"

# Require evidence B is actually waiting on A's locked Routine parent.
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align \
    --set=ON_ERROR_STOP=1 --command="select exists(
      select 1 from pg_stat_activity
      where state='active' and wait_event_type='Lock'
      and query like '%update_user_workout_routine_with_composition%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "Stale Update finished without waiting for protected Rename lock"; exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo "New RPC was never observed waiting on parent lock"; exit 1
fi

cat >&3 <<'SQL'
select public.update_user_workout_routine_with_composition(
  :'routine_id'::uuid, :'program_id'::uuid, 0, 'Race Routine',
  'a5751000-0000-4000-8000-000000000092'::uuid,
  'Protected Wins', null
);
commit;
\echo SESSION_A_PROTECTED_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "SESSION_A_PROTECTED_COMMITTED" "$log_a"

if wait "$pid_b"; then
  echo "New stale Name+Sets RPC incorrectly committed"; exit 1
fi
pid_b=""
grep -Fq "routine_update_revision_conflict" "$log_b"

result="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select name='Protected Wins'
    and composition_revision=1
    and last_composition_mutation_id='a5751000-0000-4000-8000-000000000092'
    and pg_catalog.octet_length(last_routine_update_request_hash)=32
  from public.user_workout_routines where id='$routine_id'::uuid" \
  | tr -d '[:space:]')"
if [[ "$result" != t ]]; then
  echo "The stale Update changed the protected Rename winner"; exit 1
fi
echo "TNYX-81 protected Rename/stale Update two-session parent-lock race passed."
