\set ON_ERROR_STOP on

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
  p_sql text,
  p_state text,
  p_message text
)
returns void language plpgsql as $$
declare
  v_state text;
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
  to_regclass('public.user_workout_routine_notes') is not null
  and to_regclass('private.user_workout_routine_note_mutations') is not null
  and has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'INSERT'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'UPDATE'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'DELETE'
  )
  and not has_table_privilege(
    'authenticated', 'private.user_workout_routine_note_mutations', 'SELECT'
  )
  and has_function_privilege(
    'authenticated',
    'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and has_function_privilege(
    'authenticated',
    'public.reconcile_user_workout_routine_note_mutation(uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  ),
  'Notes tables and RPCs use the owner-secured access boundary'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_class where oid = 'public.user_workout_routine_notes'::regclass)
  and (select relrowsecurity
   from pg_class
   where oid = 'private.user_workout_routine_note_mutations'::regclass),
  'Notes and receipt tables have RLS enabled'
);

insert into auth.users (id, email) values
  ('a8100000-0000-4000-8000-000000000001', 'notes-a@example.test'),
  ('a8100000-0000-4000-8000-000000000002', 'notes-b@example.test');
insert into public.user_workout_programs (id, user_id, name) values
  ('a8100000-0000-4000-8000-000000000011',
   'a8100000-0000-4000-8000-000000000001', 'Program A'),
  ('a8100000-0000-4000-8000-000000000012',
   'a8100000-0000-4000-8000-000000000002', 'Program B');
insert into public.user_workout_routines (id, user_id, program_id, name) values
  ('a8100000-0000-4000-8000-000000000021',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine A'),
  ('a8100000-0000-4000-8000-000000000022',
   'a8100000-0000-4000-8000-000000000002',
   'a8100000-0000-4000-8000-000000000012', 'Routine B'),
  ('a8100000-0000-4000-8000-000000000023',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine Delete');
insert into public.user_workout_exercises (
  id, user_id, display_name
) values (
  'a8100000-0000-4000-8000-000000000031',
  'a8100000-0000-4000-8000-000000000001',
  'Custom Notes Exercise'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_routine_notes (
      id, user_id, routine_id, note_type, body
    ) values (
      'a8100000-0000-4000-8000-000000000101',
      'a8100000-0000-4000-8000-000000000001',
      'a8100000-0000-4000-8000-000000000021',
      'pinned_routine', 'direct write'
    )$$,
  '42501', 'authenticated cannot write Notes directly'
);
select pg_temp.assert_raises(
  $$select * from private.user_workout_routine_note_mutations$$,
  '42501', 'authenticated cannot read mutation receipts directly'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create',
    'a8100000-0000-4000-8000-000000000101',
    'a8100000-0000-4000-8000-000000000021',
    null, null, '  Routine note  ', null,
    'a8100000-0000-4000-8000-000000000201'
  )->>'status') = 'applied',
  'create defaults to a Routine Note and normalizes body text'
);
select pg_temp.assert_true(
  (select note_type = 'pinned_routine'
      and body = 'Routine note' and revision = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000101'),
  'created Routine Note has stable identity and initial revision'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create',
    'a8100000-0000-4000-8000-000000000102',
    null,
    'a8100000-0000-4000-8000-000000000031',
    'pinned_exercise', 'Custom exercise note', null,
    'a8100000-0000-4000-8000-000000000202'
  )->>'status') = 'applied',
  'active owner-bound Custom Exercise accepts an Exercise Note'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create',
    'a8100000-0000-4000-8000-000000000103',
    null, 'ex_barbell_bench_press', 'pinned_exercise',
    'Catalog exercise note', null,
    'a8100000-0000-4000-8000-000000000203'
  )->>'status') = 'applied',
  'catalog ExerciseRef remains a catalog identity and is not mirrored'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'update',
    'a8100000-0000-4000-8000-000000000101',
    null, null, null, 'Updated note', 0,
    'a8100000-0000-4000-8000-000000000204'
  )->>'revision')::bigint = 1,
  'body update advances revision exactly once'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'update',
    'a8100000-0000-4000-8000-000000000101',
    null, null, null, 'Stale update', 0,
    'a8100000-0000-4000-8000-000000000205'
  )$$,
  'P0001', 'stale revision is rejected without changing body'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'transfer',
    'a8100000-0000-4000-8000-000000000101',
    null, 'a8100000-0000-4000-8000-000000000031',
    'pinned_exercise', null, 1,
    'a8100000-0000-4000-8000-000000000206'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000101',
  'type transfer preserves Note UUID and body'
);
select pg_temp.assert_true(
  (select routine_id is null
      and exercise_ref = 'a8100000-0000-4000-8000-000000000031'
      and body = 'Updated note'
      and revision = 2
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000101'),
  'type transfer changes only the approved Note scope'
);

-- Fill the Routine scope to the approved cap.
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000111',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 1', null, 'a8100000-0000-4000-8000-000000000211');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000112',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 2', null, 'a8100000-0000-4000-8000-000000000212');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000113',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 3', null, 'a8100000-0000-4000-8000-000000000213');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000114',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 4', null, 'a8100000-0000-4000-8000-000000000214');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000115',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 5', null, 'a8100000-0000-4000-8000-000000000215');
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000116',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'Routine 6', null, 'a8100000-0000-4000-8000-000000000216'
  )$$,
  'P0001', 'sixth Note is rejected at the authoritative quota'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000111',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'Routine 1', null, 'a8100000-0000-4000-8000-000000000211'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000111',
  'exact create retry returns the durable receipt without a duplicate'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000111',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'Different request', null, 'a8100000-0000-4000-8000-000000000211'
  )$$,
  'P0001', 'reusing a mutation ID for a different request is rejected'
);

-- The two canonical scopes have independent caps. Fill Exercise scope, then
-- verify a full destination rejects a transfer without changing its source.
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000104',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 2', null, 'a8100000-0000-4000-8000-000000000314');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000105',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 3', null, 'a8100000-0000-4000-8000-000000000315');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000106',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 4', null, 'a8100000-0000-4000-8000-000000000316');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000109',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 5', null, 'a8100000-0000-4000-8000-000000000321');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000107',
  'a8100000-0000-4000-8000-000000000023', null, 'pinned_routine',
  'Transfer source', null, 'a8100000-0000-4000-8000-000000000217');
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'transfer', 'a8100000-0000-4000-8000-000000000107',
    null, 'ex_barbell_bench_press', 'pinned_exercise', null, 0,
    'a8100000-0000-4000-8000-000000000218'
  )$$,
  'P0001', 'full destination rejects transfer atomically'
);
select pg_temp.assert_true(
  (select note_type = 'pinned_routine'
      and routine_id = 'a8100000-0000-4000-8000-000000000023'
      and body = 'Transfer source' and revision = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000107'),
  'failed transfer retains source scope and body'
);

-- Archiving a Custom Exercise retains its existing Note and permits editing
-- that existing Note, while new Notes on the archived ref are rejected.
reset role;
update public.user_workout_exercises
set status = 'archived'
where id = 'a8100000-0000-4000-8000-000000000031';
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000102'),
  'archiving a Custom Exercise does not delete its existing Note'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'update', 'a8100000-0000-4000-8000-000000000102',
    null, null, null, 'Archived Exercise note', 0,
    'a8100000-0000-4000-8000-000000000219'
  )->>'revision')::bigint = 1,
  'existing archived Exercise Note remains safely editable'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000108',
    null, 'a8100000-0000-4000-8000-000000000031', 'pinned_exercise',
    'New archived note', null, 'a8100000-0000-4000-8000-000000000220'
  )$$,
  'P0001', 'new Notes cannot attach to an archived Custom Exercise'
);

select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000110',
  'a8100000-0000-4000-8000-000000000023', null, 'pinned_routine',
  'Routine deletion note', null, 'a8100000-0000-4000-8000-000000000222');

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000101',
    null, null, null, null, 2,
    'a8100000-0000-4000-8000-000000000207'
  )->>'status') = 'deleted',
  'Delete removes exactly one Note'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000101',
    null, null, null, null, 2,
    'a8100000-0000-4000-8000-000000000207'
  )->>'status') = 'deleted'
  and not exists (
    select 1 from public.user_workout_routine_notes
    where id = 'a8100000-0000-4000-8000-000000000101'
  ),
  'Delete replay cannot resurrect a Note'
);

reset role;
delete from public.user_workout_routine_notes
where id = 'a8100000-0000-4000-8000-000000000102';
delete from public.user_workout_routines
where id = 'a8100000-0000-4000-8000-000000000023';
select pg_temp.assert_true(
  not exists (
    select 1 from public.user_workout_routine_notes
    where routine_id = 'a8100000-0000-4000-8000-000000000023'
  ),
  'Routine deletion cascades only its Routine Notes'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes),
  'cross-owner Note reads return no rows under RLS'
);

reset role;
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000102'),
  'deleted Note remains absent for every owner'
);

rollback;
