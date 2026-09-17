-- TNYX-217 / N20A-8: physical persistence foundation for detailed MealLog history.
--
-- This migration widens the existing canonical MealLog parent and adds ordered
-- provider-independent consumed item snapshots. Repository/RPC/UI/parser
-- activation remains outside this slice.

do $$
begin
  if pg_catalog.to_regclass('public.meal_log_entries') is null then
    raise exception 'TNYX-217 blocked: public.meal_log_entries is missing';
  end if;

  if pg_catalog.to_regclass('public.meal_log_item_snapshots') is not null then
    raise exception 'TNYX-217 blocked: public.meal_log_item_snapshots already exists';
  end if;

  if pg_catalog.to_regprocedure('private.is_valid_nutrition_snapshot_v1(jsonb)') is null then
    raise exception 'TNYX-217 blocked: private.is_valid_nutrition_snapshot_v1(jsonb) is missing';
  end if;

  if exists (
    select 1
    from public.meal_log_entries
    where mode <> 'manual'
      or manual_nutrition_snapshot is null
  ) then
    raise exception 'TNYX-217 blocked: existing MealLog rows are not compatible with the manual baseline';
  end if;
end
$$;

alter table public.meal_log_entries
  drop constraint meal_log_entries_mode_manual_only,
  alter column manual_nutrition_snapshot drop not null;

alter table public.meal_log_entries
  add constraint meal_log_entries_mode_check
    check (mode in ('manual', 'detailed')),
  add constraint meal_log_entries_mode_nutrition_shape
    check (
      (mode = 'manual' and manual_nutrition_snapshot is not null)
      or
      (mode = 'detailed' and manual_nutrition_snapshot is null)
    );

comment on table public.meal_log_entries is
  'Canonical actual MealLog history. Manual entries own a meal-level NutritionSnapshot; detailed entries own ordered item snapshots.';
comment on column public.meal_log_entries.manual_nutrition_snapshot is
  'Canonical provider-independent NutritionSnapshot JSON for manual/coarse entries; null for detailed entries whose nutrition truth is owned by child snapshots.';

create table public.meal_log_item_snapshots (
  id uuid primary key default gen_random_uuid(),
  meal_log_entry_id uuid not null,
  position integer not null,
  display_name text not null,
  brand_name text,
  quantity numeric not null,
  serving_unit text not null,
  nutrition_snapshot jsonb not null,

  constraint meal_log_item_snapshots_entry_fkey
    foreign key (meal_log_entry_id)
    references public.meal_log_entries(id)
    on delete cascade,
  constraint meal_log_item_snapshots_entry_position_key
    unique (meal_log_entry_id, position),
  constraint meal_log_item_snapshots_position_nonnegative
    check (position >= 0),
  constraint meal_log_item_snapshots_display_name_nonblank
    check (pg_catalog.btrim(display_name) <> ''),
  constraint meal_log_item_snapshots_brand_name_nonblank
    check (brand_name is null or pg_catalog.btrim(brand_name) <> ''),
  constraint meal_log_item_snapshots_quantity_positive_finite
    check (quantity > 0 and quantity < 'Infinity'::numeric),
  constraint meal_log_item_snapshots_serving_unit_nonblank
    check (pg_catalog.btrim(serving_unit) <> ''),
  constraint meal_log_item_snapshots_nutrition_snapshot_valid
    check (private.is_valid_nutrition_snapshot_v1(nutrition_snapshot))
);

comment on table public.meal_log_item_snapshots is
  'Ordered durable consumed-item truth for detailed MealLog entries. Nutrition snapshots are historical truth; provider provenance is intentionally not stored in V1.';
comment on column public.meal_log_item_snapshots.position is
  'Zero-based persistence order for deterministic reconstruction of the detailed MealLog item list.';
comment on column public.meal_log_item_snapshots.nutrition_snapshot is
  'Canonical provider-independent consumed-total NutritionSnapshot JSON for this confirmed quantity and serving unit.';

alter table public.meal_log_item_snapshots enable row level security;

revoke all on table public.meal_log_item_snapshots
  from anon, authenticated, service_role;
grant select, insert, update, delete on table public.meal_log_item_snapshots
  to authenticated;
grant select, insert, update, delete on table public.meal_log_item_snapshots
  to service_role;

create policy meal_log_item_snapshots_select_own
  on public.meal_log_item_snapshots
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.meal_log_entries as entry
      where entry.id = meal_log_entry_id
        and entry.user_id = (select auth.uid())
    )
  );

create policy meal_log_item_snapshots_insert_own_detailed
  on public.meal_log_item_snapshots
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.meal_log_entries as entry
      where entry.id = meal_log_entry_id
        and entry.user_id = (select auth.uid())
        and entry.mode = 'detailed'
    )
  );

create policy meal_log_item_snapshots_update_own_detailed
  on public.meal_log_item_snapshots
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.meal_log_entries as entry
      where entry.id = meal_log_entry_id
        and entry.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.meal_log_entries as entry
      where entry.id = meal_log_entry_id
        and entry.user_id = (select auth.uid())
        and entry.mode = 'detailed'
    )
  );

create policy meal_log_item_snapshots_delete_own
  on public.meal_log_item_snapshots
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.meal_log_entries as entry
      where entry.id = meal_log_entry_id
        and entry.user_id = (select auth.uid())
    )
  );

create function private.assert_meal_log_entry_item_cardinality(p_entry_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_mode text;
  v_item_count bigint;
begin
  select entry.mode
  into v_mode
  from public.meal_log_entries as entry
  where entry.id = p_entry_id;

  if not found then
    -- Parent deletion may cascade child deletes whose deferred trigger events
    -- are still queued. A missing parent is valid in that case.
    return;
  end if;

  select pg_catalog.count(*)
  into v_item_count
  from public.meal_log_item_snapshots as item
  where item.meal_log_entry_id = p_entry_id;

  if v_mode = 'manual' and v_item_count <> 0 then
    raise exception using
      errcode = '23514',
      message = 'manual MealLog entries cannot own detailed item snapshots';
  end if;

  if v_mode = 'detailed' and v_item_count < 1 then
    raise exception using
      errcode = '23514',
      message = 'detailed MealLog entries require at least one item snapshot';
  end if;
end;
$$;

create function private.enforce_meal_log_entry_item_cardinality()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_table_name = 'meal_log_entries' then
    perform private.assert_meal_log_entry_item_cardinality(new.id);
    return null;
  end if;

  if tg_op = 'INSERT' then
    perform private.assert_meal_log_entry_item_cardinality(new.meal_log_entry_id);
    return null;
  end if;

  if tg_op = 'DELETE' then
    perform private.assert_meal_log_entry_item_cardinality(old.meal_log_entry_id);
    return null;
  end if;

  if old.meal_log_entry_id is distinct from new.meal_log_entry_id then
    perform private.assert_meal_log_entry_item_cardinality(old.meal_log_entry_id);
  end if;
  perform private.assert_meal_log_entry_item_cardinality(new.meal_log_entry_id);
  return null;
end;
$$;

revoke all on function private.assert_meal_log_entry_item_cardinality(uuid)
  from public, anon, authenticated, service_role;
revoke all on function private.enforce_meal_log_entry_item_cardinality()
  from public, anon, authenticated, service_role;
grant execute on function private.assert_meal_log_entry_item_cardinality(uuid)
  to authenticated, service_role;
grant execute on function private.enforce_meal_log_entry_item_cardinality()
  to authenticated, service_role;

create constraint trigger trg_meal_log_entries_item_cardinality
  after insert or update of mode on public.meal_log_entries
  deferrable initially deferred
  for each row
  execute function private.enforce_meal_log_entry_item_cardinality();

create constraint trigger trg_meal_log_item_snapshots_parent_cardinality
  after insert or update or delete on public.meal_log_item_snapshots
  deferrable initially deferred
  for each row
  execute function private.enforce_meal_log_entry_item_cardinality();