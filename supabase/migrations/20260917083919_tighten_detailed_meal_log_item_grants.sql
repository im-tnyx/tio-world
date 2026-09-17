-- TNYX-217 review hardening: keep the new detailed child table read-only
-- for authenticated clients until the later atomic repository/RPC write boundary
-- is explicitly implemented. This prevents direct item mutation from bypassing
-- parent revision/concurrency semantics.

revoke all on table public.meal_log_item_snapshots
  from anon, authenticated, service_role;

grant select on table public.meal_log_item_snapshots
  to authenticated;

grant select, insert, update, delete on table public.meal_log_item_snapshots
  to service_role;
