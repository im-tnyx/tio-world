-- TNYX-81 / Routine Notes server-side Data API gate
-- Install the fail-closed gate before the first Notes migration. This protects
-- only PostgREST Data API paths; Realtime, Storage, GraphQL, Edge Functions and
-- direct database connections remain separate boundaries.

create schema if not exists private;

create table private.routine_notes_data_api_gate_state (
  gate_key text primary key,
  gate_state text default 'disabled'
);

insert into private.routine_notes_data_api_gate_state (gate_key, gate_state)
values ('routine_notes', 'disabled');

alter table private.routine_notes_data_api_gate_state
  enable row level security;

-- The gate state is trusted operator configuration, never a client-owned API
-- object. Keep the table unreachable even when default privileges change.
revoke all on table private.routine_notes_data_api_gate_state
  from public, anon, authenticated, service_role;

revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema private to anon, authenticated, service_role;

create function private.routine_notes_data_api_gate()
returns void
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_request_path text := current_setting('request.path', true);
  v_gate_state text;
begin
  if v_request_path not in (
      '/user_workout_routine_notes',
      '/rpc/mutate_user_workout_routine_note',
      '/rpc/mutate_user_workout_routine_note_legacy',
      '/rpc/reconcile_user_workout_routine_note_mutation'
    ) then
    return;
  end if;

  select gate_state
    into v_gate_state
  from private.routine_notes_data_api_gate_state
  where gate_key = 'routine_notes';

  if v_gate_state is distinct from 'enabled' then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'routine_notes_data_api_disabled',
        'message', 'Routine Notes Data API is disabled',
        'details', 'Routine Notes access is disabled by server policy',
        'hint', 'Enable only after the approved Routine Notes security gate'
      )::text,
      detail = pg_catalog.json_build_object(
        'status', 403,
        'headers', pg_catalog.json_build_object(),
        'status_text', 'Forbidden'
      )::text;
  end if;
end;
$$;

revoke all on function private.routine_notes_data_api_gate()
  from public, anon, authenticated, service_role;
grant execute on function private.routine_notes_data_api_gate()
  to anon, authenticated, service_role;

-- Supabase-supported PostgREST configuration. The state remains disabled until
-- a separately authorized operator changes the private state row.
alter role authenticator
  set pgrst.db_pre_request = 'private.routine_notes_data_api_gate';

notify pgrst, 'reload config';
