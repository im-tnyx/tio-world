-- ============================================================================
-- Migration: create_user_workout_routines
--
-- Minimal durable persistence for user-owned Routines nested under a
-- user-owned Program. Composition, ordering and source provenance are deferred.
-- ============================================================================

alter table public.user_workout_programs
  add constraint user_workout_programs_id_user_id_key unique (id, user_id);

create table public.user_workout_routines (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  program_id uuid not null,
  name text not null,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_workout_routines_name_nonblank check (btrim(name) <> ''),
  constraint user_workout_routines_program_owner_fkey
    foreign key (program_id, user_id)
    references public.user_workout_programs(id, user_id)
    on delete cascade
);

create index idx_user_workout_routines_user_program_created_at
  on public.user_workout_routines (user_id, program_id, created_at desc);

create trigger trg_user_workout_routines_updated_at
before update on public.user_workout_routines
for each row execute function public.set_row_updated_at();

alter table public.user_workout_routines enable row level security;

revoke all on table public.user_workout_routines from anon;
revoke all on table public.user_workout_routines from authenticated;
grant select, insert, update, delete on table public.user_workout_routines to authenticated;
grant select, insert, update, delete on table public.user_workout_routines to service_role;

create policy user_workout_routines_select_own
on public.user_workout_routines
for select to authenticated
using ((select auth.uid()) = user_id);

create policy user_workout_routines_insert_own
on public.user_workout_routines
for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy user_workout_routines_update_own
on public.user_workout_routines
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy user_workout_routines_delete_own
on public.user_workout_routines
for delete to authenticated
using ((select auth.uid()) = user_id);
