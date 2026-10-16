#!/usr/bin/env bash
set -euo pipefail

# These tests exercise only the pre-write guard, never connect to any DB.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
harness="$script_dir/tnyx_526_owner_routine_delete_concurrency.sh"
canonical="postgresql://postgres:postgres@127.0.0.1:54322/postgres"

expect_reject() {
  local label="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "Routine Delete guard unexpectedly accepted $label" >&2
    exit 1
  fi
}

# The one accepted CI connection passes the guard without making a connection.
GITHUB_ACTIONS=true DATABASE_URL="$canonical" bash "$harness" --guard-only

expect_reject "missing CI flag" \
  env GITHUB_ACTIONS=false DATABASE_URL="$canonical" bash "$harness" --guard-only
expect_reject "missing DATABASE_URL" \
  env -u DATABASE_URL GITHUB_ACTIONS=true bash "$harness" --guard-only

# URI authority, userinfo, DB and port are fixed; libpq URI override
# parameters and fragments must be rejected before any fixture writes.
for invalid in \
  'postgresql://postgres:postgres@localhost:54322/postgres' \
  'postgresql://postgres:postgres@localhost.example.com:54322/postgres' \
  'postgresql://localhost@remote.example.com:54322/postgres' \
  'postgresql://postgres:postgres@127.0.0.1:5432/postgres' \
  'postgresql://postgres:postgres@127.0.0.1:54322/other' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres?hostaddr=203.0.113.44' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres?host=remote.example.com' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres#hostaddr=203.0.113.44' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres?service=remote' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable'; do
  expect_reject "unexpected connection URI" \
    env GITHUB_ACTIONS=true DATABASE_URL="$invalid" bash "$harness" --guard-only
done

# libpq environment defaults can supply missing connection parameters even
# when a URL looks local. Keep all PG* variables except CI's PGPASSWORD out.
for override in PGHOSTADDR PGSERVICE PGSERVICEFILE PGHOST PGPORT PGDATABASE PGUSER PGOPTIONS; do
  expect_reject "libpq environment override $override" \
    env "GITHUB_ACTIONS=true" "DATABASE_URL=$canonical" "$override=203.0.113.44" \
      bash "$harness" --guard-only
done

echo "TNYX-526 destructive harness connection guard-only cases passed (no DB access)."
