create schema if not exists private;

revoke all on schema private from public;
revoke all on schema private from anon;
revoke all on schema private from authenticated;

create or replace function private.username_unavailability_reason(p_username text, p_user_id uuid)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  v_username text := pg_catalog.lower(pg_catalog.btrim(p_username));
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
  ]::text[]) then
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

create or replace function private.username_suggestions(p_username text, p_user_id uuid)
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

  v_base := pg_catalog.substr(v_username, 1, 25);

  while pg_catalog.jsonb_array_length(v_suggestions) < 3 and v_attempt < 50 loop
    v_attempt := v_attempt + 1;
    v_candidate := v_base || '.' || pg_catalog.substr(
      pg_catalog.md5(v_username || ':' || v_attempt::text), 1, 4
    );

    if private.username_unavailability_reason(v_candidate, p_user_id) is null then
      v_suggestions := v_suggestions || pg_catalog.jsonb_build_array(v_candidate);
    end if;
  end loop;

  return v_suggestions;
end;
$$;

revoke all on function private.username_unavailability_reason(text, uuid) from public;
revoke all on function private.username_unavailability_reason(text, uuid) from anon;
revoke all on function private.username_unavailability_reason(text, uuid) from authenticated;
revoke all on function private.username_suggestions(text, uuid) from public;
revoke all on function private.username_suggestions(text, uuid) from anon;
revoke all on function private.username_suggestions(text, uuid) from authenticated;

create or replace function public.check_username_availability(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_username text := pg_catalog.lower(pg_catalog.btrim(p_username));
  v_reason text;
  v_suggestions jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  v_reason := private.username_unavailability_reason(v_username, v_user_id);
  if v_reason in ('taken', 'reserved') then
    v_suggestions := private.username_suggestions(v_username, v_user_id);
  end if;

  return pg_catalog.jsonb_build_object(
    'normalized', v_username,
    'is_available', v_reason is null,
    'reason', v_reason,
    'suggestions', v_suggestions
  );
end;
$$;

create or replace function public.is_username_available(p_username text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_username text := pg_catalog.lower(pg_catalog.btrim(p_username));
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  return private.username_unavailability_reason(v_username, v_user_id) is null;
end;
$$;

create or replace function public.claim_username(p_username text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_username text := pg_catalog.lower(pg_catalog.btrim(p_username));
  v_reason text;
  v_suggestions jsonb := '[]'::jsonb;
  v_updated_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  v_reason := private.username_unavailability_reason(v_username, v_user_id);

  if v_reason is not null then
    if v_reason in ('taken', 'reserved') then
      v_suggestions := private.username_suggestions(v_username, v_user_id);
    end if;

    return pg_catalog.jsonb_build_object(
      'claimed', false,
      'normalized', v_username,
      'reason', v_reason,
      'suggestions', v_suggestions
    );
  end if;

  begin
    update public.users
    set username = v_username,
        updated_at = pg_catalog.now()
    where id = v_user_id
    returning id into v_updated_id;
  exception
    when unique_violation then
      return pg_catalog.jsonb_build_object(
        'claimed', false,
        'normalized', v_username,
        'reason', 'taken',
        'suggestions', private.username_suggestions(v_username, v_user_id)
      );
  end;

  if v_updated_id is null then
    return pg_catalog.jsonb_build_object(
      'claimed', false,
      'normalized', v_username,
      'reason', 'profile_missing',
      'suggestions', '[]'::jsonb
    );
  end if;

  return pg_catalog.jsonb_build_object(
    'claimed', true,
    'normalized', v_username,
    'reason', null,
    'suggestions', '[]'::jsonb
  );
end;
$$;

revoke all on function public.check_username_availability(text) from public;
revoke all on function public.check_username_availability(text) from anon;
grant execute on function public.check_username_availability(text) to authenticated;
revoke all on function public.is_username_available(text) from public;
revoke all on function public.is_username_available(text) from anon;
grant execute on function public.is_username_available(text) to authenticated;
revoke all on function public.claim_username(text) from public;
revoke all on function public.claim_username(text) from anon;
grant execute on function public.claim_username(text) to authenticated;

alter table public.users drop constraint if exists users_username_policy_check;
alter table public.users add constraint users_username_policy_check check (
  username is null
  or (
    username = pg_catalog.lower(username)
    and pg_catalog.length(username) between 3 and 30
    and username ~ '^[a-z0-9._]+$'
    and pg_catalog.lower(username) <> all (array[
      'admin','administrator','support','help','security','billing','official',
      'moderator','mod','root','system','staff','tio','tioworld','tioofficial'
    ]::text[])
  )
);
