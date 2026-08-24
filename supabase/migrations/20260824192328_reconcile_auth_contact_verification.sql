-- Trusted Account contact projection from Supabase Auth.
-- auth.users confirmation timestamps are evidence; public.users timestamps are
-- provider-neutral application projections for the exact same contact.

create or replace function private.reconcile_tio_user_contact_verification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  normalized_email text := nullif(lower(btrim(new.email)), '');
  normalized_phone text := nullif(regexp_replace(btrim(new.phone), '\s+', '', 'g'), '');
begin
  update public.users
  set email = normalized_email,
      email_verified_at = case
        when normalized_email is not null and new.email_confirmed_at is not null
          then new.email_confirmed_at
        else null
      end,
      mobile = normalized_phone,
      mobile_verified_at = case
        when normalized_phone is not null and new.phone_confirmed_at is not null
          then new.phone_confirmed_at
        else null
      end,
      updated_at = timezone('utc'::text, now())
  where id = new.id;

  return new;
end;
$function$;

revoke all on function private.reconcile_tio_user_contact_verification()
  from public, anon, authenticated, service_role;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.reconcile_tio_user_contact_verification()
  to supabase_auth_admin;

drop trigger if exists reconcile_tio_user_contact_verification_after_auth_change
  on auth.users;

-- PostgreSQL runs same-kind triggers in name order. The existing
-- provision_tio_user_root_after_auth_insert trigger sorts before this one, so
-- a fresh public.users root exists before INSERT reconciliation executes.
create trigger reconcile_tio_user_contact_verification_after_auth_change
after insert or update of email, email_confirmed_at, phone, phone_confirmed_at
on auth.users
for each row execute function private.reconcile_tio_user_contact_verification();

-- Repair provider-neutral verification projections from trusted Auth evidence.
-- Contacts are not overwritten during backfill: only exact normalized matches
-- may become verified, and any projection without matching Auth evidence is
-- cleared.
update public.users as account
set email_verified_at = case
      when nullif(lower(btrim(account.email)), '') = nullif(lower(btrim(auth_user.email)), '')
        and auth_user.email_confirmed_at is not null
        then auth_user.email_confirmed_at
      else null
    end,
    mobile_verified_at = case
      when nullif(regexp_replace(btrim(account.mobile), '\s+', '', 'g'), '') =
           nullif(regexp_replace(btrim(auth_user.phone), '\s+', '', 'g'), '')
        and auth_user.phone_confirmed_at is not null
        then auth_user.phone_confirmed_at
      else null
    end,
    updated_at = timezone('utc'::text, now())
from auth.users as auth_user
where account.id = auth_user.id
  and (
    account.email_verified_at is distinct from case
      when nullif(lower(btrim(account.email)), '') = nullif(lower(btrim(auth_user.email)), '')
        and auth_user.email_confirmed_at is not null
        then auth_user.email_confirmed_at
      else null
    end
    or account.mobile_verified_at is distinct from case
      when nullif(regexp_replace(btrim(account.mobile), '\s+', '', 'g'), '') =
           nullif(regexp_replace(btrim(auth_user.phone), '\s+', '', 'g'), '')
        and auth_user.phone_confirmed_at is not null
        then auth_user.phone_confirmed_at
      else null
    end
  );
