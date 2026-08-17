create or replace function private.username_unavailability_reason(
  p_username text,
  p_user_id uuid
)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  v_username text := pg_catalog.lower(pg_catalog.btrim(p_username));
  v_role_pattern text := '(admin|administrator|support|help|security|billing|official|moderator|mod|root|system|staff)';
begin
  if v_username is null
    or pg_catalog.length(v_username) < 3
    or pg_catalog.length(v_username) > 30
    or v_username !~ '^[a-z0-9._]+$'
  then
    return 'invalid';
  end if;

  if v_username = any (array[
    'admin','administrator','support','help','security','billing','official',
    'moderator','mod','root','system','staff','tio','tioworld','tioofficial'
  ]::text[])
    or v_username ~ ('^' || v_role_pattern || '[._].+$')
    or v_username ~ ('^tio[._]?' || v_role_pattern || '$')
    or v_username ~ ('^' || v_role_pattern || '[._]?tio$')
  then
    return 'reserved';
  end if;

  if exists (
    select 1
    from public.users as candidate
    where pg_catalog.lower(candidate.username) = v_username
      and candidate.id <> p_user_id
  ) then
    return 'taken';
  end if;

  return null;
end;
$$;

create or replace function private.username_suggestions(
  p_username text,
  p_user_id uuid
)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_username text := pg_catalog.lower(pg_catalog.btrim(p_username));
  v_base text;
  v_candidate text;
  v_suggestions jsonb := '[]'::jsonb;
  v_attempt integer := 0;
begin
  if v_username is null
    or pg_catalog.length(v_username) < 3
    or pg_catalog.length(v_username) > 30
    or v_username !~ '^[a-z0-9._]+$'
  then
    return v_suggestions;
  end if;

  if private.username_unavailability_reason(v_username, p_user_id) = 'reserved' then
    v_base := 'user';
  else
    v_base := pg_catalog.substr(v_username, 1, 25);
  end if;

  while pg_catalog.jsonb_array_length(v_suggestions) < 3
    and v_attempt < 50
  loop
    v_attempt := v_attempt + 1;
    v_candidate := v_base || '.' || pg_catalog.substr(
      pg_catalog.md5(v_username || ':' || v_attempt::text),
      1,
      4
    );

    if private.username_unavailability_reason(v_candidate, p_user_id) is null then
      v_suggestions := v_suggestions || pg_catalog.jsonb_build_array(v_candidate);
    end if;
  end loop;

  return v_suggestions;
end;
$$;

alter table public.users
  drop constraint if exists users_username_policy_check;

alter table public.users
  add constraint users_username_policy_check
  check (
    username is null
    or (
      username = pg_catalog.lower(username)
      and pg_catalog.length(username) between 3 and 30
      and username ~ '^[a-z0-9._]+$'
      and pg_catalog.lower(username) <> all (array[
        'admin','administrator','support','help','security','billing','official',
        'moderator','mod','root','system','staff','tio','tioworld','tioofficial'
      ]::text[])
      and username !~ '^(admin|administrator|support|help|security|billing|official|moderator|mod|root|system|staff)[._].+$'
      and username !~ '^tio[._]?(admin|administrator|support|help|security|billing|official|moderator|mod|root|system|staff)$'
      and username !~ '^(admin|administrator|support|help|security|billing|official|moderator|mod|root|system|staff)[._]?tio$'
    )
  );
