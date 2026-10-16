#!/usr/bin/env bash
# Keep each Flutter test-bearing package in exactly one shard.
set -euo pipefail

fail() {
  printf 'Flutter CI shard inventory error: %s\n' "$*" >&2
  exit 1
}

# These are intentionally fixed until real CI timings justify rebalancing.
# Keep all Flutter packages with a test/ directory in exactly one list.
APP_WORKOUT=(
  apps/app
  apps/features/workout
  apps/features/profile
  apps/features/splash
)
NUTRITION_ONBOARDING=(
  apps/features/nutrition
  apps/features/onboarding
  apps/features/auth
  apps/features/account_setup
)
CORE_WEAR=(
  apps/core
  apps/wear
  apps/features/home
  apps/features/progress
  apps/features/settings
)

verify_inventory() {
  local package
  local -a expected=("${APP_WORKOUT[@]}" "${NUTRITION_ONBOARDING[@]}" "${CORE_WEAR[@]}")
  local -a actual=()
  local -A seen=()

  for package in "${expected[@]}"; do
    [[ -z "${seen[$package]+present}" ]] || fail "Duplicate shard assignment: $package"
    seen[$package]=1
    [[ -f "$package/pubspec.yaml" && -d "$package/test" ]] || fail "Missing Flutter test package: $package"
  done

  shopt -s nullglob globstar
  # Cover every Melos features/** nesting depth, not only one feature level.
  for package in apps/* apps/features/**; do
    if [[ -f "$package/pubspec.yaml" && -d "$package/test" ]] &&
       grep -Eq '^  flutter:[[:space:]]*$' "$package/pubspec.yaml"; then
      actual+=("$package")
    fi
  done
  shopt -u nullglob globstar

  ((${#actual[@]} > 0)) || fail 'No Flutter test-bearing packages were discovered'
  local expected_sorted actual_sorted
  expected_sorted="$(printf '%s\n' "${expected[@]}" | LC_ALL=C sort)"
  actual_sorted="$(printf '%s\n' "${actual[@]}" | LC_ALL=C sort)"
  if [[ "$expected_sorted" != "$actual_sorted" ]]; then
    printf 'Expected shard inventory vs discovered Flutter test packages:\n' >&2
    diff -u <(printf '%s\n' "$expected_sorted") <(printf '%s\n' "$actual_sorted") >&2 || true
    fail 'Test inventory drift: update shard assignments before merging'
  fi
  echo "Verified ${#actual[@]} Flutter test packages across three disjoint shards."
}

[[ $# -ge 1 ]] || fail 'Usage: flutter-test-shards.sh verify | run <app-workout|nutrition-onboarding|core-wear>'
case "$1" in
  verify)
    [[ $# -eq 1 ]] || fail 'verify takes no additional arguments'
    verify_inventory
    ;;
  run)
    [[ $# -eq 2 ]] || fail 'run requires exactly one shard name'
    verify_inventory
    case "$2" in
      app-workout) selected=("${APP_WORKOUT[@]}") ;;
      nutrition-onboarding) selected=("${NUTRITION_ONBOARDING[@]}") ;;
      core-wear) selected=("${CORE_WEAR[@]}") ;;
      *) fail "Unknown shard: $2" ;;
    esac
    result=0
    for package in "${selected[@]}"; do
      echo "::group::Flutter test $package"
      if (cd "$package" && flutter pub get && flutter test --no-pub); then
        echo "PASS: $package"
      else
        echo "FAIL: $package" >&2
        result=1
      fi
      echo '::endgroup::'
    done
    exit "$result"
    ;;
  *) fail "Unknown action: $1" ;;
esac
