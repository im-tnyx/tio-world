#!/usr/bin/env bash
set -euo pipefail

# This harness intentionally resets only the disposable local Supabase
# database. It must never be pointed at a hosted or developer-owned database.
: "${DATABASE_URL:?DATABASE_URL must point at the disposable local database}"
: "${TNYX_81_DISPOSABLE_DB:?Set TNYX_81_DISPOSABLE_DB=1 for this destructive local reset harness}"

supabase_cli="${SUPABASE_CLI:-supabase}"
baseline_version="20261030074635"
gate_version="20261030081321"
gate_migration="supabase/migrations/${gate_version}_routine_note_legacy_receipt_gate.sql"
repository_migrations_dir="supabase/migrations"
scratch_root=""
migrations_moved=0
failure_log=""

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
    and to_regclass('supabase_migrations.schema_migrations') is not null
    and to_regclass('private.user_workout_routine_note_mutations') is not null
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

seed_legacy_receipts() {
  psql_local "$DATABASE_URL" <<'SQL'
insert into auth.users (id, email) values
  ('a8110000-0000-4000-8000-000000000001', 'legacy-gate@example.test');

alter table private.user_workout_routine_note_mutations
  disable trigger trg_user_workout_routine_note_receipt_snapshot;

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

alter table private.user_workout_routine_note_mutations
  enable trigger trg_user_workout_routine_note_receipt_snapshot;
SQL
}

seed_valid_receipt() {
  psql_local "$DATABASE_URL" <<'SQL'
insert into auth.users (id, email) values
  ('a8110000-0000-4000-8000-000000000001', 'clean-gate@example.test');

insert into private.user_workout_routine_note_mutations (
  user_id, mutation_id, operation, request_hash, result_kind, note_id,
  result_revision
) values (
  'a8110000-0000-4000-8000-000000000001',
  'a8110000-0000-4000-8000-000000000103',
  'delete', repeat('3', 64), 'deleted',
  'a8110000-0000-4000-8000-000000000203', 2
);
SQL
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

# Test B/C: apply the gate at its exact migration boundary with two legacy
# receipts. The expected failure must roll back the migration transaction.
reset_to_baseline
seed_legacy_receipts
before_state="$(receipt_state)"

set +e
psql_local "$DATABASE_URL" --single-transaction --file="$gate_migration" \
  >"$failure_log" 2>&1
failure_status=$?
set -e

if [[ "$failure_status" -eq 0 ]]; then
  echo 'Legacy receipt migration gate unexpectedly succeeded.' >&2
  cat "$failure_log" >&2
  exit 1
fi
grep -Fq 'routine_note_legacy_receipt_snapshot_required' "$failure_log"
if grep -Eq 'a8110000-0000-4000-8000-00000000010[12]|a8110000-0000-4000-8000-00000000020[12]' "$failure_log"; then
  echo 'Migration error exposed private receipt identifiers.' >&2
  cat "$failure_log" >&2
  exit 1
fi

after_state="$(receipt_state)"
if [[ "$after_state" != "$before_state" ]]; then
  echo 'Legacy receipts changed after the failed migration.' >&2
  exit 1
fi
ledger_state="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) = 0 from supabase_migrations.schema_migrations
  where version = '$gate_version';
" | tr -d '[:space:]')"
if [[ "$ledger_state" != "t" ]]; then
  echo 'Failed migration was incorrectly recorded in the migration ledger.' >&2
  exit 1
fi
echo 'Legacy NULL receipt gate rejected multiple receipts atomically.'

# Test A/D: a clean boundary applies successfully, preserves an existing
# immutable snapshot, records its ledger entry, and keeps normal
# mutation/replay/reconciliation behavior.
reset_to_baseline
seed_valid_receipt
clean_before_state="$(receipt_state)"
psql_local "$DATABASE_URL" --single-transaction --file="$gate_migration"
clean_after_state="$(receipt_state)"
if [[ "$clean_after_state" != "$clean_before_state" ]]; then
  echo 'Clean migration changed an existing immutable receipt.' >&2
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
"$supabase_cli" migration repair --local --status applied --yes "$gate_version" \
  >/dev/null
ledger_state="$(psql_local "$DATABASE_URL" --tuples-only --no-align --command="
  select count(*) = 1 from supabase_migrations.schema_migrations
  where version = '$gate_version';
" | tr -d '[:space:]')"
if [[ "$ledger_state" != "t" ]]; then
  echo 'Clean migration was not recorded exactly once.' >&2
  exit 1
fi
psql_local "$DATABASE_URL" \
  --file=supabase/tests/database/tnyx_81_routine_notes_persistence.test.sql
echo 'Clean migration and Routine Notes replay matrix passed.'
