\set ON_ERROR_STOP on

begin;

create function pg_temp.assert_true(p_condition boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_condition is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260917092920'
     and name = 'create_detailed_meal_log_rpc'),
  'migration ledger must contain the TNYX-218 RPC migration exactly once'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'create_detailed_meal_log'
      and p.prosecdef
      and pg_catalog.pg_get_function_identity_arguments(p.oid) =
        'p_client_mutation_id uuid, p_meal_category_id text, p_meal_name text, p_note text, p_consumed_at timestamp with time zone, p_consumed_local_date date, p_consumed_timezone_id text, p_consumed_utc_offset_minutes integer, p_capture_source text, p_items jsonb'
      and pg_catalog.pg_get_functiondef(p.oid) ilike '%SET search_path TO ''''%'
  ),
  'atomic detailed create RPC must have the frozen signature, SECURITY DEFINER and empty search_path'
);

select pg_temp.assert_true(
  has_function_privilege(
    'authenticated',
    'public.create_detailed_meal_log(uuid,text,text,text,timestamptz,date,text,integer,text,jsonb)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.create_detailed_meal_log(uuid,text,text,text,timestamptz,date,text,integer,text,jsonb)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.create_detailed_meal_log(uuid,text,text,text,timestamptz,date,text,integer,text,jsonb)',
    'EXECUTE'
  ),
  'only authenticated callers must execute the detailed create RPC'
);

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'SELECT')
  and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'INSERT')
  and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'DELETE'),
  'TNYX-218 must not reopen direct authenticated child writes'
);

insert into auth.users (id, email)
values
  ('a2180000-0000-4000-8000-000000001001', 'tnyx-218-owner@example.test'),
  ('a2180000-0000-4000-8000-000000001002', 'tnyx-218-other@example.test');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a2180000-0000-4000-8000-000000001001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a2180000-0000-4000-8000-000000001001","role":"authenticated"}',
  true
);

create temp table t_tnyx_218_result (
  first_id uuid,
  retry_id uuid
) on commit drop;

insert into t_tnyx_218_result (first_id)
select public.create_detailed_meal_log(
  'a2180000-0000-4000-8000-000000001011',
  'meal_slot_2',
  'Lunch',
  'After training',
  '2026-09-17T12:00:00Z',
  '2026-09-17',
  'Asia/Kolkata',
  330,
  'text',
  '[
    {"display_name":"Dal","brand_name":null,"quantity":1,"serving_unit":"bowl","nutrition_snapshot":{"schemaVersion":1,"nutrients":{"energy":220,"protein":12}}},
    {"display_name":"Roti","brand_name":null,"quantity":2,"serving_unit":"piece","nutrition_snapshot":{"schemaVersion":1,"nutrients":{"energy":240,"protein":8}}}
  ]'::jsonb
);

update t_tnyx_218_result
set retry_id = public.create_detailed_meal_log(
  'a2180000-0000-4000-8000-000000001011',
  'meal_slot_2',
  'Lunch',
  'After training',
  '2026-09-17T12:00:00Z',
  '2026-09-17',
  'Asia/Kolkata',
  330,
  'text',
  '[
    {"display_name":"Dal","brand_name":null,"quantity":1,"serving_unit":"bowl","nutrition_snapshot":{"schemaVersion":1,"nutrients":{"energy":220,"protein":12}}},
    {"display_name":"Roti","brand_name":null,"quantity":2,"serving_unit":"piece","nutrition_snapshot":{"schemaVersion":1,"nutrients":{"energy":240,"protein":8}}}
  ]'::jsonb
);

select pg_temp.assert_true(
  (select first_id = retry_id from t_tnyx_218_result),
  'same logical retry must return the same durable parent identity'
);

select pg_temp.assert_true(
  (select count(*) = 1
   from public.meal_log_entries
   where user_id = 'a2180000-0000-4000-8000-000000001001'
     and client_mutation_id = 'a2180000-0000-4000-8000-000000001011'),
  'same mutation retry must create exactly one parent'
);

select pg_temp.assert_true(
  (select count(*) = 2
   from public.meal_log_item_snapshots
   where meal_log_entry_id = (select first_id from t_tnyx_218_result)),
  'atomic create must persist every ordered detailed item exactly once'
);

select pg_temp.assert_true(
  (select array_agg(display_name order by position) = array['Dal','Roti']::text[]
   from public.meal_log_item_snapshots
   where meal_log_entry_id = (select first_id from t_tnyx_218_result)),
  'durable detailed item order must match request order'
);

reset role;

do $$
declare
  v_conflict boolean := false;
  v_empty_items boolean := false;
  v_bad_quantity boolean := false;
  v_direct_child_write_denied boolean := false;
begin
  perform set_config('request.jwt.claim.sub', 'a2180000-0000-4000-8000-000000001001', true);
  perform set_config(
    'request.jwt.claims',
    '{"sub":"a2180000-0000-4000-8000-000000001001","role":"authenticated"}',
    true
  );
  set local role authenticated;

  begin
    perform public.create_detailed_meal_log(
      'a2180000-0000-4000-8000-000000001011',
      'meal_slot_2',
      'Lunch',
      'After training',
      '2026-09-17T12:00:00Z',
      '2026-09-17',
      'Asia/Kolkata',
      330,
      'text',
      '[{"display_name":"Dal","brand_name":null,"quantity":2,"serving_unit":"bowl","nutrition_snapshot":{"schemaVersion":1,"nutrients":{"energy":440,"protein":24}}}]'::jsonb
    );
  exception when raise_exception then
    v_conflict := sqlstate = 'P0001'
      and sqlerrm = 'meal_log_create_mutation_conflict';
  end;

  begin
    perform public.create_detailed_meal_log(
      'a2180000-0000-4000-8000-000000001012',
      'meal_slot_2',
      'Lunch',
      null,
      '2026-09-17T12:30:00Z',
      '2026-09-17',
      'Asia/Kolkata',
      330,
      'text',
      '[]'::jsonb
    );
  exception when invalid_parameter_value then
    v_empty_items := sqlerrm = 'detailed_items_required';
  end;

  begin
    perform public.create_detailed_meal_log(
      'a2180000-0000-4000-8000-000000001013',
      'meal_slot_2',
      'Lunch',
      null,
      '2026-09-17T12:45:00Z',
      '2026-09-17',
      'Asia/Kolkata',
      330,
      'text',
      '[{"display_name":"Dal","brand_name":null,"quantity":0,"serving_unit":"bowl","nutrition_snapshot":{"schemaVersion":1,"nutrients":{"energy":220}}}]'::jsonb
    );
  exception when invalid_parameter_value then
    v_bad_quantity := sqlerrm = 'invalid_detailed_item_quantity';
  end;

  begin
    insert into public.meal_log_item_snapshots (
      meal_log_entry_id,
      position,
      display_name,
      quantity,
      serving_unit,
      nutrition_snapshot
    ) values (
      (select first_id from t_tnyx_218_result),
      2,
      'Bypass item',
      1,
      'serving',
      '{"schemaVersion":1,"nutrients":{"energy":1}}'
    );
  exception when insufficient_privilege then
    v_direct_child_write_denied := true;
  end;

  reset role;

  if not v_conflict then
    raise exception 'assertion failed: same mutation id with different facts must conflict';
  end if;
  if not v_empty_items then
    raise exception 'assertion failed: empty detailed items must be rejected';
  end if;
  if not v_bad_quantity then
    raise exception 'assertion failed: non-positive detailed quantity must be rejected';
  end if;
  if not v_direct_child_write_denied then
    raise exception 'assertion failed: authenticated direct child insert must remain denied';
  end if;
end
$$;

select pg_temp.assert_true(
  (select count(*) = 1
   from public.meal_log_entries
   where user_id = 'a2180000-0000-4000-8000-000000001001'),
  'failed conflict/validation attempts must not create additional parent rows'
);

select pg_temp.assert_true(
  (select count(*) = 2
   from public.meal_log_item_snapshots
   where meal_log_entry_id = (select first_id from t_tnyx_218_result)),
  'failed conflict/validation attempts must not mutate durable detailed items'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a2180000-0000-4000-8000-000000001002', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a2180000-0000-4000-8000-000000001002","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  (select count(*) = 0
   from public.meal_log_entries
   where id = (select first_id from t_tnyx_218_result)),
  'another authenticated user must not read the detailed parent'
);

select pg_temp.assert_true(
  (select count(*) = 0
   from public.meal_log_item_snapshots
   where meal_log_entry_id = (select first_id from t_tnyx_218_result)),
  'another authenticated user must not read detailed child snapshots'
);

reset role;

-- Manual compatibility remains untouched by the detailed RPC.
insert into public.meal_log_entries (
  id,
  user_id,
  mode,
  meal_category_id,
  consumed_at,
  consumed_local_date,
  consumed_utc_offset_minutes,
  capture_source,
  manual_nutrition_snapshot,
  client_mutation_id
) values (
  'a2180000-0000-4000-8000-000000001021',
  'a2180000-0000-4000-8000-000000001001',
  'manual',
  'meal_slot_1',
  '2026-09-17T13:00:00Z',
  '2026-09-17',
  330,
  'quick_add',
  '{"schemaVersion":1,"nutrients":{"energy":300}}',
  'a2180000-0000-4000-8000-000000001022'
);

select pg_temp.assert_true(
  (select mode = 'manual'
      and manual_nutrition_snapshot is not null
      and revision = 1
   from public.meal_log_entries
   where id = 'a2180000-0000-4000-8000-000000001021'),
  'existing manual persistence contract must remain valid'
);

rollback;
