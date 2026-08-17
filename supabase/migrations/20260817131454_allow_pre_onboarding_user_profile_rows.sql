-- Fresh authenticated users must claim a unique username before profile onboarding.
-- Keep canonical profile values empty until the user actually supplies them;
-- do not manufacture gender/DOB/height/weight/activity defaults just to create
-- the public.users identity row.

alter table public.users
  alter column gender drop not null,
  alter column goals drop not null,
  alter column date_of_birth drop not null,
  alter column height_cm drop not null,
  alter column current_weight_kg drop not null,
  alter column activity_level drop not null;

comment on column public.users.gender is
  'Nullable until onboarding profile setup is completed.';
comment on column public.users.goals is
  'Nullable until onboarding profile setup is completed.';
comment on column public.users.date_of_birth is
  'Nullable until onboarding profile setup is completed.';
comment on column public.users.height_cm is
  'Nullable until onboarding profile setup is completed.';
comment on column public.users.current_weight_kg is
  'Nullable until onboarding profile setup is completed.';
comment on column public.users.activity_level is
  'Nullable until onboarding profile setup is completed.';
