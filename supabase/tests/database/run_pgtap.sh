#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# TAP-aware runner for pgTAP database test suites in Tio-World.
#
# Guarantees:
# 1. Fatal SQL errors cause immediate failure with psql exit code (via ON_ERROR_STOP=1 & pipefail).
# 2. Failed assertions ('not ok') cause nonzero exit code (1).
# 3. Plan mismatch or missing plan causes nonzero exit code (1).
# 4. Finish diagnostic failure comments ('# Looks like you failed/planned') cause nonzero exit code (1).
# 5. Only suites where all planned assertions pass exit with code 0.
# ==============================================================================

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <test_file.sql> [psql args...]" >&2
  exit 1
fi

sql_file="$1"
shift

if [[ ! -f "$sql_file" ]]; then
  echo "Test file not found: $sql_file" >&2
  exit 1
fi

db_target=()
if [[ -n "${DATABASE_URL:-}" ]]; then
  db_target=("$DATABASE_URL")
elif [[ -z "${PGHOST:-}" && -z "${PGPORT:-}" ]]; then
  db_target=("postgresql://postgres:postgres@127.0.0.1:54322/postgres")
fi

raw_log="$(mktemp)"
trap 'rm -f "$raw_log"' EXIT

# Run psql with tuples-only and no-align for machine-parseable TAP output.
# set -o pipefail preserves psql failure exit status across tee.
psql ${db_target[@]+"${db_target[@]}"} \
  --set=ON_ERROR_STOP=1 \
  --tuples-only \
  --no-align \
  "$@" \
  --file="$sql_file" 2>&1 | tee "$raw_log"

# 1. Check for explicit pgTAP failure or plan mismatch diagnostics from finish()
if grep -Eq '^# Looks like you (failed|planned)' "$raw_log"; then
  echo "TAP verification failed: pgTAP diagnostic reported failure or plan mismatch" >&2
  exit 1
fi

# 2. Check for any 'not ok' assertion
if grep -Eq '^(not ok|.*\bnot ok\b)' "$raw_log"; then
  echo "TAP verification failed: one or more assertions reported 'not ok'" >&2
  exit 1
fi

# 3. Verify plan was declared and at least one assertion passed
plan_line="$(grep -E '^1\.\.[0-9]+' "$raw_log" | head -n 1 || true)"
if [[ -z "$plan_line" ]]; then
  echo "TAP verification failed: missing TAP plan line (e.g. 1..N)" >&2
  exit 1
fi

planned_count="${plan_line#1..}"
if ! [[ "$planned_count" =~ ^[0-9]+$ ]] || [[ "$planned_count" -le 0 ]]; then
  echo "TAP verification failed: invalid planned assertion count: '$planned_count'" >&2
  exit 1
fi

# 4. Count of passed assertions ('ok <num>') must match plan
passed_count="$(grep -Ec '^ok [0-9]+' "$raw_log" || true)"
if [[ "$passed_count" -ne "$planned_count" ]]; then
  echo "TAP verification failed: assertion count mismatch (planned: $planned_count, passed: $passed_count)" >&2
  exit 1
fi

echo "TAP verification succeeded: $passed_count / $planned_count assertions passed."
