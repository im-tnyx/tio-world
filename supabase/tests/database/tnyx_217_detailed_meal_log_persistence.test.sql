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

-- Migration ledger and approved physical shape.
select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260917083552'),
  'migration ledger must contain TNYX-217 detailed persistence migration exactly once'
);

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260917083919'),
  'migration ledger must contain TNYX-217 grant-hardening migration exactly once'
);

select pg_temp.assert_true(
  (select data_type = 'jsonb' and is_nullable = 'YES'
   from information_schema.columns
   where table_schema = 'public'
     and table_name = 'meal_log_entries'
     and column_name = 'manual_nutrition_snapshot'),
  'manual snapshot column must be nullable so detailed mode can carry no meal-level total'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_mode_check'
      and contype = 'c'
  ),
  'parent mode check must exist'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_mode_nutrition_shape'
      and contype = 'c'
  ),
  'parent mode/nutrition shape check must exist'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_mode_manual_only'
  ),
  'legacy manual-only mode constraint must be retired'
);

select pg_temp.assert_true(
  pg_catalog.to_regclass('public.meal_log_item_snapshots') is not null,
  'detailed child table must exist'
);

select pg_temp.assert_true(
  (select array_agg(column_name::text order by ordinal_position)
   from information_schema.columns
   where table_schema = 'public'
     and table_name = 'meal_log_item_snapshots') = array[
    'id',
    'meal_log_entry_id',
    'position',
    'display_name',
    'brand_name',
    'quantity',
    'serving_unit',
    'nutrition_snapshot'
  ]::text[],
  'child table must contain only the approved V1 columns'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_catalog.pg_class
   where oid = 'public.meal_log_item_snapshots'::pg_catalog.regclass),
  'child RLS must be enabled'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_item_snapshots'::pg_catalog.regclass
      and conname = 'meal_log_item_snapshots_entry_fkey'
      and contype = 'f'
      and confrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and confdeltype = 'c'
  ),
  'child FK must target MealLog parent ON DELETE CASCADE'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_item_snapshots'::pg_catalog.regclass
      and conname = 'meal_log_item_snapshots_entry_position_key'
      and contype = 'u'
  ),
  'child order must be unique per parent'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_item_snapshots'::pg_catalog.regclass
      and conname = 'meal_log_item_snapshots_quantity_positive_finite'
      and contype = 'c'
  ),
  'child quantity must have a positive finite check'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_item_snapshots'::pg_catalog.regclass
      and conname = 'meal_log_item_snapshots_nutrition_snapshot_valid'
      and contype = 'c'
  ),
  'child nutrition snapshot must use the canonical validator'
);

select pg_temp.assert_true(
  (select count(*) = 2
   from pg_catalog.pg_trigger
   where tgname in (
     'trg_meal_log_entries_item_cardinality',
     'trg_meal_log_item_snapshots_parent_cardinality'
   )
     and not tgisinternal
     and tgconstraint <> 0
     and tgdeferrable
     and tginitdeferred),
  'both aggregate integrity triggers must be deferred constraint triggers'
);

select pg_temp.assert_true(
  (select count(*) = 2
   from pg_catalog.pg_proc as p
   join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
   where n.nspname = 'private'
     and p.proname in (
       'assert_meal_log_entry_item_cardinality',
       'enforce_meal_log_entry_item_cardinality'
     )
     and not p.prosecdef
     and pg_catalog.pg_get_functiondef(p.oid) ilike '%SET search_path TO ''''%'),
  'aggregate helpers must be security-invoker functions with empty search paths'
);

-- Grants and RLS: read-only authenticated clients until the atomic write boundary lands.
select pg_temp.assert_true(
  not has_table_privilege('anon', 'public.meal_log_item_snapshots', 'SELECT')
    and not has_table_privilege('anon', 'public.meal_log_item_snapshots', 'INSERT')
    and not has_table_privilege('anon', 'public.meal_log_item_snapshots', 'UPDATE')
    and not has_table_privilege('anon', 'public.meal_log_item_snapshots', 'DELETE'),
  'anon must have no child-table DML privileges'
);

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'SELECT')
    and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'INSERT')
    and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'UPDATE')
    and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'DELETE')
    and not has_table_privilege('authenticated', 'public.meal_log_item_snapshots', 'TRUNCATE'),
  'authenticated clients must be child-table read-only in this slice'
);

select pg_temp.assert_true(
  has_table_privilege('service_role', 'public.meal_log_item_snapshots', 'SELECT')
    and has_table_privilege('service_role', 'public.meal_log_item_snapshots', 'INSERT')
    and has_table_privilege('service_role', 'public.meal_log_item_snapshots', 'UPDATE')
    and has_table_privilege('service_role', 'public.meal_log_item_snapshots', 'DELETE')
    and not has_table_privilege('service_role', 'public.meal_log_item_snapshots', 'TRUNCATE'),
  'service role must have explicit child-table CRUD only'
);

select pg_temp.assert_true(
  (select array_agg(policyname order by policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public'
     and tablename = 'meal_log_item_snapshots') = array[
    'meal_log_item_snapshots_delete_own',
    'meal_log_item_snapshots_insert_own_detailed',
    'meal_log_item_snapshots_select_own',
    'meal_log_item_snapshots_update_own_detailed'
  ]::name[],
  'exactly four owner-scoped child policies must exist'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename = 'meal_log_item_snapshots'
      and roles <> array['authenticated']::name[]
  ),
  'all child policies must target authenticated only'
);

-- Provision an owner and a manual baseline row for compatibility and snapshot reuse.
insert into auth.users (id, email)
values ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'tnyx-217-owner@example.test');

insert into public.meal_log_entries (
  id,
  user_id,
  mode,
  meal_category_id,
  meal_name,
  consumed_at,
  consumed_local_date,
  consumed_utc_offset_minutes,
  capture_source,
  manual_nutrition_snapshot,
  client_mutation_id
)
values (
  '10000000-0000-4000-8000-000000000001',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  'manual',
  'meal_slot_1',
  'TNYX-217 manual compatibility',
  '2026-09-17T06:30:00Z',
  '2026-09-17',
  330,
  'quick_add',
  '{"schemaVersion":1,"nutrients":{"energy":500,"protein":25}}',
  '10000000-0000-4000-8000-000000000002'
);

select pg_temp.assert_true(
  (select mode = 'manual'
      and manual_nutrition_snapshot is not null
      and revision = 1
   from public.meal_log_entries
   where id = '10000000-0000-4000-8000-000000000001'),
  'existing manual aggregate shape and revision initialization must remain valid'
);

-- Immediate parent shape checks.
do $$
declare
  v_rejected boolean := false;
begin
  begin
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      '10000000-0000-4000-8000-000000000003',
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'manual', 'meal_slot_1',
      '2026-09-17T07:00:00Z', '2026-09-17', 330,
      null
    );
  exception when check_violation then
    v_rejected := true;
  end;

  if not v_rejected then
    raise exception 'assertion failed: manual parent without manual nutrition snapshot must be rejected';
  end if;
end
$$;

do $$
declare
  v_rejected boolean := false;
begin
  begin
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      '10000000-0000-4000-8000-000000000004',
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'detailed', 'meal_slot_1',
      '2026-09-17T07:00:00Z', '2026-09-17', 330,
      '{"schemaVersion":1,"nutrients":{}}'
    );
  exception when check_violation then
    v_rejected := true;
  end;

  if not v_rejected then
    raise exception 'assertion failed: detailed parent with manual nutrition snapshot must be rejected';
  end if;
end
$$;

-- Deferred aggregate cardinality and child validity.
do $$
declare
  v_empty_detailed_rejected boolean := false;
  v_manual_child_rejected boolean := false;
  v_infinite_quantity_rejected boolean := false;
  v_last_child_delete_rejected boolean := false;
  v_parent_cascade_passed boolean := false;
  v_parent uuid;
  v_child uuid;
  v_snapshot jsonb := '{"schemaVersion":1,"nutrients":{"energy":300,"protein":20}}'::jsonb;
begin
  begin
    v_parent := '20000000-0000-4000-8000-000000000001';
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      v_parent,
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'detailed', 'meal_slot_1',
      '2026-09-17T08:00:00Z', '2026-09-17', 330,
      null
    );
    set constraints all immediate;
  exception when check_violation then
    v_empty_detailed_rejected := true;
  end;
  set constraints all deferred;

  begin
    v_parent := '20000000-0000-4000-8000-000000000002';
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      v_parent,
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'manual', 'meal_slot_1',
      '2026-09-17T08:00:00Z', '2026-09-17', 330,
      v_snapshot
    );
    insert into public.meal_log_item_snapshots (
      meal_log_entry_id, position, display_name,
      quantity, serving_unit, nutrition_snapshot
    ) values (
      v_parent, 0, 'Invalid manual child',
      1, 'serving', v_snapshot
    );
    set constraints all immediate;
  exception when check_violation then
    v_manual_child_rejected := true;
  end;
  set constraints all deferred;

  begin
    v_parent := '20000000-0000-4000-8000-000000000003';
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      v_parent,
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'detailed', 'meal_slot_1',
      '2026-09-17T08:00:00Z', '2026-09-17', 330,
      null
    );
    insert into public.meal_log_item_snapshots (
      meal_log_entry_id, position, display_name,
      quantity, serving_unit, nutrition_snapshot
    ) values (
      v_parent, 0, 'Invalid infinite quantity',
      'Infinity'::numeric, 'serving', v_snapshot
    );
  exception when check_violation then
    v_infinite_quantity_rejected := true;
  end;
  set constraints all deferred;

  begin
    v_parent := '20000000-0000-4000-8000-000000000004';
    v_child := '30000000-0000-4000-8000-000000000001';
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      v_parent,
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'detailed', 'meal_slot_1',
      '2026-09-17T08:00:00Z', '2026-09-17', 330,
      null
    );
    insert into public.meal_log_item_snapshots (
      id, meal_log_entry_id, position, display_name,
      quantity, serving_unit, nutrition_snapshot
    ) values (
      v_child, v_parent, 0, 'Valid detailed item',
      1, 'serving', v_snapshot
    );
    set constraints all immediate;
    set constraints all deferred;
    delete from public.meal_log_item_snapshots where id = v_child;
    set constraints all immediate;
  exception when check_violation then
    v_last_child_delete_rejected := true;
  end;
  set constraints all deferred;

  begin
    v_parent := '20000000-0000-4000-8000-000000000005';
    v_child := '30000000-0000-4000-8000-000000000002';
    insert into public.meal_log_entries (
      id, user_id, mode, meal_category_id,
      consumed_at, consumed_local_date, consumed_utc_offset_minutes,
      manual_nutrition_snapshot
    ) values (
      v_parent,
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      'detailed', 'meal_slot_1',
      '2026-09-17T08:00:00Z', '2026-09-17', 330,
      null
    );
    insert into public.meal_log_item_snapshots (
      id, meal_log_entry_id, position, display_name,
      quantity, serving_unit, nutrition_snapshot
    ) values (
      v_child, v_parent, 0, 'Cascade item',
      1, 'serving', v_snapshot
    );
    set constraints all immediate;
    set constraints all deferred;
    delete from public.meal_log_entries where id = v_parent;
    set constraints all immediate;
    v_parent_cascade_passed :=
      not exists (select 1 from public.meal_log_entries where id = v_parent)
      and not exists (select 1 from public.meal_log_item_snapshots where id = v_child);
  end;
  set constraints all deferred;

  if not v_empty_detailed_rejected then
    raise exception 'assertion failed: empty detailed parent must be rejected';
  end if;
  if not v_manual_child_rejected then
    raise exception 'assertion failed: manual parent must not own detailed children';
  end if;
  if not v_infinite_quantity_rejected then
    raise exception 'assertion failed: infinite quantity must be rejected';
  end if;
  if not v_last_child_delete_rejected then
    raise exception 'assertion failed: deleting the final detailed child must be rejected';
  end if;
  if not v_parent_cascade_passed then
    raise exception 'assertion failed: deleting a detailed parent must cascade its children';
  end if;
end
$$;

-- Persist one valid detailed aggregate inside the outer rollback transaction for RLS reads.
insert into public.meal_log_entries (
  id, user_id, mode, meal_category_id,
  consumed_at, consumed_local_date, consumed_utc_offset_minutes,
  capture_source, manual_nutrition_snapshot, client_mutation_id
)
values (
  '20000000-0000-4000-8000-000000000006',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  'detailed', 'meal_slot_2',
  '2026-09-17T09:00:00Z', '2026-09-17', 330,
  'text', null,
  '20000000-0000-4000-8000-000000000007'
);

insert into public.meal_log_item_snapshots (
  id, meal_log_entry_id, position, display_name, brand_name,
  quantity, serving_unit, nutrition_snapshot
)
values (
  '30000000-0000-4000-8000-000000000003',
  '20000000-0000-4000-8000-000000000006',
  0, 'Dal', null,
  1, 'bowl',
  '{"schemaVersion":1,"nutrients":{"energy":220,"protein":12}}'
);

set constraints all immediate;
set constraints all deferred;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  (select count(*) = 1
   from public.meal_log_item_snapshots
   where meal_log_entry_id = '20000000-0000-4000-8000-000000000006'),
  'owner must be able to read owned detailed item snapshots'
);

select set_config('request.jwt.claim.sub', 'ffffffff-ffff-4fff-8fff-ffffffffffff', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"ffffffff-ffff-4fff-8fff-ffffffffffff","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  (select count(*) = 0
   from public.meal_log_item_snapshots
   where meal_log_entry_id = '20000000-0000-4000-8000-000000000006'),
  'non-owner must not read another user detailed item snapshots'
);

reset role;

rollback;
