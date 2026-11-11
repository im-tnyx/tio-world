-- TNYX-81 staged migration security assertions.
-- The caller supplies the checkpoint through psql --set=stage=...

begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void
language plpgsql
as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

select set_config('tnyx81.stage', :'stage', true);

select pg_temp.assert_true(
  case :'stage'
    when 'baseline' then
      to_regclass('private.routine_notes_data_api_gate_state') is null
      and to_regclass('public.user_workout_routine_notes') is null
    when 'pre_notes_gate' then
      to_regclass('private.routine_notes_data_api_gate_state') is not null
      and to_regprocedure('private.routine_notes_data_api_gate()') is not null
      and to_regclass('public.user_workout_routine_notes') is null
    else
      to_regclass('private.routine_notes_data_api_gate_state') is not null
      and to_regclass('public.user_workout_routine_notes') is not null
      and to_regprocedure('private.routine_notes_data_api_gate_is_enabled()') is not null
      and exists (
        select 1
        from pg_catalog.pg_policies
        where schemaname = 'public'
          and tablename = 'user_workout_routine_notes'
          and policyname = 'routine_notes_data_api_gate_enabled_select'
          and permissive = 'RESTRICTIVE'
          and cmd = 'SELECT'
          and roles = array['authenticated']::name[]
          and qual ilike '%routine_notes_data_api_gate_is_enabled%'
          and qual not ilike '%current_setting%request.path%'
      )
  end,
  'staged checkpoint has the expected Notes/gate object boundary'
);

do $$
declare
  v_stage text := current_setting('tnyx81.stage');
  v_gate_state text;
begin
  if v_stage <> 'baseline' then
    execute $sql$
      select gate_state
      from private.routine_notes_data_api_gate_state
      where gate_key = 'routine_notes'
    $sql$
    into v_gate_state;
    perform pg_temp.assert_true(
      v_gate_state = 'disabled',
      'staged checkpoint starts with the default-disabled gate state'
    );
  end if;
end;
$$;

do $$
declare
  v_stage text := current_setting('tnyx81.stage');
begin
  if v_stage not in ('baseline', 'pre_notes_gate') then
    insert into auth.users (id, email, is_anonymous) values
      ('a8100000-0000-4000-8000-000000000071', 'notes-stage-owner@example.test', false);
    insert into public.user_workout_programs (id, user_id, name) values
      ('a8100000-0000-4000-8000-000000000071',
       'a8100000-0000-4000-8000-000000000071', 'Notes Stage Program');
    insert into public.user_workout_routines (id, user_id, program_id, name) values
      ('a8100000-0000-4000-8000-000000000072',
       'a8100000-0000-4000-8000-000000000071',
       'a8100000-0000-4000-8000-000000000071', 'Notes Stage Routine');
    insert into public.user_workout_routine_notes (
      id, user_id, routine_id, note_type, body
    ) values (
      'a8100000-0000-4000-8000-000000000073',
      'a8100000-0000-4000-8000-000000000071',
      'a8100000-0000-4000-8000-000000000072',
      'pinned_routine', 'Synthetic staged gate note'
    );

    set local role authenticated;
    perform set_config(
      'request.jwt.claim.sub',
      'a8100000-0000-4000-8000-000000000071',
      true
    );
    perform pg_temp.assert_true(
      (select count(*) = 0
       from public.user_workout_routine_notes
       where id = 'a8100000-0000-4000-8000-000000000073'),
      'authenticated SQL Notes read fails closed at every post-table checkpoint'
    );
    reset role;
  end if;
end;
$$;

rollback;
