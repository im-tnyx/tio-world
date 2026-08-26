-- Harden the existing Before User Created hook for Email + Password Signup.
--
-- This remains account-enumeration-safe: Email Signup is never rejected because
-- an owner exists. The hook only enforces that Gmail/Googlemail aliases arrive
-- in the same canonical form used by Tio's official client before Supabase Auth
-- decides exact-email uniqueness / obfuscated duplicate behavior.
--
-- No table, column, identity key, or persistent contact constraint is added.

create or replace function private.before_user_created_canonical_email_guard(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $function$
declare
  provider text := nullif(lower(btrim(event #>> '{user,app_metadata,provider}')), '');
  raw_email text := nullif(btrim(event #>> '{user,email}'), '');
  normalized_email text := case
    when raw_email is null then null
    else lower(raw_email)
  end;
  canonical_email text := case
    when raw_email is null then null
    else private.canonical_email_identity(raw_email)
  end;
begin
  if provider = 'email' then
    if canonical_email is null then
      return jsonb_build_object(
        'error', jsonb_build_object(
          'http_code', 400,
          'message', 'Tio could not validate this email for account creation.'
        )
      );
    end if;

    -- This decision is independent of account existence. It only closes a
    -- malicious/old-client bypass where a Gmail alias could otherwise create a
    -- second unconfirmed Auth UUID before verified ownership enforcement runs.
    if normalized_email is distinct from canonical_email then
      return jsonb_build_object(
        'error', jsonb_build_object(
          'http_code', 400,
          'message', 'Tio could not validate this email for account creation.'
        )
      );
    end if;

    return '{}'::jsonb;
  end if;

  -- Existing Google backstop: provider evidence has already verified Email
  -- ownership before the Auth user creation boundary, so canonical owner
  -- existence may safely block a second canonical UUID here.
  if provider is distinct from 'google' then
    return '{}'::jsonb;
  end if;

  if canonical_email is null then
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
  'Before User Created hook guard: Email/password enforces canonical form without owner lookup; Google blocks verified canonical Email collisions.';

revoke all on function private.before_user_created_canonical_email_guard(jsonb)
  from public, anon, authenticated, service_role, supabase_auth_admin;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.before_user_created_canonical_email_guard(jsonb)
  to supabase_auth_admin;
