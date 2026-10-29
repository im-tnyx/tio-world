-- TNYX-81 / Routine Notes Slice 1
-- Durable owner-scoped Routine and Exercise Notes foundation.
-- This migration is source/review only until an explicit hosted apply decision.

create table public.user_workout_routine_notes (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  routine_id uuid,
  exercise_ref text,
  note_type text not null,
  body text not null,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  revision bigint not null default 0,
  last_mutation_id uuid,
  constraint user_workout_routine_notes_routine_owner_fkey
    foreign key (routine_id, user_id)
    references public.user_workout_routines(id, user_id)
    on delete cascade,
  constraint user_workout_routine_notes_target_check
    check ((routine_id is not null) <> (exercise_ref is not null)),
  constraint user_workout_routine_notes_type_target_check
    check (
      (note_type = 'pinned_routine'
        and routine_id is not null and exercise_ref is null)
      or
      (note_type = 'pinned_exercise'
        and routine_id is null and exercise_ref is not null)
    ),
  constraint user_workout_routine_notes_type_check
    check (note_type in ('pinned_routine', 'pinned_exercise')),
  constraint user_workout_routine_notes_exercise_ref_format_check
    check (
      exercise_ref is null
      or exercise_ref ~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'
      or exercise_ref ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    ),
  constraint user_workout_routine_notes_body_check
    check (
      body = btrim(body)
      and btrim(body) <> ''
      and char_length(body) <= 500
    ),
  constraint user_workout_routine_notes_revision_check
    check (revision >= 0)
);

create index idx_user_workout_routine_notes_routine_order
  on public.user_workout_routine_notes (user_id, routine_id, created_at, id)
  where note_type = 'pinned_routine';

create index idx_user_workout_routine_notes_exercise_order
  on public.user_workout_routine_notes (user_id, exercise_ref, created_at, id)
  where note_type = 'pinned_exercise';

create trigger trg_user_workout_routine_notes_updated_at
before update on public.user_workout_routine_notes
for each row execute function public.set_row_updated_at();

create schema if not exists private;

create table private.user_workout_routine_note_mutations (
  user_id uuid not null references public.users(id) on delete cascade,
  mutation_id uuid not null,
  operation text not null,
  request_hash text not null,
  result_kind text not null,
  note_id uuid not null,
  result_revision bigint,
  created_at timestamptz not null default timezone('utc'::text, now()),
  primary key (user_id, mutation_id),
  constraint user_workout_routine_note_mutations_operation_check
    check (operation in ('create', 'update', 'transfer', 'delete')),
  constraint user_workout_routine_note_mutations_result_check
    check (result_kind in ('applied', 'deleted')),
  constraint user_workout_routine_note_mutations_hash_check
    check (request_hash ~ '^[0-9a-f]{64}$'),
  constraint user_workout_routine_note_mutations_revision_check
    check (result_revision is null or result_revision >= 0)
);

revoke all on table public.user_workout_routine_notes from anon;
revoke all on table public.user_workout_routine_notes from authenticated;
revoke all on table public.user_workout_routine_notes from service_role;
grant select on table public.user_workout_routine_notes to authenticated;

alter table public.user_workout_routine_notes enable row level security;

create policy user_workout_routine_notes_select_own
on public.user_workout_routine_notes
for select to authenticated
using ((select auth.uid()) = user_id);

revoke all on table private.user_workout_routine_note_mutations
  from public, anon, authenticated, service_role;
alter table private.user_workout_routine_note_mutations enable row level security;

create function private.user_workout_routine_note_payload(
  p_user_id uuid,
  p_note_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select pg_catalog.jsonb_build_object(
    'id', note.id,
    'user_id', note.user_id,
    'routine_id', note.routine_id,
    'exercise_ref', note.exercise_ref,
    'note_type', note.note_type,
    'body', note.body,
    'created_at', note.created_at,
    'updated_at', note.updated_at,
    'revision', note.revision,
    'last_mutation_id', note.last_mutation_id
  )
  from public.user_workout_routine_notes as note
  where note.user_id = p_user_id
    and note.id = p_note_id;
$$;

revoke all on function private.user_workout_routine_note_payload(uuid, uuid)
  from public, anon, authenticated, service_role;

create function public.mutate_user_workout_routine_note(
  p_operation text,
  p_note_id uuid,
  p_routine_id uuid,
  p_exercise_ref text,
  p_note_type text,
  p_body text,
  p_expected_revision bigint,
  p_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_operation text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_operation, '')));
  v_note_type text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_note_type, '')));
  v_exercise_ref text;
  v_body text;
  v_request_hash text;
  v_existing_hash text;
  v_existing_result_kind text;
  v_existing_note_id uuid;
  v_existing_revision bigint;
  v_note public.user_workout_routine_notes%rowtype;
  v_source_scope text;
  v_destination_scope text;
  v_scope_keys text[];
  v_scope_key text;
  v_count bigint;
  v_custom_status text;
begin
  if v_user_id is null then
    raise exception 'routine_note_not_authenticated' using errcode = '28000';
  end if;

  if p_note_id is null or p_mutation_id is null
      or v_operation not in ('create', 'update', 'transfer', 'delete') then
    raise exception 'invalid_routine_note_request' using errcode = '22023';
  end if;

  if p_expected_revision is not null and p_expected_revision < 0 then
    raise exception 'invalid_routine_note_revision' using errcode = '22023';
  end if;

  if v_operation in ('create', 'update') then
    if p_body is null then
      raise exception 'invalid_routine_note_body' using errcode = '22023';
    end if;
    v_body := pg_catalog.btrim(p_body);
    if v_body = '' or pg_catalog.char_length(v_body) > 500 then
      raise exception 'invalid_routine_note_body' using errcode = '22023';
    end if;
  end if;

  if v_operation = 'create' and v_note_type = '' then
    v_note_type := 'pinned_routine';
  end if;

  if v_operation in ('create', 'transfer') then
    if v_note_type not in ('pinned_routine', 'pinned_exercise') then
      raise exception 'invalid_routine_note_type' using errcode = '22023';
    end if;
    if v_note_type = 'pinned_routine' then
      if p_routine_id is null or p_exercise_ref is not null then
        raise exception 'invalid_routine_note_scope' using errcode = '22023';
      end if;
    else
      if p_routine_id is not null or p_exercise_ref is null then
        raise exception 'invalid_routine_note_scope' using errcode = '22023';
      end if;
      v_exercise_ref := pg_catalog.lower(pg_catalog.btrim(p_exercise_ref));
      if v_exercise_ref !~ '^ex_[a-z0-9]+(?:_[a-z0-9]+)*$'
          and v_exercise_ref !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
        raise exception 'invalid_routine_note_exercise_ref'
          using errcode = '22023';
      end if;
    end if;
  elsif v_operation in ('update', 'delete') then
    if p_routine_id is not null or p_exercise_ref is not null
        or p_note_type is not null and pg_catalog.btrim(p_note_type) <> '' then
      raise exception 'invalid_routine_note_scope' using errcode = '22023';
    end if;
  end if;

  if v_operation = 'create' and p_expected_revision is not null then
    raise exception 'invalid_routine_note_revision' using errcode = '22023';
  end if;
  if v_operation in ('update', 'transfer', 'delete')
      and p_expected_revision is null then
    raise exception 'invalid_routine_note_revision' using errcode = '22023';
  end if;

  v_request_hash := pg_catalog.encode(
    pg_catalog.sha256(
      pg_catalog.convert_to(
        pg_catalog.jsonb_build_object(
          'operation', v_operation,
          'note_id', p_note_id,
          'routine_id', p_routine_id,
          'exercise_ref', v_exercise_ref,
          'note_type', case when v_note_type = '' then null else v_note_type end,
          'body', v_body,
          'expected_revision', p_expected_revision
        )::text,
        'UTF8'
      )
    ),
    'hex'
  );

  -- Serialize receipt lookup and replay for the same owner/mutation pair.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      v_user_id::text || ':routine-note-mutation:' || p_mutation_id::text,
      0
    )
  );

  select receipt.request_hash, receipt.result_kind, receipt.note_id,
         receipt.result_revision
    into v_existing_hash, v_existing_result_kind, v_existing_note_id,
         v_existing_revision
  from private.user_workout_routine_note_mutations as receipt
  where receipt.user_id = v_user_id
    and receipt.mutation_id = p_mutation_id
  for update;

  if found then
    if v_existing_hash is distinct from v_request_hash then
      raise exception 'routine_note_mutation_conflict' using errcode = 'P0001';
    end if;
    if v_existing_result_kind = 'deleted' then
      return pg_catalog.jsonb_build_object(
        'status', 'deleted',
        'note_id', v_existing_note_id,
        'revision', v_existing_revision
      );
    end if;
    return pg_catalog.jsonb_build_object(
      'status', 'applied',
      'note', private.user_workout_routine_note_payload(
        v_user_id, v_existing_note_id
      ),
      'note_id', v_existing_note_id,
      'revision', v_existing_revision
    );
  end if;

  if v_operation = 'create' then
    v_destination_scope := case
      when v_note_type = 'pinned_routine'
        then 'routine:' || p_routine_id::text
      else 'exercise:' || v_exercise_ref
    end;
    v_scope_keys := array[v_destination_scope];
  elsif v_operation in ('update', 'delete', 'transfer') then
    select * into v_note
    from public.user_workout_routine_notes as note
    where note.id = p_note_id and note.user_id = v_user_id
    for update;
    if not found then
      raise exception 'routine_note_not_found' using errcode = 'P0002';
    end if;
    v_source_scope := case
      when v_note.note_type = 'pinned_routine'
        then 'routine:' || v_note.routine_id::text
      else 'exercise:' || v_note.exercise_ref
    end;
    if v_operation = 'transfer' then
      v_destination_scope := case
        when v_note_type = 'pinned_routine'
          then 'routine:' || p_routine_id::text
        else 'exercise:' || v_exercise_ref
      end;
      if v_destination_scope = v_source_scope then
        raise exception 'invalid_routine_note_transfer'
          using errcode = '22023';
      end if;
      v_scope_keys := array[v_source_scope, v_destination_scope];
    else
      v_scope_keys := array[v_source_scope];
    end if;
  end if;

  -- Lexical ordering makes opposing transfers acquire scope locks identically.
  for v_scope_key in
    select distinct scope_key
    from pg_catalog.unnest(v_scope_keys) as scopes(scope_key)
    order by scope_key
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        v_user_id::text || ':routine-note-scope:' || v_scope_key,
        0
      )
    );
  end loop;

  if v_operation in ('create', 'transfer') then
    if v_note_type = 'pinned_routine' then
      if not exists (
        select 1 from public.user_workout_routines as routine
        where routine.id = p_routine_id and routine.user_id = v_user_id
      ) then
        raise exception 'routine_note_routine_not_found' using errcode = 'P0002';
      end if;
    else
      if v_exercise_ref ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
        select exercise.status into v_custom_status
        from public.user_workout_exercises as exercise
        where exercise.id = v_exercise_ref::uuid
          and exercise.user_id = v_user_id
        for share;
        if not found then
          raise exception 'routine_note_exercise_not_found'
            using errcode = 'P0002';
        end if;
        if v_custom_status <> 'active' then
          raise exception 'routine_note_exercise_archived'
            using errcode = 'P0001';
        end if;
      end if;
    end if;
  end if;

  if v_operation = 'create' then
    if exists (
      select 1 from public.user_workout_routine_notes as note
      where note.id = p_note_id
    ) then
      raise exception 'routine_note_id_conflict' using errcode = 'P0001';
    end if;
    select count(*) into v_count
    from public.user_workout_routine_notes as note
    where note.user_id = v_user_id
      and ((v_note_type = 'pinned_routine' and note.routine_id = p_routine_id)
        or (v_note_type = 'pinned_exercise'
          and note.exercise_ref = v_exercise_ref));
    if v_count >= 5 then
      raise exception 'routine_note_quota_exceeded' using errcode = 'P0001';
    end if;
    insert into public.user_workout_routine_notes (
      id, user_id, routine_id, exercise_ref, note_type, body, revision,
      last_mutation_id
    ) values (
      p_note_id, v_user_id,
      case when v_note_type = 'pinned_routine' then p_routine_id else null end,
      case when v_note_type = 'pinned_exercise' then v_exercise_ref else null end,
      v_note_type, v_body, 0, p_mutation_id
    ) returning * into v_note;

    insert into private.user_workout_routine_note_mutations (
      user_id, mutation_id, operation, request_hash, result_kind, note_id,
      result_revision
    ) values (
      v_user_id, p_mutation_id, v_operation, v_request_hash, 'applied',
      p_note_id, v_note.revision
    );
    return pg_catalog.jsonb_build_object(
      'status', 'applied',
      'note', private.user_workout_routine_note_payload(v_user_id, p_note_id),
      'note_id', p_note_id,
      'revision', v_note.revision
    );
  end if;

  -- Re-read after scope locks so no concurrent transfer can change the source.
  select * into v_note
  from public.user_workout_routine_notes as note
  where note.id = p_note_id and note.user_id = v_user_id
  for update;
  if not found then
    raise exception 'routine_note_not_found' using errcode = 'P0002';
  end if;
  if v_note.revision <> p_expected_revision then
    raise exception 'routine_note_revision_conflict' using errcode = 'P0001';
  end if;

  if v_operation = 'update' then
    update public.user_workout_routine_notes as note
    set body = v_body,
        revision = note.revision + 1,
        last_mutation_id = p_mutation_id
    where note.id = p_note_id and note.user_id = v_user_id
    returning * into v_note;
  elsif v_operation = 'transfer' then
    select count(*) into v_count
    from public.user_workout_routine_notes as note
    where note.user_id = v_user_id
      and ((v_note_type = 'pinned_routine' and note.routine_id = p_routine_id)
        or (v_note_type = 'pinned_exercise'
          and note.exercise_ref = v_exercise_ref));
    if v_count >= 5 then
      raise exception 'routine_note_quota_exceeded' using errcode = 'P0001';
    end if;
    update public.user_workout_routine_notes as note
    set routine_id = case when v_note_type = 'pinned_routine'
                          then p_routine_id else null end,
        exercise_ref = case when v_note_type = 'pinned_exercise'
                            then v_exercise_ref else null end,
        note_type = v_note_type,
        revision = note.revision + 1,
        last_mutation_id = p_mutation_id
    where note.id = p_note_id and note.user_id = v_user_id
    returning * into v_note;
  else
    delete from public.user_workout_routine_notes as note
    where note.id = p_note_id and note.user_id = v_user_id
    returning note.id, note.revision into v_existing_note_id, v_existing_revision;
    insert into private.user_workout_routine_note_mutations (
      user_id, mutation_id, operation, request_hash, result_kind, note_id,
      result_revision
    ) values (
      v_user_id, p_mutation_id, v_operation, v_request_hash, 'deleted',
      v_existing_note_id, v_existing_revision
    );
    return pg_catalog.jsonb_build_object(
      'status', 'deleted',
      'note_id', v_existing_note_id,
      'revision', v_existing_revision
    );
  end if;

  insert into private.user_workout_routine_note_mutations (
    user_id, mutation_id, operation, request_hash, result_kind, note_id,
    result_revision
  ) values (
    v_user_id, p_mutation_id, v_operation, v_request_hash, 'applied',
    p_note_id, v_note.revision
  );
  return pg_catalog.jsonb_build_object(
    'status', 'applied',
    'note', private.user_workout_routine_note_payload(v_user_id, p_note_id),
    'note_id', p_note_id,
    'revision', v_note.revision
  );
end;
$$;

revoke all on function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) to authenticated;

create function public.reconcile_user_workout_routine_note_mutation(
  p_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_receipt private.user_workout_routine_note_mutations%rowtype;
begin
  if v_user_id is null then
    raise exception 'routine_note_not_authenticated' using errcode = '28000';
  end if;
  if p_mutation_id is null then
    raise exception 'invalid_routine_note_mutation' using errcode = '22023';
  end if;

  select * into v_receipt
  from private.user_workout_routine_note_mutations as receipt
  where receipt.user_id = v_user_id
    and receipt.mutation_id = p_mutation_id;
  if not found then
    return pg_catalog.jsonb_build_object('status', 'pending');
  end if;
  if v_receipt.result_kind = 'deleted' then
    return pg_catalog.jsonb_build_object(
      'status', 'deleted',
      'note_id', v_receipt.note_id,
      'revision', v_receipt.result_revision
    );
  end if;
  return pg_catalog.jsonb_build_object(
    'status', 'applied',
    'note', private.user_workout_routine_note_payload(
      v_user_id, v_receipt.note_id
    ),
    'note_id', v_receipt.note_id,
    'revision', v_receipt.result_revision
  );
end;
$$;

revoke all on function public.reconcile_user_workout_routine_note_mutation(uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.reconcile_user_workout_routine_note_mutation(uuid)
  to authenticated;
