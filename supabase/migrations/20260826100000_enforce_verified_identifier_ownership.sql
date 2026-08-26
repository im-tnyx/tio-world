-- Enforce verified-only Email/Mobile ownership without introducing a second
-- identity-key column. Pending contacts remain non-authoritative.
--
-- Preconditions:
-- - private.canonical_email_identity(text) exists and is immutable.
-- - Supabase Auth confirmation timestamps remain the verification authority.
-- - public.users may temporarily store pending/unverified secondary contacts.

-- Fail closed if current trusted projections cannot satisfy the ownership
-- invariants. Never rewrite/delete identities to make this migration pass.
do $preflight$
begin
  if exists (
    select 1
    from public.users
    where email_verified_at is not null
      and private.canonical_email_identity(email) is null
  ) then
    raise exception
      'verified Email ownership preflight failed: canonical identity is NULL';
  end if;

  if exists (
    select 1
    from public.users
    where email_verified_at is not null
    group by private.canonical_email_identity(email)
    having count(*) > 1
  ) then
    raise exception
      'verified Email ownership preflight failed: canonical collision exists';
  end if;

  if exists (
    select 1
    from public.users
    where mobile_verified_at is not null
      and (
        mobile is null
        or mobile !~ '^\+[1-9][0-9]{7,14}$'
      )
  ) then
    raise exception
      'verified Mobile ownership preflight failed: non-canonical E.164 value exists';
  end if;

  if exists (
    select 1
    from public.users
    where mobile_verified_at is not null
    group by mobile
    having count(*) > 1
  ) then
    raise exception
      'verified Mobile ownership preflight failed: collision exists';
  end if;
end;
$preflight$;

-- Verified ownership values must always be canonical enough to participate in
-- the unique backstop. Pending/unverified values intentionally remain outside
-- these checks.
alter table public.users
  add constraint users_verified_email_canonical_check
  check (
    email_verified_at is null
    or private.canonical_email_identity(email) is not null
  ) not valid;

alter table public.users
  validate constraint users_verified_email_canonical_check;

alter table public.users
  add constraint users_verified_mobile_e164_check
  check (
    mobile_verified_at is null
    or (
      mobile is not null
      and mobile ~ '^\+[1-9][0-9]{7,14}$'
    )
  ) not valid;

alter table public.users
  validate constraint users_verified_mobile_e164_check;

-- Pending contacts do not reserve ownership. The unique key becomes active only
-- when trusted verification evidence is projected onto the row.
create unique index users_verified_email_identity_uidx
  on public.users (private.canonical_email_identity(email))
  where email_verified_at is not null;

create unique index users_verified_mobile_uidx
  on public.users (mobile)
  where mobile_verified_at is not null;

-- A verified contact cannot be replaced directly through public.users because
-- doing so would release its unique ownership while Supabase Auth could still
-- own the old verified identifier. Verified contact add/change/removal must go
-- through Supabase Auth and trusted reconciliation. Pending contacts remain
-- client-editable on the caller's own RLS-protected row.
create or replace function public.protect_user_contact_verification()
returns trigger
language plpgsql
set search_path = 'public', 'pg_temp'
as $function$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.email_verified_at := null;
      new.mobile_verified_at := null;
      return new;
    end if;

    if old.email_verified_at is not null
       and new.email is distinct from old.email
    then
      raise exception using
        errcode = '42501',
        message = 'Verified Email must be changed through Supabase Auth.';
    end if;

    if new.email is distinct from old.email then
      new.email_verified_at := null;
    elsif new.email_verified_at is distinct from old.email_verified_at then
      new.email_verified_at := old.email_verified_at;
    end if;

    if old.mobile_verified_at is not null
       and new.mobile is distinct from old.mobile
    then
      raise exception using
        errcode = '42501',
        message = 'Verified Mobile must be changed through Supabase Auth.';
    end if;

    if new.mobile is distinct from old.mobile then
      new.mobile_verified_at := null;
    elsif new.mobile_verified_at is distinct from old.mobile_verified_at then
      new.mobile_verified_at := old.mobile_verified_at;
    end if;
  end if;

  return new;
end;
$function$;

-- Reconcile only the Auth contact whose authoritative state changed. This is
-- required so an Email confirmation cannot erase a pending Mobile stored only
-- in public.users, and a Phone confirmation cannot erase a pending Email.
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
  if tg_op = 'INSERT' then
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
  end if;

  if new.email is distinct from old.email
     or new.email_confirmed_at is distinct from old.email_confirmed_at
  then
    update public.users
    set email = normalized_email,
        email_verified_at = case
          when normalized_email is not null and new.email_confirmed_at is not null
            then new.email_confirmed_at
          else null
        end,
        updated_at = timezone('utc'::text, now())
    where id = new.id;
  end if;

  if new.phone is distinct from old.phone
     or new.phone_confirmed_at is distinct from old.phone_confirmed_at
  then
    update public.users
    set mobile = normalized_phone,
        mobile_verified_at = case
          when normalized_phone is not null and new.phone_confirmed_at is not null
            then new.phone_confirmed_at
          else null
        end,
        updated_at = timezone('utc'::text, now())
    where id = new.id;
  end if;

  return new;
end;
$function$;

revoke all on function private.reconcile_tio_user_contact_verification()
  from public, anon, authenticated, service_role;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.reconcile_tio_user_contact_verification()
  to supabase_auth_admin;
