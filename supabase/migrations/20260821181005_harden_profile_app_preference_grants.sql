revoke all privileges on table public.user_profiles from anon;
revoke all privileges on table public.user_app_preferences from anon;

revoke all privileges on table public.user_profiles from authenticated;
revoke all privileges on table public.user_app_preferences from authenticated;

grant select, insert, update on table public.user_profiles to authenticated;
grant select, insert, update on table public.user_app_preferences to authenticated;

grant select, insert, update, delete on table public.user_profiles to service_role;
grant select, insert, update, delete on table public.user_app_preferences to service_role;
