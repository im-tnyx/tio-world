-- ============================================================================
-- Migration: create_user_workout_exercises
--
-- Minimal durable persistence for user-owned canonical Exercises.
-- Bundled catalog Exercises remain application-owned content and are not
-- mirrored into Postgres. Favorites, Folders, Routine composition, media and
-- richer Exercise definition fields remain separate approved slices.
-- ============================================================================

create table public.user_workout_exercises (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  display_name text not null,
  status text not null default 'active',
  based_on_catalog_exercise_id text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_workout_exercises_id_user_id_key unique (id, user_id),
  constraint user_workout_exercises_display_name_nonblank
    check (btrim(display_name) <> ''),
  constraint user_workout_exercises_status_check
    check (status in ('active', 'archived')),
  constraint user_workout_exercises_catalog_lineage_format_check
    check (
      based_on_catalog_exercise_id is null
      or based_on_catalog_exercise_id ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'
    )
);

create index idx_user_workout_exercises_user_status_created_at
  on public.user_workout_exercises (user_id, status, created_at desc);

create trigger trg_user_workout_exercises_updated_at
before update on public.user_workout_exercises
for each row execute function public.set_row_updated_at();

alter table public.user_workout_exercises enable row level security;

revoke all on table public.user_workout_exercises from anon;
revoke all on table public.user_workout_exercises from authenticated;

grant select on table public.user_workout_exercises to authenticated;
grant insert (
  id,
  user_id,
  display_name,
  based_on_catalog_exercise_id
) on public.user_workout_exercises to authenticated;
grant update (
  display_name,
  status
) on public.user_workout_exercises to authenticated;

grant select, insert, update, delete
on table public.user_workout_exercises
to service_role;

create policy user_workout_exercises_select_own
on public.user_workout_exercises
for select to authenticated
using ((select auth.uid()) = user_id);

create policy user_workout_exercises_insert_own
on public.user_workout_exercises
for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy user_workout_exercises_update_own
on public.user_workout_exercises
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
