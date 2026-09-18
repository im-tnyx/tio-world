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
   where version = '20260918182500'),
  'migration ledger must contain TNYX-233 exactly once'
);

select pg_temp.assert_true(
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_profiles'
      and column_name = 'country_code'
      and data_type = 'text'
      and is_nullable = 'YES'
  ),
  'country_code must be nullable text on public.user_profiles'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.user_profiles'::pg_catalog.regclass
      and conname = 'user_profiles_country_code_check'
      and contype = 'c'
  ),
  'country_code shape check must exist'
);

insert into auth.users (id, email)
values
  ('11111111-1111-4111-8111-111111111111', 'tnyx-233-a@example.test'),
  ('22222222-2222-4222-8222-222222222222', 'tnyx-233-b@example.test');

insert into public.user_profiles (user_id, name, country_code)
values
  ('11111111-1111-4111-8111-111111111111', 'Country A', null),
  ('22222222-2222-4222-8222-222222222222', 'Country B', 'US');

select pg_temp.assert_true(
  (select country_code is null
   from public.user_profiles
   where user_id = '11111111-1111-4111-8111-111111111111'),
  'NULL must remain the explicit unknown/unset country state'
);

update public.user_profiles
set country_code = 'IN'
where user_id = '11111111-1111-4111-8111-111111111111';

select pg_temp.assert_true(
  (select country_code = 'IN'
   from public.user_profiles
   where user_id = '11111111-1111-4111-8111-111111111111'),
  'uppercase alpha-2 country code must be accepted'
);

select pg_temp.assert_raises(
  $$update public.user_profiles
    set country_code = 'in'
    where user_id = '11111111-1111-4111-8111-111111111111'$$,
  '23514',
  'lowercase country code must be rejected rather than normalized silently'
);

select pg_temp.assert_raises(
  $$update public.user_profiles
    set country_code = 'USA'
    where user_id = '11111111-1111-4111-8111-111111111111'$$,
  '23514',
  'three-letter country code must be rejected'
);

select pg_temp.assert_raises(
  $$update public.user_profiles
    set country_code = '1N'
    where user_id = '11111111-1111-4111-8111-111111111111'$$,
  '23514',
  'non-alpha country code must be rejected'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);

select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_profiles),
  'authenticated user must only read their own profile row through existing RLS'
);

update public.user_profiles
set country_code = 'GB'
where user_id = '22222222-2222-4222-8222-222222222222';

reset role;

select pg_temp.assert_true(
  (select country_code = 'US'
   from public.user_profiles
   where user_id = '22222222-2222-4222-8222-222222222222'),
  'authenticated user must not update another user country through existing RLS'
);

rollback;
