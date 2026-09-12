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

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260912064635'),
  'migration ledger must contain TNYX-203 exactly once'
);

select pg_temp.assert_true(
  (select data_type = 'bigint'
      and is_nullable = 'NO'
      and column_default is not null
   from information_schema.columns
   where table_schema = 'public'
     and table_name = 'meal_log_entries'
     and column_name = 'revision'),
  'revision must be non-null bigint with a default'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_revision_positive'
      and contype = 'c'
      and pg_catalog.pg_get_constraintdef(oid) ilike '%revision%>= 1%'
  ),
  'revision must have the positive check invariant'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'enforce_meal_log_revision'
      and not p.prosecdef
      and pg_catalog.pg_get_functiondef(p.oid) ilike '%SET search_path TO ''''%'
  ),
  'revision trigger helper must be invoker with empty search path'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_trigger
    where tgrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and tgname = 'trg_meal_log_entries_revision'
      and not tgisinternal
      and pg_catalog.pg_get_triggerdef(oid) ilike '%BEFORE INSERT OR UPDATE%'
  ),
  'revision trigger must own both insert initialization and update increments'
);

select pg_temp.assert_true(
  not has_function_privilege(
    'anon', 'private.enforce_meal_log_revision()', 'EXECUTE'
  )
    and not has_function_privilege(
      'authenticated', 'private.enforce_meal_log_revision()', 'EXECUTE'
    )
    and not has_function_privilege(
      'service_role', 'private.enforce_meal_log_revision()', 'EXECUTE'
    ),
  'revision trigger helper must not be directly executable by API roles'
);

insert into auth.users (id, email)
values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'tnyx-203@example.test');

insert into public.meal_log_entries (
  id, user_id, mode, meal_category_id, meal_name,
  consumed_at, consumed_local_date, consumed_utc_offset_minutes,
  capture_source, manual_nutrition_snapshot, client_mutation_id, revision
)
values (
  'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  'manual', 'meal_slot_1', 'Lunch',
  '2026-09-12T06:30:00Z', '2026-09-12', 330,
  'quick_add',
  '{"schemaVersion":1,"nutrients":{"energy":500,"protein":25}}',
  '11111111-1111-4111-8111-111111111111',
  999
);

select pg_temp.assert_true(
  (select revision = 1
   from public.meal_log_entries
   where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'server must force every new MealLog revision to 1'
);

with winner as (
  update public.meal_log_entries
  set meal_name = 'Winner edit', revision = 999
  where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
    and revision = 1
  returning revision
)
select pg_temp.assert_true(
  (select count(*) = 1 and max(revision) = 2 from winner),
  'successful expected-revision update must advance exactly once to 2'
);

with stale as (
  update public.meal_log_entries
  set meal_name = 'Stale overwrite'
  where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
    and revision = 1
  returning id
)
select pg_temp.assert_true(
  (select count(*) = 0 from stale),
  'stale expected revision must match zero rows'
);

select pg_temp.assert_true(
  (select revision = 2 and meal_name = 'Winner edit'
   from public.meal_log_entries
   where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'stale update must not overwrite newer durable facts'
);

select pg_temp.assert_raises(
  $$update public.meal_log_entries
    set capture_source = 'text'
    where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'$$,
  '23514',
  'capture provenance must remain immutable'
);

select pg_temp.assert_raises(
  $$update public.meal_log_entries
    set client_mutation_id = '22222222-2222-4222-8222-222222222222'
    where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'$$,
  '23514',
  'create mutation identity must remain immutable'
);

select pg_temp.assert_raises(
  $$update public.meal_log_entries
    set created_at = '2020-01-01T00:00:00Z'
    where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'$$,
  '23514',
  'created_at must remain immutable'
);

select pg_temp.assert_true(
  (select revision = 2
      and capture_source = 'quick_add'
      and client_mutation_id = '11111111-1111-4111-8111-111111111111'::uuid
   from public.meal_log_entries
   where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'failed immutable-field attempts must not advance revision or mutate provenance'
);

rollback;
