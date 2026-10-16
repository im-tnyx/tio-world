\set ON_ERROR_STOP on
-- #578 P2: account-lifetime 20k Routine identity budget, covering active +
-- permanent tombstones, direct metadata INSERT, atomic Create and multi-row
-- INSERT. Local disposable DB only. The entire fixture rolls back.
begin;

create function pg_temp.assert_true(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_label;
  end if;
end;
$$;
create function pg_temp.expect_state(p_sql text, p_state text, p_label text)
returns void language plpgsql as $$
declare v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then return; end if;
    raise exception 'assertion failed: % expected %, got %',
      p_label, p_state, v_state;
  end;
  raise exception 'assertion failed: % (succeeded)', p_label;
end;
$$;

select pg_temp.assert_true(
  not has_function_privilege('authenticated',
    'private.enforce_user_workout_routine_identity_budget()', 'EXECUTE')
  and not has_function_privilege('anon',
    'private.enforce_user_workout_routine_identity_budget()', 'EXECUTE')
  and exists(select 1 from pg_trigger
    where tgrelid='public.user_workout_routines'::regclass
      and tgname='trg_user_workout_routines_identity_budget'
      and tgenabled='O'),
  'budget trigger is active; internal enforcement is not client callable'
);

insert into auth.users(id,email) values
 ('d5280000-0000-4000-8000-000000000001','routine-budget-owner@example.test'),
 ('d5280000-0000-4000-8000-000000000002','routine-budget-other@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('d5280000-0000-4000-8000-000000000011',
  'd5280000-0000-4000-8000-000000000001','Budget Owner Program'),
 ('d5280000-0000-4000-8000-000000000012',
  'd5280000-0000-4000-8000-000000000002','Budget Other Program');

-- Efficient, administrator-only local fixture. Trigger disabling is strictly
-- inside this rollback transaction and only to seed a near-boundary state.
-- Both protection triggers are restored BEFORE any authenticated action.
alter table public.user_workout_routines
  disable trigger trg_user_workout_routines_reject_retired_identity;
alter table public.user_workout_routines
  disable trigger trg_user_workout_routines_identity_budget;
insert into public.user_workout_routines(id,user_id,program_id,name)
select pg_catalog.md5('budget-seed-'||n::text)::uuid,
 'd5280000-0000-4000-8000-000000000001'::uuid,
 'd5280000-0000-4000-8000-000000000011'::uuid,
 'Seed '||n::text
from generate_series(1,19999) n;
alter table public.user_workout_routines
  enable trigger trg_user_workout_routines_reject_retired_identity;
alter table public.user_workout_routines
  enable trigger trg_user_workout_routines_identity_budget;

select pg_temp.assert_true(
  (select count(*)=19999 from public.user_workout_routines
    where user_id='d5280000-0000-4000-8000-000000000001')
  and (select count(*)=0 from private.deleted_user_workout_routine_ids
    where user_id='d5280000-0000-4000-8000-000000000001'),
  '19999 active Routines are counted before boundary tests'
);

set local role authenticated;
select set_config('request.jwt.claim.sub',
 'd5280000-0000-4000-8000-000000000001', true);

-- The statement-level transition table must prevent a 2-row bulk INSERT
-- from bypassing the final single-identity allowance.
select pg_temp.expect_state($cmd$
 insert into public.user_workout_routines(id,user_id,program_id,name)
 values
  ('d5280000-0000-4000-8000-000000000021',
   'd5280000-0000-4000-8000-000000000001',
   'd5280000-0000-4000-8000-000000000011','Batch first'),
  ('d5280000-0000-4000-8000-000000000022',
   'd5280000-0000-4000-8000-000000000001',
   'd5280000-0000-4000-8000-000000000011','Batch second')
$cmd$, 'P0001', 'multi-row INSERT cannot overshoot lifetime identity budget');
select pg_temp.assert_true(
  (select count(*)=19999 from public.user_workout_routines
    where user_id='d5280000-0000-4000-8000-000000000001'),
  'oversized batch rolls back all inserted Routines'
);

-- Atomic Create must remain compatible and fill the final available slot.
select pg_temp.assert_true(
 public.create_user_workout_routine_with_composition(
  'd5280000-0000-4000-8000-000000000023',
  'd5280000-0000-4000-8000-000000000011',
  'Boundary',
  'd5280000-0000-4000-8000-000000000091',
  '[{"id":"d5280000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"d5280000-0000-4000-8000-000000000051","reps":10}]}]'::jsonb
 )=1, 'atomic Create fills the 20000th owner identity'
);
-- Even at capacity an identical Create is still an idempotent no-op.
select pg_temp.assert_true(
 public.create_user_workout_routine_with_composition(
  'd5280000-0000-4000-8000-000000000023',
  'd5280000-0000-4000-8000-000000000011',
  'Boundary',
  'd5280000-0000-4000-8000-000000000091',
  '[{"id":"d5280000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"d5280000-0000-4000-8000-000000000051","reps":10}]}]'::jsonb
 )=1, 'idempotent atomic Create still replays exactly at identity cap'
);

select pg_temp.expect_state($cmd$
 insert into public.user_workout_routines(id,user_id,program_id,name)
 values ('d5280000-0000-4000-8000-000000000024',
   'd5280000-0000-4000-8000-000000000001',
   'd5280000-0000-4000-8000-000000000011','Over cap')
$cmd$, 'P0001', 'direct authenticated Create is rejected at identity cap');

select pg_temp.expect_state($cmd$
 select public.create_user_workout_routine_with_composition(
  'd5280000-0000-4000-8000-000000000025',
  'd5280000-0000-4000-8000-000000000011',
  'Atomic over cap',
  'd5280000-0000-4000-8000-000000000092',
  '[{"id":"d5280000-0000-4000-8000-000000000042",
     "exercise_ref":"ex_squat","sets":[
      {"id":"d5280000-0000-4000-8000-000000000052","reps":10}]}]'::jsonb
 )
$cmd$, 'P0001', 'atomic Create is rejected at identity cap');

-- Deleting one does not reclaim its UUID. Permanent retention is exactly
-- why the cumulative cap has to include active plus retired identities.
select pg_temp.assert_true(
 public.delete_user_workout_routine(
  'd5280000-0000-4000-8000-000000000023',
  'd5280000-0000-4000-8000-000000000011', 1),
 'Delete is still permitted at owner identity cap'
);
select pg_temp.expect_state($cmd$
 insert into public.user_workout_routines(id,user_id,program_id,name)
 values ('d5280000-0000-4000-8000-000000000026',
   'd5280000-0000-4000-8000-000000000001',
   'd5280000-0000-4000-8000-000000000011','Replay storage after Delete')
$cmd$, 'P0001','deletion cannot reset permanent identity quota');

reset role;
select pg_temp.assert_true(
 (select count(*)=19999 from public.user_workout_routines
  where user_id='d5280000-0000-4000-8000-000000000001')
 and (select count(*)=1 from private.deleted_user_workout_routine_ids
  where user_id='d5280000-0000-4000-8000-000000000001'),
 '20k active-plus-retired identities, with no post-delete leakage'
);

set local role authenticated;
select set_config('request.jwt.claim.sub',
 'd5280000-0000-4000-8000-000000000002', true);
insert into public.user_workout_routines(id,user_id,program_id,name)
values ('d5280000-0000-4000-8000-000000000027',
 'd5280000-0000-4000-8000-000000000002',
 'd5280000-0000-4000-8000-000000000012','Other owner unaffected');
reset role;
select pg_temp.assert_true(
 (select count(*)=1 from public.user_workout_routines where
  user_id='d5280000-0000-4000-8000-000000000002'),
 'owner budget does not block another owner'
);
rollback;
