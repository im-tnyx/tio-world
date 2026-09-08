-- TNYX-67: bring the database validator level with the Dart domain.
--
-- Three rules the B1 validator did not carry, all of which the client already
-- enforces. Where the two disagree, the database is the one that matters: it
-- is the only guard in front of a client that never runs the app.
--
-- 1. At most 32 retained categories, archived included.
--
--    B1 capped active categories at 8 and deliberately left retained ones
--    uncapped. Archiving never deletes, and the retained-ID trigger stops
--    anything shrinking the set, so it only ever grew. An authenticated
--    client writing straight to the API could grow one row without limit,
--    and the whole configuration is scanned and revalidated on every write,
--    so each later write paid for every item ever added.
--
--    Nothing here removes identities. Reaching the ceiling means adding
--    stops, and the reader restores an archived category and renames it.
--
-- 2. At least one active category.
--
--    Every meal has to be filed under something. The database accepted all
--    four canonical items as `active: false`, which the Dart decoder then
--    refuses to read — leaving the screen in a permanent load failure that
--    the account could not get out of.
--
-- 3. breakfast < lunch < dinner < snacks.
--
--    Enforced on the canonical ids and their `order` values, never on
--    `display_name`: a reader may rename Lunch to anything, and it keeps its
--    anchor. Custom categories stay free to sit before, between or after the
--    anchors. Same failure as above — the database accepted an inversion the
--    client cannot read back.

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

-- Preflight. Replacing the validator does not revalidate stored rows, so a row
-- that already breaks one of the new rules would keep being readable and then
-- fail every future write — and the retained-ID trigger would stop it being
-- brought back under the ceiling. That is a silently bricked account.
--
-- So the tightening refuses to apply at all if any stored row would be left in
-- that state. Nothing here repairs, truncates or grandfathers anything: the
-- migration fails, names what it found, and the environment is dealt with
-- deliberately.
--
-- All three new rules are checked, not just the ceiling, because all three are
-- tightenings and each can strand a row the same way.
do $$
declare
  v_over_ceiling integer;
  v_no_active integer;
  v_order_inverted integer;
begin
  with stored as (
    select
      p.user_id,
      pg_catalog.jsonb_array_length(p.meal_categories_config -> 'items')
        as retained_count,
      (
        select pg_catalog.count(*)
        from pg_catalog.jsonb_array_elements(
          p.meal_categories_config -> 'items'
        ) as item
        where (item ->> 'active')::boolean
      ) as active_count,
      (
        select (item ->> 'order')::integer
        from pg_catalog.jsonb_array_elements(
          p.meal_categories_config -> 'items'
        ) as item
        where item ->> 'id' = 'meal_slot_1'
      ) as breakfast_order,
      (
        select (item ->> 'order')::integer
        from pg_catalog.jsonb_array_elements(
          p.meal_categories_config -> 'items'
        ) as item
        where item ->> 'id' = 'meal_slot_2'
      ) as lunch_order,
      (
        select (item ->> 'order')::integer
        from pg_catalog.jsonb_array_elements(
          p.meal_categories_config -> 'items'
        ) as item
        where item ->> 'id' = 'meal_slot_3'
      ) as dinner_order,
      (
        select (item ->> 'order')::integer
        from pg_catalog.jsonb_array_elements(
          p.meal_categories_config -> 'items'
        ) as item
        where item ->> 'id' = 'meal_slot_4'
      ) as snacks_order
    from public.user_nutrition_profiles as p
    where p.meal_categories_config is not null
  )
  select
    pg_catalog.count(*) filter (where retained_count > 32),
    pg_catalog.count(*) filter (where active_count < 1),
    pg_catalog.count(*) filter (
      where not (
        breakfast_order < lunch_order
        and lunch_order < dinner_order
        and dinner_order < snacks_order
      )
    )
  into v_over_ceiling, v_no_active, v_order_inverted
  from stored;

  if v_over_ceiling > 0 or v_no_active > 0 or v_order_inverted > 0 then
    raise exception
      'TNYX-67 retained cap blocked: stored meal_categories_config rows would '
      'be stranded by the tightened validator (over 32 retained: %, no active '
      'category: %, canonical order inverted: %). Resolve these rows first; '
      'this migration will not truncate identities or grandfather malformed '
      'state.',
      v_over_ceiling, v_no_active, v_order_inverted;
  end if;
end
$$;

-- Replaced rather than wrapped: the CHECK constraint already points at this
-- function by name, so the new rules take effect for every future write
-- without touching the constraint. Postgres does not revalidate stored rows
-- when the function behind a constraint changes, which is why the preflight
-- above exists — by the time execution reaches here, no stored row breaks any
-- of the three new rules.
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
  -- Captured per canonical id, so the relative order is checked against
  -- durable identity and never against display_name.
  v_order_meal_slot_1 integer;
  v_order_meal_slot_2 integer;
  v_order_meal_slot_3 integer;
  v_order_meal_slot_4 integer;
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
        v_order_meal_slot_1 := (v_item ->> 'order')::integer;
      when 'meal_slot_2' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'lunch'
        then
          return false;
        end if;
        v_seen_meal_slot_2 := true;
        v_order_meal_slot_2 := (v_item ->> 'order')::integer;
      when 'meal_slot_3' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'dinner'
        then
          return false;
        end if;
        v_seen_meal_slot_3 := true;
        v_order_meal_slot_3 := (v_item ->> 'order')::integer;
      when 'meal_slot_4' then
        if v_default_key_type is distinct from 'string'
          or v_item ->> 'default_key' is distinct from 'snacks'
        then
          return false;
        end if;
        v_seen_meal_slot_4 := true;
        v_order_meal_slot_4 := (v_item ->> 'order')::integer;
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

  if not (
    v_seen_meal_slot_1
    and v_seen_meal_slot_2
    and v_seen_meal_slot_3
    and v_seen_meal_slot_4
  ) then
    return false;
  end if;

  -- Every meal has to be filed under something, so a configuration with
  -- nothing active is not a state the account can be in.
  if v_active_count < 1 then
    return false;
  end if;

  -- Anchored to the canonical ids captured above, never to display_name: a
  -- reader may rename Lunch and it keeps its anchor. Custom categories are
  -- unconstrained and may sit before, between or after the anchors.
  if not (
    v_order_meal_slot_1 < v_order_meal_slot_2
    and v_order_meal_slot_2 < v_order_meal_slot_3
    and v_order_meal_slot_3 < v_order_meal_slot_4
  ) then
    return false;
  end if;

  return true;
end;
$$;

revoke all on function private.is_valid_meal_categories_config_v1(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function private.is_valid_meal_categories_config_v1(jsonb)
  to authenticated, service_role;

comment on column public.user_nutrition_profiles.meal_categories_config is
  'Versioned Meal Categories config. NULL resolves canonical runtime defaults. Retained IDs are historical identities and ordinary writes cannot remove them. Active categories: at least 1, at most 8. Maximum retained categories, archived included: 32. Canonical order by id: meal_slot_1 < meal_slot_2 < meal_slot_3 < meal_slot_4.';
