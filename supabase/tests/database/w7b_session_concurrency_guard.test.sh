#!/usr/bin/env bash
set -euo pipefail

# These tests exercise only the pre-write connection guard, never connect to any DB.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
harness="$script_dir/w7b_session_concurrency.sh"
canonical="postgresql://postgres:postgres@127.0.0.1:54322/postgres"

expect_reject() {
  local label="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "W7B concurrency guard unexpectedly accepted $label" >&2
    exit 1
  fi
}

# 1. Valid CI invocation passes the guard without DB connection.
GITHUB_ACTIONS=true DATABASE_URL="$canonical" bash "$harness" --guard-only

# 2. Valid local opt-in invocation passes the guard without DB connection (unset DATABASE_URL).
env -u DATABASE_URL GITHUB_ACTIONS=false bash "$harness" --local --guard-only

# 3. Valid local opt-in invocation passes the guard with exact loopback DATABASE_URL.
env GITHUB_ACTIONS=false DATABASE_URL="$canonical" bash "$harness" --local --guard-only

# 4. CI mode: reject missing CI flag when not --local.
expect_reject "missing CI flag without --local" \
  env GITHUB_ACTIONS=false DATABASE_URL="$canonical" bash "$harness" --guard-only

# 5. CI mode: reject missing DATABASE_URL.
expect_reject "missing DATABASE_URL in CI" \
  env -u DATABASE_URL GITHUB_ACTIONS=true bash "$harness" --guard-only

# 6. CI mode: reject unexpected connection URIs, parameters, or overrides.
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
  expect_reject "unexpected CI connection URI ($invalid)" \
    env GITHUB_ACTIONS=true DATABASE_URL="$invalid" bash "$harness" --guard-only
done

# 7. Local mode: reject unexpected or remote connection URIs (P2 security fix).
for invalid_local in \
  'postgresql://postgres:postgres@aws-0-ap-south-1.pooler.supabase.com:6543/postgres' \
  'postgresql://postgres:postgres@db.oykupyiitspujzpwwvuj.supabase.co:5432/postgres' \
  'postgresql://postgres:postgres@localhost:5432/postgres' \
  'postgresql://postgres:postgres@127.0.0.1:5432/postgres' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres?hostaddr=203.0.113.44' \
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable'; do
  expect_reject "unexpected local connection URI ($invalid_local)" \
    env GITHUB_ACTIONS=false DATABASE_URL="$invalid_local" bash "$harness" --local --guard-only
done

# 8. CI mode: reject libpq environment overrides.
for override in PGHOSTADDR PGSERVICE PGSERVICEFILE PGHOST PGPORT PGDATABASE PGUSER PGOPTIONS; do
  expect_reject "CI libpq environment override $override" \
    env GITHUB_ACTIONS=true DATABASE_URL="$canonical" "$override=203.0.113.44" \
      bash "$harness" --guard-only
done

# 9. Local mode: reject libpq environment overrides.
for override in PGHOSTADDR PGSERVICE PGSERVICEFILE PGHOST PGPORT PGDATABASE PGUSER PGOPTIONS; do
  expect_reject "local libpq environment override $override" \
    env GITHUB_ACTIONS=false DATABASE_URL="$canonical" "$override=203.0.113.44" \
      bash "$harness" --local --guard-only
done

# 10. Reject unsupported harness arguments.
expect_reject "unsupported harness argument" \
  env GITHUB_ACTIONS=true DATABASE_URL="$canonical" bash "$harness" --invalid-flag

echo "W7B concurrency harness connection guard-only cases passed (no DB access)."
