-- CI-ONLY TEST FIXTURE — DO NOT APPLY TO ANY PRODUCTION OR HOSTED PROJECT.
--
-- Not a migration: lives outside supabase/migrations and is only ever applied
-- by .github/workflows/supabase-db-tests.yml, directly via psql, against the
-- ephemeral local Postgres started by `supabase start` inside that CI job.
--
-- Purpose (TNYX-136 real-database rollback proof): raise an exception partway
-- through a public.set_active_body_goal changed-goal transition -- after the
-- previous active row has already been updated to 'superseded' but before the
-- new active row's insert commits -- so the test can prove the whole RPC
-- transaction rolls back atomically (the superseded update included) rather
-- than leaving the account with zero active goals.
--
-- The trigger only fires for one hardcoded sentinel target_weight_kg value
-- (123.45) that no other test case in run_body_goal_db_tests.sh uses, so it
-- cannot interfere with any other scenario run earlier or later in the same
-- job.

create schema if not exists test_only;

create or replace function test_only.force_insert_failure()
returns trigger
language plpgsql
as $$
begin
  if new.target_weight_kg = 123.45 then
    raise exception 'ci_test_forced_rollback: sentinel target_weight_kg reached, forcing this insert to fail';
  end if;
  return new;
end;
$$;

drop trigger if exists ci_test_force_insert_failure on public.user_body_goals;

create trigger ci_test_force_insert_failure
before insert on public.user_body_goals
for each row execute function test_only.force_insert_failure();
