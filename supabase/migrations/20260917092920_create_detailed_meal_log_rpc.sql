-- TNYX-218 / N20A-9: authenticated atomic create boundary for detailed MealLog.
--
-- Direct authenticated writes to meal_log_item_snapshots remain disabled. This
-- narrow SECURITY DEFINER function owns parent + ordered child creation as one
-- transaction and derives ownership exclusively from auth.uid().

create or replace function public.create_detailed_meal_log(
  p_client_mutation_id uuid,
  p_meal_category_id text,
  p_meal_name text,
  p_note text,
  p_consumed_at timestamptz,
  p_consumed_local_date date,
  p_consumed_timezone_id text,
  p_consumed_utc_offset_minutes integer,
  p_capture_source text,
  p_items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_entry_id uuid;
  v_existing public.meal_log_entries%rowtype;
  v_meal_name text := case
    when p_meal_name is null or pg_catalog.btrim(p_meal_name) = '' then null
    else p_meal_name
  end;
  v_note text := case
    when p_note is null or pg_catalog.btrim(p_note) = '' then null
    else p_note
  end;
  v_timezone_id text := case
    when p_consumed_timezone_id is null
      or pg_catalog.btrim(p_consumed_timezone_id) = '' then null
    else p_consumed_timezone_id
  end;
  v_normalized_items jsonb := '[]'::jsonb;
  v_existing_items jsonb;
  v_item jsonb;
  v_ordinality bigint;
  v_brand_name text;
  v_quantity numeric;
begin
  if v_user_id is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_client_mutation_id is null then
    raise exception 'client_mutation_id_required' using errcode = '22023';
  end if;

  if p_meal_category_id is null
      or p_meal_category_id = ''
      or pg_catalog.btrim(p_meal_category_id) <> p_meal_category_id then
    raise exception 'invalid_meal_category_id' using errcode = '22023';
  end if;

  if p_consumed_at is null or p_consumed_local_date is null then
    raise exception 'consumed_time_required' using errcode = '22023';
  end if;

  if v_timezone_id is null and p_consumed_utc_offset_minutes is null then
    raise exception 'consumed_time_context_required' using errcode = '22023';
  end if;

  if p_items is null
      or pg_catalog.jsonb_typeof(p_items) <> 'array'
      or pg_catalog.jsonb_array_length(p_items) < 1 then
    raise exception 'detailed_items_required' using errcode = '22023';
  end if;

  for v_item, v_ordinality in
    select item.value, item.ordinality
    from pg_catalog.jsonb_array_elements(p_items)
      with ordinality as item(value, ordinality)
  loop
    if pg_catalog.jsonb_typeof(v_item) <> 'object'
        or pg_catalog.jsonb_typeof(v_item -> 'display_name') <> 'string'
        or pg_catalog.btrim(v_item ->> 'display_name') = ''
        or (
          v_item ? 'brand_name'
          and v_item -> 'brand_name' <> 'null'::jsonb
          and pg_catalog.jsonb_typeof(v_item -> 'brand_name') <> 'string'
        )
        or pg_catalog.jsonb_typeof(v_item -> 'quantity') <> 'number'
        or pg_catalog.jsonb_typeof(v_item -> 'serving_unit') <> 'string'
        or pg_catalog.btrim(v_item ->> 'serving_unit') = ''
        or pg_catalog.jsonb_typeof(v_item -> 'nutrition_snapshot') <> 'object' then
      raise exception 'invalid_detailed_item' using errcode = '22023';
    end if;

    v_quantity := (v_item ->> 'quantity')::numeric;
    if v_quantity <= 0 or v_quantity >= 'Infinity'::numeric then
      raise exception 'invalid_detailed_item_quantity' using errcode = '22023';
    end if;

    if not private.is_valid_nutrition_snapshot_v1(
      v_item -> 'nutrition_snapshot'
    ) then
      raise exception 'invalid_detailed_item_nutrition' using errcode = '22023';
    end if;

    v_brand_name := case
      when not (v_item ? 'brand_name')
        or v_item -> 'brand_name' = 'null'::jsonb
        or pg_catalog.btrim(v_item ->> 'brand_name') = '' then null
      else v_item ->> 'brand_name'
    end;

    v_normalized_items := v_normalized_items || pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object(
        'display_name', v_item ->> 'display_name',
        'brand_name', v_brand_name,
        'quantity', v_quantity,
        'serving_unit', v_item ->> 'serving_unit',
        'nutrition_snapshot', v_item -> 'nutrition_snapshot'
      )
    );
  end loop;

  insert into public.meal_log_entries (
    user_id,
    mode,
    meal_category_id,
    meal_name,
    note,
    consumed_at,
    consumed_local_date,
    consumed_timezone_id,
    consumed_utc_offset_minutes,
    capture_source,
    manual_nutrition_snapshot,
    client_mutation_id
  ) values (
    v_user_id,
    'detailed',
    p_meal_category_id,
    v_meal_name,
    v_note,
    p_consumed_at,
    p_consumed_local_date,
    v_timezone_id,
    p_consumed_utc_offset_minutes,
    p_capture_source,
    null,
    p_client_mutation_id
  )
  on conflict (user_id, client_mutation_id) do nothing
  returning id into v_entry_id;

  if v_entry_id is not null then
    insert into public.meal_log_item_snapshots (
      meal_log_entry_id,
      position,
      display_name,
      brand_name,
      quantity,
      serving_unit,
      nutrition_snapshot
    )
    select
      v_entry_id,
      item.ordinality - 1,
      item.value ->> 'display_name',
      case
        when item.value -> 'brand_name' = 'null'::jsonb then null
        else item.value ->> 'brand_name'
      end,
      (item.value ->> 'quantity')::numeric,
      item.value ->> 'serving_unit',
      item.value -> 'nutrition_snapshot'
    from pg_catalog.jsonb_array_elements(v_normalized_items)
      with ordinality as item(value, ordinality);

    return v_entry_id;
  end if;

  select entry.*
  into v_existing
  from public.meal_log_entries as entry
  where entry.user_id = v_user_id
    and entry.client_mutation_id = p_client_mutation_id;

  if not found then
    raise exception 'meal_log_create_outcome_unknown' using errcode = 'P0002';
  end if;

  select coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'display_name', item.display_name,
        'brand_name', item.brand_name,
        'quantity', item.quantity,
        'serving_unit', item.serving_unit,
        'nutrition_snapshot', item.nutrition_snapshot
      ) order by item.position
    ),
    '[]'::jsonb
  )
  into v_existing_items
  from public.meal_log_item_snapshots as item
  where item.meal_log_entry_id = v_existing.id;

  if v_existing.mode <> 'detailed'
      or v_existing.revision <> 1
      or v_existing.meal_category_id <> p_meal_category_id
      or v_existing.meal_name is distinct from v_meal_name
      or v_existing.note is distinct from v_note
      or v_existing.consumed_at <> p_consumed_at
      or v_existing.consumed_local_date <> p_consumed_local_date
      or v_existing.consumed_timezone_id is distinct from v_timezone_id
      or v_existing.consumed_utc_offset_minutes is distinct from p_consumed_utc_offset_minutes
      or v_existing.capture_source is distinct from p_capture_source
      or v_existing.manual_nutrition_snapshot is not null
      or v_existing_items <> v_normalized_items then
    raise exception 'meal_log_create_mutation_conflict' using errcode = 'P0001';
  end if;

  return v_existing.id;
end;
$$;

revoke all on function public.create_detailed_meal_log(
  uuid, text, text, text, timestamptz, date, text, integer, text, jsonb
) from public, anon, authenticated, service_role;

grant execute on function public.create_detailed_meal_log(
  uuid, text, text, text, timestamptz, date, text, integer, text, jsonb
) to authenticated;

comment on function public.create_detailed_meal_log(
  uuid, text, text, text, timestamptz, date, text, integer, text, jsonb
) is
  'TNYX-218 atomic authenticated detailed MealLog create. Caller identity comes from auth.uid(); durable parent/item IDs remain database-owned; same client mutation identity reconciles only when parent and ordered item facts match exactly.';
