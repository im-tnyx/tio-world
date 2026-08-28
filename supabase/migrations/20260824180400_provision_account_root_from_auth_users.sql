-- P0 production hardening: make public.users root provisioning database-owned.
--
-- Account/Profile ownership remains intentionally split:
--   public.users         -> account/domain root + contacts/status/bootstrap
--   public.user_profiles -> canonical user-entered Profile fields including Name
--
-- The bootstrap name here is not canonical Profile Name. It only satisfies the
-- existing Account/bootstrap contract until Product Onboarding persists
-- public.user_profiles.name.

create or replace function private.provision_tio_user_root()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  normalized_email text := nullif(lower(btrim(new.email)), '');
  bootstrap_name text;
begin
  bootstrap_name := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
    case
      when normalized_email is not null and position('@' in normalized_email) > 1
        then split_part(normalized_email, '@', 1)
      else null
    end,
    'Tio User'
  );

  insert into public.users (
    id,
    name,
    email,
    created_at,
    updated_at
  )
  values (
    new.id,
    bootstrap_name,
    normalized_email,
    coalesce(new.created_at, timezone('utc'::text, now())),
    timezone('utc'::text, now())
  )
  on conflict (id) do nothing;

  return new;
end;
$function$;

-- Trigger execution is internal to Supabase Auth. Do not expose the privileged
-- function as a client-callable RPC.
revoke all on function private.provision_tio_user_root()
  from public, anon, authenticated;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.provision_tio_user_root()
  to supabase_auth_admin;

drop trigger if exists provision_tio_user_root_after_auth_insert on auth.users;

create trigger provision_tio_user_root_after_auth_insert
after insert on auth.users
for each row execute function private.provision_tio_user_root();

-- Repair any historical Auth identities that were created before the trigger.
-- This is deliberately insert-only and conflict-safe: existing Account-owned
-- fields are never overwritten by the backfill.
insert into public.users (
  id,
  name,
  email,
  created_at,
  updated_at
)
select
  auth_user.id,
  coalesce(
    nullif(btrim(auth_user.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(auth_user.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(auth_user.raw_user_meta_data ->> 'name'), ''),
    case
      when nullif(lower(btrim(auth_user.email)), '') is not null
        and position('@' in lower(btrim(auth_user.email))) > 1
        then split_part(lower(btrim(auth_user.email)), '@', 1)
      else null
    end,
    'Tio User'
  ) as name,
  nullif(lower(btrim(auth_user.email)), '') as email,
  coalesce(auth_user.created_at, timezone('utc'::text, now())) as created_at,
  timezone('utc'::text, now()) as updated_at
from auth.users as auth_user
left join public.users as account_root
  on account_root.id = auth_user.id
where account_root.id is null
on conflict (id) do nothing;
