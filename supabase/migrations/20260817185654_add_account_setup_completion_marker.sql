alter table public.users
  add column account_setup_completed_at timestamptz;

comment on column public.users.account_setup_completed_at is
  'Timestamp when the authenticated account completed the pre-onboarding Account Setup boundary. Null means Account Setup is still pending for fresh/incomplete accounts.';
