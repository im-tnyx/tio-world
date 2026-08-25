-- Keep destructive account deletion callable only by the authenticated client
-- boundary. `postgres` remains the function owner and can administer it.

revoke execute on function public.delete_user_account() from service_role;
