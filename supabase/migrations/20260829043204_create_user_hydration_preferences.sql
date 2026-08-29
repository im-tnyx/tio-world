create table public.user_hydration_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  default_glass_size_ml integer,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_hydration_preferences_glass_size_check check (
    default_glass_size_ml is null or (
      default_glass_size_ml between 50 and 2000
      and default_glass_size_ml % 10 = 0
    )
  )
);

create trigger trg_user_hydration_preferences_updated_at
before update on public.user_hydration_preferences
for each row execute function public.set_row_updated_at();

alter table public.user_hydration_preferences enable row level security;
revoke all on table public.user_hydration_preferences from public, anon, authenticated;
grant select, insert, update on table public.user_hydration_preferences to authenticated;
grant select, insert, update, delete on table public.user_hydration_preferences to service_role;

create policy user_hydration_preferences_select_own
on public.user_hydration_preferences for select to authenticated
using ((select auth.uid()) = user_id);

create policy user_hydration_preferences_insert_own
on public.user_hydration_preferences for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy user_hydration_preferences_update_own
on public.user_hydration_preferences for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

comment on table public.user_hydration_preferences is
  'Settings-owned account-synced hydration preferences; no hydration logs or Water Goal.';
comment on column public.user_hydration_preferences.default_glass_size_ml is
  'Future +1 glass amount in integer ml. NULL means Not set; independent of display units and daily Water Goal.';
