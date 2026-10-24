\set ON_ERROR_STOP on
-- #569 staged atomic Create Program & Move Routine SQL matrix.
-- Runs ONLY in disposable CI/local database; all fixture writes and test
-- EXECUTE grants are inside this one transaction and rolled back.
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
    raise exception 'assertion failed: %, expected %, actual %',
      p_label, p_state, v_state;
  end;
  raise exception 'assertion failed: % (unexpectedly committed)', p_label;
end;
$$;

select pg_temp.assert_true(
  not has_function_privilege('authenticated',
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)', 'EXECUTE')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines','program_id','UPDATE')
  and not has_table_privilege('authenticated',
    'public.user_workout_programs','DELETE')
  and not has_table_privilege('authenticated',
    'public.user_workout_programs','INSERT')
  and has_column_privilege('authenticated',
    'public.user_workout_programs','id','INSERT')
  and has_column_privilege('authenticated',
    'public.user_workout_programs','user_id','INSERT')
  and has_column_privilege('authenticated',
    'public.user_workout_programs','name','INSERT')
  and not has_column_privilege('authenticated',
    'public.user_workout_programs','is_default','INSERT')
  and not has_column_privilege('authenticated',
    'public.user_workout_programs','is_default','UPDATE'),
  'staged function dormant, direct Routine reparent denied, Program INSERT restricted to id/user_id/name, is_default frozen');

select pg_temp.assert_true(
  (select count(*) = 9
    from information_schema.columns
    where table_schema='public' and table_name='user_workout_programs')
  and exists (
    select 1
    from information_schema.columns
    where table_schema='public' and table_name='user_workout_programs'
      and column_name='is_default' and data_type='boolean'
  ),
  'Program schema contains six baseline plus three M5B provenance columns');

-- CI-only transactional grants. No production client capability is published.
grant execute on function public.create_user_workout_program_and_move_routine(
 uuid,uuid,uuid,text,bigint,uuid) to authenticated;
grant execute on function public.move_user_workout_routine(
 uuid,uuid,uuid,bigint,uuid) to authenticated;

insert into auth.users(id,email) values
 ('b5690000-0000-4000-8000-000000000001','newmove-owner-a@example.test'),
 ('b5690000-0000-4000-8000-000000000002','newmove-owner-b@example.test');
insert into public.user_workout_programs(id,user_id,name,is_default) values
 ('b5690000-0000-4000-8000-000000000011','b5690000-0000-4000-8000-000000000001','Source A', true),
 ('b5690000-0000-4000-8000-000000000012','b5690000-0000-4000-8000-000000000002','Source B', false),
 ('b5690000-0000-4000-8000-000000000013','b5690000-0000-4000-8000-000000000001','Other A', false);

insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('b5690000-0000-4000-8000-000000000021','b5690000-0000-4000-8000-000000000001','b5690000-0000-4000-8000-000000000011','My Routine'),
 ('b5690000-0000-4000-8000-000000000022','b5690000-0000-4000-8000-000000000002','b5690000-0000-4000-8000-000000000012','Foreign Routine');

set local role authenticated;
select set_config('request.jwt.claim.sub',
 'b5690000-0000-4000-8000-000000000001',true);

select pg_temp.expect_state(
  $$update public.user_workout_programs
    set is_default = true
    where id='b5690000-0000-4000-8000-000000000013'$$,
  '42501','authenticated cannot mint a second default beside Create & Move');

-- Test the real composed aggregate (stable Exercise & Set IDs through move).
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'b5690000-0000-4000-8000-000000000021',0,
    'b5690000-0000-4000-8000-000000000090',
    '[{"id":"b5690000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_squat","sets":[
         {"id":"b5690000-0000-4000-8000-000000000051",
          "reps":8,"set_type":"normal","reps_max":null,
          "load_kg":40,"distance_meters":null,
          "duration_seconds":null,"rest_seconds":90}]}]'::jsonb) = 1,
  'source Routine has revision 1 with saved composition');

-- Negative matrix before any Program INSERT.
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     null,'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000031','Program 1',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  '22023','null Routine rejected');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000031','   ',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  '22023','blank name rejected');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000011','Program 1',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  '22023','same source and new ID forbidden');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000031','Program 1',0,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0001','stale revision cannot strand Program');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000012',
     'b5690000-0000-4000-8000-000000000031','Program 1',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0002','foreign source Program not visible');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000022',
     'b5690000-0000-4000-8000-000000000012',
     'b5690000-0000-4000-8000-000000000031','Program 1',0,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0002','foreign Routine cannot be moved');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000012','Collision',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0001','foreign Program UUID collision cannot overwrite');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000013','Collision',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0001','owned Program UUID collision cannot be claimed as fresh create');
select pg_temp.assert_true(
  (select count(*)=2 from public.user_workout_programs where user_id=auth.uid())
   and (select program_id='b5690000-0000-4000-8000-000000000011'
      and composition_revision=1 from public.user_workout_routines
       where id='b5690000-0000-4000-8000-000000000021'),
  'all failed requests preserve exactly two owner-visible Programs and source Routine');
-- Post-rollback sanity. pg_temp.expect_state already caught the rejection
-- inside a subtransaction, so this read cannot see a committed failed write.
select pg_temp.assert_true(
  (select count(*)=1 from public.user_workout_programs
    where user_id='b5690000-0000-4000-8000-000000000001' and is_default)
  and (select is_default from public.user_workout_programs
    where id='b5690000-0000-4000-8000-000000000011'),
  'post-rollback sanity: rejected Create & Move leaves the canonical default on the source Program');

-- Late atomicity regression: force the Routine UPDATE to fail AFTER the
-- server has INSERTed the proposed Program in the same statement.
-- The exception caught by pg_temp.expect_state must roll both writes back.
reset role;
create function pg_temp.reject_atomic_move_after_insert()
returns trigger language plpgsql as $tnyx_atomic_trigger$
begin
  if new.program_id='b5690000-0000-4000-8000-000000000032'::uuid then
    raise exception 'synthetic move rejects after Program INSERT'
      using errcode = '23514';
  end if;
  return new;
end;
$tnyx_atomic_trigger$;
create trigger tnyx_569_atomic_late_failure_fixture
before update on public.user_workout_routines
for each row execute function pg_temp.reject_atomic_move_after_insert();
set local role authenticated;

select pg_temp.expect_state(
  $tnyx_atomic_query$select public.create_user_workout_program_and_move_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000011',
    'b5690000-0000-4000-8000-000000000032',
    'Must Not Persist',1,'b5690000-0000-4000-8000-000000000109')$tnyx_atomic_query$,
  '23514','Routine UPDATE failure aborts Program INSERT as one transaction');

select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_programs
     where id='b5690000-0000-4000-8000-000000000032')
  and (select program_id='b5690000-0000-4000-8000-000000000011'
     and composition_revision=1
     from public.user_workout_routines
     where id='b5690000-0000-4000-8000-000000000021')
  and (select count(*)=1 from public.user_workout_routine_exercises
     where routine_id='b5690000-0000-4000-8000-000000000021'
       and id='b5690000-0000-4000-8000-000000000041')
  and (select count(*)=1 from public.user_workout_routine_sets
     where routine_exercise_id='b5690000-0000-4000-8000-000000000041'
       and id='b5690000-0000-4000-8000-000000000051'),
  'late rejected Move leaves no empty Program and preserves child identities');
-- Post-rollback sanity. expect_state already rolled the rejected INSERT back.
select pg_temp.assert_true(
  (select count(*)=1 from public.user_workout_programs
    where user_id='b5690000-0000-4000-8000-000000000001' and is_default)
  and not exists (
    select 1 from public.user_workout_programs
    where id='b5690000-0000-4000-8000-000000000032'),
  'post-rollback sanity: rolled-back Program INSERT does not create or replace the default');

reset role;
drop trigger tnyx_569_atomic_late_failure_fixture
  on public.user_workout_routines;
set local role authenticated;

-- Success is atomic and preserves all Routine child identities/prescriptions.
select pg_temp.assert_true(
  public.create_user_workout_program_and_move_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000011',
    'b5690000-0000-4000-8000-000000000031',
    'Program 1',1,'b5690000-0000-4000-8000-000000000101') = 2,
  'new owned Program and Routine move committed together');
select pg_temp.assert_true(
  (select count(*)=1 from public.user_workout_programs
    where id='b5690000-0000-4000-8000-000000000031'
      and user_id='b5690000-0000-4000-8000-000000000001'
      and name='Program 1')
  and (select program_id='b5690000-0000-4000-8000-000000000031'
      and composition_revision=2
      and last_composition_mutation_id='b5690000-0000-4000-8000-000000000101'
      and pg_catalog.octet_length(last_routine_update_request_hash)=32
     from public.user_workout_routines
     where id='b5690000-0000-4000-8000-000000000021')
  and (select count(*)=1 from public.user_workout_routine_exercises
       where id='b5690000-0000-4000-8000-000000000041'
         and routine_id='b5690000-0000-4000-8000-000000000021'
         and position=0)
  and (select count(*)=1 from public.user_workout_routine_sets
       where id='b5690000-0000-4000-8000-000000000051'
         and routine_exercise_id='b5690000-0000-4000-8000-000000000041'
         and reps=8 and load_kg=40 and rest_seconds=90),
  'atomic success preserves original Routine, Exercise and Set IDs and prescription');
select pg_temp.assert_true(
  (select is_default = false and name='Program 1'
    from public.user_workout_programs
    where id='b5690000-0000-4000-8000-000000000031')
  and (select count(*)=1 from public.user_workout_programs
    where user_id='b5690000-0000-4000-8000-000000000001' and is_default)
  and (select is_default from public.user_workout_programs
    where id='b5690000-0000-4000-8000-000000000011'),
  'Create & Move destination is not a second canonical default');

select pg_temp.assert_true(
 public.create_user_workout_program_and_move_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000011',
    'b5690000-0000-4000-8000-000000000031',
    'Program 1',1,'b5690000-0000-4000-8000-000000000101')=2,
 'exact identical retry confirms revision without creating another Program');
select pg_temp.assert_true(
 (select count(*)=3 from public.user_workout_programs where user_id=auth.uid())
 and (select count(*)=1 from public.user_workout_programs
    where user_id=auth.uid() and is_default),
 'identical replay leaves exactly three owner-visible Programs and one default');

select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000031','Changed name',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0001','same mutation UUID cannot change original name');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000031','Program 1',1,
     'b5690000-0000-4000-8000-000000000102')$$,
  'P0002','new mutation token cannot claim an already moved Routine');

-- Name-only Program Rename is independent of immutable exact Create+Move proof.
update public.user_workout_programs
set name='My Edited Program' where id='b5690000-0000-4000-8000-000000000031';
select pg_temp.assert_true(
 public.create_user_workout_program_and_move_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000011',
    'b5690000-0000-4000-8000-000000000031',
    'Program 1',1,'b5690000-0000-4000-8000-000000000101')=2,
 'replay proves original Create+Move after user renames destination');

-- Exact committed replay must survive a deleted *old source* Program.
-- The privileged fixture moves the canonical default from 011 to 013 before
-- deleting 011. That keeps the canonical default present while proving 031
-- is not promoted. A zero-default owner is a separate #568 lazy-resolver
-- state and is not covered here. The savepoint still isolates the delete
-- from the subsequent Move regression.
savepoint replay_without_source;
reset role;
update public.user_workout_programs
  set is_default = false
  where id = 'b5690000-0000-4000-8000-000000000011';
update public.user_workout_programs
  set is_default = true
  where id = 'b5690000-0000-4000-8000-000000000013';
delete from public.user_workout_programs
where id='b5690000-0000-4000-8000-000000000011';
set local role authenticated;

select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_programs
    where id='b5690000-0000-4000-8000-000000000011'),
  'source Program is gone before exact Create+Move replay');

select pg_temp.assert_true(
  public.create_user_workout_program_and_move_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000011',
    'b5690000-0000-4000-8000-000000000031',
    'Program 1',1,'b5690000-0000-4000-8000-000000000101')=2,
  'latest exact retry still succeeds after source Program was deleted');

select pg_temp.assert_true(
  (select count(*)=2 from public.user_workout_programs
    where user_id=auth.uid())
  and (select program_id='b5690000-0000-4000-8000-000000000031'
       and composition_revision=2
       from public.user_workout_routines
       where id='b5690000-0000-4000-8000-000000000021')
  and (select count(*)=1 from public.user_workout_routine_exercises
       where id='b5690000-0000-4000-8000-000000000041'
         and routine_id='b5690000-0000-4000-8000-000000000021')
  and (select count(*)=1 from public.user_workout_routine_sets
       where id='b5690000-0000-4000-8000-000000000051'
         and routine_exercise_id='b5690000-0000-4000-8000-000000000041')
  and (select is_default = false from public.user_workout_programs
       where id='b5690000-0000-4000-8000-000000000031')
  and (select count(*)=1 from public.user_workout_programs
       where user_id=auth.uid() and is_default)
  and (select is_default from public.user_workout_programs
       where id='b5690000-0000-4000-8000-000000000013'),
  'source-deleted retry does not promote 031; the moved default remains 013');

select pg_temp.expect_state(
  $tnyx_deleted_source_retry$select public.create_user_workout_program_and_move_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000011',
    'b5690000-0000-4000-8000-000000000031',
    'Changed after source deletion',1,
    'b5690000-0000-4000-8000-000000000101')$tnyx_deleted_source_retry$,
  'P0001','same mutation with changed payload rejected after source deletion');

rollback to savepoint replay_without_source;
release savepoint replay_without_source;

-- Another aggregate mutation invalidates any stale earlier success proof.
select pg_temp.assert_true(
 public.move_user_workout_routine(
    'b5690000-0000-4000-8000-000000000021',
    'b5690000-0000-4000-8000-000000000031',
    'b5690000-0000-4000-8000-000000000013',
     2,'b5690000-0000-4000-8000-000000000103')=3,
 'subsequent ordinary Move advances aggregate revision');
select pg_temp.expect_state(
  $$select public.create_user_workout_program_and_move_routine(
     'b5690000-0000-4000-8000-000000000021',
     'b5690000-0000-4000-8000-000000000011',
     'b5690000-0000-4000-8000-000000000031','Program 1',1,
     'b5690000-0000-4000-8000-000000000101')$$,
  'P0002','old Create+Move token cannot claim success after later Move');
select pg_temp.assert_true(
  (select count(*)=3 from public.user_workout_programs where user_id=auth.uid())
  and (select program_id='b5690000-0000-4000-8000-000000000013'
       and composition_revision=3
      from public.user_workout_routines
      where id='b5690000-0000-4000-8000-000000000021')
  and (select is_default from public.user_workout_programs
      where id='b5690000-0000-4000-8000-000000000011')
  and not (select is_default from public.user_workout_programs
      where id='b5690000-0000-4000-8000-000000000013')
  and not (select is_default from public.user_workout_programs
      where id='b5690000-0000-4000-8000-000000000031')
  and (select count(*)=1 from public.user_workout_programs
      where user_id=auth.uid() and is_default),
  'later Move keeps the original default and does not mark the new parents');

-- Privilege checks must still hold when transactional grants roll back.
rollback;
