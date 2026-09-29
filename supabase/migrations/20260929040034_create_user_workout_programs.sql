-- ============================================================================
-- Migration: create_user_workout_programs
--
-- Minimal durable persistence for user-owned Workout Programs.
-- Authoritative Tio/Coach source Programs, Routine composition, provenance,
-- media and TrainingPlan scheduling are intentionally outside this slice.
-- ============================================================================

create table public.user_workout_programs (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_workout_programs_name_nonblank check (btrim(name) <> '')
);

create index idx_user_workout_programs_user_created_at
  on public.user_workout_programs (user_id, created_at desc);

create trigger trg_user_workout_programs_updated_at
before update on public.user_workout_programs
for each row execute function public.set_row_updated_at();

alter table public.user_workout_programs enable row level security;

revoke all on table public.user_workout_programs from anon;
revoke all on table public.user_workout_programs from authenticated;
grant select, insert, update, delete on table public.user_workout_programs to authenticated;
grant select, insert, update, delete on table public.user_workout_programs to service_role;

create policy user_workout_programs_select_own
on public.user_workout_programs
for select to authenticated
using ((select auth.uid()) = user_id);

create policy user_workout_programs_insert_own
on public.user_workout_programs
for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy user_workout_programs_update_own
on public.user_workout_programs
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy user_workout_programs_delete_own
on public.user_workout_programs
for delete to authenticated
using ((select auth.uid()) = user_id);
