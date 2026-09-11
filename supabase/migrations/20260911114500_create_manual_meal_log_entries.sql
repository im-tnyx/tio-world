-- TNYX-194 / N20A-5: first physical persistence owner for manual MealLog history.
--
-- This intentionally supports manual/coarse entries only. Detailed items,
-- serving/serving-size, media, idempotency/version fields, and app wiring remain
-- separate later slices.

do $$
begin
  if pg_catalog.to_regclass('public.meal_log_entries') is not null then
    raise exception 'TNYX-194 blocked: public.meal_log_entries already exists';
  end if;

  if pg_catalog.to_regprocedure('public.set_row_updated_at()') is null then
    raise exception 'TNYX-194 blocked: public.set_row_updated_at() is missing';
  end if;

  if pg_catalog.to_regprocedure('private.is_valid_nutrition_snapshot_v1(jsonb)') is not null then
    raise exception 'TNYX-194 blocked: reserved nutrition snapshot validator already exists';
  end if;
end
$$;

-- Keep the DB validator aligned with the current shared NutritionSnapshot codec:
-- require the canonical envelope, require an integer schemaVersion, validate
-- currently-known nutrient identities, and tolerate unknown future identities
-- rather than remapping or rejecting unrelated known data.
create function private.is_valid_nutrition_snapshot_v1(p_snapshot jsonb)
returns boolean
language plpgsql
immutable
strict
security invoker
set search_path = ''
as $$
declare
  v_key text;
  v_value jsonb;
begin
  if pg_catalog.jsonb_typeof(p_snapshot) <> 'object'
    or not (p_snapshot ?& array['schemaVersion', 'nutrients']::text[])
    or pg_catalog.jsonb_typeof(p_snapshot -> 'schemaVersion') <> 'number'
    or (p_snapshot ->> 'schemaVersion') !~ '^-?(0|[1-9][0-9]*)$'
    or pg_catalog.jsonb_typeof(p_snapshot -> 'nutrients') <> 'object'
  then
    return false;
  end if;

  for v_key, v_value in
    select key, value
    from pg_catalog.jsonb_each(p_snapshot -> 'nutrients')
  loop
    if v_key = any (array[
      'energy',
      'protein',
      'carbohydrate',
      'fat',
      'fiber',
      'saturated_fat',
      'trans_fat',
      'added_sugar',
      'sodium',
      'calcium',
      'phosphorus',
      'vitamin_d'
    ]::text[])
    then
      if pg_catalog.jsonb_typeof(v_value) <> 'number'
        or (v_value #>> '{}')::numeric < 0
      then
        return false;
      end if;
    end if;
  end loop;

  return true;
end;
$$;

revoke all on function private.is_valid_nutrition_snapshot_v1(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function private.is_valid_nutrition_snapshot_v1(jsonb)
  to authenticated, service_role;

create table public.meal_log_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,

  mode text not null,
  meal_category_id text not null,
  meal_name text,
  note text,

  consumed_at timestamptz not null,
  consumed_local_date date not null,
  consumed_timezone_id text,
  consumed_utc_offset_minutes integer,

  capture_source text,
  manual_nutrition_snapshot jsonb not null,

  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),

  constraint meal_log_entries_mode_manual_only
    check (mode = 'manual'),
  constraint meal_log_entries_timezone_id_nonblank
    check (consumed_timezone_id is null or btrim(consumed_timezone_id) <> ''),
  constraint meal_log_entries_time_context_required
    check (
      consumed_timezone_id is not null
      or consumed_utc_offset_minutes is not null
    ),
  constraint meal_log_entries_capture_source_check
    check (
      capture_source is null
      or capture_source in (
        'quick_add',
        'food_search',
        'barcode',
        'text',
        'voice',
        'photo',
        'recent',
        'saved_meal',
        'planned_meal'
      )
    ),
  constraint meal_log_entries_manual_nutrition_snapshot_valid
    check (
      private.is_valid_nutrition_snapshot_v1(manual_nutrition_snapshot)
    )
);

comment on table public.meal_log_entries is
  'Canonical actual MealLog history. TNYX-194 introduces manual-mode persistence only; detailed item snapshots widen this same owner additively later.';
comment on column public.meal_log_entries.consumed_local_date is
  'Durable user-intended Diary date. Do not recompute from the device current timezone.';
comment on column public.meal_log_entries.manual_nutrition_snapshot is
  'Canonical provider-independent NutritionSnapshot JSON for manual/coarse entries.';

create index idx_meal_log_entries_user_local_date_consumed_at
  on public.meal_log_entries (user_id, consumed_local_date, consumed_at desc);

create trigger trg_meal_log_entries_updated_at
before update on public.meal_log_entries
for each row
execute function public.set_row_updated_at();

alter table public.meal_log_entries enable row level security;

-- Current projects can inherit broad public-schema grants. Reset the three API
-- roles, then grant only the DML needed by this table.
revoke all on table public.meal_log_entries
  from anon, authenticated, service_role;
grant select, insert, update, delete on table public.meal_log_entries
  to authenticated;
grant select, insert, update, delete on table public.meal_log_entries
  to service_role;

create policy meal_log_entries_select_own
  on public.meal_log_entries
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy meal_log_entries_insert_own
  on public.meal_log_entries
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy meal_log_entries_update_own
  on public.meal_log_entries
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy meal_log_entries_delete_own
  on public.meal_log_entries
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
