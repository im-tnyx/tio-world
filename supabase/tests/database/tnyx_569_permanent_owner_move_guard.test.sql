\set ON_ERROR_STOP on
-- GitHub #569 / Linear TNYX-81: R3 permanent-account admission for all three Move/Create+Move/Full-Undo RPCs.
-- Disposable migrated CI only; guest fixtures and temporary grants ROLLBACK.
begin;

create function pg_temp.assert_true(p_ok boolean, p_reason text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_reason;
  end if;
end;
$$;

create function pg_temp.assert_raises(p_sql text, p_state text, p_reason text)
returns void language plpgsql as $$
declare
  v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then
      return;
    end if;
    raise exception 'assertion failed: % (SQLSTATE %, expected %)',
      p_reason, v_state, p_state;
  end;
  raise exception 'assertion failed: % (unexpected success)', p_reason;
end;
$$;

-- M4A hardens Move/Create+Move; M5B also guards Full Undo. Durable ACL is checked in the
-- separate current-state ACL contract, while this matrix tests admission.
select pg_temp.assert_true(
  (select count(*) = 1 from supabase_migrations.schema_migrations
   where version = '20261021130000')
  and not has_function_privilege('anon',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and has_function_privilege('authenticated',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines', 'program_id', 'UPDATE')
  and not has_column_privilege('authenticated',
    'public.user_workout_programs', 'is_default', 'UPDATE')
  and (select p.proowner = 'postgres'::regrole
              and p.prosecdef
              and p.proconfig @> array['search_path=""']::text[]
       from pg_catalog.pg_proc as p
       where p.oid =
         'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'::regprocedure)
  and (select p.proowner = 'postgres'::regrole
              and p.prosecdef
              and p.proconfig @> array['search_path=""']::text[]
       from pg_catalog.pg_proc as p
       where p.oid =
         'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'::regprocedure),
  'both SECDEF Move APIs retain owner, anon/service_role and direct-write boundaries'
);

-- Transaction-local SQL access rolls back to the migrated ACL.
grant execute on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) to authenticated;
grant execute on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) to authenticated;
grant execute on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) to authenticated;

-- A valid UID with Auth is_anonymous=true must still be rejected even though
-- its DB role is authenticated and its client JWT can claim otherwise.
insert into auth.users (id, is_anonymous)
values ('f5690000-0000-4000-8000-000000000001', true);

select pg_temp.assert_true(
  exists (select 1 from public.users
          where id = 'f5690000-0000-4000-8000-000000000001'::uuid)
  and exists (select 1 from auth.users
              where id = 'f5690000-0000-4000-8000-000000000001'::uuid
                and is_anonymous is true),
  'guest fixture has valid Auth and owner account rows'
);

insert into public.user_workout_programs(id,user_id,name,is_default) values
 ('f5690000-0000-4000-8000-000000000011',
  'f5690000-0000-4000-8000-000000000001','Source',false),
 ('f5690000-0000-4000-8000-000000000012',
  'f5690000-0000-4000-8000-000000000001','Destination',false);
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('f5690000-0000-4000-8000-000000000021',
  'f5690000-0000-4000-8000-000000000001',
  'f5690000-0000-4000-8000-000000000011','Guest Routine');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'f5690000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.is_anonymous', 'false', true);

select pg_temp.assert_raises(
  $$select public.move_user_workout_routine(
    'f5690000-0000-4000-8000-000000000021'::uuid,
    'f5690000-0000-4000-8000-000000000011'::uuid,
    'f5690000-0000-4000-8000-000000000012'::uuid, 0,
    'f5690000-0000-4000-8000-000000000031'::uuid)$$,
  '28000',
  'signed-in guest cannot reparent an existing Routine'
);

select pg_temp.assert_raises(
  $$select public.create_user_workout_program_and_move_routine(
    'f5690000-0000-4000-8000-000000000021'::uuid,
    'f5690000-0000-4000-8000-000000000011'::uuid,
    'f5690000-0000-4000-8000-000000000013'::uuid,
    'Guest Program', 0,
    'f5690000-0000-4000-8000-000000000032'::uuid)$$,
  '28000',
  'signed-in guest cannot create a Program and Move'
);

-- R3 exposes Full Undo through the same authenticated role. It must reject
-- real anonymous Auth accounts before any provenance/row lookup, even if the
-- JWT supplies a spoofed non-anonymous claim.
select pg_temp.assert_raises(
  $select public.undo_create_user_workout_program_and_move_routine(
    'f5690000-0000-4000-8000-000000000021'::uuid,
    'f5690000-0000-4000-8000-000000000011'::uuid,
    'f5690000-0000-4000-8000-000000000013'::uuid,
    'f5690000-0000-4000-8000-000000000033'::uuid, 1,
    'f5690000-0000-4000-8000-000000000034'::uuid)$,
  '28000',
  'signed-in guest cannot invoke full atomic Undo'
);
reset role;

select pg_temp.assert_true(
  (select program_id =
    'f5690000-0000-4000-8000-000000000011'::uuid
   and composition_revision = 0
   from public.user_workout_routines
   where id = 'f5690000-0000-4000-8000-000000000021'::uuid)
  and not exists (
    select 1 from public.user_workout_programs
    where id = 'f5690000-0000-4000-8000-000000000013'::uuid),
  'rejected guest preserves Routine revision and leaves no new Program'
);

-- Verify test-local revoke behavior; the transaction rollback restores the
-- migrated ACL, including any future authenticated grant.
revoke execute on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) from authenticated;
revoke execute on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) from authenticated;
revoke execute on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) from authenticated;
select pg_temp.assert_true(
  not has_function_privilege('authenticated',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated',
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated',
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and has_function_privilege('authenticated',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE'),
  'transactional test grants fully revoked; W1 permission unchanged'
);

rollback;
