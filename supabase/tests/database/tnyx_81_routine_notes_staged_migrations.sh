#!/usr/bin/env bash
set -euo pipefail

expected_database_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
if [[ "${GITHUB_ACTIONS:-}" != 'true' || "${DATABASE_URL:-}" != "$expected_database_url" ]]; then
  echo 'Refuse staged Routine Notes qualification outside the exact disposable Database CI database.' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
migration_dir="$repo_root/supabase/migrations"
staging_root="$(mktemp -d)"
all_migrations="$staging_root/all-migrations"
mv "$migration_dir" "$all_migrations"
mkdir "$migration_dir"

restore_migrations() {
  rm -rf "$migration_dir"
  mv "$all_migrations" "$migration_dir"
  rm -rf "$staging_root"
}

trap restore_migrations EXIT

stages=(
  'baseline:20261028110000'
  'pre_notes_gate:20261028120000'
  'first_notes:20261029120000'
  'after_20261030065649:20261030065649'
  'after_20261030074635:20261030074635'
  'after_20261030081321:20261030081321'
  'after_20261031100000:20261031100000'
  'after_20261031110000:20261031110000'
  'after_20261031130000:20261031130000'
  'after_20261031142025:20261031142025'
)

for stage_spec in "${stages[@]}"; do
  stage="${stage_spec%%:*}"
  checkpoint="${stage_spec##*:}"
  echo "==> Routine Notes staged checkpoint: $stage ($checkpoint)"

  # Reset only after removing repository migrations, then replay the selected
  # checkpoint explicitly in one transaction per migration like Database CI.
  rm -rf "$migration_dir"
  mkdir "$migration_dir"
  supabase db reset --local --no-seed

  while IFS= read -r migration; do
    version="$(basename "$migration")"
    version="${version%%_*}"
    if [[ "$version" > "$checkpoint" ]]; then
      continue
    fi
    cp "$migration" "$migration_dir/"
  done < <(find "$all_migrations" -maxdepth 1 -type f -name '*.sql' -print | sort)

  psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 --command="
    create schema if not exists supabase_migrations;
    create table if not exists supabase_migrations.schema_migrations (
      version text primary key,
      name text not null,
      statements text[] not null default '{}'
    );"

  versions=()
  for migration in "$migration_dir"/*.sql; do
    filename="$(basename "$migration")"
    version="${filename%%_*}"
    psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 --single-transaction \
      --file="$migration"
    versions+=("$version")
  done
  supabase migration repair --local --status applied --yes "${versions[@]}"

  psql "$DATABASE_URL" \
    --set=ON_ERROR_STOP=1 \
    --set="stage=$stage" \
    --file="$repo_root/supabase/tests/database/tnyx_81_routine_notes_staged.test.sql"

  TNYX_81_STAGE="$stage" \
    TNYX_81_STAGE_MIGRATION="$checkpoint" \
    python3 "$repo_root/supabase/tests/database/tnyx_81_routine_notes_data_api_gate_smoke.py"
done

echo 'PASS: TNYX-81 atomic staged migration qualification'
