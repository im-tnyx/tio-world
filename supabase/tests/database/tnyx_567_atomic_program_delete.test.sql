\set ON_ERROR_STOP on
-- #567 D1: disposable SQL-only owner-safe Program Delete regression.
-- All Auth/user/Program/Routine/child writes and test EXECUTE grant ROLLBACK.
begin;

create function pg_temp.assert_true(ok boolean, label text)
returns void language plpgsql as $$
begin
  if ok is not true then
    raise exception 'assertion failed: %', label;
  end if;
end;
$$;

create function pg_temp.expect_state(stmt text, expected text, label text)
returns void language plpgsql as $$
declare actual text;
begin
  begin
    execute stmt;
  exception when others then
    get stacked diagnostics actual = returned_sqlstate;
    if actual = expected then return; end if;
    raise exception 'assertion failed: % expected SQLSTATE %, got %',
      label, expected, actual;
  end;
  raise exception 'assertion failed: % unexpectedly succeeded', label;
end;
$$;

select pg_temp.assert_true(
  (select p.prosecdef
          and p.proowner = 'postgres'::regrole
          and p.proconfig @> array['search_path=""']::text[]
     from pg_catalog.pg_proc p
    where p.oid =
      'public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)'::regprocedure)
  and not has_function_privilege('anon',
      'public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)',
      'EXECUTE')
  and not has_function_privilege('authenticated',
      'public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)',
      'EXECUTE')
  and not has_function_privilege('service_role',
      'public.delete_user_workout_program_preserving_routines(uuid,uuid[],uuid)',
      'EXECUTE')
  and not has_table_privilege(
    'authenticated', 'public.user_workout_programs', 'DELETE')
  and not has_column_privilege(
    'authenticated', 'public.user_workout_routines', 'program_id', 'UPDATE'),
  'source migration has a protected dormant RPC and no direct client delete'
);

grant execute on function public.delete_user_workout_program_preserving_routines(
  uuid,uuid[],uuid
) to authenticated;

insert into auth.users(id,email,is_anonymous) values
 ('d5670000-0000-4000-8000-000000000001','program-delete-a@example.test',false),
 ('d5670000-0000-4000-8000-000000000002','program-delete-b@example.test',false),
 ('d5670000-0000-4000-8000-000000000003','program-delete-c@example.test',false),
 ('d5670000-0000-4000-8000-000000000004','program-delete-guest@example.test',true);

-- Owner A: renamed default and a non-default source with two real child trees.
-- Owner B: empty Program, no default. Owner C: populated, no default.
insert into public.user_workout_programs(id,user_id,name,is_default) values
 ('d5670000-0000-4000-8000-000000000011',
  'd5670000-0000-4000-8000-000000000001','Renamed My Program',true),
 ('d5670000-0000-4000-8000-000000000012',
  'd5670000-0000-4000-8000-000000000001','Source A',false),
 ('d5670000-0000-4000-8000-000000000013',
  'd5670000-0000-4000-8000-000000000001','Rollback A',false),
 ('d5670000-0000-4000-8000-000000000021',
  'd5670000-0000-4000-8000-000000000002','Empty B',false),
 ('d5670000-0000-4000-8000-000000000031',
  'd5670000-0000-4000-8000-000000000003','Source C',false),
 ('d5670000-0000-4000-8000-000000000041',
  'd5670000-0000-4000-8000-000000000004','Guest Source',false);

insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('d5670000-0000-4000-8000-000000000101',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000012','Chest'),
 ('d5670000-0000-4000-8000-000000000102',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000012','Back'),
 ('d5670000-0000-4000-8000-000000000103',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000013','Rollback A1'),
 ('d5670000-0000-4000-8000-000000000104',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000013','Rollback A2'),
 ('d5670000-0000-4000-8000-000000000301',
  'd5670000-0000-4000-8000-000000000003',
  'd5670000-0000-4000-8000-000000000031','C Routine'),
 ('d5670000-0000-4000-8000-000000000401',
  'd5670000-0000-4000-8000-000000000004',
  'd5670000-0000-4000-8000-000000000041','Guest Routine');

insert into public.user_workout_routine_exercises(
  id,user_id,routine_id,position,catalog_exercise_id
) values
 ('d5670000-0000-4000-8000-000000000201',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000101',0,'ex_squat'),
 ('d5670000-0000-4000-8000-000000000202',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000102',0,'ex_squat');

insert into public.user_workout_routine_sets(
  id,user_id,routine_exercise_id,position,reps,load_kg,rest_seconds
) values
 ('d5670000-0000-4000-8000-000000000211',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000201',0,8,20,60),
 ('d5670000-0000-4000-8000-000000000212',
  'd5670000-0000-4000-8000-000000000001',
  'd5670000-0000-4000-8000-000000000202',0,10,30,90);

-- Force a late second-child overflow after the first Routine has already
-- been tentatively moved. A subtransaction rolls the first update back.
update public.user_workout_routines set composition_revision =
  9223372036854775807 where id='d5670000-0000-4000-8000-000000000104';

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5670000-0000-4000-8000-000000000001',true);

select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000011',
   '{}'::uuid[], 'd5670000-0000-4000-8000-000000000801')$$,
 'P0001','canonical default cannot be removed even after rename');

select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000021',
   '{}'::uuid[], 'd5670000-0000-4000-8000-000000000801')$$,
 'P0002','foreign Program must be opaque not found');

select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000012',
   array['d5670000-0000-4000-8000-000000000101'::uuid],
   'd5670000-0000-4000-8000-000000000802')$$,
 'P0001','missing second Routine makes confirmation stale');

select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000012',
   array['d5670000-0000-4000-8000-000000000101'::uuid,
         'd5670000-0000-4000-8000-000000000101'::uuid],
   'd5670000-0000-4000-8000-000000000802')$$,
 '22023','duplicate snapshot identifiers are invalid');

select pg_temp.expect_state(
 $$delete from public.user_workout_programs
   where id='d5670000-0000-4000-8000-000000000012'$$,
 '42501','client table DELETE remains forbidden');

select pg_temp.expect_state(
 $$update public.user_workout_routines
   set program_id='d5670000-0000-4000-8000-000000000011'
   where id='d5670000-0000-4000-8000-000000000101'$$,
 '42501','client direct Routine reparent stays denied');

select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000013',
   array['d5670000-0000-4000-8000-000000000103'::uuid,
         'd5670000-0000-4000-8000-000000000104'::uuid],
   'd5670000-0000-4000-8000-000000000803')$$,
 'P0001','late Routine revision overflow rolls back entire delete');

reset role;
select pg_temp.assert_true(
 (select count(*)=2 from public.user_workout_routines
  where user_id='d5670000-0000-4000-8000-000000000001'
    and program_id='d5670000-0000-4000-8000-000000000013')
 and (select composition_revision=0 from public.user_workout_routines
      where id='d5670000-0000-4000-8000-000000000103'),
 'late failure retains both original Routines and source Program');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5670000-0000-4000-8000-000000000001',true);

select pg_temp.assert_true(
 (public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000012',
   array['d5670000-0000-4000-8000-000000000102'::uuid,
         'd5670000-0000-4000-8000-000000000101'::uuid],
   'd5670000-0000-4000-8000-000000000804'
 )->>'moved_routine_count')::bigint=2,
 'two same-owner Routines atomically transferred (order-independent input)'
);

reset role;
select pg_temp.assert_true(
 not exists(select 1 from public.user_workout_programs
            where id='d5670000-0000-4000-8000-000000000012')
 and (select count(*)=2 from public.user_workout_routines
      where id in ('d5670000-0000-4000-8000-000000000101',
                   'd5670000-0000-4000-8000-000000000102')
        and program_id='d5670000-0000-4000-8000-000000000011'
        and composition_revision=1
        and last_composition_mutation_id=
            'd5670000-0000-4000-8000-000000000804'
        and pg_catalog.octet_length(last_routine_update_request_hash)=32)
 and (select count(*)=2 from public.user_workout_routine_exercises
      where id in ('d5670000-0000-4000-8000-000000000201',
                   'd5670000-0000-4000-8000-000000000202'))
 and (select count(*)=2 from public.user_workout_routine_sets
      where id in ('d5670000-0000-4000-8000-000000000211',
                   'd5670000-0000-4000-8000-000000000212'))
 and (select name='Renamed My Program' from public.user_workout_programs
      where id='d5670000-0000-4000-8000-000000000011'),
 'source gone; same stable Routine/Exercise/Set UUIDs and renamed default');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5670000-0000-4000-8000-000000000001',true);
select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000012',
   array['d5670000-0000-4000-8000-000000000101'::uuid,
         'd5670000-0000-4000-8000-000000000102'::uuid],
   'd5670000-0000-4000-8000-000000000804')$$,
 'P0002','exact retry after committed deletion never falsely returns success');

reset role;
select pg_temp.assert_true(
 (select count(*)=2 from public.user_workout_routines
  where program_id='d5670000-0000-4000-8000-000000000011'
    and id in ('d5670000-0000-4000-8000-000000000101',
               'd5670000-0000-4000-8000-000000000102')),
 'failed replay cannot duplicate or move any Routine');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5670000-0000-4000-8000-000000000002',true);

select pg_temp.assert_true(
 (public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000021', '{}'::uuid[],
   'd5670000-0000-4000-8000-000000000805'
 )->>'moved_routine_count')::bigint=0,
 'empty Program removed without inventing default'
);

reset role;
select pg_temp.assert_true(
 not exists(select 1 from public.user_workout_programs
   where user_id='d5670000-0000-4000-8000-000000000002'),
 'empty source creates no default Program');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5670000-0000-4000-8000-000000000003',true);

select pg_temp.assert_true(
 (public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000031',
   array['d5670000-0000-4000-8000-000000000301'::uuid],
   'd5670000-0000-4000-8000-000000000806'
 )->>'moved_routine_count')::bigint=1,
 'populated source without default gets atomic canonical default'
);

reset role;
select pg_temp.assert_true(
 (select count(*)=1 from public.user_workout_programs
   where user_id='d5670000-0000-4000-8000-000000000003'
     and name='My Program' and is_default)
 and not exists(select 1 from public.user_workout_programs
   where id='d5670000-0000-4000-8000-000000000031')
 and (select r.program_id=p.id from public.user_workout_routines r
      join public.user_workout_programs p on p.user_id=r.user_id and p.is_default
      where r.id='d5670000-0000-4000-8000-000000000301'),
 'one server-authoritative default, same Routine identity');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5670000-0000-4000-8000-000000000004',true);

select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000041',
   array['d5670000-0000-4000-8000-000000000401'::uuid],
   'd5670000-0000-4000-8000-000000000807')$$,
 '28000','real anonymous Auth user cannot delete Program');

reset role;
select pg_temp.assert_true(
 (select program_id='d5670000-0000-4000-8000-000000000041'
    from public.user_workout_routines
   where id='d5670000-0000-4000-8000-000000000401'),
 'guest denied without any data writes');

set local role authenticated;
select set_config('request.jwt.claim.sub','',true);
select pg_temp.expect_state(
 $$select public.delete_user_workout_program_preserving_routines(
   'd5670000-0000-4000-8000-000000000013', '{}'::uuid[],
   'd5670000-0000-4000-8000-000000000808')$$,
 '28000','no Auth session cannot invoke the SECDEF operation');
reset role;

rollback;
