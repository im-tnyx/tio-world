-- TNYX-203 / N20D-2: optimistic revision identity for manual MealLog updates.
--
-- Existing/new rows start at revision 1. Clients supply only the revision they
-- read; every successful UPDATE advances the durable revision exactly once in
-- the database. updated_at remains independent audit/presentation metadata.

do $$
begin
  if pg_catalog.to_regclass('public.meal_log_entries') is null then
    raise exception 'TNYX-203 blocked: public.meal_log_entries is missing';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'meal_log_entries'
      and column_name = 'revision'
  ) then
    raise exception 'TNYX-203 blocked: revision already exists';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and conname = 'meal_log_entries_revision_positive'
  ) then
    raise exception 'TNYX-203 blocked: revision check already exists';
  end if;

  if pg_catalog.to_regprocedure('private.bump_meal_log_revision()') is not null then
    raise exception 'TNYX-203 blocked: revision trigger function already exists';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_trigger
    where tgrelid = 'public.meal_log_entries'::pg_catalog.regclass
      and tgname = 'trg_meal_log_entries_revision'
      and not tgisinternal
  ) then
    raise exception 'TNYX-203 blocked: revision trigger already exists';
  end if;
end
$$;

alter table public.meal_log_entries
  add column revision bigint not null default 1;

alter table public.meal_log_entries
  add constraint meal_log_entries_revision_positive
  check (revision >= 1);

create function private.bump_meal_log_revision()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.revision := old.revision + 1;
  return new;
end;
$$;

revoke all on function private.bump_meal_log_revision()
  from public, anon, authenticated, service_role;

create trigger trg_meal_log_entries_revision
before update on public.meal_log_entries
for each row
execute function private.bump_meal_log_revision();

comment on column public.meal_log_entries.revision is
  'Monotonic optimistic-concurrency identity. Starts at 1 and advances exactly once on every successful row update; clients match expected revision but do not choose the next value.';
