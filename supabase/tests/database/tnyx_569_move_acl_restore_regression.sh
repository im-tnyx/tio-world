#!/usr/bin/env bash
# Disposable CI only: exercise the same ACL cleanup used by two-session races.
set -euo pipefail
source supabase/tests/database/tnyx_569_move_acl_fixture.sh
tnyx_569_require_disposable_db

signatures=(
  'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'
  'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'
  'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)'
)
original=()
for signature in "${signatures[@]}"; do
  original+=("$(tnyx_569_auth_acl "$signature")")
done

restore_original() {
  local status=$? failed=0
  trap - EXIT
  for i in "${!signatures[@]}"; do
    tnyx_569_restore_acl "${signatures[$i]}" "${original[$i]}" || failed=1
  done
  if [[ "$failed" == 1 ]]; then exit 74; fi
  exit "$status"
}
trap restore_original EXIT

run_fixture() (
  local initial="$1" outcome="$2"
  cleanup_fixture() {
    local status=$? failed=0
    trap - EXIT
    for signature in "${signatures[@]}"; do
      tnyx_569_restore_acl "$signature" "$initial" || failed=1
    done
    if [[ "$failed" == 1 ]]; then exit 74; fi
    exit "$status"
  }
  trap cleanup_fixture EXIT
  for signature in "${signatures[@]}"; do
    tnyx_569_assert_acl "$signature" "$initial" || exit 72
    psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 \
      --command="grant execute on function $signature to authenticated" || exit 72
    tnyx_569_assert_acl "$signature" t || exit 72
  done
  # Exit 73 models a failed race fixture after grants are visible. EXIT must
  # run the identical helper used by real race blocks before CI continues.
  if [[ "$outcome" == failure ]]; then exit 73; fi
  exit 0
)

for signature in "${signatures[@]}"; do
  psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 \
    --command="revoke all on function $signature from public,anon,authenticated,service_role"
  tnyx_569_assert_acl "$signature" f
done
run_fixture f success
if run_fixture f failure; then
  echo 'Simulated denied-baseline failure unexpectedly succeeded.' >&2
  exit 1
else
  [[ "$?" == 73 ]]
fi
for signature in "${signatures[@]}"; do tnyx_569_assert_acl "$signature" f; done

for signature in "${signatures[@]}"; do
  psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 \
    --command="grant execute on function $signature to authenticated"
  tnyx_569_assert_acl "$signature" t
done
run_fixture t success
if run_fixture t failure; then
  echo 'Simulated granted-baseline failure unexpectedly succeeded.' >&2
  exit 1
else
  [[ "$?" == 73 ]]
fi
for signature in "${signatures[@]}"; do tnyx_569_assert_acl "$signature" t; done
