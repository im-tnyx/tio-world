-- TNYX-81 / workout Superset composition.
-- Routine composition remains one owner-scoped transaction. Legacy array
-- writers continue to work for ungrouped Routines and fail closed for grouped
-- Routines rather than silently deleting group configuration.

create table public.user_workout_routine_supersets (
  id uuid primary key,
  user_id uuid not null,
  routine_id uuid not null,
  normal_rest_seconds integer,
  warm_up_rest_seconds integer,
  constraint user_workout_routine_supersets_owner_fkey
    foreign key (routine_id, user_id)
    references public.user_workout_routines(id, user_id) on delete cascade,
  constraint user_workout_routine_supersets_id_owner_routine_key
    unique (id, user_id, routine_id),
  constraint user_workout_routine_supersets_normal_rest_valid
    check (normal_rest_seconds is null or (
      normal_rest_seconds between 5 and 600
      and normal_rest_seconds % 5 = 0
    )),
  constraint user_workout_routine_supersets_warm_up_rest_valid
    check (warm_up_rest_seconds is null or (
      warm_up_rest_seconds between 5 and 600
      and warm_up_rest_seconds % 5 = 0
    ))
);

alter table public.user_workout_routine_exercises
  add column superset_id uuid;

alter table public.user_workout_routine_exercises
  add constraint user_workout_routine_exercises_superset_owner_fkey
  foreign key (superset_id, user_id, routine_id)
  references public.user_workout_routine_supersets(id, user_id, routine_id)
  on delete no action deferrable initially deferred;

alter table public.user_workout_routine_supersets enable row level security;
revoke all on public.user_workout_routine_supersets
  from public, anon, authenticated, service_role;
grant select on public.user_workout_routine_supersets to authenticated;
create policy user_workout_routine_supersets_select_own
  on public.user_workout_routine_supersets
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Keep the reviewed full validator intact as a private implementation detail.
-- This compatibility wrapper prevents an older array client from replacing
-- a grouped Routine without carrying the Superset metadata.
alter function public.save_user_workout_routine_composition(
  uuid, bigint, uuid, jsonb
) rename to save_user_workout_routine_composition_legacy;

revoke all on function public.save_user_workout_routine_composition_legacy(
  uuid, bigint, uuid, jsonb
) from public, anon, authenticated, service_role;

create function private.is_valid_routine_superset_rest_value(p_value jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_text text;
  v_seconds integer;
begin
  if p_value is null then
    return false;
  end if;
  if pg_catalog.jsonb_typeof(p_value) = 'null' then
    return true;
  end if;
  if pg_catalog.jsonb_typeof(p_value) <> 'number' then
    return false;
  end if;
  v_text := p_value #>> '{}';
  if v_text !~ '^[0-9]+$' then
    return false;
  end if;
  v_seconds := v_text::integer;
  return v_seconds between 5 and 600 and v_seconds % 5 = 0;
exception when others then
  return false;
end;
$$;

revoke all on function private.is_valid_routine_superset_rest_value(jsonb)
  from public, anon, authenticated, service_role;

create function private.validate_user_workout_routine_superset_payload(
  p_composition jsonb
)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_entry jsonb;
  v_group jsonb;
  v_group_id text;
  v_count bigint;
  v_first bigint;
  v_last bigint;
begin
  if p_composition is null
      or pg_catalog.jsonb_typeof(p_composition) <> 'object'
      or p_composition - 'schema_version' - 'entries' - 'supersets' <> '{}'::jsonb
      or pg_catalog.jsonb_typeof(p_composition -> 'schema_version') <> 'number'
      or p_composition ->> 'schema_version' is distinct from '2'
      or pg_catalog.jsonb_typeof(p_composition -> 'entries') <> 'array'
      or pg_catalog.jsonb_typeof(p_composition -> 'supersets') <> 'array'
      or pg_catalog.octet_length(p_composition::text) > 262144 then
    raise exception 'invalid_routine_superset_composition'
      using errcode = '22023';
  end if;

  for v_entry in
    select e.value
    from pg_catalog.jsonb_array_elements(p_composition -> 'entries') as e(value)
  loop
    if pg_catalog.jsonb_typeof(v_entry) <> 'object'
        or (v_entry ? 'superset_id'
            and pg_catalog.jsonb_typeof(v_entry -> 'superset_id')
              not in ('null', 'string'))
        or (v_entry ->> 'superset_id') is not null
          and (v_entry ->> 'superset_id') !~*
            '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'invalid_routine_superset_member'
        using errcode = '22023';
    end if;
  end loop;

  if exists (
    select 1
    from pg_catalog.jsonb_array_elements(p_composition -> 'supersets') as g(value)
    where pg_catalog.jsonb_typeof(g.value) <> 'object'
       or g.value - 'id' - 'normal_rest_seconds' - 'warm_up_rest_seconds'
          <> '{}'::jsonb
       or pg_catalog.jsonb_typeof(g.value -> 'id') <> 'string'
       or (g.value ->> 'id') !~*
          '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or not (g.value ? 'normal_rest_seconds')
       or not (g.value ? 'warm_up_rest_seconds')
       or not private.is_valid_routine_superset_rest_value(
         g.value -> 'normal_rest_seconds'
       )
       or not private.is_valid_routine_superset_rest_value(
         g.value -> 'warm_up_rest_seconds'
       )
  ) then
    raise exception 'invalid_routine_superset_group'
      using errcode = '22023';
  end if;

  if exists (
    select lower(g.value ->> 'id')
    from pg_catalog.jsonb_array_elements(p_composition -> 'supersets') as g(value)
    group by lower(g.value ->> 'id')
    having count(*) > 1
  ) then
    raise exception 'duplicate_routine_superset_id' using errcode = '22023';
  end if;

  if exists (
    select 1
    from pg_catalog.jsonb_array_elements(p_composition -> 'entries') as e(value)
    where e.value ->> 'superset_id' is not null
      and not exists (
        select 1
        from pg_catalog.jsonb_array_elements(p_composition -> 'supersets') as g(value)
        where lower(g.value ->> 'id') = lower(e.value ->> 'superset_id')
      )
  ) then
    raise exception 'routine_superset_group_not_found' using errcode = '22023';
  end if;

  for v_group in
    select g.value
    from pg_catalog.jsonb_array_elements(p_composition -> 'supersets') as g(value)
  loop
    v_group_id := lower(v_group ->> 'id');
    select count(*), min(e.ordinality), max(e.ordinality)
      into v_count, v_first, v_last
    from pg_catalog.jsonb_array_elements(p_composition -> 'entries')
      with ordinality as e(value, ordinality)
    where lower(e.value ->> 'superset_id') = v_group_id;
    if v_count < 2 or v_count > 3 or v_last - v_first + 1 <> v_count then
      raise exception 'invalid_routine_superset_membership'
        using errcode = '22023';
    end if;
  end loop;

  select coalesce(pg_catalog.jsonb_agg(e.value - 'superset_id'
      order by e.ordinality), '[]'::jsonb)
    into v_entry
  from pg_catalog.jsonb_array_elements(p_composition -> 'entries')
    with ordinality as e(value, ordinality);
  return v_entry;
end;
$$;

revoke all on function private.validate_user_workout_routine_superset_payload(jsonb)
  from public, anon, authenticated, service_role;

create function private.routine_superset_payload_matches(
  p_routine_id uuid,
  p_user_id uuid,
  p_composition jsonb
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with requested as (
    select coalesce(pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', lower(g.value ->> 'id'),
        'normal_rest_seconds', g.value -> 'normal_rest_seconds',
        'warm_up_rest_seconds', g.value -> 'warm_up_rest_seconds',
        'members', (
          select coalesce(pg_catalog.jsonb_agg(
            lower(e.value ->> 'id') order by e.ordinality
          ), '[]'::jsonb)
          from pg_catalog.jsonb_array_elements(p_composition -> 'entries')
            with ordinality as e(value, ordinality)
          where lower(e.value ->> 'superset_id') = lower(g.value ->> 'id')
        )
      ) order by lower(g.value ->> 'id')
    ), '[]'::jsonb) as payload
    from pg_catalog.jsonb_array_elements(p_composition -> 'supersets') as g(value)
  ), persisted as (
    select coalesce(pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', lower(group_row.id::text),
        'normal_rest_seconds', group_row.normal_rest_seconds,
        'warm_up_rest_seconds', group_row.warm_up_rest_seconds,
        'members', (
          select coalesce(pg_catalog.jsonb_agg(
            lower(entry.id::text) order by entry.position
          ), '[]'::jsonb)
          from public.user_workout_routine_exercises as entry
          where entry.user_id = p_user_id
            and entry.routine_id = p_routine_id
            and entry.superset_id = group_row.id
        )
      ) order by lower(group_row.id::text)
    ), '[]'::jsonb) as payload
    from public.user_workout_routine_supersets as group_row
    where group_row.user_id = p_user_id
      and group_row.routine_id = p_routine_id
  )
  select requested.payload = persisted.payload from requested, persisted;
$$;

revoke all on function private.routine_superset_payload_matches(uuid, uuid, jsonb)
  from public, anon, authenticated, service_role;

create function private.clear_user_workout_routine_supersets(
  p_routine_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.user_workout_routine_exercises
  set superset_id = null
  where routine_id = p_routine_id and user_id = p_user_id;
  delete from public.user_workout_routine_supersets
  where routine_id = p_routine_id and user_id = p_user_id;
end;
$$;

revoke all on function private.clear_user_workout_routine_supersets(uuid, uuid)
  from public, anon, authenticated, service_role;

create function private.apply_user_workout_routine_supersets(
  p_routine_id uuid,
  p_user_id uuid,
  p_composition jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_group jsonb;
begin
  perform private.clear_user_workout_routine_supersets(p_routine_id, p_user_id);

  for v_group in
    select g.value
    from pg_catalog.jsonb_array_elements(p_composition -> 'supersets') as g(value)
  loop
    insert into public.user_workout_routine_supersets (
      id, user_id, routine_id, normal_rest_seconds, warm_up_rest_seconds
    ) values (
      (v_group ->> 'id')::uuid,
      p_user_id,
      p_routine_id,
      (v_group ->> 'normal_rest_seconds')::integer,
      (v_group ->> 'warm_up_rest_seconds')::integer
    );
  end loop;

  update public.user_workout_routine_exercises as entry
  set superset_id = nullif(payload.value ->> 'superset_id', '')::uuid
  from pg_catalog.jsonb_array_elements(p_composition -> 'entries') as payload(value)
  where entry.id = (payload.value ->> 'id')::uuid
    and entry.user_id = p_user_id
    and entry.routine_id = p_routine_id;
end;
$$;

revoke all on function private.apply_user_workout_routine_supersets(uuid, uuid, jsonb)
  from public, anon, authenticated, service_role;

-- Retain the old four-argument signature for deployed clients, with the new
-- guard ahead of the full replacement. The former reviewed validator remains
-- unchanged under its private implementation name.
create function public.save_user_workout_routine_composition(
  p_routine_id uuid,
  p_expected_revision bigint,
  p_client_mutation_id uuid,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.user_workout_routine_supersets as group_row
    where group_row.routine_id = p_routine_id
      and group_row.user_id = auth.uid()
  ) then
    raise exception 'routine_composition_legacy_superset_overwrite'
      using errcode = 'P0001';
  end if;
  return public.save_user_workout_routine_composition_legacy(
    p_routine_id, p_expected_revision, p_client_mutation_id, p_exercises
  );
end;
$$;

revoke all on function public.save_user_workout_routine_composition(
  uuid, bigint, uuid, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.save_user_workout_routine_composition(
  uuid, bigint, uuid, jsonb
) to authenticated;

-- The legacy Update RPC can reach its former Save function by an internal
-- reference, so guard the public Update boundary as well as the Save RPC.
alter function public.update_user_workout_routine_with_composition(
  uuid, uuid, bigint, text, uuid, text, jsonb
) rename to update_user_workout_routine_with_composition_legacy;

revoke all on function public.update_user_workout_routine_with_composition_legacy(
  uuid, uuid, bigint, text, uuid, text, jsonb
) from public, anon, authenticated, service_role;

create function public.update_user_workout_routine_with_composition(
  p_routine_id uuid,
  p_program_id uuid,
  p_expected_revision bigint,
  p_expected_name text,
  p_client_mutation_id uuid,
  p_name text,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_exercises is not null and exists (
    select 1
    from public.user_workout_routine_supersets as group_row
    where group_row.routine_id = p_routine_id
      and group_row.user_id = auth.uid()
  ) then
    raise exception 'routine_composition_legacy_superset_overwrite'
      using errcode = 'P0001';
  end if;
  return public.update_user_workout_routine_with_composition_legacy(
    p_routine_id, p_program_id, p_expected_revision, p_expected_name,
    p_client_mutation_id, p_name, p_exercises
  );
end;
$$;

revoke all on function public.update_user_workout_routine_with_composition(
  uuid, uuid, bigint, text, uuid, text, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.update_user_workout_routine_with_composition(
  uuid, uuid, bigint, text, uuid, text, jsonb
) to authenticated;

create function public.save_user_workout_routine_composition_v2(
  p_routine_id uuid,
  p_expected_revision bigint,
  p_client_mutation_id uuid,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_revision bigint;
  v_last_mutation uuid;
  v_entries jsonb;
begin
  if v_user_id is null then
    raise exception 'routine_composition_not_authenticated' using errcode = '28000';
  end if;
  if p_routine_id is null or p_client_mutation_id is null
      or p_expected_revision is null or p_expected_revision < 0 then
    raise exception 'invalid_routine_composition_request' using errcode = '22023';
  end if;
  v_entries := private.validate_user_workout_routine_superset_payload(p_exercises);

  select routine.composition_revision, routine.last_composition_mutation_id
    into v_revision, v_last_mutation
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;
  if not found then
    raise exception 'routine_composition_not_found' using errcode = 'P0002';
  end if;

  if v_last_mutation = p_client_mutation_id
      and not private.routine_superset_payload_matches(
        p_routine_id, v_user_id, p_exercises
      ) then
    raise exception 'routine_composition_mutation_conflict' using errcode = 'P0001';
  end if;

  v_revision := public.save_user_workout_routine_composition_legacy(
    p_routine_id, p_expected_revision, p_client_mutation_id, v_entries
  );
  perform private.apply_user_workout_routine_supersets(
    p_routine_id, v_user_id, p_exercises
  );
  return v_revision;
end;
$$;

revoke all on function public.save_user_workout_routine_composition_v2(
  uuid, bigint, uuid, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.save_user_workout_routine_composition_v2(
  uuid, bigint, uuid, jsonb
) to authenticated;

create function public.update_user_workout_routine_with_composition_v2(
  p_routine_id uuid,
  p_program_id uuid,
  p_expected_revision bigint,
  p_expected_name text,
  p_client_mutation_id uuid,
  p_name text,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_last_mutation uuid;
  v_entries jsonb;
  v_revision bigint;
begin
  if p_exercises is null then
    return public.update_user_workout_routine_with_composition(
      p_routine_id, p_program_id, p_expected_revision, p_expected_name,
      p_client_mutation_id, p_name, null
    );
  end if;
  if v_user_id is null then
    raise exception 'routine_update_not_authenticated' using errcode = '28000';
  end if;
  v_entries := private.validate_user_workout_routine_superset_payload(p_exercises);

  select routine.last_composition_mutation_id
    into v_last_mutation
  from public.user_workout_routines as routine
  where routine.id = p_routine_id
    and routine.program_id = p_program_id
    and routine.user_id = v_user_id
  for update;
  if not found then
    raise exception 'routine_update_not_found' using errcode = 'P0002';
  end if;
  if v_last_mutation = p_client_mutation_id
      and not private.routine_superset_payload_matches(
        p_routine_id, v_user_id, p_exercises
      ) then
    raise exception 'routine_update_mutation_conflict' using errcode = 'P0001';
  end if;

  perform private.clear_user_workout_routine_supersets(p_routine_id, v_user_id);
  v_revision := public.update_user_workout_routine_with_composition(
    p_routine_id, p_program_id, p_expected_revision, p_expected_name,
    p_client_mutation_id, p_name, v_entries
  );
  perform private.apply_user_workout_routine_supersets(
    p_routine_id, v_user_id, p_exercises
  );
  return v_revision;
end;
$$;

revoke all on function public.update_user_workout_routine_with_composition_v2(
  uuid, uuid, bigint, text, uuid, text, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.update_user_workout_routine_with_composition_v2(
  uuid, uuid, bigint, text, uuid, text, jsonb
) to authenticated;

create function public.create_user_workout_routine_with_composition_v2(
  p_routine_id uuid,
  p_program_id uuid,
  p_name text,
  p_client_mutation_id uuid,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing boolean;
  v_entries jsonb;
  v_revision bigint;
begin
  if p_routine_id is null then
    raise exception 'invalid_routine_create_request' using errcode = '22023';
  end if;
  v_entries := private.validate_user_workout_routine_superset_payload(p_exercises);
  if v_user_id is null then
    raise exception 'routine_create_not_authenticated' using errcode = '28000';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('routine-create:' || p_routine_id::text, 0)
  );
  select exists (
    select 1 from public.user_workout_routines as routine
    where routine.id = p_routine_id and routine.user_id = v_user_id
  ) into v_existing;
  if v_existing then
    if not private.routine_superset_payload_matches(
      p_routine_id, v_user_id, p_exercises
    ) then
      raise exception 'routine_create_identity_conflict' using errcode = 'P0001';
    end if;
    perform private.clear_user_workout_routine_supersets(p_routine_id, v_user_id);
  end if;

  v_revision := public.create_user_workout_routine_with_composition(
    p_routine_id, p_program_id, p_name, p_client_mutation_id, v_entries
  );
  perform private.apply_user_workout_routine_supersets(
    p_routine_id, v_user_id, p_exercises
  );
  return v_revision;
end;
$$;

revoke all on function public.create_user_workout_routine_with_composition_v2(
  uuid, uuid, text, uuid, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.create_user_workout_routine_with_composition_v2(
  uuid, uuid, text, uuid, jsonb
) to authenticated;

create function public.create_user_workout_routine_in_my_program_v2(
  p_routine_id uuid,
  p_name text,
  p_client_mutation_id uuid,
  p_exercises jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing boolean;
  v_entries jsonb;
  v_receipt jsonb;
begin
  if p_routine_id is null then
    raise exception 'invalid_routine_create_request' using errcode = '22023';
  end if;
  v_entries := private.validate_user_workout_routine_superset_payload(p_exercises);
  if v_user_id is null then
    raise exception 'routine_create_not_authenticated' using errcode = '28000';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('routine-create:' || p_routine_id::text, 0)
  );
  select exists (
    select 1 from public.user_workout_routines as routine
    where routine.id = p_routine_id and routine.user_id = v_user_id
  ) into v_existing;
  if v_existing then
    if not private.routine_superset_payload_matches(
      p_routine_id, v_user_id, p_exercises
    ) then
      raise exception 'routine_create_identity_conflict' using errcode = 'P0001';
    end if;
    perform private.clear_user_workout_routine_supersets(p_routine_id, v_user_id);
  end if;

  v_receipt := public.create_user_workout_routine_in_my_program(
    p_routine_id, p_name, p_client_mutation_id, v_entries
  );
  perform private.apply_user_workout_routine_supersets(
    p_routine_id, v_user_id, p_exercises
  );
  return v_receipt;
end;
$$;

revoke all on function public.create_user_workout_routine_in_my_program_v2(
  uuid, text, uuid, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.create_user_workout_routine_in_my_program_v2(
  uuid, text, uuid, jsonb
) to authenticated;

comment on function public.save_user_workout_routine_composition_v2(
  uuid, bigint, uuid, jsonb
) is 'Owner-scoped versioned atomic Routine composition writer with Superset groups and legacy overwrite protection.';
