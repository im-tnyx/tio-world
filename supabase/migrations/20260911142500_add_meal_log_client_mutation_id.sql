-- TNYX-196 / N20D-1: durable idempotency identity for manual MealLog create.
--
-- Existing history remains compatible because client_mutation_id is nullable.
-- New create flows use one stable UUID per logical create operation and the
-- owner-scoped unique constraint is the final concurrent duplicate guard.

do $$
begin
  if pg_catalog.to_regclass('public.meal_log_entries') is null then
    raise exception 'TNYX-196 blocked: public.meal_log_entries is missing';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'meal_log_entries'
      and column_name = 'client_mutation_id'
  ) then
    raise exception 'TNYX-196 blocked: client_mutation_id already exists';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_user_client_mutation_id_key'
  ) then
    raise exception 'TNYX-196 blocked: mutation unique constraint already exists';
  end if;
end
$$;

alter table public.meal_log_entries
  add column client_mutation_id uuid;

alter table public.meal_log_entries
  add constraint meal_log_entries_user_client_mutation_id_key
  unique (user_id, client_mutation_id);

comment on column public.meal_log_entries.client_mutation_id is
  'Stable client identity for one logical MealLog create operation. Retries reuse this UUID; it is distinct from the durable MealLog row id.';
