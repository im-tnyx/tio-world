-- TNYX-67: put a ceiling on retained Meal Category identities.
--
-- The B1 validator caps active categories at 8 and deliberately left retained
-- ones uncapped. Archiving never deletes, so the retained set only ever grows,
-- and the retained-ID trigger stops anything shrinking it. An authenticated
-- client writing straight to the API could therefore grow one row without
-- limit, and the whole configuration is scanned and revalidated on every
-- write, so each later write pays for every item ever added.
--
-- 32 total: the same 8 active, plus 24 archived. The client refuses to add
-- past this and names the way out, but the client is not the guard — this is.
-- Nothing here removes identities; reaching the ceiling means adding stops,
-- and the reader restores an archived category and renames it instead.

do $$
begin
  if pg_catalog.to_regclass('public.user_nutrition_profiles') is null then
    raise exception 'TNYX-67 retained cap blocked: public.user_nutrition_profiles is missing';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'is_valid_meal_categories_config_v1'
  ) then
    raise exception 'TNYX-67 retained cap blocked: the B1 validator is missing';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_constraint as c
    where c.conrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
      and c.conname = 'user_nutrition_profiles_meal_categories_config_valid'
  ) then
    raise exception 'TNYX-67 retained cap blocked: the B1 CHECK constraint is missing';
  end if;
end
$$;

-- Replaced rather than wrapped: the CHECK constraint already points at this
-- function by name, so the new rule takes effect for every future write
-- without touching the constraint. Existing rows are not revalidated, which
-- is deliberate — a row already over the ceiling keeps being readable, and is
-- only refused when something next tries to write it.
create or replace function private.is_valid_meal_categories_config_v1(p_config jsonb)
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
  v_retained_count integer := 0;
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

  -- Checked before the per-item loop as well as inside it, so an oversized
  -- payload is refused without walking every element of it first.
  if pg_catalog.jsonb_array_length(p_config -> 'items') > 32 then
    return false;
  end if;

  for v_item in
    select value
    from pg_catalog.jsonb_array_elements(p_config -> 'items')
  loop
    v_retained_count := v_retained_count + 1;
    if v_retained_count > 32 then
      return false;
    end if;

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

  -- Retained items are now bounded, but uniqueness stays set-oriented: it is
  -- one pass either way and does not depend on the ceiling holding.
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

comment on column public.user_nutrition_profiles.meal_categories_config is
  'Versioned Meal Categories config. NULL resolves canonical runtime defaults. Retained IDs are historical identities and ordinary writes cannot remove them. Maximum active categories: 8. Maximum retained categories, archived included: 32.';
