#!/usr/bin/env bash
set -euo pipefail

database_url="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
test_user="dddddddd-dddd-4ddd-8ddd-dddddddddddd"
canonical_config='{"schema_version":1,"items":[{"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},{"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},{"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},{"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3}]}'
config_with_x='{"schema_version":1,"items":[{"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},{"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},{"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},{"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3},{"id":"meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","display_name":"Concurrent X","active":true,"order":4}]}'

sync_dir="$(mktemp -d)"
session_a_fifo="$sync_dir/session-a.stdin"
session_a_log="$sync_dir/session-a.log"
session_b_log="$sync_dir/session-b.log"
session_a_pid=""
writer_open=0

cleanup() {
  local status=$?
  trap - EXIT

  if [[ "$writer_open" == "1" ]]; then
    exec 3>&-
  fi
  if [[ -n "$session_a_pid" ]] && kill -0 "$session_a_pid" 2>/dev/null; then
    kill "$session_a_pid" 2>/dev/null || true
    wait "$session_a_pid" 2>/dev/null || true
  fi

  psql "$database_url" --set=ON_ERROR_STOP=1 --quiet \
    --command="delete from auth.users where id = '$test_user'::uuid" \
    >/dev/null 2>&1 || true

  if [[ "$status" != "0" ]]; then
    echo 'Session A log:'
    test -f "$session_a_log" && sed -n '1,240p' "$session_a_log"
    echo 'Session B log:'
    test -f "$session_b_log" && sed -n '1,240p' "$session_b_log"
  fi

  rm -r -- "$sync_dir"
  exit "$status"
}
trap cleanup EXIT

wait_for_log() {
  local sentinel=$1
  local log_file=$2
  local process_id=$3

  for _ in $(seq 1 200); do
    if grep -Fq "$sentinel" "$log_file" 2>/dev/null; then
      return 0
    fi
    if ! kill -0 "$process_id" 2>/dev/null; then
      echo "Session exited before sentinel: $sentinel"
      return 1
    fi
    sleep 0.1
  done

  echo "Timed out waiting for sentinel: $sentinel"
  return 1
}

psql "$database_url" \
  --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" \
  --set=canonical_config="$canonical_config" <<'SQL'
delete from auth.users where id = :'test_user'::uuid;
insert into auth.users (id, email)
values (:'test_user'::uuid, 'concurrency@example.test');
insert into public.user_nutrition_profiles (user_id, meal_categories_config)
values (:'test_user'::uuid, :'canonical_config'::jsonb);
SQL

mkfifo "$session_a_fifo"
psql "$database_url" \
  --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" \
  <"$session_a_fifo" >"$session_a_log" 2>&1 &
session_a_pid=$!
exec 3>"$session_a_fifo"
writer_open=1

cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub', :'test_user', 'role', 'authenticated')::text,
  true
);
create temp table session_a_stale_config as
select meal_categories_config as config
from public.user_nutrition_profiles
where user_id = :'test_user'::uuid;
\echo SESSION_A_STALE_SNAPSHOT_READY
SQL

wait_for_log 'SESSION_A_STALE_SNAPSHOT_READY' "$session_a_log" "$session_a_pid"

psql "$database_url" \
  --set=ON_ERROR_STOP=1 \
  --set=test_user="$test_user" \
  --set=config_with_x="$config_with_x" >"$session_b_log" 2>&1 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub', :'test_user', 'role', 'authenticated')::text,
  true
);
update public.user_nutrition_profiles
set meal_categories_config = :'config_with_x'::jsonb
where user_id = :'test_user'::uuid;
commit;
\echo SESSION_B_X_COMMITTED
SQL
grep -Fq 'SESSION_B_X_COMMITTED' "$session_b_log"

cat >&3 <<'SQL'
do $$
declare
  v_rejected boolean := false;
begin
  begin
    update public.user_nutrition_profiles
    set meal_categories_config = (select config from session_a_stale_config)
    where user_id = current_setting('request.jwt.claim.sub')::uuid;
  exception
    when check_violation then
      v_rejected := true;
  end;

  if not v_rejected then
    raise exception 'stale Session A write unexpectedly removed retained custom ID X';
  end if;
end;
$$;
commit;
\echo SESSION_A_STALE_WRITE_REJECTED
\quit
SQL
exec 3>&-
writer_open=0

wait "$session_a_pid"
session_a_pid=""
grep -Fq 'SESSION_A_STALE_WRITE_REJECTED' "$session_a_log"

final_has_x="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select exists (
    select 1
    from public.user_nutrition_profiles p,
         jsonb_array_elements(p.meal_categories_config->'items') item
    where p.user_id = '$test_user'::uuid
      and item->>'id' = 'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  )")"
if [[ "$final_has_x" != "t" ]]; then
  echo 'Final row lost retained custom ID X after stale Session A attempted its write.'
  exit 1
fi

psql "$database_url" --set=ON_ERROR_STOP=1 --set=test_user="$test_user" <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'test_user', true);
select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub', :'test_user', 'role', 'authenticated')::text,
  true
);
update public.user_nutrition_profiles
set meal_categories_config = jsonb_set(
  jsonb_set(meal_categories_config, '{items,4,display_name}', '"Concurrent X renamed"'),
  '{items,4,active}',
  'false'
)
where user_id = :'test_user'::uuid;
commit;
SQL

preserving_update_passed="$(psql "$database_url" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
  --command="select exists (
    select 1
    from public.user_nutrition_profiles p,
         jsonb_array_elements(p.meal_categories_config->'items') item
    where p.user_id = '$test_user'::uuid
      and item->>'id' = 'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and item->>'display_name' = 'Concurrent X renamed'
      and (item->>'active')::boolean = false
  )")"
if [[ "$preserving_update_passed" != "t" ]]; then
  echo 'Later identity-preserving update did not persist as expected.'
  exit 1
fi

echo 'TNYX-67 Slice B1 real two-session concurrency test passed.'
