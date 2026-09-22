#!/usr/bin/env bash
# Fixture-based regression tests for check_commit_attribution.sh.
#
# Builds a disposable temporary Git repository, creates one commit per
# fixture on top of a shared base commit, and asserts the checker's exit
# code matches the expected PASS/FAIL outcome. Does not depend on network
# access, GitHub Actions, or this repository's own history.
#
# Usage: check_commit_attribution_test.sh

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checker="$script_dir/check_commit_attribution.sh"

if [ ! -x "$checker" ] && [ ! -f "$checker" ]; then
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

run_case() {
  local expect="$1" desc="$2" message="$3"
  local expected_rc=0
  [ "$expect" = "fail" ] && expected_rc=1

  (cd "$repo" && git reset -q --hard "$base_sha")
  (cd "$repo" && git commit --allow-empty -q -m "$message")
  local head_sha
  head_sha="$(cd "$repo" && git rev-parse HEAD)"

  local output rc=0
  output="$(cd "$repo" && bash "$checker" "$base_sha" "$head_sha" 2>&1)" || rc=$?

  if [ "$rc" -eq "$expected_rc" ]; then
    echo "PASS  [${expect}] ${desc}"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL  [expected ${expect} -> rc=${expected_rc}, got rc=${rc}] ${desc}"
    echo "${output}" | sed 's/^/    /'
    fail_count=$((fail_count + 1))
  fi
}

# --- PASS: no trailer at all ---
run_case pass "no Co-Authored-By trailer" \
  "$(printf 'feat: add widget\n\nRegular commit body with no trailer at all.')"

# --- PASS: single ordinary human co-author ---
run_case pass "single human co-author" \
  "$(printf 'feat: add widget\n\nBody text.\n\nCo-Authored-By: Jane Developer <jane@example.com>')"

# --- PASS: multiple ordinary human co-authors ---
run_case pass "multiple human co-authors" \
  "$(printf 'feat: add widget\n\nBody text.\n\nCo-Authored-By: Jane Developer <jane@example.com>\nCo-Authored-By: John Smith <john@example.com>')"

# --- PASS: human whose first name happens to be "Claude" ---
run_case pass "human named Claude with a personal email" \
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

echo
echo "check_commit_attribution_test: ${pass_count} passed, ${fail_count} failed"

if [ "$fail_count" -ne 0 ]; then
  exit 1
fi

exit 0
