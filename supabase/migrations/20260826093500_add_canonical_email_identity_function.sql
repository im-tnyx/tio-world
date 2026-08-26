-- Canonical provider-aware Email identity contract for account resolution.
--
-- This function intentionally separates a communication/display Email value
-- from the server-owned identity key used by later verified-ownership slices.
-- It does not create uniqueness, bind ownership, or imply verification.

create or replace function public.canonical_email_identity(raw_email text)
returns text
language plpgsql
immutable
strict
parallel safe
set search_path = ''
as $function$
declare
  normalized_email text := lower(btrim(raw_email));
  local_part text;
  domain_part text;
  plus_position integer;
begin
  -- This is an identity canonicalizer, not a full RFC Email validator. Fail
  -- closed for shapes that cannot represent one unambiguous address.
  if normalized_email = ''
     or normalized_email ~ '[[:space:]]'
     or length(normalized_email) - length(replace(normalized_email, '@', '')) <> 1
  then
    return null;
  end if;

  local_part := split_part(normalized_email, '@', 1);
  domain_part := split_part(normalized_email, '@', 2);

  if local_part = '' or domain_part = '' then
    return null;
  end if;

  if domain_part in ('gmail.com', 'googlemail.com') then
    plus_position := strpos(local_part, '+');
    if plus_position > 0 then
      local_part := left(local_part, plus_position - 1);
    end if;

    local_part := replace(local_part, '.', '');
    domain_part := 'gmail.com';

    if local_part = '' then
      return null;
    end if;
  end if;

  return local_part || '@' || domain_part;
end;
$function$;

comment on function public.canonical_email_identity(text) is
  'Server-owned provider-aware canonical Email identity key. Gmail/Googlemail aliases collapse; other domains retain provider-specific local-part semantics.';

-- The function lives in public so trusted server callers such as a future Edge
-- Function can consume the same database-owned contract through RPC. Normal
-- application roles must not treat it as client-authoritative identity logic.
revoke all on function public.canonical_email_identity(text)
  from public, anon, authenticated;

grant execute on function public.canonical_email_identity(text)
  to service_role, supabase_auth_admin;
