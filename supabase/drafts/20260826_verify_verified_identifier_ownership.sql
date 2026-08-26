-- Disposable/dev verification for verified-only identifier ownership.
--
-- Run only after:
--   20260826093500_add_canonical_email_identity_function.sql
--   20260826100000_enforce_verified_identifier_ownership.sql
--
-- This script creates a transient test table inside a transaction and rolls the
-- transaction back. It does not mutate public.users or auth.users.

begin;

create table public._tio_verified_identifier_test (
  id uuid primary key,
  email text,
  email_verified_at timestamptz,
  mobile text,
  mobile_verified_at timestamptz
);

grant select, insert, update, delete
  on public._tio_verified_identifier_test
  to authenticated;

create unique index _tio_verified_email_identity_uidx
  on public._tio_verified_identifier_test (
    private.canonical_email_identity(email)
  )
  where email_verified_at is not null;

create unique index _tio_verified_mobile_uidx
  on public._tio_verified_identifier_test (mobile)
  where mobile_verified_at is not null;

create trigger _tio_protect_contact_verification
before insert or update of email, email_verified_at, mobile, mobile_verified_at
on public._tio_verified_identifier_test
for each row execute function public.protect_user_contact_verification();

-- PostgreSQL must be able to maintain the expression index during authenticated
-- DML. Pending aliases are intentionally allowed because they do not own the
-- identifier yet.
set local role authenticated;

insert into public._tio_verified_identifier_test (id, email)
values
  ('00000000-0000-0000-0000-000000000101', 'na.me+one@gmail.com'),
  ('00000000-0000-0000-0000-000000000102', 'name+two@googlemail.com');

insert into public._tio_verified_identifier_test (id, mobile)
values
  ('00000000-0000-0000-0000-000000000103', '+919123456789'),
  ('00000000-0000-0000-0000-000000000104', '+919123456789');

reset role;

-- Seed trusted verified owners as a privileged server/database path would.
insert into public._tio_verified_identifier_test (
  id,
  email,
  email_verified_at,
  mobile,
  mobile_verified_at
)
values (
  '00000000-0000-0000-0000-000000000105',
  'name@gmail.com',
  timezone('utc'::text, now()),
  '+919999999999',
  timezone('utc'::text, now())
);

-- A second verified Gmail alias and second verified Mobile must not insert.
with attempted as (
  insert into public._tio_verified_identifier_test (
    id,
    email,
    email_verified_at
  )
  values (
    '00000000-0000-0000-0000-000000000106',
    'n.a.m.e+blocked@googlemail.com',
    timezone('utc'::text, now())
  )
  on conflict do nothing
  returning id
)
select case when count(*) = 0 then 1 else 1 / 0 end
from attempted;

with attempted as (
  insert into public._tio_verified_identifier_test (
    id,
    mobile,
    mobile_verified_at
  )
  values (
    '00000000-0000-0000-0000-000000000107',
    '+919999999999',
    timezone('utc'::text, now())
  )
  on conflict do nothing
  returning id
)
select case when count(*) = 0 then 1 else 1 / 0 end
from attempted;

-- A pending contact may overlap a verified owner because pending contact is not
-- ownership authority.
set local role authenticated;
insert into public._tio_verified_identifier_test (id, email, mobile)
values (
  '00000000-0000-0000-0000-000000000108',
  'n.a.m.e+pending@gmail.com',
  '+919999999999'
);
reset role;

-- Direct client mutation of a trusted verified contact must fail rather than
-- releasing ownership while Auth still owns the old identifier.
do $guard_test$
begin
  begin
    set local role authenticated;
    update public._tio_verified_identifier_test
    set email = 'attacker@example.com'
    where id = '00000000-0000-0000-0000-000000000105';
    reset role;
    raise exception 'verified Email direct-mutation guard did not fire';
  exception
    when insufficient_privilege then
      reset role;
  end;

  begin
    set local role authenticated;
    update public._tio_verified_identifier_test
    set mobile = '+918888888888'
    where id = '00000000-0000-0000-0000-000000000105';
    reset role;
    raise exception 'verified Mobile direct-mutation guard did not fire';
  exception
    when insufficient_privilege then
      reset role;
  end;
end;
$guard_test$;

-- Pending values remain editable and must stay unverified.
set local role authenticated;
update public._tio_verified_identifier_test
set email = 'other.pending@example.com',
    mobile = '+917777777777'
where id = '00000000-0000-0000-0000-000000000108';
reset role;

do $assertions$
begin
  if exists (
    select 1
    from public._tio_verified_identifier_test
    where id = '00000000-0000-0000-0000-000000000108'
      and (email_verified_at is not null or mobile_verified_at is not null)
  ) then
    raise exception 'pending contact unexpectedly became verified';
  end if;

  if (select count(*) from public._tio_verified_identifier_test where email_verified_at is not null) <> 1 then
    raise exception 'verified Email uniqueness assertion failed';
  end if;

  if (select count(*) from public._tio_verified_identifier_test where mobile_verified_at is not null) <> 1 then
    raise exception 'verified Mobile uniqueness assertion failed';
  end if;
end;
$assertions$;

rollback;
