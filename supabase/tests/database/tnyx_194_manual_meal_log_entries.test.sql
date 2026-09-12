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

-- Migration ledger and physical contract.
select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260911114500'),
  'migration ledger must contain TNYX-194 exactly once'
);

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260911143309'),
  'migration ledger must contain TNYX-196 exactly once'
);

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260912064635'),
  'migration ledger must contain TNYX-203 exactly once'
);

select pg_temp.assert_true(
  pg_catalog.to_regclass('public.meal_log_entries') is not null,
  'meal_log_entries table must exist'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_catalog.pg_class
   where oid = 'public.meal_log_entries'::pg_catalog.regclass),
  'RLS must be enabled'
);

select pg_temp.assert_true(
  (select array_agg(column_name::text order by ordinal_position)
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries') = array[
    'id', 'user_id', 'mode', 'meal_category_id', 'meal_name', 'note',
    'consumed_at', 'consumed_local_date', 'consumed_timezone_id',
    'consumed_utc_offset_minutes', 'capture_source',
    'manual_nutrition_snapshot', 'created_at', 'updated_at',
    'client_mutation_id', 'revision'
  ]::text[],
  'only approved current MealLog columns may exist'
);

select pg_temp.assert_true(
  (select data_type = 'uuid' and is_nullable = 'NO'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'id'),
  'id must be non-null UUID'
);

select pg_temp.assert_true(
  (select data_type = 'jsonb' and is_nullable = 'NO'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'manual_nutrition_snapshot'),
  'manual snapshot must be non-null jsonb'
);

select pg_temp.assert_true(
  (select data_type = 'date' and is_nullable = 'NO'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'consumed_local_date'),
  'consumed_local_date must be non-null date'
);

select pg_temp.assert_true(
  (select data_type = 'uuid' and is_nullable = 'YES'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'meal_log_entries'
     and column_name = 'client_mutation_id'),
  'client_mutation_id must be nullable UUID for historical compatibility'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_user_client_mutation_id_key'
      and contype = 'u'
      and pg_catalog.pg_get_constraintdef(oid) =
        'UNIQUE (user_id, client_mutation_id)'
  ),
  'client mutation identity must be unique per owner'
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
  'owner FK must target public.users ON DELETE CASCADE'
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
  'Diary index must use user/local-date/chronology'
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

-- Hardened private snapshot validator.
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
  'validator must be immutable, strict, invoker, empty-search-path'
);

select pg_temp.assert_true(
  has_function_privilege(
    'authenticated', 'private.is_valid_nutrition_snapshot_v1(jsonb)', 'EXECUTE'
  )
    and has_function_privilege(
      'service_role', 'private.is_valid_nutrition_snapshot_v1(jsonb)', 'EXECUTE'
    )
    and not has_function_privilege(
      'anon', 'private.is_valid_nutrition_snapshot_v1(jsonb)', 'EXECUTE'
    ),
  'validator execute privilege must exclude anon'
);

select pg_temp.assert_true(
  private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1,"nutrients":{"energy":500,"protein":35,"fiber":0}}'
  ),
  'known non-negative nutrients must be accepted'
);

select pg_temp.assert_true(
  private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":2,"nutrients":{"energy":500,"future_nutrient":{"shape":"unknown"}},"futureEnvelopeField":true}'
  ),
  'unknown future fields must remain forward-compatible'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1.5,"nutrients":{}}'
  ),
  'schemaVersion must be integer-shaped'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1,"nutrients":{"energy":-1}}'
  ),
  'negative known nutrient must be rejected'
);

select pg_temp.assert_true(
  not private.is_valid_nutrition_snapshot_v1(
    '{"schemaVersion":1,"nutrients":{"protein":"35"}}'
  ),
  'non-numeric known nutrient must be rejected'
);

-- Grants + RLS are both required.
select pg_temp.assert_true(
  not has_table_privilege('anon', 'public.meal_log_entries', 'SELECT')
    and not has_table_privilege('anon', 'public.meal_log_entries', 'INSERT')
    and not has_table_privilege('anon', 'public.meal_log_entries', 'UPDATE')
    and not has_table_privilege('anon', 'public.meal_log_entries', 'DELETE'),
  'anon must have no MealLog DML grants'
);

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.meal_log_entries', 'SELECT')
    and has_table_privilege('authenticated', 'public.meal_log_entries', 'INSERT')
    and has_table_privilege('authenticated', 'public.meal_log_entries', 'UPDATE')
    and has_table_privilege('authenticated', 'public.meal_log_entries', 'DELETE')
    and not has_table_privilege('authenticated', 'public.meal_log_entries', 'TRUNCATE'),
  'authenticated must have only intended DML'
);

select pg_temp.assert_true(
  has_table_privilege('service_role', 'public.meal_log_entries', 'SELECT')
    and has_table_privilege('service_role', 'public.meal_log_entries', 'INSERT')
    and has_table_privilege('service_role', 'public.meal_log_entries', 'UPDATE')
    and has_table_privilege('service_role', 'public.meal_log_entries', 'DELETE')
    and not has_table_privilege('service_role', 'public.meal_log_entries', 'TRUNCATE'),
  'service_role must have explicit DML only'
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
  'exactly four owner CRUD policies must exist'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename = 'meal_log_entries'
      and roles <> array['authenticated']::name[]
  ),
  'all policies must target authenticated only'
);

-- Provision two owners via the existing auth -> public.users contract.
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
  'both domain owner rows must be provisioned'
);

-- One timezone-ID row and one offset-only row prove both valid shapes. They
-- intentionally omit client_mutation_id to prove historical null compatibility.
insert into public.meal_log_entries (
  user_id, mode, meal_category_id, meal_name, note,
  consumed_at, consumed_local_date, consumed_timezone_id,
  capture_source, manual_nutrition_snapshot, updated_at
)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'manual', 'meal_slot_1', 'Breakfast', 'Before training',
  '2026-09-11T02:30:00Z', '2026-09-11', 'Asia/Kolkata',
  'quick_add',
  '{"schemaVersion":1,"nutrients":{"energy":500,"protein":35}}',
  '2000-01-01T00:00:00Z'
);

insert into public.meal_log_entries (
  user_id, mode, meal_category_id,
  consumed_at, consumed_local_date, consumed_utc_offset_minutes,
  manual_nutrition_snapshot, updated_at
)
values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'manual', 'meal_slot_2',
  '2026-09-11T07:00:00Z', '2026-09-11', 330,
  '{"schemaVersion":1,"nutrients":{}}',
  '2000-01-01T00:00:00Z'
);

select pg_temp.assert_true(
  (select count(*) = 2
   from public.meal_log_entries
   where client_mutation_id is null),
  'historical rows may retain null client mutation identity'
);

update public.meal_log_entries
set note = 'Updated note'
where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select pg_temp.assert_true(
  (select updated_at > '2000-01-01T00:00:00Z'::timestamptz
   from public.meal_log_entries
   where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  'updated_at trigger must refresh timestamp'
);

-- Manual-only and shape constraints.
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
  'detailed mode must be blocked in V1'
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
  'time context must be required'
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
  'blank timezone ID must not count as context'
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
  'unknown capture source must be rejected'
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
  'invalid snapshot must fail table CHECK'
);

-- Authenticated owner isolation.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.meal_log_entries),
  'user A SELECT must see only user A row'
);

insert into public.meal_log_entries (
  user_id, mode, meal_category_id,
  consumed_at, consumed_local_date, consumed_utc_offset_minutes,
  capture_source, manual_nutrition_snapshot
)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'manual', 'meal_slot_4',
  '2026-09-11T09:00:00Z', '2026-09-11', 330,
  'quick_add', '{"schemaVersion":1,"nutrients":{"energy":100}}'
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
  'user A must not insert user B row'
);

select pg_temp.assert_raises(
  $$update public.meal_log_entries
    set user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
    where meal_category_id = 'meal_slot_4'$$,
  '42501',
  'WITH CHECK must block ownership reassignment'
);

delete from public.meal_log_entries
where meal_category_id = 'meal_slot_4';

reset role;

select pg_temp.assert_true(
  (select count(*) = 1
   from public.meal_log_entries
   where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
  'user B row must remain untouched by user A'
);

-- TNYX-196 owner-scoped idempotency: the same logical UUID is allowed for a
-- different owner, but never twice for one owner.
insert into public.meal_log_entries (
  user_id, mode, meal_category_id,
  consumed_at, consumed_local_date, consumed_utc_offset_minutes,
  manual_nutrition_snapshot, client_mutation_id
)
values
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'manual', 'meal_slot_1',
    '2026-09-11T10:00:00Z', '2026-09-11', 330,
    '{"schemaVersion":1,"nutrients":{"energy":200}}',
    '11111111-1111-4111-8111-111111111111'
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'manual', 'meal_slot_1',
    '2026-09-11T10:00:00Z', '2026-09-11', 330,
    '{"schemaVersion":1,"nutrients":{"energy":200}}',
    '11111111-1111-4111-8111-111111111111'
  );

select pg_temp.assert_raises(
  $$insert into public.meal_log_entries (
      user_id, mode, meal_category_id, consumed_at, consumed_local_date,
      consumed_utc_offset_minutes, manual_nutrition_snapshot,
      client_mutation_id
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'manual', 'meal_slot_2',
      '2026-09-11T10:01:00Z', '2026-09-11', 330,
      '{"schemaVersion":1,"nutrients":{"energy":250}}',
      '11111111-1111-4111-8111-111111111111'
    )$$,
  '23505',
  'same owner and client mutation id must reject duplicate durable effect'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  (select count(*) = 1
   from public.meal_log_entries
   where client_mutation_id =
     '11111111-1111-4111-8111-111111111111'::uuid),
  'owner-scoped RLS must expose only the authenticated owner mutation row'
);

reset role;

rollback;
