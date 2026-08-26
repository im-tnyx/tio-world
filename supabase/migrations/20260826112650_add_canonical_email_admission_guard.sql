-- Server-owned canonical Email admission primitives for #120.
--
-- This migration intentionally adds no table, column, generated identity field,
-- or persistent contact constraint. Verified ownership continues to live in the
-- existing partial UNIQUE expression index on public.users.

-- Trusted server callers need one reusable existence decision without receiving
-- a user UUID or exposing account lookup to normal clients. SECURITY DEFINER is
-- intentionally scoped to one static read-only query so supabase_auth_admin does
-- not need broad SELECT access to public.users.
create or replace function public.verified_email_owner_exists(raw_email text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  target_key text := private.canonical_email_identity(raw_email);
begin
  if target_key is null then
    return false;
  end if;

  return exists (
    select 1
    from public.users as candidate
    where candidate.email_verified_at is not null
      and private.canonical_email_identity(candidate.email) = target_key
  );
end;
$function$;

comment on function public.verified_email_owner_exists(text) is
  'Trusted server-only verified canonical Email ownership existence check. Returns no owner UUID and is not executable by normal client roles.';

revoke all on function public.verified_email_owner_exists(text)
  from public, anon, authenticated, service_role, supabase_auth_admin;

grant execute on function public.verified_email_owner_exists(text)
  to service_role, supabase_auth_admin;

-- Before User Created hook for new Google identities only.
--
-- Important enumeration boundary:
-- Email/password signup is deliberately NOT rejected here based on canonical
-- owner existence because that Email has not yet been proven and a hook error
-- would make raw account existence observable. Google reaches this hook only
-- after Supabase Auth has accepted provider identity evidence, so blocking a
-- canonical alias collision does not turn an arbitrary Email string into an
-- account-existence oracle.
create or replace function private.before_user_created_canonical_email_guard(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $function$
declare
  provider text := nullif(lower(btrim(event #>> '{user,app_metadata,provider}')), '');
  raw_email text := nullif(btrim(event #>> '{user,email}'), '');
begin
  -- Phone-first/future providers without an Email remain outside this slice.
  if provider is distinct from 'google' then
    return '{}'::jsonb;
  end if;

  if raw_email is null
     or private.canonical_email_identity(raw_email) is null
  then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 400,
        'message', 'Tio could not verify the Google email for account creation.'
      )
    );
  end if;

  if public.verified_email_owner_exists(raw_email) then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 409,
        'message', 'This verified Google email already belongs to a Tio account. Sign in to the existing account to continue.'
      )
    );
  end if;

  return '{}'::jsonb;
end;
$function$;

comment on function private.before_user_created_canonical_email_guard(jsonb) is
  'Before User Created hook guard for Google canonical Email collisions. Email/password signup is intentionally not owner-gated here to preserve enumeration safety.';

revoke all on function private.before_user_created_canonical_email_guard(jsonb)
  from public, anon, authenticated, service_role, supabase_auth_admin;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.before_user_created_canonical_email_guard(jsonb)
  to supabase_auth_admin;
