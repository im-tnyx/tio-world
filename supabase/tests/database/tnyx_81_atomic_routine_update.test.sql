\set ON_ERROR_STOP on
-- GitHub #564 / TNYX-81: disposable local SQL matrix, always rolled back.
begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.assert_raises(p_sql text, p_state text, p_message text)
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
  raise exception 'assertion failed: % (succeeded)', p_message;
end;
$$;

select pg_temp.assert_true(
  exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='user_workout_routines'
      and column_name='last_routine_update_request_hash'
      and data_type='bytea' and is_nullable='YES')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines',
    'last_routine_update_request_hash', 'UPDATE')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines',
    'last_routine_update_request_hash', 'INSERT')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines', 'composition_revision', 'UPDATE')
  and has_column_privilege('authenticated',
    'public.user_workout_routines', 'name', 'UPDATE'),
  'new hash and revision are RPC-owned while legacy Rename remains allowed'
);

select pg_temp.assert_true(
  has_function_privilege('authenticated',
    'public.update_user_workout_routine_with_composition(uuid,uuid,bigint,text,uuid,text,jsonb)',
    'EXECUTE')
  and not has_function_privilege('anon',
    'public.update_user_workout_routine_with_composition(uuid,uuid,bigint,text,uuid,text,jsonb)',
    'EXECUTE')
  and has_function_privilege('authenticated',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)',
    'EXECUTE'),
  'new RPC is authenticated only; older composition RPC remains supported'
);

insert into auth.users (id,email) values
 ('a5750000-0000-4000-8000-000000000001','atomic-routine-a@example.test'),
 ('a5750000-0000-4000-8000-000000000002','atomic-routine-b@example.test');
insert into public.user_workout_programs (id,user_id,name) values
 ('a5750000-0000-4000-8000-000000000011','a5750000-0000-4000-8000-000000000001','Program A'),
 ('a5750000-0000-4000-8000-000000000012','a5750000-0000-4000-8000-000000000002','Program B');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('a5750000-0000-4000-8000-000000000021','a5750000-0000-4000-8000-000000000001','a5750000-0000-4000-8000-000000000011','Routine A'),
 ('a5750000-0000-4000-8000-000000000022','a5750000-0000-4000-8000-000000000002','a5750000-0000-4000-8000-000000000012','Routine B');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'a5750000-0000-4000-8000-000000000001',true);

-- The existing four-arg RPC remains the initial composition writer.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5750000-0000-4000-8000-000000000021',0,
    'a5750000-0000-4000-8000-000000000091',
    '[{"id":"a5750000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[
        {"id":"a5750000-0000-4000-8000-000000000051",
         "reps":10,"set_type":"normal","reps_max":null,
         "load_kg":20,"distance_meters":null,
         "duration_seconds":null,"rest_seconds":60}]}]'::jsonb
  )=1, 'legacy composition saves with revision 1'
);

select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  1,'Routine A','a5750000-0000-4000-8000-000000000101',
  'Renamed A',null)=2, 'name-only operation increments exactly once'
);

select pg_temp.assert_true(
  (select name='Renamed A' and composition_revision=2
       and last_composition_mutation_id='a5750000-0000-4000-8000-000000000101'
       and pg_catalog.octet_length(last_routine_update_request_hash)=32
   from public.user_workout_routines
   where id='a5750000-0000-4000-8000-000000000021')
  and (select count(*)=1 from public.user_workout_routine_sets
       where id='a5750000-0000-4000-8000-000000000051'
         and reps=10),
  'name-only leaves exact Set identity and payload untouched'
);

select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  1,'Routine A','a5750000-0000-4000-8000-000000000101',
  'Renamed A',null)=2,
 'same-token name-only replay wins before stale CAS'
);

select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  1,'Routine A','a5750000-0000-4000-8000-000000000101',
  'Different A',null)$$,
 'P0001','identical token with different requested name fails'
);

-- Older phone UPDATE(name) advances the aggregate revision, clears token/hash
-- and cannot leave a retry from before the rename falsely confirmed.
update public.user_workout_routines set name='Legacy Rename A'
where id='a5750000-0000-4000-8000-000000000021';
select pg_temp.assert_true(
  (select composition_revision=3 and name='Legacy Rename A'
       and last_composition_mutation_id is null
       and last_routine_update_request_hash is null
   from public.user_workout_routines
   where id='a5750000-0000-4000-8000-000000000021'),
  'legacy name write increments revision, invalidates both replay markers'
);
update public.user_workout_routines set name='Legacy Rename A'
where id='a5750000-0000-4000-8000-000000000021';
select pg_temp.assert_true(
  (select composition_revision=3 from public.user_workout_routines
   where id='a5750000-0000-4000-8000-000000000021'),
  'legacy same-value Name update does not double-increment'
);
select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  1,'Routine A','a5750000-0000-4000-8000-000000000101',
  'Renamed A',null)$$,
 'P0001','superseded unknown Name update is not falsely confirmed'
);

-- Old composition RPC remains usable after direct Name changes.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5750000-0000-4000-8000-000000000021',3,
    'a5750000-0000-4000-8000-000000000102',
    '[{"id":"a5750000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[
        {"id":"a5750000-0000-4000-8000-000000000051",
         "reps":10,"set_type":"normal","reps_max":null,
         "load_kg":20,"distance_meters":null,
         "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=4,
  'legacy 4-argument RPC still writes after a legacy Name update'
);

select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  4,'Legacy Rename A','a5750000-0000-4000-8000-000000000103',
  null,
  '[{"id":"a5750000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"a5750000-0000-4000-8000-000000000051",
       "reps":12,"set_type":"normal","reps_max":null,
       "load_kg":20,"distance_meters":null,
       "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=5,
  'Sets-only update keeps metadata Name and advances exactly once'
);
select pg_temp.assert_true(
  (select name='Legacy Rename A' and composition_revision=5
      and pg_catalog.octet_length(last_routine_update_request_hash)=32
   from public.user_workout_routines
   where id='a5750000-0000-4000-8000-000000000021')
  and (select reps=12 from public.user_workout_routine_sets
       where id='a5750000-0000-4000-8000-000000000051'),
  'Set-only change does not rename'
);

-- Same-token set replay compares the actual persisted normalized content.
select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  4,'Legacy Rename A','a5750000-0000-4000-8000-000000000103',
  null,
  '[{"id":"a5750000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"a5750000-0000-4000-8000-000000000051",
       "reps":12,"set_type":"normal","reps_max":null,
       "load_kg":20,"distance_meters":null,
       "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=5,
 'Sets-only same-token replay is read-verified and idempotent'
);

select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  5,'Legacy Rename A','a5750000-0000-4000-8000-000000000104',
  'Combined A',
  '[{"id":"a5750000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"a5750000-0000-4000-8000-000000000051",
       "reps":14,"set_type":"normal","reps_max":null,
       "load_kg":20,"distance_meters":null,
       "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=6,
  'combined name+sets succeeds transactionally with one revision bump'
);
select pg_temp.assert_true(
  (select name='Combined A' and composition_revision=6
      and last_composition_mutation_id='a5750000-0000-4000-8000-000000000104'
      and pg_catalog.octet_length(last_routine_update_request_hash)=32
   from public.user_workout_routines
   where id='a5750000-0000-4000-8000-000000000021')
  and (select reps=14 from public.user_workout_routine_sets
       where id='a5750000-0000-4000-8000-000000000051'),
  'combined write preserves Set UUID and Name once, no double bump'
);
select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  5,'Legacy Rename A','a5750000-0000-4000-8000-000000000104',
  'Combined A',
  '[{"id":"a5750000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"a5750000-0000-4000-8000-000000000051",
       "reps":14,"set_type":"normal","reps_max":null,
       "load_kg":20,"distance_meters":null,
       "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=6,
  'combined replay works despite original stale Name and revision'
);

-- Invalid Set payload must roll Name and child writes back together.
select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  6,'Combined A','a5750000-0000-4000-8000-000000000105',
  'Must Roll Back',
  '[{"id":"a5750000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"a5750000-0000-4000-8000-000000000051",
       "reps":0}]}]'::jsonb)$$,
 '22023','invalid combined Set change rejects entire new operation'
);
select pg_temp.assert_true(
  (select name='Combined A' and composition_revision=6
      and last_composition_mutation_id='a5750000-0000-4000-8000-000000000104'
   from public.user_workout_routines
   where id='a5750000-0000-4000-8000-000000000021')
  and (select reps=14 from public.user_workout_routine_sets
       where id='a5750000-0000-4000-8000-000000000051'),
  'failed combined write neither renames nor changes Sets or replay state'
);

select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000012',
  6,'Combined A','a5750000-0000-4000-8000-000000000105',
  'Wrong Program',null)$$,
 'P0002','wrong Program identity is not found'
);
select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000022',
  'a5750000-0000-4000-8000-000000000012',
  0,'Routine B','a5750000-0000-4000-8000-000000000105',
  'Cross Owner',null)$$,
 'P0002','cross-owner Routine is indistinguishable from missing'
);
select pg_temp.assert_raises(
 $$update public.user_workout_routines
 set last_routine_update_request_hash = '\x00'::bytea
 where id='a5750000-0000-4000-8000-000000000021'$$,
 '42501','client cannot inject direct request hash'
);
select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  5,'Legacy Rename A','a5750000-0000-4000-8000-000000000105',
  'Stale',null)$$,
 'P0001','new token with stale expected revision/name must conflict'
);

reset role;
set local role anon;
select pg_temp.assert_raises(
 $$select public.update_user_workout_routine_with_composition(
  'a5750000-0000-4000-8000-000000000021',
  'a5750000-0000-4000-8000-000000000011',
  6,'Combined A','a5750000-0000-4000-8000-000000000106',
  'Forbidden',null)$$,
 '42501','anon cannot execute new RPC'
);
rollback;
