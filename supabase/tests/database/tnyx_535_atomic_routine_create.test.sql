\set ON_ERROR_STOP on

-- GitHub #535: disposable transaction-scoped tests for atomic Routine Create.
begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.assert_raises(
  p_sql text, p_state text, p_message text
)
returns void language plpgsql as $$
declare v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then return; end if;
    raise exception 'assertion failed: % expected %, got %',
      p_message, p_state, v_state;
  end;
  raise exception 'assertion failed: % (operation succeeded)', p_message;
end;
$$;

select pg_temp.assert_true(
  has_function_privilege(
    'authenticated',
    'public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb)',
    'EXECUTE'
  ),
  'only authenticated may execute the narrow create RPC'
);

select pg_temp.assert_true(
  (select p.prosecdef and p.proconfig @> array['search_path=""']
   from pg_proc as p where p.oid =
     'public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb)'::regprocedure),
  'create RPC must be SECURITY DEFINER with empty search_path'
);

insert into auth.users (id,email) values
 ('a5350000-0000-4000-8000-000000000001','issue535-owner@example.test'),
 ('a5350000-0000-4000-8000-000000000002','issue535-foreign@example.test');

insert into public.user_workout_programs (id,user_id,name) values
 ('a5350000-0000-4000-8000-000000000011','a5350000-0000-4000-8000-000000000001','Owner Program'),
 ('a5350000-0000-4000-8000-000000000012','a5350000-0000-4000-8000-000000000002','Foreign Program');

insert into public.user_workout_exercises
 (id,user_id,display_name,status) values
 ('a5350000-0000-4000-8000-000000000031','a5350000-0000-4000-8000-000000000001','Owner Active','active'),
 ('a5350000-0000-4000-8000-000000000032','a5350000-0000-4000-8000-000000000001','Owner Archived','archived'),
 ('a5350000-0000-4000-8000-000000000033','a5350000-0000-4000-8000-000000000002','Foreign Active','active');

set local role authenticated;
select set_config('request.jwt.claim.sub','a5350000-0000-4000-8000-000000000001',true);

-- Name alone (or malformed/blank input) must never leave an empty Routine.
select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Routine 1','a5350000-0000-4000-8000-000000000091','[]'::jsonb
  )
$sql$, '22023', 'zero Exercise entries must be rejected');

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    '  ','a5350000-0000-4000-8000-000000000091',
    '[{"id":"a5350000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )
$sql$, '22023', 'blank Routine name must be rejected');

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Routine 1','a5350000-0000-4000-8000-000000000091',
    '{"unexpected":"object"}'::jsonb
  )
$sql$, '22023', 'nonarray Exercise payload must be rejected');

select pg_temp.assert_true(
 (select count(*) = 0 from public.user_workout_routines
   where user_id='a5350000-0000-4000-8000-000000000001'),
 'bad inputs must not insert metadata'
);

-- Foreign Program must be hidden, not writable through DEFINER privileges.
select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000012',
    'Wrong owner','a5350000-0000-4000-8000-000000000091',
    '[{"id":"a5350000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )
$sql$, 'P0002', 'other owner Program must be rejected');

-- Missing, archived, and foreign Custom refs cannot produce even a
-- transient committed metadata-only Routine.
select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000022',
    'a5350000-0000-4000-8000-000000000011',
    'Archived','a5350000-0000-4000-8000-000000000092',
    '[{"id":"a5350000-0000-4000-8000-000000000042",
       "exercise_ref":"a5350000-0000-4000-8000-000000000032","sets":[]}]'::jsonb
  )
$sql$, 'P0002', 'archived Custom ref must fail closed');

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000023',
    'a5350000-0000-4000-8000-000000000011',
    'Foreign','a5350000-0000-4000-8000-000000000093',
    '[{"id":"a5350000-0000-4000-8000-000000000043",
       "exercise_ref":"a5350000-0000-4000-8000-000000000033","sets":[]}]'::jsonb
  )
$sql$, 'P0002', 'foreign Custom ref must fail closed');

select pg_temp.assert_true(
 (select count(*)=0 from public.user_workout_routines
  where id in (
    'a5350000-0000-4000-8000-000000000022'::uuid,
    'a5350000-0000-4000-8000-000000000023'::uuid
  )),
 'archived and foreign Custom failures must roll back metadata'
);

-- Existing writer validates all entry and Set IDs. Create must roll back
-- its metadata insert if any later canonical composition check rejects.
select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000024',
    'a5350000-0000-4000-8000-000000000011',
    'Invalid Entries','a5350000-0000-4000-8000-000000000094',
    '[{"id":"a5350000-0000-4000-8000-000000000044",
       "exercise_ref":"ex_squat","sets":[]},
      {"id":"a5350000-0000-4000-8000-000000000044",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )
$sql$, '22023', 'duplicate Exercise entry UUIDs must roll back all');

select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_routines
   where id='a5350000-0000-4000-8000-000000000024'),
  'canonical validation failure must not leave empty metadata'
);

-- A valid catalog Exercise with zero Sets is sufficient: no invented
-- mandatory Set/reps requirement in the screenshot-backed approval.
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Routine 1','a5350000-0000-4000-8000-000000000091',
    '[{"id":"a5350000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )=1, 'one selected catalog Exercise must atomically create'
);

select pg_temp.assert_true(
  (select count(*)=1 from public.user_workout_routines
   where id='a5350000-0000-4000-8000-000000000021'
     and user_id='a5350000-0000-4000-8000-000000000001'
     and program_id='a5350000-0000-4000-8000-000000000011'
     and name='Routine 1' and composition_revision=1
     and last_composition_mutation_id='a5350000-0000-4000-8000-000000000091')
  and (select count(*)=1 from public.user_workout_routine_exercises
       where routine_id='a5350000-0000-4000-8000-000000000021'
         and id='a5350000-0000-4000-8000-000000000041'
         and position=0 and catalog_exercise_id='ex_squat')
  and (select count(*)=0 from public.user_workout_routine_sets
       where user_id='a5350000-0000-4000-8000-000000000001'),
  'one RPC transaction must commit metadata and ordered Exercise together'
);

-- Retried exact mutation cannot duplicate Routine or silently overwrite.
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Routine 1','a5350000-0000-4000-8000-000000000091',
    '[{"id":"a5350000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )=1, 'same exact RPC call must be idempotent'
);

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Changed Name','a5350000-0000-4000-8000-000000000091',
    '[{"id":"a5350000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )
$sql$, 'P0001', 'same token with different name is not a replay');

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Routine 1','a5350000-0000-4000-8000-000000000099',
    '[{"id":"a5350000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )
$sql$, 'P0001', 'same Routine UUID with another mutation must fail');

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000021',
    'a5350000-0000-4000-8000-000000000011',
    'Routine 1','a5350000-0000-4000-8000-000000000091',
    '[{"id":"a5350000-0000-4000-8000-000000000045",
       "exercise_ref":"ex_squat","sets":[]}]'::jsonb
  )
$sql$, 'P0001', 'same mutation but different entry UUID is not a replay');

-- Active Custom may be saved; later lifecycle archive must not revoke
-- idempotent replay of that already-confirmed create.
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000025',
    'a5350000-0000-4000-8000-000000000011',
    'My Custom','a5350000-0000-4000-8000-000000000095',
    '[{"id":"a5350000-0000-4000-8000-000000000046",
       "exercise_ref":"a5350000-0000-4000-8000-000000000031","sets":[]}]'::jsonb
  )=1, 'active owner Custom Exercise is eligible for first create'
);

update public.user_workout_exercises
set status='archived'
where id='a5350000-0000-4000-8000-000000000031';

select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'a5350000-0000-4000-8000-000000000025',
    'a5350000-0000-4000-8000-000000000011',
    'My Custom','a5350000-0000-4000-8000-000000000095',
    '[{"id":"a5350000-0000-4000-8000-000000000046",
       "exercise_ref":"a5350000-0000-4000-8000-000000000031","sets":[]}]'::jsonb
  )=1, 'same proven create replay remains valid after later archive'
);

select pg_temp.assert_true(
  (select count(*)=2 from public.user_workout_routines
   where user_id='a5350000-0000-4000-8000-000000000001')
  and (select count(*)=2 from public.user_workout_routine_exercises
   where user_id='a5350000-0000-4000-8000-000000000001'),
  'replays and failures must not duplicate or leak rows'
);

rollback;
\echo 'GitHub #535 atomic Routine Create SQL matrix passed.'
