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

create temp table meal_category_fixtures (
  fixture_name text primary key,
  config jsonb not null
);

insert into meal_category_fixtures (fixture_name, config)
values
  ('canonical', '{"schema_version":1,"items":[
    {"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},
    {"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},
    {"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},
    {"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3}
  ]}'::jsonb),
  ('custom_one', '{"schema_version":1,"items":[
    {"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},
    {"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},
    {"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},
    {"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3},
    {"id":"meal_slot_11111111-1111-4111-8111-111111111111","display_name":"Second breakfast","active":true,"order":4}
  ]}'::jsonb),
  ('eight_active', '{"schema_version":1,"items":[
    {"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},
    {"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},
    {"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},
    {"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3},
    {"id":"meal_slot_11111111-1111-4111-8111-111111111111","display_name":"Meal 5","active":true,"order":4},
    {"id":"meal_slot_22222222-2222-4222-8222-222222222222","display_name":"Meal 6","active":true,"order":5},
    {"id":"meal_slot_33333333-3333-4333-8333-333333333333","display_name":"Meal 7","active":true,"order":6},
    {"id":"meal_slot_44444444-4444-4444-8444-444444444444","display_name":"Meal 8","active":true,"order":7}
  ]}'::jsonb),
  ('eight_active_archived_extras', '{"schema_version":1,"items":[
    {"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},
    {"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},
    {"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},
    {"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3},
    {"id":"meal_slot_11111111-1111-4111-8111-111111111111","display_name":"Meal 5","active":true,"order":4},
    {"id":"meal_slot_22222222-2222-4222-8222-222222222222","display_name":"Meal 6","active":true,"order":5},
    {"id":"meal_slot_33333333-3333-4333-8333-333333333333","display_name":"Meal 7","active":true,"order":6},
    {"id":"meal_slot_44444444-4444-4444-8444-444444444444","display_name":"Meal 8","active":true,"order":7},
    {"id":"meal_slot_55555555-5555-4555-8555-555555555555","display_name":"Archived 1","active":false,"order":8},
    {"id":"meal_slot_66666666-6666-4666-8666-666666666666","display_name":"Archived 2","active":false,"order":9}
  ]}'::jsonb),
  ('retained_active_and_archived', '{"schema_version":1,"items":[
    {"id":"meal_slot_1","default_key":"breakfast","display_name":"Breakfast","active":true,"order":0},
    {"id":"meal_slot_2","default_key":"lunch","display_name":"Lunch","active":true,"order":1},
    {"id":"meal_slot_3","default_key":"dinner","display_name":"Dinner","active":true,"order":2},
    {"id":"meal_slot_4","default_key":"snacks","display_name":"Snacks","active":true,"order":3},
    {"id":"meal_slot_77777777-7777-4777-8777-777777777777","display_name":"Retained active","active":true,"order":4},
    {"id":"meal_slot_88888888-8888-4888-8888-888888888888","display_name":"Retained archived","active":false,"order":5}
  ]}'::jsonb);

-- The same psql session deliberately switches into client roles below. Grant
-- those roles read-only access to this transaction-local test fixture only.
grant select on pg_temp.meal_category_fixtures to authenticated, anon;

create function pg_temp.fixture(p_name text)
returns jsonb language sql stable as $$
  select config from pg_temp.meal_category_fixtures where fixture_name = p_name
$$;

create function pg_temp.large_archived_config(p_archived_count integer)
returns jsonb language sql stable as $$
  select pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'items',
    pg_temp.fixture('canonical') -> 'items'
      || pg_catalog.coalesce(
        (
          select pg_catalog.jsonb_agg(
            pg_catalog.jsonb_build_object(
              'id',
              'meal_slot_'
                || pg_catalog.lpad(item_number::text, 8, '0')
                || '-0000-4000-8000-'
                || pg_catalog.lpad(item_number::text, 12, '0'),
              'display_name', 'Archived ' || item_number,
              'active', false,
              'order', item_number + 3
            )
            order by item_number
          )
          from pg_catalog.generate_series(1, p_archived_count)
            as archived(item_number)
        ),
        '[]'::jsonb
      )
  )
$$;

create function pg_temp.test_user_id(p_suffix integer)
returns uuid language sql immutable as $$
  select ('00000000-0000-4000-8000-' || lpad(p_suffix::text, 12, '0'))::uuid
$$;

create function pg_temp.assert_insert_accepted(p_suffix integer, p_config jsonb, p_label text)
returns void language plpgsql as $$
declare
  v_user_id uuid := pg_temp.test_user_id(p_suffix);
begin
  insert into auth.users (id, email)
  values (v_user_id, 'accepted-' || p_suffix || '@example.test');
  insert into public.user_nutrition_profiles (user_id, meal_categories_config)
  values (v_user_id, p_config);
  perform pg_temp.assert_true(
    (select meal_categories_config is not distinct from p_config
     from public.user_nutrition_profiles where user_id = v_user_id),
    p_label
  );
  delete from auth.users where id = v_user_id;
end;
$$;

create function pg_temp.assert_insert_rejected(p_suffix integer, p_config jsonb, p_label text)
returns void language plpgsql as $$
declare
  v_user_id uuid := pg_temp.test_user_id(p_suffix);
  v_rejected boolean := false;
begin
  insert into auth.users (id, email)
  values (v_user_id, 'rejected-' || p_suffix || '@example.test');
  begin
    insert into public.user_nutrition_profiles (user_id, meal_categories_config)
    values (v_user_id, p_config);
  exception when check_violation then
    v_rejected := true;
  end;
  perform pg_temp.assert_true(v_rejected, p_label);
  delete from auth.users where id = v_user_id;
end;
$$;

create function pg_temp.assert_update_rejected(p_user_id uuid, p_config jsonb, p_label text)
returns void language plpgsql as $$
declare
  v_rejected boolean := false;
begin
  begin
    update public.user_nutrition_profiles
    set meal_categories_config = p_config
    where user_id = p_user_id;
  exception when check_violation then
    v_rejected := true;
  end;
  perform pg_temp.assert_true(v_rejected, p_label);
end;
$$;

-- Full replay ledger and database object contract.
select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260907065602'),
  'migration ledger must contain TNYX-67 Slice B1 exactly once'
);
select pg_temp.assert_true(
  (select data_type = 'jsonb' and is_nullable = 'YES' and column_default is null
   from information_schema.columns
   where table_schema = 'public' and table_name = 'user_nutrition_profiles'
     and column_name = 'meal_categories_config'),
  'meal_categories_config must be nullable jsonb with no default'
);
select pg_temp.assert_true(
  exists (select 1 from pg_catalog.pg_constraint
          where conrelid = 'public.user_nutrition_profiles'::regclass
            and conname = 'user_nutrition_profiles_meal_categories_config_valid'
            and contype = 'c' and convalidated),
  'validated CHECK constraint must exist'
);
select pg_temp.assert_true(
  exists (select 1 from pg_catalog.pg_proc p
          join pg_catalog.pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'private'
            and p.proname = 'is_valid_meal_categories_config_v1'
            and p.provolatile = 'i' and p.proisstrict and not p.prosecdef
            and pg_catalog.pg_get_functiondef(p.oid) ilike '%SET search_path TO ''''%'),
  'validator must be immutable, strict, SECURITY INVOKER, with empty search_path'
);
select pg_temp.assert_true(
  exists (select 1 from pg_catalog.pg_proc p
          join pg_catalog.pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'private'
            and p.proname = 'protect_meal_category_retained_ids'
            and not p.prosecdef
            and pg_catalog.pg_get_functiondef(p.oid) ilike '%SET search_path TO ''''%'),
  'trigger function must be SECURITY INVOKER with empty search_path'
);
select pg_temp.assert_true(
  exists (select 1 from pg_catalog.pg_trigger
          where tgrelid = 'public.user_nutrition_profiles'::regclass
            and tgname = 'trg_user_nutrition_profiles_protect_meal_category_retained_ids'
            and not tgisinternal and (tgtype & 1) = 1 and (tgtype & 2) = 2
            and (tgtype & 16) = 16),
  'row-level BEFORE UPDATE trigger must exist'
);

-- Function exposure is deliberately minimal.
select pg_temp.assert_true(
  has_schema_privilege('authenticated', 'private', 'USAGE')
    and has_schema_privilege('service_role', 'private', 'USAGE')
    and not has_schema_privilege('anon', 'private', 'USAGE'),
  'private schema usage must remain limited to existing server/write roles'
);
select pg_temp.assert_true(
  has_function_privilege('authenticated', 'private.is_valid_meal_categories_config_v1(jsonb)', 'EXECUTE')
    and has_function_privilege('service_role', 'private.is_valid_meal_categories_config_v1(jsonb)', 'EXECUTE')
    and not has_function_privilege('anon', 'private.is_valid_meal_categories_config_v1(jsonb)', 'EXECUTE'),
  'only authenticated and service_role may execute the validator'
);
select pg_temp.assert_true(
  not has_function_privilege('authenticated', 'private.protect_meal_category_retained_ids()', 'EXECUTE')
    and not has_function_privilege('service_role', 'private.protect_meal_category_retained_ids()', 'EXECUTE')
    and not has_function_privilege('anon', 'private.protect_meal_category_retained_ids()', 'EXECUTE'),
  'trigger function must not be directly executable by client roles'
);

-- RLS remains owner-scoped, with standalone Nutrition Profile deletion closed.
select pg_temp.assert_true(
  (select relrowsecurity from pg_catalog.pg_class
   where oid = 'public.user_nutrition_profiles'::regclass),
  'RLS must remain enabled'
);
select pg_temp.assert_true(
  (select array_agg(policyname order by policyname) from pg_catalog.pg_policies
   where schemaname = 'public' and tablename = 'user_nutrition_profiles') = array[
    'user_nutrition_profiles_insert_own',
    'user_nutrition_profiles_select_own',
    'user_nutrition_profiles_update_own'
  ]::name[],
  'only SELECT, INSERT, and UPDATE owner policies may remain'
);
select pg_temp.assert_true(
  not exists (select 1 from pg_catalog.pg_policies
              where schemaname = 'public' and tablename = 'user_nutrition_profiles'
                and roles <> array['authenticated']::name[]),
  'all nutrition profile policies must remain authenticated-only'
);

-- Accepted table writes.
select pg_temp.assert_insert_accepted(1, null, 'SQL NULL must be accepted');
select pg_temp.assert_insert_accepted(2, pg_temp.fixture('canonical'), 'canonical config must be accepted');
select pg_temp.assert_insert_accepted(
  3, jsonb_set(pg_temp.fixture('canonical'), '{items,0,display_name}', '"Morning meal"'),
  'renamed canonical label must be accepted'
);
select pg_temp.assert_insert_accepted(
  4, jsonb_set(jsonb_set(pg_temp.fixture('canonical'), '{items,0,order}', '1'), '{items,1,order}', '0'),
  'reordered canonical config must be accepted'
);
select pg_temp.assert_insert_accepted(5, pg_temp.fixture('eight_active'), 'eight active categories must be accepted');
select pg_temp.assert_insert_accepted(
  6, pg_temp.fixture('eight_active_archived_extras'),
  'eight active plus archived categories must be accepted'
);
select pg_temp.assert_insert_accepted(7, pg_temp.fixture('custom_one'), 'valid custom UUID-v4 category must be accepted');
select pg_temp.assert_insert_accepted(
  8, pg_temp.large_archived_config(512),
  'large retained archived set must be accepted without a total-item cap'
);

-- Rejected structural and semantic table writes.
create temp table rejected_meal_category_cases (
  case_id integer primary key,
  label text not null,
  config jsonb not null
);
insert into rejected_meal_category_cases (case_id, label, config)
select 101, 'root array', '[]'::jsonb union all
select 102, 'missing root key', jsonb_build_object('items', pg_temp.fixture('canonical')->'items') union all
select 103, 'extra root key', pg_temp.fixture('canonical') || '{"extra":true}'::jsonb union all
select 104, 'schema_version string', jsonb_set(pg_temp.fixture('canonical'), '{schema_version}', '"1"') union all
select 105, 'unsupported schema_version', jsonb_set(pg_temp.fixture('canonical'), '{schema_version}', '2') union all
select 106, 'non-canonical numeric schema_version', jsonb_set(pg_temp.fixture('canonical'), '{schema_version}', '1.0') union all
select 107, 'items object', jsonb_set(pg_temp.fixture('canonical'), '{items}', '{}') union all
select 108, 'non-object item', jsonb_set(pg_temp.fixture('canonical'), '{items}', (pg_temp.fixture('canonical')->'items') || jsonb_build_array(5)) union all
select 109, 'missing item field', jsonb_set(pg_temp.fixture('canonical'), '{items,0}', (pg_temp.fixture('canonical')->'items'->0) - 'display_name') union all
select 110, 'extra item field', jsonb_set(pg_temp.fixture('canonical'), '{items,0}', (pg_temp.fixture('canonical')->'items'->0) || '{"extra":true}'::jsonb) union all
select 111, 'non-string display_name', jsonb_set(pg_temp.fixture('canonical'), '{items,0,display_name}', '7') union all
select 112, 'non-boolean active', jsonb_set(pg_temp.fixture('canonical'), '{items,0,active}', '"true"') union all
select 113, 'fractional order', jsonb_set(pg_temp.fixture('canonical'), '{items,0,order}', '0.5') union all
select 114, 'negative order', jsonb_set(pg_temp.fixture('canonical'), '{items,0,order}', '-1') union all
select 115, 'duplicate id', jsonb_set(pg_temp.fixture('canonical'), '{items,1,id}', '"meal_slot_1"') union all
select 116, 'duplicate order', jsonb_set(pg_temp.fixture('canonical'), '{items,1,order}', '0') union all
select 117, 'missing canonical category', jsonb_set(
  pg_temp.fixture('canonical'), '{items}',
  (select jsonb_agg(value) from jsonb_array_elements(pg_temp.fixture('canonical')->'items')
   where value->>'id' <> 'meal_slot_4')
) union all
select 118, 'wrong canonical mapping', jsonb_set(pg_temp.fixture('canonical'), '{items,0,default_key}', '"lunch"') union all
select 119, 'custom default_key', jsonb_set(pg_temp.fixture('custom_one'), '{items,4,default_key}', '"breakfast"') union all
select 120, 'invalid custom id', jsonb_set(pg_temp.fixture('custom_one'), '{items,4,id}', '"meal_slot_custom"') union all
select 121, 'nine active categories', jsonb_set(
  pg_temp.fixture('eight_active'), '{items}',
  (pg_temp.fixture('eight_active')->'items') || jsonb_build_array(
    '{"id":"meal_slot_99999999-9999-4999-8999-999999999999","display_name":"Meal 9","active":true,"order":8}'::jsonb
  )
) union all
select 122, 'duplicate ID in large archived set', jsonb_set(
  pg_temp.large_archived_config(512),
  '{items,5,id}',
  '"meal_slot_00000001-0000-4000-8000-000000000001"'::jsonb
);

do $$
declare v_case record;
begin
  for v_case in select case_id, label, config from pg_temp.rejected_meal_category_cases order by case_id loop
    perform pg_temp.assert_insert_rejected(v_case.case_id, v_case.config, 'must reject ' || v_case.label);
  end loop;
end;
$$;

-- Retained identities: normal identity-preserving changes pass; removals fail.
insert into auth.users (id, email)
values ('00000000-0000-4000-8000-000000000500', 'retained@example.test');
insert into public.user_nutrition_profiles (user_id, meal_categories_config)
values ('00000000-0000-4000-8000-000000000500', pg_temp.fixture('retained_active_and_archived'));

update public.user_nutrition_profiles
set meal_categories_config = jsonb_set(
  jsonb_set(jsonb_set(meal_categories_config, '{items,4,display_name}', '"Renamed retained"'),
            '{items,4,active}', 'false'),
  '{items,4,order}', '6'
)
where user_id = '00000000-0000-4000-8000-000000000500';
select pg_temp.assert_true(
  (select meal_categories_config->'items'->4->>'display_name' = 'Renamed retained'
          and not (meal_categories_config->'items'->4->>'active')::boolean
   from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500'),
  'rename, archive, and reorder must succeed while retaining IDs'
);
update public.user_nutrition_profiles
set meal_categories_config = jsonb_set(meal_categories_config, '{items,4,active}', 'true')
where user_id = '00000000-0000-4000-8000-000000000500';
select pg_temp.assert_true(
  (select (meal_categories_config->'items'->4->>'active')::boolean
   from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500'),
  'reactivation must succeed while retaining IDs'
);

select pg_temp.assert_update_rejected(
  '00000000-0000-4000-8000-000000000500', null,
  'non-null to NULL must be rejected'
);
select pg_temp.assert_update_rejected(
  '00000000-0000-4000-8000-000000000500',
  jsonb_set(
    (select meal_categories_config from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500'),
    '{items}',
    (select jsonb_agg(value order by ordinality)
     from jsonb_array_elements((select meal_categories_config->'items' from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500')) with ordinality
     where value->>'id' <> 'meal_slot_1')
  ),
  'canonical retained ID removal must be rejected'
);
select pg_temp.assert_update_rejected(
  '00000000-0000-4000-8000-000000000500',
  jsonb_set(
    (select meal_categories_config from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500'),
    '{items}',
    (select jsonb_agg(value order by ordinality)
     from jsonb_array_elements((select meal_categories_config->'items' from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500')) with ordinality
     where value->>'id' <> 'meal_slot_77777777-7777-4777-8777-777777777777')
  ),
  'active custom retained ID removal must be rejected'
);
select pg_temp.assert_update_rejected(
  '00000000-0000-4000-8000-000000000500',
  jsonb_set(
    (select meal_categories_config from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500'),
    '{items}',
    (select jsonb_agg(value order by ordinality)
     from jsonb_array_elements((select meal_categories_config->'items' from public.user_nutrition_profiles where user_id = '00000000-0000-4000-8000-000000000500')) with ordinality
     where value->>'id' <> 'meal_slot_88888888-8888-4888-8888-888888888888')
  ),
  'archived custom retained ID removal must be rejected'
);

-- RLS, first-row write, authenticated guards, and profile-writer preservation.
insert into auth.users (id, email)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'user-a@example.test'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'user-b@example.test'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'user-c@example.test'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'account-delete@example.test');
insert into public.user_nutrition_profiles (user_id, preferred_diet, meal_categories_config)
values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'vegan', pg_temp.fixture('canonical')),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'other', pg_temp.fixture('custom_one'));

set local role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);

insert into public.user_nutrition_profiles (user_id, meal_categories_config)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', pg_temp.fixture('custom_one'));
select pg_temp.assert_true(
  (select preferred_diet is null and allergies = '{}'::text[]
          and disliked_foods = '{}'::text[] and medical_conditions = '{}'::text[]
          and other_diet_type is null and other_allergy_restriction is null
          and updated_at is not null and meal_categories_config = pg_temp.fixture('custom_one')
   from public.user_nutrition_profiles where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  'first category write must not fabricate Nutrition Profile values'
);
select pg_temp.assert_true(
  (select count(*) = 1 from public.user_nutrition_profiles),
  'authenticated user A must read only its own row'
);

do $$
declare
  v_row_count integer;
  v_reinsert_blocked boolean := false;
begin
  delete from public.user_nutrition_profiles
  where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  get diagnostics v_row_count = row_count;
  perform pg_temp.assert_true(
    v_row_count = 0,
    'authenticated owner must not hard-delete its Nutrition Profile'
  );

  delete from public.user_nutrition_profiles
  where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  get diagnostics v_row_count = row_count;
  perform pg_temp.assert_true(
    v_row_count = 0,
    'authenticated user A must not delete user B Nutrition Profile'
  );

  begin
    insert into public.user_nutrition_profiles (user_id, meal_categories_config)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', pg_temp.fixture('canonical'));
  exception when unique_violation then
    v_reinsert_blocked := true;
  end;
  perform pg_temp.assert_true(
    v_reinsert_blocked
      and (
        select meal_categories_config = pg_temp.fixture('custom_one')
        from public.user_nutrition_profiles
        where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      ),
    'DELETE then reinsert must not erase retained category identities'
  );
end;
$$;

do $$
declare v_row_count integer; v_denied boolean := false;
begin
  update public.user_nutrition_profiles set preferred_diet = 'other'
  where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  get diagnostics v_row_count = row_count;
  perform pg_temp.assert_true(v_row_count = 0, 'user A must not update user B');
  begin
    insert into public.user_nutrition_profiles (user_id, meal_categories_config)
    values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', pg_temp.fixture('canonical'));
  exception when insufficient_privilege then
    v_denied := true;
  end;
  perform pg_temp.assert_true(v_denied, 'user A must not insert user C profile');
end;
$$;

do $$
declare v_rejected boolean := false;
begin
  begin
    update public.user_nutrition_profiles
    set meal_categories_config = jsonb_set(meal_categories_config, '{items,4,id}', '"meal_slot_not-a-uuid"')
    where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  exception when check_violation then
    v_rejected := true;
  end;
  perform pg_temp.assert_true(v_rejected, 'CHECK must execute for authenticated writes');
end;
$$;
do $$
declare v_rejected boolean := false;
begin
  begin
    update public.user_nutrition_profiles set meal_categories_config = pg_temp.fixture('canonical')
    where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  exception when check_violation then
    v_rejected := true;
  end;
  perform pg_temp.assert_true(v_rejected, 'retained-ID trigger must execute for authenticated writes');
end;
$$;

insert into public.user_nutrition_profiles (
  user_id, preferred_diet, allergies, disliked_foods, medical_conditions,
  other_diet_type, other_allergy_restriction
)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'other', array['other'], array['celery'],
  array['diabetes'], 'pescatarian', 'shellfish'
)
on conflict (user_id) do update set
  preferred_diet = excluded.preferred_diet,
  allergies = excluded.allergies,
  disliked_foods = excluded.disliked_foods,
  medical_conditions = excluded.medical_conditions,
  other_diet_type = excluded.other_diet_type,
  other_allergy_restriction = excluded.other_allergy_restriction;
select pg_temp.assert_true(
  (select meal_categories_config = pg_temp.fixture('custom_one') and preferred_diet = 'other'
   from public.user_nutrition_profiles where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  'profile-only ON CONFLICT writer must preserve meal_categories_config'
);

reset role;

-- SECURITY INVOKER CHECK/trigger evaluation requires this narrow validator
-- EXECUTE grant for normal authenticated writes; prove the dependency rather
-- than widening the function or schema boundary.
revoke execute on function private.is_valid_meal_categories_config_v1(jsonb)
  from authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);
do $$
declare v_denied boolean := false;
begin
  begin
    update public.user_nutrition_profiles
    set meal_categories_config = meal_categories_config
    where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  exception when insufficient_privilege then
    v_denied := true;
  end;
  perform pg_temp.assert_true(
    v_denied,
    'authenticated guarded writes must require validator EXECUTE'
  );
end;
$$;
reset role;
grant execute on function private.is_valid_meal_categories_config_v1(jsonb)
  to authenticated;

-- The canonical SECURITY DEFINER account-deletion RPC removes auth.users;
-- the existing FK cascade must still remove the Nutrition Profile without a
-- standalone client DELETE policy.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', true);
select set_config('request.jwt.claims', '{"sub":"dddddddd-dddd-4ddd-8ddd-dddddddddddd","role":"authenticated"}', true);
select public.delete_user_account();
reset role;
select pg_temp.assert_true(
  not exists (
    select 1 from auth.users
    where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
  ) and not exists (
    select 1 from public.user_nutrition_profiles
    where user_id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
  ),
  'canonical account deletion must cascade to the Nutrition Profile'
);

set local role anon;
select pg_temp.assert_true(
  (select count(*) = 0 from public.user_nutrition_profiles),
  'anon must read no Nutrition Profile rows'
);
do $$
declare v_denied boolean := false; v_row_count integer;
begin
  begin
    insert into public.user_nutrition_profiles (user_id, meal_categories_config)
    values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', pg_temp.fixture('canonical'));
  exception when insufficient_privilege then
    v_denied := true;
  end;
  perform pg_temp.assert_true(v_denied, 'anon insert must be denied');
  update public.user_nutrition_profiles set preferred_diet = 'other'
  where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  get diagnostics v_row_count = row_count;
  perform pg_temp.assert_true(v_row_count = 0, 'anon update must affect no rows');
  delete from public.user_nutrition_profiles
  where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  get diagnostics v_row_count = row_count;
  perform pg_temp.assert_true(v_row_count = 0, 'anon delete must affect no rows');
end;
$$;

reset role;
rollback;

\echo 'TNYX-67 Slice B1 SQL matrix passed.'
