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
-- WHAT THIS ENFORCES
--
--   * no C0 controls, DEL or C1 controls;
--   * no U+2028 or U+2029;
--   * no U+200B ZERO WIDTH SPACE;
--   * not blank;
--   * no leading or trailing collapsible whitespace;
--   * no run of two or more collapsible whitespace characters;
--   * every space in the stored value is an ordinary U+0020;
--   * U+200C ZWNJ, U+200D ZWJ and U+2060 WORD JOINER remain allowed;
--   * no two ACTIVE categories carry the same stored name, compared exactly,
--     while an archived category may still share an ordinary name with an
--     active one;
--   * Breakfast, Lunch, Dinner and Snacks remain permanently owned by
--     meal_slot_1 through meal_slot_4 respectively, regardless of whether the
--     owner is currently using its token and regardless of active/archive
--     state.
--
-- Each of those was checked against the merged Dart policy on this database
-- before this file was written: twenty-one probe values covering every shape
-- rule and every allowed format character, all agreeing.
--
-- This is a subset of the merged contract. It is not "the non-length half",
-- and claiming so would be wrong. Two gaps stay with the application, and both
-- are named here rather than implied.
--
-- GAP 1: THE 24-GRAPHEME LIMIT
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
-- GAP 2: CASE-ONLY DUPLICATE ACTIVE NAMES
--
-- The Dart policy refuses two active categories whose `comparisonKey()`
-- matches, and that key is lowercased. This migration refuses only names that
-- are identical as stored, so `Lunch` beside `lunch` still passes here.
--
-- `lower()` was audited rather than assumed, on this database's ICU
-- en_US.UTF-8 collation, against the merged Dart key over sixteen vectors.
-- Fourteen agreed. Two did not, and they fail in opposite directions:
--
--   * U+0130 LATIN CAPITAL LETTER I WITH DOT ABOVE lowercases to `i` plus
--     U+0307 here and to a plain `i` in Dart, so `lower()` would miss a
--     collision the app catches;
--   * a Greek word ending in a final sigma and the same word spelled with a
--     medial sigma fold to one key here and to two in Dart, so `lower()`
--     would refuse a configuration the app accepts.
--
-- The second is disqualifying on its own: a guard that refuses valid writes is
-- not a guard. Exact equality cannot do that. The shape rules above already
-- force the stored value to be canonical, so two identical active names always
-- produce identical Dart keys, which means everything refused here is refused
-- by the app as well.
--
-- Case-only variants therefore stay application-authoritative, exactly like
-- the length limit. A test pins this boundary so it cannot later be mistaken
-- for full parity.
--
-- RESERVED ASCII TOKENS
--
-- The four reserved words are ASCII. Their ownership check therefore uses an
-- explicit ASCII-only fold with `translate()`, not PostgreSQL `lower()`,
-- locale-dependent comparison, citext, ICU equality or a generic Unicode
-- normalization rule. This exact rule is separate from the ordinary Unicode
-- case-only duplicate gap above.
--
-- WHY THE CHARACTER SETS ARE WRITTEN OUT
--
-- PostgreSQL and Dart do not agree on what whitespace is, so `\s` is not
-- used anywhere below:
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
--
-- The migration runner executes this file in one transaction. A
-- SHARE ROW EXCLUSIVE lock is acquired before the stored-row scan and held
-- through validator replacement, so an old-validator-valid write cannot race
-- into the table after preflight and become stranded at commit.

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

-- Block INSERT/UPDATE/DELETE for the preflight-to-replacement interval while
-- keeping ordinary reads available. CI and the approved Supabase migration
-- runner execute each migration as one transaction, so this lock is released
-- only after the tightened validator is in place (or the migration rolls back).
lock table public.user_nutrition_profiles in share row exclusive mode;

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
  v_duplicate_active integer;
  v_reserved_custom integer;
  v_reserved_wrong_canonical integer;
  v_reserved_archived integer;
  v_reserved_total integer;
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

  -- The active-name rule is a tightening too, so it gets the same treatment:
  -- a stored row already holding two identically named active categories
  -- would be readable and then unwritable forever.
  select pg_catalog.count(*)
  into v_duplicate_active
  from public.user_nutrition_profiles as p
  where p.meal_categories_config is not null
    and exists (
      select 1
      from pg_catalog.jsonb_array_elements(
        p.meal_categories_config -> 'items'
      ) as item
      where (item ->> 'active')::boolean
      group by item ->> 'display_name'
      having pg_catalog.count(*) > 1
    );

  -- Reserved-name ownership is permanent and applies to active and archived
  -- items alike. The words are ASCII, so fold only ASCII A-Z explicitly.
  with classified as (
    select
      item ->> 'id' as item_id,
      (item ->> 'active')::boolean as is_active,
      case pg_catalog.translate(
        item ->> 'display_name',
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'abcdefghijklmnopqrstuvwxyz'
      )
        when 'breakfast' then 'meal_slot_1'
        when 'lunch' then 'meal_slot_2'
        when 'dinner' then 'meal_slot_3'
        when 'snacks' then 'meal_slot_4'
        else null
      end as reserved_owner_id
    from public.user_nutrition_profiles as p,
      pg_catalog.jsonb_array_elements(
        p.meal_categories_config -> 'items'
      ) as item
    where p.meal_categories_config is not null
  )
  select
    pg_catalog.count(*) filter (
      where reserved_owner_id is not null
        and item_id not in (
          'meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4'
        )
    ),
    pg_catalog.count(*) filter (
      where reserved_owner_id is not null
        and item_id in (
          'meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4'
        )
        and item_id <> reserved_owner_id
    ),
    pg_catalog.count(*) filter (
      where reserved_owner_id is not null
        and item_id <> reserved_owner_id
        and not is_active
    ),
    pg_catalog.count(*) filter (
      where reserved_owner_id is not null
        and item_id <> reserved_owner_id
    )
  into
    v_reserved_custom,
    v_reserved_wrong_canonical,
    v_reserved_archived,
    v_reserved_total
  from classified;

  if v_forbidden > 0 or v_blank > 0 or v_noncanonical > 0
    or v_duplicate_active > 0 or v_reserved_total > 0 then
    raise exception
      'TNYX-186 display-name guard blocked: stored meal_categories_config names '
      'would be stranded by the tightened validator (forbidden characters: %, '
      'blank or invisible: %, not in canonical whitespace form: %, rows with '
      'two identically named active categories: %, custom reserved-name uses: %, '
      'wrong canonical reserved-name owners: %, archived reserved-name '
      'violations: %, total reserved-name ownership violations: %). Resolve '
      'these rows first; '
      'this migration will not rewrite, rename or truncate a name a reader '
      'chose.',
      v_forbidden, v_blank, v_noncanonical, v_duplicate_active,
      v_reserved_custom, v_reserved_wrong_canonical, v_reserved_archived,
      v_reserved_total;
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
  v_reserved_owner_id text;
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

    -- The four original ASCII names are permanently identity-owned. The
    -- owner's current label is irrelevant: renaming Lunch to Mid Meal does not
    -- release Lunch, and Mid Meal does not become a new reserved token. This
    -- check is deliberately before active-only duplicate validation and
    -- applies to archived items too.
    v_reserved_owner_id := case pg_catalog.translate(
      v_display_name,
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      'abcdefghijklmnopqrstuvwxyz'
    )
      when 'breakfast' then 'meal_slot_1'
      when 'lunch' then 'meal_slot_2'
      when 'dinner' then 'meal_slot_3'
      when 'snacks' then 'meal_slot_4'
      else null
    end;

    if v_reserved_owner_id is not null
      and v_reserved_owner_id <> v_id
    then
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

  -- Two active categories may not carry the same name, compared as stored.
  --
  -- Exact equality, not `lower()`. The Dart policy compares
  -- `comparisonKey()`, which lowercases, and PostgreSQL's `lower()` is not
  -- the same function on this database. Measured here, ICU en_US.UTF-8:
  --
  --   * `lower()` maps U+0130 to `i` plus a combining dot, where Dart maps it
  --     to a plain `i`, so the two disagree on whether a pair collides;
  --   * `lower()` folds a Greek word spelled with a final sigma and the same
  --     word spelled with a medial sigma to one key, where Dart keeps them
  --     apart -- so a validator using `lower()` would refuse a configuration
  --     the app accepts, and brick a legitimate write.
  --
  -- Comparing the stored values byte for byte cannot do that. Display names
  -- are already required to be canonical by the rules above, so two identical
  -- active names always produce identical Dart comparison keys, which means
  -- everything refused here is refused by the app as well. The reverse does
  -- not hold: case-only variants such as `Lunch` and `lunch` still pass this
  -- validator and are caught only by the domain. That gap is named in the
  -- header, in the column comment and in the test matrix.
  --
  -- Scoped to active items, matching the Dart rule: an archived category may
  -- share a name with an active one, which is what lets a name be reused
  -- after archiving.
  if exists (
    select 1
    from pg_catalog.jsonb_array_elements(p_config -> 'items') as item
    where (item ->> 'active')::boolean
    group by item ->> 'display_name'
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
  'Versioned Meal Categories config. NULL resolves canonical runtime defaults. Retained IDs are historical identities and ordinary writes cannot remove them. Active categories: at least 1, at most 8. Maximum retained categories, archived included: 32. Canonical order by id: meal_slot_1 < meal_slot_2 < meal_slot_3 < meal_slot_4. display_name must be non-blank, free of C0/C1 controls, DEL, U+2028, U+2029 and U+200B, and already in canonical whitespace form (no outer whitespace, no repeated whitespace, ordinary U+0020 only); U+200C, U+200D and U+2060 are allowed. Breakfast, Lunch, Dinner and Snacks are permanently owned by meal_slot_1, meal_slot_2, meal_slot_3 and meal_slot_4 respectively, matched with explicit ASCII-only case folding and enforced for active and archived items. Two active categories may not carry the same stored name, compared exactly; archived ordinary duplicates are allowed. Two rules are NOT enforced here and remain owned by MealCategoryDisplayNamePolicy in the Nutrition domain: the 24 extended-grapheme-cluster limit, because PostgreSQL has no grapheme primitive and char_length would reject valid names; and ordinary Unicode case-only duplicate active names, because this database''s lower() disagrees with Dart on U+0130 and on Greek final sigma, in the latter case refusing configurations the app accepts.';
