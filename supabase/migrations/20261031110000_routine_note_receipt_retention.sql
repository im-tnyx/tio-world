-- TNYX-81 / PR #717
-- Redact expired receipt snapshots on authenticated receipt access while
-- retaining the permanent mutation identity and request hash tombstone.
-- This is an access-time fallback; scheduled expiry remains a separate gate.

create function private.expire_user_workout_routine_note_receipt(
  p_user_id uuid,
  p_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_snapshot jsonb;
begin
  -- Return NULL only for an unknown receipt. Expired receipts become a stable,
  -- body-free tombstone; request_hash and the receipt primary key are untouched.
  if p_user_id is null or p_mutation_id is null then
    return null;
  end if;

  update private.user_workout_routine_note_mutations as receipt
     set result_snapshot = pg_catalog.jsonb_build_object(
       'status', 'expired',
       'mutation_id', receipt.mutation_id,
       'operation', receipt.operation,
       'result_kind', receipt.result_kind,
       'note_id', receipt.note_id,
       'revision', receipt.result_revision,
       'created_at', receipt.created_at
     )
   where receipt.user_id = p_user_id
     and receipt.mutation_id = p_mutation_id
     and receipt.created_at <=
       transaction_timestamp() - interval '30 days'
     and receipt.result_snapshot->>'status' <> 'expired'
  returning receipt.result_snapshot into v_snapshot;

  if found then
    return v_snapshot;
  end if;

  select receipt.result_snapshot
    into v_snapshot
  from private.user_workout_routine_note_mutations as receipt
  where receipt.user_id = p_user_id
    and receipt.mutation_id = p_mutation_id;

  if not found then
    return null;
  end if;
  if v_snapshot is null then
    raise exception 'routine_note_mutation_snapshot_unavailable'
      using errcode = 'P0001';
  end if;
  return v_snapshot;
end;
$$;

revoke all on function private.expire_user_workout_routine_note_receipt(
  uuid, uuid
) from public, anon, authenticated, service_role;

create or replace function public.mutate_user_workout_routine_note(
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
  v_body text;
  v_snapshot jsonb;
begin
  if v_user_id is null then
    raise exception 'routine_note_not_authenticated' using errcode = '28000';
  end if;

  -- Redact an existing expired receipt before the canonical mutation path
  -- checks its request hash. The legacy RPC still rejects a changed request
  -- and can never execute an expired mutation ID as a new operation.
  perform private.expire_user_workout_routine_note_receipt(
    v_user_id, p_mutation_id
  );

  if pg_catalog.lower(pg_catalog.btrim(coalesce(p_operation, '')))
      in ('create', 'update') then
    v_body := private.normalize_user_workout_routine_note_body(p_body);
  else
    v_body := p_body;
  end if;

  perform public.mutate_user_workout_routine_note_legacy(
    p_operation,
    p_note_id,
    p_routine_id,
    p_exercise_ref,
    p_note_type,
    v_body,
    p_expected_revision,
    p_mutation_id
  );

  select receipt.result_snapshot
    into v_snapshot
  from private.user_workout_routine_note_mutations as receipt
  where receipt.user_id = v_user_id
    and receipt.mutation_id = p_mutation_id;

  if not found or v_snapshot is null then
    raise exception 'routine_note_mutation_snapshot_unavailable'
      using errcode = 'P0001';
  end if;

  return v_snapshot;
end;
$$;

revoke all on function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) to authenticated;

create or replace function public.reconcile_user_workout_routine_note_mutation(
  p_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_snapshot jsonb;
begin
  if v_user_id is null then
    raise exception 'routine_note_not_authenticated' using errcode = '28000';
  end if;
  if p_mutation_id is null then
    raise exception 'invalid_routine_note_mutation' using errcode = '22023';
  end if;

  v_snapshot := private.expire_user_workout_routine_note_receipt(
    v_user_id, p_mutation_id
  );
  if v_snapshot is null then
    return pg_catalog.jsonb_build_object('status', 'pending');
  end if;
  return v_snapshot;
end;
$$;

revoke all on function public.reconcile_user_workout_routine_note_mutation(uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.reconcile_user_workout_routine_note_mutation(uuid)
  to authenticated;
