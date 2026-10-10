-- GitHub #509 / TNYX-78: additive Program-owned Routine composition.
-- Owner approved physical contract 2026-10-10. Does not enable Routine builder UI.
-- No live deployment is implied by committing this migration.

alter table public.user_workout_routines
  add column composition_revision bigint not null default 0,
  add column last_composition_mutation_id uuid,
  add constraint user_workout_routines_composition_revision_nonnegative
    check (composition_revision >= 0),
  add constraint user_workout_routines_id_user_id_key unique (id, user_id);

create table public.user_workout_routine_exercises (
  id uuid primary key,
  user_id uuid not null,
  routine_id uuid not null,
  position integer not null,
  catalog_exercise_id text,
  user_exercise_id uuid,
  constraint user_workout_routine_exercises_position_nonnegative
    check (position >= 0),
  constraint user_workout_routine_exercises_reference_exclusive
    check ((catalog_exercise_id is not null) <> (user_exercise_id is not null)),
  constraint user_workout_routine_exercises_catalog_ref_format
    check (catalog_exercise_id is null
      or catalog_exercise_id ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'),
  constraint user_workout_routine_exercises_owner_fkey
    foreign key (routine_id, user_id)
    references public.user_workout_routines(id, user_id) on delete cascade,
  constraint user_workout_routine_exercises_user_exercise_fkey
    foreign key (user_exercise_id, user_id)
    references public.user_workout_exercises(id, user_id)
    on delete no action deferrable initially deferred,
  constraint user_workout_routine_exercises_id_user_id_key unique (id, user_id),
  constraint user_workout_routine_exercises_position_key
    unique (routine_id, user_id, position)
);

create table public.user_workout_routine_sets (
  id uuid primary key,
  user_id uuid not null,
  routine_exercise_id uuid not null,
  position integer not null,
  reps integer not null,
  load_kg double precision,
  rest_seconds integer,
  constraint user_workout_routine_sets_position_nonnegative
    check (position >= 0),
  constraint user_workout_routine_sets_reps_positive check (reps > 0),
  constraint user_workout_routine_sets_load_nonnegative_finite
    check (load_kg is null or (
      load_kg >= 0
      and load_kg < 'Infinity'::double precision
      and load_kg <> 'NaN'::double precision
    )),
  constraint user_workout_routine_sets_rest_nonnegative
    check (rest_seconds is null or rest_seconds >= 0),
  constraint user_workout_routine_sets_exercise_owner_fkey
    foreign key (routine_exercise_id, user_id)
    references public.user_workout_routine_exercises(id, user_id)
    on delete cascade,
  constraint user_workout_routine_sets_position_key
    unique (routine_exercise_id, user_id, position)
);

alter table public.user_workout_routine_exercises enable row level security;
alter table public.user_workout_routine_sets enable row level security;

revoke all on public.user_workout_routine_exercises from public, anon, authenticated;
revoke all on public.user_workout_routine_sets from public, anon, authenticated;
grant select on public.user_workout_routine_exercises to authenticated;
grant select on public.user_workout_routine_sets to authenticated;
grant select, insert, update, delete
  on public.user_workout_routine_exercises to service_role;
grant select, insert, update, delete
  on public.user_workout_routine_sets to service_role;

create policy user_workout_routine_exercises_select_own
  on public.user_workout_routine_exercises
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy user_workout_routine_sets_select_own
  on public.user_workout_routine_sets
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Atomic full composition replacement. All row ownership comes from auth.uid().
-- Direct authenticated child INSERT/UPDATE/DELETE remains prohibited.
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
  v_rest integer;
  v_normalized jsonb := '[]'::jsonb;
  v_sets jsonb;
  v_persisted jsonb;
  v_seen_entries uuid[] := array[]::uuid[];
  v_seen_sets uuid[] := array[]::uuid[];
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

  for v_entry, v_entry_ordinal in
    select e.value, e.ordinality
    from pg_catalog.jsonb_array_elements(p_exercises)
      with ordinality as e(value, ordinality)
  loop
    if pg_catalog.jsonb_typeof(v_entry) <> 'object'
        or v_entry - 'id' - 'exercise_ref' - 'sets' <> '{}'::jsonb
        or pg_catalog.jsonb_typeof(v_entry -> 'id') <> 'string'
        or pg_catalog.jsonb_typeof(v_entry -> 'exercise_ref') <> 'string'
        or pg_catalog.jsonb_typeof(v_entry -> 'sets') <> 'array'
        or (v_entry ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'invalid_routine_exercise_entry' using errcode = '22023';
    end if;

    v_entry_id := (v_entry ->> 'id')::uuid;
    if v_entry_id = any(v_seen_entries) then
      raise exception 'duplicate_routine_exercise_entry' using errcode = '22023';
    end if;
    v_seen_entries := pg_catalog.array_append(v_seen_entries, v_entry_id);

    v_entry_ref := v_entry ->> 'exercise_ref';
    v_catalog_id := null;
    v_user_exercise_id := null;
    if v_entry_ref ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$' then
      v_catalog_id := v_entry_ref;
    elsif v_entry_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      v_user_exercise_id := v_entry_ref::uuid;
    else
      raise exception 'invalid_routine_exercise_ref' using errcode = '22023';
    end if;

    v_sets := '[]'::jsonb;
    for v_set, v_set_ordinal in
      select s.value, s.ordinality
      from pg_catalog.jsonb_array_elements(v_entry -> 'sets')
        with ordinality as s(value, ordinality)
    loop
      if pg_catalog.jsonb_typeof(v_set) <> 'object'
          or v_set - 'id' - 'reps' - 'load_kg' - 'rest_seconds' <> '{}'::jsonb
          or pg_catalog.jsonb_typeof(v_set -> 'id') <> 'string'
          or (v_set ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          or pg_catalog.jsonb_typeof(v_set -> 'reps') <> 'number'
          or (v_set ->> 'reps') !~ '^[0-9]+$' then
        raise exception 'invalid_routine_set' using errcode = '22023';
      end if;
      v_set_id := (v_set ->> 'id')::uuid;
      if v_set_id = any(v_seen_sets) then
        raise exception 'duplicate_routine_set' using errcode = '22023';
      end if;
      v_seen_sets := pg_catalog.array_append(v_seen_sets, v_set_id);
      v_reps := (v_set ->> 'reps')::integer;
      if v_reps <= 0 then
        raise exception 'invalid_routine_set_reps' using errcode = '22023';
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

      v_rest := null;
      if v_set ? 'rest_seconds'
          and pg_catalog.jsonb_typeof(v_set -> 'rest_seconds') <> 'null' then
        if pg_catalog.jsonb_typeof(v_set -> 'rest_seconds') <> 'number'
            or (v_set ->> 'rest_seconds') !~ '^[0-9]+$' then
          raise exception 'invalid_routine_set_rest' using errcode = '22023';
        end if;
        v_rest := (v_set ->> 'rest_seconds')::integer;
      end if;

      v_sets := v_sets || pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object(
          'id', v_set_id::text, 'reps', v_reps,
          'load_kg', v_load, 'rest_seconds', v_rest
        )
      );
    end loop;

    v_normalized := v_normalized || pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object(
        'id', v_entry_id::text,
        'exercise_ref', pg_catalog.coalesce(v_catalog_id, v_user_exercise_id::text),
        'sets', v_sets
      )
    );
  end loop;

  -- Lock exactly the authenticated user's parent Routine before checking
  -- revision. An unknown or other-owner Routine produces the same error.
  select routine.composition_revision, routine.last_composition_mutation_id
    into v_revision, v_last_mutation
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;

  if not found then
    raise exception 'routine_composition_not_found' using errcode = 'P0002';
  end if;

  if v_last_mutation = p_client_mutation_id then
    select pg_catalog.coalesce(pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', exercise.id::text,
        'exercise_ref', pg_catalog.coalesce(
          exercise.catalog_exercise_id, exercise.user_exercise_id::text
        ),
        'sets', (
          select pg_catalog.coalesce(pg_catalog.jsonb_agg(
            pg_catalog.jsonb_build_object(
              'id', set_row.id::text,
              'reps', set_row.reps,
              'load_kg', set_row.load_kg,
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

  if v_revision <> p_expected_revision then
    raise exception 'routine_composition_revision_conflict' using errcode = 'P0001';
  end if;

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
        id, user_id, routine_exercise_id, position, reps, load_kg, rest_seconds
      ) values (
        (v_set ->> 'id')::uuid, v_user_id, v_entry_id,
        (v_set_ordinal - 1)::integer,
        (v_set ->> 'reps')::integer,
        (v_set ->> 'load_kg')::double precision,
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
