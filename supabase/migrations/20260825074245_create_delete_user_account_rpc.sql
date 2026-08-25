-- Create the permanent account-deletion RPC for the currently authenticated user.
-- Storage objects are intentionally excluded: Supabase Storage files must be
-- removed through the Storage API before this RPC is invoked.

create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_uid uuid := auth.uid();
  deleted_count integer;
begin
  if current_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  delete from auth.users
  where id = current_uid;

  get diagnostics deleted_count = row_count;
  if deleted_count <> 1 then
    raise exception 'Authenticated user account was not deleted'
      using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.delete_user_account() from public;
revoke all on function public.delete_user_account() from anon;
grant execute on function public.delete_user_account() to authenticated;
