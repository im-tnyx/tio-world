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

create function pg_temp.assert_raises(
  p_sql text,
  p_expected_sqlstate text,
  p_message text
)
returns void language plpgsql as $$
declare
  v_sqlstate text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_sqlstate = returned_sqlstate;
    if v_sqlstate = p_expected_sqlstate then
      return;
    end if;
    raise exception
      'assertion failed: % (expected SQLSTATE %, got %)',
      p_message,
      p_expected_sqlstate,
      v_sqlstate;
  end;

  raise exception 'assertion failed: % (statement unexpectedly succeeded)', p_message;
end;
$$;

-- Full replay ledger and core object contract.
select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260911114500'),
  'migration ledger must contain TNYX-194 exactly once'
);

select pg_temp.assert_true(
  pg_catalog.to_regclass('public.meal_log_entries') is not null,
  'meal_log_entries table must exist'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_catalog.pg_class
   where oid = 'public.meal_log_entries'::pg_catalog.regclass),
  'RLS must be enabled on meal_log_entries'
);

select pg_temp.assert_true(
  (select array_agg(column_name order by ordinal_position)
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries') = array[
    'id',
    'user_id',
    'mode',
    'meal_category_id',
    'meal_name',
    'note',
    'consumed_at',
    'consumed_local_date',
    'consumed_timezone_id',
    'consumed_utc_offset_minutes',
    'capture_source',
    'manual_nutrition_snapshot',
    'created_at',
    'updated_at'
  ]::text[],
  'meal_log_entries must expose only the approved V1 columns'
);

select pg_temp.assert_true(
  (select data_type = 'uuid' and is_nullable = 'NO'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'id'),
  'id must be a non-null UUID'
);

select pg_temp.assert_true(
  (select data_type = 'jsonb' and is_nullable = 'NO'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'manual_nutrition_snapshot'),
  'manual_nutrition_snapshot must be non-null jsonb'
);

select pg_temp.assert_true(
  (select data_type = 'date' and is_nullable = 'NO'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'consumed_local_date'),
  'consumed_local_date must be a non-null PostgreSQL date'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_user_id_fkey'
      and contype = 'f'
      and confrelid = 'public.users'::pg_catalog.regclass
      and confdeltype = 'c'
  ),
  'user ownership FK must target public.users with ON DELETE CASCADE'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'is_valid_nutrition_snapshot_v1'
      and p.provolatile = 'i'
      and p.proisstrict
      and not p.prosecdef
      and pg_catalog.pg_get_functiondef(p.oid) ilike '%SET search_path TO ''''%'
  ),
  'snapshot validator must be immutable, strict, SECURITY INVOKER, and use empty search_path'
);

select pg_temp.assert_true(
  has_function_privilege(
    'authenticated',
    'private.is_valid_nutrition_snapshot_v1(jsonb)',
    'EXECUTE'
  )
    and has_function_privilege(
      'service_role',
      'private.is_valid_nutrition_snapshot_v1(jsonb)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'private.is_valid_nutrition_snapshot_v1(jsonb)',
      'EXECUTE'
    ),
  'validator execution must be limited to authenticated and service_role'
);

-- Current NutritionSnapshot codec semantics.
select pg_temp.assert_true(
  private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1,"nutrients":{"energy":500,"protein":35,"fiber":0}}'::jsonb
  ),
  'valid known nutrient values must be accepted'
);

select pg_temp.assert_true(
  private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":2,"nutrients":{"energy":500,"future_nutrient":{"shape":"unknown"}},"futureEnvelopeField":true}'::jsonb
  ),
  'unknown future nutrient identities and envelope fields must remain forward-compatible'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1.5,"nutrients":{}}'::jsonb
  ),
  'schemaVersion must be an integer'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1,"nutrients":{"energy":-1}}'::jsonb
  ),
  'negative known nutrient amounts must be rejected'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1,"nutrients":{"protein":"35"}}'::jsonb
  ),
  'non-numeric known nutrient amounts must be rejected'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1}'::jsonb
  ),
  'missing nutrients map must be rejected'
);

-- Grants and policies are separate security controls.
select pg_temp.assert_true(
  not has_table_privilege('anon', 'public.meal_log_entries', 'SELECT')
    and not has_table_privilege('anon', 'public.meal_log_entries', 'INSERT')
    and not has_table_privilege('anon', 'public.meal_log_entries', 'UPDATE')
    and not has_table_privilege('anon', 'public.meal_log_entries', 'DELETE'),
  'anon must hold no MealLog DML privileges'
);

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.meal_log_entries', 'SELECT')
    and has_table_privilege('authenticated', 'public.meal_log_entries', 'INSERT')
    and has_table_privilege('authenticated', 'public.meal_log_entries', 'UPDATE')
    and has_table_privilege('authenticated', 'public.meal_log_entries', 'DELETE')
    and not has_table_privilege('authenticated', 'public.meal_log_entries', 'TRUNCATE'),
  'authenticated must receive only intended MealLog DML access'
);

select pg_temp.assert_true(
  has_table_privilege('service_role', 'public.meal_log_entries', 'SELECT')
    and has_table_privilege('service_role', 'public.meal_log_entries', 'INSERT')
    and has_table_privilege('service_role', 'public.meal_log_entries', 'UPDATE')
    and has_table_privilege('service_role', 'public.meal_log_entries', 'DELETE')
    and not has_table_privilege('service_role', 'public.meal_log_entries', 'TRUNCATE'),
  'service_role must receive explicit DML without broad table privileges'
);

select pg_temp.assert_true(
  (select array_agg(policyname order by policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public' and tablename = 'meal_log_entries') = array[
    'meal_log_entries_delete_own',
    'meal_log_entries_insert_own',
    'meal_log_entries_select_own',
    'meal_log_entries_update_own'
  ]::name[],
  'exactly four own-row CRUD policies must exist'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename = 'meal_log_entries'
      and roles <> array['authenticated']::name[]
  ),
  'all MealLog policies must target authenticated only'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_indexes
    where schemaname = 'public'
      and tablename = 'meal_log_entries'
      and indexname = 'idx_meal_log_entries_user_local_date_consumed_at'
      and indexdef ilike '%(user_id, consumed_local_date, consumed_at DESC)%'
  ),
  'Diary-oriented user/local-date/chronology index must exist'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_trigger
    where tgrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and tgname = 'trg_meal_log_entries_updated_at'
      and not tgisinternal
  ),
  'updated_at trigger must exist'
);

-- Provision two domain users through the existing auth -> public.users path.
insert into auth.users (id, email)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'tnyx-194-a@example.test'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'tnyx-194-b@example.test');

select pg_temp.assert_true(
  (select count(*) = 2
   from public.users
   where id in (
     'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid,
     'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid
   )),
  'auth provisioning must produce both public.users owners'
);

-- Canonical valid rows and defaults.
insert into public.meal_log_entries (
  user_id,
  mode,
  meal_category_id,
  meal_name,
  note,
  consumed_at,
  consumed_local_date,
  consumed_timezone_id,
  capture_source,
  manual_nutrition_snapshot,
  updated_at
)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'manual',
  'meal_slot_1',
  'Breakfast',
  'Before training',
  '2026-09-11T02:30:00Z',
  '2026-09-11',
  'Asia/Kolkata',
  'quick_add',
  '{"schemaVersion":1,"nutrients":{"energy":500,"protein":35}}',
  '2000-01-01T00:00:00Z'
), (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'manual',
  'meal_slot_2',
  null,
  null,
  '2026-09-11T07:00:00Z',
  '2026-09-11',
  null,
  null,
  '{"schemaVersion":1,"nutrients":{}}',
  '2000-01-01T00:00:00Z'
);

update public.meal_log_entries
set note = 'Updated note'
where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select pg_temp.assert_true(
  (select updated_at > '2000-01-01T00:00:00Z'::timestamptz
   from public.meal_log_entries
   where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  'updated_at trigger must refresh timestamps on update'
);

-- The second valid row used offset-only context.
update public.meal_log_entries
set consumed_utc_offset_minutes = 330
where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

-- Manual-only and physical-shape checks.
select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      consumed_utc_offset_minutes, manual_nutrition_snapshot
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'detailed', 'meal_slot_1',
      '2026-09-11T02:30:00Z', '2026-09-11', 330,
      '{"schemaVersion":1,"nutrients":{}}'
    )$$,
  '23514',
  'detailed mode must remain blocked in V1'
);

select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      manual_nutrition_snapshot
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'manual', 'meal_slot_1',
      '2026-09-11T02:30:00Z', '2026-09-11',
      '{"schemaVersion":1,"nutrients":{}}'
    )$$,
  '23514',
  'a timezone ID or UTC offset must be required'
);

select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      consumed_timezone_id, manual_nutrition_snapshot
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'manual', 'meal_slot_1',
      '2026-09-11T02:30:00Z', '2026-09-11', '   ',
      '{"schemaVersion":1,"nutrients":{}}'
    )$$,
  '23514',
  'blank timezone IDs must not be persisted as meaningful context'
);

select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      consumed_utc_offset_minutes, capture_source, manual_nutrition_snapshot
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'manual', 'meal_slot_1',
      '2026-09-11T02:30:00Z', '2026-09-11', 330, 'provider_magic',
      '{"schemaVersion":1,"nutrients":{}}'
    )$$,
  '23514',
  'unknown capture source values must be rejected instead of fabricated'
);

select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      consumed_utc_offset_minutes, manual_nutrition_snapshot
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'manual', 'meal_slot_1',
      '2026-09-11T02:30:00Z', '2026-09-11', 330,
      '{"schemaVersion":1,"nutrients":{"energy":-1}}'
    )$$,
  '23514',
  'invalid manual nutrition snapshots must be rejected by the table CHECK'
);

-- Authenticated own-row behavior. User A sees only A and may mutate only A.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.meal_log_entries),
  'user A SELECT must see only user A rows'
);

insert into public.meal_log_entries (
  user_id,
  mode,
  meal_category_id,
  consumed_at,
  consumed_local_date,
  consumed_utc_offset_minutes,
  capture_source,
  manual_nutrition_snapshot
)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'manual',
  'meal_slot_4',
  '2026-09-11T09:00:00Z',
  '2026-09-11',
  330,
  'quick_add',
  '{"schemaVersion":1,"nutrients":{"energy":100}}'
);

select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      consumed_utc_offset_minutes, manual_nutrition_snapshot
    ) values (
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'manual', 'meal_slot_1',
      '2026-09-11T09:00:00Z', '2026-09-11', 330,
      '{"schemaVersion":1,"nutrients":{}}'
    )$$,
  '42501',
  'user A must not insert a row owned by user B'
);

select pg_temp.assert_raises(
  $$update public.meal_log_entries
    set user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
    where meal_category_id = 'meal_slot_4'$$,
  '42501',
  'UPDATE WITH CHECK must prevent ownership reassignment'
);

delete from public.meal_log_entries
where meal_category_id = 'meal_slot_4';

reset role;

select pg_temp.assert_true(
  (select count(*) = 1
   from public.meal_log_entries
   where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
  'user B row must remain untouched by user A operations'
);

rollback;
