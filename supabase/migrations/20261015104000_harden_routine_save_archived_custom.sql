-- #534: atomic Routine Save vs archived Custom row, with historical
-- entries retainable only while entry reference and ordered Set data match.
-- Requires #536/#540 migrations. Reuses existing RPC signature and grants.
-- Preserve security-definer signature, owner locks, mutation revisions/grants.
create or replace function public.save_user_workout_routine_composition(
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
  v_entry jsonb;
  v_set jsonb;
  v_entry_ordinal bigint;
  v_set_ordinal bigint;
  v_entry_id uuid;
  v_set_id uuid;
  v_entry_ref text;
  v_catalog_id text;
  v_user_exercise_id uuid;
  v_reps integer;
  v_load double precision;
  v_distance double precision;
  v_duration integer;
  v_rest integer;
  v_set_type text;
  v_reps_max integer;
  v_entry_range boolean;
  v_normalized jsonb;
  v_persisted jsonb;
  v_custom_status text;
  v_original_exists boolean;
  v_original_sets jsonb;
begin
  if v_user_id is null then
    raise exception 'routine_composition_not_authenticated' using errcode = '28000';
  end if;
  if p_routine_id is null or p_client_mutation_id is null
      or p_expected_revision is null or p_expected_revision < 0
      or p_exercises is null
      or pg_catalog.jsonb_typeof(p_exercises) <> 'array' then
    raise exception 'invalid_routine_composition_request' using errcode = '22023';
  end if;

  -- Technical payload-size cap (256 KiB), not a user-visible Exercise limit.
  if pg_catalog.octet_length(p_exercises::text) > 262144 then
    raise exception 'routine_composition_payload_too_large' using errcode = '22023';
  end if;

  -- Check ownership before spending CPU on parsing untrusted nested contents.
  -- Lock serializes concurrent editor writes and retries for this Routine.
  select routine.composition_revision, routine.last_composition_mutation_id
    into v_revision, v_last_mutation
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;

  if not found then
    raise exception 'routine_composition_not_found' using errcode = 'P0002';
  end if;

  for v_entry, v_entry_ordinal in
    select e.value, e.ordinality
    from pg_catalog.jsonb_array_elements(p_exercises)
      with ordinality as e(value, ordinality)
  loop
    if pg_catalog.jsonb_typeof(v_entry) <> 'object'
        or v_entry - 'id' - 'exercise_ref' - 'sets' <> '{}'::jsonb
        or pg_catalog.jsonb_typeof(v_entry -> 'id') is distinct from 'string'
        or pg_catalog.jsonb_typeof(v_entry -> 'exercise_ref') is distinct from 'string'
        or pg_catalog.jsonb_typeof(v_entry -> 'sets') is distinct from 'array'
        or (v_entry ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'invalid_routine_exercise_entry' using errcode = '22023';
    end if;

    v_entry_id := (v_entry ->> 'id')::uuid;

    v_entry_ref := v_entry ->> 'exercise_ref';
    v_catalog_id := null;
    v_user_exercise_id := null;
    if v_entry_ref ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$' then
      v_catalog_id := v_entry_ref;
    elsif v_entry_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      v_user_exercise_id := v_entry_ref::uuid;
      -- Owner lookup rejects cross-user or missing User Exercises equally.
      -- The deferred owner FK remains a transactional race safeguard.
      if not exists (
        select 1 from public.user_workout_exercises as owned_exercise
        where owned_exercise.id = v_user_exercise_id
          and owned_exercise.user_id = v_user_id
      ) then
        raise exception 'routine_composition_exercise_not_found'
          using errcode = 'P0002';
      end if;
    else
      raise exception 'invalid_routine_exercise_ref' using errcode = '22023';
    end if;

    v_entry_range := null;
    for v_set, v_set_ordinal in
      select s.value, s.ordinality
      from pg_catalog.jsonb_array_elements(v_entry -> 'sets')
        with ordinality as s(value, ordinality)
    loop
      if pg_catalog.jsonb_typeof(v_set) <> 'object'
          or v_set - 'id' - 'reps' - 'load_kg' - 'rest_seconds' - 'set_type' - 'reps_max' - 'distance_meters' - 'duration_seconds' <> '{}'::jsonb
          or pg_catalog.jsonb_typeof(v_set -> 'id') is distinct from 'string'
          or (v_set ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          or not (v_set ? 'reps') then
        raise exception 'invalid_routine_set' using errcode = '22023';
      end if;
      v_set_id := (v_set ->> 'id')::uuid;
      v_reps := null;
      if pg_catalog.jsonb_typeof(v_set -> 'reps') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'reps') <> 'number'
            or (v_set ->> 'reps') !~ '^[0-9]+$' then
          raise exception 'invalid_routine_set_reps' using errcode = '22023';
        end if;
        v_reps := (v_set ->> 'reps')::integer;
        if v_reps <= 0 then
          raise exception 'invalid_routine_set_reps' using errcode = '22023';
        end if;
      end if;

      -- Missing new fields mean an old fixed/Normal Set.
      if v_set ? 'set_type' and
          pg_catalog.jsonb_typeof(v_set -> 'set_type') <> 'string' then
        raise exception 'invalid_routine_set_type' using errcode = '22023';
      end if;
      v_set_type := coalesce(v_set ->> 'set_type','normal');
      if v_set_type not in ('normal','warm_up','failure','drop') then
        raise exception 'invalid_routine_set_type' using errcode = '22023';
      end if;
      v_reps_max := null;
      if v_set ? 'reps_max' and
          pg_catalog.jsonb_typeof(v_set -> 'reps_max') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'reps_max') <> 'number'
            or (v_set ->> 'reps_max') !~ '^[0-9]+$' then
          raise exception 'invalid_routine_set_reps_max' using errcode = '22023';
        end if;
        v_reps_max := (v_set ->> 'reps_max')::integer;
        if v_reps is null or v_reps_max < v_reps then
          raise exception 'invalid_routine_set_reps_max' using errcode = '22023';
        end if;
      end if;

      if v_entry_range is null then
        v_entry_range := v_reps_max is not null;
      elsif v_entry_range is distinct from (v_reps_max is not null) then
        raise exception 'mixed_routine_exercise_repetition_modes'
          using errcode = '22023';
      end if;

      v_load := null;
      if v_set ? 'load_kg'
          and pg_catalog.jsonb_typeof(v_set -> 'load_kg') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'load_kg') <> 'number' then
          raise exception 'invalid_routine_set_load' using errcode = '22023';
        end if;
        v_load := (v_set ->> 'load_kg')::double precision;
        if v_load < 0 or v_load >= 'Infinity'::double precision
            or v_load = 'NaN'::double precision then
          raise exception 'invalid_routine_set_load' using errcode = '22023';
        end if;
      end if;

      v_distance := null;
      if v_set ? 'distance_meters' and
          pg_catalog.jsonb_typeof(v_set -> 'distance_meters') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'distance_meters') <> 'number' then
          raise exception 'invalid_routine_set_distance' using errcode = '22023';
        end if;
        v_distance := (v_set ->> 'distance_meters')::double precision;
        if v_distance < 0 or v_distance >= 'Infinity'::double precision
            or v_distance = 'NaN'::double precision then
          raise exception 'invalid_routine_set_distance' using errcode = '22023';
        end if;
      end if;

      v_duration := null;
      if v_set ? 'duration_seconds' and
          pg_catalog.jsonb_typeof(v_set -> 'duration_seconds') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'duration_seconds') <> 'number'
            or (v_set ->> 'duration_seconds') !~ '^[0-9]+$' then
          raise exception 'invalid_routine_set_duration' using errcode = '22023';
        end if;
        v_duration := (v_set ->> 'duration_seconds')::integer;
      end if;

      v_rest := null;
      if v_set ? 'rest_seconds'
          and pg_catalog.jsonb_typeof(v_set -> 'rest_seconds') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'rest_seconds') <> 'number'
            or (v_set ->> 'rest_seconds') !~ '^[0-9]+$' then
          raise exception 'invalid_routine_set_rest' using errcode = '22023';
        end if;
        v_rest := (v_set ->> 'rest_seconds')::integer;
      end if;

    end loop;
  end loop;

  -- Detect UUID-equivalent duplicate IDs without quadratic array scans.
  if exists (
    select 1 from pg_catalog.jsonb_array_elements(p_exercises) as e(value)
    group by (e.value ->> 'id')::uuid having count(*) > 1
  ) then
    raise exception 'duplicate_routine_exercise_entry' using errcode = '22023';
  end if;

  if exists (
    select 1
    from pg_catalog.jsonb_array_elements(p_exercises) as e(value)
    cross join lateral pg_catalog.jsonb_array_elements(e.value -> 'sets') as s(value)
    group by (s.value ->> 'id')::uuid having count(*) > 1
  ) then
    raise exception 'duplicate_routine_set' using errcode = '22023';
  end if;

  -- Build ordered normalized content in single aggregations, not per-item
  -- jsonb concatenations. Strict validation above makes all casts safe.
  select coalesce(pg_catalog.jsonb_agg(
    pg_catalog.jsonb_build_object(
      'id', (e.value ->> 'id')::uuid::text,
      'exercise_ref', case
        when (e.value ->> 'exercise_ref') ~ '^ex_'
          then e.value ->> 'exercise_ref'
        else (e.value ->> 'exercise_ref')::uuid::text
      end,
      'sets', (
        select coalesce(pg_catalog.jsonb_agg(
          pg_catalog.jsonb_build_object(
            'id', (s.value ->> 'id')::uuid::text,
            'reps', (s.value ->> 'reps')::integer,
            'set_type', coalesce(s.value ->> 'set_type','normal'),
            'reps_max', (s.value ->> 'reps_max')::integer,
            'load_kg', (s.value ->> 'load_kg')::double precision,
            'distance_meters', (s.value ->> 'distance_meters')::double precision,
            'duration_seconds', (s.value ->> 'duration_seconds')::integer,
            'rest_seconds', (s.value ->> 'rest_seconds')::integer
          ) order by s.ordinality
        ), '[]'::jsonb)
        from pg_catalog.jsonb_array_elements(e.value -> 'sets')
          with ordinality as s(value, ordinality)
      )
    ) order by e.ordinality
  ), '[]'::jsonb)
    into v_normalized
  from pg_catalog.jsonb_array_elements(p_exercises)
    with ordinality as e(value, ordinality);

  if v_last_mutation = p_client_mutation_id then
    select coalesce(pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', exercise.id::text,
        'exercise_ref', coalesce(
          exercise.catalog_exercise_id, exercise.user_exercise_id::text
        ),
        'sets', (
          select coalesce(pg_catalog.jsonb_agg(
            pg_catalog.jsonb_build_object(
              'id', set_row.id::text,
              'reps', set_row.reps,
              'set_type', set_row.set_type,
              'reps_max', set_row.reps_max,
              'load_kg', set_row.load_kg,
              'distance_meters', set_row.distance_meters,
              'duration_seconds', set_row.duration_seconds,
              'rest_seconds', set_row.rest_seconds
            ) order by set_row.position
          ), '[]'::jsonb)
          from public.user_workout_routine_sets as set_row
          where set_row.user_id = v_user_id
            and set_row.routine_exercise_id = exercise.id
        )
      ) order by exercise.position
    ), '[]'::jsonb)
    into v_persisted
    from public.user_workout_routine_exercises as exercise
    where exercise.routine_id = p_routine_id
      and exercise.user_id = v_user_id;

    if v_persisted = v_normalized then
      return v_revision;
    end if;
    raise exception 'routine_composition_mutation_conflict' using errcode = 'P0001';
  end if;

  -- Legacy full-snapshot clients must not erase rich Set type/range,
  -- targetless Reps or distance/duration values. Even an empty replacement
  -- of a rich Routine is fail-closed.
  if exists (
    select 1 from public.user_workout_routine_sets old_set
    join public.user_workout_routine_exercises old_entry
      on old_entry.id = old_set.routine_exercise_id
      and old_entry.user_id = old_set.user_id
    where old_entry.routine_id = p_routine_id
      and old_entry.user_id = v_user_id
      and (old_set.set_type <> 'normal'
        or old_set.reps_max is not null
        or old_set.reps is null
        or old_set.distance_meters is not null
        or old_set.duration_seconds is not null)
  ) and (
    not exists (
      select 1 from pg_catalog.jsonb_array_elements(p_exercises) e(value)
      cross join lateral pg_catalog.jsonb_array_elements(e.value -> 'sets') s(value)
    )
    or exists (
      select 1 from pg_catalog.jsonb_array_elements(p_exercises) e(value)
      cross join lateral pg_catalog.jsonb_array_elements(e.value -> 'sets') s(value)
      where not (s.value ? 'set_type' and s.value ? 'reps_max'
                 and s.value ? 'distance_meters'
                 and s.value ? 'duration_seconds')
    )
  ) then
    raise exception 'routine_composition_legacy_rich_set_overwrite'
      using errcode = 'P0001';
  end if;

  if v_revision <> p_expected_revision then
    raise exception 'routine_composition_revision_conflict' using errcode = 'P0001';
  end if;

  -- #534: lock each distinct Custom row before any child DML, serializing
  -- this new mutation with the authenticated owner's archive UPDATE.
  -- Keep this AFTER same-token replay, legacy overwrite and revision gates.
  -- Consistent UUID lock ordering avoids opposing Routine writers deadlocking.
  for v_user_exercise_id in
    select distinct refs.ref_id from (
      select distinct case
        when e.value ->> 'exercise_ref' ~ '^ex_' then null::uuid
        else (e.value ->> 'exercise_ref')::uuid
      end as ref_id
      from pg_catalog.jsonb_array_elements(v_normalized) as e(value)
      -- Also lock archived refs already attached to this Routine. A proposed
      -- entry may reuse its historical UUID with a catalog/active ref instead,
      -- which is invisible when locking incoming Custom refs alone.
      union all
      select old_entry.user_exercise_id
      from public.user_workout_routine_exercises as old_entry
      where old_entry.user_id = v_user_id
        and old_entry.routine_id = p_routine_id
    ) as refs
    where refs.ref_id is not null
    order by refs.ref_id
  loop
    select custom.status into v_custom_status
    from public.user_workout_exercises as custom
    where custom.id = v_user_exercise_id
      and custom.user_id = v_user_id
    for share;

    if not found then
      raise exception 'routine_composition_exercise_not_found'
        using errcode = 'P0002';
    end if;

    if v_custom_status <> 'active' then
      -- An archived historical entry may be removed, but never reused with a
      -- different Exercise ref (including catalog or still-active Custom).
      -- Check by OLD entry UUID, not only the incoming Custom references.
      if exists (
        select 1
        from public.user_workout_routine_exercises as old_entry
        cross join lateral pg_catalog.jsonb_array_elements(v_normalized)
          as proposed(value)
        where old_entry.routine_id = p_routine_id
          and old_entry.user_id = v_user_id
          and old_entry.user_exercise_id = v_user_exercise_id
          and (proposed.value ->> 'id')::uuid = old_entry.id
          and (proposed.value ->> 'exercise_ref')
            is distinct from v_user_exercise_id::text
      ) then
        raise exception 'routine_composition_archived_exercise_modified'
          using errcode = '22023';
      end if;

      -- Archived means the same entry ID/Custom reference and ordered Sets.
      -- Reordering Routine entries is allowed; changing archived Set order,
      -- targets, IDs or adding a new entry referencing it is not.
      for v_entry in
        select e.value
        from pg_catalog.jsonb_array_elements(v_normalized) as e(value)
        where e.value ->> 'exercise_ref' = v_user_exercise_id::text
      loop
        select exists (
          select 1 from public.user_workout_routine_exercises as old_entry
          where old_entry.id = (v_entry ->> 'id')::uuid
            and old_entry.routine_id = p_routine_id
            and old_entry.user_id = v_user_id
            and old_entry.user_exercise_id = v_user_exercise_id
        ) into v_original_exists;
        if not v_original_exists then
          raise exception 'routine_composition_archived_exercise_modified'
            using errcode = '22023';
        end if;

        select coalesce(pg_catalog.jsonb_agg(
          pg_catalog.jsonb_build_object(
            'id', old_set.id::text,
            'reps', old_set.reps,
            'set_type', old_set.set_type,
            'reps_max', old_set.reps_max,
            'load_kg', old_set.load_kg,
            'distance_meters', old_set.distance_meters,
            'duration_seconds', old_set.duration_seconds,
            'rest_seconds', old_set.rest_seconds
          ) order by old_set.position
        ), '[]'::jsonb) into v_original_sets
        from public.user_workout_routine_sets as old_set
        where old_set.user_id = v_user_id
          and old_set.routine_exercise_id = (v_entry ->> 'id')::uuid;

        if v_original_sets is distinct from v_entry -> 'sets' then
          raise exception 'routine_composition_archived_exercise_modified'
            using errcode = '22023';
        end if;
      end loop;
    end if;
  end loop;

  -- Full snapshot replacement, including empty draft compositions.
  -- All child DML rolls back if a later row/owner FK/constraint fails.
  delete from public.user_workout_routine_exercises
  where routine_id = p_routine_id and user_id = v_user_id;

  for v_entry, v_entry_ordinal in
    select e.value, e.ordinality
    from pg_catalog.jsonb_array_elements(v_normalized)
      with ordinality as e(value, ordinality)
  loop
    v_entry_id := (v_entry ->> 'id')::uuid;
    v_entry_ref := v_entry ->> 'exercise_ref';
    insert into public.user_workout_routine_exercises (
      id, user_id, routine_id, position, catalog_exercise_id, user_exercise_id
    ) values (
      v_entry_id, v_user_id, p_routine_id, (v_entry_ordinal - 1)::integer,
      case when v_entry_ref ~ '^ex_' then v_entry_ref else null end,
      case when v_entry_ref ~ '^ex_' then null else v_entry_ref::uuid end
    );

    for v_set, v_set_ordinal in
      select s.value, s.ordinality
      from pg_catalog.jsonb_array_elements(v_entry -> 'sets')
        with ordinality as s(value, ordinality)
    loop
      insert into public.user_workout_routine_sets (
        id, user_id, routine_exercise_id, position, reps, reps_max,
        set_type, load_kg, distance_meters, duration_seconds, rest_seconds
      ) values (
        (v_set ->> 'id')::uuid, v_user_id, v_entry_id,
        (v_set_ordinal - 1)::integer,
        (v_set ->> 'reps')::integer,
        (v_set ->> 'reps_max')::integer,
        coalesce(v_set ->> 'set_type','normal'),
        (v_set ->> 'load_kg')::double precision,
        (v_set ->> 'distance_meters')::double precision,
        (v_set ->> 'duration_seconds')::integer,
        (v_set ->> 'rest_seconds')::integer
      );
    end loop;
  end loop;

  update public.user_workout_routines
  set composition_revision = v_revision + 1,
      last_composition_mutation_id = p_client_mutation_id
  where id = p_routine_id and user_id = v_user_id;

  return v_revision + 1;
end;
$$;

revoke all on function public.save_user_workout_routine_composition(
  uuid, bigint, uuid, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.save_user_workout_routine_composition(
  uuid, bigint, uuid, jsonb
) to authenticated;
