\set ON_ERROR_STOP on

begin;

-- TNYX-186 Slice B: the display-name rules the database can decide exactly.
--
-- What is deliberately NOT tested here is the 24 extended-grapheme-cluster
-- limit. This database has no grapheme primitive, so that limit stays owned by
-- MealCategoryDisplayNamePolicy in the Nutrition domain. The last group below
-- pins the consequence: a 24-grapheme name is 168 code points, and the
-- validator must still accept it. A test suite that let a char_length guard in
-- would fail there.
--
-- Every input is built from chr() rather than pasted, so what each case
-- exercises is readable in the source instead of hiding inside a literal.

create temporary sequence tnyx_186_assertion_seq;

create function pg_temp.assert_true(p_condition boolean, p_message text)
returns void language plpgsql as $$
begin
  perform pg_catalog.nextval('pg_temp.tnyx_186_assertion_seq'::pg_catalog.regclass);
  if p_condition is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

-- One canonical configuration with a single custom category whose name is the
-- value under test. Everything else stays at the TNYX-67 canonical shape, so a
-- rejection can only come from the name.
create function pg_temp.config_with_name(p_name text)
returns jsonb language sql immutable as $$
  select pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'items', pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('id', 'meal_slot_1', 'default_key', 'breakfast',
        'display_name', 'Breakfast', 'active', true, 'order', 0),
      pg_catalog.jsonb_build_object('id', 'meal_slot_2', 'default_key', 'lunch',
        'display_name', 'Lunch', 'active', true, 'order', 1),
      pg_catalog.jsonb_build_object('id', 'meal_slot_3', 'default_key', 'dinner',
        'display_name', 'Dinner', 'active', true, 'order', 2),
      pg_catalog.jsonb_build_object('id', 'meal_slot_4', 'default_key', 'snacks',
        'display_name', 'Snacks', 'active', true, 'order', 3),
      pg_catalog.jsonb_build_object(
        'id', 'meal_slot_11111111-1111-4111-8111-111111111111',
        'display_name', p_name, 'active', true, 'order', 4)
    )
  );
$$;

create function pg_temp.expect_name(p_name text, p_valid boolean, p_label text)
returns void language plpgsql as $$
begin
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(pg_temp.config_with_name(p_name))
      = p_valid,
    p_label
  );
end;
$$;

-- A canonical name is the baseline every rejection below is measured against.
select pg_temp.expect_name('Pre Workout', true, 'a canonical name is accepted');

-- Rejected: blank, controls, line separators and U+200B.
select pg_temp.expect_name(
  '',
  false,
  'blank: the empty string'
);
select pg_temp.expect_name(
  ' ',
  false,
  'blank: one space'
);
select pg_temp.expect_name(
  '   ',
  false,
  'blank: only spaces'
);
select pg_temp.expect_name(
  pg_catalog.chr(9),
  false,
  'blank-looking: only a tab'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(9) || 'Workout',
  false,
  'embedded tab'
);
select pg_temp.expect_name(
  pg_catalog.chr(9) || 'Lunch',
  false,
  'leading tab'
);
select pg_temp.expect_name(
  'Lunch' || pg_catalog.chr(9),
  false,
  'trailing tab'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(10) || 'Workout',
  false,
  'embedded newline'
);
select pg_temp.expect_name(
  pg_catalog.chr(10) || 'Lunch',
  false,
  'leading newline'
);
select pg_temp.expect_name(
  'Lunch' || pg_catalog.chr(10),
  false,
  'trailing newline'
);
select pg_temp.expect_name(
  'Lunch' || pg_catalog.chr(13),
  false,
  'trailing carriage return'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(31) || 'Workout',
  false,
  'embedded U+001F unit separator'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(127) || 'Workout',
  false,
  'embedded DEL'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(133) || 'Workout',
  false,
  'embedded U+0085 NEL'
);
select pg_temp.expect_name(
  pg_catalog.chr(133) || 'Lunch',
  false,
  'leading U+0085 NEL'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8232) || 'Workout',
  false,
  'embedded U+2028 line separator'
);
select pg_temp.expect_name(
  'Lunch' || pg_catalog.chr(8232),
  false,
  'trailing U+2028 line separator'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8233) || 'Workout',
  false,
  'embedded U+2029 paragraph separator'
);
select pg_temp.expect_name(
  pg_catalog.chr(8203),
  false,
  'a name of nothing but U+200B is not an invisible label'
);
select pg_temp.expect_name(
  pg_catalog.repeat(pg_catalog.chr(8203), 4),
  false,
  'repeated U+200B is still invisible'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8203) || 'Workout',
  false,
  'embedded U+200B zero width space'
);
select pg_temp.expect_name(
  pg_catalog.chr(8203) || 'Lunch',
  false,
  'leading U+200B'
);
select pg_temp.expect_name(
  'Lunch' || pg_catalog.chr(8203),
  false,
  'trailing U+200B'
);

-- Rejected: names that are not already in canonical whitespace form.
select pg_temp.expect_name(
  ' Lunch',
  false,
  'leading space is not canonical'
);
select pg_temp.expect_name(
  'Lunch ',
  false,
  'trailing space is not canonical'
);
select pg_temp.expect_name(
  '  Pre Workout  ',
  false,
  'surrounding spaces are not canonical'
);
select pg_temp.expect_name(
  'Pre  Workout',
  false,
  'two spaces are not canonical'
);
select pg_temp.expect_name(
  'Pre     Workout',
  false,
  'a long run of spaces is not canonical'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(160) || 'Workout',
  false,
  'U+00A0 is not an ordinary space'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8199) || 'Workout',
  false,
  'U+2007 is not an ordinary space'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8239) || 'Workout',
  false,
  'U+202F is not an ordinary space'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(12288) || 'Workout',
  false,
  'U+3000 is not an ordinary space'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(65279) || 'Workout',
  false,
  'U+FEFF is not an ordinary space'
);
select pg_temp.expect_name(
  pg_catalog.chr(160) || 'Lunch',
  false,
  'leading U+00A0'
);
select pg_temp.expect_name(
  'Lunch' || pg_catalog.chr(65279),
  false,
  'trailing U+FEFF'
);

-- Accepted: the format characters that must keep working, and the length boundary this validator does not own.
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8204) || 'Workout',
  true,
  'U+200C ZWNJ stays allowed'
);
select pg_temp.expect_name(
  pg_catalog.chr(2309) || pg_catalog.chr(8204) || pg_catalog.chr(2310),
  true,
  'U+200C ZWNJ in Devanagari stays allowed'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8205) || 'Workout',
  true,
  'U+200D ZWJ stays allowed'
);
select pg_temp.expect_name(
  'Pre' || pg_catalog.chr(8288) || 'Workout',
  true,
  'U+2060 WORD JOINER stays outside the locked boundary'
);
select pg_temp.expect_name(
  'Brunch',
  true,
  'a plain name is accepted (not Lunch: that now collides with the canonical)'
);
select pg_temp.expect_name(
  'Pre Workout Late Night Meal',
  true,
  'a long canonical name is accepted: length is not this validator''s business'
);
select pg_temp.expect_name(
  pg_catalog.repeat(pg_catalog.chr(128104) || pg_catalog.chr(8205) || pg_catalog.chr(128105) || pg_catalog.chr(8205) || pg_catalog.chr(128103) || pg_catalog.chr(8205) || pg_catalog.chr(128102), 24),
  true,
  '24 family emoji: 24 graphemes and 168 code points, so a char_length guard would wrongly reject it'
);

-- Two custom categories beside the four canonical ones, so active-name
-- uniqueness can be exercised without touching any other rule.
create function pg_temp.config_with_two_customs(
  p_first text, p_first_active boolean,
  p_second text, p_second_active boolean
)
returns jsonb language sql immutable as $$
  select pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'items', pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('id', 'meal_slot_1', 'default_key', 'breakfast',
        'display_name', 'Breakfast', 'active', true, 'order', 0),
      pg_catalog.jsonb_build_object('id', 'meal_slot_2', 'default_key', 'lunch',
        'display_name', 'Lunch', 'active', true, 'order', 1),
      pg_catalog.jsonb_build_object('id', 'meal_slot_3', 'default_key', 'dinner',
        'display_name', 'Dinner', 'active', true, 'order', 2),
      pg_catalog.jsonb_build_object('id', 'meal_slot_4', 'default_key', 'snacks',
        'display_name', 'Snacks', 'active', true, 'order', 3),
      pg_catalog.jsonb_build_object(
        'id', 'meal_slot_11111111-1111-4111-8111-111111111111',
        'display_name', p_first, 'active', p_first_active, 'order', 4),
      pg_catalog.jsonb_build_object(
        'id', 'meal_slot_22222222-2222-4222-8222-222222222222',
        'display_name', p_second, 'active', p_second_active, 'order', 5)
    )
  );
$$;

create function pg_temp.expect_pair(
  p_first text, p_first_active boolean,
  p_second text, p_second_active boolean,
  p_valid boolean, p_label text
)
returns void language plpgsql as $$
begin
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_two_customs(
        p_first, p_first_active, p_second, p_second_active
      )
    ) = p_valid,
    p_label
  );
end;
$$;

-- Change one canonical identity's name while leaving the rest of the config
-- valid. A fifth ordinary custom category stays present so this also exercises
-- the same retained shape as the custom-name cases.
create function pg_temp.config_with_canonical_name(
  p_id text,
  p_name text
)
returns jsonb language sql immutable as $$
  select pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'items', pg_catalog.jsonb_agg(
      case when item ->> 'id' = p_id
        then pg_catalog.jsonb_set(
          item,
          '{display_name}',
          pg_catalog.to_jsonb(p_name)
        )
        else item
      end
      order by (item ->> 'order')::integer
    )
  )
  from pg_catalog.jsonb_array_elements(
    pg_temp.config_with_name('Pre Workout') -> 'items'
  ) as item;
$$;

-- Exercise ownership without letting the active exact-duplicate check be the
-- reason a stolen token fails. The permanent owner is renamed first, then the
-- requested identity receives the reserved token.
create function pg_temp.config_with_reserved_assignment(
  p_assignee_id text,
  p_owner_id text,
  p_reserved_name text
)
returns jsonb language sql immutable as $$
  select pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'items', pg_catalog.jsonb_agg(
      case
        when item ->> 'id' = p_assignee_id
          and p_assignee_id = p_owner_id
        then pg_catalog.jsonb_set(
          item, '{display_name}', pg_catalog.to_jsonb(p_reserved_name)
        )
        when item ->> 'id' = p_owner_id
        then pg_catalog.jsonb_set(
          item,
          '{display_name}',
          pg_catalog.to_jsonb('Renamed ' || p_owner_id)
        )
        when item ->> 'id' = p_assignee_id
        then pg_catalog.jsonb_set(
          item, '{display_name}', pg_catalog.to_jsonb(p_reserved_name)
        )
        else item
      end
      order by (item ->> 'order')::integer
    )
  )
  from pg_catalog.jsonb_array_elements(
    pg_temp.config_with_name('Pre Workout') -> 'items'
  ) as item;
$$;

-- Rename one canonical owner and configure the existing custom item in the
-- same payload. This pins both permanent token ownership and the fact that a
-- temporary replacement label does not become reserved.
create function pg_temp.config_with_owner_and_custom_names(
  p_owner_id text,
  p_owner_name text,
  p_custom_name text,
  p_custom_active boolean
)
returns jsonb language sql immutable as $$
  select pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'items', pg_catalog.jsonb_agg(
      case
        when item ->> 'id' = p_owner_id
        then pg_catalog.jsonb_set(
          item, '{display_name}', pg_catalog.to_jsonb(p_owner_name)
        )
        when item ->> 'id' like 'meal_slot_11111111%'
        then pg_catalog.jsonb_set(
          pg_catalog.jsonb_set(
            item, '{display_name}', pg_catalog.to_jsonb(p_custom_name)
          ),
          '{active}',
          pg_catalog.to_jsonb(p_custom_active)
        )
        else item
      end
      order by (item ->> 'order')::integer
    )
  )
  from pg_catalog.jsonb_array_elements(
    pg_temp.config_with_name('Pre Workout') -> 'items'
  ) as item;
$$;

-- The four canonical ASCII tokens are owned forever by their original ids.
-- The full 4x4 matrix renames the true owner away before assigning a stolen
-- token, so every off-diagonal rejection is the ownership rule itself.
do $$
declare
  v_ids text[] := array[
    'meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4'
  ];
  v_names text[] := array['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  v_assignee integer;
  v_token integer;
begin
  for v_assignee in 1..4 loop
    for v_token in 1..4 loop
      perform pg_temp.assert_true(
        private.is_valid_meal_categories_config_v1(
          pg_temp.config_with_reserved_assignment(
            v_ids[v_assignee],
            v_ids[v_token],
            v_names[v_token]
          )
        ) = (v_assignee = v_token),
        pg_catalog.format(
          'reserved token %s is accepted only for %s, not %s',
          v_names[v_token],
          v_ids[v_token],
          v_ids[v_assignee]
        )
      );
    end loop;
  end loop;
end;
$$;

-- ASCII case variants of an owner's own token remain valid.
select pg_temp.assert_true(
  private.is_valid_meal_categories_config_v1(
    pg_temp.config_with_canonical_name('meal_slot_2', 'lunch')
  ),
  'meal_slot_2 may use lower-case lunch'
);
select pg_temp.assert_true(
  private.is_valid_meal_categories_config_v1(
    pg_temp.config_with_canonical_name('meal_slot_2', 'LUNCH')
  ),
  'meal_slot_2 may use upper-case LUNCH'
);

-- Active custom categories cannot hold any reserved token, including mixed
-- ASCII case variants.
do $$
declare
  v_names text[] := array[
    'Breakfast', 'Lunch', 'Dinner', 'Snacks', 'lunch', 'LUNCH', 'LuNcH'
  ];
  v_owner_ids text[] := array[
    'meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4',
    'meal_slot_2', 'meal_slot_2', 'meal_slot_2'
  ];
  v_index integer;
begin
  for v_index in 1..pg_catalog.array_length(v_names, 1) loop
    perform pg_temp.assert_true(
      not private.is_valid_meal_categories_config_v1(
        pg_temp.config_with_owner_and_custom_names(
          v_owner_ids[v_index],
          'Renamed ' || v_owner_ids[v_index],
          v_names[v_index],
          true
        )
      ),
      pg_catalog.format(
        'active custom cannot use reserved token %s',
        v_names[v_index]
      )
    );
  end loop;
end;
$$;

-- Archived custom categories are covered too; archive state never releases a
-- canonical token.
do $$
declare
  v_name text;
begin
  foreach v_name in array array['Breakfast', 'Lunch', 'Dinner', 'Snacks'] loop
    perform pg_temp.assert_true(
      not private.is_valid_meal_categories_config_v1(
        pg_temp.config_with_two_customs(
          v_name, false, 'Post Workout', true
        )
      ),
      pg_catalog.format('archived custom cannot use reserved token %s', v_name)
    );
  end loop;
end;
$$;

select pg_temp.assert_true(
  not private.is_valid_meal_categories_config_v1(
    pg_temp.config_with_owner_and_custom_names(
      'meal_slot_2', 'Mid Meal', 'Lunch', true
    )
  ),
  'renaming Lunch to Mid Meal does not release the Lunch token'
);

select pg_temp.assert_true(
  private.is_valid_meal_categories_config_v1(
    pg_temp.config_with_owner_and_custom_names(
      'meal_slot_2', 'Lunch', 'Mid Meal', true
    )
  ),
  'a canonical owner replacement label does not become reserved'
);

-- Active display names must be unique, compared exactly as stored.
select pg_temp.expect_pair(
  'Pre Workout', true, 'Pre Workout', true, false,
  'two active customs cannot share a name'
);
select pg_temp.expect_pair(
  'Pre Workout', true, 'Post Workout', true, true,
  'two different active names are fine'
);

-- Archived ordinary names are outside the duplicate rule, which is what lets
-- an ordinary name be reused after archiving. Reserved names remain refused by
-- their separate identity rule.
select pg_temp.expect_pair(
  'Lunch', false, 'Post Workout', true, false,
  'an archived custom may not hold a reserved canonical token'
);
select pg_temp.expect_pair(
  'Pre Workout', true, 'Pre Workout', false, true,
  'an archived duplicate of an active name is allowed'
);
select pg_temp.expect_pair(
  'Pre Workout', false, 'Pre Workout', false, true,
  'two archived duplicates are allowed'
);

-- THE BOUNDARY THIS VALIDATOR DOES NOT COVER.
--
-- The Dart policy refuses these, because its comparison key is lowercased.
-- This validator accepts them, because PostgreSQL's lower() is not Dart's
-- toLowerCase() on this database: it disagrees on U+0130, and on a Greek word
-- spelled with a final sigma it folds two names the app keeps apart, which
-- would make the database refuse a configuration the app accepts.
--
-- Asserted as accepted on purpose. If someone later adds lower() here these
-- fail, and the failure is the point: it forces the parity question to be
-- answered again rather than assumed.
select pg_temp.expect_pair(
  'Pre Workout', true, 'pre workout', true, true,
  'BOUNDARY: case-only duplicate customs are accepted here'
);
select pg_temp.expect_pair(
  'Pre Workout', true, 'PRE WORKOUT', true, true,
  'BOUNDARY: upper-case duplicate customs are accepted here'
);

-- ---------------------------------------------------------------------------
-- Reserved tokens spelled with the two non-ASCII code points that the pinned
-- Dart runtime lowercases into ASCII letters.
--
-- Every valid scalar except surrogates was scanned on Dart 3.12.2 and exactly
-- two qualify: U+0130 reaches `dinner`, U+212A reaches `breakfast` and
-- `snacks`. `lunch` is unreachable. An A-Z fold left all of these looking like
-- ordinary names, so a direct API write could park DINNER-with-U+0130 on a
-- custom category and the app would then refuse to read the row back.
--
-- Built from chr() rather than pasted, so each case is readable in the source.
do $$
declare
  v_dotted_i text := pg_catalog.chr(304);
  v_kelvin text := pg_catalog.chr(8490);
  v_name text;
  v_owner text;
begin
  -- Active custom holding a Unicode-spelled reserved token: refused.
  foreach v_name in array array[
    'D' || v_dotted_i || 'NNER',
    'd' || v_dotted_i || 'nner',
    'D' || v_dotted_i || 'nner',
    'SNAC' || v_kelvin || 'S',
    'snac' || v_kelvin || 's',
    'BREA' || v_kelvin || 'FAST',
    'brea' || v_kelvin || 'fast'
  ]
  loop
    perform pg_temp.assert_true(
      not private.is_valid_meal_categories_config_v1(
        pg_temp.config_with_name(v_name)
      ),
      pg_catalog.format(
        'active custom must not hold Unicode-spelled reserved token %s', v_name
      )
    );
  end loop;

  -- The same names archived: still refused, because the reservation is not the
  -- active-only duplicate rule.
  foreach v_name in array array[
    'D' || v_dotted_i || 'NNER',
    'SNAC' || v_kelvin || 'S',
    'BREA' || v_kelvin || 'FAST'
  ]
  loop
    perform pg_temp.assert_true(
      not private.is_valid_meal_categories_config_v1(
        pg_temp.config_with_owner_and_custom_names(
          'meal_slot_2', 'Lunch', v_name, false
        )
      ),
      pg_catalog.format(
        'archived custom must not hold Unicode-spelled reserved token %s',
        v_name
      )
    );
  end loop;

  -- The correct canonical owner may spell its own token that way.
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_canonical_name(
        'meal_slot_3', 'D' || v_dotted_i || 'NNER'
      )
    ),
    'meal_slot_3 may spell DINNER with U+0130'
  );
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_canonical_name(
        'meal_slot_4', 'SNAC' || v_kelvin || 'S'
      )
    ),
    'meal_slot_4 may spell SNACKS with U+212A'
  );
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_canonical_name(
        'meal_slot_1', 'BREA' || v_kelvin || 'FAST'
      )
    ),
    'meal_slot_1 may spell BREAKFAST with U+212A'
  );

  -- A different canonical identity may not.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_reserved_assignment(
        'meal_slot_2', 'meal_slot_3', 'D' || v_dotted_i || 'NNER'
      )
    ),
    'meal_slot_2 must not take DINNER spelled with U+0130'
  );
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_reserved_assignment(
        'meal_slot_1', 'meal_slot_4', 'SNAC' || v_kelvin || 'S'
      )
    ),
    'meal_slot_1 must not take SNACKS spelled with U+212A'
  );

  -- Renaming the owner away releases nothing, in this spelling too.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_owner_and_custom_names(
        'meal_slot_3', 'Evening Meal', 'D' || v_dotted_i || 'NNER', true
      )
    ),
    'DINNER stays reserved while meal_slot_3 is called something else'
  );

  -- The fold is exactly these two code points and nothing wider. A name that
  -- merely contains one of them is an ordinary name.
  foreach v_name in array array[
    'D' || v_dotted_i || 'NNERS',
    'Mid ' || v_kelvin || 'eal',
    'Snac' || v_kelvin
  ]
  loop
    perform pg_temp.assert_true(
      private.is_valid_meal_categories_config_v1(
        pg_temp.config_with_name(v_name)
      ),
      pg_catalog.format('%s is an ordinary name, not a reserved token', v_name)
    );
  end loop;

  -- And the fold has not turned into general case folding: a Greek or Turkish
  -- variant of an ordinary name is still an ordinary distinct name, which is
  -- what keeps the app-authoritative duplicate gap where it is.
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(
      pg_temp.config_with_two_customs(
        'Pre Workout', true, 'PRE WORKOUT', true
      )
    ),
    'case-only ordinary duplicates remain accepted here, as documented'
  );
end;
$$;

-- The TNYX-67 rules must still hold. The name checks are additions, not a
-- replacement, so every one of these has to fail for its original reason.
do $$
declare
  v_canonical jsonb := pg_temp.config_with_name('Pre Workout');
begin
  perform pg_temp.assert_true(
    private.is_valid_meal_categories_config_v1(v_canonical),
    'the canonical five-item configuration is still valid'
  );

  -- Nothing active.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1((
      select pg_catalog.jsonb_build_object(
        'schema_version', 1,
        'items', pg_catalog.jsonb_agg(
          pg_catalog.jsonb_set(item, '{active}', 'false'::jsonb)
        )
      )
      from pg_catalog.jsonb_array_elements(v_canonical -> 'items') as item
    )),
    'a configuration with nothing active is still refused'
  );

  -- Canonical order inverted: give breakfast a later order than lunch.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1((
      select pg_catalog.jsonb_build_object(
        'schema_version', 1,
        'items', pg_catalog.jsonb_agg(
          case when item ->> 'id' = 'meal_slot_1'
               then pg_catalog.jsonb_set(item, '{order}', '9'::jsonb)
               else item end
        )
      )
      from pg_catalog.jsonb_array_elements(v_canonical -> 'items') as item
    )),
    'breakfast after lunch is still refused'
  );

  -- A missing canonical default.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1((
      select pg_catalog.jsonb_build_object(
        'schema_version', 1,
        'items', pg_catalog.jsonb_agg(item)
      )
      from pg_catalog.jsonb_array_elements(v_canonical -> 'items') as item
      where item ->> 'id' <> 'meal_slot_4'
    )),
    'dropping a canonical default is still refused'
  );

  -- An unsupported schema version.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1(
      pg_catalog.jsonb_set(v_canonical, '{schema_version}', '2'::jsonb)
    ),
    'schema_version 2 is still refused'
  );

  -- A custom id outside the lowercase UUID v4 contract.
  perform pg_temp.assert_true(
    not private.is_valid_meal_categories_config_v1((
      select pg_catalog.jsonb_build_object(
        'schema_version', 1,
        'items', pg_catalog.jsonb_agg(
          case when item ->> 'id' like 'meal_slot_1111%'
               then pg_catalog.jsonb_set(item, '{id}', '"meal_slot_pre_workout"'::jsonb)
               else item end
        )
      )
      from pg_catalog.jsonb_array_elements(v_canonical -> 'items') as item
    )),
    'a malformed custom id is still refused'
  );
end;
$$;

-- The function's posture is part of the contract, not an implementation
-- detail: a CHECK constraint may only call an immutable function, and the
-- empty search_path is what stops a caller's schema shadowing pg_catalog.
select pg_temp.assert_true(
  (select p.provolatile = 'i' and p.proisstrict and not p.prosecdef
     and p.proconfig @> array['search_path=""']
   from pg_catalog.pg_proc as p
   join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
   where n.nspname = 'private'
     and p.proname = 'is_valid_meal_categories_config_v1'),
  'the validator stays immutable, strict, security invoker, search_path empty'
);

select pg_temp.assert_true(
  (select count(*) = 1
   from pg_catalog.pg_constraint as c
   where c.conrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
     and c.conname = 'user_nutrition_profiles_meal_categories_config_valid'),
  'the CHECK constraint is still the single entry point'
);

select pg_temp.assert_true(
  (select count(*) = 1
   from pg_catalog.pg_trigger as t
   where t.tgrelid = 'public.user_nutrition_profiles'::pg_catalog.regclass
     and t.tgname = 'trg_user_nutrition_profiles_protect_meal_category_retained_ids'),
  'the retained-ID trigger is untouched'
);

select last_value as tnyx_186_assertion_count
from pg_temp.tnyx_186_assertion_seq;

rollback;

\echo 'TNYX-186 Slice B display-name SQL matrix passed.'
