-- Keep username suggestions privacy-safe and human-readable.
-- Suggestions are seeded only by the explicit candidate supplied to the RPC.
-- No profile, provider, email, phone, DOB, year, or other identity data is read.

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
  v_reason text;
  v_base text;
  v_hash text;
  v_digits text;
  v_suffix text;
  v_candidate text;
  v_suggestions jsonb := '[]'::jsonb;
  v_attempt integer := 0;
  v_pattern integer;
begin
  if v_username is null
    or pg_catalog.length(v_username) < 3
    or pg_catalog.length(v_username) > 30
    or v_username !~ '^[a-z0-9._]+$'
  then
    return v_suggestions;
  end if;

  v_reason := private.username_unavailability_reason(v_username, p_user_id);

  -- Protected role/system handles must not generate lookalike handles inside
  -- the protected namespace. The neutral fallback is still deterministically
  -- seeded only from the candidate the user explicitly typed.
  if v_reason = 'reserved' then
    v_base := 'user';
  else
    -- Preserve ordinary user-selected dots/underscores while cleaning only
    -- repeated or edge separators so generated alternatives stay readable.
    v_base := pg_catalog.regexp_replace(v_username, '[._]{2,}', '.', 'g');
    v_base := pg_catalog.regexp_replace(v_base, '^[._]+', '');
    v_base := pg_catalog.regexp_replace(v_base, '[._]+$', '');

    -- A separator-only candidate is syntactically allowed by the legacy
    -- character policy, but it is not a useful suggestion base. Use a neutral
    -- fallback while keeping the typed candidate as the suffix seed.
    if v_base = '' then
      v_base := 'user';
    end if;
  end if;

  -- Build a bounded pool with multiple neutral shapes instead of one fixed
  -- suffix template. Every candidate is rechecked through the authoritative
  -- server policy before it is returned.
  while pg_catalog.jsonb_array_length(v_suggestions) < 5
    and v_attempt < 100
  loop
    v_attempt := v_attempt + 1;
    v_hash := pg_catalog.md5(v_username || ':' || v_attempt::text);
    v_digits := pg_catalog.translate(
      pg_catalog.substr(v_hash, 1, 8),
      'abcdef',
      '123456'
    );
    v_pattern := (v_attempt - 1) % 5;

    case v_pattern
      when 0 then
        v_suffix := pg_catalog.substr(v_digits, 1, 2);
      when 1 then
        v_suffix := '_' || pg_catalog.substr(v_digits, 1, 3);
      when 2 then
        v_suffix := '.' || pg_catalog.substr(v_digits, 2, 3);
      when 3 then
        v_suffix := pg_catalog.substr(v_digits, 1, 4);
      else
        v_suffix := '_' || pg_catalog.substr(v_digits, 3, 2);
    end case;

    v_candidate := pg_catalog.substr(
      v_base,
      1,
      30 - pg_catalog.length(v_suffix)
    ) || v_suffix;

    if v_candidate <> v_username
      and not (v_suggestions @> pg_catalog.jsonb_build_array(v_candidate))
      and private.username_unavailability_reason(v_candidate, p_user_id) is null
    then
      v_suggestions := v_suggestions || pg_catalog.jsonb_build_array(v_candidate);
    end if;
  end loop;

  return v_suggestions;
end;
$$;

revoke all on function private.username_suggestions(text, uuid) from public;
revoke all on function private.username_suggestions(text, uuid) from anon;
revoke all on function private.username_suggestions(text, uuid) from authenticated;
