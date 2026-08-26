-- Read-only verification for #120 Phase 3 Google canonical admission resolver.
-- Run only after the resolver migration exists on the target database.
-- This script performs no DML and does not print user identifiers.

do $verification$
declare
  fixture_user_id uuid;
  fixture_email text;
  fixture_google_subject text;
  second_fixture_email text;
  no_owner_email text := 'tio-google-admission-' || md5(clock_timestamp()::text) || '@example.invalid';
  no_owner_subject text := 'tio-google-admission-' || md5(random()::text);
  actual text;
begin
  select u.id, u.email, i.provider_id
  into fixture_user_id, fixture_email, fixture_google_subject
  from public.users as u
  join auth.identities as i
    on i.user_id = u.id
   and i.provider = 'google'
  where u.email_verified_at is not null
    and private.canonical_email_identity(u.email) is not null
  limit 1;

  if fixture_user_id is null
     or fixture_email is null
     or fixture_google_subject is null
  then
    raise exception 'Google admission verification requires an existing verified Google fixture.';
  end if;

  select u.email
  into second_fixture_email
  from public.users as u
  join auth.identities as i
    on i.user_id = u.id
   and i.provider = 'google'
  where u.id <> fixture_user_id
    and u.email_verified_at is not null
    and private.canonical_email_identity(u.email) is not null
  limit 1;

  if second_fixture_email is null then
    raise exception 'Google admission conflict verification requires a second verified Google fixture.';
  end if;

  actual := public.resolve_google_login_admission(
    fixture_email,
    fixture_google_subject
  );
  if actual <> 'linked_account' then
    raise exception 'Expected linked_account, got %', actual;
  end if;

  -- The stable linked Google subject remains sign-in authority when the
  -- provider's current verified Email has changed to a canonical Email that is
  -- not owned by another Tio account.
  actual := public.resolve_google_login_admission(
    no_owner_email,
    fixture_google_subject
  );
  if actual <> 'linked_account' then
    raise exception 'Expected linked_account for linked subject with unowned current Email, got %', actual;
  end if;

  actual := public.resolve_google_login_admission(
    fixture_email,
    no_owner_subject
  );
  if actual <> 'link_required' then
    raise exception 'Expected link_required, got %', actual;
  end if;

  actual := public.resolve_google_login_admission(
    no_owner_email,
    no_owner_subject
  );
  if actual <> 'no_account' then
    raise exception 'Expected no_account, got %', actual;
  end if;

  actual := public.resolve_google_login_admission(
    second_fixture_email,
    fixture_google_subject
  );
  if actual <> 'identity_conflict' then
    raise exception 'Expected identity_conflict, got %', actual;
  end if;

  if has_function_privilege(
    'anon',
    'public.resolve_google_login_admission(text,text)',
    'EXECUTE'
  ) then
    raise exception 'anon must not execute Google admission resolver.';
  end if;

  if has_function_privilege(
    'authenticated',
    'public.resolve_google_login_admission(text,text)',
    'EXECUTE'
  ) then
    raise exception 'authenticated must not execute Google admission resolver.';
  end if;

  if not has_function_privilege(
    'service_role',
    'public.resolve_google_login_admission(text,text)',
    'EXECUTE'
  ) then
    raise exception 'service_role must execute Google admission resolver.';
  end if;
end;
$verification$;

select jsonb_build_object(
  'resolver_exists', to_regprocedure(
    'public.resolve_google_login_admission(text,text)'
  ) is not null,
  'normal_client_execute_revoked',
    not has_function_privilege(
      'anon',
      'public.resolve_google_login_admission(text,text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'authenticated',
      'public.resolve_google_login_admission(text,text)',
      'EXECUTE'
    ),
  'service_role_execute', has_function_privilege(
    'service_role',
    'public.resolve_google_login_admission(text,text)',
    'EXECUTE'
  )
) as verification;
