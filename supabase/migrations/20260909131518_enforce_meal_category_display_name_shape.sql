-- TNYX-186 Slice B: hold the database to the merged Meal Category
-- display-name contract, as far as PostgreSQL can actually prove it.
--
-- Slice A (PR #234) made the Dart domain the single owner of what a category
-- name may be. The database still only type-checks `display_name` as a string,
-- so a client talking straight to the API can store a name the app will then
-- refuse to read back -- and the retained-ID trigger means that row cannot
-- simply be dropped. This closes the part of that gap the database can close
-- exactly.
--
-- WHAT THIS DOES NOT ENFORCE
--
-- The owner contract is at most 24 *extended grapheme clusters*. This
-- migration does not enforce that, and deliberately does not pretend to.
--
-- PostgreSQL 17 has no extended-grapheme-cluster primitive. `char_length`
-- counts code points, and the two are not close: one family emoji is a single
-- grapheme to the reader and seven code points here, so a name of 24 such
-- emoji -- valid under the contract -- is 168 code points. A guard written as
-- `char_length(display_name) <= 24` would therefore reject names the app
-- accepts, which is worse than no guard at all. Measured on this project, not
-- assumed. The only procedural languages installed are `plpgsql` and `sql`,
-- and no installed extension exposes grapheme segmentation.
--
-- So the exact 24-grapheme limit stays owned by
-- `MealCategoryDisplayNamePolicy` in the Nutrition domain. A direct API write
-- can still store an over-long name; that hole is named here rather than
-- papered over, and closing it needs a mechanism this database does not have.
--
-- WHAT THIS DOES ENFORCE
--
-- The non-length half of the contract, which PostgreSQL can decide exactly:
--
--   * no C0 controls, DEL or C1 controls;
--   * no U+2028 or U+2029;
--   * no U+200B ZERO WIDTH SPACE;
--   * not blank;
--   * no leading or trailing collapsible whitespace;
--   * no run of two or more collapsible whitespace characters;
--   * every space in the stored value is an ordinary U+0020;
--   * U+200C ZWNJ, U+200D ZWJ and U+2060 WORD JOINER remain allowed.
--
-- Each rule was checked against the merged Dart policy on this database before
-- this file was written: twenty-one probe values covering every rule and every
-- allowed format character, all agreeing.
--
-- Two places where PostgreSQL and Dart genuinely disagree, which is why the
-- character sets below are written out rather than expressed as `\s`:
--
--   * U+0085 NEL matches PostgreSQL's `\s` and not Dart's;
--   * U+FEFF matches Dart's `\s` and not PostgreSQL's;
--   * and `btrim` with no second argument removes only ASCII space.
--
-- A VALIDATOR, NOT A REPAIR LAYER
--
-- A write whose `display_name` is not already canonical is refused. Nothing
-- here trims it for the writer, collapses it and saves a changed value, or
-- truncates anything. The stored JSON is never mutated by validation.

do $$
begin
  if pg_catalog.to_regclass('public.user_nutrition_profiles') is null then
    raise exception 'TNYX-186 display-name guard blocked: public.user_nutrition_profiles is missing';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc as p
    join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'is_valid_meal_categories_config_v1'
  ) then
    raise exception 'TNYX-186 display-name guard blocked: the validator is missing';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_constraint as c
    where c.conrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
      and c.conname = 'user_nutrition_profiles_meal_categories_config_valid'
  ) then
    raise exception 'TNYX-186 display-name guard blocked: the CHECK constraint is missing';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger as t
    where t.tgrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
      and t.tgname = 'trg_user_nutrition_profiles_protect_meal_category_retained_ids'
  ) then
    raise exception 'TNYX-186 display-name guard blocked: the retained-ID trigger is missing';
  end if;
end
$$;

-- Preflight. Replacing the validator does not revalidate stored rows, so a row
-- that already breaks one of the new rules would stay readable and then fail
-- every future write -- and the retained-ID trigger would stop it being
-- brought back into shape by deletion. That is a silently bricked account, the
-- same failure the TNYX-67 tightening guarded against.
--
-- So this refuses to apply at all if any stored name would be left in that
-- state. Nothing here repairs, canonicalizes, truncates or grandfathers
-- anything: the migration fails, says what it found, and the environment is
-- dealt with deliberately. Counts only -- no name is echoed into the log.
do $$
declare
  v_forbidden integer;
  v_blank integer;
  v_noncanonical integer;
begin
  with stored as (
    select item ->> 'display_name' as nm
    from public.user_nutrition_profiles as p,
      pg_catalog.jsonb_array_elements(p.meal_categories_config -> 'items') as item
    where p.meal_categories_config is not null
  ), classified as (
    select
      nm,
      (nm ~ '[\u0001-\u001F\u007F-\u009F\u2028\u2029\u200B]') as has_forbidden,
      pg_catalog.btrim(
        pg_catalog.regexp_replace(nm, '[\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000\uFEFF]+', ' ', 'g'),
        ' '
      ) as canonical
    from stored
  )
  select
    pg_catalog.count(*) filter (where has_forbidden),
    pg_catalog.count(*) filter (where not has_forbidden and canonical = ''),
    pg_catalog.count(*) filter (
      where not has_forbidden and canonical <> '' and nm <> canonical
    )
  into v_forbidden, v_blank, v_noncanonical
  from classified;

  if v_forbidden > 0 or v_blank > 0 or v_noncanonical > 0 then
    raise exception
      'TNYX-186 display-name guard blocked: stored meal_categories_config names '
      'would be stranded by the tightened validator (forbidden characters: %, '
      'blank or invisible: %, not in canonical whitespace form: %). Resolve '
      'these rows first; this migration will not rewrite or truncate a name a '
      'reader chose.',
      v_forbidden, v_blank, v_noncanonical;
  end if;
end
$$;

-- Replaced rather than wrapped, and rather than joined by a second validator:
-- the CHECK constraint already points at this function by name, so the new
-- rules take effect for every future write without touching the constraint,
-- the trigger or the grants. Every TNYX-67 rule below is carried through
-- unchanged -- canonical identities and default keys, 1 to 8 active, 32
-- retained, unique ids and orders, and breakfast < lunch < dinner < snacks.
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
  v_display_name text;
  v_canonical_name text;
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

    -- TNYX-186: the display-name contract, as far as this database can prove
    -- it. Length is deliberately absent; see the header.
    v_display_name := v_item ->> 'display_name';

    -- Forbidden code points first, against the raw value. Collapsing or
    -- trimming first would delete a leading or trailing newline, tab or
    -- control on its way past and accept the result, which is the one thing
    -- the contract says must not happen: such input is refused, not
    -- converted. U+200B is named here for the same reason the Dart policy
    -- names it -- it is whitespace to neither language, so a name of nothing
    -- but zero-width spaces would otherwise pass the blank check and store a
    -- category with an invisible label.
    --
    -- U+200C ZWNJ, U+200D ZWJ and U+2060 WORD JOINER are deliberately absent.
    -- ZWNJ is required for correct Hindi and Persian text, ZWJ holds
    -- multi-part emoji together, and U+2060 sits outside the locked boundary.
    -- A list of ranges and named code points, never a rule against format
    -- characters as a class.
    if v_display_name ~ '[\u0001-\u001F\u007F-\u009F\u2028\u2029\u200B]' then
      return false;
    end if;

    -- Then the canonical shape. The collapsed set is exactly the set Dart
    -- collapses once its forbidden members are gone, named explicitly rather
    -- than written as \s: PostgreSQL's \s and Dart's disagree on U+0085 and
    -- on U+FEFF, and btrim's default removes only ASCII space.
    v_canonical_name := pg_catalog.btrim(
      pg_catalog.regexp_replace(
        v_display_name,
        '[\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000\uFEFF]+',
        ' ',
        'g'
      ),
      ' '
    );

    -- A validator, not a repair layer. The write is refused when the stored
    -- value is not already canonical; nothing here trims, collapses, truncates
    -- or rewrites what the caller sent.
    if v_canonical_name = '' or v_display_name <> v_canonical_name then
      return false;
    end if;

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
  'Versioned Meal Categories config. NULL resolves canonical runtime defaults. Retained IDs are historical identities and ordinary writes cannot remove them. Active categories: at least 1, at most 8. Maximum retained categories, archived included: 32. Canonical order by id: meal_slot_1 < meal_slot_2 < meal_slot_3 < meal_slot_4. display_name must be non-blank, free of C0/C1 controls, DEL, U+2028, U+2029 and U+200B, and already in canonical whitespace form (no outer whitespace, no repeated whitespace, ordinary U+0020 only); U+200C, U+200D and U+2060 are allowed. The 24 extended-grapheme-cluster limit is NOT enforced here (PostgreSQL has no grapheme primitive and char_length would reject valid names) and remains owned by MealCategoryDisplayNamePolicy in the Nutrition domain.';
