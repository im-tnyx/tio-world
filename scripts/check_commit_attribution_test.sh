#!/usr/bin/env bash
# Fixture-based regression tests for check_commit_attribution.sh.
#
# Builds a disposable temporary Git repository, creates one commit per
# fixture on top of a shared base commit, and asserts the checker's exit
# code matches the expected outcome. Also covers the 4-argument
# exception/error-path contract (owner exception, and fail-closed technical
# errors that the exception must never bypass). Does not depend on network
# access, GitHub Actions, or this repository's own history.
#
# Usage: check_commit_attribution_test.sh

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checker="$script_dir/check_commit_attribution.sh"

if [ ! -f "$checker" ]; then
  echo "check_commit_attribution_test: error: checker script not found at ${checker}" >&2
  exit 2
fi

workdir="$(mktemp -d)"
cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

repo="$workdir/repo"
git init -q -b main "$repo"
(
  cd "$repo"
  git config user.name "Test Runner"
  git config user.email "test-runner@example.invalid"
  git config commit.gpgsign false
)

base_sha="$(cd "$repo" && git commit --allow-empty -q -m "chore: base commit" && git rev-parse HEAD)"

pass_count=0
fail_count=0

expected_rc_for() {
  case "$1" in
    pass) echo 0 ;;
    fail) echo 1 ;;
    error) echo 2 ;;
    *) echo "unknown expectation: $1" >&2; exit 2 ;;
  esac
}

report() {
  local expect="$1" expected_rc="$2" rc="$3" desc="$4" output="$5"
  if [ "$rc" -eq "$expected_rc" ]; then
    echo "PASS  [${expect}] ${desc}"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL  [expected ${expect} -> rc=${expected_rc}, got rc=${rc}] ${desc}"
    echo "${output}" | sed 's/^/    /'
    fail_count=$((fail_count + 1))
  fi
}

# Two-argument identity fixtures: no PR/exception context.
run_case() {
  local expect="$1" desc="$2" message="$3"
  local expected_rc
  expected_rc="$(expected_rc_for "$expect")"

  (cd "$repo" && git reset -q --hard "$base_sha")
  (cd "$repo" && git commit --allow-empty -q -m "$message")
  local head_sha
  head_sha="$(cd "$repo" && git rev-parse HEAD)"

  local output rc=0
  output="$(cd "$repo" && bash "$checker" "$base_sha" "$head_sha" 2>&1)" || rc=$?

  report "$expect" "$expected_rc" "$rc" "$desc" "$output"
}

# Four-argument exception-aware fixtures.
run_case_ex() {
  local expect="$1" desc="$2" message="$3" pr_number="$4" exception_pr="$5"
  local expected_rc
  expected_rc="$(expected_rc_for "$expect")"

  (cd "$repo" && git reset -q --hard "$base_sha")
  (cd "$repo" && git commit --allow-empty -q -m "$message")
  local head_sha
  head_sha="$(cd "$repo" && git rev-parse HEAD)"

  local output rc=0
  output="$(cd "$repo" && bash "$checker" "$base_sha" "$head_sha" "$pr_number" "$exception_pr" 2>&1)" || rc=$?

  report "$expect" "$expected_rc" "$rc" "$desc" "$output"
}

# Invalid-ref / technical-failure fixtures: must return rc=2 even when a
# matching exception is supplied.
run_invalid_ref_case() {
  local desc="$1" base_arg="$2" head_arg="$3" pr_number="$4" exception_pr="$5"
  local expected_rc=2

  local output rc=0
  output="$(cd "$repo" && bash "$checker" "$base_arg" "$head_arg" "$pr_number" "$exception_pr" 2>&1)" || rc=$?

  report "error" "$expected_rc" "$rc" "$desc" "$output"
}

# --- PASS: no trailer at all ---
run_case pass "no Co-Authored-By trailer" \
  "$(printf 'feat: add widget\n\nRegular commit body with no trailer at all.')"

# --- FAIL: any Co-authored-by trailer, including a human ---
run_case fail "single human co-author trailer" \
  "$(printf 'feat: add widget\n\nBody text.\n\nCo-Authored-By: Jane Developer <jane@example.com>')"

# --- FAIL: multiple Co-authored-by trailers ---
run_case fail "multiple human co-author trailers" \
  "$(printf 'feat: add widget\n\nBody text.\n\nCo-Authored-By: Jane Developer <jane@example.com>\nCo-Authored-By: John Smith <john@example.com>')"

# --- FAIL: human named Claude still cannot appear as a Co-authored-by trailer ---
run_case fail "human named Claude as a Co-authored-by trailer" \
  "$(printf 'fix: correct off-by-one\n\nBody text.\n\nCo-Authored-By: Claude Dupont <claude.dupont@example.com>')"

# --- PASS: ordinary prose mentioning AI vendor names outside a trailer ---
run_case pass "prose mentions Claude/OpenAI outside any trailer" \
  "$(printf 'docs: mention Claude and OpenAI\n\nThis commit updates docs that mention Claude and OpenAI in prose, not as a trailer.')"

# --- FAIL: the actual PR #282 regression identity ---
run_case fail "Claude with anthropic.com email" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"

# --- FAIL: lower-case trailer key + Claude Sonnet display name ---
run_case fail "case-variant trailer key with Claude Sonnet identity" \
  "$(printf 'feat: x\n\nBody.\n\nco-authored-by: Claude Sonnet <sonnet@anthropic.com>')"

# --- FAIL: Anthropic display name ---
run_case fail "Anthropic display identity" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Anthropic <bot@anthropic.com>')"

# --- FAIL: Codex identity ---
run_case fail "Codex identity" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Codex <codex@openai.com>')"

# --- FAIL: OpenAI identity ---
run_case fail "OpenAI identity" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: OpenAI <bot@openai.com>')"

# --- FAIL: OpenAI Codex identity ---
run_case fail "OpenAI Codex identity" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: OpenAI Codex <codex@openai.com>')"

# --- FAIL: AI trailer mixed among otherwise-normal human co-authors ---
run_case fail "AI trailer mixed among human co-authors" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Jane Developer <jane@example.com>\nCo-Authored-By: Claude <noreply@anthropic.com>')"

# --- FAIL: Cursor agent trailer (common Cursor IDE auto-attribution) ---
run_case fail "Cursor with cursoragent.com email" \
  "$(printf 'feat: x\n\nBody.\n\nCo-authored-by: Cursor <cursoragent@cursor.com>')"

# --- FAIL: Cursor display name with cursor.com email ---
run_case fail "Cursor with cursor.com email" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Cursor <agent@cursor.com>')"

# --- FAIL: the PR #742 identity, any case of the trailer key ---
run_case fail "Cursor Agent co-author trailer" \
  "$(printf 'feat: x\n\nBody.\n\nCo-authored-by: Cursor Agent <cursoragent@cursor.com>')"

run_identity_case() {
  local expect="$1" desc="$2" author_name="$3" author_email="$4" committer_name="$5" committer_email="$6" message="$7"
  local expected_rc
  expected_rc="$(expected_rc_for "$expect")"

  (cd "$repo" && git reset -q --hard "$base_sha")
  (
    cd "$repo"
    GIT_AUTHOR_NAME="$author_name" \
    GIT_AUTHOR_EMAIL="$author_email" \
    GIT_COMMITTER_NAME="$committer_name" \
    GIT_COMMITTER_EMAIL="$committer_email" \
      git commit --allow-empty -q -m "$message"
  )
  local head_sha
  head_sha="$(cd "$repo" && git rev-parse HEAD)"

  local output rc=0
  output="$(cd "$repo" && bash "$checker" "$base_sha" "$head_sha" 2>&1)" || rc=$?

  report "$expect" "$expected_rc" "$rc" "$desc" "$output"
}

# --- PASS: human author whose name resembles a provider, no trailer ---
run_identity_case pass "human author named Claude Dupont, no trailer" \
  "Claude Dupont" "claude.dupont@example.com" \
  "Claude Dupont" "claude.dupont@example.com" \
  "$(printf 'fix: correct off-by-one\n\nNo trailer.')"

# --- FAIL: Cursor Agent author, clean message ---
run_identity_case fail "Cursor Agent author with cursoragent email" \
  "Cursor Agent" "cursoragent@cursor.com" \
  "Test Runner" "test-runner@example.invalid" \
  "$(printf 'feat: clean message\n\nNo trailer.')"

# --- FAIL: Cursor Agent committer, clean message ---
run_identity_case fail "Cursor Agent committer with cursoragent email" \
  "Test Runner" "test-runner@example.invalid" \
  "Cursor Agent" "cursoragent@cursor.com" \
  "$(printf 'feat: clean message\n\nNo trailer.')"

# --- FAIL: an earlier commit in the range, not only HEAD ---
(
  cd "$repo"
  git reset -q --hard "$base_sha"
  git commit --allow-empty -q -m "$(printf 'feat: bad\n\nCo-authored-by: Cursor Agent <cursoragent@cursor.com>')"
  git commit --allow-empty -q -m "$(printf 'feat: later clean commit\n\nNo trailer.')"
)
range_head="$(cd "$repo" && git rev-parse HEAD)"
range_output=""
range_rc=0
range_output="$(cd "$repo" && bash "$checker" "$base_sha" "$range_head" 2>&1)" || range_rc=$?
report fail 1 "$range_rc" "earlier commit in base..head still fails when HEAD is clean" "$range_output"

# --- Exception-contract fixtures (4-argument form) ---

# clean range + no exception -> PASS
run_case_ex pass "clean range, no exception set" \
  "$(printf 'chore: x\n\nNo trailer here.')" "42" ""

# violation + no exception -> FAIL rc=1
run_case_ex fail "violation, no exception set" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Claude <noreply@anthropic.com>')" "42" ""

# violation + different PR exception -> FAIL rc=1
run_case_ex fail "violation, exception set for a different PR" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Claude <noreply@anthropic.com>')" "42" "43"

# violation + exact matching PR exception -> PASS rc=0
run_case_ex pass "violation, exact matching PR exception" \
  "$(printf 'feat: x\n\nBody.\n\nCo-Authored-By: Claude <noreply@anthropic.com>')" "42" "42"

# --- Fail-closed technical-failure fixtures: exception must NEVER apply ---

# invalid base ref + exact matching exception -> FAIL rc=2, not bypassed
run_invalid_ref_case "invalid base ref with matching exception must still fail closed (rc=2)" \
  "not-a-real-ref" "$base_sha" "42" "42"

# invalid head ref + exact matching exception -> FAIL rc=2, not bypassed
run_invalid_ref_case "invalid head ref with matching exception must still fail closed (rc=2)" \
  "$base_sha" "0000000000000000000000000000000000dead" "42" "42"

echo
echo "check_commit_attribution_test: ${pass_count} passed, ${fail_count} failed"

if [ "$fail_count" -ne 0 ]; then
  exit 1
fi

exit 0
