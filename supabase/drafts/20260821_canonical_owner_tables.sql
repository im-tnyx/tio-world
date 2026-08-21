-- DRAFT ONLY — DO NOT APPLY YET
-- Canonical owner migration design for Issue #44.
-- This file intentionally lives under supabase/drafts/, not supabase/migrations/.
-- After review, move an approved version into a forward-only migration.
--
-- Goals:
--   * one canonical durable owner per concept;
--   * public.users is the application/domain user root;
--   * Supabase Auth/RLS is the current access layer, not the domain FK boundary;
--   * additive first migration; no legacy columns are dropped here;
--   * future protected backend reads/writes the same tables.

begin;

-- ---------------------------------------------------------------------------
-- Shared updated_at trigger helper.
-- SECURITY INVOKER is the default; no SECURITY DEFINER is required.
-- ---------------------------------------------------------------------------
create or replace function public.set_row_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 1. Body weight history
-- ---------------------------------------------------------------------------
create table public.body_weight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  weight_kg numeric not null,
  measured_at timestamptz not null default timezone('utc'::text, now()),
  source text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc'::text, now()),
  constraint body_weight_logs_weight_positive
    check (weight_kg > 0),
  constraint body_weight_logs_metadata_object
    check (jsonb_typeof(metadata) = 'object')
);

create index idx_body_weight_logs_user_measured_at
  on public.body_weight_logs (user_id, measured_at desc);

alter table public.body_weight_logs enable row level security;

grant select, insert, update, delete on table public.body_weight_logs to authenticated;
grant select, insert, update, delete on table public.body_weight_logs to service_role;

create policy body_weight_logs_select_own
  on public.body_weight_logs
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy body_weight_logs_insert_own
  on public.body_weight_logs
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy body_weight_logs_update_own
  on public.body_weight_logs
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy body_weight_logs_delete_own
  on public.body_weight_logs
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- 2. Body goal plans
-- ---------------------------------------------------------------------------
create table public.user_body_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  goal_type text not null,
  starting_weight_kg numeric,
  target_weight_kg numeric,
  weekly_weight_change_kg numeric,
  intent_rank smallint,
  status text not null default 'active',
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_body_goals_type_check
    check (goal_type in ('lose_weight', 'gain_weight', 'maintain_weight', 'recomposition')),
  constraint user_body_goals_starting_weight_positive
    check (starting_weight_kg is null or starting_weight_kg > 0),
  constraint user_body_goals_target_weight_positive
    check (target_weight_kg is null or target_weight_kg > 0),
  constraint user_body_goals_weekly_change_nonnegative
    check (weekly_weight_change_kg is null or weekly_weight_change_kg >= 0),
  constraint user_body_goals_intent_rank_check
    check (intent_rank is null or intent_rank in (1, 2)),
  constraint user_body_goals_status_check
    check (status in ('active', 'completed', 'cancelled', 'superseded')),
  constraint user_body_goals_end_after_start
    check (ended_at is null or started_at is null or ended_at >= started_at)
);

create index idx_user_body_goals_user_created_at
  on public.user_body_goals (user_id, created_at desc);

create unique index uq_user_body_goals_one_active
  on public.user_body_goals (user_id)
  where status = 'active';

create trigger trg_user_body_goals_updated_at
before update on public.user_body_goals
for each row execute function public.set_row_updated_at();

alter table public.user_body_goals enable row level security;

grant select, insert, update, delete on table public.user_body_goals to authenticated;
grant select, insert, update, delete on table public.user_body_goals to service_role;

create policy user_body_goals_select_own
  on public.user_body_goals
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy user_body_goals_insert_own
  on public.user_body_goals
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy user_body_goals_update_own
  on public.user_body_goals
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy user_body_goals_delete_own
  on public.user_body_goals
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- 3. Common Wellness targets
-- ---------------------------------------------------------------------------
create table public.user_wellness_targets (
  user_id uuid primary key references public.users(id) on delete cascade,
  steps_target integer,
  water_target_ml integer,
  sleep_target_minutes integer,
  bed_time time,
  wake_up_time time,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_wellness_targets_steps_nonnegative
    check (steps_target is null or steps_target >= 0),
  constraint user_wellness_targets_water_nonnegative
    check (water_target_ml is null or water_target_ml >= 0),
  constraint user_wellness_targets_sleep_nonnegative
    check (sleep_target_minutes is null or sleep_target_minutes >= 0)
);

create trigger trg_user_wellness_targets_updated_at
before update on public.user_wellness_targets
for each row execute function public.set_row_updated_at();

alter table public.user_wellness_targets enable row level security;

grant select, insert, update, delete on table public.user_wellness_targets to authenticated;
grant select, insert, update, delete on table public.user_wellness_targets to service_role;

create policy user_wellness_targets_select_own
  on public.user_wellness_targets
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy user_wellness_targets_insert_own
  on public.user_wellness_targets
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy user_wellness_targets_update_own
  on public.user_wellness_targets
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy user_wellness_targets_delete_own
  on public.user_wellness_targets
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- 4. Numeric Nutrition targets
-- ---------------------------------------------------------------------------
create table public.user_nutrition_targets (
  user_id uuid primary key references public.users(id) on delete cascade,
  calories_kcal integer,
  protein_grams numeric,
  carbohydrate_grams numeric,
  fat_grams numeric,
  fiber_grams numeric,
  customization_state text not null default 'unknown',
  customized_fields text[] not null default '{}'::text[],
  recommendation_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_nutrition_targets_calories_positive
    check (calories_kcal is null or calories_kcal > 0),
  constraint user_nutrition_targets_protein_nonnegative
    check (protein_grams is null or protein_grams >= 0),
  constraint user_nutrition_targets_carbs_nonnegative
    check (carbohydrate_grams is null or carbohydrate_grams >= 0),
  constraint user_nutrition_targets_fat_nonnegative
    check (fat_grams is null or fat_grams >= 0),
  constraint user_nutrition_targets_fiber_nonnegative
    check (fiber_grams is null or fiber_grams >= 0),
  constraint user_nutrition_targets_customization_state_check
    check (customization_state in ('unknown', 'recommended', 'custom', 'mixed')),
  constraint user_nutrition_targets_metadata_object
    check (jsonb_typeof(recommendation_metadata) = 'object')
);

create trigger trg_user_nutrition_targets_updated_at
before update on public.user_nutrition_targets
for each row execute function public.set_row_updated_at();

alter table public.user_nutrition_targets enable row level security;

grant select, insert, update, delete on table public.user_nutrition_targets to authenticated;
grant select, insert, update, delete on table public.user_nutrition_targets to service_role;

create policy user_nutrition_targets_select_own
  on public.user_nutrition_targets
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy user_nutrition_targets_insert_own
  on public.user_nutrition_targets
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy user_nutrition_targets_update_own
  on public.user_nutrition_targets
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy user_nutrition_targets_delete_own
  on public.user_nutrition_targets
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- 5. Workout goals + plan constraints
-- Body Goal values are deliberately NOT mirrored here.
-- Overall unified-goal order can be preserved with *_goal_rank where known.
-- ---------------------------------------------------------------------------
create table public.user_workout_targets (
  user_id uuid primary key references public.users(id) on delete cascade,
  primary_workout_goal text,
  primary_goal_rank smallint,
  supporting_workout_goal text,
  supporting_goal_rank smallint,
  training_days text[] not null default '{}'::text[],
  preferred_duration_mins integer,
  split_program text,
  special_event text,
  special_event_date date,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_workout_targets_primary_goal_check
    check (
      primary_workout_goal is null or
      primary_workout_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
    ),
  constraint user_workout_targets_supporting_goal_check
    check (
      supporting_workout_goal is null or
      supporting_workout_goal in ('build_muscle', 'get_stronger', 'improve_endurance', 'stay_fit')
    ),
  constraint user_workout_targets_primary_rank_check
    check (primary_goal_rank is null or primary_goal_rank in (1, 2)),
  constraint user_workout_targets_supporting_rank_check
    check (supporting_goal_rank is null or supporting_goal_rank in (1, 2)),
  constraint user_workout_targets_distinct_goals
    check (
      supporting_workout_goal is null or
      primary_workout_goal is null or
      supporting_workout_goal <> primary_workout_goal
    ),
  constraint user_workout_targets_support_requires_primary
    check (supporting_workout_goal is null or primary_workout_goal is not null),
  constraint user_workout_targets_distinct_known_ranks
    check (
      primary_goal_rank is null or
      supporting_goal_rank is null or
      primary_goal_rank <> supporting_goal_rank
    ),
  constraint user_workout_targets_duration_positive
    check (preferred_duration_mins is null or preferred_duration_mins > 0)
);

create trigger trg_user_workout_targets_updated_at
before update on public.user_workout_targets
for each row execute function public.set_row_updated_at();

alter table public.user_workout_targets enable row level security;

grant select, insert, update, delete on table public.user_workout_targets to authenticated;
grant select, insert, update, delete on table public.user_workout_targets to service_role;

create policy user_workout_targets_select_own
  on public.user_workout_targets
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy user_workout_targets_insert_own
  on public.user_workout_targets
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy user_workout_targets_update_own
  on public.user_workout_targets
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy user_workout_targets_delete_own
  on public.user_workout_targets
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

commit;
