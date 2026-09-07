-- TNYX-67 Slice B1: persist the complete versioned Meal Categories config on
-- the existing Nutrition Profile owner row. NULL intentionally means that the
-- client resolves the four canonical runtime defaults without a backfill.

do $$
declare
  v_column_type text;
  v_column_not_null boolean;
  v_column_default text;
begin
  if pg_catalog.to_regclass('public.user_nutrition_profiles') is null then
    raise exception 'TNYX-67 B1 blocked: public.user_nutrition_profiles is missing';
  end if;

  select
    pg_catalog.format_type(a.atttypid, a.atttypmod),
    a.attnotnull,
    pg_catalog.pg_get_expr(d.adbin, d.adrelid)
  into v_column_type, v_column_not_null, v_column_default
  from pg_catalog.pg_attribute as a
  left join pg_catalog.pg_attrdef as d
    on d.adrelid = a.attrelid
   and d.adnum = a.attnum
  where a.attrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
    and a.attname = 'meal_categories_config'
    and a.attnum > 0
    and not a.attisdropped;

  if v_column_type is not null
    and (
      v_column_type <> 'jsonb'
      or v_column_not_null
      or v_column_default is not null
    )
  then
    raise exception
      'TNYX-67 B1 blocked: meal_categories_config exists with an incompatible contract';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname in (
        'is_valid_meal_categories_config_v1',
        'protect_meal_category_retained_ids'
      )
  ) then
    raise exception 'TNYX-67 B1 blocked: a reserved private function name already exists';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_constraint as c
    where c.conrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
      and c.conname = 'user_nutrition_profiles_meal_categories_config_valid'
  ) then
    raise exception 'TNYX-67 B1 blocked: the reserved CHECK constraint already exists';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_trigger as t
    where t.tgrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
      and t.tgname = 'trg_user_nutrition_profiles_protect_meal_category_retained_ids'
      and not t.tgisinternal
  ) then
    raise exception 'TNYX-67 B1 blocked: the reserved retained-ID trigger already exists';
  end if;
end
$$;

alter table public.user_nutrition_profiles
  add column if not exists meal_categories_config jsonb;

comment on column public.user_nutrition_profiles.meal_categories_config is
  'Versioned Meal Categories config. NULL resolves canonical runtime defaults. Retained IDs are historical identities and ordinary writes cannot remove them. Maximum active categories: 8.';

-- Ordinary clients must not erase retained category identities by deleting and
-- recreating the whole Nutrition Profile row. Full account deletion continues
-- through public.delete_user_account(), whose auth.users deletion reaches this
-- table through its existing ON DELETE CASCADE foreign key.
drop policy if exists "user_nutrition_profiles_delete_own"
  on public.user_nutrition_profiles;

create function private.is_valid_meal_categories_config_v1(p_config jsonb)
returns boolean
language plpgsql
immutable
strict
security invoker
set search_path = ''
as $$
declare
  v_item jsonb;
  v_id text;
  v_default_key_type text;
  v_active_count integer := 0;
  v_seen_meal_slot_1 boolean := false;
  v_seen_meal_slot_2 boolean := false;
  v_seen_meal_slot_3 boolean := false;
  v_seen_meal_slot_4 boolean := false;
begin
  if pg_catalog.jsonb_typeof(p_config) <> 'object'
    or not (p_config ?& array['schema_version', 'items']::text[])
    or p_config - array['schema_version', 'items']::text[] <> '{}'::jsonb
    or pg_catalog.jsonb_typeof(p_config -> 'schema_version') <> 'number'
    or p_config ->> 'schema_version' <> '1'
    or pg_catalog.jsonb_typeof(p_config -> 'items') <> 'array'
  then
    return false;
  end if;

  for v_item in
    select value
    from pg_catalog.jsonb_array_elements(p_config -> 'items')
  loop
    if pg_catalog.jsonb_typeof(v_item) <> 'object'
      or not (v_item ?& array['id', 'display_name', 'active', 'order']::text[])
      or v_item - array['id', 'display_name', 'active', 'order', 'default_key']::text[] <> '{}'::jsonb
      or pg_catalog.jsonb_typeof(v_item -> 'id') <> 'string'
      or pg_catalog.jsonb_typeof(v_item -> 'display_name') <> 'string'
      or pg_catalog.jsonb_typeof(v_item -> 'active') <> 'boolean'
      or pg_catalog.jsonb_typeof(v_item -> 'order') <> 'number'
      or v_item ->> 'order' !~ '^(0|[1-9][0-9]*)$'
    then
      return false;
    end if;

    v_default_key_type := pg_catalog.jsonb_typeof(v_item -> 'default_key');
    if v_item ? 'default_key'
      and v_default_key_type not in ('null', 'string')
    then
      return false;
    end if;

    v_id := v_item ->> 'id';

    if (v_item ->> 'active')::boolean then
      v_active_count := v_active_count + 1;
      if v_active_count > 8 then
        return false;
      end if;
    end if;

    case v_id
      when 'meal_slot_1' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'breakfast'
        then
          return false;
        end if;
        v_seen_meal_slot_1 := true;
      when 'meal_slot_2' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'lunch'
        then
          return false;
        end if;
        v_seen_meal_slot_2 := true;
      when 'meal_slot_3' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'dinner'
        then
          return false;
        end if;
        v_seen_meal_slot_3 := true;
      when 'meal_slot_4' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'snacks'
        then
          return false;
        end if;
        v_seen_meal_slot_4 := true;
      else
        if v_id !~ '^meal_slot_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
          or (
            v_item ? 'default_key'
            and v_default_key_type <> 'null'
          )
        then
          return false;
        end if;
    end case;
  end loop;

  -- Retained archived items are intentionally not capped, so uniqueness must
  -- remain set-oriented rather than repeatedly scanning growing arrays.
  if exists (
    select 1
    from pg_catalog.jsonb_array_elements(p_config -> 'items') as item
    group by item ->> 'id'
    having pg_catalog.count(*) > 1
  ) or exists (
    select 1
    from pg_catalog.jsonb_array_elements(p_config -> 'items') as item
    group by item ->> 'order'
    having pg_catalog.count(*) > 1
  ) then
    return false;
  end if;

  return
    v_seen_meal_slot_1
    and v_seen_meal_slot_2
    and v_seen_meal_slot_3
    and v_seen_meal_slot_4;
end;
$$;

revoke all on function private.is_valid_meal_categories_config_v1(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function private.is_valid_meal_categories_config_v1(jsonb)
  to authenticated, service_role;

alter table public.user_nutrition_profiles
  add constraint user_nutrition_profiles_meal_categories_config_valid
  check (
    meal_categories_config is null
    or private.is_valid_meal_categories_config_v1(meal_categories_config)
  );

create function private.protect_meal_category_retained_ids()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.meal_categories_config is null then
    return new;
  end if;

  if new.meal_categories_config is null then
    raise exception
      'meal_categories_config cannot remove retained category identities by resetting to NULL'
      using errcode = '23514';
  end if;

  -- Let the table CHECK produce the structural-validation failure. This guard
  -- compares IDs only after NEW is known to be a valid V1 envelope.
  if not private.is_valid_meal_categories_config_v1(new.meal_categories_config) then
    return new;
  end if;

  if exists (
    select old_item ->> 'id'
    from pg_catalog.jsonb_array_elements(
      old.meal_categories_config -> 'items'
    ) as old_item
    except
    select new_item ->> 'id'
    from pg_catalog.jsonb_array_elements(
      new.meal_categories_config -> 'items'
    ) as new_item
  ) then
    raise exception
      'meal_categories_config cannot remove a retained category identity'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all on function private.protect_meal_category_retained_ids()
  from public, anon, authenticated, service_role;

create trigger trg_user_nutrition_profiles_protect_meal_category_retained_ids
before update of meal_categories_config
on public.user_nutrition_profiles
for each row
execute function private.protect_meal_category_retained_ids();
