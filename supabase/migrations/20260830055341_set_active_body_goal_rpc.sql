-- Add a single atomic post-onboarding Body Goal transition RPC.
--
-- Replaces the previous client-side two-request reconciliation (update the
-- old active goal to superseded, then insert the new one as two separate
-- PostgREST requests) with one Postgres transaction, closing the window
-- where a failure between the two requests could leave an account with
-- zero active Body Goals. See TNYX-136 for the full frozen contract.
--
-- SECURITY INVOKER (not DEFINER): the function runs with the calling
-- authenticated role's own privileges so the existing own-row RLS policies
-- on public.users, public.user_body_goals, and public.body_weight_logs
-- remain the enforcement boundary; the function does not bypass RLS.

create or replace function public.set_active_body_goal(
  p_goal_type text,
  p_target_weight_kg numeric,
  p_weekly_weight_change_kg numeric
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_active public.user_body_goals%rowtype;
  v_had_active boolean;
  v_is_directional boolean;
  v_latest_weight_kg numeric;
  v_now timestamptz := now();
begin
  if v_user_id is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Stable per-user serialization: lock the caller's canonical users row
  -- before touching any Body Goal state. This also correctly serializes the
  -- first-goal-creation case, where there is no user_body_goals row yet to
  -- lock directly (locking only an existing active goal row would miss
  -- concurrent first-goal creation, since there would be nothing to lock).
  perform 1 from public.users where id = v_user_id for update;
  if not found then
    raise exception 'Canonical account not found' using errcode = 'P0001';
  end if;

  if p_goal_type is null
      or p_goal_type not in ('lose_weight', 'gain_weight', 'maintain_weight') then
    raise exception 'invalid_goal_type' using errcode = 'P0001';
  end if;

  v_is_directional := p_goal_type in ('lose_weight', 'gain_weight');

  if v_is_directional then
    if p_target_weight_kg is null or p_weekly_weight_change_kg is null then
      raise exception 'directional_goal_requires_target_and_pace'
        using errcode = 'P0001';
    end if;
    if p_target_weight_kg < 30.0 or p_target_weight_kg > 200.0 then
      raise exception 'target_weight_out_of_range' using errcode = 'P0001';
    end if;
    if p_weekly_weight_change_kg < 0.1 or p_weekly_weight_change_kg > 1.5 then
      raise exception 'goal_pace_out_of_range' using errcode = 'P0001';
    end if;
    -- NUMERIC-safe 0.1 kg/week increment check (no floating-point epsilon
    -- logic): round(numeric, 1) is exact decimal rounding, so this rejects
    -- 0.15 / 0.25 / 1.05 and accepts 0.1, 0.2, ..., 1.5 exactly.
    if round(p_weekly_weight_change_kg, 1) <> p_weekly_weight_change_kg then
      raise exception 'goal_pace_invalid_increment' using errcode = 'P0001';
    end if;
  else
    if p_target_weight_kg is not null or p_weekly_weight_change_kg is not null then
      raise exception 'maintain_goal_cannot_carry_target_or_pace'
        using errcode = 'P0001';
    end if;
  end if;

  select *
  into v_active
  from public.user_body_goals
  where user_id = v_user_id and status = 'active';
  -- Capture FOUND immediately: it is a single shared PL/pgSQL variable that
  -- the next SELECT below would otherwise silently overwrite.
  v_had_active := found;

  -- Direction validation always uses the latest canonical Current Weight,
  -- never a fabricated value, whether this is a same-goal edit or a new
  -- directional goal -- a persisted directional target must always be
  -- truthfully consistent with the account's actual current weight.
  if v_is_directional then
    select weight_kg
    into v_latest_weight_kg
    from public.body_weight_logs
    where user_id = v_user_id
    order by measured_at desc
    limit 1;

    if v_latest_weight_kg is null then
      raise exception 'directional_goal_requires_current_weight'
        using errcode = 'P0001';
    end if;
    if p_goal_type = 'lose_weight' and p_target_weight_kg >= v_latest_weight_kg then
      raise exception 'target_weight_must_be_below_current_for_lose'
        using errcode = 'P0001';
    end if;
    if p_goal_type = 'gain_weight' and p_target_weight_kg <= v_latest_weight_kg then
      raise exception 'target_weight_must_be_above_current_for_gain'
        using errcode = 'P0001';
    end if;
  end if;

  if v_had_active and v_active.goal_type = p_goal_type then
    -- Same active goal type: update user-editable fields in place. Row
    -- identity, starting_weight_kg (including a historical null), started_at,
    -- and intent_rank are all preserved exactly -- never backfilled or
    -- reordered by an ordinary same-goal edit.
    update public.user_body_goals
    set target_weight_kg = p_target_weight_kg,
        weekly_weight_change_kg = p_weekly_weight_change_kg
    where id = v_active.id;
    return;
  end if;

  -- Changed goal type, legacy Recomposition transitioning away, or no prior
  -- active goal: supersede the previous active row (if any) and insert
  -- exactly one new active row, all within this same transaction. If any
  -- statement below raises, the whole transaction -- including the
  -- supersede above -- rolls back, so the previous active goal is never
  -- left superseded without a replacement.
  if v_is_directional and v_latest_weight_kg is null then
    -- Already rejected above, but keep this invariant explicit: a
    -- directional first/changed goal never proceeds without a real weight.
    raise exception 'directional_goal_requires_current_weight'
      using errcode = 'P0001';
  end if;

  if v_had_active then
    update public.user_body_goals
    set status = 'superseded', ended_at = v_now
    where id = v_active.id;
  end if;

  insert into public.user_body_goals (
    user_id, goal_type, starting_weight_kg, target_weight_kg,
    weekly_weight_change_kg, intent_rank, status, started_at
  ) values (
    v_user_id,
    p_goal_type,
    v_latest_weight_kg,
    p_target_weight_kg,
    p_weekly_weight_change_kg,
    case when v_had_active then v_active.intent_rank else null end,
    'active',
    v_now
  );
end;
$$;

revoke all on function public.set_active_body_goal(text, numeric, numeric) from public;
revoke all on function public.set_active_body_goal(text, numeric, numeric) from anon;
grant execute on function public.set_active_body_goal(text, numeric, numeric) to authenticated;

comment on function public.set_active_body_goal(text, numeric, numeric) is
  'Atomic post-onboarding Body Goal transition for the authenticated caller (auth.uid()). Same goal type updates target/pace in place; a changed goal type supersedes the previous active row and inserts a new one in the same transaction, snapshotting starting_weight_kg from the latest public.body_weight_logs row. See TNYX-136.';
