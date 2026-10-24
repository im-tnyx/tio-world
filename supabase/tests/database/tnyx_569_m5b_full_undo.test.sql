\set ON_ERROR_STOP on
-- #569 M5B-B1: disposable SQL matrix for Create & Move provenance and full Undo.
-- All fixture writes, temporary grants and assertions are inside one rollback.
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
declare
  v_state text;
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

create function pg_temp.expect_error(
  p_sql text,
  p_state text,
  p_message text,
  p_label text
)
returns void language plpgsql as $$
declare
  v_state text;
  v_message text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    if v_state = p_state and v_message = p_message then return; end if;
    raise exception 'assertion failed: %, expected %/% actual %/%',
      p_label, p_state, p_message, v_state, v_message;
  end;
  raise exception 'assertion failed: % (unexpectedly committed)', p_label;
end;
$$;

select pg_temp.assert_true(
  (select count(*) = 3
     from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_workout_programs'
      and column_name in (
        'create_move_mutation_id',
        'create_move_routine_id',
        'create_move_source_program_id'
      ))
  and not has_function_privilege(
    'authenticated',
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)',
    'EXECUTE'
  )
  and not has_column_privilege(
    'authenticated', 'public.user_workout_routines', 'program_id', 'UPDATE'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_programs', 'DELETE'
  ),
  'M5B provenance exists while Undo and direct parent mutation remain dormant');

-- CI-only access. The migration itself must keep all ordinary hosted roles
-- revoked; this grant is transaction-local test setup and is rolled back.
grant execute on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) to authenticated;
grant execute on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) to authenticated;

insert into auth.users(id, email) values
  ('b569b100-0000-4000-8000-000000000001','m5b-owner@example.test'),
  ('b569b100-0000-4000-8000-000000000002','m5b-foreign@example.test');

insert into public.user_workout_programs(id, user_id, name, is_default) values
  ('b569b100-0000-4000-8000-000000000011','b569b100-0000-4000-8000-000000000001','Program A',true),
  ('b569b100-0000-4000-8000-000000000012','b569b100-0000-4000-8000-000000000001','Other A',false),
  ('b569b100-0000-4000-8000-000000000021','b569b100-0000-4000-8000-000000000002','Foreign',false);

insert into public.user_workout_routines(id, user_id, program_id, name) values
  ('b569b100-0000-4000-8000-000000000031','b569b100-0000-4000-8000-000000000001','b569b100-0000-4000-8000-000000000011','Stable Routine');
insert into public.user_workout_routine_exercises(
  id, user_id, routine_id, position, catalog_exercise_id
) values (
  'b569b100-0000-4000-8000-000000000041',
  'b569b100-0000-4000-8000-000000000001',
  'b569b100-0000-4000-8000-000000000031',0,'ex_squat'
);
insert into public.user_workout_routine_sets(
  id, user_id, routine_exercise_id, position, reps, load_kg, rest_seconds
) values (
  'b569b100-0000-4000-8000-000000000051',
  'b569b100-0000-4000-8000-000000000001',
  'b569b100-0000-4000-8000-000000000041',0,8,40,90
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'b569b100-0000-4000-8000-000000000001', true
);

-- A -> newly-created B: provenance, revision and child identities are atomic.
select pg_temp.assert_true(
  public.create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000061',
    'Program B',0,'b569b100-0000-4000-8000-000000000101'
  ) = 1,
  'Create & Move commits at revision 1');
select pg_temp.assert_true(
  (select create_move_mutation_id = 'b569b100-0000-4000-8000-000000000101'
       and create_move_routine_id = 'b569b100-0000-4000-8000-000000000031'
       and create_move_source_program_id = 'b569b100-0000-4000-8000-000000000011'
    from public.user_workout_programs
   where id = 'b569b100-0000-4000-8000-000000000061')
  and (select program_id = 'b569b100-0000-4000-8000-000000000061'
          and composition_revision = 1
          and last_composition_mutation_id = 'b569b100-0000-4000-8000-000000000101'
       from public.user_workout_routines
      where id = 'b569b100-0000-4000-8000-000000000031')
  and (select count(*) = 1 from public.user_workout_routine_exercises
      where id = 'b569b100-0000-4000-8000-000000000041'
        and routine_id = 'b569b100-0000-4000-8000-000000000031')
  and (select count(*) = 1 from public.user_workout_routine_sets
      where id = 'b569b100-0000-4000-8000-000000000051'
        and routine_exercise_id = 'b569b100-0000-4000-8000-000000000041'),
  'Create & Move stamps exact provenance and preserves composition identities');

-- First Undo atomically restores A, removes only exact B, and records a
-- durable aggregate receipt on the stable Routine row.
select pg_temp.assert_true(
  public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000061',
    'b569b100-0000-4000-8000-000000000101',1,
    'b569b100-0000-4000-8000-000000000102'
  ) = 2,
  'Undo commits at revision 2');
select pg_temp.assert_true(
  not exists (select 1 from public.user_workout_programs
               where id = 'b569b100-0000-4000-8000-000000000061')
  and (select program_id = 'b569b100-0000-4000-8000-000000000011'
          and composition_revision = 2
          and last_composition_mutation_id = 'b569b100-0000-4000-8000-000000000102'
       from public.user_workout_routines
      where id = 'b569b100-0000-4000-8000-000000000031')
  and (select count(*) = 1 from public.user_workout_routine_exercises
      where id = 'b569b100-0000-4000-8000-000000000041')
  and (select count(*) = 1 from public.user_workout_routine_sets
      where id = 'b569b100-0000-4000-8000-000000000051'),
  'successful Undo removes B without deleting Routine/Exercise/Set rows');

-- Exact retry succeeds after B deletion; a different token does not.
select pg_temp.assert_true(
  public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000061',
    'b569b100-0000-4000-8000-000000000101',1,
    'b569b100-0000-4000-8000-000000000102'
  ) = 2,
  'exact duplicate Undo is idempotent after B deletion');
select pg_temp.expect_state(
  $$select public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000061',
    'b569b100-0000-4000-8000-000000000101',1,
    'b569b100-0000-4000-8000-000000000103')$$,
  'P0002','conflicting replay token is rejected');

-- Reusing the deleted UUID is not an exact replay and cannot be deleted by
-- the old receipt, even if an actor recreates a similarly-provenanced row.
reset role;
insert into public.user_workout_programs(
  id, user_id, name, is_default, create_move_mutation_id,
  create_move_routine_id, create_move_source_program_id
) values (
  'b569b100-0000-4000-8000-000000000061',
  'b569b100-0000-4000-8000-000000000001',
  'Reused Program B', false,
  'b569b100-0000-4000-8000-000000000101',
  'b569b100-0000-4000-8000-000000000031',
  'b569b100-0000-4000-8000-000000000011'
);
set local role authenticated;
select pg_temp.expect_state(
  $$select public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000061',
    'b569b100-0000-4000-8000-000000000101',1,
    'b569b100-0000-4000-8000-000000000102')$$,
  'P0001','reused B UUID cannot satisfy deleted-B replay');
reset role;
delete from public.user_workout_programs
 where id = 'b569b100-0000-4000-8000-000000000061';
set local role authenticated;

-- A second Routine in B blocks before the reparent, leaving the committed
-- Create & Move and every child row intact.
select pg_temp.assert_true(
  public.create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000062',
    'Program B2',2,'b569b100-0000-4000-8000-000000000104'
  ) = 3,
  'second Create & Move establishes B2');
reset role;
insert into public.user_workout_routines(id, user_id, program_id, name)
values (
  'b569b100-0000-4000-8000-000000000032',
  'b569b100-0000-4000-8000-000000000001',
  'b569b100-0000-4000-8000-000000000062',
  'Additional Routine'
);
set local role authenticated;
select pg_temp.expect_state(
  $$select public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000062',
    'b569b100-0000-4000-8000-000000000104',3,
    'b569b100-0000-4000-8000-000000000105')$$,
  'P0001','B with an additional Routine rejects atomically');
select pg_temp.assert_true(
  (select program_id = 'b569b100-0000-4000-8000-000000000062'
          and composition_revision = 3
       from public.user_workout_routines
      where id = 'b569b100-0000-4000-8000-000000000031')
  and (select count(*) = 2 from public.user_workout_routines
       where program_id = 'b569b100-0000-4000-8000-000000000062')
  and exists (select 1 from public.user_workout_programs
              where id = 'b569b100-0000-4000-8000-000000000062'),
  'failed Undo leaves original Create & Move intact with no partial delete');

-- Remove the extra Routine so the rename guard is tested independently of the
-- nonempty-Program guard.
reset role;
delete from public.user_workout_routines
 where id = 'b569b100-0000-4000-8000-000000000032';
set local role authenticated;

-- A rename changes the immutable Create & Move request hash and fails closed
-- before reparent/delete, independently of the nonempty-Program guard.
update public.user_workout_programs
   set name = 'Program B2 renamed'
 where id = 'b569b100-0000-4000-8000-000000000062';
select pg_temp.expect_error(
  $$select public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000062',
    'b569b100-0000-4000-8000-000000000104',3,
    'b569b100-0000-4000-8000-000000000106')$$,
  'P0001','routine_create_move_undo_mutation_conflict',
  'renamed B rejects before reparent/delete');

-- Cross-owner calls cannot use another owner\'s Routine or Program identity.
select set_config(
  'request.jwt.claim.sub',
  'b569b100-0000-4000-8000-000000000002', true
);
select pg_temp.expect_state(
  $$select public.undo_create_user_workout_program_and_move_routine(
    'b569b100-0000-4000-8000-000000000031',
    'b569b100-0000-4000-8000-000000000011',
    'b569b100-0000-4000-8000-000000000062',
    'b569b100-0000-4000-8000-000000000104',3,
    'b569b100-0000-4000-8000-000000000107')$$,
  'P0002','cross-owner Undo is rejected');

rollback;
