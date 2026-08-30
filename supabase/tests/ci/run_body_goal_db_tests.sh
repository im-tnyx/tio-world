#!/usr/bin/env bash
# TNYX-136 real-database proof for public.set_active_body_goal.
#
# Runs entirely against the ephemeral local Supabase stack started by
# `supabase start` inside .github/workflows/supabase-db-tests.yml -- never
# against a hosted/production project. Exercises the RPC through real
# PostgREST HTTP calls with real synthetic-user access tokens (not
# session-variable simulation), so RPC execute permissions and RLS are
# proven through the actual API boundary, and inspects the applied function
# directly via psql for the security/grant properties HTTP calls can't show.
#
# Exits non-zero if any assertion fails, so the CI job fails truthfully.

set -euo pipefail

: "${API_URL:?API_URL must be set}"
: "${ANON_KEY:?ANON_KEY must be set}"
: "${DB_URL:?DB_URL must be set}"

PASSWORD='TestPass123!'
RUN_ID="${GITHUB_RUN_ID:-local$$}"

PASS=0
FAIL=0
FAILURES=()

pass() { PASS=$((PASS + 1)); echo "PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); echo "FAIL: $1"; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass "$desc"; else fail "$desc (expected [$expected] got [$actual])"; fi
}

assert_2xx() {
  local desc="$1" code="$2"
  if [[ "$code" =~ ^2 ]]; then pass "$desc ($code)"; else fail "$desc (expected 2xx, got $code)"; fi
}

assert_err() {
  local desc="$1" code="$2"
  if [[ ! "$code" =~ ^2 ]]; then pass "$desc ($code)"; else fail "$desc (expected an error status, got $code)"; fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then pass "$desc"; else fail "$desc (expected to find '$needle' in: $haystack)"; fi
}

psql_scalar() {
  psql "$DB_URL" -X -A -t -c "$1" | tr -d '[:space:]'
}

# ---- HTTP helpers ----------------------------------------------------------

# create_user EMAIL -> prints "TOKEN UID"
create_user() {
  local email="$1"
  curl -sS -o /dev/null -X POST "$API_URL/auth/v1/signup" \
    -H "apikey: $ANON_KEY" -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$PASSWORD\"}"

  local tokresp
  tokresp="$(mktemp)"
  curl -sS -o "$tokresp" -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$PASSWORD\"}"

  local token uid
  token="$(jq -r '.access_token // empty' "$tokresp")"
  uid="$(jq -r '.user.id // empty' "$tokresp")"
  if [ -z "$token" ] || [ -z "$uid" ]; then
    echo "FATAL: could not obtain access token for $email" >&2
    cat "$tokresp" >&2
    rm -f "$tokresp"
    exit 1
  fi
  rm -f "$tokresp"
  echo "$token $uid"
}

# insert_weight TOKEN WEIGHT_KG -> prints http code
insert_weight() {
  local token="$1" weight="$2"
  curl -sS -o /dev/null -w '%{http_code}' -X POST "$API_URL/rest/v1/body_weight_logs" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" -H "Prefer: return=minimal" \
    -d "{\"weight_kg\": $weight, \"source\": \"db_test_fixture\"}"
}

# call_rpc TOKEN GOAL_TYPE TARGET_OR_null PACE_OR_null OUT_FILE -> prints http code
call_rpc() {
  local token="$1" goal_type="$2" target="$3" pace="$4" out_file="$5"
  local body
  body="$(jq -n --arg gt "$goal_type" --argjson tg "$target" --argjson pc "$pace" \
    '{p_goal_type:$gt, p_target_weight_kg:$tg, p_weekly_weight_change_kg:$pc}')"
  curl -sS -o "$out_file" -w '%{http_code}' -X POST "$API_URL/rest/v1/rpc/set_active_body_goal" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$body"
}

# ---- 1. migration / function inspection ------------------------------------

echo "== function + security inspection =="

fn_count="$(psql_scalar "select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_active_body_goal';")"
assert_eq "set_active_body_goal function exists exactly once after clean migration apply" "1" "$fn_count"

fn_signature="$(psql_scalar "select string_agg(format_type(t, null), ',' order by ord) from pg_proc p, unnest(p.proargtypes) with ordinality as u(t, ord) where p.oid = 'public.set_active_body_goal(text, numeric, numeric)'::regprocedure;")"
assert_eq "signature is exactly (text, numeric, numeric)" "text,numeric,numeric" "$fn_signature"

fn_returns_void="$(psql_scalar "select p.prorettype = 'void'::regtype from pg_proc p where p.oid = 'public.set_active_body_goal(text, numeric, numeric)'::regprocedure;")"
assert_eq "return type is void" "t" "$fn_returns_void"

is_invoker="$(psql_scalar "select not p.prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_active_body_goal';")"
assert_eq "function is SECURITY INVOKER, not DEFINER" "t" "$is_invoker"

lang_ok="$(psql_scalar "select l.lanname = 'plpgsql' from pg_proc p join pg_language l on l.oid = p.prolang join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_active_body_goal';")"
assert_eq "function language is plpgsql" "t" "$lang_ok"

public_can_execute="$(psql_scalar "select has_function_privilege('public', 'public.set_active_body_goal(text, numeric, numeric)', 'EXECUTE');")"
assert_eq "PUBLIC execute is revoked" "f" "$public_can_execute"

anon_can_execute="$(psql_scalar "select has_function_privilege('anon', 'public.set_active_body_goal(text, numeric, numeric)', 'EXECUTE');")"
assert_eq "anon execute is revoked" "f" "$anon_can_execute"

authenticated_can_execute="$(psql_scalar "select has_function_privilege('authenticated', 'public.set_active_body_goal(text, numeric, numeric)', 'EXECUTE');")"
assert_eq "authenticated execute is granted" "t" "$authenticated_can_execute"

body_rls_enabled="$(psql_scalar "select relrowsecurity from pg_class where oid = 'public.body_weight_logs'::regclass;")"
assert_eq "body_weight_logs RLS remains enabled" "t" "$body_rls_enabled"

goals_rls_enabled="$(psql_scalar "select relrowsecurity from pg_class where oid = 'public.user_body_goals'::regclass;")"
assert_eq "user_body_goals RLS remains enabled" "t" "$goals_rls_enabled"

# ---- 2. anon cannot execute the RPC over the real API boundary -------------

echo "== anon execute over the wire =="

anon_out="$(mktemp)"
anon_code="$(call_rpc "$ANON_KEY" "maintain_weight" "null" "null" "$anon_out")"
assert_err "anon-role HTTP call to the RPC is rejected" "$anon_code"
rm -f "$anon_out"

# ---- fixtures ---------------------------------------------------------------

echo "== creating synthetic users =="

read -r TOK_SAME_LOSE UID_SAME_LOSE <<<"$(create_user "same-lose-$RUN_ID@example.com")"
read -r TOK_SAME_GAIN UID_SAME_GAIN <<<"$(create_user "same-gain-$RUN_ID@example.com")"
read -r TOK_SAME_MAINT UID_SAME_MAINT <<<"$(create_user "same-maint-$RUN_ID@example.com")"
read -r TOK_L2G UID_L2G <<<"$(create_user "lose-to-gain-$RUN_ID@example.com")"
read -r TOK_G2L UID_G2L <<<"$(create_user "gain-to-lose-$RUN_ID@example.com")"
read -r TOK_D2M UID_D2M <<<"$(create_user "dir-to-maint-$RUN_ID@example.com")"
read -r TOK_M2D UID_M2D <<<"$(create_user "maint-to-dir-$RUN_ID@example.com")"
read -r TOK_RECOMP UID_RECOMP <<<"$(create_user "recomp-$RUN_ID@example.com")"
read -r TOK_NOWEIGHT UID_NOWEIGHT <<<"$(create_user "no-weight-$RUN_ID@example.com")"
read -r TOK_BADVOCAB UID_BADVOCAB <<<"$(create_user "bad-vocab-$RUN_ID@example.com")"
read -r TOK_RANGE UID_RANGE <<<"$(create_user "target-range-$RUN_ID@example.com")"
read -r TOK_DIR UID_DIR <<<"$(create_user "wrong-direction-$RUN_ID@example.com")"
read -r TOK_PACERANGE UID_PACERANGE <<<"$(create_user "pace-range-$RUN_ID@example.com")"
read -r TOK_PACEINC UID_PACEINC <<<"$(create_user "pace-increment-$RUN_ID@example.com")"
read -r TOK_MAINTREJ UID_MAINTREJ <<<"$(create_user "maintain-reject-$RUN_ID@example.com")"
read -r TOK_ROLLBACK UID_ROLLBACK <<<"$(create_user "rollback-$RUN_ID@example.com")"
read -r TOK_CONC_ACTIVE UID_CONC_ACTIVE <<<"$(create_user "concurrency-active-$RUN_ID@example.com")"
read -r TOK_CONC_FIRST UID_CONC_FIRST <<<"$(create_user "concurrency-first-$RUN_ID@example.com")"
read -r TOK_RETRY UID_RETRY <<<"$(create_user "retry-$RUN_ID@example.com")"
read -r TOK_RLS_A UID_RLS_A <<<"$(create_user "rls-a-$RUN_ID@example.com")"
read -r TOK_RLS_B UID_RLS_B <<<"$(create_user "rls-b-$RUN_ID@example.com")"

# ---- 3. same-goal update preserves identity (Lose / Gain / Maintain) -------

echo "== same-goal update preserves identity =="

insert_weight "$TOK_SAME_LOSE" 90 >/dev/null
out="$(mktemp)"; code="$(call_rpc "$TOK_SAME_LOSE" "lose_weight" 70 0.5 "$out")"; assert_2xx "same-Lose: first-goal creation succeeds" "$code"; rm -f "$out"
row1="$(psql "$DB_URL" -X -A -t -c "select id, starting_weight_kg, started_at, coalesce(intent_rank::text, 'null') from public.user_body_goals where user_id = '$UID_SAME_LOSE' and status = 'active';")"
id1="$(echo "$row1" | cut -d'|' -f1)"; start1="$(echo "$row1" | cut -d'|' -f2)"; started1="$(echo "$row1" | cut -d'|' -f3)"; rank1="$(echo "$row1" | cut -d'|' -f4)"
out="$(mktemp)"; code="$(call_rpc "$TOK_SAME_LOSE" "lose_weight" 65 0.4 "$out")"; assert_2xx "same-Lose: second same-type call succeeds" "$code"; rm -f "$out"
row2="$(psql "$DB_URL" -X -A -t -c "select id, starting_weight_kg, started_at, coalesce(intent_rank::text, 'null'), target_weight_kg, weekly_weight_change_kg from public.user_body_goals where user_id = '$UID_SAME_LOSE' and status = 'active';")"
id2="$(echo "$row2" | cut -d'|' -f1)"; start2="$(echo "$row2" | cut -d'|' -f2)"; started2="$(echo "$row2" | cut -d'|' -f3)"; rank2="$(echo "$row2" | cut -d'|' -f4)"; target2="$(echo "$row2" | cut -d'|' -f5)"; pace2="$(echo "$row2" | cut -d'|' -f6)"
assert_eq "same-Lose: row id preserved" "$id1" "$id2"
assert_eq "same-Lose: starting_weight_kg preserved" "$start1" "$start2"
assert_eq "same-Lose: started_at preserved" "$started1" "$started2"
assert_eq "same-Lose: intent_rank preserved" "$rank1" "$rank2"
assert_eq "same-Lose: target updated" "65" "$target2"
assert_eq "same-Lose: pace updated" "0.4" "$pace2"
active_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_SAME_LOSE' and status = 'active';")"
assert_eq "same-Lose: exactly one active row" "1" "$active_count"

insert_weight "$TOK_SAME_GAIN" 60 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_SAME_GAIN" "gain_weight" 70 0.5 "$out" >/dev/null; rm -f "$out"
gid1="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_SAME_GAIN' and status = 'active';")"
out="$(mktemp)"; code="$(call_rpc "$TOK_SAME_GAIN" "gain_weight" 75 0.3 "$out")"; assert_2xx "same-Gain: second same-type call succeeds" "$code"; rm -f "$out"
gid2="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_SAME_GAIN' and status = 'active';")"
assert_eq "same-Gain: row id preserved" "$gid1" "$gid2"
gain_target="$(psql_scalar "select target_weight_kg from public.user_body_goals where id = '$gid2';")"
assert_eq "same-Gain: target updated" "75" "$gain_target"

out="$(mktemp)"; code="$(call_rpc "$TOK_SAME_MAINT" "maintain_weight" "null" "null" "$out")"; assert_2xx "same-Maintain: first-goal creation succeeds with no weight logged" "$code"; rm -f "$out"
maint_row1="$(psql "$DB_URL" -X -A -t -c "select id, coalesce(starting_weight_kg::text,'null') from public.user_body_goals where user_id = '$UID_SAME_MAINT' and status = 'active';")"
mid1="$(echo "$maint_row1" | cut -d'|' -f1)"; mstart1="$(echo "$maint_row1" | cut -d'|' -f2)"
assert_eq "same-Maintain: starting_weight_kg is null (no weight ever logged)" "null" "$mstart1"
out="$(mktemp)"; code="$(call_rpc "$TOK_SAME_MAINT" "maintain_weight" "null" "null" "$out")"; assert_2xx "same-Maintain: second call succeeds" "$code"; rm -f "$out"
maint_row2="$(psql "$DB_URL" -X -A -t -c "select id, coalesce(starting_weight_kg::text,'null'), coalesce(target_weight_kg::text,'null'), coalesce(weekly_weight_change_kg::text,'null') from public.user_body_goals where user_id = '$UID_SAME_MAINT' and status = 'active';")"
mid2="$(echo "$maint_row2" | cut -d'|' -f1)"; mstart2="$(echo "$maint_row2" | cut -d'|' -f2)"; mtarget2="$(echo "$maint_row2" | cut -d'|' -f3)"; mpace2="$(echo "$maint_row2" | cut -d'|' -f4)"
assert_eq "same-Maintain: row id preserved" "$mid1" "$mid2"
assert_eq "same-Maintain: starting_weight_kg still null, never backfilled" "null" "$mstart2"
assert_eq "same-Maintain: target stays null" "null" "$mtarget2"
assert_eq "same-Maintain: pace stays null" "null" "$mpace2"

# ---- 4. changed-goal transitions ------------------------------------------

echo "== changed-goal transitions =="

insert_weight "$TOK_L2G" 90 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_L2G" "lose_weight" 80 0.5 "$out" >/dev/null; rm -f "$out"
l2g_old_id="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_L2G' and status = 'active';")"
out="$(mktemp)"; code="$(call_rpc "$TOK_L2G" "gain_weight" 100 0.5 "$out")"; assert_2xx "Lose to Gain transition succeeds" "$code"; rm -f "$out"
l2g_old_status="$(psql_scalar "select status from public.user_body_goals where id = '$l2g_old_id';")"
assert_eq "Lose to Gain: previous row superseded" "superseded" "$l2g_old_status"
l2g_new="$(psql "$DB_URL" -X -A -t -c "select goal_type, starting_weight_kg, target_weight_kg, weekly_weight_change_kg from public.user_body_goals where user_id = '$UID_L2G' and status = 'active';")"
assert_eq "Lose to Gain: new active row is gain_weight with snapshot + values" "gain_weight|90|100|0.5" "$l2g_new"
l2g_active_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_L2G' and status = 'active';")"
assert_eq "Lose to Gain: exactly one active row after transition" "1" "$l2g_active_count"

insert_weight "$TOK_G2L" 60 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_G2L" "gain_weight" 70 0.5 "$out" >/dev/null; rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_G2L" "lose_weight" 55 0.4 "$out")"; assert_2xx "Gain to Lose transition succeeds" "$code"; rm -f "$out"
g2l_new="$(psql "$DB_URL" -X -A -t -c "select goal_type, target_weight_kg, weekly_weight_change_kg from public.user_body_goals where user_id = '$UID_G2L' and status = 'active';")"
assert_eq "Gain to Lose: new active row correct" "lose_weight|55|0.4" "$g2l_new"

insert_weight "$TOK_D2M" 90 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_D2M" "lose_weight" 80 0.5 "$out" >/dev/null; rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_D2M" "maintain_weight" "null" "null" "$out")"; assert_2xx "directional to Maintain transition succeeds" "$code"; rm -f "$out"
d2m_new="$(psql "$DB_URL" -X -A -t -c "select goal_type, coalesce(target_weight_kg::text,'null'), coalesce(weekly_weight_change_kg::text,'null') from public.user_body_goals where user_id = '$UID_D2M' and status = 'active';")"
assert_eq "directional to Maintain: target/pace null on the new active row" "maintain_weight|null|null" "$d2m_new"

insert_weight "$TOK_M2D" 70 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_M2D" "maintain_weight" "null" "null" "$out" >/dev/null; rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_M2D" "lose_weight" 60 0.5 "$out")"; assert_2xx "Maintain to directional transition succeeds" "$code"; rm -f "$out"
m2d_new="$(psql "$DB_URL" -X -A -t -c "select goal_type, starting_weight_kg, target_weight_kg from public.user_body_goals where user_id = '$UID_M2D' and status = 'active';")"
assert_eq "Maintain to directional: new active row correct" "lose_weight|70|60" "$m2d_new"

# legacy Recomposition -> supported goal: seed the legacy active row directly,
# the way historical onboarding data could look; the RPC itself never accepts
# 'recomposition' as a requested value, only as pre-existing state to move away from.
insert_weight "$TOK_RECOMP" 75 >/dev/null
psql "$DB_URL" -X -q -c "insert into public.user_body_goals (user_id, goal_type, starting_weight_kg, status, started_at) values ('$UID_RECOMP', 'recomposition', 75, 'active', now());"
recomp_old_id="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_RECOMP' and status = 'active';")"
out="$(mktemp)"; code="$(call_rpc "$TOK_RECOMP" "lose_weight" 65 0.4 "$out")"; assert_2xx "legacy Recomposition to Lose transition succeeds" "$code"; rm -f "$out"
recomp_old_status="$(psql_scalar "select status from public.user_body_goals where id = '$recomp_old_id';")"
assert_eq "legacy Recomposition row superseded, not rewritten in place" "superseded" "$recomp_old_status"
recomp_new="$(psql "$DB_URL" -X -A -t -c "select goal_type, target_weight_kg from public.user_body_goals where user_id = '$UID_RECOMP' and status = 'active';")"
assert_eq "new active row after Recomposition transition is lose_weight/65" "lose_weight|65" "$recomp_new"

# ---- 5. validation rejections (no state change) ----------------------------

echo "== validation rejections =="

out="$(mktemp)"; code="$(call_rpc "$TOK_NOWEIGHT" "lose_weight" 70 0.5 "$out")"
assert_err "directional goal without any current weight is rejected" "$code"
assert_contains "rejection names the missing-current-weight rule" "$(cat "$out")" "directional_goal_requires_current_weight"
rm -f "$out"
assert_eq "no-weight rejection left zero rows" "0" "$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_NOWEIGHT';")"

out="$(mktemp)"; code="$(call_rpc "$TOK_BADVOCAB" "recomposition" "null" "null" "$out")"
assert_err "recomposition is rejected as a newly-requested goal type" "$code"
assert_contains "rejection names invalid_goal_type" "$(cat "$out")" "invalid_goal_type"
rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_BADVOCAB" "bogus_value" "null" "null" "$out")"
assert_err "unknown goal vocabulary is rejected" "$code"
rm -f "$out"
assert_eq "bad-vocabulary rejections left zero rows" "0" "$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_BADVOCAB';")"

insert_weight "$TOK_RANGE" 90 >/dev/null
out="$(mktemp)"; code="$(call_rpc "$TOK_RANGE" "lose_weight" 10 0.5 "$out")"
assert_err "target below 30kg range floor is rejected" "$code"
assert_contains "rejection names target_weight_out_of_range" "$(cat "$out")" "target_weight_out_of_range"
rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_RANGE" "gain_weight" 250 0.5 "$out")"
assert_err "target above 200kg range ceiling is rejected" "$code"
rm -f "$out"
assert_eq "target-range rejections left zero rows" "0" "$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_RANGE';")"

insert_weight "$TOK_DIR" 90 >/dev/null
out="$(mktemp)"; code="$(call_rpc "$TOK_DIR" "lose_weight" 95 0.5 "$out")"
assert_err "Lose target above current weight is rejected" "$code"
assert_contains "rejection names target_weight_must_be_below_current_for_lose" "$(cat "$out")" "target_weight_must_be_below_current_for_lose"
rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_DIR" "gain_weight" 50 0.5 "$out")"
assert_err "Gain target below current weight is rejected" "$code"
assert_contains "rejection names target_weight_must_be_above_current_for_gain" "$(cat "$out")" "target_weight_must_be_above_current_for_gain"
rm -f "$out"

insert_weight "$TOK_PACERANGE" 90 >/dev/null
out="$(mktemp)"; code="$(call_rpc "$TOK_PACERANGE" "lose_weight" 80 0.05 "$out")"
assert_err "pace below 0.1 floor is rejected" "$code"
rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_PACERANGE" "lose_weight" 80 2.0 "$out")"
assert_err "pace above 1.5 ceiling is rejected" "$code"
rm -f "$out"

insert_weight "$TOK_PACEINC" 90 >/dev/null
out="$(mktemp)"; code="$(call_rpc "$TOK_PACEINC" "lose_weight" 80 0.15 "$out")"
assert_err "pace not aligned to the exact 0.1kg increment is rejected" "$code"
assert_contains "rejection names goal_pace_invalid_increment" "$(cat "$out")" "goal_pace_invalid_increment"
rm -f "$out"

insert_weight "$TOK_MAINTREJ" 90 >/dev/null
out="$(mktemp)"; code="$(call_rpc "$TOK_MAINTREJ" "maintain_weight" 80 "null" "$out")"
assert_err "Maintain with a target is rejected" "$code"
assert_contains "rejection names maintain_goal_cannot_carry_target_or_pace" "$(cat "$out")" "maintain_goal_cannot_carry_target_or_pace"
rm -f "$out"
out="$(mktemp)"; code="$(call_rpc "$TOK_MAINTREJ" "maintain_weight" "null" 0.5 "$out")"
assert_err "Maintain with a pace is rejected" "$code"
rm -f "$out"

# ---- 6. forced-exception rollback proof ------------------------------------

echo "== forced-exception rollback (CI-only trigger) =="

insert_weight "$TOK_ROLLBACK" 90 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_ROLLBACK" "lose_weight" 80 0.5 "$out" >/dev/null; rm -f "$out"
rollback_original_id="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_ROLLBACK' and status = 'active';")"

out="$(mktemp)"; code="$(call_rpc "$TOK_ROLLBACK" "gain_weight" 123.45 0.5 "$out")"
assert_err "forced-failure transition (sentinel target) is rejected end-to-end" "$code"
rm -f "$out"

rollback_status="$(psql_scalar "select status from public.user_body_goals where id = '$rollback_original_id';")"
assert_eq "rollback: original Lose goal is still active (supersede was rolled back)" "active" "$rollback_status"
rollback_row_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_ROLLBACK';")"
assert_eq "rollback: no orphaned new row was left behind by the failed insert" "1" "$rollback_row_count"

# ---- 7. concurrency ---------------------------------------------------------

echo "== concurrency =="

insert_weight "$TOK_CONC_ACTIVE" 90 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_CONC_ACTIVE" "lose_weight" 80 0.5 "$out" >/dev/null; rm -f "$out"

conc1_out="$(mktemp)"; conc2_out="$(mktemp)"
( call_rpc "$TOK_CONC_ACTIVE" "gain_weight" 100 0.5 "$conc1_out" >"$conc1_out.code" ) &
p1=$!
( call_rpc "$TOK_CONC_ACTIVE" "gain_weight" 95 0.4 "$conc2_out" >"$conc2_out.code" ) &
p2=$!
wait "$p1" "$p2"
conc1_code="$(cat "$conc1_out.code")"; conc2_code="$(cat "$conc2_out.code")"
assert_2xx "concurrent changed-goal call #1 (existing active goal) did not error" "$conc1_code"
assert_2xx "concurrent changed-goal call #2 (existing active goal) did not error" "$conc2_code"
rm -f "$conc1_out" "$conc2_out" "$conc1_out.code" "$conc2_out.code"

conc_active_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_CONC_ACTIVE' and status = 'active';")"
assert_eq "two concurrent transitions from an existing active goal serialize to exactly one active row" "1" "$conc_active_count"
conc_total_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_CONC_ACTIVE';")"
assert_eq "two concurrent transitions leave exactly two historical rows total (original + final), no duplicate insert" "2" "$conc_total_count"

insert_weight "$TOK_CONC_FIRST" 90 >/dev/null
first1_out="$(mktemp)"; first2_out="$(mktemp)"
( call_rpc "$TOK_CONC_FIRST" "lose_weight" 80 0.5 "$first1_out" >"$first1_out.code" ) &
p3=$!
( call_rpc "$TOK_CONC_FIRST" "lose_weight" 75 0.4 "$first2_out" >"$first2_out.code" ) &
p4=$!
wait "$p3" "$p4"
first1_code="$(cat "$first1_out.code")"; first2_code="$(cat "$first2_out.code")"
assert_2xx "concurrent first-goal call #1 (no prior active goal) did not error" "$first1_code"
assert_2xx "concurrent first-goal call #2 (no prior active goal) did not error" "$first2_code"
rm -f "$first1_out" "$first2_out" "$first1_out.code" "$first2_out.code"

first_active_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_CONC_FIRST' and status = 'active';")"
assert_eq "two concurrent first-goal calls (users row lock covers the no-active-row case) serialize to exactly one active row" "1" "$first_active_count"
first_total_count="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_CONC_FIRST';")"
assert_eq "two concurrent first-goal calls leave exactly one row total, not two competing inserts" "1" "$first_total_count"

# ---- 8. retry idempotency ---------------------------------------------------

echo "== retry idempotency =="

insert_weight "$TOK_RETRY" 90 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_RETRY" "lose_weight" 80 0.5 "$out" >/dev/null; rm -f "$out"
out="$(mktemp)"; call_rpc "$TOK_RETRY" "gain_weight" 100 0.5 "$out" >/dev/null; rm -f "$out"
retry_id_after_first="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_RETRY' and status = 'active';")"
out="$(mktemp)"; code="$(call_rpc "$TOK_RETRY" "gain_weight" 100 0.5 "$out")"
assert_2xx "retry of an already-committed transition succeeds" "$code"
rm -f "$out"
retry_id_after_second="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_RETRY' and status = 'active';")"
assert_eq "retry updates the same active row in place, it does not insert another one" "$retry_id_after_first" "$retry_id_after_second"
retry_total="$(psql_scalar "select count(*) from public.user_body_goals where user_id = '$UID_RETRY';")"
assert_eq "retry leaves exactly two historical rows total (original + transitioned), no third" "2" "$retry_total"

# ---- 9. RLS cross-user isolation --------------------------------------------

echo "== RLS cross-user isolation =="

insert_weight "$TOK_RLS_A" 90 >/dev/null
out="$(mktemp)"; call_rpc "$TOK_RLS_A" "lose_weight" 80 0.5 "$out" >/dev/null; rm -f "$out"
rls_a_row_id="$(psql_scalar "select id from public.user_body_goals where user_id = '$UID_RLS_A' and status = 'active';")"

# Caller B attempts to directly patch caller A's row through PostgREST using
# B's own access token. Real RLS enforcement, not the RPC's own auth.uid()
# scoping, is what must block this.
patch_out="$(mktemp)"
patch_code="$(curl -sS -o "$patch_out" -w '%{http_code}' -X PATCH \
  "$API_URL/rest/v1/user_body_goals?id=eq.$rls_a_row_id" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOK_RLS_B" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d '{"target_weight_kg": 1}')"
patch_body="$(cat "$patch_out")"
rm -f "$patch_out"
assert_2xx "cross-user PATCH request itself is accepted (RLS silently filters rows, it does not error)" "$patch_code"
assert_eq "cross-user PATCH via PostgREST affects zero rows (RLS blocks it)" "[]" "$patch_body"

rls_a_target_after="$(psql_scalar "select target_weight_kg from public.user_body_goals where id = '$rls_a_row_id';")"
assert_eq "caller A's row is unchanged after caller B's blocked cross-user PATCH attempt" "80" "$rls_a_target_after"

# ---- summary -----------------------------------------------------------------

echo "===================="
echo "PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "Failures:"
  printf ' - %s\n' "${FAILURES[@]}"
  exit 1
fi
echo "All TNYX-136 real-database assertions passed."
exit 0
