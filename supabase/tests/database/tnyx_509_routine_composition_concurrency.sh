#!/usr/bin/env bash
set -euo pipefail

# GitHub #509: deterministic two-session Routine composition revision race.
# Runs only against CI's disposable local Supabase database.
database_url="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
test_user="a5091000-0000-4000-8000-000000000001"
program_id="a5091000-0000-4000-8000-000000000002"
routine_id="a5091000-0000-4000-8000-000000000003"

sync_dir="$(mktemp -d)"
fifo="$sync_dir/session-a.stdin"
log_a="$sync_dir/session-a.log"
log_b="$sync_dir/session-b.log"
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
  psql "$database_url" --set=ON_ERROR_STOP=1 --quiet \
    --command="delete from auth.users where id='$test_user'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$status" != 0 ]]; then
    echo "Session A log:"; [[ ! -f "$log_a" ]] || cat "$log_a"
    echo "Session B log:"; [[ ! -f "$log_b" ]] || cat "$log_b"
  fi
  rm -rf -- "$sync_dir"
  exit "$status"
}
trap cleanup EXIT

wait_for_log() {
  local expected=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$expected" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "Session exited before $expected"; return 1
    fi
    sleep 0.1
  done
  echo "Timed out awaiting $expected"
  return 1
}

psql "$database_url" --set=ON_ERROR_STOP=1 --quiet <<SQL
insert into auth.users (id, email)
values ('$test_user'::uuid, 'issue509-race@example.test');
insert into public.user_workout_programs (id,user_id,name)
values ('$program_id'::uuid,'$test_user'::uuid,'Race Program');
insert into public.user_workout_routines (id,user_id,program_id,name)
values ('$routine_id'::uuid,'$test_user'::uuid,'$program_id'::uuid,'Race Routine');
SQL

mkfifo "$fifo"
psql "$database_url" --set=ON_ERROR_STOP=1 --set=test_user="$test_user" \
  --set=routine_id="$routine_id" <"$fifo" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo"
writer_open=1

cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
select composition_revision from public.user_workout_routines
where id = :'routine_id'::uuid for update;
\echo SESSION_A_LOCK_HELD
SQL
wait_for_log "SESSION_A_LOCK_HELD" "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" --set=routine_id="$routine_id" \
  >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
\echo SESSION_B_ATTEMPT
select public.save_user_workout_routine_composition(
  :'routine_id'::uuid, 0,
  'a5091000-0000-4000-8000-000000000092'::uuid,
  '[{"id":"a5091000-0000-4000-8000-000000000042",
    "exercise_ref":"ex_squat","sets":[]}]'::jsonb
);
commit;
SQL
pid_b=$!
wait_for_log "SESSION_B_ATTEMPT" "$log_b" "$pid_b"

# Require evidence that B is blocked on A's locked Routine parent.
blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
    --command="select exists (
      select 1 from pg_stat_activity
      where state = 'active' and wait_event_type = 'Lock'
      and query like '%save_user_workout_routine_composition%'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo "B finished before lock observation"; exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo "B never blocked on A Routine row lock"; exit 1
fi

cat >&3 <<'SQL'
select public.save_user_workout_routine_composition(
  :'routine_id'::uuid, 0,
  'a5091000-0000-4000-8000-000000000091'::uuid,
  '[{"id":"a5091000-0000-4000-8000-000000000041",
    "exercise_ref":"ex_squat","sets":[]}]'::jsonb
);
commit;
\echo SESSION_A_COMMITTED
\quit
SQL
exec 3>&-
writer_open=0
wait "$pid_a"
pid_a=""
grep -Fq "SESSION_A_COMMITTED" "$log_a"

if wait "$pid_b"; then
  echo "B unexpectedly committed a stale Routine composition"; exit 1
fi
pid_b=""
grep -Fq "routine_composition_revision_conflict" "$log_b"

final="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select (r.composition_revision=1
    and (select count(*) from public.user_workout_routine_exercises e
         where e.routine_id=r.id)=1
    and exists (select 1 from public.user_workout_routine_exercises e
                where e.routine_id=r.id
                  and e.id='a5091000-0000-4000-8000-000000000041'::uuid)
    and not exists (select 1 from public.user_workout_routine_exercises e
                    where e.id='a5091000-0000-4000-8000-000000000042'::uuid))
  from public.user_workout_routines r
  where r.id='$routine_id'::uuid" | tr -d '[:space:]')"
if [[ "$final" != t ]]; then
  echo "Stale concurrent writer altered the winning Routine composition"
  exit 1
fi

echo "TNYX-509 Routine composition real two-session revision race passed."
