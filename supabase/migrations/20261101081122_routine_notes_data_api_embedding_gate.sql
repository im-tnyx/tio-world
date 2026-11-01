-- TNYX-81 / Routine Notes Data API embedding gate
-- The pre-request hook protects exact Notes paths, but PostgREST can reach
-- the Notes table through a parent-resource embedding path. Keep the hook for
-- deterministic direct-path 403 responses and add a row-level, fail-closed
-- SELECT boundary for embedded Notes relations.

create function private.routine_notes_data_api_gate_is_enabled()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $$
  select exists (
    select 1
    from private.routine_notes_data_api_gate_state
    where gate_key = 'routine_notes'
      and gate_state = 'enabled'
  );
$$;

revoke all on function private.routine_notes_data_api_gate_is_enabled()
  from public, anon, authenticated, service_role;
grant execute on function private.routine_notes_data_api_gate_is_enabled()
  to authenticated;

-- RESTRICTIVE ensures this condition is required in addition to the existing
-- owner-scoped Notes policies. It affects SELECT only, which is the relation
-- embedding bypass surface; existing Notes RPC/table write contracts remain
-- unchanged and the pre-request hook still covers direct Notes paths. A null
-- request.path is the explicit direct-database/operator boundary, where the
-- existing SQL/RLS contract remains testable; PostgREST always supplies it.
create policy routine_notes_data_api_gate_enabled_select
  on public.user_workout_routine_notes
  as restrictive
  for select
  to authenticated
  using (
    current_setting('request.path', true) is null
    or private.routine_notes_data_api_gate_is_enabled()
  );
