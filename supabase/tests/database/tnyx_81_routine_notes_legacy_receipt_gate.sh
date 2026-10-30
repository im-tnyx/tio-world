#!/usr/bin/env bash
set -euo pipefail

# This harness intentionally resets only the disposable local Supabase
# database. It must never be pointed at a hosted or developer-owned database.
: "${DATABASE_URL:?DATABASE_URL must point at the disposable local database}"
: "${TNYX_81_DISPOSABLE_DB:?Set TNYX_81_DISPOSABLE_DB=1 for this destructive local reset harness}"

supabase_cli="${SUPABASE_CLI:-supabase}"
baseline_version="20261029120000"
snapshot_version="20261030065649"
contract_version="20261030074635"
gate_version="20261030081321"
snapshot_migration="supabase/migrations/${snapshot_version}_routine_note_mutation_result_snapshot.sql"
gate_migration="supabase/migrations/${gate_version}_routine_note_legacy_receipt_gate.sql"
repository_migrations_dir="supabase/migrations"
scratch_root=""
migrations_moved=0
failure_log=""
lock_a_log=""
lock_b_log=""
lock_a_pid=""
lock_b_pid=""

restore_migrations_dir() {
  if [[ "$migrations_moved" -ne 1 ]]; then
    return 0
  fi
  if [[ -d "$repository_migrations_dir" ]]; then
    # The disposable reset should leave this directory empty. If it did not,
    # preserve those generated files inside the disposable scratch directory
    # rather than deleting or overwriting repository content.
    if ! rmdir "$repository_migrations_dir"; then
      mv "$repository_migrations_dir" "$scratch_root/reset-generated-migrations"
    fi
  fi
  mv "$scratch_root/repository-migrations" "$repository_migrations_dir"
  migrations_moved=0
}

cleanup() {
  local exit_status=$?
  local cleanup_failed=0
  trap - EXIT
  set +e

  for pid in "$lock_a_pid" "$lock_b_pid"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done

  # Restore the repository migrations directory even when `supabase db reset`
  # fails. This harness never starts Docker/Supabase resources, so it must not
  # stop any developer-owned container or database during cleanup.
  restore_migrations_dir || cleanup_failed=1
  if [[ -n "$scratch_root" && -d "$scratch_root" ]]; then
    rm -rf -- "$scratch_root" || cleanup_failed=1
  fi
  if [[ -n "$failure_log" ]]; then
    rm -f -- "$failure_log" || cleanup_failed=1
  fi
  for log in "$lock_a_log" "$lock_b_log"; do
    if [[ -n "$log" ]]; then
      rm -f -- "$log" || cleanup_failed=1
    fi
  done

  if [[ "$cleanup_failed" -ne 0 ]]; then
    echo 'Legacy gate harness cleanup failed; inspect the disposable scratch state.' >&2
  fi
  exit "$exit_status"
}

trap cleanup EXIT
failure_log="$(mktemp)"

psql_local() {
  command psql --no-psqlrc --set=ON_ERROR_STOP=1 "$@"
}

identity="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select current_database() = 'postgres'
    and current_user = 'postgres'
" | tr -d '[:space:]')"
if [[ "$identity" != "t" ]]; then
  echo 'Refusing to run outside the disposable local Routine Notes database.' >&2
  exit 1
fi

reset_to_empty_local() {
  if [[ "$migrations_moved" -ne 0 ]]; then
    echo 'Migrations directory is already moved for a disposable reset.' >&2
    return 1
  fi
  scratch_root="$(mktemp -d)"
  mv "$repository_migrations_dir" "$scratch_root/repository-migrations"
  migrations_moved=1
  mkdir "$repository_migrations_dir"
  "$supabase_cli" db reset --local --no-seed >/dev/null
  restore_migrations_dir
  rmdir "$scratch_root"
  scratch_root=""
}

reset_to_baseline() {
  local migration
  local version
  local versions=()
  reset_to_empty_local
  for migration in supabase/migrations/*.sql; do
    version="$(basename "$migration")"
    version="${version%%_*}"
    if [[ "$version" > "$baseline_version" ]]; then
      continue
    fi
    psql_local "$DATABASE_URL" --single-transaction --file="$migration" \
      >/dev/null
    versions+=("$version")
  done
  "$supabase_cli" migration repair --local --status applied --yes \
    "${versions[@]}" >/dev/null
}

apply_full_sequence() {
  local migration
  local version
  local versions=()
  for migration in supabase/migrations/*.sql; do
    version="$(basename "$migration")"
    version="${version%%_*}"
    if [[ "$version" < "$baseline_version" || "$version" == "$baseline_version" ]]; then
      continue
    fi
    psql_local "$DATABASE_URL" --single-transaction --file="$migration" >/dev/null
    versions+=("$version")
  done
  "$supabase_cli" migration repair --local --status applied --yes \
    "${versions[@]}" >/dev/null
}

seed_legacy_receipts() {
  psql_local "$DATABASE_URL" <<'SQL'
insert into auth.users (id, email) values
  ('a8110000-0000-4000-8000-000000000001', 'legacy-gate@example.test');

insert into private.user_workout_routine_note_mutations (
  user_id, mutation_id, operation, request_hash, result_kind, note_id,
  result_revision
) values
  (
    'a8110000-0000-4000-8000-000000000001',
    'a8110000-0000-4000-8000-000000000101',
    'delete', repeat('1', 64), 'deleted',
    'a8110000-0000-4000-8000-000000000201', 0
  ),
  (
    'a8110000-0000-4000-8000-000000000001',
    'a8110000-0000-4000-8000-000000000102',
    'delete', repeat('2', 64), 'deleted',
    'a8110000-0000-4000-8000-000000000202', 1
  );
SQL
}

legacy_receipt_state() {
  psql_local "$DATABASE_URL" --tuples-only --no-align --command="
    select string_agg(
      format('%s|%s|%s|%s|%s', mutation_id, operation, request_hash,
        result_kind, note_id),
      ',' order by mutation_id
    )
    from private.user_workout_routine_note_mutations
    where user_id = 'a8110000-0000-4000-8000-000000000001';
  " | tr -d '\r\n'
}

receipt_state() {
  psql_local "$DATABASE_URL" --tuples-only --no-align --command="
    select string_agg(
      format('%s|%s|%s|%s|%s|%s', mutation_id, operation, request_hash,
        result_kind, note_id, coalesce(result_snapshot::text, '<NULL>')),
      ',' order by mutation_id
    )
    from private.user_workout_routine_note_mutations
    where user_id = 'a8110000-0000-4000-8000-000000000001';
  " | tr -d '\r\n'
}

function_definitions() {
  psql_local "$DATABASE_URL" --tuples-only --no-align --command="
    select string_agg(pg_catalog.pg_get_functiondef(p.oid), E'\\n---FUNCTION---\\n'
                      order by p.proname)
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'mutate_user_workout_routine_note',
        'reconcile_user_workout_routine_note_mutation'
      );
  "
}

wait_for_marker() {
  local marker="$1"
  local log="$2"
  local attempt
  for attempt in $(seq 1 100); do
    if grep -Fq "$marker" "$log"; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

# Test B/C: apply the snapshot migration at its actual boundary with two
# legacy receipts. The expected failure must roll back the whole migration,
# including the new column and all function changes.
reset_to_baseline
seed_legacy_receipts
before_state="$(legacy_receipt_state)"
before_functions="$(function_definitions)"

set +e
psql_local "$DATABASE_URL" --set=VERBOSITY=verbose --single-transaction \
  --file="$snapshot_migration" \
  >"$failure_log" 2>&1
failure_status=$?
set -e

if [[ "$failure_status" -eq 0 ]]; then
  echo 'Snapshot migration unexpectedly succeeded with legacy receipts.' >&2
  cat "$failure_log" >&2
  exit 1
fi
grep -Fq 'P0001: routine_note_legacy_receipt_snapshot_required' "$failure_log"
if grep -Eq 'a8110000-0000-4000-8000-00000000010[12]|a8110000-0000-4000-8000-00000000020[12]' "$failure_log"; then
  echo 'Migration error exposed private receipt identifiers.' >&2
  cat "$failure_log" >&2
  exit 1
fi

after_state="$(legacy_receipt_state)"
if [[ "$after_state" != "$before_state" ]]; then
  echo 'Legacy receipts changed after the failed migration.' >&2
  exit 1
fi
after_functions="$(function_definitions)"
if [[ "$after_functions" != "$before_functions" ]]; then
  echo 'Original mutation or reconciliation functions changed after failure.' >&2
  exit 1
fi
column_state="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) = 0
  from information_schema.columns
  where table_schema = 'private'
    and table_name = 'user_workout_routine_note_mutations'
    and column_name = 'result_snapshot';
" | tr -d '[:space:]')"
if [[ "$column_state" != "t" ]]; then
  echo 'Snapshot column survived the failed migration.' >&2
  exit 1
fi
ledger_state="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) = 0 from supabase_migrations.schema_migrations
  where version in ('$snapshot_version', '$contract_version', '$gate_version');
" | tr -d '[:space:]')"
if [[ "$ledger_state" != "t" ]]; then
  echo 'Snapshot or later Notes migration was recorded after failure.' >&2
  exit 1
fi
echo 'Snapshot migration rejected multiple legacy receipts atomically with SQLSTATE P0001.'

# Test D: an in-flight legacy receipt write must finish before the snapshot
# migration can acquire its ACCESS EXCLUSIVE lock. Once the write commits, the
# same migration transaction sees the receipt and fails closed.
reset_to_baseline
lock_a_log="$(mktemp)"
lock_b_log="$(mktemp)"
psql_local "$DATABASE_URL" >"$lock_a_log" 2>&1 <<'SQL' &
begin;
insert into auth.users (id, email) values
  ('a8110000-0000-4000-8000-000000000003', 'lock-gate@example.test');
insert into private.user_workout_routine_note_mutations (
  user_id, mutation_id, operation, request_hash, result_kind, note_id,
  result_revision
) values (
  'a8110000-0000-4000-8000-000000000003',
  'a8110000-0000-4000-8000-000000000301',
  'delete', repeat('4', 64), 'deleted',
  'a8110000-0000-4000-8000-000000000401', 0
);
\echo TNYX_81_LEGACY_RECEIPT_WRITE_OPEN
select pg_catalog.pg_sleep(3);
commit;
SQL
lock_a_pid=$!
wait_for_marker 'TNYX_81_LEGACY_RECEIPT_WRITE_OPEN' "$lock_a_log"

set +e
psql_local "$DATABASE_URL" --set=VERBOSITY=verbose --single-transaction \
  --file="$snapshot_migration" >"$lock_b_log" 2>&1 &
lock_b_pid=$!
set -e
sleep 1
if ! kill -0 "$lock_b_pid" 2>/dev/null; then
  echo 'Snapshot migration did not remain blocked behind the in-flight receipt write.' >&2
  cat "$lock_b_log" >&2
  exit 1
fi
if ! wait "$lock_a_pid"; then
  echo 'In-flight legacy receipt writer failed.' >&2
  cat "$lock_a_log" >&2
  exit 1
fi
lock_a_pid=""
if wait "$lock_b_pid"; then
  echo 'Snapshot migration unexpectedly bypassed the committed legacy receipt.' >&2
  exit 1
fi
lock_b_pid=""
grep -Fq 'P0001: routine_note_legacy_receipt_snapshot_required' "$lock_b_log"
echo 'ACCESS EXCLUSIVE lock blocked the migration until the legacy receipt write committed.'

# Test A/E: a clean full migration sequence applies the snapshot migration and
# subsequent gate, completes the ledger, and keeps normal replay behavior.
reset_to_baseline
apply_full_sequence
expected_ledger_count="$(find supabase/migrations -maxdepth 1 -type f -name '*.sql' | wc -l | tr -d '[:space:]')"
actual_ledger_count="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) from supabase_migrations.schema_migrations;
" | tr -d '[:space:]')"
if [[ "$actual_ledger_count" != "$expected_ledger_count" ]]; then
  echo "Migration ledger count $actual_ledger_count does not match $expected_ledger_count files." >&2
  exit 1
fi
clean_null_state="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) = 0 from private.user_workout_routine_note_mutations
  where result_snapshot is null;
" | tr -d '[:space:]')"
if [[ "$clean_null_state" != "t" ]]; then
  echo 'Clean migration left a NULL result snapshot.' >&2
  exit 1
fi
snapshot_function_state="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) = 2
  from pg_catalog.pg_proc as p
  join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'mutate_user_workout_routine_note',
      'reconcile_user_workout_routine_note_mutation'
    )
    and p.prosecdef;
" | tr -d '[:space:]')"
if [[ "$snapshot_function_state" != "t" ]]; then
  echo 'Final mutation/reconciliation RPCs are not SECURITY DEFINER after clean replay.' >&2
  exit 1
fi
psql_local "$DATABASE_URL" \
  --file=supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql
echo "Clean full migration sequence passed: ${expected_ledger_count} migrations, non-NULL snapshots and replay matrix verified."
