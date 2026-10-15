#!/usr/bin/env bash
set -euo pipefail
# #555 two-session owner Custom type change vs atomic Routine Save.
db="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
uid="a5551000-0000-4000-8000-000000000001"
program="a5551000-0000-4000-8000-000000000011"
routine_a="a5551000-0000-4000-8000-000000000021"
routine_b="a5551000-0000-4000-8000-000000000022"
custom_a="a5551000-0000-4000-8000-000000000031"
custom_b="a5551000-0000-4000-8000-000000000032"
scratch="$(mktemp -d)"
fifo="$scratch/input"
log_a="$scratch/a.log"
log_b="$scratch/b.log"
pid_a=""
pid_b=""
writer_open=0
cleanup() {
  local result=$?
  trap - EXIT
  if [[ "$writer_open" == 1 ]]; then exec 3>&-; fi
  for pid in "$pid_a" "$pid_b"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  psql "$db" --set=ON_ERROR_STOP=1 --quiet \
    --command="delete from auth.users where id='$uid'::uuid" \
    >/dev/null 2>&1 || true
  if [[ "$result" != 0 ]]; then
    echo "A log:"; [[ ! -f "$log_a" ]] || cat "$log_a"
    echo "B log:"; [[ ! -f "$log_b" ]] || cat "$log_b"
  fi
  rm -rf -- "$scratch"
  exit "$result"
}
trap cleanup EXIT
wait_log() {
  local wanted=$1 file=$2 pid=$3
  for _ in $(seq 1 150); do
    if grep -Fq "$wanted" "$file" 2>/dev/null; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  echo "Missing $wanted"; return 1
}
wait_lock() {
  local phrase=$1 pid=$2
  for _ in $(seq 1 100); do
    local result
    result="$(psql "$db" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
      --command="select exists(select 1 from pg_stat_activity
        where state='active' and wait_event_type='Lock'
          and query ilike '%$phrase%')" | tr -d '[:space:]')"
    if [[ "$result" == t ]]; then return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then return 1; fi
    sleep 0.1
  done
  echo "No Custom lock wait for $phrase"; return 1
}
start_a() {
  rm -f "$fifo"; mkfifo "$fifo"
  : >"$log_a"; : >"$log_b"
  psql "$db" --set=ON_ERROR_STOP=1 \
    --set=uid="$uid" --set=routine_a="$routine_a" \
    --set=routine_b="$routine_b" --set=custom_a="$custom_a" \
    --set=custom_b="$custom_b" <"$fifo" >"$log_a" 2>&1 &
  pid_a=$!
  exec 3>"$fifo"; writer_open=1
}
finish_a() {
  cat >&3 <<'SQL'
commit;
\echo SESSION_A_COMMITTED
\quit
SQL
  exec 3>&-; writer_open=0
  wait "$pid_a"; pid_a=""
  grep -Fq SESSION_A_COMMITTED "$log_a"
}
psql "$db" --set=ON_ERROR_STOP=1 --quiet <<SQL
insert into auth.users(id,email) values
 ('$uid'::uuid,'issue555-type-race@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('$program'::uuid,'$uid'::uuid,'Archive Race Program');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('$routine_a'::uuid,'$uid'::uuid,'$program'::uuid,'Routine A'),
 ('$routine_b'::uuid,'$uid'::uuid,'$program'::uuid,'Routine B');
insert into public.user_workout_exercises(id,user_id,display_name,status,exercise_type) values
 ('$custom_a'::uuid,'$uid'::uuid,'Type-first','active','weight_reps'),
 ('$custom_b'::uuid,'$uid'::uuid,'Save-first','active','weight_reps');
SQL
# 1: archived status UPDATE owns row first; NEW Save waits and rejects.
start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'uid', true);
update public.user_workout_exercises set exercise_type='duration'
where id=:'custom_a'::uuid and user_id=:'uid'::uuid;
\echo TYPE_CHANGE_FIRST_HELD
SQL
wait_log TYPE_CHANGE_FIRST_HELD "$log_a" "$pid_a"
psql "$db" --set=ON_ERROR_STOP=1 --set=uid="$uid" \
 --set=routine_a="$routine_a" --set=custom_a="$custom_a" \
 >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'uid', true);
\echo SAVE_START
select public.save_user_workout_routine_composition(
 :'routine_a'::uuid,0,'a5551000-0000-4000-8000-000000000091'::uuid,
 jsonb_build_array(jsonb_build_object(
   'id','a5551000-0000-4000-8000-000000000041',
   'exercise_ref',:'custom_a',
   'expected_exercise_type','weight_reps','sets',jsonb_build_array(
     jsonb_build_object('id','a5551000-0000-4000-8000-000000000051','reps',7))
 )));
commit;
SQL
pid_b=$!
wait_log SAVE_START "$log_b" "$pid_b"
wait_lock save_user_workout_routine_composition "$pid_b"
finish_a
if wait "$pid_b"; then
  echo "Concurrent type change erroneously accepted stale Save"; exit 1
fi
pid_b=""
grep -Fq routine_composition_custom_type_changed "$log_b"
check="$(psql "$db" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
 --command="select
 (select composition_revision=0 from public.user_workout_routines
  where id='$routine_a'::uuid)
 and not exists(select 1 from public.user_workout_routine_exercises
  where routine_id='$routine_a'::uuid)" | tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo "Rejected type-first Save was not atomic"; exit 1
fi
# 2: Save's share lock wins; archive waits, then succeeds after Save commit.
start_a
cat >&3 <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'uid', true);
select public.save_user_workout_routine_composition(
 :'routine_b'::uuid,0,'a5551000-0000-4000-8000-000000000092'::uuid,
 jsonb_build_array(jsonb_build_object(
   'id','a5551000-0000-4000-8000-000000000042',
   'exercise_ref',:'custom_b',
   'expected_exercise_type','weight_reps','sets',jsonb_build_array(
     jsonb_build_object('id','a5551000-0000-4000-8000-000000000052','reps',8))
 )));
\echo SAVE_FIRST_HELD
SQL
wait_log SAVE_FIRST_HELD "$log_a" "$pid_a"
psql "$db" --set=ON_ERROR_STOP=1 --set=uid="$uid" \
 --set=custom_b="$custom_b" >"$log_b" 2>&1 <<'SQL' &
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', :'uid', true);
\echo TYPE_CHANGE_START
update public.user_workout_exercises set exercise_type='duration'
where id=:'custom_b'::uuid and user_id=:'uid'::uuid;
commit;
\echo TYPE_CHANGE_AFTER_SAVE
SQL
pid_b=$!
wait_log TYPE_CHANGE_START "$log_b" "$pid_b"
wait_lock update "$pid_b"
finish_a
wait "$pid_b"; pid_b=""
grep -Fq TYPE_CHANGE_AFTER_SAVE "$log_b"
check="$(psql "$db" --tuples-only --no-align --set=ON_ERROR_STOP=1 \
 --command="select
 (select composition_revision=1 from public.user_workout_routines
  where id='$routine_b'::uuid)
 and (select exercise_type='duration' from public.user_workout_exercises
  where id='$custom_b'::uuid)
 and exists(select 1 from public.user_workout_routine_exercises
  where routine_id='$routine_b'::uuid and user_exercise_id='$custom_b'::uuid)
 and (select reps=8 from public.user_workout_routine_sets
  where id='a5551000-0000-4000-8000-000000000052'::uuid)" |
 tr -d '[:space:]')"
if [[ "$check" != t ]]; then
  echo "Save-before-type-change did not preserve the historical composition"
  exit 1
fi
echo "GitHub #534 real two-session type-vs-Save races passed."
