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

# 11. Security regression test: Sentinel password and connection URL redaction (P2 fix).
# Asserts that alternative URLs with embedded credentials rejected by the guard NEVER
# disclose credentials, URLs, or query parameters in stdout or stderr.
sentinel_password="SUPER_SECRET_DISCLOSURE_PREVENTION_SENTINEL_TOKEN_99999"
synthetic_credentialed_url="postgresql://test_user:${sentinel_password}@remote.example.com:54322/postgres?sslmode=require"

# Test 11A: Local opt-in mode with synthetic credentialed URL
local_output="$(env GITHUB_ACTIONS=false DATABASE_URL="$synthetic_credentialed_url" bash "$harness" --local --guard-only 2>&1 || true)"
if env GITHUB_ACTIONS=false DATABASE_URL="$synthetic_credentialed_url" bash "$harness" --local --guard-only >/dev/null 2>&1; then
  echo "Expected local harness to reject synthetic credentialed URL, but it exited 0" >&2
  exit 1
fi
expected_local_refusal="Refusing W7B-1 concurrency race with non-disposable or alternative DATABASE_URL"
if ! echo "$local_output" | grep -Fq "$expected_local_refusal"; then
  echo "Expected safe generic refusal message missing from local output: $local_output" >&2
  exit 1
fi
if echo "$local_output" | grep -Fq "$sentinel_password"; then
  echo "Security violation: Sentinel password leaked in local error output!" >&2
  exit 1
fi
if echo "$local_output" | grep -Fq "$synthetic_credentialed_url"; then
  echo "Security violation: Full connection URL leaked in local error output!" >&2
  exit 1
fi

# Test 11B: CI mode with synthetic credentialed URL
ci_output="$(env GITHUB_ACTIONS=true DATABASE_URL="$synthetic_credentialed_url" bash "$harness" --guard-only 2>&1 || true)"
if env GITHUB_ACTIONS=true DATABASE_URL="$synthetic_credentialed_url" bash "$harness" --guard-only >/dev/null 2>&1; then
  echo "Expected CI harness to reject synthetic credentialed URL, but it exited 0" >&2
  exit 1
fi
expected_ci_refusal="Refusing W7B-1 concurrency race outside the exact disposable CI connection"
if ! echo "$ci_output" | grep -Fq "$expected_ci_refusal"; then
  echo "Expected safe generic refusal message missing from CI output: $ci_output" >&2
  exit 1
fi
if echo "$ci_output" | grep -Fq "$sentinel_password"; then
  echo "Security violation: Sentinel password leaked in CI error output!" >&2
  exit 1
fi
if echo "$ci_output" | grep -Fq "$synthetic_credentialed_url"; then
  echo "Security violation: Full connection URL leaked in CI error output!" >&2
  exit 1
fi

# Test 11C: Unsupported argument with sensitive payload
sensitive_arg="--url=${synthetic_credentialed_url}"
arg_output="$(env GITHUB_ACTIONS=true DATABASE_URL="$canonical" bash "$harness" "$sensitive_arg" 2>&1 || true)"
if env GITHUB_ACTIONS=true DATABASE_URL="$canonical" bash "$harness" "$sensitive_arg" >/dev/null 2>&1; then
  echo "Expected harness to reject unsupported argument, but it exited 0" >&2
  exit 1
fi
if echo "$arg_output" | grep -Fq "$sentinel_password"; then
  echo "Security violation: Sentinel password leaked in unsupported argument output!" >&2
  exit 1
fi

echo "W7B concurrency harness connection guard-only cases passed (no DB access)."
