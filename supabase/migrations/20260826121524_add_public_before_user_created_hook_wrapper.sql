-- Expose a dashboard-selectable Auth Hook entrypoint without moving business
-- logic out of the private schema.
--
-- Supabase Studio currently does not list the existing private hook function in
-- the hosted Before User Created function picker for this project. This public
-- wrapper is intentionally a thin SECURITY INVOKER boundary and delegates all
-- policy decisions to the existing private implementation.
--
-- No table, column, user data, or ownership semantics are changed.

create or replace function public.before_user_created_canonical_email_guard(event jsonb)
returns jsonb
language sql
stable
set search_path = ''
as $function$
  select private.before_user_created_canonical_email_guard(event);
$function$;

comment on function public.before_user_created_canonical_email_guard(jsonb) is
  'Dashboard-selectable Before User Created Auth Hook wrapper. Delegates to private.before_user_created_canonical_email_guard(jsonb).';

revoke all on function public.before_user_created_canonical_email_guard(jsonb)
  from public, anon, authenticated, service_role, supabase_auth_admin;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.before_user_created_canonical_email_guard(jsonb)
  to supabase_auth_admin;
