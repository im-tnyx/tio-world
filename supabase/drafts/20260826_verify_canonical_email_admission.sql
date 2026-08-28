-- Focused read-only verification for canonical Email admission primitives.
-- Run only after 20260826104000_add_canonical_email_admission_guard.sql is
-- applied to the target environment. The script never emits Email values/UUIDs.

begin;

do $verify$
declare
  existing_verified_email text;
  google_result jsonb;
  email_result jsonb;
  phone_result jsonb;
  unknown_google_result jsonb;
  helper_is_security_definer boolean;
  hook_is_security_definer boolean;
begin
  if to_regprocedure('public.verified_email_owner_exists(text)') is null then
    raise exception 'verified Email owner lookup is missing';
  end if;

  if to_regprocedure('private.before_user_created_canonical_email_guard(jsonb)') is null then
    raise exception 'Before User Created canonical Email guard is missing';
  end if;

  if has_function_privilege(
       'anon',
       'public.verified_email_owner_exists(text)',
       'EXECUTE'
     )
  then
    raise exception 'anon must not execute verified Email owner lookup';
  end if;

  if has_function_privilege(
       'authenticated',
       'public.verified_email_owner_exists(text)',
       'EXECUTE'
     )
  then
    raise exception 'authenticated must not execute verified Email owner lookup';
  end if;

  if not has_function_privilege(
       'service_role',
       'public.verified_email_owner_exists(text)',
       'EXECUTE'
     )
  then
    raise exception 'service_role must execute verified Email owner lookup';
  end if;

  if not has_function_privilege(
       'supabase_auth_admin',
       'public.verified_email_owner_exists(text)',
       'EXECUTE'
     )
  then
    raise exception 'supabase_auth_admin must execute verified Email owner lookup';
  end if;

  if has_function_privilege(
       'authenticated',
       'private.before_user_created_canonical_email_guard(jsonb)',
       'EXECUTE'
     )
  then
    raise exception 'authenticated must not execute private Before User Created hook';
  end if;

  if not has_function_privilege(
       'supabase_auth_admin',
       'private.before_user_created_canonical_email_guard(jsonb)',
       'EXECUTE'
     )
  then
    raise exception 'supabase_auth_admin must execute private Before User Created hook';
  end if;

  select p.prosecdef
  into helper_is_security_definer
  from pg_proc as p
  where p.oid = 'public.verified_email_owner_exists(text)'::regprocedure;

  if helper_is_security_definer is distinct from true then
    raise exception 'verified Email owner lookup must keep narrow SECURITY DEFINER access';
  end if;

  select p.prosecdef
  into hook_is_security_definer
  from pg_proc as p
  where p.oid = 'private.before_user_created_canonical_email_guard(jsonb)'::regprocedure;

  if hook_is_security_definer is distinct from false then
    raise exception 'Before User Created hook itself must remain SECURITY INVOKER';
  end if;

  if public.verified_email_owner_exists('not-an-email') then
    raise exception 'malformed Email must not resolve to a verified owner';
  end if;

  if public.verified_email_owner_exists(
       'canonical-admission-no-owner@example.invalid'
     )
  then
    raise exception 'reserved no-owner fixture unexpectedly resolves to an owner';
  end if;

  unknown_google_result := private.before_user_created_canonical_email_guard(
    jsonb_build_object(
      'user', jsonb_build_object(
        'email', 'canonical-admission-no-owner@example.invalid',
        'app_metadata', jsonb_build_object('provider', 'google')
      )
    )
  );

  if unknown_google_result <> '{}'::jsonb then
    raise exception 'unowned Google Email must be allowed by the hook';
  end if;

  phone_result := private.before_user_created_canonical_email_guard(
    jsonb_build_object(
      'user', jsonb_build_object(
        'phone', '+15555550123',
        'app_metadata', jsonb_build_object('provider', 'phone')
      )
    )
  );

  if phone_result <> '{}'::jsonb then
    raise exception 'non-Google provider must remain outside this hook slice';
  end if;

  select u.email
  into existing_verified_email
  from public.users as u
  where u.email_verified_at is not null
  order by u.id
  limit 1;

  if existing_verified_email is not null then
    if not public.verified_email_owner_exists(existing_verified_email) then
      raise exception 'known verified Email must resolve to an owner';
    end if;

    google_result := private.before_user_created_canonical_email_guard(
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', existing_verified_email,
          'app_metadata', jsonb_build_object('provider', 'google')
        )
      )
    );

    if google_result #>> '{error,http_code}' <> '409' then
      raise exception 'owned Google Email must be rejected before new-user creation';
    end if;

    email_result := private.before_user_created_canonical_email_guard(
      jsonb_build_object(
        'user', jsonb_build_object(
          'email', existing_verified_email,
          'app_metadata', jsonb_build_object('provider', 'email')
        )
      )
    );

    if email_result <> '{}'::jsonb then
      raise exception 'Email/password provider must not become an account-existence oracle';
    end if;
  end if;
end;
$verify$;

rollback;
