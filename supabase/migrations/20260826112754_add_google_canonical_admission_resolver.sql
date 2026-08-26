-- Typed Google Login/Signup admission resolver for #120 Phase 3.
--
-- This migration adds no table, column, generated identity field, or persistent
-- contact constraint. It compares the existing verified canonical Email owner
-- with Supabase Auth's stable Google provider subject without returning UUIDs.

create or replace function public.resolve_google_login_admission(
  raw_email text,
  google_subject text
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  target_key text := private.canonical_email_identity(raw_email);
  normalized_subject text := nullif(btrim(google_subject), '');
  canonical_owner_id uuid;
  google_identity_user_id uuid;
  google_identity_has_public_root boolean := false;
begin
  if target_key is null or normalized_subject is null then
    return 'identity_conflict';
  end if;

  select candidate.id
  into canonical_owner_id
  from public.users as candidate
  where candidate.email_verified_at is not null
    and private.canonical_email_identity(candidate.email) = target_key
  limit 1;

  select identity_row.user_id
  into google_identity_user_id
  from auth.identities as identity_row
  where identity_row.provider = 'google'
    and identity_row.provider_id = normalized_subject
  limit 1;

  if google_identity_user_id is not null then
    select exists (
      select 1
      from public.users as linked_root
      where linked_root.id = google_identity_user_id
    )
    into google_identity_has_public_root;

    if not google_identity_has_public_root then
      return 'identity_conflict';
    end if;

    -- An already-linked Google subject is itself trusted sign-in authority for
    -- its existing UUID. The provider Email may legitimately change over time.
    -- Allow that same UUID when the token's current canonical Email is unowned,
    -- or when it is already owned by this UUID. Auth reconciliation + the
    -- verified-only UNIQUE index remain the final Email ownership backstop.
    if canonical_owner_id is null
       or canonical_owner_id = google_identity_user_id
    then
      return 'linked_account';
    end if;

    -- The stable Google subject is linked to one UUID while the token's current
    -- verified canonical Email is owned by another UUID. Never switch or merge.
    return 'identity_conflict';
  end if;

  if canonical_owner_id is null then
    return 'no_account';
  end if;

  -- The verified canonical Email already belongs to a Tio account, but this
  -- Google subject is not yet a sign-in method on that account. Normal Login or
  -- Signup must not turn into implicit identity linking.
  return 'link_required';
end;
$function$;

comment on function public.resolve_google_login_admission(text, text) is
  'Trusted server-only Google admission decision. Compares verified canonical Email ownership with auth.identities Google provider subject and returns linked_account, no_account, link_required, or identity_conflict without exposing UUIDs.';

revoke all on function public.resolve_google_login_admission(text, text)
  from public, anon, authenticated, service_role, supabase_auth_admin;

grant execute on function public.resolve_google_login_admission(text, text)
  to service_role;
