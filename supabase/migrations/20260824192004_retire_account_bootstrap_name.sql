-- Post-O11 ownership hardening: canonical editable Name belongs only to
-- public.user_profiles.name. public.users remains the Account/domain root.

create or replace function private.provision_tio_user_root()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  normalized_email text := nullif(lower(btrim(new.email)), '');
begin
  insert into public.users (
    id,
    email,
    created_at,
    updated_at
  )
  values (
    new.id,
    normalized_email,
    coalesce(new.created_at, timezone('utc'::text, now())),
    timezone('utc'::text, now())
  )
  on conflict (id) do nothing;

  return new;
end;
$function$;

-- Keep the privileged trigger helper internal to Supabase Auth.
revoke all on function private.provision_tio_user_root()
  from public, anon, authenticated, service_role;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.provision_tio_user_root()
  to supabase_auth_admin;

-- No CASCADE: dependency audit must stay clean and any unexpected dependency
-- must fail this migration rather than being removed implicitly.
alter table public.users drop column name;
