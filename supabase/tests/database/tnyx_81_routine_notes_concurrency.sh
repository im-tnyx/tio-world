#!/usr/bin/env bash
set -euo pipefail

# TNYX-81: real two-session Routine Notes quota and transfer races.
# Disposable Supabase CI Postgres ONLY; never run against hosted production.
database_url="${DATABASE_URL:-}"
ci_database_url="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
owner="a8100100-0000-4000-8000-000000000001"
program_id="a8100100-0000-4000-8000-000000000002"
source_routine="a8100100-0000-4000-8000-000000000003"
destination_routine="a8100100-0000-4000-8000-000000000004"
transfer_source_routine="a8100100-0000-4000-8000-000000000005"

if [[ "${GITHUB_ACTIONS:-}" != "true" || "$database_url" != "$ci_database_url" ]]; then
  echo 'Refusing Routine Notes race writes outside the exact disposable CI connection' >&2
  exit 1
fi

for pg_variable in "${!PG@}"; do
  if [[ "$pg_variable" != "PGPASSWORD" ]]; then
    echo "Refusing Routine Notes race with libpq override: $pg_variable" >&2
    exit 1
  fi
done

if [[ "$#" -ne 0 ]]; then
  echo 'Unsupported Routine Notes race harness argument' >&2
  exit 1
fi

psql() { command psql --no-psqlrc "$@"; }

database_identity="$(psql "$database_url" --set=ON_ERROR_STOP=1 \
  --tuples-only --no-align \
  --command="select (current_database() = 'postgres' and current_user = 'postgres')::text" \
  | tr -d '[:space:]')"
if [[ "$database_identity" != "true" ]]; then
  echo 'Refusing Routine Notes race writes: unexpected database identity' >&2
  exit 1
fi

sync_dir="$(mktemp -d)"
pid_a=""
pid_b=""
fifo_a=""
fifo_b=""
log_a=""
log_b=""
writer_a_open=0
writer_b_open=0

cleanup() {
  local code=$?
  trap - EXIT
  if [[ "$writer_a_open" == 1 ]]; then exec 3>&-; fi
  if [[ "$writer_b_open" == 1 ]]; then exec 4>&-; fi
  for pid in "$pid_a" "$pid_b"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  psql "$database_url" --set=ON_ERROR_STOP=1 --quiet \
    --command="delete from auth.users where id='$owner'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$code" != 0 ]]; then
    echo 'Session A:'; [[ ! -e "$log_a" ]] || cat "$log_a"
    echo 'Session B:'; [[ ! -e "$log_b" ]] || cat "$log_b"
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

create_note() {
  local note_id=$1
  local mutation_id=$2
  local routine_id=$3
  local body=$4
  psql "$database_url" --set=ON_ERROR_STOP=1 --quiet <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '$owner', true);
select public.mutate_user_workout_routine_note(
  'create', '$note_id'::uuid, '$routine_id'::uuid, null,
  'pinned_routine', '$body', null, '$mutation_id'::uuid
);
reset role;
commit;
SQL
}

psql "$database_url" --set=ON_ERROR_STOP=1 --quiet <<SQL
insert into auth.users(id,email) values
 ('$owner'::uuid,'routine-notes-race@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$program_id'::uuid,'$owner'::uuid,'Routine Notes Race Program');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$source_routine'::uuid,'$owner'::uuid,'$program_id'::uuid,'Routine Notes Source'),
 ('$destination_routine'::uuid,'$owner'::uuid,'$program_id'::uuid,'Routine Notes Destination'),
 ('$transfer_source_routine'::uuid,'$owner'::uuid,'$program_id'::uuid,'Routine Notes Transfer Source');
SQL

for index in 1 2 3 4; do
  create_note \
    "a8100100-0000-4000-8000-00000000001${index}" \
    "a8100100-0000-4000-8000-00000000011${index}" \
    "$source_routine" \
    "Existing Note $index"
done

fifo_a="$sync_dir/quota-a.in"
fifo_b="$sync_dir/quota-b.in"
log_a="$sync_dir/quota-a.log"
log_b="$sync_dir/quota-b.log"
mkfifo "$fifo_a" "$fifo_b"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source_routine="$source_routine" \
  --set=note_id='a8100100-0000-4000-8000-000000000015' \
  --set=mutation_id='a8100100-0000-4000-8000-000000000115' \
  <"$fifo_a" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo_a"
writer_a_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended(
    :'owner' || ':routine-note-scope:routine:' || :'source_routine', 0
  )
);
select public.mutate_user_workout_routine_note(
  'create', :'note_id'::uuid, :'source_routine'::uuid, null,
  'pinned_routine', 'Concurrent final slot A', null, :'mutation_id'::uuid
);
\echo SESSION_A_FIFTH_NOTE_COMMITTED_IN_TRANSACTION
SQL
wait_log 'SESSION_A_FIFTH_NOTE_COMMITTED_IN_TRANSACTION' "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source_routine="$source_routine" \
  --set=note_id='a8100100-0000-4000-8000-000000000016' \
  --set=mutation_id='a8100100-0000-4000-8000-000000000116' \
  <"$fifo_b" >"$log_b" 2>&1 &
pid_b=$!
exec 4>"$fifo_b"
writer_b_open=1
cat >&4 <<'SQL'
begin;
set local role authenticated;
set local application_name = 'tnyx_81_routine_notes_quota_b';
select set_config('request.jwt.claim.sub', :'owner', true);
select public.mutate_user_workout_routine_note(
  'create', :'note_id'::uuid, :'source_routine'::uuid, null,
  'pinned_routine', 'Concurrent final slot B', null, :'mutation_id'::uuid
);
commit;
SQL

blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(
      select 1 from pg_stat_activity
      where application_name='tnyx_81_routine_notes_quota_b'
        and state='active' and wait_event_type='Lock'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo 'Session B finished without waiting on the canonical scope lock' >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo 'Session B was not observed waiting on Session A scope lock' >&2
  exit 1
fi

cat >&3 <<'SQL'
commit;
\echo SESSION_A_QUOTA_RACE_RELEASED
\quit
SQL
exec 3>&-
writer_a_open=0
wait "$pid_a"
pid_a=""
grep -Fq 'SESSION_A_QUOTA_RACE_RELEASED' "$log_a"
if wait "$pid_b"; then
  echo 'Session B unexpectedly committed a sixth Note' >&2
  exit 1
fi
pid_b=""
grep -Fq 'routine_note_quota_exceeded' "$log_b"

quota_result="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select count(*) = 5
    from public.user_workout_routine_notes
    where user_id='$owner'::uuid and routine_id='$source_routine'::uuid" \
  | tr -d '[:space:]')"
if [[ "$quota_result" != t ]]; then
  echo 'Concurrent create race violated the five-Note scope quota' >&2
  exit 1
fi
echo 'TNYX-81 concurrent final-slot creates serialized at five Notes.'

for index in 1 2 3 4; do
  create_note \
    "a8100100-0000-4000-8000-00000000002${index}" \
    "a8100100-0000-4000-8000-00000000012${index}" \
    "$destination_routine" \
    "Destination Note $index"
done
create_note \
  'a8100100-0000-4000-8000-000000000025' \
  'a8100100-0000-4000-8000-000000000125' \
  "$transfer_source_routine" \
  'Transfer source'

fifo_a="$sync_dir/transfer-a.in"
fifo_b="$sync_dir/transfer-b.in"
log_a="$sync_dir/transfer-a.log"
log_b="$sync_dir/transfer-b.log"
mkfifo "$fifo_a" "$fifo_b"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=destination_routine="$destination_routine" \
  --set=note_id='a8100100-0000-4000-8000-000000000035' \
  --set=mutation_id='a8100100-0000-4000-8000-000000000135' \
  <"$fifo_b" >"$log_b" 2>&1 &
pid_b=$!
exec 4>"$fifo_b"
writer_b_open=1
cat >&4 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'owner', true);
select pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended(
    :'owner' || ':routine-note-scope:routine:' || :'destination_routine', 0
  )
);
select public.mutate_user_workout_routine_note(
  'create', :'note_id'::uuid, :'destination_routine'::uuid, null,
  'pinned_routine', 'Destination winning Note', null, :'mutation_id'::uuid
);
\echo SESSION_B_DESTINATION_SLOT_COMMITTED_IN_TRANSACTION
SQL
wait_log 'SESSION_B_DESTINATION_SLOT_COMMITTED_IN_TRANSACTION' "$log_b" "$pid_b"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=source_routine="$transfer_source_routine" \
  --set=destination_routine="$destination_routine" \
  <"$fifo_a" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo_a"
writer_a_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
set local application_name = 'tnyx_81_routine_notes_transfer_a';
select set_config('request.jwt.claim.sub', :'owner', true);
select public.mutate_user_workout_routine_note(
  'transfer', 'a8100100-0000-4000-8000-000000000025'::uuid,
  :'destination_routine'::uuid, null, 'pinned_routine', null, 0,
  'a8100100-0000-4000-8000-000000000225'::uuid
);
commit;
SQL

blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(
      select 1 from pg_stat_activity
      where application_name='tnyx_81_routine_notes_transfer_a'
        and state='active' and wait_event_type='Lock'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_a" 2>/dev/null; then
    echo 'Transfer finished without waiting on the destination scope lock' >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo 'Transfer was not observed waiting on the full destination scope lock' >&2
  exit 1
fi

cat >&4 <<'SQL'
commit;
\echo SESSION_B_TRANSFER_RACE_RELEASED
\quit
SQL
exec 4>&-
writer_b_open=0
wait "$pid_b"
pid_b=""
grep -Fq 'SESSION_B_TRANSFER_RACE_RELEASED' "$log_b"
if wait "$pid_a"; then
  echo 'Transfer unexpectedly committed into a full destination scope' >&2
  exit 1
fi
pid_a=""
grep -Fq 'routine_note_quota_exceeded' "$log_a"

transfer_result="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select note_type = 'pinned_routine'
    and routine_id='$transfer_source_routine'::uuid
    and body='Transfer source'
    and revision=0
    from public.user_workout_routine_notes
    where id='a8100100-0000-4000-8000-000000000025'::uuid" \
  | tr -d '[:space:]')"
if [[ "$transfer_result" != t ]]; then
  echo 'Losing transfer did not preserve the source Note' >&2
  exit 1
fi
echo 'TNYX-81 full-destination transfer race preserved the source Note.'

fifo_a="$sync_dir/duplicate-a.in"
fifo_b="$sync_dir/duplicate-b.in"
log_a="$sync_dir/duplicate-a.log"
log_b="$sync_dir/duplicate-b.log"
mkfifo "$fifo_a" "$fifo_b"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=routine_id="$transfer_source_routine" \
  --set=note_id='a8100100-0000-4000-8000-000000000036' \
  --set=mutation_id='a8100100-0000-4000-8000-000000000136' \
  <"$fifo_a" >"$log_a" 2>&1 &
pid_a=$!
exec 3>"$fifo_a"
writer_a_open=1
cat >&3 <<'SQL'
begin;
set local role authenticated;
set local application_name = 'tnyx_81_routine_notes_duplicate_a';
select set_config('request.jwt.claim.sub', :'owner', true);
select pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended(
    :'owner' || ':routine-note-mutation:' || :'mutation_id', 0
  )
);
select public.mutate_user_workout_routine_note(
  'create', :'note_id'::uuid, :'routine_id'::uuid, null,
  'pinned_routine', 'Concurrent duplicate', null, :'mutation_id'::uuid
);
\echo SESSION_A_DUPLICATE_RESULT_READY
SQL
wait_log 'SESSION_A_DUPLICATE_RESULT_READY' "$log_a" "$pid_a"

psql "$database_url" --set=ON_ERROR_STOP=1 \
  --set=owner="$owner" --set=routine_id="$transfer_source_routine" \
  --set=note_id='a8100100-0000-4000-8000-000000000036' \
  --set=mutation_id='a8100100-0000-4000-8000-000000000136' \
  <"$fifo_b" >"$log_b" 2>&1 &
pid_b=$!
exec 4>"$fifo_b"
writer_b_open=1
cat >&4 <<'SQL'
begin;
set local role authenticated;
set local application_name = 'tnyx_81_routine_notes_duplicate_b';
select set_config('request.jwt.claim.sub', :'owner', true);
select public.mutate_user_workout_routine_note(
  'create', :'note_id'::uuid, :'routine_id'::uuid, null,
  'pinned_routine', 'Concurrent duplicate', null, :'mutation_id'::uuid
);
commit;
\echo SESSION_B_DUPLICATE_RESULT_RETURNED
\quit
SQL

blocked=0
for _ in $(seq 1 100); do
  waiting="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
    --command="select exists(
      select 1 from pg_stat_activity
      where application_name='tnyx_81_routine_notes_duplicate_b'
        and state='active' and wait_event_type='Lock'
    )" | tr -d '[:space:]')"
  if [[ "$waiting" == t ]]; then blocked=1; break; fi
  if ! kill -0 "$pid_b" 2>/dev/null; then
    echo 'Session B finished without waiting on the mutation receipt lock' >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$blocked" != 1 ]]; then
  echo 'Concurrent duplicate Session B was not observed waiting on the mutation lock' >&2
  exit 1
fi

cat >&3 <<'SQL'
commit;
\echo SESSION_A_DUPLICATE_RACE_RELEASED
\quit
SQL
exec 3>&-
writer_a_open=0
wait "$pid_a"
pid_a=""
grep -Fq 'SESSION_A_DUPLICATE_RACE_RELEASED' "$log_a"
wait "$pid_b"
pid_b=""
writer_b_open=0
grep -Fq 'SESSION_B_DUPLICATE_RESULT_RETURNED' "$log_b"
grep -Fq 'a8100100-0000-4000-8000-000000000036' "$log_a"
grep -Fq 'a8100100-0000-4000-8000-000000000036' "$log_b"

duplicate_note_result="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select count(*) = 1
    and bool_and(last_mutation_id =
      'a8100100-0000-4000-8000-000000000136'::uuid)
    and bool_and(body = 'Concurrent duplicate')
    from public.user_workout_routine_notes
    where id='a8100100-0000-4000-8000-000000000036'::uuid" \
  | tr -d '[:space:]')"
duplicate_receipt_result="$(psql "$database_url" --set=ON_ERROR_STOP=1 -At \
  --command="select count(*) = 1
    and min(result_snapshot->'note'->>'id') =
      'a8100100-0000-4000-8000-000000000036'
    from private.user_workout_routine_note_mutations
    where user_id='$owner'::uuid
      and mutation_id='a8100100-0000-4000-8000-000000000136'::uuid" \
  | tr -d '[:space:]')"
if [[ "$duplicate_note_result" != t || "$duplicate_receipt_result" != t ]]; then
  echo 'Concurrent duplicate requests did not produce one Note and one immutable receipt' >&2
  exit 1
fi
echo 'TNYX-81 concurrent duplicate requests returned one immutable result.'
